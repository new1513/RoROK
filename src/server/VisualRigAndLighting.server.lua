-- ============================================================
-- VisualRigAndLighting.server.lua
-- ServerScriptService — RoROK (Ragnarok M Inspired)
-- 1. จัดแสงสีและบรรยากาศแบบ Fantasy MMORPG (Atmosphere, Bloom,
--    ColorCorrection, SunRays)
-- 2. สร้างโมเดลอาวุธและโล่ 3D จริงจับในฝ่ามือตัวละครพอดีเป๊ะ ไม่ลอย
--    (Sword, TwoHandSword, Bow, Staff/Rod, Mace, Axe, Katar, Dagger + Shield)
-- 3. ลบของตกแต่งที่วางขวางถนนออกทั้งหมด และสร้าง "ลานฝึกใช้อาวุธและสกิล"
--    ตรงสนามหญ้าข้างถนนสายเข้าปราสาท หลังโรงคราฟต์อุปกรณ์ (X = 14..54, Z = -60..-132)
--    พร้อมหุ่นฟางฝึกซ้อม 6 ตัว และ NPC ครูฝึกอาวุธหลวงให้เควสฝึกใช้อาวุธ!
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")
local ServerStorage     = game:GetService("ServerStorage")

local GameData = ReplicatedStorage:WaitForChild("GameData")
local ItemData = require(GameData:WaitForChild("ItemData"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 15)
if RemoteEvents and not RemoteEvents:FindFirstChild("PlayCombatVFX") then
	local re = Instance.new("RemoteEvent")
	re.Name = "PlayCombatVFX"
	re.Parent = RemoteEvents
end

-- ============================================================
-- 1. FANTASY MMORPG LIGHTING & ATMOSPHERE (Ragnarok M Vibe)
-- ============================================================
local function setupAtmosphereAndLighting()
	pcall(function() Lighting.Technology = Enum.Technology.ShadowMap end)
	Lighting.GlobalShadows = true
	Lighting.Brightness = 2.25
	Lighting.ClockTime = 15.0
	Lighting.GeographicLatitude = 28
	Lighting.Ambient = Color3.fromRGB(102, 110, 128)
	Lighting.OutdoorAmbient = Color3.fromRGB(145, 154, 175)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 240, 210)
	Lighting.ColorShift_Bottom = Color3.fromRGB(78, 90, 118)
	Lighting.EnvironmentDiffuseScale = 0.65
	Lighting.EnvironmentSpecularScale = 0.75

	-- ล้างเอฟเฟคแสงเก่าทุกตัวรวมถึง RoROK_TownAtmosphere ที่ซ้ำซ้อน
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Atmosphere") or child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") or child:IsA("SunRaysEffect") then
			child:Destroy()
		end
	end

	local atmo = Instance.new("Atmosphere")
	atmo.Name = "RoROK_Atmosphere"
	atmo.Density = 0.20
	atmo.Offset = 0.10
	atmo.Color = Color3.fromRGB(205, 224, 252)
	atmo.Decay = Color3.fromRGB(148, 170, 210)
	atmo.Glare = 0.12
	atmo.Haze = 0.95
	atmo.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "RoROK_Bloom"
	bloom.Intensity = 0.35
	bloom.Size = 22
	bloom.Threshold = 1.75
	bloom.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "RoROK_ColorCorrection"
	cc.Brightness = 0.02
	cc.Contrast = 0.10
	cc.Saturation = 0.15
	cc.TintColor = Color3.fromRGB(255, 250, 244)
	cc.Parent = Lighting

	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Name = "RoROK_SunRays"
	sunRays.Intensity = 0.08
	sunRays.Spread = 0.55
	sunRays.Parent = Lighting
end
setupAtmosphereAndLighting()

-- ============================================================
-- 2. 3D WEAPON & SHIELD MODELS HELD FIRMLY IN HAND (NO FLOATING!)
-- ============================================================
local ELEMENT_COLORS = {
	Fire   = Color3.fromRGB(255, 95, 35),
	Water  = Color3.fromRGB(55, 165, 255),
	Wind   = Color3.fromRGB(75, 235, 130),
	Earth  = Color3.fromRGB(205, 145, 65),
	Holy   = Color3.fromRGB(255, 235, 120),
	Shadow = Color3.fromRGB(155, 85, 235),
}

local function makePart(parent, name, size, color, material, shape, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Metal
	p.Shape = shape or Enum.PartType.Block
	p.Transparency = transparency or 0
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function weldParts(p0, p1, offsetCF)
	p1.CFrame = p0.CFrame * offsetCF
	local w = Instance.new("WeldConstraint")
	w.Part0 = p0
	w.Part1 = p1
	w.Parent = p1
	return w
end

local function getDefaultWeaponTypeForClass(className)
	if className == "Knight" then return "Sword"
	elseif className == "LordKnight" then return "TwoHandSpear"
	elseif className == "Mage" or className == "Wizard" then return "Staff"
	elseif className == "Acolyte" or className == "Priest" then return "Mace"
	elseif className == "Archer" or className == "Hunter" then return "Bow"
	elseif className == "Thief" or className == "Assassin" then return "Katar"
	elseif className == "Merchant" then return "Axe"
	elseif className == "Blacksmith" then return "TwoHandAxe"
	else return "Dagger" end
end

local function rebuildCharacterWeaponRig(player)
	local char = player.Character
	if not char then return end
	local rightArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
	local leftArm  = char:FindFirstChild("Left Arm") or char:FindFirstChild("LeftHand")
	if not rightArm then return end

	local oldRig = char:FindFirstChild("RoROK_WeaponRig")
	if oldRig then oldRig:Destroy() end
	local oldMotor = rightArm:FindFirstChild("WeaponGripMotor")
	if oldMotor then oldMotor:Destroy() end

	local rigFolder = Instance.new("Model")
	rigFolder.Name = "RoROK_WeaponRig"
	rigFolder.Parent = char

	local data = _G.DataStore and _G.DataStore.GetPlayerData(player)
	local eqWeaponId = data and data.Equipment and data.Equipment.Weapon
	local eqShieldId = data and data.Equipment and data.Equipment.Shield
	local refineLv = (data and data.EquipmentRefine and data.EquipmentRefine.Weapon) or 0
	local weaponDef = eqWeaponId and (ItemData[eqWeaponId] or (ItemData.Items and ItemData.Items[eqWeaponId]))
	local weaponType = (weaponDef and weaponDef.weaponType) or getDefaultWeaponTypeForClass(player:GetAttribute("Class") or (data and data.Class) or "Novice")
	local coatedEl = player:GetAttribute("CoatedElement") or ""

	rigFolder:SetAttribute("WeaponType", weaponType)

	local isR6 = (rightArm.Name == "Right Arm")
	local handY = isR6 and -0.95 or -0.15
	local bowHandY = isR6 and -0.90 or -0.15

	local WEAPON_MESH_DEFS = {
		Sword = {
			meshId = "http://www.roblox.com/asset/?id=94746028", texId = "http://www.roblox.com/asset/?ID=94746105",
			scale = Vector3.new(1.15, 1.15, 1.15), size = Vector3.new(0.6, 3.6, 0.4), arm = "Right Arm",
			gripC0 = CFrame.new(0, handY, 0) * CFrame.Angles(math.rad(-90), 0, 0), gripC1 = CFrame.new(0, -1.25, 0),
		},
		TwoHandSword = {
			meshId = "http://www.roblox.com/asset/?id=94746028", texId = "http://www.roblox.com/asset/?ID=94746105",
			scale = Vector3.new(1.4, 1.45, 1.4), size = Vector3.new(0.7, 4.4, 0.5), arm = "Right Arm",
			gripC0 = CFrame.new(0, handY, 0) * CFrame.Angles(math.rad(-90), 0, 0), gripC1 = CFrame.new(0, -1.45, 0),
		},
		Spear = {
			meshId = "http://www.roblox.com/asset/?id=94746028", texId = "http://www.roblox.com/asset/?ID=94746105",
			scale = Vector3.new(0.95, 1.65, 0.95), size = Vector3.new(0.5, 4.8, 0.5), arm = "Right Arm",
			gripC0 = CFrame.new(0, handY, 0) * CFrame.Angles(math.rad(-90), 0, 0), gripC1 = CFrame.new(0, -1.15, 0),
		},
		TwoHandSpear = {
			meshId = "http://www.roblox.com/asset/?id=94746028", texId = "http://www.roblox.com/asset/?ID=94746105",
			scale = Vector3.new(1.15, 1.85, 1.15), size = Vector3.new(0.6, 5.4, 0.6), arm = "Right Arm",
			gripC0 = CFrame.new(0, handY, 0) * CFrame.Angles(math.rad(-90), 0, 0), gripC1 = CFrame.new(0, -1.25, 0),
		},
		Dagger = {
			meshId = "http://www.roblox.com/asset/?id=94746028", texId = "http://www.roblox.com/asset/?ID=94746105",
			scale = Vector3.new(0.85, 0.78, 0.85), size = Vector3.new(0.4, 2.3, 0.3), arm = "Right Arm",
			gripC0 = CFrame.new(0, handY, 0) * CFrame.Angles(math.rad(-90), 0, 0), gripC1 = CFrame.new(0, -0.85, 0),
		},
		Katar = {
			meshId = "http://www.roblox.com/asset/?id=94746028", texId = "http://www.roblox.com/asset/?ID=94746105",
			scale = Vector3.new(0.95, 0.85, 0.95), size = Vector3.new(0.5, 2.4, 0.4), arm = "Right Arm",
			gripC0 = CFrame.new(0, handY, 0) * CFrame.Angles(math.rad(-90), 0, 0), gripC1 = CFrame.new(0, -0.55, 0),
		},
		Staff = {
			meshId = "http://www.roblox.com/asset?id=181326949", texId = "http://www.roblox.com/asset?id=181326992",
			scale = Vector3.new(1.0, 1.0, 1.0), size = Vector3.new(0.5, 4.25, 1.0), arm = "Right Arm",
			gripC0 = CFrame.new(0, handY, 0) * CFrame.Angles(math.rad(-90), 0, 0), gripC1 = CFrame.new(0, -0.85, 0),
		},
		Rod = {
			meshId = "http://www.roblox.com/asset?id=181326949", texId = "http://www.roblox.com/asset?id=181326992",
			scale = Vector3.new(0.85, 0.85, 0.85), size = Vector3.new(0.4, 3.6, 0.8), arm = "Right Arm",
			gripC0 = CFrame.new(0, handY, 0) * CFrame.Angles(math.rad(-90), 0, 0), gripC1 = CFrame.new(0, -0.75, 0),
		},
		Axe = {
			meshId = "http://www.roblox.com/asset?id=145815658", texId = "http://www.roblox.com/asset/?id=186913315",
			scale = Vector3.new(1.0, 0.75, 1.0), size = Vector3.new(0.6, 3.4, 1.0), arm = "Right Arm",
			gripC0 = CFrame.new(0, handY, 0) * CFrame.Angles(math.rad(-90), 0, 0), gripC1 = CFrame.new(0, -1.05, 0),
		},
		TwoHandAxe = {
			meshId = "http://www.roblox.com/asset?id=145815658", texId = "http://www.roblox.com/asset/?id=186913315",
			scale = Vector3.new(1.25, 0.95, 1.25), size = Vector3.new(0.7, 4.2, 1.2), arm = "Right Arm",
			gripC0 = CFrame.new(0, handY, 0) * CFrame.Angles(math.rad(-90), 0, 0), gripC1 = CFrame.new(0, -1.25, 0),
		},
		Mace = {
			meshId = "http://www.roblox.com/asset?id=145815658", texId = "http://www.roblox.com/asset/?id=186913315",
			scale = Vector3.new(0.95, 0.72, 0.95), size = Vector3.new(0.6, 3.2, 0.9), arm = "Right Arm",
			gripC0 = CFrame.new(0, handY, 0) * CFrame.Angles(math.rad(-90), 0, 0), gripC1 = CFrame.new(0, -1.0, 0),
		},
		Bow = {
			meshId = "http://www.roblox.com/asset/?id=283706818", texId = "",
			scale = Vector3.new(1.35, 1.35, 1.35), size = Vector3.new(0.6, 3.8, 1.2), arm = "Left Arm",
			gripC0 = CFrame.new(0, bowHandY, 0) * CFrame.Angles(math.rad(-90), 0, math.rad(90)), gripC1 = CFrame.new(0, 0, 0),
		},
	}

	local mDef = WEAPON_MESH_DEFS[weaponType] or WEAPON_MESH_DEFS.Sword
	local handle = makePart(rigFolder, "WeaponHandle", mDef.size, Color3.fromRGB(165, 122, 72), Enum.Material.Wood)
	rigFolder.PrimaryPart = handle

	local sm = Instance.new("SpecialMesh")
	sm.MeshType = Enum.MeshType.FileMesh
	sm.MeshId = mDef.meshId
	if mDef.texId and mDef.texId ~= "" then
		sm.TextureId = mDef.texId
	end
	sm.Scale = mDef.scale
	sm.Parent = handle

	-- R6 Weapon Grip Weld: attaches cleanly to appropriate arm (Left Arm for bow, Right Arm for melee/staff)
	local attachArm = (mDef.arm == "Left Arm" and leftArm) or rightArm
	local weaponGrip = Instance.new("Weld")
	weaponGrip.Name = "WeaponGripWeld"
	weaponGrip.Part0 = attachArm
	weaponGrip.Part1 = handle
	weaponGrip.C0 = mDef.gripC0
	weaponGrip.C1 = mDef.gripC1
	weaponGrip.Parent = handle

	local bladePart = handle

	if bladePart then
		local att0 = Instance.new("Attachment")
		att0.Name = "TrailBase"
		att0.Position = Vector3.new(0, -bladePart.Size.Y * 0.45, 0)
		att0.Parent = bladePart

		local att1 = Instance.new("Attachment")
		att1.Name = "TrailTip"
		att1.Position = Vector3.new(0, bladePart.Size.Y * 0.48, 0)
		att1.Parent = bladePart

		local trailColor = ELEMENT_COLORS[coatedEl] or (refineLv >= 7 and Color3.fromRGB(255, 215, 85) or Color3.fromRGB(215, 235, 255))
		local trail = Instance.new("Trail")
		trail.Name = "SlashTrail"
		trail.Attachment0 = att0
		trail.Attachment1 = att1
		trail.Lifetime = 0.20
		trail.LightEmission = 0.85
		trail.Color = ColorSequence.new(trailColor)
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.18),
			NumberSequenceKeypoint.new(1, 1),
		})
		trail.Enabled = false -- ปิดไว้ตลอดเวลาขณะเดิน/ยืน เปิดเฉพาะตอนกวัดแกว่งอาวุธโจมตี
		trail.Parent = bladePart

		if ELEMENT_COLORS[coatedEl] or refineLv >= 5 then
			local glowColor = ELEMENT_COLORS[coatedEl] or Color3.fromRGB(255, 210, 75)
			bladePart.Color = glowColor
			bladePart.Material = Enum.Material.Neon
			local pl = Instance.new("PointLight")
			pl.Color = glowColor
			pl.Range = 8
			pl.Brightness = 1.2
			pl.Parent = bladePart
		end
	end

	local TwoHandedTypes = {
		TwoHandSword = true, TwoHandSpear = true, TwoHandAxe = true,
		Bow = true, Katar = true, Staff = true,
	}
	local curClass = player:GetAttribute("Class") or (data and data.Class) or "Novice"
	local canShowShield = (not TwoHandedTypes[weaponType]) and (eqShieldId ~= nil or curClass == "Knight" or curClass == "LordKnight")
	if leftArm and canShowShield then
		local shield = makePart(rigFolder, "BucklerShield", Vector3.new(0.28, 1.95, 1.45), Color3.fromRGB(52, 76, 128), Enum.Material.Metal)
		local sWeld = Instance.new("Weld")
		sWeld.Name = "ShieldGripWeld"
		sWeld.Part0 = leftArm
		sWeld.Part1 = shield
		sWeld.C0 = CFrame.new(-0.56, isR6 and -0.25 or 0, 0)
		sWeld.Parent = shield

		local rim = makePart(rigFolder, "ShieldCrest", Vector3.new(0.34, 1.05, 0.75), Color3.fromRGB(235, 195, 75), Enum.Material.Metal)
		local rWeld = Instance.new("Weld")
		rWeld.Part0 = shield
		rWeld.Part1 = rim
		rWeld.C0 = CFrame.new(-0.04, 0, 0)
		rWeld.Parent = rim
	end
end

_G.RebuildCharacterWeaponRig = rebuildCharacterWeaponRig

local function hookPlayerRig(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.6)
		rebuildCharacterWeaponRig(player)
	end)
	player:GetAttributeChangedSignal("Class"):Connect(function()
		rebuildCharacterWeaponRig(player)
	end)
	player:GetAttributeChangedSignal("CoatedElement"):Connect(function()
		rebuildCharacterWeaponRig(player)
	end)
	if player.Character then
		task.spawn(rebuildCharacterWeaponRig, player)
	end
end

Players.PlayerAdded:Connect(hookPlayerRig)
for _, p in ipairs(Players:GetPlayers()) do
	hookPlayerRig(p)
end

if RemoteEvents then
	for _, evName in ipairs({"EquipItem", "UnequipItem", "RefineEquipment"}) do
		local ev = RemoteEvents:FindFirstChild(evName)
		if ev and ev:IsA("RemoteEvent") then
			ev.OnServerEvent:Connect(function(player)
				task.wait(0.15)
				rebuildCharacterWeaponRig(player)
			end)
		end
	end
end

-- ============================================================
-- 3. ROYAL WEAPON TRAINING GROUND (6 TRAINING DUMMIES + INSTRUCTOR NPC)
--    Located on the east side of NorthMainAvenue behind CraftingWorkshop
--    (X = 14..52, Z = -60..-132), opposite Prontera Cathedral!
--    And ZERO props blocking roads!
-- ============================================================
local function buildRoyalTrainingGround()
	local oldDecor = Workspace:FindFirstChild("RoROK_AtmosphereDecor")
	if oldDecor then oldDecor:Destroy() end

	local decorRoot = Instance.new("Folder")
	decorRoot.Name = "RoROK_AtmosphereDecor"
	decorRoot.Parent = Workspace

	local function groundPart(name, size, pos, color, mat, canCollide, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Position = pos
		p.Anchored = true
		p.CanCollide = (canCollide == nil) and true or canCollide
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Color = color
		p.Material = mat or Enum.Material.Cobblestone
		if shape then p.Shape = shape end
		p.Parent = decorRoot
		return p
	end

	-- 1. ลานหินฝึกซ้อมอาวุธหลวง (Royal Training Courtyard) หลังโรงคราฟต์ ข้างถนนเข้าปราสาท
	-- ถนน NorthMainAvenue อยู่ที่ X = -10..+10 ดังนั้นลานฝึกเริ่มที่ X = 14..54, Z = -62..-130
	groundPart("TrainingCourtyardBase", Vector3.new(38, 0.42, 66), Vector3.new(33, 0.02, -96), Color3.fromRGB(168, 156, 136), Enum.Material.Cobblestone)
	groundPart("TrainingCourtyardInner", Vector3.new(32, 0.46, 58), Vector3.new(34, 0.04, -96), Color3.fromRGB(192, 178, 152), Enum.Material.Sandstone)
	-- ทางเดินเชื่อมจากถนนสายเข้าปราสาท (NorthMainAvenue X=10) เข้าสู่ลานฝึกโดยตรง
	groundPart("TrainingAvenueWalkway", Vector3.new(8, 0.44, 14), Vector3.new(12, 0.03, -96), Color3.fromRGB(186, 172, 142), Enum.Material.Cobblestone)

	-- รั้วไม้และเสาธงอัศวินรอบลานฝึก (เว้นทางเข้าฝั่งถนน X=14 ช่วง Z=-88..-104)
	groundPart("FenceNorth", Vector3.new(38, 3.2, 0.8), Vector3.new(33, 1.6, -128.5), Color3.fromRGB(108, 74, 48), Enum.Material.Wood)
	groundPart("FenceSouth", Vector3.new(38, 3.2, 0.8), Vector3.new(33, 1.6,  -63.5), Color3.fromRGB(108, 74, 48), Enum.Material.Wood)
	groundPart("FenceEast",  Vector3.new(0.8, 3.2, 66), Vector3.new(51.6, 1.6, -96),   Color3.fromRGB(108, 74, 48), Enum.Material.Wood)

	-- ชั้นวางอาวุธ (Weapon Racks) ริมรั้วด้านตะวันออกของลานฝึก
	for idx, rz in ipairs({-78, -114}) do
		groundPart("WeaponRackBase_" .. idx, Vector3.new(2.2, 0.6, 8.5), Vector3.new(48.5, 0.5, rz), Color3.fromRGB(92, 62, 38), Enum.Material.Wood)
		groundPart("WeaponRackFrame_" .. idx, Vector3.new(0.6, 5.2, 8.0), Vector3.new(49.0, 3.1, rz), Color3.fromRGB(115, 78, 48), Enum.Material.Wood)
		for b = -2.5, 2.5, 2.5 do
			groundPart("RackSword_" .. idx .. "_" .. b, Vector3.new(0.2, 4.2, 0.35), Vector3.new(48.4, 2.8, rz + b), Color3.fromRGB(215, 225, 240), Enum.Material.Metal, false)
		end
	end

	-- ป้ายลานฝึกอาวุธริมทางเข้า
	groundPart("TrainingSignPost", Vector3.new(0.6, 6.0, 0.6), Vector3.new(16.5, 3.0, -79), Color3.fromRGB(78, 52, 36), Enum.Material.Wood, false)
	local signBoard = groundPart("TrainingSignBoard", Vector3.new(0.45, 2.8, 8.8), Vector3.new(16.5, 5.2, -79), Color3.fromRGB(108, 74, 48), Enum.Material.WoodPlanks, false)
	for _, face in ipairs({Enum.NormalId.Left, Enum.NormalId.Right}) do
		local sgui = Instance.new("SurfaceGui")
		sgui.Face = face
		sgui.CanvasSize = Vector2.new(460, 160)
		sgui.Parent = signBoard
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextScaled = true
		lbl.TextColor3 = Color3.fromRGB(255, 232, 165)
		lbl.Text = "⚔️ ลานฝึกซ้อมอาวุธและสกิล\nROYAL TRAINING GROUND"
		lbl.Parent = sgui
	end

	-- 2. NPC ครูฝึกอาวุธหลวง (Master Leo @ X = 18, Z = -96 หันหน้าไปทางถนนสายเข้าปราสาท)
	local npc = Instance.new("Model")
	npc.Name = "WeaponInstructorNPC"
	npc.Parent = decorRoot

	local nx, ny, nz = 18, 3.0, -96
	local torso = groundPart("HumanoidRootPart", Vector3.new(1.7, 2.1, 0.9), Vector3.new(nx, ny, nz), Color3.fromRGB(155, 48, 44), Enum.Material.SmoothPlastic, false)
	torso.Parent = npc
	npc.PrimaryPart = torso
	local head = groundPart("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(nx, ny + 1.65, nz), Color3.fromRGB(228, 178, 142), Enum.Material.SmoothPlastic, false, Enum.PartType.Ball)
	head.Parent = npc
	local helm = groundPart("Helm", Vector3.new(1.3, 0.55, 1.3), Vector3.new(nx, ny + 2.1, nz), Color3.fromRGB(235, 195, 75), Enum.Material.Metal, false)
	helm.Parent = npc
	local legL = groundPart("LegL", Vector3.new(0.58, 1.4, 0.62), Vector3.new(nx, ny - 1.5, nz - 0.38), Color3.fromRGB(64, 58, 54), Enum.Material.SmoothPlastic, false)
	legL.Parent = npc
	local legR = groundPart("LegR", Vector3.new(0.58, 1.4, 0.62), Vector3.new(nx, ny - 1.5, nz + 0.38), Color3.fromRGB(64, 58, 54), Enum.Material.SmoothPlastic, false)
	legR.Parent = npc
	local sword = groundPart("InstructorSword", Vector3.new(0.22, 3.2, 0.42), Vector3.new(nx - 0.6, ny + 0.4, nz + 0.75), Color3.fromRGB(235, 200, 85), Enum.Material.Metal, false)
	sword.Parent = npc

	local npcBB = Instance.new("BillboardGui")
	npcBB.Size = UDim2.fromOffset(185, 42)
	npcBB.StudsOffset = Vector3.new(0, 3.2, 0)
	npcBB.MaxDistance = 42
	npcBB.AlwaysOnTop = false
	npcBB.Parent = torso
	local npcLbl = Instance.new("TextLabel")
	npcLbl.Size = UDim2.fromScale(1, 1)
	npcLbl.BackgroundTransparency = 1
	npcLbl.Font = Enum.Font.GothamBold
	npcLbl.TextScaled = true
	npcLbl.TextColor3 = Color3.fromRGB(255, 228, 120)
	npcLbl.TextStrokeTransparency = 0.2
	npcLbl.Text = "⚔️ ครูฝึกอาวุธหลวง Leo\n[F] รับเควสฝึกใช้อาวุธ (ตีหุ่นฟาง 6 ตัว)"
	npcLbl.Parent = npcBB

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkToWeaponInstructor"
	prompt.ObjectText = "ครูฝึกอาวุธหลวง Leo"
	prompt.ActionText = "รับเควสฝึกใช้อาวุธ / ดูภารกิจ"
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = torso

	prompt.Triggered:Connect(function(player)
		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if not remotes then return end
		local openQuests = remotes:FindFirstChild("OpenDailyQuests")
		if openQuests then openQuests:FireClient(player) end
		local feedback = remotes:FindFirstChild("SkillFeedback")
		if feedback then
			feedback:FireClient(player, "ครูฝึกอาวุธหลวง Leo: กดรับเควส '⚔️ ฝึกใช้อาวุธและสกิลกับหุ่นฟาง' แล้วลองโจมตีหรือกดเลข 1 ใช้สกิลใส่หุ่นฟางทั้ง 6 ตัวได้เลย!")
		end
	end)

	-- 3. สร้างหุ่นฟางฝึกซ้อม 6 ตัว (2 แถว × 3 ตัว) ในลานฝึกหลังโรงคราฟต์
	task.spawn(function()
		task.wait(1.0)
		local mFolder = Workspace:FindFirstChild("Monsters")
		if not mFolder then
			mFolder = Instance.new("Folder")
			mFolder.Name = "Monsters"
			mFolder.Parent = Workspace
		end

		-- ลบหุ่นฟางเก่าทั้งหมดก่อนสร้างใหม่ 6 ตัว
		for _, child in ipairs(mFolder:GetChildren()) do
			if string.find(child.Name, "^TrainingDummy") then
				child:Destroy()
			end
		end

		local dummyCoords = {
			Vector3.new(28, 0, -76),
			Vector3.new(28, 0, -96),
			Vector3.new(28, 0, -116),
			Vector3.new(41, 0, -76),
			Vector3.new(41, 0, -96),
			Vector3.new(41, 0, -116),
		}

		for idx, dPos in ipairs(dummyCoords) do
			-- ฐานวงกลมใต้หุ่นฟางแต่ละตัว
			groundPart("DummyPad_" .. idx, Vector3.new(0.4, 5.5, 5.5), dPos + Vector3.new(0, 0.25, 0), Color3.fromRGB(142, 128, 108), Enum.Material.Cobblestone, true, Enum.PartType.Cylinder).CFrame =
				CFrame.new(dPos + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90))

			local dummy = Instance.new("Model")
			dummy.Name = "TrainingDummy_" .. idx
			dummy:SetAttribute("MonsterID", "TrainingDummy")
			dummy:SetAttribute("Level", 1)
			dummy:SetAttribute("HP", 300)
			dummy:SetAttribute("MaxHP", 300)
			dummy:SetAttribute("ATK", 0)
			dummy:SetAttribute("DEF", 0)
			dummy:SetAttribute("MDEF", 0)
			dummy:SetAttribute("HIT", 1)
			dummy:SetAttribute("FLEE", 0)
			dummy:SetAttribute("PerfectDodge", 0)
			dummy:SetAttribute("Element", "Neutral")
			dummy:SetAttribute("XP_Reward", 10)
			dummy:SetAttribute("JobXP_Reward", 8)
			dummy:SetAttribute("RespawnTime", 2)
			dummy:SetAttribute("MapName", "Prontera")
			dummy:SetAttribute("SpawnPosition", dPos)
			dummy:SetAttribute("AggroRange", 0)
			dummy:SetAttribute("AttackRange", 0)
			dummy:SetAttribute("MoveSpeed", 0)
			dummy:SetAttribute("StatusStun", true) -- ยืนนิ่งให้ซ้อมตีและสกิล

			local post = Instance.new("Part")
			post.Name = "HumanoidRootPart"
			post.Size = Vector3.new(2.2, 4.4, 2.2)
			post.Position = dPos + Vector3.new(0, 2.5, 0)
			post.Anchored = true
			post.Color = Color3.fromRGB(198, 158, 92)
			post.Material = Enum.Material.WoodPlanks
			post.Parent = dummy
			dummy.PrimaryPart = post

			-- เป้าวงกลมสีแดง-ขาวกลางลำตัวหุ่นฟาง
			local targetPlate = Instance.new("Part")
			targetPlate.Name = "BullseyeTarget"
			targetPlate.Shape = Enum.PartType.Cylinder
			targetPlate.Size = Vector3.new(0.25, 2.0, 2.0)
			targetPlate.CFrame = CFrame.new(dPos + Vector3.new(-1.12, 2.8, 0))
			targetPlate.Anchored = true
			targetPlate.CanCollide = false
			targetPlate.Color = Color3.fromRGB(220, 58, 52)
			targetPlate.Material = Enum.Material.SmoothPlastic
			targetPlate.Parent = dummy

			local head = Instance.new("Part")
			head.Name = "DummyHead"
			head.Shape = Enum.PartType.Ball
			head.Size = Vector3.new(2.1, 2.1, 2.1)
			head.Position = dPos + Vector3.new(0, 5.6, 0)
			head.Anchored = true
			head.Color = Color3.fromRGB(228, 192, 122)
			head.Material = Enum.Material.Fabric
			head.Parent = dummy

			local arms = Instance.new("Part")
			arms.Name = "DummyCrossbar"
			arms.Size = Vector3.new(0.65, 0.65, 4.6)
			arms.Position = dPos + Vector3.new(0, 3.8, 0)
			arms.Anchored = true
			arms.Color = Color3.fromRGB(130, 92, 54)
			arms.Material = Enum.Material.Wood
			arms.Parent = dummy

			local bb = Instance.new("BillboardGui")
			bb.Name = "MonsterBillboard"
			bb.Size = UDim2.fromOffset(145, 32)
			bb.StudsOffset = Vector3.new(0, 4.8, 0)
			bb.MaxDistance = 48
			bb.Parent = post

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 0, 16)
			lbl.BackgroundTransparency = 1
			lbl.Text = string.format("🎯 หุ่นฟางฝึกซ้อม #%d", idx)
			lbl.TextColor3 = Color3.fromRGB(255, 225, 115)
			lbl.TextStrokeTransparency = 0.2
			lbl.TextScaled = true
			lbl.Font = Enum.Font.GothamBold
			lbl.Parent = bb

			local hpBar = Instance.new("Frame")
			hpBar.Name = "HPBar"
			hpBar.Size = UDim2.new(1, 0, 0, 8)
			hpBar.Position = UDim2.new(0, 0, 0, 18)
			hpBar.BackgroundColor3 = Color3.fromRGB(45, 20, 20)
			hpBar.BorderSizePixel = 0
			hpBar.Parent = bb
			local fill = Instance.new("Frame")
			fill.Name = "HPFill"
			fill.Size = UDim2.fromScale(1, 1)
			fill.BackgroundColor3 = Color3.fromRGB(245, 185, 55)
			fill.BorderSizePixel = 0
			fill.Parent = hpBar

			dummy.Parent = mFolder
		end
	end)
end

buildRoyalTrainingGround()

-- ============================================================
-- 4. HOOK COMBAT SYSTEM TO FIRE 3D SLASH / SKILL VFX
-- ============================================================
task.spawn(function()
	local waitStart = os.clock()
	while not _G.CombatSystem and (os.clock() - waitStart < 20) do
		task.wait(0.2)
	end
	local cs = _G.CombatSystem
	local vfxRemote = RemoteEvents and RemoteEvents:FindFirstChild("PlayCombatVFX")
	if not cs or not vfxRemote then return end

	if not cs._VFXHooked then
		cs._VFXHooked = true
		local origAttack = cs.PlayerAttackMonster
		cs.PlayerAttackMonster = function(player, monster, skillId)
			local res = origAttack(player, monster, skillId)
			if not skillId and player and monster then
				local mRoot = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart
				local pos = mRoot and mRoot.Position
				if pos then
					vfxRemote:FireAllClients("BasicAttack", player, pos, player:GetAttribute("CoatedElement") or "Neutral", res and res.isCrit)
				end
			end
			return res
		end

		local origSkill = cs.HandleSkillUse
		cs.HandleSkillUse = function(player, skillId, skillLevel, targetId)
			local targetMonster = (typeof(targetId) == "Instance" and targetId)
				or ((type(targetId) == "string" and targetId ~= "") and Workspace:FindFirstChild(targetId, true))
				or nil
			local mRoot = targetMonster and (targetMonster:FindFirstChild("HumanoidRootPart") or targetMonster.PrimaryPart)
			local pRoot = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local fallbackPos = (mRoot and mRoot.Position) or (pRoot and pRoot.Position)
			local ok, actualTargetPos = origSkill(player, skillId, skillLevel, targetId)
			local targetPos = actualTargetPos or fallbackPos
			if ok and player and targetPos then
				vfxRemote:FireAllClients("Skill", player, targetPos, skillId, skillLevel)
			end
			return ok, actualTargetPos
		end
	end
end)

print("[VisualRigAndLighting] Cleaned roads, fixed hand grip, and built 6-Dummy Royal Training Ground!")
