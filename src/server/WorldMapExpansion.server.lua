-- ============================================================
-- WorldMapExpansion.server.lua
-- สร้าง 3 โซนโลกใหม่:
--   1. ดันเจี้ยนสุสานใต้ดิน Prontera Culvert (Lv.12–20 & Boss Drake / Minorous)
--   2. เมืองทะเลทรายและพีระมิด Morroc (Lv.20–40 & World Boss Eddga)
--   3. เมืองน้ำเกาะซากุระ Amatsu (Lv.35–60 & World Boss Turtle General)
-- พร้อมเชื่อมต่อประตูมิติในสุสานและท่าเรือเดินสมุทร Prontera!
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local oldWorld = Workspace:FindFirstChild("RoROK_WorldExpansion")
if oldWorld then oldWorld:Destroy() end

local worldRoot = Instance.new("Folder")
worldRoot.Name = "RoROK_WorldExpansion"
worldRoot.Parent = Workspace

local function part(name, size, pos, color, material, shape, parent, canCollide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Anchored = true
	p.CanCollide = (canCollide == nil) and true or canCollide
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = shape or Enum.PartType.Block
	p.Parent = parent or worldRoot
	return p
end

local function makeBannerSign(parent, pos, title, subtitle, textColor)
	part("SignPost", Vector3.new(0.7, 6, 0.7), pos + Vector3.new(0, 3, 0), Color3.fromRGB(78, 54, 38), Enum.Material.Wood, nil, parent, false)
	local board = part("SignBoard", Vector3.new(9.5, 3.0, 0.45), pos + Vector3.new(0, 5.5, 0), Color3.fromRGB(52, 38, 28), Enum.Material.WoodPlanks, nil, parent, false)
	for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.CanvasSize = Vector2.new(520, 170)
		gui.Parent = board
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextScaled = true
		lbl.TextColor3 = textColor or Color3.fromRGB(255, 232, 165)
		lbl.Text = title .. "\n" .. subtitle
		lbl.Parent = gui
	end
end

local function teleportPlayer(player, mapName, targetCF, toastText)
	local dataApi = _G.DataStore
	local data = dataApi and dataApi.GetPlayerData(player)
	if data then
		data.Map = mapName
		player:SetAttribute("Map", mapName)
	end
	player:SetAttribute("SpawnProtectedUntil", os.clock() + 5)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = targetCF
	end
	if _G.PushCharacterData then _G.PushCharacterData(player) end
	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
	local feedback = remotes and remotes:FindFirstChild("SkillFeedback")
	if feedback and toastText then
		feedback:FireClient(player, toastText)
	end
end

local function makeReturnPortal(parent, pos, returnCF, returnMap, labelText)
	part("PortalPedestal", Vector3.new(8, 1.0, 5), pos + Vector3.new(0, 0.5, 0), Color3.fromRGB(165, 160, 152), Enum.Material.Cobblestone, nil, parent)
	part("PortalPillarL", Vector3.new(1.6, 12, 1.6), pos + Vector3.new(-3.2, 6.5, 0), Color3.fromRGB(190, 184, 175), Enum.Material.Marble, nil, parent)
	part("PortalPillarR", Vector3.new(1.6, 12, 1.6), pos + Vector3.new( 3.2, 6.5, 0), Color3.fromRGB(190, 184, 175), Enum.Material.Marble, nil, parent)
	part("PortalArch", Vector3.new(8.4, 2.0, 2.0), pos + Vector3.new(0, 13, 0), Color3.fromRGB(190, 184, 175), Enum.Material.Marble, nil, parent)
	local orb = part("WarpGate", Vector3.new(4.8, 10.5, 0.8), pos + Vector3.new(0, 6.2, 0), Color3.fromRGB(95, 195, 255), Enum.Material.Neon, nil, parent, false)
	orb.Transparency = 0.25
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = labelText or "กลับเมืองหลวง Prontera"
	prompt.ObjectText = "เสาวาร์ปข้ามเมือง"
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = orb
	prompt.Triggered:Connect(function(player)
		teleportPlayer(player, returnMap or "Prontera", returnCF or CFrame.new(0, 5, -14), "วาร์ปกลับสู่ " .. (returnMap or "Prontera") .. " เรียบร้อย!")
	end)
end

-- ============================================================
-- 1. PRONTERA CULVERT DUNGEON (Center = 0, 0, -720)
-- ============================================================
local culvertFolder = Instance.new("Folder")
culvertFolder.Name = "PronteraCulvertDungeon"
culvertFolder.Parent = worldRoot

part("CulvertFloor", Vector3.new(150, 2, 220), Vector3.new(0, -1, -715), Color3.fromRGB(48, 46, 56), Enum.Material.Slate, nil, culvertFolder)
part("CulvertCenterWalkway", Vector3.new(24, 0.4, 200), Vector3.new(0, 0.1, -715), Color3.fromRGB(72, 68, 82), Enum.Material.Cobblestone, nil, culvertFolder)
-- คลองระบายน้ำใต้ดินขนาบสองข้างทางเดิน
for _, sx in ipairs({-20, 20}) do
	local canal = part("SewerCanal", Vector3.new(12, 0.3, 190), Vector3.new(sx, 0.05, -715), Color3.fromRGB(58, 128, 118), Enum.Material.Glass, nil, culvertFolder, false)
	canal.Transparency = 0.25
end
-- ผนังหินดันเจี้ยนและเสาคริสตัลเรืองแสงสีม่วง
part("CulvertWallWest", Vector3.new(8, 32, 220), Vector3.new(-74, 16, -715), Color3.fromRGB(36, 34, 44), Enum.Material.Rock, nil, culvertFolder)
part("CulvertWallEast", Vector3.new(8, 32, 220), Vector3.new( 74, 16, -715), Color3.fromRGB(36, 34, 44), Enum.Material.Rock, nil, culvertFolder)
part("CulvertWallNorth", Vector3.new(156, 32, 8), Vector3.new(0, 16, -824), Color3.fromRGB(36, 34, 44), Enum.Material.Rock, nil, culvertFolder)
part("CulvertWallSouth", Vector3.new(156, 32, 8), Vector3.new(0, 16, -606), Color3.fromRGB(36, 34, 44), Enum.Material.Rock, nil, culvertFolder)

for z = -640, -790, -30 do
	for _, px in ipairs({-32, 32}) do
		part("DungeonPillar", Vector3.new(4.5, 28, 4.5), Vector3.new(px, 14, z), Color3.fromRGB(64, 60, 74), Enum.Material.Cobblestone, nil, culvertFolder)
		local crystal = part("DungeonCrystal", Vector3.new(1.8, 3.6, 1.8), Vector3.new(px * 0.88, 6, z), Color3.fromRGB(168, 95, 255), Enum.Material.Neon, nil, culvertFolder, false)
		local light = Instance.new("PointLight")
		light.Color = crystal.Color
		light.Brightness = 1.4
		light.Range = 26
		light.Parent = crystal
	end
end

-- ซากเรือโจรสลัดท้ายดันเจี้ยน (Captain Drake Boss Arena @ Z = -790)
part("BossArenaPlatform", Vector3.new(58, 1.2, 42), Vector3.new(0, 0.6, -790), Color3.fromRGB(64, 52, 46), Enum.Material.WoodPlanks, nil, culvertFolder)
part("GhostShipMast", Vector3.new(1.8, 28, 1.8), Vector3.new(0, 15, -802), Color3.fromRGB(48, 36, 28), Enum.Material.Wood, nil, culvertFolder, false)
part("GhostShipSail", Vector3.new(20, 14, 0.8), Vector3.new(0, 18, -801), Color3.fromRGB(132, 78, 195), Enum.Material.Fabric, nil, culvertFolder, false)

makeBannerSign(culvertFolder, Vector3.new(-10, 0, -632), "ดันเจี้ยนใต้ดิน Prontera Culvert", "Lv.12–20 • Thief Bug, Sohee, Minorous & Boss Drake", Color3.fromRGB(215, 165, 255))
makeReturnPortal(culvertFolder, Vector3.new(0, 0, -614), CFrame.new(318, 4, 46), "Prontera", "ออกไปหน้าสุสาน Prontera")

-- ============================================================
-- 2. MORROC DESERT CITY & PYRAMID (Center = 950, 0, -90)
-- ============================================================
local morrocFolder = Instance.new("Folder")
morrocFolder.Name = "MorrocDesertRealm"
morrocFolder.Parent = worldRoot

part("MorrocSandGround", Vector3.new(280, 2, 290), Vector3.new(950, -1, -95), Color3.fromRGB(224, 190, 126), Enum.Material.Sand, nil, morrocFolder)
part("MorrocOasisPlaza", Vector3.new(68, 0.4, 56), Vector3.new(950, 0.1, -16), Color3.fromRGB(212, 178, 118), Enum.Material.Sandstone, nil, morrocFolder)
local oasisPool = part("OasisWater", Vector3.new(22, 0.5, 22), Vector3.new(950, 0.2, -16), Color3.fromRGB(68, 192, 215), Enum.Material.Glass, Enum.PartType.Cylinder, morrocFolder, false)
oasisPool.CFrame = CFrame.new(950, 0.2, -16) * CFrame.Angles(0, 0, math.rad(90))
oasisPool.Transparency = 0.2
part("MorrocDesertRoad", Vector3.new(18, 0.35, 165), Vector3.new(950, 0.08, -110), Color3.fromRGB(194, 158, 98), Enum.Material.Cobblestone, nil, morrocFolder)

-- ต้นปาล์มโอเอซิส (Desert Palm Trees)
for i, pPos in ipairs({
	Vector3.new(924, 0, -32), Vector3.new(976, 0, -32), Vector3.new(924, 0, 4), Vector3.new(976, 0, 4),
	Vector3.new(912, 0, -85), Vector3.new(988, 0, -85),
}) do
	part("PalmTrunk_" .. i, Vector3.new(1.8, 16, 1.8), pPos + Vector3.new(0, 8, 0), Color3.fromRGB(122, 86, 52), Enum.Material.Wood, nil, morrocFolder)
	part("PalmCrown_" .. i, Vector3.new(11, 4.5, 11), pPos + Vector3.new(0, 16.5, 0), Color3.fromRGB(98, 168, 68), Enum.Material.Grass, Enum.PartType.Ball, morrocFolder, false)
end

-- มหาพีระมิดแห่ง Morroc (Ancient Morroc Step Pyramid @ 950, 0, -202)
for tier = 1, 5 do
	local sz = 92 - (tier - 1) * 16
	part("PyramidTier_" .. tier, Vector3.new(sz, 9, sz), Vector3.new(950, (tier - 0.5) * 9, -202), Color3.fromRGB(208, 168, 102), Enum.Material.Sandstone, nil, morrocFolder)
end
part("PyramidApexGold", Vector3.new(14, 7, 14), Vector3.new(950, 48.5, -202), Color3.fromRGB(245, 198, 72), Enum.Material.Neon, nil, morrocFolder, false)

-- ล้อมขอบแมพทะเลทรายด้วยหน้าผาหินทราย (Sandstone Canyon Cliffs)
part("MorrocCliffW", Vector3.new(18, 36, 290), Vector3.new(812, 18, -95), Color3.fromRGB(186, 142, 88), Enum.Material.Sandstone, nil, morrocFolder)
part("MorrocCliffE", Vector3.new(18, 36, 290), Vector3.new(1088, 18, -95), Color3.fromRGB(186, 142, 88), Enum.Material.Sandstone, nil, morrocFolder)
part("MorrocCliffN", Vector3.new(290, 42, 18), Vector3.new(950, 21, -238), Color3.fromRGB(186, 142, 88), Enum.Material.Sandstone, nil, morrocFolder)

makeBannerSign(morrocFolder, Vector3.new(936, 0, -36), "เมืองทะเลทราย Morroc (Lv.20–40)", "Scorpion, Mummy, Sand Golem & World Boss Eddga", Color3.fromRGB(255, 215, 120))
makeReturnPortal(morrocFolder, Vector3.new(950, 0, 12), CFrame.new(-68, 4, 232), "Prontera", "ขึ้นเรือกลับท่าเรือ Prontera")

-- ============================================================
-- 3. AMATSU WATER BLOSSOM ISLAND (Center = -950, 0, -90)
-- ============================================================
local amatsuFolder = Instance.new("Folder")
amatsuFolder.Name = "AmatsuWaterRealm"
amatsuFolder.Parent = worldRoot

local seaWater = part("AmatsuSeaWater", Vector3.new(310, 1.5, 310), Vector3.new(-950, -1.2, -95), Color3.fromRGB(58, 152, 205), Enum.Material.Glass, nil, amatsuFolder, false)
seaWater.Transparency = 0.22
part("AmatsuMainIsland", Vector3.new(250, 2.2, 260), Vector3.new(-950, -0.8, -95), Color3.fromRGB(108, 166, 98), Enum.Material.Grass, nil, amatsuFolder)
part("AmatsuShrinePlaza", Vector3.new(64, 0.4, 54), Vector3.new(-950, 0.2, -16), Color3.fromRGB(198, 192, 184), Enum.Material.Cobblestone, nil, amatsuFolder)
part("AmatsuSacredPath", Vector3.new(16, 0.4, 165), Vector3.new(-950, 0.2, -110), Color3.fromRGB(185, 178, 168), Enum.Material.Cobblestone, nil, amatsuFolder)

-- เสาโทริอิสีแดงชาด (Vermilion Torii Gates) เรียงตามทางเดินเข้าสู่ปราสาท Amatsu
for _, tz in ipairs({-38, -88, -138}) do
	part("ToriiPillarL", Vector3.new(1.8, 18, 1.8), Vector3.new(-959, 9, tz), Color3.fromRGB(198, 46, 38), Enum.Material.SmoothPlastic, nil, amatsuFolder)
	part("ToriiPillarR", Vector3.new(1.8, 18, 1.8), Vector3.new(-941, 9, tz), Color3.fromRGB(198, 46, 38), Enum.Material.SmoothPlastic, nil, amatsuFolder)
	part("ToriiTopBeam", Vector3.new(25, 1.8, 2.4), Vector3.new(-950, 18.2, tz), Color3.fromRGB(198, 46, 38), Enum.Material.SmoothPlastic, nil, amatsuFolder, false)
	part("ToriiSubBeam", Vector3.new(21, 1.2, 1.6), Vector3.new(-950, 15.2, tz), Color3.fromRGB(42, 38, 38), Enum.Material.SmoothPlastic, nil, amatsuFolder, false)
end

-- ปราสาทเจดีย์ญี่ปุ่น Amatsu Pagoda Castle (@ -950, 0, -200)
part("PagodaBaseStone", Vector3.new(68, 8, 52), Vector3.new(-950, 4, -202), Color3.fromRGB(132, 128, 124), Enum.Material.Cobblestone, nil, amatsuFolder)
for floor = 1, 3 do
	local w = 52 - (floor - 1) * 12
	local d = 40 - (floor - 1) * 8
	local yBase = 8 + (floor - 1) * 12
	part("PagodaWall_" .. floor, Vector3.new(w, 9, d), Vector3.new(-950, yBase + 4.5, -202), Color3.fromRGB(242, 236, 224), Enum.Material.Sandstone, nil, amatsuFolder)
	part("PagodaRoof_" .. floor, Vector3.new(w + 10, 3, d + 10), Vector3.new(-950, yBase + 10.5, -202), Color3.fromRGB(54, 64, 78), Enum.Material.Slate, nil, amatsuFolder, false)
end

-- ต้นซากุระยักษ์รอบเกาะ Amatsu
for i, sPos in ipairs({
	Vector3.new(-982, 0, -24), Vector3.new(-918, 0, -24),
	Vector3.new(-995, 0, -78), Vector3.new(-905, 0, -78),
	Vector3.new(-995, 0, -142), Vector3.new(-905, 0, -142),
}) do
	part("AmatsuSakuraTrunk_" .. i, Vector3.new(2.4, 14, 2.4), sPos + Vector3.new(0, 7, 0), Color3.fromRGB(88, 58, 46), Enum.Material.Wood, nil, amatsuFolder)
	part("AmatsuSakuraCanopy_" .. i, Vector3.new(18, 12, 18), sPos + Vector3.new(0, 15.5, 0), Color3.fromRGB(255, 165, 202), Enum.Material.Grass, Enum.PartType.Ball, amatsuFolder, false)
end

makeBannerSign(amatsuFolder, Vector3.new(-964, 0, -34), "เกาะซากุระเมืองน้ำ Amatsu (Lv.35–60)", "Swordfish, Karasu Tengu & World Boss Turtle General", Color3.fromRGB(255, 190, 220))
makeReturnPortal(amatsuFolder, Vector3.new(-950, 0, 12), CFrame.new(-68, 4, 232), "Prontera", "ขึ้นเรือกลับท่าเรือ Prontera")

-- ============================================================
-- 4. เชื่อมต่อประตูมิติสุสาน Prontera และท่าเรือเดินสมุทร
-- ============================================================
task.spawn(function()
	task.wait(1.5)
	-- (A) เชื่อมต่อประตูมิติท้ายสุสาน PronteraCulvertPortal -> วาร์ปเข้าดันเจี้ยน PronteraCulvert
	local plaza = Workspace:FindFirstChild("RoROK_StarterPlaza")
	local portalPart = plaza and plaza:FindFirstChild("PronteraCulvertPortal", true)
	if portalPart and not portalPart:FindFirstChild("EnterCulvertPrompt") then
		local p = Instance.new("ProximityPrompt")
		p.Name = "EnterCulvertPrompt"
		p.ObjectText = "ดันเจี้ยนสุสานใต้ดิน Prontera Culvert"
		p.ActionText = "เข้าสู่ดันเจี้ยนใต้ดิน (Lv.12–20)"
		p.KeyboardKeyCode = Enum.KeyCode.F
		p.HoldDuration = 0
		p.MaxActivationDistance = 14
		p.RequiresLineOfSight = false
		p.Parent = portalPart
		p.Triggered:Connect(function(player)
			teleportPlayer(player, "PronteraCulvert", CFrame.new(0, 5, -624), "เข้าสู่ดันเจี้ยนสุสานใต้ดิน Prontera Culvert!")
		end)
	end

	-- (B) เพิ่มป้ายและจุดขึ้นเรือเดินสมุทรที่ท่าเรือ Prontera (ไป Morroc / Amatsu / Culvert)
	local shipTravelPost = part("HarborTravelHelm", Vector3.new(2.4, 5.2, 2.4), Vector3.new(-68, 3.6, 266), Color3.fromRGB(115, 82, 52), Enum.Material.Wood, nil, worldRoot)
	local travelOrb = part("HarborCompassOrb", Vector3.new(1.8, 1.8, 1.8), Vector3.new(-68, 6.8, 266), Color3.fromRGB(255, 215, 95), Enum.Material.Neon, Enum.PartType.Ball, worldRoot, false)
	local travelPrompt = Instance.new("ProximityPrompt")
	travelPrompt.Name = "OpenWorldTravelPrompt"
	travelPrompt.ObjectText = "พังงาเรือเดินสมุทร (World Travel)"
	travelPrompt.ActionText = "เลือกเมืองเดินทาง (Morroc / Amatsu)"
	travelPrompt.KeyboardKeyCode = Enum.KeyCode.F
	travelPrompt.HoldDuration = 0
	travelPrompt.MaxActivationDistance = 14
	travelPrompt.RequiresLineOfSight = false
	travelPrompt.Parent = shipTravelPost
	travelPrompt.Triggered:Connect(function(player)
		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
		local openTravel = remotes and remotes:FindFirstChild("OpenWorldTravel")
		if openTravel then openTravel:FireClient(player) end
	end)

	-- อัปเดต NPC กัปตันท่าเรือ Drake ให้เปิดหน้าต่างเดินเรือข้ามเมืองได้ด้วย
	local harborMaster = plaza and plaza:FindFirstChild("HarborMasterNPC", true)
	local hmPrompt = harborMaster and harborMaster:FindFirstChild("TalkToNpc", true)
	if hmPrompt then
		hmPrompt.ActionText = "ออกเรือไปเมือง Morroc / Amatsu"
		hmPrompt.Triggered:Connect(function(player)
			local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
			local openTravel = remotes and remotes:FindFirstChild("OpenWorldTravel")
			if openTravel then openTravel:FireClient(player) end
		end)
	end

	-- (C) เสกมอนสเตอร์ประจำดันเจี้ยนใต้ดิน, เมืองทะเลทราย Morroc, เมืองน้ำ Amatsu และ World Boss!
	local aiWait = 0
	while (not _G.MonsterAI or not _G.MonsterAI.SpawnMonster) and aiWait < 15 do
		task.wait(0.2)
		aiWait += 0.2
	end
	if _G.MonsterAI and _G.MonsterAI.SpawnMonster then
		local expansionSpawns = {
			-- ดันเจี้ยนสุสานใต้ดิน Prontera Culvert
			{ id = "ThiefBug", pos = Vector3.new(-12, 0, -660), map = "PronteraCulvert" },
			{ id = "ThiefBug", pos = Vector3.new( 14, 0, -672), map = "PronteraCulvert" },
			{ id = "Sohee",    pos = Vector3.new(-16, 0, -708), map = "PronteraCulvert" },
			{ id = "Sohee",    pos = Vector3.new( 16, 0, -722), map = "PronteraCulvert" },
			{ id = "Minorous", pos = Vector3.new(  0, 0, -752), map = "PronteraCulvert" },
			{ id = "Drake",    pos = Vector3.new(  0, 1, -792), map = "PronteraCulvert" },

			-- เมืองทะเลทราย Morroc (Lv.20–40 & World Boss Eddga)
			{ id = "Scorpion", pos = Vector3.new(918, 0, -68),  map = "Morroc" },
			{ id = "Scorpion", pos = Vector3.new(982, 0, -72),  map = "Morroc" },
			{ id = "Mummy",    pos = Vector3.new(915, 0, -118), map = "Morroc" },
			{ id = "Mummy",    pos = Vector3.new(985, 0, -122), map = "Morroc" },
			{ id = "SandMan",  pos = Vector3.new(922, 0, -152), map = "Morroc" },
			{ id = "SandMan",  pos = Vector3.new(978, 0, -155), map = "Morroc" },
			{ id = "Eddga",    pos = Vector3.new(950, 0, -162), map = "Morroc" },

			-- เกาะซากุระเมืองน้ำ Amatsu (Lv.35–60 & World Boss Turtle General)
			{ id = "Swordfish",     pos = Vector3.new(-982, 0, -68),  map = "Amatsu" },
			{ id = "Swordfish",     pos = Vector3.new(-918, 0, -72),  map = "Amatsu" },
			{ id = "Tengu",         pos = Vector3.new(-982, 0, -124), map = "Amatsu" },
			{ id = "Tengu",         pos = Vector3.new(-918, 0, -128), map = "Amatsu" },
			{ id = "TurtleGeneral", pos = Vector3.new(-950, 0, -162), map = "Amatsu" },
		}
		for _, sp in ipairs(expansionSpawns) do
			_G.MonsterAI.SpawnMonster(sp.id, sp.pos, sp.map)
		end
		print("[WorldMapExpansion] เสกมอนสเตอร์และบอสประจำ Culvert, Morroc, Amatsu ครบถ้วน!")
	end
end)
