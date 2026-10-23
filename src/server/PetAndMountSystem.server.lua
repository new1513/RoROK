-- ============================================================
-- PetAndMountSystem.server.lua
-- ServerScriptService — RoROK (Ragnarok Online-inspired MMORPG)
-- ระบบสัตว์ขี่ (Peco Peco Mount) และสัตว์เลี้ยงคู่ใจ (Pet System)
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local Debris            = game:GetService("Debris")

local DataStore
local GameManager

local t0 = tick()
repeat
	task.wait(0.1)
	DataStore = _G.DataStore
	GameManager = _G.GameManager
until (DataStore and GameManager) or (tick() - t0 > 15)

local remotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local function getRemote(name)
	local r = remotesFolder:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = remotesFolder
	end
	return r
end

local RE_ToggleMount     = getRemote("ToggleMount")
local RE_SummonPet       = getRemote("SummonPet")
local RE_DismissPet      = getRemote("DismissPet")
local RE_SkillFeedback   = getRemote("SkillFeedback")

local petsFolder = Workspace:FindFirstChild("RoROK_ActivePets")
if petsFolder then petsFolder:Destroy() end
petsFolder = Instance.new("Folder")
petsFolder.Name = "RoROK_ActivePets"
petsFolder.Parent = Workspace

local activePets = {}   -- [userId] = petModel
local mountedState = {} -- [userId] = bool

-- ── 1. PECO PECO MOUNT SYSTEM ─────────────────────────────────
local function toggleMount(player)
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end

	local playerClass = player:GetAttribute("Class") or "Novice"
	if playerClass ~= "Knight" and playerClass ~= "LordKnight" then
		RE_SkillFeedback:FireClient(player, "⚠️ สัตว์ขี่ Peco Peco สามารถขี่ได้เฉพาะคลาส Knight และ Lord Knight เท่านั้น")
		return
	end

	local isCurrentlyMounted = mountedState[player.UserId] or false

	if isCurrentlyMounted then
		-- Dismount
		mountedState[player.UserId] = false
		player:SetAttribute("IsMounted", false)
		humanoid.WalkSpeed = 16

		local oldMount = char:FindFirstChild("PecoPecoMount")
		if oldMount then oldMount:Destroy() end

		RE_SkillFeedback:FireClient(player, "ลงจากสัตว์ขี่ Peco Peco แล้ว (ความเร็วเดินปกติ)")
	else
		-- Mount
		mountedState[player.UserId] = true
		player:SetAttribute("IsMounted", true)
		humanoid.WalkSpeed = 24 -- +50% movement speed!

		local mountModel = Instance.new("Model")
		mountModel.Name = "PecoPecoMount"

		local body = Instance.new("Part")
		body.Name = "MountBody"
		body.Size = Vector3.new(2.8, 2.2, 3.4)
		body.Material = Enum.Material.SmoothPlastic
		body.Color = Color3.fromRGB(245, 195, 45) -- Peco Peco yellow
		body.CanCollide = false
		body.Massless = true
		body.Parent = mountModel

		local head = Instance.new("Part")
		head.Name = "MountHead"
		head.Size = Vector3.new(1.4, 1.6, 1.8)
		head.Material = Enum.Material.SmoothPlastic
		head.Color = Color3.fromRGB(255, 215, 60)
		head.CanCollide = false
		head.Massless = true
		head.Parent = mountModel

		local beak = Instance.new("Part")
		beak.Name = "MountBeak"
		beak.Size = Vector3.new(0.8, 0.6, 1.2)
		beak.Material = Enum.Material.SmoothPlastic
		beak.Color = Color3.fromRGB(240, 110, 30)
		beak.CanCollide = false
		beak.Massless = true
		beak.Parent = mountModel

		-- Weld parts to RootPart
		local weldBody = Instance.new("WeldConstraint")
		weldBody.Part0 = root
		weldBody.Part1 = body
		body.CFrame = root.CFrame * CFrame.new(0, -1.2, 0.4)
		weldBody.Parent = body

		local weldHead = Instance.new("WeldConstraint")
		weldHead.Part0 = body
		weldHead.Part1 = head
		head.CFrame = body.CFrame * CFrame.new(0, 1.2, 1.8)
		weldHead.Parent = head

		local weldBeak = Instance.new("WeldConstraint")
		weldBeak.Part0 = head
		weldBeak.Part1 = beak
		beak.CFrame = head.CFrame * CFrame.new(0, -0.2, 1.1)
		weldBeak.Parent = beak

		mountModel.Parent = char
		RE_SkillFeedback:FireClient(player, "🐤 ขี่ Peco Peco สำเร็จ! ความเร็วเคลื่อนที่เพิ่มขึ้น +50%")
	end
end

RE_ToggleMount.OnServerEvent:Connect(toggleMount)

-- ── 2. PET TAMING & SUMMON SYSTEM ─────────────────────────────
local function summonPet(player, petType)
	-- Remove old pet if active
	if activePets[player.UserId] then
		activePets[player.UserId]:Destroy()
		activePets[player.UserId] = nil
	end

	petType = petType or "Poring"
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local pet = Instance.new("Model")
	pet.Name = "Pet_" .. player.Name
	pet.Parent = petsFolder

	local petBody = Instance.new("Part")
	petBody.Name = "HumanoidRootPart"
	petBody.Size = Vector3.new(1.8, 1.8, 1.8)
	petBody.Shape = Enum.PartType.Ball
	petBody.Material = Enum.Material.SmoothPlastic
	petBody.CanCollide = false
	petBody.Anchored = true
	petBody.CFrame = root.CFrame * CFrame.new(-4, 0, -4)

	if petType == "Lunatic" then
		petBody.Color = Color3.fromRGB(210, 180, 245) -- Lunatic purple
	else
		petBody.Color = Color3.fromRGB(255, 120, 175) -- Poring pink
	end
	petBody.Parent = pet
	pet.PrimaryPart = petBody

	-- Overhead Pet Billboard
	local bb = Instance.new("BillboardGui")
	bb.Name = "PetBillboard"
	bb.Size = UDim2.new(0, 180, 0, 36)
	bb.StudsOffset = Vector3.new(0, 1.8, 0)
	bb.MaxDistance = 35
	bb.AlwaysOnTop = false
	bb.Parent = petBody

	local bbText = Instance.new("TextLabel")
	bbText.Size = UDim2.new(1, 0, 1, 0)
	bbText.BackgroundTransparency = 1
	bbText.Text = (petType == "Lunatic" and "🐰 Lunatic Pet\n[FLEE +8 • Crit +3]" or "🌸 Poring Pet\n[LUK +5 • Drop +10%]")
	bbText.TextColor3 = Color3.fromRGB(255, 235, 140)
	bbText.TextStrokeTransparency = 0.2
	bbText.Font = Enum.Font.GothamBold
	bbText.TextSize = 11
	bbText.Parent = bb

	activePets[player.UserId] = pet
	player:SetAttribute("ActivePet", petType)

	RE_SkillFeedback:FireClient(player, string.format("🐾 อัญเชิญสัตว์เลี้ยง %s สำเร็จ! ได้รับบัพติดตัวแล้ว", petType))
end

local function dismissPet(player)
	if activePets[player.UserId] then
		activePets[player.UserId]:Destroy()
		activePets[player.UserId] = nil
	end
	player:SetAttribute("ActivePet", nil)
	RE_SkillFeedback:FireClient(player, "เก็บสัตว์เลี้ยงกลับเรียบร้อย")
end

RE_SummonPet.OnServerEvent:Connect(summonPet)
RE_DismissPet.OnServerEvent:Connect(dismissPet)

-- ── 3. PET FOLLOW LOOP (Heartbeat Smooth Follow) ──────────────
RunService.Heartbeat:Connect(function()
	for userId, pet in pairs(activePets) do
		local player = Players:GetPlayerByUserId(userId)
		local char = player and player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local petPart = pet and pet.PrimaryPart

		if root and petPart then
			-- Follow target position: behind left of player
			local targetPos = (root.CFrame * CFrame.new(-3.5, -0.6, -3.5)).Position
			local curPos = petPart.Position
			local newPos = curPos:Lerp(targetPos, 0.12)
			petPart.CFrame = CFrame.new(newPos, root.Position)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if activePets[player.UserId] then
		activePets[player.UserId]:Destroy()
		activePets[player.UserId] = nil
	end
	mountedState[player.UserId] = nil
end)

_G.PetAndMountSystem = {
	ToggleMount = toggleMount,
	SummonPet   = summonPet,
	DismissPet  = dismissPet,
}

print("[PetAndMountSystem] Peco Peco Mount & Pet Taming system initialized successfully")
