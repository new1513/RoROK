-- ============================================================
-- CombatVFX.client.lua
-- StarterPlayerScripts — RoROK (Ragnarok M Inspired)
-- 1. แอนิเมชันฟันดาบ/แทง/ยิงธนู/ร่ายเวท (R6 Right Shoulder + WeaponGripMotor)
-- 2. เอฟเฟคสกิล 3D สไตล์ Ragnarok M (วงเวทย์ร่ายบนพื้น, คลื่นดาบโค้ง,
--    พายุหิมะ Storm Gust, ฝนอุกกาบาต Meteor Storm, วงระเบิดไฟ Magnum Break,
--    ลำแสงฮีลศักดิ์สิทธิ์, เสาฟ้าผ่า Lightning Bolt, ลูกธนูพุ่ง)
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local Debris            = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local GameData = ReplicatedStorage:WaitForChild("GameData")
local SkillData = require(GameData:WaitForChild("SkillData"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 15)
local PlayCombatVFX = RemoteEvents and RemoteEvents:WaitForChild("PlayCombatVFX", 15)

local vfxFolder = Workspace:FindFirstChild("RoROK_ClientVFX")
if not vfxFolder then
	vfxFolder = Instance.new("Folder")
	vfxFolder.Name = "RoROK_ClientVFX"
	vfxFolder.Parent = Workspace
end

local ELEMENT_COLORS = {
	Neutral = Color3.fromRGB(235, 242, 255),
	Fire    = Color3.fromRGB(255, 95, 35),
	Water   = Color3.fromRGB(65, 185, 255),
	Wind    = Color3.fromRGB(85, 245, 145),
	Earth   = Color3.fromRGB(215, 155, 75),
	Holy    = Color3.fromRGB(255, 235, 115),
	Shadow  = Color3.fromRGB(165, 90, 245),
	Ghost   = Color3.fromRGB(185, 215, 255),
	Poison  = Color3.fromRGB(145, 235, 75),
}

local function makeVFXPart(size, cf, color, shape, transparency)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.CFrame = cf
	p.Transparency = transparency or 0.15
	p.Parent = vfxFolder
	return p
end

-- ============================================================
-- 1. R6 CHARACTER SWING / CAST / BOW POSE ANIMATION
-- ============================================================
local swingAlternator = 0

local function playCharacterActionAnimation(casterPlayer, mode)
	local char = casterPlayer and casterPlayer.Character
	if not char then return end
	local torso = char:FindFirstChild("Torso")
	local rightShoulder = torso and torso:FindFirstChild("Right Shoulder")
	local leftShoulder  = torso and torso:FindFirstChild("Left Shoulder")
	if not rightShoulder then return end

	local baseRightC0 = CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
	local baseLeftC0  = CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)

	if mode == "Cast" or mode == "Heal" or mode == "Buff" then
		-- Raise both arms skyward to channel magic!
		TweenService:Create(rightShoulder, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			C0 = baseRightC0 * CFrame.Angles(0, 0, math.rad(145))
		}):Play()
		if leftShoulder then
			TweenService:Create(leftShoulder, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				C0 = baseLeftC0 * CFrame.Angles(0, 0, math.rad(-135))
			}):Play()
		end
		task.delay(0.38, function()
			if rightShoulder.Parent then
				TweenService:Create(rightShoulder, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { C0 = baseRightC0 }):Play()
			end
			if leftShoulder and leftShoulder.Parent then
				TweenService:Create(leftShoulder, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { C0 = baseLeftC0 }):Play()
			end
		end)
	elseif mode == "Bow" then
		-- Authentic Archery: Left hand holds bow aimed forward, Right hand draws string back to cheek!
		if leftShoulder then
			TweenService:Create(leftShoulder, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				C0 = baseLeftC0 * CFrame.Angles(0, math.rad(-15), math.rad(-90))
			}):Play()
		end
		TweenService:Create(rightShoulder, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			C0 = baseRightC0 * CFrame.Angles(math.rad(24), math.rad(-28), math.rad(48))
		}):Play()

		task.delay(0.24, function()
			if rightShoulder and rightShoulder.Parent then
				TweenService:Create(rightShoulder, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { C0 = baseRightC0 }):Play()
			end
			if leftShoulder and leftShoulder.Parent then
				TweenService:Create(leftShoulder, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { C0 = baseLeftC0 }):Play()
			end
		end)
	else
		-- Melee Slash Combo (alternating overhead cleave & wide horizontal slash)
		swingAlternator = (swingAlternator + 1) % 2
		if swingAlternator == 0 then
			-- Windup high -> Fast overhead cleave
			rightShoulder.C0 = baseRightC0 * CFrame.Angles(math.rad(-20), 0, math.rad(135))
			TweenService:Create(rightShoulder, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				C0 = baseRightC0 * CFrame.Angles(math.rad(15), 0, math.rad(25))
			}):Play()
		else
			-- Wide horizontal cross-slash
			rightShoulder.C0 = baseRightC0 * CFrame.Angles(0, math.rad(-45), math.rad(95))
			TweenService:Create(rightShoulder, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				C0 = baseRightC0 * CFrame.Angles(0, math.rad(55), math.rad(75))
			}):Play()
		end
		-- เปิด SlashTrail บนตัวอาวุธเฉพาะตอนฟัน 0.22 วินาที แล้วปิดกลับทันที ไม่เกิดรอยขาวค้างขณะเดิน
		local rig = char:FindFirstChild("RoROK_WeaponRig")
		local trail = rig and rig:FindFirstChildWhichIsA("BasePart") and rig:FindFirstChildWhichIsA("BasePart"):FindFirstChild("SlashTrail")
		if trail then trail.Enabled = true end

		task.delay(0.22, function()
			if trail and trail.Parent then trail.Enabled = false end
			if rightShoulder.Parent then
				TweenService:Create(rightShoulder, TweenInfo.new(0.16), { C0 = baseRightC0 }):Play()
			end
		end)
	end
end

-- ============================================================
-- 2. 3D SLASH CRESCENT, ARROWS, MAGIC CIRCLES & ELEMENTAL SPELLS
-- ============================================================
local function spawnImpactBurst(pos, color, scale)
	scale = scale or 1
	local ring = makeVFXPart(Vector3.new(0.2, 1.5 * scale, 1.5 * scale), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.PartType.Cylinder, 0.1)
	TweenService:Create(ring, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.08, 7.5 * scale, 7.5 * scale),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, 0.36)

	for i = 1, 5 do
		local ang = math.rad(i * 72 + math.random(-15, 15))
		local dir = Vector3.new(math.cos(ang), 0.55, math.sin(ang)).Unit
		local spark = makeVFXPart(Vector3.new(0.35 * scale, 0.35 * scale, 1.2 * scale), CFrame.lookAt(pos, pos + dir), color)
		TweenService:Create(spark, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = CFrame.lookAt(pos + dir * (3.8 * scale), pos + dir * (5 * scale)),
			Size = Vector3.new(0.08, 0.08, 0.3),
			Transparency = 1,
		}):Play()
		Debris:AddItem(spark, 0.32)
	end
end

local function spawnGroundMagicCircle(centerPos, color, radius, duration)
	duration = duration or 0.85
	local yPos = Vector3.new(centerPos.X, centerPos.Y - 2.2, centerPos.Z)
	local outer = makeVFXPart(Vector3.new(0.12, 1, 1), CFrame.new(yPos) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.PartType.Cylinder, 0.25)
	TweenService:Create(outer, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.12, radius * 2, radius * 2),
	}):Play()

	local runeBar1 = makeVFXPart(Vector3.new(radius * 1.75, 0.14, 0.35), CFrame.new(yPos), color, Enum.PartType.Block, 0.2)
	local runeBar2 = makeVFXPart(Vector3.new(0.35, 0.14, radius * 1.75), CFrame.new(yPos), color, Enum.PartType.Block, 0.2)

	TweenService:Create(runeBar1, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(yPos) * CFrame.Angles(0, math.rad(120), 0),
		Transparency = 1,
	}):Play()
	TweenService:Create(runeBar2, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(yPos) * CFrame.Angles(0, math.rad(120), 0),
		Transparency = 1,
	}):Play()
	task.delay(duration * 0.65, function()
		if outer.Parent then
			TweenService:Create(outer, TweenInfo.new(duration * 0.35), { Transparency = 1 }):Play()
		end
	end)
	Debris:AddItem(outer, duration + 0.05)
	Debris:AddItem(runeBar1, duration + 0.05)
	Debris:AddItem(runeBar2, duration + 0.05)
end

local function spawnSlashWave(casterRoot, targetPos, color, scale)
	scale = scale or 1
	local startPos = casterRoot.Position + Vector3.new(0, 0.5, 0)
	local flatDir = Vector3.new(targetPos.X - startPos.X, 0, targetPos.Z - startPos.Z)
	if flatDir.Magnitude < 0.1 then flatDir = casterRoot.CFrame.LookVector end
	flatDir = flatDir.Unit

	local tilt = (swingAlternator == 0) and math.rad(28) or math.rad(-28)
	local slashCF = CFrame.lookAt(startPos + flatDir * 2.2, startPos + flatDir * 6) * CFrame.Angles(0, 0, tilt)
	local arc = makeVFXPart(Vector3.new(4.2 * scale, 0.22 * scale, 1.6 * scale), slashCF, color, Enum.PartType.Block, 0.1)

	TweenService:Create(arc, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = slashCF * CFrame.new(0, 0, -2.6 * scale),
		Size = Vector3.new(5.6 * scale, 0.08, 2.2 * scale),
		Transparency = 1,
	}):Play()
	Debris:AddItem(arc, 0.24)
end

local function spawnArrowProjectile(startPos, targetPos, color)
	local dist = (targetPos - startPos).Magnitude
	local dur = math.clamp(dist / 85, 0.08, 0.28)
	local arrow = makeVFXPart(Vector3.new(0.18, 0.18, 2.6), CFrame.lookAt(startPos, targetPos), color, Enum.PartType.Block, 0.05)
	TweenService:Create(arrow, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
		CFrame = CFrame.lookAt(targetPos, targetPos + (targetPos - startPos).Unit),
	}):Play()
	Debris:AddItem(arrow, dur + 0.04)
end

local function playSkillVFX(casterPlayer, targetPos, skillId)
	local char = casterPlayer and casterPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local sDef = SkillData[skillId] or {}
	local el = sDef.element or (casterPlayer:GetAttribute("CoatedElement")) or "Neutral"
	local color = ELEMENT_COLORS[el] or ELEMENT_COLORS.Neutral
	local className = casterPlayer:GetAttribute("Class") or "Novice"

	if sDef.isHeal then
		playCharacterActionAnimation(casterPlayer, "Heal")
		local healColor = Color3.fromRGB(85, 255, 155)
		spawnGroundMagicCircle(root.Position, healColor, 4.5, 0.9)
		local pillar = makeVFXPart(Vector3.new(28, 3.2, 3.2), CFrame.new(root.Position + Vector3.new(0, 6, 0)) * CFrame.Angles(0, 0, math.rad(90)), healColor, Enum.PartType.Cylinder, 0.35)
		TweenService:Create(pillar, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(28, 0.2, 0.2),
			Transparency = 1,
		}):Play()
		Debris:AddItem(pillar, 0.7)
		return
	elseif sDef.isBuff then
		playCharacterActionAnimation(casterPlayer, "Buff")
		local buffColor = Color3.fromRGB(255, 220, 95)
		spawnGroundMagicCircle(root.Position, buffColor, 4.2, 0.85)
		spawnImpactBurst(root.Position + Vector3.new(0, 1, 0), buffColor, 1.1)
		return
	end

	-- Specific Iconic Ragnarok M Skill Visuals
	if skillId == "StormGust" then
		playCharacterActionAnimation(casterPlayer, "Cast")
		local iceColor = Color3.fromRGB(95, 215, 255)
		spawnGroundMagicCircle(root.Position, iceColor, 4.0, 0.75)
		spawnGroundMagicCircle(targetPos, iceColor, sDef.aoeRadius or 12, 1.35)
		for i = 1, 8 do
			task.delay((i - 1) * 0.08, function()
				local ox = math.random(-8, 8)
				local oz = math.random(-8, 8)
				local dropStart = targetPos + Vector3.new(ox, 16, oz)
				local dropEnd   = targetPos + Vector3.new(ox, 0.5, oz)
				local shard = makeVFXPart(Vector3.new(1.1, 3.8, 1.1), CFrame.new(dropStart), iceColor, Enum.PartType.Block, 0.15)
				TweenService:Create(shard, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					CFrame = CFrame.new(dropEnd),
				}):Play()
				task.delay(0.28, function()
					spawnImpactBurst(dropEnd, iceColor, 0.85)
				end)
				Debris:AddItem(shard, 0.55)
			end)
		end
	elseif skillId == "MeteorStorm" then
		playCharacterActionAnimation(casterPlayer, "Cast")
		local fireColor = Color3.fromRGB(255, 95, 35)
		spawnGroundMagicCircle(root.Position, fireColor, 4.2, 0.8)
		spawnGroundMagicCircle(targetPos, fireColor, sDef.aoeRadius or 14, 1.5)
		for i = 1, 6 do
			task.delay((i - 1) * 0.11, function()
				local ox = math.random(-9, 9)
				local oz = math.random(-9, 9)
				local hitPos = targetPos + Vector3.new(ox, 0.5, oz)
				local skyPos = hitPos + Vector3.new(-8, 24, -6)
				local meteor = makeVFXPart(Vector3.new(3.2, 3.2, 3.2), CFrame.new(skyPos), fireColor, Enum.PartType.Ball, 0.05)
				TweenService:Create(meteor, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					CFrame = CFrame.new(hitPos),
				}):Play()
				task.delay(0.32, function()
					spawnImpactBurst(hitPos, fireColor, 1.5)
				end)
				Debris:AddItem(meteor, 0.4)
			end)
		end
	elseif skillId == "MagnumBreak" or skillId == "CartRevolution" then
		playCharacterActionAnimation(casterPlayer, "Slash")
		local radius = sDef.aoeRadius or 10
		spawnGroundMagicCircle(root.Position, color, radius, 0.7)
		spawnSlashWave(root, targetPos, color, 1.65)
		spawnImpactBurst(root.Position, color, 1.8)
	elseif skillId == "FireBolt" or skillId == "ColdBolt" or skillId == "LightningBolt" or skillId == "HolyLight" then
		playCharacterActionAnimation(casterPlayer, "Cast")
		spawnGroundMagicCircle(root.Position, color, 3.6, 0.65)
		for i = 1, 3 do
			task.delay((i - 1) * 0.09, function()
				local beam = makeVFXPart(Vector3.new(22, 1.4, 1.4), CFrame.new(targetPos + Vector3.new(0, 10, 0)) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.PartType.Cylinder, 0.15)
				TweenService:Create(beam, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = Vector3.new(22, 0.1, 0.1),
					Transparency = 1,
				}):Play()
				Debris:AddItem(beam, 0.26)
				spawnImpactBurst(targetPos, color, 0.95)
			end)
		end
	elseif className == "Archer" or className == "Hunter" or skillId == "DoubleStrafe" or skillId == "ArrowShower" or skillId == "BlitzBeat" or skillId == "FalconAssault" then
		playCharacterActionAnimation(casterPlayer, "Bow")
		local arrowCount = (skillId == "ArrowShower") and 5 or ((skillId == "FalconAssault" or skillId == "BlitzBeat") and 3 or 2)
		for i = 1, arrowCount do
			task.delay((i - 1) * 0.07, function()
				local offset = (arrowCount > 2) and Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)) or Vector3.zero
				spawnArrowProjectile(root.Position + Vector3.new(0, 1.2, 0), targetPos + offset, Color3.fromRGB(135, 255, 165))
				spawnImpactBurst(targetPos + offset, Color3.fromRGB(135, 255, 165), 0.75)
			end)
		end
	else
		-- Melee Physical Skills (Bash, Backstab, Envenom, Mammonite, NoviceStrike)
		playCharacterActionAnimation(casterPlayer, "Slash")
		local slashColor = (skillId == "Mammonite") and Color3.fromRGB(255, 215, 65)
			or ((skillId == "Envenom") and Color3.fromRGB(155, 240, 80) or color)
		spawnSlashWave(root, targetPos, slashColor, 1.35)
		spawnImpactBurst(targetPos, slashColor, 1.2)
	end
end

if PlayCombatVFX then
	PlayCombatVFX.OnClientEvent:Connect(function(kind, casterPlayer, targetPos, param1, param2)
		if typeof(targetPos) ~= "Vector3" then return end
		if kind == "BasicAttack" then
			local char = casterPlayer and casterPlayer.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not root then return end
			local className = casterPlayer:GetAttribute("Class") or "Novice"
			local elColor = ELEMENT_COLORS[tostring(param1 or "Neutral")] or ELEMENT_COLORS.Neutral
			if param2 == true then
				elColor = Color3.fromRGB(255, 220, 65) -- Critical golden slash!
			end

			if className == "Archer" or className == "Hunter" then
				playCharacterActionAnimation(casterPlayer, "Bow")
				spawnArrowProjectile(root.Position + Vector3.new(0, 1, 0), targetPos, elColor)
			elseif className == "Mage" or className == "Wizard" or className == "Priest" or className == "Acolyte" then
				playCharacterActionAnimation(casterPlayer, "Cast")
				spawnArrowProjectile(root.Position + Vector3.new(0, 1.5, 0), targetPos, Color3.fromRGB(145, 195, 255))
			else
				playCharacterActionAnimation(casterPlayer, "Slash")
				spawnSlashWave(root, targetPos, elColor, param2 and 1.35 or 1.0)
			end
			spawnImpactBurst(targetPos, elColor, param2 and 1.25 or 0.8)
		elseif kind == "Skill" then
			playSkillVFX(casterPlayer, targetPos, tostring(param1 or "NoviceStrike"))
		end
	end)
end

print("[CombatVFX] 3D Slash, Bow, Cast Animations & Ragnarok M Skill VFX initialized!")
