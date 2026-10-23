-- ============================================================
-- CameraController.client.lua
-- LocalScript สำหรับ StarterPlayerScripts
-- ควบคุมกล้องมุมมองบุคคลที่สาม (Third-Person Camera) สำหรับ R6
-- Custom third-person camera controller for R6 rig
-- ============================================================

local Players              = game:GetService("Players")
local RunService           = game:GetService("RunService")
local UserInputService     = game:GetService("UserInputService")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")

-- ─── Constants / ค่าคงที่ ───────────────────────────────────
local DEFAULT_DISTANCE  = 12      -- studs, ระยะกล้องเริ่มต้น / default camera distance
local MIN_DISTANCE      = 5       -- studs, ซูมเข้าสุด / min zoom
local MAX_DISTANCE      = 30      -- studs, ซูมออกสุด / max zoom
local DEFAULT_PITCH     = 20      -- degrees เหนือแนวนอน / degrees above horizontal
local MIN_PITCH         = -15     -- มุมกดลงต่ำสุด / lowest look-down angle
local MAX_PITCH         = 80      -- มุมเงยขึ้นสูงสุด / highest look-up angle
local ZOOM_SPEED        = 1.5     -- studs per scroll tick / ความเร็วซูม
local MOUSE_SENSITIVITY = 0.3     -- degrees per pixel / ความไวเมาส์
local LERP_FACTOR       = 0.1     -- camera smoothing factor (0=frozen, 1=instant)
local HEAD_OFFSET       = Vector3.new(0, 1.5, 0)  -- focus point above character root
local COLLISION_PADDING = 0.3     -- studs margin so camera doesn't clip into walls

-- ─── References / ตัวแปรหลัก ──────────────────────────────
local player      = Players.LocalPlayer
local camera      = workspace.CurrentCamera
local mouse       = player:GetMouse()

-- ─── Camera State / สถานะกล้อง ────────────────────────────
local currentDistance  = DEFAULT_DISTANCE
local targetDistance   = DEFAULT_DISTANCE
local currentYaw       = 0              -- horizontal angle (degrees), มุมซ้าย-ขวา
local currentPitch     = DEFAULT_PITCH  -- vertical angle (degrees), มุมเงย-กด
local smoothedPos      = Vector3.new(0, 0, 0)

local isRightMouseDown = false  -- กด RMB อยู่หรือไม่
local isShaking        = false  -- shake effect active
local shakeOffset      = Vector3.new(0, 0, 0)

-- ─── Override default Roblox camera / ปิดกล้อง default ────
local function disableDefaultCamera()
    camera.CameraType = Enum.CameraType.Scriptable
end
disableDefaultCamera()

-- ─── Helpers ──────────────────────────────────────────────
local function getRoot()
    local char = player.Character
    if char then return char:FindFirstChild("HumanoidRootPart") end
    return nil
end

local function getHumanoid()
    local char = player.Character
    if char then return char:FindFirstChildOfClass("Humanoid") end
    return nil
end

-- ─── Zoom with Mouse Wheel / ซูมด้วย scroll wheel ─────────
mouse.WheelForward:Connect(function()
    targetDistance = math.clamp(targetDistance - ZOOM_SPEED, MIN_DISTANCE, MAX_DISTANCE)
end)
mouse.WheelBackward:Connect(function()
    targetDistance = math.clamp(targetDistance + ZOOM_SPEED, MIN_DISTANCE, MAX_DISTANCE)
end)

-- ─── Right Mouse Button: Drag to Rotate + Lock Mouse ──────
-- กด RMB ค้างเพื่อหมุนกล้อง + ล็อคเมาส์
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRightMouseDown = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRightMouseDown = false
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end)

-- อ่านการเคลื่อนเมาส์เพื่อหมุนกล้อง / read mouse delta for rotation
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    if not isRightMouseDown then return end
    local dx = input.Delta.X
    local dy = input.Delta.Y
    currentYaw   = currentYaw   - dx * MOUSE_SENSITIVITY
    currentPitch = math.clamp(currentPitch - dy * MOUSE_SENSITIVITY, MIN_PITCH, MAX_PITCH)
end)

-- ─── Camera Shake / เขย่ากล้องตอนต่อสู้ ──────────────────
-- intensity = ความรุนแรง (studs), duration = ระยะเวลา (วินาที)
-- Global so other scripts (combat, etc.) can call ShakeCam(0.5, 0.3)
function ShakeCam(intensity, duration)
    if isShaking then return end
    isShaking = true
    task.spawn(function()
        local startTime = tick()
        while tick() - startTime < duration do
            local elapsed = tick() - startTime
            local fade    = 1 - (elapsed / duration)  -- fade out ตามเวลา
            local rx = (math.random() * 2 - 1) * intensity * fade
            local ry = (math.random() * 2 - 1) * intensity * fade
            shakeOffset = Vector3.new(rx, ry, 0)
            task.wait(0.04)  -- ~25 fps shake
        end
        shakeOffset = Vector3.new(0, 0, 0)
        isShaking = false
    end)
end

-- ─── Camera Collision via Raycast ─────────────────────────
-- คืนค่าระยะกล้องที่ปลอดภัย (ไม่ทะลุผนัง/พื้น)
local function getSafeDistance(origin, direction, maxDist)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local char = player.Character
    if char then
        params.FilterDescendantsInstances = {char}
    end
    local result = workspace:Raycast(origin, direction * maxDist, params)
    if result then
        local dist = (result.Position - origin).Magnitude - COLLISION_PADDING
        return math.max(dist, 0.5)  -- ไม่ให้กล้องชิดตัวละครเกินไป
    end
    return maxDist
end

-- ─── WASD Movement Relative to Camera Direction ────────────
-- ให้ตัวละครเคลื่อนที่ตามทิศกล้อง (ไม่ใช่ world forward)
local function updateMovement()
    local hum  = getHumanoid()
    local root = getRoot()
    if not hum or not root then return end

    local yawRad    = math.rad(currentYaw)
    local camFwd    = Vector3.new(-math.sin(yawRad), 0, -math.cos(yawRad))
    local camRight  = Vector3.new( math.cos(yawRad), 0, -math.sin(yawRad))

    local move = Vector3.new(0, 0, 0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + camFwd   end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - camFwd   end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - camRight  end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + camRight  end

    if move.Magnitude > 0.01 then
        move = move.Unit
        -- หมุน root ให้หันตามทิศเดิน / face the direction of movement
        root.CFrame = CFrame.new(root.Position, root.Position + move)
    end

    hum:Move(move, false)
end

-- ─── Main RenderStepped Loop / อัปเดตกล้องทุก frame ──────
RunService.RenderStepped:Connect(function(dt)
    local root = getRoot()
    if not root then return end

    -- 1. Spring-arm: lerp currentDistance → targetDistance
    currentDistance = currentDistance + (targetDistance - currentDistance) * 0.15

    -- 2. คำนวณ offset vector จาก spherical coords
    local yawRad   = math.rad(currentYaw)
    local pitchRad = math.rad(currentPitch)
    local camDir = Vector3.new(
        math.sin(yawRad) * math.cos(pitchRad),
        math.sin(pitchRad),
        math.cos(yawRad) * math.cos(pitchRad)
    )

    -- 3. Focus point เหนือหัวตัวละคร
    local focus = root.Position + HEAD_OFFSET

    -- 4. Collision check: หา safe distance
    local safeDist = getSafeDistance(focus, camDir, currentDistance)

    -- 5. Target position ของกล้อง
    local targetPos = focus + camDir * safeDist

    -- 6. Smooth lerp กล้องไปหา target / smooth camera movement
    local alpha = math.min(LERP_FACTOR * (dt * 60), 1)
    smoothedPos = smoothedPos:Lerp(targetPos, LERP_FACTOR + alpha * 0.4)

    -- 7. Apply shake offset + set camera CFrame
    camera.CFrame = CFrame.lookAt(smoothedPos + shakeOffset, focus)

    -- 8. อัปเดตการเคลื่อนที่ของตัวละคร
    updateMovement()
end)

-- ─── Reset on Respawn / reset เมื่อ respawn ───────────────
local function onCharacterAdded(character)
    character:WaitForChild("HumanoidRootPart")
    task.wait(0.1)
    -- ปิด default camera อีกครั้ง (Roblox reset เมื่อ respawn)
    camera.CameraType = Enum.CameraType.Scriptable
    -- ตั้ง smoothedPos ไปที่ตำแหน่งใหม่ทันที (ป้องกันกล้อง "บิน")
    local root = character:FindFirstChild("HumanoidRootPart")
    if root then
        local yr = math.rad(currentYaw)
        local pr = math.rad(currentPitch)
        local dir = Vector3.new(
            math.sin(yr) * math.cos(pr),
            math.sin(pr),
            math.cos(yr) * math.cos(pr)
        )
        smoothedPos = root.Position + HEAD_OFFSET + dir * currentDistance
    end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
    onCharacterAdded(player.Character)
end

-- ─── Listen for combat hits → small camera shake ──────────
-- รับ event ดาเมจเพื่อ shake เล็กน้อย
task.spawn(function()
    local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
    if not remoteFolder then return end
    local showDmg = remoteFolder:WaitForChild("ShowDamageNumber", 5)
    if showDmg then
        showDmg.OnClientEvent:Connect(function(position, amount, _isCrit, dmgType)
            -- Damage numbers are broadcast to everyone; shake only for a real monster hit on this player.
            local root = getRoot()
            if dmgType == "MONSTER" and (tonumber(amount) or 0) > 0 and typeof(position) == "Vector3"
                and root and (root.Position - position).Magnitude <= 4 then
                ShakeCam(0.12, 0.18)
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- API สำหรับ script อื่น / Public API for other scripts:
--   ShakeCam(intensity: number, duration: number)
--     intensity = studs of max shake  (แนะนำ 0.1–1.0)
--     duration  = seconds              (แนะนำ 0.1–0.5)
-- ═══════════════════════════════════════════════════════════
