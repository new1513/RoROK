-- ============================================================

-- StarterMap.server.lua

-- สร้างหมู่บ้านแฟนตาซียุคกลาง (Fantasy Medieval Village — Prontera Capital)

-- และสภาพแวดล้อมเขตล่ามอนสเตอร์แยกตามประเภท (Habitat Biomes)

--

-- จุดเด่นของการปรับปรุงรอบนี้:

--   1. จัตุรัสวงเวียนน้ำพุกลางเมืองกว้าง 84×84 studs ไม่เบี้ยว ไม่ชนผนังบ้าน

--   2. อาคารที่มีป้ายชื่อทุกหลัง (โรงตีเหล็ก, โรงเตี๊ยม, กิลด์อัศวิน, มหาวิหาร, ร้านอาวุธ,

--      ร้านเครื่องราง, ร้านสมุนไพร, หอเวทมนตร์, บ้านพักนักเดินทาง, โกดังท่าเรือ)

--      **เดินเข้าได้จริง (Enterable Interior)** มีพื้นที่ภายใน เฟอร์นิเจอร์ แสงไฟ และ NPC ประจำบ้าน

--      พร้อมคุยเพื่อเปิดกระดานเควส/บริการผู้เล่นได้ทันที

--   3. ไม่มีต้นไม้เกิดทับหน้าประตูหรือทะลุกันสาดบ้าน

--   4. เขตมอนสเตอร์ด้านตะวันออก (X = 80..350) แยกเป็น 4 สภาพแวดล้อมชัดเจน:

--      - โซน 1 (X 85..140): ทุ่งหญ้าดอกไม้ Poring Meadow (Lv.1)

--      - โซน 2 (X 145..198): สวนโคลเวอร์และแปลงแครอท Lunatic Patch (Lv.3)

--      - โซน 3 (X 205..270, ฝั่งเหนือ Z < -10): ป่าสนและโขดหินหมาป่า Wolf Pine Woods (Lv.5)

--      - โซน 4 (X 215..330, ฝั่งใต้ Z > 10): สุสานโบราณ รั้วเหล็ก ป้ายหลุมศพ และซากวิหาร Undead Graveyard (Lv.8-10 Zombie & Skeleton)

-- ============================================================



local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerStorage = game:GetService("ServerStorage")

local Lighting = game:GetService("Lighting")



local ROOT_NAME = "RoROK_StarterPlaza"

local old = Workspace:FindFirstChild(ROOT_NAME)

if old then old:Destroy() end

local oldScenery = Workspace:FindFirstChild("RoROK_TownScenery")

if oldScenery then oldScenery:Destroy() end

local oldGround = Workspace:FindFirstChild("RoROK_TownGround")

if oldGround then oldGround:Destroy() end

local leftoverBow = Workspace:FindFirstChild("TestBowPart", true)

if leftoverBow then leftoverBow:Destroy() end



local root = Instance.new("Folder")

root.Name = ROOT_NAME

root.Parent = Workspace



local PALETTE = {

	grassMain      = Color3.fromRGB(92, 138, 68),

	grassDark      = Color3.fromRGB(72, 114, 54),

	meadowGrass    = Color3.fromRGB(106, 156, 76),

	forestFloor    = Color3.fromRGB(64, 94, 52),

	graveyardDirt  = Color3.fromRGB(78, 74, 68),

	cobbleMain     = Color3.fromRGB(156, 143, 118),

	cobbleDark     = Color3.fromRGB(124, 114, 94),

	cobbleLight    = Color3.fromRGB(186, 172, 142),

	dirtRoad       = Color3.fromRGB(148, 125, 92),

	stoneWall      = Color3.fromRGB(145, 138, 126),

	stoneDark      = Color3.fromRGB(105, 99, 90),

	stoneLight     = Color3.fromRGB(188, 178, 158),

	plasterWarm    = Color3.fromRGB(230, 214, 182),

	plasterCream   = Color3.fromRGB(222, 202, 168),

	plasterSage    = Color3.fromRGB(202, 208, 184),

	plasterTan     = Color3.fromRGB(218, 192, 158),

	timberDark     = Color3.fromRGB(78, 52, 36),

	timberMed      = Color3.fromRGB(108, 74, 48),

	woodFloor      = Color3.fromRGB(132, 94, 62),

	roofRed        = Color3.fromRGB(152, 66, 52),

	roofTerra      = Color3.fromRGB(168, 84, 54),

	roofSlate      = Color3.fromRGB(72, 86, 106),

	roofBrown      = Color3.fromRGB(116, 74, 52),

	roofThatch     = Color3.fromRGB(196, 164, 96),

	goldTrim       = Color3.fromRGB(235, 194, 94),

	windowGlow     = Color3.fromRGB(255, 210, 125),

	waterBlue      = Color3.fromRGB(68, 156, 192),

}



local function part(name, size, position, color, material, shape, parent, canCollide)

	local item = Instance.new("Part")

	item.Name = name

	item.Size = size

	item.Position = position

	item.Anchored = true

	item.CanCollide = canCollide ~= false

	item.TopSurface = Enum.SurfaceType.Smooth

	item.BottomSurface = Enum.SurfaceType.Smooth

	item.Color = color

	item.Material = material or Enum.Material.SmoothPlastic

	item.Shape = shape or Enum.PartType.Block

	item.Parent = parent or root

	return item

end



local function cframePart(name, size, cf, color, material, parent, canCollide, shape)

	local item = Instance.new("Part")

	item.Name = name

	item.Size = size

	item.CFrame = cf

	item.Anchored = true

	item.CanCollide = canCollide ~= false

	item.TopSurface = Enum.SurfaceType.Smooth

	item.BottomSurface = Enum.SurfaceType.Smooth

	item.Color = color

	item.Material = material or Enum.Material.SmoothPlastic

	if shape then item.Shape = shape end

	item.Parent = parent or root

	return item

end



-- รายการกรอบพื้นที่ห้ามวางต้นไม้ (ตัวอาคาร + ลานหน้าประตู + ถนน + จัตุรัส)

local buildingFootprints = {}

local function registerFootprint(x, z, halfW, halfD)

	table.insert(buildingFootprints, { minX = x - halfW, maxX = x + halfW, minZ = z - halfD, maxZ = z + halfD })

end



local function isInsideAnyFootprint(x, z, margin)

	local m = margin or 0

	for _, fp in ipairs(buildingFootprints) do

		if x >= fp.minX - m and x <= fp.maxX + m and z >= fp.minZ - m and z <= fp.maxZ + m then

			return true

		end

	end

	return false

end



-- ============================================================

-- 1. พื้นโลกหลักและแม่น้ำทางใต้

-- ============================================================

local terrainFolder = Instance.new("Folder")

terrainFolder.Name = "VillageTerrain"

terrainFolder.Parent = root



part("VillageGrassland", Vector3.new(1150, 2, 820), Vector3.new(-20, -1.0, 0), PALETTE.grassMain, Enum.Material.Grass, nil, terrainFolder)

part("SouthernRiverBed", Vector3.new(1150, 1.5, 140), Vector3.new(-20, -2.2, 310), Color3.fromRGB(98, 88, 72), Enum.Material.Sand, nil, terrainFolder)

local riverWater = part("SouthernRiverWater", Vector3.new(1150, 1.8, 136), Vector3.new(-20, -0.8, 310), PALETTE.waterBlue, Enum.Material.Glass, nil, terrainFolder, false)

riverWater.Transparency = 0.25

part("RiverBankNorth", Vector3.new(1150, 1.6, 8), Vector3.new(-20, -0.1, 240), PALETTE.stoneWall, Enum.Material.Cobblestone, nil, terrainFolder)



-- ============================================================

-- 2. จัตุรัสวงเวียนกลางเมือง (กว้าง 88×88 studs โล่ง สมมาตร ไม่ชนอาคาร)

-- ============================================================

local roadsFolder = Instance.new("Folder")

roadsFolder.Name = "RoadsAndPlaza"

roadsFolder.Parent = root



part("ArrivalPlaza", Vector3.new(88, 0.5, 88), Vector3.new(0, 0.0, 0), PALETTE.cobbleMain, Enum.Material.Cobblestone, nil, roadsFolder)

part("ArrivalPlazaInner", Vector3.new(66, 0.54, 66), Vector3.new(0, 0.02, 0), PALETTE.cobbleLight, Enum.Material.Cobblestone, nil, roadsFolder)

registerFootprint(0, 0, 48, 48) -- ห้ามต้นไม้เกิดในจัตุรัสกลางเมืองเด็ดขาด



-- จุดเกิดหลักของผู้เล่นอยู่หน้าสระน้ำพุบนวงเวียนหินพอดี (0, y, -14)

local spawnLoc = Instance.new("SpawnLocation")

spawnLoc.Name = "PronteraSpawn"

spawnLoc.Size = Vector3.new(6, 0.5, 6)

spawnLoc.Position = Vector3.new(0, 0.25, -14)

spawnLoc.Anchored = true

spawnLoc.CanCollide = false

spawnLoc.Transparency = 1

spawnLoc.TopSurface = Enum.SurfaceType.Smooth

spawnLoc.BottomSurface = Enum.SurfaceType.Smooth

spawnLoc.Parent = root



-- วงเวียนหินรอบน้ำพุ (ศูนย์กลางอยู่ที่จุดตัดถนน 4 ทิศ (0, 0, 0) ตรงแนวถนน 100%)

local outerRing = part("PlazaCircleOuter", Vector3.new(0.58, 38, 38), Vector3.new(0, 0.04, 0), PALETTE.cobbleDark, Enum.Material.Cobblestone, Enum.PartType.Cylinder, roadsFolder)

outerRing.CFrame = CFrame.new(0, 0.04, 0) * CFrame.Angles(0, 0, math.rad(90))

local innerRing = part("PlazaCircleInner", Vector3.new(0.62, 24, 24), Vector3.new(0, 0.06, 0), PALETTE.cobbleLight, Enum.Material.Cobblestone, Enum.PartType.Cylinder, roadsFolder)

innerRing.CFrame = CFrame.new(0, 0.06, 0) * CFrame.Angles(0, 0, math.rad(90))

local centerMedallion = part("PlazaCenterMedallion", Vector3.new(0.65, 14, 14), Vector3.new(0, 0.08, 0), PALETTE.stoneLight, Enum.Material.Marble, Enum.PartType.Cylinder, roadsFolder)

centerMedallion.CFrame = CFrame.new(0, 0.08, 0) * CFrame.Angles(0, 0, math.rad(90))



-- น้ำพุหินกลมกลางวงเวียน ณ จุดตัดถนน (0, y, 0)

local basin = part("PlazaFountainBasin", Vector3.new(1.4, 10.6, 10.6), Vector3.new(0, 0.7, 0), Color3.fromRGB(132, 144, 150), Enum.Material.Slate, Enum.PartType.Cylinder, roadsFolder, true)

basin.CFrame = CFrame.new(0, 0.7, 0) * CFrame.Angles(0, 0, math.rad(90))

local basinRim = part("PlazaFountainRim", Vector3.new(1.6, 9.2, 9.2), Vector3.new(0, 0.8, 0), PALETTE.stoneLight, Enum.Material.Marble, Enum.PartType.Cylinder, roadsFolder, false)

basinRim.CFrame = CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, math.rad(90))

local water = part("PlazaFountainWater", Vector3.new(1.5, 8.4, 8.4), Vector3.new(0, 0.95, 0), Color3.fromRGB(78, 184, 214), Enum.Material.Glass, Enum.PartType.Cylinder, roadsFolder, false)

water.CFrame = CFrame.new(0, 0.95, 0) * CFrame.Angles(0, 0, math.rad(90))

water.Transparency = 0.18

part("PlazaFountainStem", Vector3.new(1.8, 3.8, 1.8), Vector3.new(0, 2.5, 0), PALETTE.stoneLight, Enum.Material.Marble, nil, roadsFolder, false)

local fountainBowl = part("PlazaFountainUpperBowl", Vector3.new(0.9, 4.6, 4.6), Vector3.new(0, 4.0, 0), PALETTE.stoneLight, Enum.Material.Marble, Enum.PartType.Cylinder, roadsFolder, false)

fountainBowl.CFrame = CFrame.new(0, 4.0, 0) * CFrame.Angles(0, 0, math.rad(90))

local fountainOrb = part("PlazaFountainOrb", Vector3.new(1.6, 1.6, 1.6), Vector3.new(0, 5.3, 0), Color3.fromRGB(115, 215, 240), Enum.Material.Neon, Enum.PartType.Ball, roadsFolder, false)

local fountainLight = Instance.new("PointLight")

fountainLight.Color = Color3.fromRGB(125, 220, 255)

fountainLight.Brightness = 1.1

fountainLight.Range = 24

fountainLight.Parent = fountainOrb



local fountainSpray = Instance.new("ParticleEmitter")

fountainSpray.Name = "FountainWaterSpray"

fountainSpray.Color = ColorSequence.new({

	ColorSequenceKeypoint.new(0, Color3.fromRGB(225, 248, 255)),

	ColorSequenceKeypoint.new(1, Color3.fromRGB(155, 225, 255)),

})

fountainSpray.Size = NumberSequence.new({

	NumberSequenceKeypoint.new(0, 0.45),

	NumberSequenceKeypoint.new(0.5, 0.85),

	NumberSequenceKeypoint.new(1, 1.3),

})

fountainSpray.Transparency = NumberSequence.new({

	NumberSequenceKeypoint.new(0, 0.1),

	NumberSequenceKeypoint.new(0.7, 0.35),

	NumberSequenceKeypoint.new(1, 0.95),

})

fountainSpray.Speed = NumberRange.new(5.5, 8.5)

fountainSpray.SpreadAngle = Vector2.new(25, 25)

fountainSpray.EmissionDirection = Enum.NormalId.Top

fountainSpray.Lifetime = NumberRange.new(1.1, 1.6)

fountainSpray.Rate = 32

fountainSpray.Acceleration = Vector3.new(0, -16, 0)

fountainSpray.Parent = fountainOrb



-- ถนนหลัก 4 ทิศ (กว้าง 20 studs ตัดผ่านจุดศูนย์กลางวงเวียนน้ำพุ (0,0,0) พอดี)

part("NorthMainAvenue", Vector3.new(20, 0.44, 140), Vector3.new(0, 0.0, -106), PALETTE.cobbleMain, Enum.Material.Cobblestone, nil, roadsFolder)

part("SouthMainAvenue", Vector3.new(20, 0.44, 200), Vector3.new(0, 0.0, 142), PALETTE.cobbleMain, Enum.Material.Cobblestone, nil, roadsFolder)

part("WestMainAvenue",  Vector3.new(260, 0.44, 20), Vector3.new(-170, 0.0, 0), PALETTE.cobbleMain, Enum.Material.Cobblestone, nil, roadsFolder)

part("EastGateRoadConnector", Vector3.new(44, 0.44, 20), Vector3.new(62, 0.0, 0), PALETTE.cobbleMain, Enum.Material.Cobblestone, nil, roadsFolder)



-- ถนนสายตะวันออกผ่านหุบเขาล่ามอนสเตอร์ (X = 80 ถึง 330) พร้อมขอบหินสองข้างทาง

part("TrainingRoad", Vector3.new(260, 0.36, 14), Vector3.new(205, 0.0, 0), PALETTE.dirtRoad, Enum.Material.Cobblestone, nil, roadsFolder)

part("RoadCenter", Vector3.new(250, 0.42, 3.2), Vector3.new(205, 0.02, 0), PALETTE.cobbleLight, Enum.Material.Cobblestone, nil, roadsFolder)

part("TrainingRoadCurbN", Vector3.new(256, 0.5, 1.0), Vector3.new(205, 0.2, -7.2), PALETTE.stoneWall, Enum.Material.Cobblestone, nil, roadsFolder)

part("TrainingRoadCurbS", Vector3.new(256, 0.5, 1.0), Vector3.new(205, 0.2,  7.2), PALETTE.stoneWall, Enum.Material.Cobblestone, nil, roadsFolder)



-- ถนนรองในย่านพักอาศัยด้านตะวันตก (กว้าง 12 studs, เริ่มตั้งแต่ X = -85 ไปถึง X = -275 เพื่อไม่ให้ผ่าทะลุอาคารรอบวงเวียนหรือมหาวิหาร)

for _, zRoad in ipairs({-70, 70, 140}) do

	part("SecondaryRoad_EW_" .. zRoad, Vector3.new(190, 0.38, 12), Vector3.new(-175, -0.02, zRoad), PALETTE.dirtRoad, Enum.Material.Cobblestone, nil, roadsFolder)

	registerFootprint(-175, zRoad, 98, 9)

end

for _, xRoad in ipairs({-85, -175, -265}) do

	part("SecondaryRoad_NS_" .. xRoad, Vector3.new(12, 0.38, 222), Vector3.new(xRoad, -0.02, 35), PALETTE.dirtRoad, Enum.Material.Cobblestone, nil, roadsFolder)

	registerFootprint(xRoad, 35, 9, 114)

end

registerFootprint(0, -106, 14, 72)

registerFootprint(0, 145, 14, 100)

registerFootprint(-170, 0, 132, 14)



-- เสาไฟถนน (วางริมถนนเท่านั้น ไม่ขวางหน้าประตูบ้าน)

local function lantern(x, z)

	part("LanternPost", Vector3.new(0.65, 7.5, 0.65), Vector3.new(x, 3.75, z), PALETTE.timberDark, Enum.Material.Wood, nil, roadsFolder, false)

	part("LanternArm", Vector3.new(1.5, 0.4, 0.4), Vector3.new(x, 7.3, z), PALETTE.timberDark, Enum.Material.Wood, nil, roadsFolder, false)

	local lamp = part("Lantern", Vector3.new(1.2, 1.4, 1.2), Vector3.new(x, 6.8, z), Color3.fromRGB(255, 214, 122), Enum.Material.Neon, nil, roadsFolder, false)

	local light = Instance.new("PointLight")

	light.Color = lamp.Color

	light.Brightness = 0.85

	light.Range = 18

	light.Parent = lamp

end

for _, z in ipairs({-130, -80, 80, 130, 180}) do

	lantern(-11, z)

	lantern(11, z)

end

for _, x in ipairs({48, 72, 98, 132, 154, 195, 240, 285}) do

	lantern(x, -9)

	lantern(x, 9)

end



-- ============================================================

-- 3. จุดบริการผู้เล่น & NPC หลักในร้านค้ารอบจัตุรัส

-- ============================================================

-- ป้ายแนะนำสนามฝึก Novice (ย้ายมาที่จุดเปิดโล่ง X = -18, Z = -6 ไม่ชนร้านเบเกอรี่และไม่ขวางทางเดิน)

part("GuideSignSupportLeft", Vector3.new(0.45, 5, 0.45), Vector3.new(-18, 2.5, -8.2), PALETTE.timberDark, Enum.Material.Wood)

part("GuideSignSupportRight", Vector3.new(0.45, 5, 0.45), Vector3.new(-18, 2.5, -3.8), PALETTE.timberDark, Enum.Material.Wood)

local sign = part("GuideSign", Vector3.new(0.45, 3, 5), Vector3.new(-18, 4.3, -6), Color3.fromRGB(86, 111, 70), Enum.Material.WoodPlanks, nil, root, false)



local function attachGuideLabel(face)

	local boardGui = Instance.new("SurfaceGui")

	boardGui.Name = "GuideLabel_" .. face.Name

	boardGui.Face = face

	boardGui.CanvasSize = Vector2.new(500, 220)

	boardGui.Parent = sign

	local label = Instance.new("TextLabel")

	label.Size = UDim2.fromScale(1, 1)

	label.BackgroundTransparency = 1

	label.Text = "PRONTERA\nสนามฝึก Novice"

	label.TextColor3 = Color3.fromRGB(255, 236, 175)

	label.TextScaled = true

	label.Font = Enum.Font.GothamBold

	label.Parent = boardGui

end

attachGuideLabel(Enum.NormalId.Right)

attachGuideLabel(Enum.NormalId.Left)



local prompt = Instance.new("ProximityPrompt")

prompt.Name = "OpenGuide"

prompt.ActionText = "ดูวิธีเล่น"

prompt.ObjectText = "ป้ายแนะนำสนามฝึก"

prompt.KeyboardKeyCode = Enum.KeyCode.F

prompt.HoldDuration = 0

prompt.MaxActivationDistance = 10

prompt.Parent = sign

prompt.Triggered:Connect(function(player)

	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")

	local openTutorial = remotes and remotes:FindFirstChild("OpenTutorial")

	if openTutorial then openTutorial:FireClient(player) end

end)



-- ============================================================

-- Ragnarok M Style Mission Board (กระดานภารกิจประจำวัน)

-- ============================================================

local boardModel = Instance.new("Model")

boardModel.Name = "MissionBoard"

boardModel.Parent = root



local boardPos = Vector3.new(-58, 0, -52)

local boardSupportLeft = part("DailyQuestBoardSupportLeft", Vector3.new(0.5, 5.2, 0.5), boardPos + Vector3.new(-3.0, 2.6, 0), PALETTE.timberDark, Enum.Material.Wood, nil, boardModel)

local boardSupportRight = part("DailyQuestBoardSupportRight", Vector3.new(0.5, 5.2, 0.5), boardPos + Vector3.new(3.0, 2.6, 0), PALETTE.timberDark, Enum.Material.Wood, nil, boardModel)

local boardRoofPeak = part("DailyQuestBoardRoofPeak", Vector3.new(8.6, 0.7, 2.2), boardPos + Vector3.new(0, 5.4, 0), Color3.fromRGB(110, 65, 38), Enum.Material.WoodPlanks, nil, boardModel)

local boardRoofTrim = part("DailyQuestBoardRoofTrim", Vector3.new(9.0, 0.35, 2.4), boardPos + Vector3.new(0, 5.7, 0), Color3.fromRGB(165, 120, 65), Enum.Material.Wood, nil, boardModel)

local questBoard = part("DailyQuestBoard", Vector3.new(7.2, 3.6, 0.45), boardPos + Vector3.new(0, 3.2, 0), Color3.fromRGB(140, 95, 55), Enum.Material.WoodPlanks, nil, boardModel, false)



-- แผ่นประกาศเควสติดบนกระดาน (Notice Parchments)

for i = 1, 4 do

	local ox = (i - 2.5) * 1.5

	local poster = part("QuestPoster_" .. i, Vector3.new(1.1, 1.5, 0.08), boardPos + Vector3.new(ox, 3.2 + (i % 2 == 0 and 0.15 or -0.15), 0.25), Color3.fromRGB(244, 235, 210), Enum.Material.SmoothPlastic, nil, boardModel, false)

	local pgui = Instance.new("SurfaceGui")

	pgui.Face = Enum.NormalId.Back

	pgui.CanvasSize = Vector2.new(100, 140)

	pgui.Parent = poster

	local plabel = Instance.new("TextLabel")

	plabel.Size = UDim2.fromScale(1, 1)

	plabel.BackgroundTransparency = 1

	plabel.Text = ({"📜\nWANTED", "⚔️\nMISSION", "💎\nGATHER", "📦\nSUPPLY"})[i]

	plabel.TextColor3 = Color3.fromRGB(100, 60, 25)

	plabel.TextSize = 18

	plabel.Font = Enum.Font.GothamBold

	plabel.Parent = pgui

end



-- ป้ายชื่อกระดานด้านหน้า

local questBoardGui = Instance.new("SurfaceGui")

questBoardGui.Name = "DailyQuestBoardLabel"

questBoardGui.Face = Enum.NormalId.Back

questBoardGui.CanvasSize = Vector2.new(640, 240)

questBoardGui.Parent = questBoard

local questBoardLabel = Instance.new("TextLabel")

questBoardLabel.Size = UDim2.fromScale(1, 1)

questBoardLabel.BackgroundTransparency = 1

questBoardLabel.Text = "📜 กระดานภารกิจ\n(Mission Board)"

questBoardLabel.TextColor3 = Color3.fromRGB(255, 240, 185)

questBoardLabel.TextSize = 36

questBoardLabel.Font = Enum.Font.GothamBold

questBoardLabel.Parent = questBoardGui



-- วงกลมอินเทอร์แอคทีฟสีเขียวเรืองแสงบนพื้นหน้ากระดาน (Green Target Circle) สไตล์ Ragnarok M

local greenRing = Instance.new("Part")

greenRing.Name = "MissionBoardCircle"

greenRing.Shape = Enum.PartType.Cylinder

greenRing.Size = Vector3.new(0.08, 6.5, 6.5)

greenRing.CFrame = CFrame.new(boardPos + Vector3.new(0, 0.12, 2.5)) * CFrame.Angles(0, 0, math.rad(90))

greenRing.Color = Color3.fromRGB(60, 220, 90)

greenRing.Material = Enum.Material.Neon

greenRing.Transparency = 0.55

greenRing.Anchored = true

greenRing.CanCollide = false

greenRing.Parent = boardModel



local ringGui = Instance.new("BillboardGui")

ringGui.Size = UDim2.fromOffset(160, 36)

ringGui.StudsOffset = Vector3.new(0, 0.4, 0)

ringGui.MaxDistance = 35

ringGui.AlwaysOnTop = false

ringGui.Adornee = greenRing

ringGui.Parent = greenRing

local ringLbl = Instance.new("TextLabel")

ringLbl.Size = UDim2.fromScale(1, 1)

ringLbl.BackgroundTransparency = 1

ringLbl.Text = "Mission Board"

ringLbl.TextColor3 = Color3.fromRGB(90, 255, 120)

ringLbl.Font = Enum.Font.GothamBold

ringLbl.TextSize = 14

ringLbl.Parent = ringGui



-- Floating Quest Icon / บับเบิ้ลลอยด้านบน

local floatingQuestSign = Instance.new("BillboardGui")

floatingQuestSign.Size = UDim2.fromOffset(130, 46)

floatingQuestSign.StudsOffset = Vector3.new(0, 3.8, 0)

floatingQuestSign.AlwaysOnTop = false

floatingQuestSign.MaxDistance = 35

floatingQuestSign.Adornee = questBoard

floatingQuestSign.Parent = questBoard

local questSignLbl = Instance.new("TextLabel")

questSignLbl.Size = UDim2.fromScale(1, 1)

questSignLbl.BackgroundColor3 = Color3.fromRGB(24, 30, 45)

questSignLbl.BackgroundTransparency = 0.15

questSignLbl.TextColor3 = Color3.fromRGB(255, 215, 75)

questSignLbl.Text = "📜 Quest\nMission Board"

questSignLbl.Font = Enum.Font.GothamBold

questSignLbl.TextSize = 12

questSignLbl.Parent = floatingQuestSign

Instance.new("UICorner", questSignLbl).CornerRadius = UDim.new(0, 8)

local questSignStroke = Instance.new("UIStroke", questSignLbl)

questSignStroke.Color = Color3.fromRGB(245, 190, 70)

questSignStroke.Thickness = 1.4



-- Proximity Prompt & Click Detector

local questPrompt = Instance.new("ProximityPrompt")

questPrompt.Name = "OpenDailyQuestBoard"

questPrompt.ActionText = "เปิดกระดานภารกิจ"

questPrompt.ObjectText = "กระดานเควส (Mission Board)"

questPrompt.KeyboardKeyCode = Enum.KeyCode.F

questPrompt.HoldDuration = 0

questPrompt.MaxActivationDistance = 14

questPrompt.Parent = questBoard



local function triggerBoard(player)

	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")

	local openDailyQuests = remotes and remotes:FindFirstChild("OpenDailyQuests")

	if openDailyQuests then openDailyQuests:FireClient(player) end

end

questPrompt.Triggered:Connect(triggerBoard)



local clickDetector = Instance.new("ClickDetector")

clickDetector.MaxActivationDistance = 20

clickDetector.Parent = questBoard

clickDetector.MouseClick:Connect(triggerBoard)



-- NPC ช่างตีเหล็กหลัก (ย้ายเข้าไปอยู่ในร้านตีเหล็ก BlacksmithForgeHall มุมตะวันตกเฉียงเหนือของจัตุรัสน้ำพุ @ -32, 3, -27.5)

local smith = Instance.new("Model")

smith.Name = "Blacksmith"

smith.Parent = root

local function smithPart(name, size, position, color, material, shape)

	return part(name, size, position, color, material or Enum.Material.SmoothPlastic, shape, smith, false)

end

local sx, sy, sz = -32, 3.0, -27.5

local smithTorso = smithPart("HumanoidRootPart", Vector3.new(1.6, 2, 0.8), Vector3.new(sx, sy, sz), Color3.fromRGB(125, 55, 42))

smith.PrimaryPart = smithTorso

smithPart("Apron", Vector3.new(1.65, 1.25, 0.16), Vector3.new(sx, sy - 0.25, sz + 0.45), Color3.fromRGB(65, 47, 39))

smithPart("Head", Vector3.new(1.15, 1.15, 1.05), Vector3.new(sx, sy + 1.65, sz), Color3.fromRGB(224, 174, 137), Enum.Material.SmoothPlastic, Enum.PartType.Ball)

smithPart("Hair", Vector3.new(1.2, 0.36, 1.1), Vector3.new(sx, sy + 2.13, sz), Color3.fromRGB(144, 57, 43), Enum.Material.SmoothPlastic, Enum.PartType.Ball)

smithPart("ArmLeft", Vector3.new(0.42, 1.55, 0.45), Vector3.new(sx - 1.05, sy + 0.2, sz + 0.1), Color3.fromRGB(224, 174, 137))

smithPart("ArmRight", Vector3.new(0.42, 1.55, 0.45), Vector3.new(sx + 1.05, sy + 0.2, sz + 0.1), Color3.fromRGB(224, 174, 137))

smithPart("LegLeft", Vector3.new(0.58, 1.2, 0.62), Vector3.new(sx - 0.38, sy - 1.55, sz), Color3.fromRGB(72, 62, 58))

smithPart("LegRight", Vector3.new(0.58, 1.2, 0.62), Vector3.new(sx + 0.38, sy - 1.55, sz), Color3.fromRGB(72, 62, 58))

smithPart("HammerHandle", Vector3.new(0.2, 0.95, 0.2), Vector3.new(sx + 1.2, sy + 0.75, sz + 0.45), Color3.fromRGB(105, 72, 43), Enum.Material.Wood)

smithPart("HammerHead", Vector3.new(0.7, 0.3, 0.36), Vector3.new(sx + 1.2, sy + 1.3, sz + 0.45), Color3.fromRGB(126, 135, 148), Enum.Material.Metal)

smithPart("AnvilBase", Vector3.new(2, 1.25, 1.3), Vector3.new(sx + 2.6, 1.2, sz + 1.2), Color3.fromRGB(66, 72, 82), Enum.Material.Metal)

smithPart("AnvilHorn", Vector3.new(2.4, 0.38, 0.72), Vector3.new(sx + 2.6, 2.02, sz + 1.2), Color3.fromRGB(117, 126, 137), Enum.Material.Metal)

local smithBB = Instance.new("BillboardGui")

smithBB.Size = UDim2.fromOffset(160, 36)

smithBB.StudsOffset = Vector3.new(0, 2.8, 0)

smithBB.MaxDistance = 32

smithBB.AlwaysOnTop = false

smithBB.Parent = smithTorso

local smithLabel = Instance.new("TextLabel")

smithLabel.Size = UDim2.fromScale(1, 1)

smithLabel.BackgroundTransparency = 1

smithLabel.Text = "ช่างตีเหล็ก Hollgrehenn\n[F] ตีบวกอุปกรณ์"

smithLabel.TextColor3 = Color3.fromRGB(255, 226, 160)

smithLabel.TextStrokeTransparency = 0.2

smithLabel.TextScaled = true

smithLabel.Font = Enum.Font.GothamBold

smithLabel.Parent = smithBB

local smithPrompt = Instance.new("ProximityPrompt")

smithPrompt.Name = "OpenBlacksmith"

smithPrompt.ActionText = "ตีบวกอุปกรณ์"

smithPrompt.ObjectText = "ช่างตีเหล็ก Hollgrehenn"

smithPrompt.KeyboardKeyCode = Enum.KeyCode.F

smithPrompt.HoldDuration = 0

smithPrompt.MaxActivationDistance = 12

smithPrompt.RequiresLineOfSight = false

local promptAttachment = Instance.new("Attachment")

promptAttachment.Name = "BlacksmithPromptPoint"

promptAttachment.Position = Vector3.new(0, 2.1, 0.45)

promptAttachment.Parent = smithTorso

smithPrompt.Parent = promptAttachment

smithPrompt.Triggered:Connect(function(player)

	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")

	if remotes then

		local openRefinement = remotes:FindFirstChild("OpenRefinement")

		if openRefinement then openRefinement:FireClient(player) end

	end

end)



-- ============================================================

-- 4. ม้านั่งหินและกระถางดอกไม้ประดับรอบวงเวียนสระน้ำพุกลางเมือง (ศูนย์กลางที่ (0, 0, 0))

-- ============================================================

local marketFolder = Instance.new("Folder")

marketFolder.Name = "TownMarketStalls"

marketFolder.Parent = root



for idx, angleDeg in ipairs({45, 135, 225, 315}) do

	local rad = math.rad(angleDeg)

	local bPos = Vector3.new(math.cos(rad) * 15.5, 0.25, math.sin(rad) * 15.5)

	local origin = CFrame.lookAt(bPos, Vector3.new(0, 0.25, 0))

	cframePart("PlazaBenchSeat_" .. idx, Vector3.new(5.0, 0.4, 1.8), origin * CFrame.new(0, 1.1, 0), PALETTE.stoneLight, Enum.Material.Cobblestone, marketFolder, true)

	cframePart("PlazaBenchLegL_" .. idx, Vector3.new(0.8, 1.0, 1.6), origin * CFrame.new(-1.9, 0.5, 0), PALETTE.stoneDark, Enum.Material.Cobblestone, marketFolder, true)

	cframePart("PlazaBenchLegR_" .. idx, Vector3.new(0.8, 1.0, 1.6), origin * CFrame.new( 1.9, 0.5, 0), PALETTE.stoneDark, Enum.Material.Cobblestone, marketFolder, true)

	cframePart("PlazaPlanter_" .. idx, Vector3.new(2.2, 1.4, 2.2), origin * CFrame.new(3.6, 0.7, 0), PALETTE.stoneWall, Enum.Material.Cobblestone, marketFolder, true)

	cframePart("PlazaBush_" .. idx, Vector3.new(2.4, 1.8, 2.4), origin * CFrame.new(3.6, 1.9, 0), PALETTE.meadowGrass, Enum.Material.Grass, marketFolder, false, Enum.PartType.Ball)

end



-- 4 ร้านค้าแผงลอยกลางแจ้ง (Open-Air Market Stalls) พร้อมผ้าใบกันสาดลายทางสลับสี

local stallData = {

	{

		name = "ProduceStall", angle = 50, dist = 21.5,

		col1 = Color3.fromRGB(205, 45, 45), col2 = Color3.fromRGB(245, 240, 230),

		category = "Produce",

	},

	{

		name = "FishmongerStall", angle = 130, dist = 21.5,

		col1 = Color3.fromRGB(38, 118, 195), col2 = Color3.fromRGB(245, 240, 230),

		category = "Fish",

	},

	{

		name = "BakeryStall", angle = 230, dist = 21.5,

		col1 = Color3.fromRGB(218, 142, 38), col2 = Color3.fromRGB(245, 240, 230),

		category = "Bakery",

	},

	{

		name = "ApothecaryStall", angle = 310, dist = 21.5,

		col1 = Color3.fromRGB(118, 52, 168), col2 = Color3.fromRGB(235, 195, 52),

		category = "Curio",

	},

}



for _, st in ipairs(stallData) do

	local sRad = math.rad(st.angle)

	local sPos = Vector3.new(math.cos(sRad) * st.dist, 0, math.sin(sRad) * st.dist)

	local sOrigin = CFrame.lookAt(sPos, Vector3.new(0, 0, 0))



	-- โต๊ะแผงขายของ

	cframePart(st.name .. "_Counter", Vector3.new(6.8, 2.3, 2.8), sOrigin * CFrame.new(0, 1.15, 0), PALETTE.timberMed, Enum.Material.WoodPlanks, marketFolder, true)

	cframePart(st.name .. "_TableTrim", Vector3.new(7.1, 0.35, 3.1), sOrigin * CFrame.new(0, 2.35, 0), PALETTE.timberDark, Enum.Material.Wood, marketFolder, true)



	-- เสาไม้ 4 มุมค้ำผ้าใบ

	for _, sx in ipairs({-3.2, 3.2}) do

		for _, sz in ipairs({-1.3, 1.3}) do

			local postH = (sz < 0) and 7.4 or 8.2

			cframePart(st.name .. "_Post", Vector3.new(0.42, postH, 0.42), sOrigin * CFrame.new(sx, postH / 2, sz), PALETTE.timberDark, Enum.Material.Wood, marketFolder, false)

		end

	end



	-- หลังคาผ้าใบกันสาดลายทาง (Striped Fabric Canopy)

	local awningCF = sOrigin * CFrame.new(0, 7.8, 0) * CFrame.Angles(math.rad(8), 0, 0)

	for i = 1, 5 do

		local stripX = (i - 3) * 1.45

		local stripCol = (i % 2 == 1) and st.col1 or st.col2

		cframePart(st.name .. "_AwningStrip_" .. i, Vector3.new(1.45, 0.2, 4.2), awningCF * CFrame.new(stripX, 0, 0), stripCol, Enum.Material.Fabric, marketFolder, false)

	end



	-- โคมไฟแขวนใต้กันสาด

	local lanternPt = cframePart(st.name .. "_Lantern", Vector3.new(0.65, 0.75, 0.65), awningCF * CFrame.new(0, -0.6, -1.5), PALETTE.windowGlow, Enum.Material.Neon, marketFolder, false, Enum.PartType.Ball)

	local lLight = Instance.new("PointLight")

	lLight.Color = PALETTE.windowGlow

	lLight.Brightness = 0.95

	lLight.Range = 14

	lLight.Parent = lanternPt



	-- สิ่งของจัดวางตามประเภทแผงลอย

	if st.category == "Produce" then

		cframePart(st.name .. "_Crate1", Vector3.new(2.4, 1.0, 2.0), sOrigin * CFrame.new(-1.8, 2.85, 0), PALETTE.timberDark, Enum.Material.Wood, marketFolder, true)

		for ax = -0.7, 0.7, 0.7 do

			for az = -0.5, 0.5, 0.5 do

				cframePart(st.name .. "_Apple", Vector3.new(0.65, 0.65, 0.65), sOrigin * CFrame.new(-1.8 + ax, 3.45, az), Color3.fromRGB(225, 42, 42), Enum.Material.SmoothPlastic, marketFolder, false, Enum.PartType.Ball)

			end

		end

		cframePart(st.name .. "_Crate2", Vector3.new(2.4, 1.0, 2.0), sOrigin * CFrame.new(1.8, 2.85, 0), PALETTE.timberDark, Enum.Material.Wood, marketFolder, true)

		cframePart(st.name .. "_Pumpkin", Vector3.new(1.4, 1.2, 1.4), sOrigin * CFrame.new(1.8, 3.6, 0), Color3.fromRGB(235, 125, 30), Enum.Material.SmoothPlastic, marketFolder, false, Enum.PartType.Ball)

		cframePart(st.name .. "_Sack", Vector3.new(1.8, 2.4, 1.8), sOrigin * CFrame.new(-4.4, 1.2, -0.2), Color3.fromRGB(215, 195, 160), Enum.Material.Fabric, marketFolder, true, Enum.PartType.Cylinder)

	elseif st.category == "Fish" then

		cframePart(st.name .. "_Barrel", Vector3.new(2.2, 2.2, 2.2), sOrigin * CFrame.new(-1.8, 1.1, -1.8), PALETTE.timberDark, Enum.Material.Wood, marketFolder, true, Enum.PartType.Cylinder)

		cframePart(st.name .. "_Ice", Vector3.new(1.9, 0.3, 1.9), sOrigin * CFrame.new(-1.8, 2.2, -1.8), Color3.fromRGB(195, 238, 255), Enum.Material.Glass, marketFolder, false, Enum.PartType.Cylinder)

		for fx = -1.2, 1.2, 1.2 do

			cframePart(st.name .. "_Fish_" .. fx, Vector3.new(1.4, 0.35, 0.6), sOrigin * CFrame.new(fx, 2.55, 0) * CFrame.Angles(0, math.rad(25 * fx), 0), Color3.fromRGB(175, 190, 205), Enum.Material.Metal, marketFolder, false)

		end

	elseif st.category == "Bakery" then

		for bx = -1.8, 1.8, 1.2 do

			cframePart(st.name .. "_Baguette_" .. bx, Vector3.new(0.5, 0.45, 2.2), sOrigin * CFrame.new(bx, 2.6, 0) * CFrame.Angles(0, math.rad(15), 0), Color3.fromRGB(224, 172, 88), Enum.Material.Wood, marketFolder, false)

			cframePart(st.name .. "_Loaf_" .. bx, Vector3.new(1.1, 0.8, 1.1), sOrigin * CFrame.new(bx + 0.3, 2.65, 0.8), Color3.fromRGB(192, 134, 65), Enum.Material.SmoothPlastic, marketFolder, false, Enum.PartType.Ball)

		end

	elseif st.category == "Curio" then

		local potionCols = {

			Color3.fromRGB(255, 55, 55),

			Color3.fromRGB(55, 145, 255),

			Color3.fromRGB(55, 225, 115),

			Color3.fromRGB(185, 75, 235),

		}

		for pi, pcol in ipairs(potionCols) do

			local pFlask = cframePart(st.name .. "_Potion_" .. pi, Vector3.new(0.65, 1.1, 0.65), sOrigin * CFrame.new((pi - 2.5) * 1.3, 3.0, 0), pcol, Enum.Material.Neon, marketFolder, false, Enum.PartType.Ball)

			local potLight = Instance.new("PointLight")

			potLight.Color = pcol

			potLight.Brightness = 0.8

			potLight.Range = 6

			potLight.Parent = pFlask

		end

	end

end



-- ธงราวสามเหลี่ยมเทศกาล (Festive Triangular Bunting Strings) โยงระหว่างเสาแผงลอยรอบจัตุรัส

local buntingColors = {

	Color3.fromRGB(235, 55, 55),

	Color3.fromRGB(250, 210, 45),

	Color3.fromRGB(45, 125, 235),

	Color3.fromRGB(52, 195, 95),

	Color3.fromRGB(175, 65, 225),

	Color3.fromRGB(245, 130, 42),

}



local flagIdx = 0

for i = 1, #stallData do

	local nextI = (i % #stallData) + 1

	local r1 = math.rad(stallData[i].angle)

	local r2 = math.rad(stallData[nextI].angle)

	local p1 = Vector3.new(math.cos(r1) * 21.5, 7.8, math.sin(r1) * 21.5)

	local p2 = Vector3.new(math.cos(r2) * 21.5, 7.8, math.sin(r2) * 21.5)



	local mid = (p1 + p2) / 2 + Vector3.new(0, -1.1, 0)

	local segs = { {p1, mid}, {mid, p2} }

	for _, seg in ipairs(segs) do

		local sp1, sp2 = seg[1], seg[2]

		local dVec = sp2 - sp1

		local sLen = dVec.Magnitude

		local sMid = (sp1 + sp2) / 2

		cframePart("BuntingRope_" .. flagIdx, Vector3.new(0.08, 0.08, sLen), CFrame.lookAt(sMid, sp2), PALETTE.timberDark, Enum.Material.Fabric, marketFolder, false)

		for step = 0.2, 0.85, 0.22 do

			flagIdx = flagIdx + 1

			local flagPos = sp1:Lerp(sp2, step)

			local fCol = buntingColors[((flagIdx - 1) % #buntingColors) + 1]

			cframePart("BuntingFlag_" .. flagIdx, Vector3.new(0.95, 1.25, 0.08), CFrame.new(flagPos + Vector3.new(0, -0.65, 0)) * CFrame.Angles(0, math.rad(flagIdx * 17), 0), fCol, Enum.Material.Fabric, marketFolder, false)

		end

	end

end



-- ============================================================

-- 5. ฟังก์ชันสร้าง NPC ประจำในอาคารที่เปิดเข้าได้ (สำหรับรับ-ส่งเควส/คุย)

-- ============================================================

local function buildInteriorNpc(parentModel, originCF, npcSpec)

	local npc = Instance.new("Model")

	npc.Name = npcSpec.modelName or "HouseNPC"

	npc.Parent = parentModel

	local npcCF = originCF * (npcSpec.localCF or CFrame.new(0, 0, 2))

	local torso = cframePart("HumanoidRootPart", Vector3.new(1.6, 2.0, 0.8), npcCF * CFrame.new(0, 2.8, 0), npcSpec.coatColor or Color3.fromRGB(88, 112, 148), Enum.Material.SmoothPlastic, npc, false)

	npc.PrimaryPart = torso

	cframePart("Head", Vector3.new(1.15, 1.15, 1.15), npcCF * CFrame.new(0, 4.45, 0), Color3.fromRGB(228, 178, 142), Enum.Material.SmoothPlastic, npc, false, Enum.PartType.Ball)

	cframePart("Hair", Vector3.new(1.2, 0.4, 1.2), npcCF * CFrame.new(0, 4.95, 0), npcSpec.hairColor or PALETTE.timberDark, Enum.Material.SmoothPlastic, npc, false, Enum.PartType.Ball)

	cframePart("LegL", Vector3.new(0.55, 1.4, 0.6), npcCF * CFrame.new(-0.38, 1.1, 0), Color3.fromRGB(64, 58, 54), Enum.Material.SmoothPlastic, npc, false)

	cframePart("LegR", Vector3.new(0.55, 1.4, 0.6), npcCF * CFrame.new( 0.38, 1.1, 0), Color3.fromRGB(64, 58, 54), Enum.Material.SmoothPlastic, npc, false)



	local bb = Instance.new("BillboardGui")

	bb.Size = UDim2.fromOffset(150, 32)

	bb.StudsOffset = Vector3.new(0, 2.6, 0)

	bb.MaxDistance = 28

	bb.AlwaysOnTop = false

	bb.Parent = torso

	local lbl = Instance.new("TextLabel")

	lbl.Size = UDim2.fromScale(1, 1)

	lbl.BackgroundTransparency = 1

	lbl.Font = Enum.Font.GothamBold

	lbl.TextScaled = true

	lbl.TextColor3 = Color3.fromRGB(255, 232, 152)

	lbl.TextStrokeTransparency = 0.25

	lbl.Text = npcSpec.displayName

	lbl.Parent = bb



	local att = Instance.new("Attachment")

	att.Position = Vector3.new(0, 1.6, -0.4)

	att.Parent = torso

	local p = Instance.new("ProximityPrompt")

	p.Name = "TalkToNpc"

	p.ObjectText = npcSpec.displayName

	p.ActionText = npcSpec.actionText or "พูดคุย / รับภารกิจ"

	p.KeyboardKeyCode = Enum.KeyCode.F

	p.HoldDuration = 0

	p.MaxActivationDistance = 9

	p.RequiresLineOfSight = false

	p.Parent = att

	p.Triggered:Connect(function(player)

		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")

		if not remotes then return end

		local openNpcDialogue = remotes:FindFirstChild("OpenNpcDialogue")

		if openNpcDialogue and npcSpec.modelName and npcSpec.remoteName ~= "OpenWorldTravel" then

			openNpcDialogue:FireClient(player, npcSpec.modelName)

		end

		local remoteName = npcSpec.remoteName

		if remoteName and remoteName ~= "OpenDailyQuests" then

			local targetRemote = remotes:FindFirstChild(remoteName)

			if targetRemote then targetRemote:FireClient(player) end

		end

		local feedback = remotes:FindFirstChild("SkillFeedback")

		if feedback and npcSpec.greeting and not openNpcDialogue then

			feedback:FireClient(player, npcSpec.displayName .. ": " .. npcSpec.greeting)

		end

	end)

end



-- ============================================================

-- 6. ชุดสร้างอาคารยุคกลาง:

--    - ถ้ามี signTitle (บ้านที่มีชื่อ) -> สร้างเป็นอาคารกลวงเดินเข้าได้จริง (Hollow Interior)

--      ประตูเปิดโล่ง มีพื้นไม้ โต๊ะ เคาน์เตอร์ โคมไฟในบ้าน และวาง NPC ข้างในได้

--    - ถ้าเป็นบ้านประกอบฉากทั่วไป -> สร้างเป็นอาคารทึบเพื่อประหยัด Part

-- ============================================================

local buildingsFolder = Instance.new("Folder")

buildingsFolder.Name = "VillageBuildings"

buildingsFolder.Parent = root



local function buildMedievalBuilding(name, centerPos, yaw, bType, wallCol, roofCol, signTitle, npcSpec)

	local model = Instance.new("Model")

	model.Name = name

	model.Parent = buildingsFolder



	local w, d, floors = 18, 22, 2

	if bType == "Small" then

		w, d, floors = 15, 20, 1

	elseif bType == "Standard" then

		w, d, floors = 20, 24, 2

	elseif bType == "Large" then

		w, d, floors = 22, 30, 2

	elseif bType == "Shop" then

		w, d, floors = 19, 25, 2

	elseif bType == "Inn" then

		w, d, floors = 30, 36, 2

	elseif bType == "Blacksmith" then

		w, d, floors = 22, 26, 2

	end



	-- ลงทะเบียนพื้นที่อาคาร + ลานหน้าบ้านเพื่อห้ามต้นไม้เกิดทับ

	registerFootprint(centerPos.X, centerPos.Z, math.max(w, d) / 2 + 8, math.max(w, d) / 2 + 8)



	local enterable = (signTitle ~= nil)

	local f1H = 9.5

	local f2H = (floors >= 2) and 8.5 or 0

	local totalWallH = f1H + f2H

	local origin = CFrame.new(centerPos.X, 0, centerPos.Z) * CFrame.Angles(0, yaw, 0)



	local function bpart(pName, sz, localCF, col, mat, collide, shp)

		return cframePart(pName, sz, origin * localCF, col, mat, model, collide, shp)

	end



	-- พื้นฐานหิน (เตี้ย 0.5 studs เพื่อให้เดินก้าวเข้าประตูได้ทันทีไม่ต้องกระโดด)

	bpart("Foundation", Vector3.new(w + 1.2, 0.5, d + 1.2), CFrame.new(0, 0.25, 0), PALETTE.stoneDark, Enum.Material.Cobblestone, true)



	local doorW = 5.6

	local doorH = 7.4

	local frontZ = -d / 2



	-- ทางเดินหินปูจากหน้าประตูบ้านทุกหลังเชื่อมออกไปยังถนน/ลานจัตุรัสอย่างเป็นกิจจะลักษณะ

	bpart("FrontPorchStep", Vector3.new(7.2, 0.34, 2.8), CFrame.new(0, 0.17, frontZ - 1.4), PALETTE.stoneLight, Enum.Material.Cobblestone, true)

	bpart("FrontWalkway", Vector3.new(5.6, 0.26, 10.5), CFrame.new(0, 0.13, frontZ - 6.6), PALETTE.cobbleLight, Enum.Material.Cobblestone, true)

	bpart("WalkwayCurbL", Vector3.new(0.45, 0.36, 10.5), CFrame.new(-3.0, 0.18, frontZ - 6.6), PALETTE.stoneDark, Enum.Material.Cobblestone, false)

	bpart("WalkwayCurbR", Vector3.new(0.45, 0.36, 10.5), CFrame.new( 3.0, 0.18, frontZ - 6.6), PALETTE.stoneDark, Enum.Material.Cobblestone, false)



	if enterable then

		-- ── อาคารเดินเข้าได้จริง (Hollow Interior) ──────────────────

		local wallT = 0.85

		local sideWallW = (w - doorW) / 2



		-- พื้นไม้ภายในบ้าน

		bpart("InteriorWoodFloor", Vector3.new(w - 1.0, 0.2, d - 1.0), CFrame.new(0, 0.55, 0), PALETTE.woodFloor, Enum.Material.WoodPlanks, true)

		bpart("EntranceCarpet", Vector3.new(4.4, 0.08, 7.5), CFrame.new(0, 0.66, frontZ + 4.8), PALETTE.roofRed, Enum.Material.Fabric, false)



		-- ผนังหลังและผนังข้างซ้าย-ขวา (กลวงตรงกลาง)

		bpart("BackWallLower", Vector3.new(w, 3.5, wallT), CFrame.new(0, 0.5 + 1.75, d / 2 - wallT / 2), PALETTE.stoneWall, Enum.Material.Cobblestone, true)

		bpart("BackWallUpper", Vector3.new(w, f1H - 3.5, wallT), CFrame.new(0, 0.5 + 3.5 + (f1H - 3.5) / 2, d / 2 - wallT / 2), wallCol, Enum.Material.Sandstone, true)

		for _, sx in ipairs({-1, 1}) do

			bpart("SideWallLower", Vector3.new(wallT, 3.5, d), CFrame.new(sx * (w / 2 - wallT / 2), 0.5 + 1.75, 0), PALETTE.stoneWall, Enum.Material.Cobblestone, true)

			bpart("SideWallUpper", Vector3.new(wallT, f1H - 3.5, d), CFrame.new(sx * (w / 2 - wallT / 2), 0.5 + 3.5 + (f1H - 3.5) / 2, 0), wallCol, Enum.Material.Sandstone, true)

			-- ผนังหน้าซ้าย-ขวา (เว้นช่องประตูกลางกว้าง 5.6 studs)

			local wingX = sx * (doorW / 2 + sideWallW / 2)

			bpart("FrontWingLower", Vector3.new(sideWallW, 3.5, wallT), CFrame.new(wingX, 0.5 + 1.75, frontZ + wallT / 2), PALETTE.stoneWall, Enum.Material.Cobblestone, true)

			bpart("FrontWingUpper", Vector3.new(sideWallW, f1H - 3.5, wallT), CFrame.new(wingX, 0.5 + 3.5 + (f1H - 3.5) / 2, frontZ + wallT / 2), wallCol, Enum.Material.Sandstone, true)

		end

		-- คานเหนือช่องประตู

		bpart("FrontDoorHeader", Vector3.new(doorW, f1H - doorH, wallT), CFrame.new(0, 0.5 + doorH + (f1H - doorH) / 2, frontZ + wallT / 2), wallCol, Enum.Material.Sandstone, true)



		-- วงกบประตู บานประตูไม้เปิดต้อนรับ และโคมไฟหน้าประตู

		for _, sx in ipairs({-1, 1}) do

			bpart("DoorJamb", Vector3.new(0.45, doorH, 1.0), CFrame.new(sx * (doorW / 2), 0.5 + doorH / 2, frontZ + 0.4), PALETTE.timberDark, Enum.Material.Wood, false)

			bpart("DoorLantern", Vector3.new(0.75, 1.0, 0.75), CFrame.new(sx * (doorW / 2 + 1.1), 0.5 + 5.6, frontZ - 0.35), PALETTE.windowGlow, Enum.Material.Neon, false)

		end

		bpart("DoorLintel", Vector3.new(doorW + 0.9, 0.55, 1.1), CFrame.new(0, 0.5 + doorH + 0.2, frontZ + 0.4), PALETTE.timberDark, Enum.Material.Wood, false)

		bpart("OpenDoorLeaf", Vector3.new(2.4, doorH - 0.3, 0.35),

			CFrame.new(-doorW / 2 + 0.4, 0.5 + (doorH - 0.3) / 2, frontZ + 1.2) * CFrame.Angles(0, math.rad(72), 0),

			PALETTE.timberMed, Enum.Material.WoodPlanks, false)



		-- เฟอร์นิเจอร์ภายใน (เคาน์เตอร์ไม้ โต๊ะ ชั้นวางของ และโคมไฟเพดาน)

		bpart("InteriorCounter", Vector3.new(w * 0.52, 2.3, 2.2), CFrame.new(0, 0.5 + 1.15, d * 0.18), PALETTE.timberMed, Enum.Material.WoodPlanks, true)

		bpart("InteriorShelf", Vector3.new(w * 0.58, 5.5, 1.2), CFrame.new(0, 0.5 + 2.75, d / 2 - 1.6), PALETTE.timberDark, Enum.Material.Wood, true)

		local roomLight = bpart("CeilingLantern", Vector3.new(1.4, 1.4, 1.4), CFrame.new(0, 0.5 + f1H - 1.2, 0), PALETTE.windowGlow, Enum.Material.Neon, false, Enum.PartType.Ball)

		local ptLight = Instance.new("PointLight")

		ptLight.Color = PALETTE.windowGlow

		ptLight.Brightness = 1.1

		ptLight.Range = 24

		ptLight.Parent = roomLight



		if npcSpec then

			buildInteriorNpc(model, origin, npcSpec)

		end

	else

		-- ── อาคารประกอบฉากทั่วไป (Solid Block) ──────────────────────

		bpart("FirstFloorStone", Vector3.new(w, 3.5, d), CFrame.new(0, 0.5 + 1.75, 0), PALETTE.stoneWall, Enum.Material.Cobblestone, true)

		bpart("FirstFloorPlaster", Vector3.new(w, f1H - 3.5, d), CFrame.new(0, 0.5 + 3.5 + (f1H - 3.5) / 2, 0), wallCol, Enum.Material.Sandstone, true)

		bpart("DoorFrame", Vector3.new(4.4, 6.8, 0.5), CFrame.new(0, 0.5 + 3.4, frontZ - 0.1), PALETTE.timberDark, Enum.Material.Wood, false)

		bpart("FrontDoor", Vector3.new(3.6, 6.4, 0.4), CFrame.new(0, 0.5 + 3.2, frontZ - 0.2), PALETTE.timberMed, Enum.Material.WoodPlanks, false)

	end



	-- เสาไม้เข้ามุมชั้น 1

	for _, sx in ipairs({-1, 1}) do

		for _, sz in ipairs({-1, 1}) do

			bpart("CornerPostF1", Vector3.new(0.85, f1H, 0.85), CFrame.new(sx * (w / 2), 0.5 + f1H / 2, sz * (d / 2)), PALETTE.timberDark, Enum.Material.Wood, false)

		end

	end



	-- ชั้น 2 (เพดานชั้น 1 + โครงไม้ Tudor)

	local topW, topD = w, d

	if floors >= 2 then

		topW = w + 1.0

		topD = d + 1.2

		local f2CenterY = 0.5 + f1H + f2H / 2

		bpart("FloorDividerBeam", Vector3.new(topW + 0.5, 0.8, topD + 0.5), CFrame.new(0, 0.5 + f1H, 0), PALETTE.timberDark, Enum.Material.Wood, true)

		bpart("SecondFloorPlaster", Vector3.new(topW, f2H, topD), CFrame.new(0, f2CenterY, 0), wallCol, Enum.Material.Sandstone, true)

		for _, sx in ipairs({-1, 1}) do

			for _, sz in ipairs({-1, 1}) do

				bpart("CornerPostF2", Vector3.new(0.8, f2H, 0.8), CFrame.new(sx * (topW / 2), f2CenterY, sz * (topD / 2)), PALETTE.timberDark, Enum.Material.Wood, false)

			end

			for _, fz in ipairs({-1, 1}) do

				bpart("DiagBrace", Vector3.new(0.5, f2H * 0.82, 0.35),

					CFrame.new(sx * (topW * 0.34), f2CenterY, fz * (topD / 2 + 0.08)) * CFrame.Angles(0, 0, sx * math.rad(28)),

					PALETTE.timberDark, Enum.Material.Wood, false)

			end

		end

	end



	-- หลังคาจั่ว

	local roofBaseY = 0.5 + totalWallH

	local roofRise = math.max(7.2, topW * 0.4)

	local slopeLen = math.sqrt((topW / 2 + 2.0) ^ 2 + roofRise ^ 2)

	local slopeAngle = math.atan2(roofRise, topW / 2 + 2.0)

	local roofLenZ = topD + 2.8



	bpart("RoofSlopeLeft",  Vector3.new(slopeLen, 1.0, roofLenZ),

		CFrame.new(-(topW / 4 + 0.5), roofBaseY + roofRise / 2 - 0.2, 0) * CFrame.Angles(0, 0, slopeAngle),

		roofCol, Enum.Material.Slate, false)

	bpart("RoofSlopeRight", Vector3.new(slopeLen, 1.0, roofLenZ),

		CFrame.new( (topW / 4 + 0.5), roofBaseY + roofRise / 2 - 0.2, 0) * CFrame.Angles(0, 0, -slopeAngle),

		roofCol, Enum.Material.Slate, false)

	bpart("RoofRidge", Vector3.new(1.0, 1.0, roofLenZ + 0.5), CFrame.new(0, roofBaseY + roofRise + 0.2, 0), PALETTE.timberDark, Enum.Material.Wood, false)

	bpart("GableFillLower", Vector3.new(topW * 0.66, roofRise * 0.52, topD), CFrame.new(0, roofBaseY + roofRise * 0.26, 0), wallCol, Enum.Material.Sandstone, false)

	bpart("GableFillUpper", Vector3.new(topW * 0.35, roofRise * 0.42, topD), CFrame.new(0, roofBaseY + roofRise * 0.68, 0), wallCol, Enum.Material.Sandstone, false)



	-- หน้าต่าง

	for _, wx in ipairs({ -w * 0.33, w * 0.33 }) do

		bpart("WinFrameF1", Vector3.new(2.6, 3.2, 0.45), CFrame.new(wx, 0.5 + 5.2, frontZ - 0.08), PALETTE.timberDark, Enum.Material.Wood, false)

		bpart("WinGlassF1", Vector3.new(2.0, 2.6, 0.3),  CFrame.new(wx, 0.5 + 5.2, frontZ - 0.18), PALETTE.windowGlow, Enum.Material.Neon, false)

		if floors >= 2 then

			local frontZ2 = -topD / 2

			bpart("WinFrameF2", Vector3.new(2.6, 3.2, 0.45), CFrame.new(wx, 0.5 + f1H + 4.2, frontZ2 - 0.08), PALETTE.timberDark, Enum.Material.Wood, false)

			bpart("WinGlassF2", Vector3.new(2.0, 2.6, 0.3),  CFrame.new(wx, 0.5 + f1H + 4.2, frontZ2 - 0.18), PALETTE.windowGlow, Enum.Material.Neon, false)

		end

	end



	-- ปล่องไฟอิฐ

	bpart("Chimney", Vector3.new(2.4, roofRise + 4.0, 2.4), CFrame.new(-topW * 0.28, roofBaseY + (roofRise + 2) / 2, topD * 0.22), Color3.fromRGB(132, 82, 68), Enum.Material.Brick, false)



	-- กันสาดและป้ายชื่ออาคาร

	if signTitle then

		local awningCol = (bType == "Inn") and Color3.fromRGB(168, 64, 52) or Color3.fromRGB(64, 114, 148)

		bpart("FrontAwning", Vector3.new(w * 0.68, 0.42, 3.0), CFrame.new(0, 0.5 + f1H - 0.6, frontZ - 1.4) * CFrame.Angles(math.rad(14), 0, 0), awningCol, Enum.Material.Fabric, false)

		local signY = 0.5 + f1H + 1.3

		local signZ = -(floors >= 2 and topD or d) / 2 - 0.55

		local signBoard = bpart("Sign", Vector3.new(math.min(w * 0.65, 11), 2.2, 0.35), CFrame.new(0, signY, signZ), PALETTE.timberDark, Enum.Material.WoodPlanks, false)

		local sgui = Instance.new("SurfaceGui")

		sgui.Face = Enum.NormalId.Front

		sgui.CanvasSize = Vector2.new(460, 130)

		sgui.Parent = signBoard

		local slabel = Instance.new("TextLabel")

		slabel.Size = UDim2.fromScale(1, 1)

		slabel.BackgroundTransparency = 1

		slabel.Text = signTitle

		slabel.TextColor3 = Color3.fromRGB(255, 230, 168)

		slabel.TextScaled = true

		slabel.Font = Enum.Font.GothamBold

		slabel.Parent = sgui

	end



	return model

end



-- ============================================================

-- 7. อาคารสำคัญและร้านค้าหลัก 4 มุมรอบสระน้ำพุกลางเมือง + มหาวิหารพร้อมถนนทางเข้ายิ่งใหญ่

-- ============================================================



-- ============================================================

-- กิลด์นักผจญภัย (Adventurer's Guild @ X=-58, Z=-95)

-- ขนาดยาวและใหญ่กว่ามหาวิหารเดิม (กว้าง 48 studs, ยาว 84 studs, สูง 28 studs)

-- ใช้สำหรับรับเควส, มีกระดานเควสด้านหน้าทางเข้า, และเคาน์เตอร์เปลี่ยนอาชีพ

-- ============================================================

do

	local guildCenter = Vector3.new(-58, 0, -95)

	registerFootprint(guildCenter.X, guildCenter.Z, 48, 86)

	registerFootprint(-58, -48, 20, 24)



	local guild = Instance.new("Model")

	guild.Name = "AdventurerGuild"

	guild.Parent = buildingsFolder



	-- ลานหินด้านหน้าและทางเดินเชื่อมต่อสู่ถนนใหญ่

	part("GuildCourtyard", Vector3.new(58, 0.42, 96), guildCenter, PALETTE.cobbleLight, Enum.Material.Cobblestone, nil, guild)

	part("GuildGrandAvenue", Vector3.new(20, 0.44, 46), Vector3.new(-58, 0.02, -42), PALETTE.cobbleMain, Enum.Material.Cobblestone, nil, guild)

	part("GuildAvenueCarpet", Vector3.new(6.8, 0.50, 44), Vector3.new(-58, 0.05, -42), Color3.fromRGB(180, 50, 50), Enum.Material.Fabric, nil, guild, false)



	-- ฐานอาคารหินแกรนิตและพื้นไม้โอ๊คด้านใน

	part("GuildFoundation", Vector3.new(46, 1.2, 82), guildCenter + Vector3.new(0, 0.6, 0), PALETTE.stoneDark, Enum.Material.Cobblestone, nil, guild)

	part("GuildFloor", Vector3.new(44.4, 0.4, 80.4), guildCenter + Vector3.new(0, 1.3, 0), PALETTE.timberMed, Enum.Material.WoodPlanks, nil, guild)



	-- บันไดทางเข้าด้านหน้า

	part("GuildEntranceSteps", Vector3.new(18, 0.6, 6.0), guildCenter + Vector3.new(0, 0.6, 42.5), PALETTE.stoneLight, Enum.Material.Cobblestone, nil, guild)



	-- ผนังอาคารไม้และปูนแบบ Half-Timbered ยุคกลาง

	part("GuildBackWall", Vector3.new(46, 24, 1.6), guildCenter + Vector3.new(0, 13.2, -40.2), PALETTE.plasterWarm, Enum.Material.Sandstone, nil, guild)

	for _, sx in ipairs({-1, 1}) do

		part("GuildSideWall", Vector3.new(1.6, 24, 82), guildCenter + Vector3.new(sx * 22.2, 13.2, 0), PALETTE.plasterWarm, Enum.Material.Sandstone, nil, guild)

		part("GuildFrontWing", Vector3.new(16, 24, 1.6), guildCenter + Vector3.new(sx * 14.5, 13.2, 40.2), PALETTE.plasterWarm, Enum.Material.Sandstone, nil, guild)



		-- เสาหลักมุมอาคารไม้โอ๊คดำ

		part("GuildCornerPostFront", Vector3.new(2.4, 24, 2.4), guildCenter + Vector3.new(sx * 22.2, 13.2, 40.2), PALETTE.timberDark, Enum.Material.Wood, nil, guild)

		part("GuildCornerPostBack",  Vector3.new(2.4, 24, 2.4), guildCenter + Vector3.new(sx * 22.2, 13.2, -40.2), PALETTE.timberDark, Enum.Material.Wood, nil, guild)

	end

	part("GuildDoorHeader", Vector3.new(14, 11, 1.6), guildCenter + Vector3.new(0, 19.5, 40.2), PALETTE.timberDark, Enum.Material.Wood, nil, guild)



	-- ซุ้มประตูมุขด้านหน้า (Entrance Portico)

	part("GuildPorticoRoof", Vector3.new(20, 2.2, 8.5), guildCenter + Vector3.new(0, 15.0, 44.5), PALETTE.roofBrown, Enum.Material.WoodPlanks, nil, guild, false)

	for _, px in ipairs({-9, 9}) do

		part("GuildPorticoPillar", Vector3.new(1.8, 14.0, 1.8), guildCenter + Vector3.new(px, 7.5, 47.8), PALETTE.timberDark, Enum.Material.Wood, nil, guild)

	end



	-- หลังคาจั่วไม้ทรงสูง (Guildhall Timber Gabled Roof)

	cframePart("GuildRoofL", Vector3.new(28.5, 1.6, 85), CFrame.new(guildCenter + Vector3.new(-11.5, 30.5, 0)) * CFrame.Angles(0, 0, math.rad(38)), PALETTE.roofBrown, Enum.Material.WoodPlanks, guild, false)

	cframePart("GuildRoofR", Vector3.new(28.5, 1.6, 85), CFrame.new(guildCenter + Vector3.new( 11.5, 30.5, 0)) * CFrame.Angles(0, 0, math.rad(-38)), PALETTE.roofBrown, Enum.Material.WoodPlanks, guild, false)

	part("GuildRoofRidge", Vector3.new(2.4, 2.2, 86), guildCenter + Vector3.new(0, 38.6, 0), PALETTE.timberDark, Enum.Material.Wood, nil, guild, false)



	-- ปิดหน้าจั่วหน้าและหลัง

	for _, gz in ipairs({-40.2, 40.2}) do

		part("GuildGableLower", Vector3.new(34, 5.5, 1.6), guildCenter + Vector3.new(0, 27.5, gz), PALETTE.plasterWarm, Enum.Material.Sandstone, nil, guild, false)

		part("GuildGableMid",   Vector3.new(22, 5.0, 1.6), guildCenter + Vector3.new(0, 32.5, gz), PALETTE.plasterWarm, Enum.Material.Sandstone, nil, guild, false)

		part("GuildGableTop",   Vector3.new(10, 4.5, 1.6), guildCenter + Vector3.new(0, 36.8, gz), PALETTE.plasterWarm, Enum.Material.Sandstone, nil, guild, false)

	end



	-- ป้ายชื่อกิลด์นักผจญภัยขนาดใหญ่หน้าทางเข้า

	local guildSign = part("GuildSignboard", Vector3.new(19, 3.8, 0.6), guildCenter + Vector3.new(0, 17.5, 44.8), PALETTE.timberDark, Enum.Material.WoodPlanks, nil, guild, false)

	local gsgui = Instance.new("SurfaceGui")

	gsgui.Face = Enum.NormalId.Back

	gsgui.CanvasSize = Vector2.new(640, 140)

	gsgui.Parent = guildSign

	local gslbl = Instance.new("TextLabel")

	gslbl.Size = UDim2.fromScale(1, 1)

	gslbl.BackgroundTransparency = 1

	gslbl.Text = "🛡️ กิลด์นักผจญภัย (ADVENTURER'S GUILD)\n⚔️ รับภารกิจ & เปลี่ยนอาชีพ (Job Change) ⚔️"

	gslbl.TextColor3 = Color3.fromRGB(255, 235, 160)

	gslbl.TextScaled = true

	gslbl.Font = Enum.Font.GothamBold

	gslbl.Parent = gsgui



	-- เตาผิงหินขนาดใหญ่ (Guild Great Fireplace)

	local fpPos = guildCenter + Vector3.new(-21, 0, 0)

	part("GuildFireplaceBase", Vector3.new(4, 12, 16), fpPos + Vector3.new(0, 6, 0), PALETTE.stoneDark, Enum.Material.Cobblestone, nil, guild)

	part("GuildChimney", Vector3.new(3.8, 32, 5.0), fpPos + Vector3.new(0, 20, 0), PALETTE.stoneDark, Enum.Material.Cobblestone, nil, guild, false)

	local fpFire = part("GuildFireplaceFlame", Vector3.new(2.2, 2.2, 4.5), fpPos + Vector3.new(1.2, 2.5, 0), Color3.fromRGB(255, 130, 40), Enum.Material.Neon, nil, guild, false)

	local fpLight = Instance.new("PointLight")

	fpLight.Color = Color3.fromRGB(255, 160, 60)

	fpLight.Brightness = 1.4

	fpLight.Range = 28

	fpLight.Parent = fpFire



	-- เคาน์เตอร์รับเควสและเปลี่ยนอาชีพ (Guild Reception & Class Change Counter)

	part("GuildCounterDesk", Vector3.new(22, 3.8, 3.2), guildCenter + Vector3.new(0, 2.8, -26), PALETTE.timberDark, Enum.Material.Wood, nil, guild)

	part("GuildCounterTop",  Vector3.new(23, 0.4, 3.6), guildCenter + Vector3.new(0, 4.8, -26), PALETTE.goldTrim, Enum.Material.SmoothPlastic, nil, guild, false)



	-- ธงตราสัญลักษณ์ 6 อาชีพหลัก (Class Guild Banners)

	local classBanners = {

		{ name = "Knight", col = Color3.fromRGB(195, 40, 40), icon = "⚔️ KNIGHT", x = -14, z = -39 },

		{ name = "Mage", col = Color3.fromRGB(130, 60, 210), icon = "🔮 MAGE", x = -6, z = -39 },

		{ name = "Archer", col = Color3.fromRGB(45, 150, 65), icon = "🏹 ARCHER", x = 2, z = -39 },

		{ name = "Acolyte", col = Color3.fromRGB(230, 200, 70), icon = "🙏 ACOLYTE", x = 10, z = -39 },

		{ name = "Thief", col = Color3.fromRGB(60, 65, 75), icon = "🗡️ THIEF", x = 18, z = -39 },

		{ name = "Merchant", col = Color3.fromRGB(220, 150, 40), icon = "💰 MERCHANT", x = 20, z = -20 },

	}

	for _, cb in ipairs(classBanners) do

		local bPart = part("Banner_" .. cb.name, Vector3.new(3.8, 8.5, 0.2), guildCenter + Vector3.new(cb.x, 15, cb.z), cb.col, Enum.Material.Fabric, nil, guild, false)

		local bsg = Instance.new("SurfaceGui")

		bsg.Face = Enum.NormalId.Back

		bsg.CanvasSize = Vector2.new(160, 360)

		bsg.Parent = bPart

		local blbl = Instance.new("TextLabel")

		blbl.Size = UDim2.fromScale(1, 1)

		blbl.BackgroundTransparency = 1

		blbl.Text = cb.icon

		blbl.TextColor3 = Color3.fromRGB(255, 255, 255)

		blbl.TextScaled = true

		blbl.Font = Enum.Font.GothamBold

		blbl.Parent = bsg

	end



	-- โต๊ะประชุมและม้านั่งนักผจญภัย

	for _, tz in ipairs({-8, 12}) do

		for _, tx in ipairs({-10, 10}) do

			part("GuildTable", Vector3.new(8, 2.6, 4.0), guildCenter + Vector3.new(tx, 2.4, tz), PALETTE.timberMed, Enum.Material.WoodPlanks, nil, guild)

			part("GuildBenchL", Vector3.new(8, 1.4, 1.4), guildCenter + Vector3.new(tx, 1.8, tz - 3.2), PALETTE.timberDark, Enum.Material.Wood, nil, guild)

			part("GuildBenchR", Vector3.new(8, 1.4, 1.4), guildCenter + Vector3.new(tx, 1.8, tz + 3.2), PALETTE.timberDark, Enum.Material.Wood, nil, guild)

		end

	end



	-- โคมไฟระย้าไม้คานเพดาน

	for _, cz in ipairs({-22, 0, 22}) do

		part("GuildCeilingBeam", Vector3.new(44, 1.2, 1.4), guildCenter + Vector3.new(0, 24.0, cz), PALETTE.timberDark, Enum.Material.Wood, nil, guild, false)

		local gChand = part("GuildChandelier", Vector3.new(3.2, 1.8, 3.2), guildCenter + Vector3.new(0, 19.5, cz), PALETTE.windowGlow, Enum.Material.Neon, Enum.PartType.Ball, guild, false)

		local cl = Instance.new("PointLight")

		cl.Color = PALETTE.windowGlow

		cl.Brightness = 1.2

		cl.Range = 26

		cl.Parent = gChand

	end



	-- NPC ประจำกิลด์นักผจญภัย (Guild Master Siegfried & Class Trainer)

	buildInteriorNpc(guild, CFrame.new(guildCenter) * CFrame.Angles(0, math.pi, 0), {

		modelName = "GuildMaster",

		displayName = "กิลด์มาสเตอร์ ซิกฟรีด (Guild Master Siegfried)",

		actionText = "เปลี่ยนอาชีพ / แนะนำภารกิจ",

		remoteName = "OpenClassChange",

		greeting = "ยินดีต้อนรับสู่กิลด์นักผจญภัย! เจ้าพร้อมที่จะก้าวสู่เส้นทางอาชีพใหม่หรือยัง?",

		localCF = CFrame.new(0, 0, 24),

	})

end



-- (B) 4 ร้านค้าหลักล้อมรอบสระน้ำพุกลางเมือง ณ (0, 0, 0) อย่างสมมาตร 4 มุม (เดินเข้าประตูไปใช้บริการ NPC จริงข้างในได้เลย)

-- 1. มุมตะวันตกเฉียงเหนือ (X=-32, Z=-32 หันหน้าลงทิศใต้เข้าหาสระน้ำพุ): โรงตีเหล็ก (มี NPC Blacksmith อยู่ข้างในแล้ว)

buildMedievalBuilding("BlacksmithForgeHall", Vector3.new(-32, 0, -32), math.pi, "Shop", PALETTE.plasterTan, PALETTE.roofSlate, "โรงตีเหล็ก\nBLACKSMITH", nil)



-- 2. มุมตะวันออกเฉียงเหนือ (X=32, Z=-32 หันหน้าลงทิศใต้เข้าหาสระน้ำพุ): โรงคราฟต์อุปกรณ์ (มี NPC Craftsman อยู่ข้างใน)

buildMedievalBuilding("CraftingWorkshop", Vector3.new(32, 0, -32), math.pi, "Shop", PALETTE.plasterWarm, PALETTE.roofTerra, "โรงคราฟต์อุปกรณ์\nCRAFTING", nil)



-- 3. มุมตะวันออกเฉียงใต้ (X=32, Z=32 หันหน้าขึ้นทิศเหนือเข้าหาสระน้ำพุ): ร้านขายยาและของใช้ (มี NPC SupplyVendor อยู่ข้างใน)

buildMedievalBuilding("PotionSupplyShop", Vector3.new(32, 0, 32), 0, "Shop", PALETTE.plasterCream, PALETTE.roofRed, "ร้านขายยาและของใช้\nSUPPLIES", nil)



-- 4. มุมตะวันตกเฉียงใต้ (X=-32, Z=32 หันหน้าขึ้นทิศเหนือเข้าหาสระน้ำพุ): ตลาดกลางแลกเปลี่ยน (มี NPC MarketBroker อยู่ข้างใน)

buildMedievalBuilding("CentralMarketHall", Vector3.new(-32, 0, 32), 0, "Shop", PALETTE.plasterWarm, PALETTE.roofBrown, "ตลาดกลางแลกเปลี่ยน\nMARKET", nil)



-- ============================================================

-- ตกแต่งพิเศษ: โรงตีเหล็ก Blacksmith Forge Hall (เตาหลอมไฟลุกโชน, ควันปล่องไฟ, อ่างชุบโลหะ, ชั้นวางอาวุธ)

-- ============================================================

do

	local forgePos = Vector3.new(-32, 0, -32)

	local forgeFolder = Instance.new("Folder")

	forgeFolder.Name = "BlacksmithDecor"

	forgeFolder.Parent = buildingsFolder:FindFirstChild("BlacksmithForgeHall") or root



	-- เตาหลอมหินโบราณ (Stone Forge Hearth)

	part("ForgeBase", Vector3.new(4.8, 3.2, 3.8), forgePos + Vector3.new(-5.5, 1.6, -2.5), PALETTE.stoneDark, Enum.Material.Cobblestone, nil, forgeFolder)

	part("ForgeHood", Vector3.new(4.2, 2.4, 3.2), forgePos + Vector3.new(-5.5, 4.4, -2.5), PALETTE.stoneWall, Enum.Material.Slate, nil, forgeFolder)

	local coals = part("ForgeHotCoals", Vector3.new(3.6, 0.5, 2.6), forgePos + Vector3.new(-5.5, 2.6, -2.5), Color3.fromRGB(255, 95, 20), Enum.Material.Neon, nil, forgeFolder, false)



	-- เอฟเฟกต์ไฟลุกโชนในเตาหลอม

	local forgeFire = Instance.new("ParticleEmitter")

	forgeFire.Name = "ForgeFlames"

	forgeFire.Color = ColorSequence.new({

		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 50)),

		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 110, 20)),

		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 40, 10)),

	})

	forgeFire.Size = NumberSequence.new({

		NumberSequenceKeypoint.new(0, 0.6),

		NumberSequenceKeypoint.new(0.6, 1.4),

		NumberSequenceKeypoint.new(1, 0.2),

	})

	forgeFire.Transparency = NumberSequence.new({

		NumberSequenceKeypoint.new(0, 0.1),

		NumberSequenceKeypoint.new(0.8, 0.3),

		NumberSequenceKeypoint.new(1, 1),

	})

	forgeFire.LightEmission = 0.95

	forgeFire.Speed = NumberRange.new(3, 5.5)

	forgeFire.SpreadAngle = Vector2.new(15, 15)

	forgeFire.EmissionDirection = Enum.NormalId.Top

	forgeFire.Lifetime = NumberRange.new(0.6, 1.0)

	forgeFire.Rate = 26

	forgeFire.Parent = coals



	local forgeLight = Instance.new("PointLight")

	forgeLight.Color = Color3.fromRGB(255, 130, 40)

	forgeLight.Brightness = 2.4

	forgeLight.Range = 22

	forgeLight.Parent = coals



	-- ควันพวยพุ่งจากปล่องไฟบนหลังคาโรงตีเหล็ก

	local chimneyTop = part("ChimneySmokeSource", Vector3.new(1, 1, 1), forgePos + Vector3.new(5.5, 26, 4.5), Color3.fromRGB(80, 80, 80), Enum.Material.Slate, nil, forgeFolder, false)

	chimneyTop.Transparency = 1

	local smoke = Instance.new("ParticleEmitter")

	smoke.Name = "ChimneySmoke"

	smoke.Color = ColorSequence.new(Color3.fromRGB(200, 200, 205), Color3.fromRGB(150, 150, 155))

	smoke.Size = NumberSequence.new({

		NumberSequenceKeypoint.new(0, 0.8),

		NumberSequenceKeypoint.new(0.5, 2.2),

		NumberSequenceKeypoint.new(1, 4.0),

	})

	smoke.Transparency = NumberSequence.new({

		NumberSequenceKeypoint.new(0, 0.35),

		NumberSequenceKeypoint.new(0.7, 0.6),

		NumberSequenceKeypoint.new(1, 1),

	})

	smoke.Speed = NumberRange.new(2.5, 4.5)

	smoke.SpreadAngle = Vector2.new(18, 18)

	smoke.EmissionDirection = Enum.NormalId.Top

	smoke.Lifetime = NumberRange.new(3.0, 5.0)

	smoke.Rate = 12

	smoke.Acceleration = Vector3.new(1.5, 0.5, 0)

	smoke.Parent = chimneyTop



	-- ถังน้ำชุบโลหะ (Quench Barrel) พร้อมไอน้ำ

	part("QuenchBarrel", Vector3.new(2.4, 2.6, 2.4), forgePos + Vector3.new(-5.5, 1.3, 2.2), PALETTE.timberDark, Enum.Material.Wood, Enum.PartType.Cylinder, forgeFolder, true)

	local qWater = part("QuenchWater", Vector3.new(2.1, 0.3, 2.1), forgePos + Vector3.new(-5.5, 2.4, 2.2), Color3.fromRGB(70, 140, 190), Enum.Material.Glass, Enum.PartType.Cylinder, forgeFolder, false)

	local steam = Instance.new("ParticleEmitter")

	steam.Name = "QuenchSteam"

	steam.Color = ColorSequence.new(Color3.fromRGB(240, 245, 250))

	steam.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1.6)})

	steam.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1)})

	steam.Speed = NumberRange.new(1.2, 2.5)

	steam.SpreadAngle = Vector2.new(12, 12)

	steam.Lifetime = NumberRange.new(1.2, 2.0)

	steam.Rate = 8

	steam.Parent = qWater



	-- ชั้นวางอาวุธ (Weapon Display Rack) ด้านข้าง

	part("WeaponRackFrameL", Vector3.new(0.4, 4.8, 0.4), forgePos + Vector3.new(5.2, 2.4, -2.8), PALETTE.timberDark, Enum.Material.Wood, nil, forgeFolder)

	part("WeaponRackFrameR", Vector3.new(0.4, 4.8, 0.4), forgePos + Vector3.new(5.2, 2.4, 0.8), PALETTE.timberDark, Enum.Material.Wood, nil, forgeFolder)

	part("WeaponRackBar", Vector3.new(0.3, 0.3, 4.0), forgePos + Vector3.new(5.2, 3.8, -1.0), PALETTE.timberDark, Enum.Material.Wood, nil, forgeFolder)

	part("DisplayBroadsword", Vector3.new(0.2, 3.8, 0.6), forgePos + Vector3.new(5.0, 2.6, -1.8), Color3.fromRGB(210, 215, 225), Enum.Material.Metal, nil, forgeFolder, false)

	part("DisplayBattleaxe", Vector3.new(0.3, 3.6, 1.2), forgePos + Vector3.new(5.0, 2.5, -0.6), Color3.fromRGB(150, 155, 165), Enum.Material.Metal, nil, forgeFolder, false)

	part("DisplayShield", Vector3.new(0.4, 2.4, 2.4), forgePos + Vector3.new(5.0, 2.0, 0.6), Color3.fromRGB(135, 45, 38), Enum.Material.WoodPlanks, Enum.PartType.Cylinder, forgeFolder, false)



	-- กองแท่งเหล็ก (Iron Ingots) บนโต๊ะงาน

	for iy = 0, 1 do

		for ix = -1, 1 do

			part("IronIngot_" .. iy .. "_" .. ix, Vector3.new(1.4, 0.3, 0.7), forgePos + Vector3.new(-2.2 + ix * 0.9, 2.6 + iy * 0.32, -3.2), Color3.fromRGB(175, 185, 195), Enum.Material.Metal, nil, forgeFolder, false)

		end

	end

end



-- ============================================================

-- ตกแต่งพิเศษ: ร้านขายยาและของใช้ Potion Supply Shop (กระถางดอกไม้หน้าร้าน, ตู้ยาขวดแก้วเปล่งแสง, สมุนไพร)

-- ============================================================

do

	local potPos = Vector3.new(32, 0, 32)

	local potFolder = Instance.new("Folder")

	potFolder.Name = "ApothecaryDecor"

	potFolder.Parent = buildingsFolder:FindFirstChild("PotionSupplyShop") or root



	-- กระถางดอกไม้ประดับใต้หน้าต่างหน้าร้าน 2 ข้าง

	for _, wx in ipairs({-6.2, 6.2}) do

		part("PlanterBox", Vector3.new(3.8, 1.0, 1.4), potPos + Vector3.new(wx, 1.2, -13.2), PALETTE.timberDark, Enum.Material.WoodPlanks, nil, potFolder)

		part("PlanterSoil", Vector3.new(3.5, 0.3, 1.1), potPos + Vector3.new(wx, 1.7, -13.2), Color3.fromRGB(92, 64, 44), Enum.Material.Ground, nil, potFolder)

		local fColors = {

			Color3.fromRGB(245, 60, 80),

			Color3.fromRGB(255, 215, 50),

			Color3.fromRGB(60, 175, 245),

			Color3.fromRGB(215, 80, 235),

		}

		for fi = 1, 4 do

			local fx = (fi - 2.5) * 0.8

			part("FlowerBush", Vector3.new(0.65, 0.65, 0.65), potPos + Vector3.new(wx + fx, 2.1, -13.2), Color3.fromRGB(85, 165, 65), Enum.Material.Grass, Enum.PartType.Ball, potFolder, false)

			part("FlowerBlossom", Vector3.new(0.45, 0.45, 0.45), potPos + Vector3.new(wx + fx, 2.45, -13.2), fColors[fi], Enum.Material.SmoothPlastic, Enum.PartType.Ball, potFolder, false)

		end

	end



	-- ตู้ยาและชั้นวางขวดโพชั่นเปล่งแสงภายในร้าน

	local potionTypes = {

		{ name = "RedPotion",   col = Color3.fromRGB(255, 45, 45),   y = 3.6, x = -3.5 },

		{ name = "RedPotion",   col = Color3.fromRGB(255, 45, 45),   y = 3.6, x = -2.2 },

		{ name = "BluePotion",  col = Color3.fromRGB(45, 135, 255),  y = 3.6, x =  2.2 },

		{ name = "BluePotion",  col = Color3.fromRGB(45, 135, 255),  y = 3.6, x =  3.5 },

		{ name = "GreenHerb",   col = Color3.fromRGB(45, 225, 105),  y = 5.2, x = -3.0 },

		{ name = "YellowHerb",  col = Color3.fromRGB(255, 220, 45),  y = 5.2, x = -1.5 },

		{ name = "VioletElix",  col = Color3.fromRGB(195, 65, 245),  y = 5.2, x =  1.5 },

		{ name = "OrangeBuff",  col = Color3.fromRGB(255, 135, 35),  y = 5.2, x =  3.0 },

	}



	for pi, pt in ipairs(potionTypes) do

		local pBottle = part(pt.name .. "_" .. pi, Vector3.new(0.6, 0.95, 0.6), potPos + Vector3.new(pt.x, pt.y, 10.8), pt.col, Enum.Material.Neon, Enum.PartType.Ball, potFolder, false)

		local bLight = Instance.new("PointLight")

		bLight.Color = pt.col

		bLight.Brightness = 0.85

		bLight.Range = 5

		bLight.Parent = pBottle

	end



	-- โกร่งบดยาสมุนไพร (Mortar & Pestle) บนเคาน์เตอร์

	part("MortarBowl", Vector3.new(1.0, 0.7, 1.0), potPos + Vector3.new(-2.2, 3.1, 4.5), PALETTE.stoneLight, Enum.Material.Cobblestone, Enum.PartType.Cylinder, potFolder, false)

	part("PestleStick", Vector3.new(0.25, 1.2, 0.25), potPos + Vector3.new(-2.2, 3.6, 4.5), PALETTE.timberDark, Enum.Material.Wood, nil, potFolder, false)

end



-- (C) โรงเตี๊ยม (PronteraInn @ X=32, Z=82 หันหน้าเข้าหาถนนสายใต้ SouthMainAvenue)

buildMedievalBuilding("PronteraInn", Vector3.new(32, 0, 82), math.rad(90), "Inn", PALETTE.plasterWarm, PALETTE.roofRed, "โรงเตี๊ยม\nTAVERN & INN", {

	modelName = "InnkeeperNPC",

	displayName = "เจ้าของโรงเตี๊ยม Belladonna",

	actionText = "พูดคุย / ดูภารกิจ",

	remoteName = "OpenDailyQuests",

	greeting = "ยินดีต้อนรับนักเดินทาง! มองหาภารกิจประจำวันอยู่หรือเปล่า?",

})



-- (D) กิลด์อัศวิน (PronteraKnightGuild @ X=-32, Z=82 หันหน้าเข้าหาถนนสายใต้ SouthMainAvenue)

buildMedievalBuilding("PronteraKnightGuild", Vector3.new(-32, 0, 82), math.rad(-90), "Large", PALETTE.plasterCream, PALETTE.roofBrown, "กิลด์อัศวิน\nKNIGHT GUILD", {

	modelName = "KnightMasterNPC",

	displayName = "หัวหน้าอัศวิน Herman",

	actionText = "รายงานภารกิจกิลด์",

	remoteName = "OpenDailyQuests",

	greeting = "นักรบผู้กล้า! ออกไปปราบฝูงมอนสเตอร์นอกประตูตะวันออกกันเถอะ!",

	coatColor = Color3.fromRGB(148, 52, 48),

})



-- ============================================================

-- 8. เขตที่อยู่อาศัย (Residential Quarter — จัดผังบล็อกใหม่ทั้งหมด ไม่ทับถนน ไม่เหลื่อมกัน และมีทางเดินหน้าบ้านทุกหลัง)

-- ============================================================

local residentialFolder = Instance.new("Folder")

residentialFolder.Name = "ResidentialDistrict"

residentialFolder.Parent = root



local houseBlocks = {

	-- แถวที่ 1 (Z = -28, หันหน้าลงทิศใต้เข้าหาถนนใหญ่ WestMainAvenue Z = 0)

	{ x = -114, z = -28, yaw = math.pi, t = "Standard", w = PALETTE.plasterWarm,  r = PALETTE.roofRed,    sign = "สำนักเครื่องราง",

	  npc = { modelName = "TalismanSeerNPC", displayName = "หมอดูเครื่องราง Aria", actionText = "รับภารกิจเครื่องราง", remoteName = "OpenDailyQuests", greeting = "ดวงชะตาของเจ้ากำลังรุ่งโรจน์ ลองรับภารกิจวันนี้ดูสิ!" } },

	{ x = -146, z = -28, yaw = math.pi, t = "Small",    w = PALETTE.plasterSage,  r = PALETTE.roofThatch },

	{ x = -204, z = -28, yaw = math.pi, t = "Shop",     w = PALETTE.plasterWarm,  r = PALETTE.roofRed,    sign = "สมาคมช่างทอผ้า",

	  npc = { modelName = "TailorQuestNPC", displayName = "หัวหน้าช่างทอผ้า Clara", actionText = "รับภารกิจรวบรวมขนปุย", remoteName = "OpenDailyQuests", greeting = "ช่วงนี้สมาคมต้องการ Jellopy กับขนปุยจำนวนมาก ช่วยไปหามาให้ทีนะ!" } },

	{ x = -236, z = -28, yaw = math.pi, t = "Standard", w = PALETTE.plasterCream, r = PALETTE.roofBrown },



	-- แถวที่ 2 (Z = -94, หันหน้าลงทิศใต้เข้าหาถนนรอง SecondaryRoad_EW_-70)

	{ x = -114, z = -94, yaw = math.pi, t = "Standard", w = PALETTE.plasterCream, r = PALETTE.roofTerra,  sign = "หอเวทมนตร์",

	  npc = { modelName = "ArchmageNPC", displayName = "จอมเวทฝึกสอน Zephyr", actionText = "รับภารกิจเวทมนตร์", remoteName = "OpenDailyQuests", greeting = "พลังเวทมนตร์เริ่มต้นจากการฝึกฝนทำภารกิจทุกวัน!" } },

	{ x = -146, z = -94, yaw = math.pi, t = "Large",    w = PALETTE.plasterTan,   r = PALETTE.roofSlate },

	{ x = -204, z = -94, yaw = math.pi, t = "Small",    w = PALETTE.plasterSage,  r = PALETTE.roofThatch },

	{ x = -236, z = -94, yaw = math.pi, t = "Standard", w = PALETTE.plasterWarm,  r = PALETTE.roofTerra },



	-- แถวที่ 3 (Z = 28, หันหน้าขึ้นทิศเหนือเข้าหาถนนใหญ่ WestMainAvenue Z = 0)

	{ x = -114, z =  28, yaw = 0,       t = "Standard", w = PALETTE.plasterCream, r = PALETTE.roofRed,    sign = "บ้านพักนักเดินทาง",

	  npc = { modelName = "TravelerGuideNPC", displayName = "นักสำรวจรุ่นพี่ Leon", actionText = "คู่มือนักผจญภัย", remoteName = "OpenTutorial", greeting = "อยากทบทวนพื้นฐานการอัป Status และการต่อสู้ไหม?" } },

	{ x = -146, z =  28, yaw = 0,       t = "Small",    w = PALETTE.plasterTan,   r = PALETTE.roofThatch },

	{ x = -204, z =  28, yaw = 0,       t = "Large",    w = PALETTE.plasterWarm,  r = PALETTE.roofSlate },

	{ x = -236, z =  28, yaw = 0,       t = "Standard", w = PALETTE.plasterSage,  r = PALETTE.roofTerra },



	-- แถวที่ 4 (Z = 94, หันหน้าขึ้นทิศเหนือเข้าหาถนนรอง SecondaryRoad_EW_70)

	{ x = -114, z =  94, yaw = 0,       t = "Small",    w = PALETTE.plasterWarm,  r = PALETTE.roofThatch, sign = "บ้านคนส่งสาร",

	  npc = { modelName = "CourierNPC", displayName = "คนส่งสารแห่งเมือง Milo", actionText = "รับภารกิจด่วน", remoteName = "OpenDailyQuests", greeting = "มีใบประกาศจับมอนสเตอร์ส่งตรงมาจากปราสาท!" } },

	{ x = -146, z =  94, yaw = 0,       t = "Standard", w = PALETTE.plasterCream, r = PALETTE.roofRed },

	{ x = -204, z =  94, yaw = 0,       t = "Standard", w = PALETTE.plasterTan,   r = PALETTE.roofBrown },

	{ x = -236, z =  94, yaw = 0,       t = "Small",    w = PALETTE.plasterSage,  r = PALETTE.roofThatch },



	-- แถวที่ 5 (Z = 164, หันหน้าขึ้นทิศเหนือเข้าหาถนนรอง SecondaryRoad_EW_140)

	{ x = -114, z = 164, yaw = 0,       t = "Standard", w = PALETTE.plasterWarm,  r = PALETTE.roofTerra },

	{ x = -146, z = 164, yaw = 0,       t = "Large",    w = PALETTE.plasterCream, r = PALETTE.roofSlate },

	{ x = -204, z = 164, yaw = 0,       t = "Small",    w = PALETTE.plasterTan,   r = PALETTE.roofThatch },

	{ x = -236, z = 164, yaw = 0,       t = "Standard", w = PALETTE.plasterWarm,  r = PALETTE.roofRed },

}



for idx, h in ipairs(houseBlocks) do

	buildMedievalBuilding("VillageHouse_" .. idx, Vector3.new(h.x, 0, h.z), h.yaw, h.t, h.w, h.r, h.sign, h.npc)

end



-- ============================================================

-- ============================================================

-- 9. มหาวิหารใหญ่โพรนเทอรา (Grand Prontera Cathedral @ North Z = -180..-280)

-- แทนที่เขตปราสาทเดิมด้วยสถาปัตยกรรมมหาวิหารทรงโรมาเนสก์-กอทิกขนาดอลังการ

-- ขยายสเกล 1.5x (กว้าง 64 studs, ยาว 96 studs, หอระฆังคู่สูง 68 studs, กางเขนทองสูง 88 studs)

-- ============================================================

local grandCathedralFolder = Instance.new("Folder")

grandCathedralFolder.Name = "GrandCathedralDistrict"

grandCathedralFolder.Parent = root



do

	local catCenter = Vector3.new(0, 14, -245)



	-- ทางขึ้นเขาและซุ้มประตูหินมหาวิหาร (Grand Cathedral Processional Gate)

	for _, x in ipairs({-18, 18}) do

		part("CathedralGateTower", Vector3.new(10, 26, 10), Vector3.new(x, 13, -165), PALETTE.stoneLight, Enum.Material.Sandstone, nil, grandCathedralFolder)

		part("CathedralGateTowerCap", Vector3.new(12, 8, 12), Vector3.new(x, 29, -165), PALETTE.roofSlate, Enum.Material.Slate, nil, grandCathedralFolder, false)

	end

	part("CathedralGateArch", Vector3.new(28, 6, 6), Vector3.new(0, 22, -165), PALETTE.stoneLight, Enum.Material.Marble, nil, grandCathedralFolder, false)

	part("CathedralGateCross", Vector3.new(1.6, 6.0, 1.4), Vector3.new(0, 27.5, -165), PALETTE.goldTrim, Enum.Material.Neon, nil, grandCathedralFolder, false)



	-- ภูเขาหินและบันไดทางเดินขบวนพิธีขึ้นสู่อาสนวิหาร

	part("CathedralHillLower", Vector3.new(240, 14, 150), Vector3.new(0, 7, -250), PALETTE.grassDark, Enum.Material.Grass, nil, grandCathedralFolder)

	part("CathedralHillUpper", Vector3.new(190, 20, 120), Vector3.new(0, 11, -255), PALETTE.stoneDark, Enum.Material.Rock, nil, grandCathedralFolder)

	cframePart("CathedralGrandRamp", Vector3.new(22, 2.4, 68), CFrame.new(0, 9.5, -198) * CFrame.Angles(math.rad(18), 0, 0), PALETTE.cobbleLight, Enum.Material.Cobblestone, grandCathedralFolder, true)

	cframePart("CathedralRampCarpet", Vector3.new(8.0, 2.6, 66), CFrame.new(0, 9.7, -198) * CFrame.Angles(math.rad(18), 0, 0), PALETTE.roofRed, Enum.Material.Fabric, grandCathedralFolder, false)



	-- ลานหินอ่อนและฐานวิหาร

	part("GrandCathedralCourtyard", Vector3.new(150, 1.4, 130), catCenter + Vector3.new(0, 0.7, 0), PALETTE.cobbleLight, Enum.Material.Cobblestone, nil, grandCathedralFolder)

	part("GrandCathedralFloor",     Vector3.new(64, 1.2, 92),  catCenter + Vector3.new(0, 1.2, 0), PALETTE.stoneLight, Enum.Material.Marble, nil, grandCathedralFolder)



	-- บันไดหินอ่อนทางเข้าด้านหน้า

	part("GrandEntranceSteps", Vector3.new(26, 1.2, 8.0), catCenter + Vector3.new(0, 0.6, 48), PALETTE.stoneLight, Enum.Material.Marble, nil, grandCathedralFolder)



	-- ผนังอาคารหลักมหาวิหาร (Vaulted Grand Nave)

	part("GrandCathedralBackWall", Vector3.new(64, 38, 2.2), catCenter + Vector3.new(0, 20.2, -45.5), PALETTE.stoneLight, Enum.Material.Sandstone, nil, grandCathedralFolder)

	for _, sx in ipairs({-1, 1}) do

		-- ผนังด้านข้างยาว 92 studs

		part("GrandCathedralSideWall", Vector3.new(2.2, 38, 92), catCenter + Vector3.new(sx * 31.5, 20.2, 0), PALETTE.stoneLight, Enum.Material.Sandstone, nil, grandCathedralFolder)

		part("GrandCathedralFrontWing", Vector3.new(22, 38, 2.2), catCenter + Vector3.new(sx * 20.5, 20.2, 45.5), PALETTE.stoneLight, Enum.Material.Sandstone, nil, grandCathedralFolder)



		-- หอระฆังคู่ด้านหน้า (Twin Grand Bell Towers) สูง 68 studs

		part("GrandBellTower", Vector3.new(16, 68, 16), catCenter + Vector3.new(sx * 24, 34, 43), PALETTE.stoneLight, Enum.Material.Sandstone, nil, grandCathedralFolder)

		part("GrandBellTowerSpire", Vector3.new(18, 22, 18), catCenter + Vector3.new(sx * 24, 78, 43), PALETTE.roofSlate, Enum.Material.Slate, nil, grandCathedralFolder, false)

		part("GrandBellTowerCross", Vector3.new(1.4, 7.5, 1.4), catCenter + Vector3.new(sx * 24, 91.5, 43), PALETTE.goldTrim, Enum.Material.Neon, nil, grandCathedralFolder, false)

		part("GrandBellTowerCrossBar", Vector3.new(4.8, 1.4, 1.4), catCenter + Vector3.new(sx * 24, 92.5, 43), PALETTE.goldTrim, Enum.Material.Neon, nil, grandCathedralFolder, false)



		-- ครีบยันรับน้ำหนัก (Flying Buttresses) ตามผนังข้าง

		for _, bz in ipairs({-30, -10, 10, 30}) do

			part("FlyingButtressPillar", Vector3.new(3.2, 28, 3.2), catCenter + Vector3.new(sx * 34.5, 14, bz), PALETTE.stoneLight, Enum.Material.Marble, nil, grandCathedralFolder)

			part("FlyingButtressCap",    Vector3.new(3.8, 6.0, 3.8), catCenter + Vector3.new(sx * 34.5, 30, bz), PALETTE.roofSlate, Enum.Material.Slate, nil, grandCathedralFolder, false)

		end

	end



	-- ซุ้มประตูโค้งทางเข้าใหญ่

	part("GrandEntranceArch", Vector3.new(18, 18, 2.2), catCenter + Vector3.new(0, 29.5, 45.5), PALETTE.stoneLight, Enum.Material.Marble, nil, grandCathedralFolder)



	-- หน้าต่างกุหลาบเรืองแสงขนาดใหญ่ยักษ์ (Gigantic Stained Glass Rose Window) เส้นผ่านศูนย์กลาง 14 studs

	local roseWin = part("GrandRoseWindow", Vector3.new(1.6, 14, 14), catCenter + Vector3.new(0, 38.5, 46.2), PALETTE.windowGlow, Enum.Material.Neon, Enum.PartType.Cylinder, grandCathedralFolder, false)

	roseWin.CFrame = CFrame.new(catCenter + Vector3.new(0, 38.5, 46.2)) * CFrame.Angles(0, math.rad(90), 0)



	-- หลังคาจั่วหินชนวนขนาดใหญ่

	cframePart("GrandCathedralRoofL", Vector3.new(41, 2.2, 96), CFrame.new(catCenter + Vector3.new(-16.2, 49.5, 0)) * CFrame.Angles(0, 0, math.rad(36)), PALETTE.roofSlate, Enum.Material.Slate, grandCathedralFolder, false)

	cframePart("GrandCathedralRoofR", Vector3.new(41, 2.2, 96), CFrame.new(catCenter + Vector3.new( 16.2, 49.5, 0)) * CFrame.Angles(0, 0, math.rad(-36)), PALETTE.roofSlate, Enum.Material.Slate, grandCathedralFolder, false)

	part("GrandCathedralRoofRidge", Vector3.new(3.2, 2.8, 97), catCenter + Vector3.new(0, 61.2, 0), PALETTE.goldTrim, Enum.Material.SmoothPlastic, nil, grandCathedralFolder, false)



	-- เพดานโค้งและหน้าจั่ว

	part("GrandCathedralVaultCeiling", Vector3.new(63, 1.8, 91), catCenter + Vector3.new(0, 38.2, 0), PALETTE.plasterCream, Enum.Material.Marble, nil, grandCathedralFolder, true)

	for _, gz in ipairs({-45.5, 45.5}) do

		part("GrandGableLower", Vector3.new(48, 8.0, 2.2), catCenter + Vector3.new(0, 42.5, gz), PALETTE.stoneLight, Enum.Material.Sandstone, nil, grandCathedralFolder, false)

		part("GrandGableMid",   Vector3.new(32, 7.5, 2.2), catCenter + Vector3.new(0, 49.5, gz), PALETTE.stoneLight, Enum.Material.Sandstone, nil, grandCathedralFolder, false)

		part("GrandGableTop",   Vector3.new(16, 6.0, 2.2), catCenter + Vector3.new(0, 56.0, gz), PALETTE.stoneLight, Enum.Material.Sandstone, nil, grandCathedralFolder, false)

	end



	-- ภายใน: พรมแดงยาว, แท่นบูชาศักดิ์สิทธิ์, โคมระย้า, และม้านั่ง

	part("GrandCathedralCarpet", Vector3.new(10.5, 0.2, 76), catCenter + Vector3.new(0, 1.9, 2), PALETTE.roofRed, Enum.Material.Fabric, nil, grandCathedralFolder, false)

	part("GrandCathedralAltar",  Vector3.new(18, 4.2, 6.5), catCenter + Vector3.new(0, 3.8, -32), PALETTE.stoneLight, Enum.Material.Marble, nil, grandCathedralFolder)

	part("GrandAltarCross",      Vector3.new(1.4, 7.0, 1.2), catCenter + Vector3.new(0, 9.2, -32), PALETTE.goldTrim, Enum.Material.Neon, nil, grandCathedralFolder, false)



	for _, cz in ipairs({-24, -4, 16, 34}) do

		part("GrandCeilingBeam", Vector3.new(61, 1.4, 1.6), catCenter + Vector3.new(0, 37.0, cz), PALETTE.timberDark, Enum.Material.Wood, nil, grandCathedralFolder, false)

		local chand = part("GrandChandelier", Vector3.new(4.5, 2.2, 4.5), catCenter + Vector3.new(0, 31.0, cz), PALETTE.windowGlow, Enum.Material.Neon, Enum.PartType.Ball, grandCathedralFolder, false)

		local cLight = Instance.new("PointLight")

		cLight.Color = PALETTE.windowGlow

		cLight.Brightness = 1.4

		cLight.Range = 36

		cLight.Parent = chand

	end



	for _, pz in ipairs({-18, -8, 2, 12, 22}) do

		for _, px in ipairs({-16, 16}) do

			part("GrandCathedralPew", Vector3.new(12, 2.2, 2.6), catCenter + Vector3.new(px, 2.6, pz), PALETTE.timberMed, Enum.Material.WoodPlanks, nil, grandCathedralFolder)

		end

	end



	-- ป้ายชื่อมหาวิหารใหญ่

	local gcatSign = part("GrandCathedralSign", Vector3.new(24, 3.6, 0.6), catCenter + Vector3.new(0, 20.0, 47.0), PALETTE.timberDark, Enum.Material.WoodPlanks, nil, grandCathedralFolder, false)

	local gsg = Instance.new("SurfaceGui")

	gsg.Face = Enum.NormalId.Back

	gsg.CanvasSize = Vector2.new(640, 120)

	gsg.Parent = gcatSign

	local gsl = Instance.new("TextLabel")

	gsl.Size = UDim2.fromScale(1, 1)

	gsl.BackgroundTransparency = 1

	gsl.Text = "⛪ มหาวิหารใหญ่โพรนเทอรา\nGRAND PRONTERA CATHEDRAL"

	gsl.TextColor3 = Color3.fromRGB(255, 235, 175)

	gsl.TextScaled = true

	gsl.Font = Enum.Font.GothamBold

	gsl.Parent = gsg



	-- บาทหลวงใหญ่ประจำมหาวิหาร

	buildInteriorNpc(grandCathedralFolder, CFrame.new(catCenter + Vector3.new(0, 1.8, -26)) * CFrame.Angles(0, math.pi, 0), {

		modelName = "ArchbishopBamph",

		displayName = "หลวงพ่อ Bamph (สังฆราชแห่งมหาวิหาร)",

		actionText = "รับพรศักดิ์สิทธิ์ / เควสโบสถ์",

		remoteName = "OpenDailyQuests",

		greeting = "ขอแสงศักดิ์สิทธิ์แห่งมหาวิหารสถิตอยู่กับเจ้า เหล่านักรบผู้กล้า!",

		localCF = CFrame.new(0, 0, 12),

	})

end



-- ============================================================

-- 10. พื้นที่เกษตร & โรงสีลม (Farm & Windmill)

-- ============================================================

local farmFolder = Instance.new("Folder")

farmFolder.Name = "FarmAndWindmill"

farmFolder.Parent = root



for f = 0, 3 do

	local fx = -225 - (f % 2) * 58

	local fz = -145 - math.floor(f / 2) * 44

	part("FarmSoil_" .. f, Vector3.new(48, 0.4, 34), Vector3.new(fx, 0.2, fz), Color3.fromRGB(108, 78, 52), Enum.Material.Ground, nil, farmFolder)

	for row = -12, 12, 6 do

		part("WheatRow", Vector3.new(44, 1.8, 2.4), Vector3.new(fx, 1.1, fz + row), Color3.fromRGB(218, 184, 78), Enum.Material.Grass, nil, farmFolder, false)

	end

end



do

	local wmPos = Vector3.new(-275, 0, -165)

	part("WindmillBase", Vector3.new(20, 12, 20), wmPos + Vector3.new(0, 6, 0), PALETTE.stoneWall, Enum.Material.Cobblestone, nil, farmFolder)

	part("WindmillTower", Vector3.new(16, 22, 16), wmPos + Vector3.new(0, 23, 0), PALETTE.plasterWarm, Enum.Material.Sandstone, nil, farmFolder)

	part("WindmillCap", Vector3.new(18, 8, 18), wmPos + Vector3.new(0, 38, 0), PALETTE.roofBrown, Enum.Material.WoodPlanks, nil, farmFolder, false)

	local hub = part("WindmillHub", Vector3.new(2.4, 2.4, 3.0), wmPos + Vector3.new(0, 28, 9.5), PALETTE.timberDark, Enum.Material.Wood, nil, farmFolder, false)

	for angle = 0, 270, 90 do

		local rad = math.rad(angle + 25)

		cframePart("WindmillBlade", Vector3.new(1.2, 26, 0.3), CFrame.new(hub.Position) * CFrame.Angles(0, 0, rad) * CFrame.new(0, 13, 0.8), PALETTE.timberDark, Enum.Material.Wood, farmFolder, false)

		cframePart("WindmillSail", Vector3.new(3.6, 20, 0.15), CFrame.new(hub.Position) * CFrame.Angles(0, 0, rad) * CFrame.new(1.4, 14, 0.95), PALETTE.plasterCream, Enum.Material.Fabric, farmFolder, false)

	end

end



-- ============================================================

-- 11. ท่าเรือ สะพานหิน และเรือใบ (Harbor & Wharf — เปิดทางเดินโล่ง ไม่โดนกำแพงเมืองหรือราวสะพานบัง)

-- ============================================================

local harborFolder = Instance.new("Folder")

harborFolder.Name = "HarborAndWharf"

harborFolder.Parent = root



-- ถนนเลียบท่าเรือ (HarborPromenadeRoad) เชื่อมจาก SouthMainAvenue (X=0) ไปยังบ้านคนเรือและสะพานท่าเรือโดยตรง

part("HarborPromenadeRoad", Vector3.new(136, 0.46, 20), Vector3.new(-58, 0.02, 232), PALETTE.cobbleMain, Enum.Material.Cobblestone, nil, harborFolder)

part("HarborPromenadePlaza", Vector3.new(64, 0.48, 28), Vector3.new(-68, 0.03, 230), PALETTE.cobbleLight, Enum.Material.Cobblestone, nil, harborFolder)

registerFootprint(-58, 232, 72, 18)



-- สะพานหินข้ามแม่น้ำทางใต้ (เปิดราวสะพานฝั่งตะวันตกช่วง Z = 238..264 ให้เดินเลี้ยวลงท่าเรือได้สะดวก)

part("RiverStoneBridgeDeck", Vector3.new(22, 1.6, 86), Vector3.new(0, 2.2, 280), PALETTE.cobbleMain, Enum.Material.Cobblestone, nil, harborFolder)

part("BridgeParapetEast", Vector3.new(1.6, 3.2, 86), Vector3.new(10, 4.4, 280), PALETTE.stoneWall, Enum.Material.Cobblestone, nil, harborFolder)

part("BridgeParapetWestSouth", Vector3.new(1.6, 3.2, 56), Vector3.new(-10, 4.4, 295), PALETTE.stoneWall, Enum.Material.Cobblestone, nil, harborFolder)



-- ชานชาลาไม้ท่าเรือหลักและบันไดไม้กว้างเชื่อมจากถนนเลียบท่าเรือลงสู่ท่าเทียบเรือ

part("WharfAccessSteps1", Vector3.new(44, 0.5, 6), Vector3.new(-68, 0.45, 241), PALETTE.timberMed, Enum.Material.WoodPlanks, nil, harborFolder)

part("WharfAccessSteps2", Vector3.new(44, 0.9, 6), Vector3.new(-68, 0.85, 244), PALETTE.timberMed, Enum.Material.WoodPlanks, nil, harborFolder)

part("WharfMainDeck", Vector3.new(112, 1.2, 26), Vector3.new(-66, 1.2, 256), PALETTE.timberMed, Enum.Material.WoodPlanks, nil, harborFolder)

for _, px in ipairs({-108, -68, -28}) do

	part("WharfFingerPier", Vector3.new(12, 1.0, 42), Vector3.new(px, 1.1, 286), PALETTE.timberMed, Enum.Material.WoodPlanks, nil, harborFolder)

	for _, pz in ipairs({270, 286, 302}) do

		part("PierPiling", Vector3.new(1.4, 7, 1.4), Vector3.new(px - 4.5, -0.5, pz), PALETTE.timberDark, Enum.Material.Wood, nil, harborFolder)

		part("PierPiling", Vector3.new(1.4, 7, 1.4), Vector3.new(px + 4.5, -0.5, pz), PALETTE.timberDark, Enum.Material.Wood, nil, harborFolder)

	end

end



-- ซุ้มประตูไม้เข้าท่าเรือ (Harbor Welcome Archway) ริมถนน SouthMainAvenue

part("HarborArchPillarN", Vector3.new(2.2, 14, 2.2), Vector3.new(-16, 7, 222), PALETTE.timberDark, Enum.Material.Wood, nil, harborFolder)

part("HarborArchPillarS", Vector3.new(2.2, 14, 2.2), Vector3.new(-16, 7, 242), PALETTE.timberDark, Enum.Material.Wood, nil, harborFolder)

part("HarborArchBeam", Vector3.new(2.6, 2.4, 24), Vector3.new(-16, 14.5, 232), PALETTE.timberMed, Enum.Material.WoodPlanks, nil, harborFolder, false)



-- บ้านคนเรือ / ที่ทำการท่าเรือการค้า (หันหน้าลงทิศใต้ yaw = math.pi สู่ถนนเลียบท่าเรือและเรือใบ ไม่มีกำแพงบัง!)

buildMedievalBuilding("HarborWarehouse", Vector3.new(-68, 0, 206), math.pi, "Large", PALETTE.plasterTan, PALETTE.roofBrown, "บ้านคนเรือ & ท่าเรือ\nHARBOR MASTER", {

	modelName = "HarborMasterNPC",

	displayName = "กัปตันท่าเรือ Drake",

	actionText = "ออกเรือไปเมือง Morroc / Amatsu",

	remoteName = "OpenWorldTravel",

	greeting = "ยินดีต้อนรับสู่ท่าเรือ Prontera! เรือไปเมืองทะเลทราย Morroc และเมืองน้ำ Amatsu กำลังเตรียมพร้อม!",

})



-- ลังสินค้าและโคมไฟริมท่าเรือ

for i, cPos in ipairs({Vector3.new(-92, 2.8, 250), Vector3.new(-88, 2.8, 251), Vector3.new(-42, 2.8, 250)}) do

	part("HarborCrate_" .. i, Vector3.new(3.2, 3.2, 3.2), cPos, PALETTE.timberMed, Enum.Material.WoodPlanks, nil, harborFolder)

end



do

	local shipPos = Vector3.new(-68, 0.6, 318)

	part("ShipHull", Vector3.new(44, 6, 14), shipPos, PALETTE.timberMed, Enum.Material.WoodPlanks, nil, harborFolder)

	part("ShipSternCastle", Vector3.new(13, 9, 14.5), shipPos + Vector3.new(-15.5, 5, 0), PALETTE.timberDark, Enum.Material.WoodPlanks, nil, harborFolder)

	part("ShipMast", Vector3.new(1.5, 34, 1.5), shipPos + Vector3.new(0, 19, 0), PALETTE.timberDark, Enum.Material.Wood, nil, harborFolder, false)

	part("ShipMainSail", Vector3.new(1.2, 19, 24), shipPos + Vector3.new(1.5, 21, 0), PALETTE.plasterCream, Enum.Material.Fabric, nil, harborFolder, false)

end



-- ============================================================

-- 12. กำแพงเมืองหินและประตูตะวันออก (เว้นช่องเปิดหน้าท่าเรือ X = -128..+22 ให้เปิดโล่งออกสู่แม่น้ำและท่าเรือ)

-- ============================================================

local wallFolder = Instance.new("Folder")

wallFolder.Name = "TownPerimeterWalls"

wallFolder.Parent = root



local function buildWallSegment(p1, p2)

	local diff = p2 - p1

	local len = diff.Magnitude

	local mid = (p1 + p2) / 2

	local cf = CFrame.lookAt(mid, p2)

	cframePart("FortifiedWall", Vector3.new(10, 22, len), cf + Vector3.new(0, 11, 0), PALETTE.stoneWall, Enum.Material.Cobblestone, wallFolder, true)

	cframePart("WallWalkway", Vector3.new(12, 1.5, len), cf + Vector3.new(0, 22.5, 0), PALETTE.stoneLight, Enum.Material.Cobblestone, wallFolder, false)

end



local function buildGuardTower(pos)

	part("WallWatchTower", Vector3.new(18, 30, 18), pos + Vector3.new(0, 15, 0), PALETTE.stoneWall, Enum.Material.Cobblestone, nil, wallFolder)

	part("WallWatchTowerRoof", Vector3.new(21, 9, 21), pos + Vector3.new(0, 34.5, 0), PALETTE.roofRed, Enum.Material.Slate, nil, wallFolder, false)

end



-- แนวกำแพงฝั่งตะวันตกสิ้นสุดที่ป้อมยามริมอ่าวตะวันตก (X = -128, Z = 232) เพื่อไม่ให้บังทางเข้าท่าเรือและบ้านคนเรือ

local wallPoints = {

	Vector3.new(65, 0, -165),

	Vector3.new(-150, 0, -210),

	Vector3.new(-305, 0, -195),

	Vector3.new(-320, 0, 0),

	Vector3.new(-305, 0, 195),

	Vector3.new(-185, 0, 228),

	Vector3.new(-128, 0, 232),

}

for i = 1, #wallPoints - 1 do

	buildWallSegment(wallPoints[i], wallPoints[i + 1])

	buildGuardTower(wallPoints[i])

end

buildGuardTower(wallPoints[#wallPoints])



-- กำแพงฝั่งตะวันออกเฉียงใต้ เริ่มจากป้อมยามฝั่งตะวันออกของสะพาน (X = 24, Z = 232) ไปถึงมุมกำแพงตะวันออก (X = 65, Z = 232)

buildGuardTower(Vector3.new(24, 0, 232))

buildWallSegment(Vector3.new(24, 0, 232), Vector3.new(65, 0, 232))

buildWallSegment(Vector3.new(65, 0, -165), Vector3.new(65, 0, -18))

buildWallSegment(Vector3.new(65, 0,  18), Vector3.new(65, 0, 232))

buildGuardTower(Vector3.new(65, 0, 232))

registerFootprint(65, 35, 12, 205)



-- ซุ้มประตูตะวันออก @ X = 65

for _, z in ipairs({-14, 14}) do

	part("EastGateTower", Vector3.new(9, 24, 9), Vector3.new(65, 12, z), PALETTE.stoneLight, Enum.Material.Sandstone, nil, wallFolder)

	part("EastGateTowerCap", Vector3.new(11, 6, 11), Vector3.new(65, 27, z), PALETTE.roofRed, Enum.Material.Slate, nil, wallFolder, false)

end

part("EastGateLintel", Vector3.new(7, 5, 36), Vector3.new(65, 21.5, 0), PALETTE.stoneLight, Enum.Material.Sandstone, nil, wallFolder, false)



-- ============================================================

-- 13. ยกระดับแผนที่ล่ามอนสเตอร์นอกประตูตะวันออก (3D RPG Adventure Valley X = 78..365)

--     ประกอบด้วยหน้าผาหุบเขา น้ำตก ลำธารสะพานไม้ ศาลาพักผ่อน โรงนา กังหันลม หอคอยนายพราน ถ้ำหมาป่า และดันเจี้ยนสุสานโบราณ!

-- ============================================================

local habitatsFolder = Instance.new("Folder")

habitatsFolder.Name = "MonsterHabitats"

habitatsFolder.Parent = root



local function makeZoneSign(pos, titleText, subText, accentColor)

	part("ZoneSignPost", Vector3.new(0.6, 5.5, 0.6), pos + Vector3.new(0, 2.75, 0), PALETTE.timberDark, Enum.Material.Wood, nil, habitatsFolder, false)

	local board = part("ZoneSignBoard", Vector3.new(7.4, 2.6, 0.4), pos + Vector3.new(0, 4.9, 0), PALETTE.timberMed, Enum.Material.WoodPlanks, nil, habitatsFolder, false)

	for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do

		local gui = Instance.new("SurfaceGui")

		gui.Face = face

		gui.CanvasSize = Vector2.new(440, 160)

		gui.Parent = board

		local lbl = Instance.new("TextLabel")

		lbl.Size = UDim2.fromScale(1, 1)

		lbl.BackgroundTransparency = 1

		lbl.Font = Enum.Font.GothamBold

		lbl.TextScaled = true

		lbl.TextColor3 = accentColor or Color3.fromRGB(255, 236, 175)

		lbl.Text = titleText .. "\n" .. subText

		lbl.Parent = gui

	end

end



-- (13.0) หน้าผาหินและแนวเทือกเขาล้อมรอบหุบเขาล่ามอนสเตอร์ (ป้องกันไม่ให้เห็นขอบแมพโล่งแบน)

local valleyCliffConfigs = {

	-- แนวหน้าผาทิศเหนือ (Z = -96..-118)

	{ sz = Vector3.new(64, 28, 26), pos = Vector3.new(108, 14, -98), col = PALETTE.stoneLight, mat = Enum.Material.Rock },

	{ sz = Vector3.new(58, 36, 28), pos = Vector3.new(165, 18, -102), col = PALETTE.stoneWall, mat = Enum.Material.Rock },

	{ sz = Vector3.new(75, 44, 32), pos = Vector3.new(230, 22, -104), col = PALETTE.stoneDark, mat = Enum.Material.Rock },

	{ sz = Vector3.new(85, 52, 34), pos = Vector3.new(305, 26, -102), col = PALETTE.stoneDark, mat = Enum.Material.Rock },

	-- ยอดหญ้าบนหน้าผาทิศเหนือ

	{ sz = Vector3.new(62, 2.5, 24), pos = Vector3.new(108, 28.5, -98), col = PALETTE.meadowGrass, mat = Enum.Material.Grass },

	{ sz = Vector3.new(72, 2.5, 28), pos = Vector3.new(230, 44.5, -104), col = PALETTE.forestFloor, mat = Enum.Material.Grass },

	-- แนวหน้าผาหินทิศตะวันออก (X = 348..372)

	{ sz = Vector3.new(32, 56, 120), pos = Vector3.new(354, 28, -42), col = PALETTE.stoneDark, mat = Enum.Material.Rock },

	{ sz = Vector3.new(34, 48, 125), pos = Vector3.new(352, 24,  58), col = Color3.fromRGB(64, 62, 68), mat = Enum.Material.Slate },

	-- แนวเนินผาทิศใต้ (Z = 96..115)

	{ sz = Vector3.new(95, 22, 24), pos = Vector3.new(135, 11, 98), col = PALETTE.stoneLight, mat = Enum.Material.Rock },

	{ sz = Vector3.new(145, 32, 26), pos = Vector3.new(265, 16, 102), col = Color3.fromRGB(68, 65, 72), mat = Enum.Material.Slate },

}

for i, cf in ipairs(valleyCliffConfigs) do

	part("ValleyCliff_" .. i, cf.sz, cf.pos, cf.col, cf.mat, nil, habitatsFolder)

end



-- ============================================================

-- 13. เขตล่ามอนสเตอร์ขยายใหญ่พิเศษ (Expanded Hunting Grounds @ X = 85..520, Z = -150..150)

-- จัดองค์ประกอบกว้างขวาง สวยงาม มีชีวิตชีวา ไม่แออัด รองรับผู้เล่น 10-50 คน

-- ย้ายลำธารมาที่ X = 188 พร้อมสะพานหินโค้งใหญ่และสะพานไม้

-- ============================================================



-- ผนังหน้าผาธรรมชาติล้อมรอบหุบเขาล่าสัตว์

local valleyCliffConfigs = {

	{ sz = Vector3.new(440, 28, 22), pos = Vector3.new(300, 14, -155), col = PALETTE.stoneDark, mat = Enum.Material.Rock },

	{ sz = Vector3.new(440, 28, 22), pos = Vector3.new(300, 14,  155), col = PALETTE.stoneDark, mat = Enum.Material.Rock },

	{ sz = Vector3.new(22, 34, 320), pos = Vector3.new(525, 17,    0), col = PALETTE.stoneDark, mat = Enum.Material.Rock },

}

for i, cf in ipairs(valleyCliffConfigs) do

	part("ValleyCliff_" .. i, cf.sz, cf.pos, cf.col, cf.mat, nil, habitatsFolder)

end



-- ลำธารใส (Scenic Meadow Creek @ X = 188) ไหลผ่านกลางหุบเขา

part("WaterfallCliffBack", Vector3.new(22, 36, 16), Vector3.new(188, 18, -145), PALETTE.stoneWall, Enum.Material.Rock, nil, habitatsFolder)

local wfStream = part("WaterfallCascade", Vector3.new(9.5, 34, 2.4), Vector3.new(188, 17, -137), Color3.fromRGB(115, 215, 245), Enum.Material.Glass, nil, habitatsFolder, false)

wfStream.Transparency = 0.2

part("WaterfallFoamTop", Vector3.new(10.5, 2.5, 3.5), Vector3.new(188, 33, -137), Color3.fromRGB(235, 250, 255), Enum.Material.Neon, Enum.PartType.Ball, habitatsFolder, false)

part("WaterfallFoamPool", Vector3.new(18, 1.4, 18), Vector3.new(188, 0.5, -130), Color3.fromRGB(165, 235, 255), Enum.Material.Neon, Enum.PartType.Cylinder, habitatsFolder, false)



local creekWater = part("MeadowCreekWater", Vector3.new(12, 0.38, 290), Vector3.new(188, 0.08, 0), Color3.fromRGB(75, 185, 225), Enum.Material.Glass, nil, habitatsFolder, false)

creekWater.Transparency = 0.22

part("MeadowCreekBed", Vector3.new(15, 0.24, 292), Vector3.new(188, 0.01, 0), Color3.fromRGB(168, 152, 122), Enum.Material.Sand, nil, habitatsFolder)



-- สะพานหินทรงโค้งกลางลำธาร (Central Grand Stone Arch Bridge @ X = 188, Z = 0)

part("CenterStoneBridgeDeck", Vector3.new(24, 1.4, 18), Vector3.new(188, 0.7, 0), PALETTE.stoneLight, Enum.Material.Cobblestone, nil, habitatsFolder)

part("CenterStoneBridgeRoad", Vector3.new(24, 0.2, 14), Vector3.new(188, 1.4, 0), PALETTE.cobbleMain, Enum.Material.Cobblestone, nil, habitatsFolder)

for _, bz in ipairs({-8.5, 8.5}) do

	part("BridgeStoneParapet", Vector3.new(24, 2.6, 1.2), Vector3.new(188, 2.2, bz), PALETTE.stoneLight, Enum.Material.Sandstone, nil, habitatsFolder)

	for _, bx in ipairs({-10, 0, 10}) do

		local bPost = part("BridgeStonePost", Vector3.new(1.8, 3.6, 1.8), Vector3.new(188 + bx, 2.6, bz), PALETTE.stoneWall, Enum.Material.Cobblestone, nil, habitatsFolder)

		local bLamp = part("BridgeLantern", Vector3.new(1.2, 1.2, 1.2), Vector3.new(188 + bx, 4.8, bz), PALETTE.windowGlow, Enum.Material.Neon, Enum.PartType.Ball, habitatsFolder, false)

		local bl = Instance.new("PointLight")

		bl.Color = PALETTE.windowGlow

		bl.Brightness = 1.0

		bl.Range = 16

		bl.Parent = bLamp

	end

end



-- สะพานไม้ฝั่งเหนือ (North Timber Footbridge @ X = 188, Z = -80)

part("NorthWoodBridgeDeck", Vector3.new(20, 0.8, 12), Vector3.new(188, 0.6, -80), PALETTE.timberMed, Enum.Material.WoodPlanks, nil, habitatsFolder)

for _, bz in ipairs({-5.5, 5.5}) do

	part("NorthBridgeRailL", Vector3.new(20, 0.45, 0.45), Vector3.new(188, 2.8, -80 + bz), PALETTE.timberDark, Enum.Material.Wood, nil, habitatsFolder)

	for _, bx in ipairs({-8, 0, 8}) do

		part("NorthBridgePost", Vector3.new(0.8, 2.8, 0.8), Vector3.new(188 + bx, 1.8, -80 + bz), PALETTE.timberDark, Enum.Material.Wood, nil, habitatsFolder)

	end

end



-- ── โซนที่ 1: ทุ่งดอกไม้และเนินหญ้ากว้าง Poring Blossom Meadow (Lv.1, X = 85..182, Z = -140..140) ──

part("PoringMeadowGround", Vector3.new(98, 0.22, 280), Vector3.new(134, 0.04, 0), PALETTE.meadowGrass, Enum.Material.Grass, nil, habitatsFolder)

part("PoringMoundNorth", Vector3.new(36, 4.2, 34), Vector3.new(130, -0.4, -65), PALETTE.meadowGrass, Enum.Material.Grass, Enum.PartType.Ball, habitatsFolder)

part("PoringMoundSouth", Vector3.new(38, 4.8, 36), Vector3.new(135, -0.5,  65), PALETTE.meadowGrass, Enum.Material.Grass, Enum.PartType.Ball, habitatsFolder)

makeZoneSign(Vector3.new(84, 0, -14), "โซน 1: ทุ่งหน้าประตูเมือง (Lv.1)", "Poring โพริ่ง • มอนสเตอร์เริ่มต้น ดรอป Jellopy & Apple", Color3.fromRGB(255, 195, 215))



-- ศาลาพักผ่อนนักผจญภัยกลางทุ่ง (Adventurer Rest Gazebo @ X = 120, Z = -35)

do

	local gzPos = Vector3.new(120, 0, -35)

	part("GazeboBase", Vector3.new(14, 0.8, 14), gzPos + Vector3.new(0, 0.4, 0), PALETTE.stoneLight, Enum.Material.Cobblestone, nil, habitatsFolder)

	for _, gx in ipairs({-5.5, 5.5}) do

		for _, gz in ipairs({-5.5, 5.5}) do

			part("GazeboPillar", Vector3.new(0.9, 9.5, 0.9), gzPos + Vector3.new(gx, 5.15, gz), PALETTE.stoneLight, Enum.Material.Marble, nil, habitatsFolder)

		end

	end

	part("GazeboRoofTier1", Vector3.new(16, 1.8, 16), gzPos + Vector3.new(0, 10.6, 0), PALETTE.roofRed, Enum.Material.Slate, nil, habitatsFolder, false)

	part("GazeboRoofTier2", Vector3.new(10, 2.2, 10), gzPos + Vector3.new(0, 12.4, 0), PALETTE.roofRed, Enum.Material.Slate, nil, habitatsFolder, false)

	part("GazeboBench", Vector3.new(6, 1.2, 2.2), gzPos + Vector3.new(0, 1.4, -4), PALETTE.timberMed, Enum.Material.WoodPlanks, nil, habitatsFolder)

end



-- ต้นซากุระบานสะพรั่งกระจายทั่วทุ่งหญ้า Poring

for i, skPos in ipairs({

	Vector3.new(98, 0, -35), Vector3.new(138, 0, -35), Vector3.new(110, 0, -85), Vector3.new(155, 0, -90),

	Vector3.new(98, 0,  35), Vector3.new(138, 0,  35), Vector3.new(115, 0,  85), Vector3.new(155, 0,  90),

}) do

	part("SakuraTrunk_" .. i, Vector3.new(2.2, 12, 2.2), skPos + Vector3.new(0, 6, 0), PALETTE.timberDark, Enum.Material.Wood, nil, habitatsFolder)

	part("SakuraCanopyMain_" .. i, Vector3.new(16, 11, 16), skPos + Vector3.new(0, 14, 0), Color3.fromRGB(255, 162, 198), Enum.Material.Grass, Enum.PartType.Ball, habitatsFolder, false)

	part("SakuraCanopySub_" .. i, Vector3.new(12, 9, 12), skPos + Vector3.new(3.5, 12.5, 2.5), Color3.fromRGB(255, 185, 212), Enum.Material.Grass, Enum.PartType.Ball, habitatsFolder, false)

end



for i, flPos in ipairs({

	Vector3.new(102, 0.4, -22), Vector3.new(125, 0.4, -20), Vector3.new(145, 0.4, -18),

	Vector3.new(102, 0.4,  22), Vector3.new(125, 0.4,  24), Vector3.new(145, 0.4,  20),

}) do

	part("FlowerBush_" .. i, Vector3.new(3.6, 1.6, 3.6), flPos, Color3.fromRGB(116, 178, 86), Enum.Material.Grass, Enum.PartType.Ball, habitatsFolder, false)

	part("PinkBlossom_" .. i, Vector3.new(1.4, 1.4, 1.4), flPos + Vector3.new(0, 0.9, 0), Color3.fromRGB(255, 142, 182), Enum.Material.SmoothPlastic, Enum.PartType.Ball, habitatsFolder, false)

end



-- ── โซนที่ 2: ฟาร์มแครอทและทุ่งโคลเวอร์ Lunatic & Fabre Farmlands (Lv.2-15, X = 195..285, Z = -150..-15) ──

part("LunaticPatchGround", Vector3.new(90, 0.22, 136), Vector3.new(240, 0.04, -82), Color3.fromRGB(118, 164, 78), Enum.Material.Grass, nil, habitatsFolder)

makeZoneSign(Vector3.new(198, 0, -14), "โซน 2: ฟาร์มและทุ่งหญ้าโคลเวอร์ (Lv.2-15)", "Fabre, Lunatic & Goblin • Clover & Carrot", Color3.fromRGB(255, 240, 165))



-- โรงนาไม้สีแดง (Red Farmer's Barn Shed @ X = 245, Z = -100) และกองฟางสีทอง

do

	local barnPos = Vector3.new(245, 0, -100)

	part("BarnFoundation", Vector3.new(22, 1.0, 16), barnPos + Vector3.new(0, 0.5, 0), PALETTE.stoneWall, Enum.Material.Cobblestone, nil, habitatsFolder)

	part("BarnWalls", Vector3.new(20.5, 13, 14.8), barnPos + Vector3.new(0, 7.2, 0), Color3.fromRGB(168, 62, 52), Enum.Material.WoodPlanks, nil, habitatsFolder)

	part("BarnRoof", Vector3.new(23, 6.5, 17.5), barnPos + Vector3.new(0, 16.5, 0), PALETTE.roofBrown, Enum.Material.WoodPlanks, nil, habitatsFolder, false)

	part("BarnDoorFrame", Vector3.new(6.5, 8.5, 0.6), barnPos + Vector3.new(0, 5.2, 7.5), PALETTE.plasterCream, Enum.Material.Wood, nil, habitatsFolder, false)

	-- กองฟางทรงกระบอกสีทอง

	for idx, hbPos in ipairs({Vector3.new(230, 2.0, -92), Vector3.new(234, 2.0, -90), Vector3.new(232, 5.0, -91), Vector3.new(260, 2.0, -88)}) do

		cframePart("HayBale_" .. idx, Vector3.new(3.4, 3.8, 3.8), CFrame.new(hbPos) * CFrame.Angles(0, math.rad(idx * 35), 0), Color3.fromRGB(228, 188, 78), Enum.Material.Grass, habitatsFolder, true, Enum.PartType.Cylinder)

	end

end



-- กังหันลมสูบน้ำและหุ่นไล่กา

do

	local wpPos = Vector3.new(220, 0, -60)

	part("WindpumpTower", Vector3.new(4.2, 22, 4.2), wpPos + Vector3.new(0, 11, 0), PALETTE.timberDark, Enum.Material.Wood, nil, habitatsFolder)

	part("WindpumpWheel", Vector3.new(0.6, 9.0, 9.0), wpPos + Vector3.new(0, 20, 2.5), PALETTE.timberMed, Enum.Material.WoodPlanks, Enum.PartType.Cylinder, habitatsFolder, false)



	local scPos = Vector3.new(255, 0, -65)

	part("ScarecrowPost", Vector3.new(0.6, 7.0, 0.6), scPos + Vector3.new(0, 3.5, 0), PALETTE.timberDark, Enum.Material.Wood, nil, habitatsFolder, false)

	part("ScarecrowArms", Vector3.new(5.2, 0.5, 0.5), scPos + Vector3.new(0, 5.2, 0), PALETTE.timberDark, Enum.Material.Wood, nil, habitatsFolder, false)

	part("ScarecrowTorso", Vector3.new(2.2, 2.8, 1.4), scPos + Vector3.new(0, 4.8, 0), Color3.fromRGB(195, 118, 58), Enum.Material.Fabric, nil, habitatsFolder, false)

	part("ScarecrowHead", Vector3.new(1.8, 1.8, 1.8), scPos + Vector3.new(0, 6.8, 0), Color3.fromRGB(232, 165, 62), Enum.Material.SmoothPlastic, Enum.PartType.Ball, habitatsFolder, false)

end



-- แปลงปลูกแครอทและผัก

for _, patchZ in ipairs({-45, -75}) do

	part("CarrotGardenSoil", Vector3.new(34, 0.4, 18), Vector3.new(245, 0.2, patchZ), Color3.fromRGB(112, 82, 54), Enum.Material.Ground, nil, habitatsFolder)

	for cx = -12, 12, 4.8 do

		for cz = -5, 5, 5 do

			part("CarrotTop", Vector3.new(1.2, 1.3, 1.2), Vector3.new(245 + cx, 0.9, patchZ + cz), Color3.fromRGB(98, 185, 74), Enum.Material.Grass, Enum.PartType.Ball, habitatsFolder, false)

			part("CarrotRoot", Vector3.new(0.7, 0.9, 0.7), Vector3.new(245 + cx, 0.45, patchZ + cz), Color3.fromRGB(238, 126, 48), Enum.Material.SmoothPlastic, Enum.PartType.Ball, habitatsFolder, false)

		end

	end

end



-- ── โซนที่ 3: ป่าสนหุบเขาหมาป่า Whispering Wolf Woods (Lv.5, X = 195..315, Z = 15..150) ──

part("WolfForestGround", Vector3.new(120, 0.26, 136), Vector3.new(255, 0.06, 82), PALETTE.forestFloor, Enum.Material.Grass, nil, habitatsFolder)

makeZoneSign(Vector3.new(198, 0, 14), "โซน 3: ป่าสนและรังหมาป่า (Lv.5)", "Wolf หมาป่า • Raw Meat, Hide, Bone", Color3.fromRGB(255, 175, 110))



-- แคมป์ไฟนักล่าและเต็นท์พักแรม (Hunter Campfire & Tent @ X = 235, Z = 50)

do

	local campPos = Vector3.new(235, 0, 50)

	cframePart("HunterTentSideL", Vector3.new(0.4, 7.2, 8.5), CFrame.new(campPos + Vector3.new(-7, 3.0, -2)) * CFrame.Angles(0, 0, math.rad(-32)), PALETTE.plasterCream, Enum.Material.Fabric, habitatsFolder, true)

	cframePart("HunterTentSideR", Vector3.new(0.4, 7.2, 8.5), CFrame.new(campPos + Vector3.new(-3.2, 3.0, -2)) * CFrame.Angles(0, 0, math.rad(32)), PALETTE.plasterCream, Enum.Material.Fabric, habitatsFolder, true)

	local fireGlow = part("CampfireFlame", Vector3.new(2.4, 2.8, 2.4), campPos + Vector3.new(2, 1.4, 0), Color3.fromRGB(255, 145, 42), Enum.Material.Neon, Enum.PartType.Ball, habitatsFolder, false)

	local campLight = Instance.new("PointLight")

	campLight.Color = Color3.fromRGB(255, 165, 75)

	campLight.Brightness = 1.4

	campLight.Range = 24

	campLight.Parent = fireGlow

	part("CampfireRocks", Vector3.new(4.2, 0.9, 4.2), campPos + Vector3.new(2, 0.45, 0), PALETTE.stoneDark, Enum.Material.Rock, Enum.PartType.Cylinder, habitatsFolder)

end



-- หอคอยสังเกตการณ์นายพราน (Watchtower @ X = 268, Z = 95)

do

	local wtPos = Vector3.new(268, 0, 95)

	for _, lx in ipairs({-4.5, 4.5}) do

		for _, lz in ipairs({-4.5, 4.5}) do

			part("WatchtowerLeg", Vector3.new(1.3, 18, 1.3), wtPos + Vector3.new(lx, 9, lz), PALETTE.timberDark, Enum.Material.Wood, nil, habitatsFolder)

		end

	end

	part("WatchtowerPlatform", Vector3.new(12, 0.9, 12), wtPos + Vector3.new(0, 18, 0), PALETTE.timberMed, Enum.Material.WoodPlanks, nil, habitatsFolder)

	part("WatchtowerRoof", Vector3.new(14, 5.0, 14), wtPos + Vector3.new(0, 25.5, 0), PALETTE.roofBrown, Enum.Material.WoodPlanks, nil, habitatsFolder, false)

end



-- ถ้ำรังหมาป่าในหินผา (Wolf Den Cave @ X = 295, Z = 125)

do

	local denPos = Vector3.new(295, 0, 125)

	part("WolfDenMound", Vector3.new(32, 20, 20), denPos + Vector3.new(0, 10, -4), PALETTE.stoneDark, Enum.Material.Rock, nil, habitatsFolder)

	part("WolfDenDarkMouth", Vector3.new(13, 10, 5), denPos + Vector3.new(0, 5.0, 4.5), Color3.fromRGB(18, 16, 22), Enum.Material.Slate, nil, habitatsFolder, false)

end



for i, rockPos in ipairs({

	Vector3.new(225, 2.5, 70), Vector3.new(260, 3.0, 65), Vector3.new(280, 2.2, 85), Vector3.new(245, 2.0, 115),

}) do

	part("ForestBoulder_" .. i, Vector3.new(8.5, 5.5, 7.5), rockPos, PALETTE.stoneDark, Enum.Material.Rock, Enum.PartType.Ball, habitatsFolder)

end

cframePart("FallenLog", Vector3.new(2.4, 16, 2.4), CFrame.new(250, 1.2, 55) * CFrame.Angles(math.rad(88), math.rad(35), 0), PALETTE.timberDark, Enum.Material.Wood, habitatsFolder, true, Enum.PartType.Cylinder)



-- ── โซนที่ 4: ซากปรักหักพังทะเลทราย Sunken Desert Ruins (Lv.20-28, X = 315..420, Z = -150..-15) ──

part("DesertRuinsGround", Vector3.new(105, 0.28, 136), Vector3.new(368, 0.06, -82), Color3.fromRGB(218, 178, 115), Enum.Material.Sand, nil, habitatsFolder)

makeZoneSign(Vector3.new(318, 0, -14), "โซน 4: ซากโบราณทะเลทราย (Lv.20-28)", "Scorpion & Sandman • แมงป่องและภูตทราย", Color3.fromRGB(240, 180, 70))



-- เสาหินทรายโบราณและโอเบลิสก์

for idx, colPos in ipairs({

	Vector3.new(335, 0, -45), Vector3.new(355, 0, -45), Vector3.new(375, 0, -45),

	Vector3.new(345, 0, -95), Vector3.new(365, 0, -95), Vector3.new(385, 0, -95),

}) do

	part("DesertPillarBase_" .. idx, Vector3.new(4.2, 1.4, 4.2), colPos + Vector3.new(0, 0.7, 0), PALETTE.stoneLight, Enum.Material.Sandstone, nil, habitatsFolder)

	local h = (idx % 2 == 0) and 14 or 9

	part("DesertPillarShaft_" .. idx, Vector3.new(3.0, h, 3.0), colPos + Vector3.new(0, 1.4 + h / 2, 0), PALETTE.stoneLight, Enum.Material.Sandstone, nil, habitatsFolder)

end

part("DesertObelisk", Vector3.new(3.8, 22, 3.8), Vector3.new(365, 11, -70), PALETTE.stoneLight, Enum.Material.Sandstone, nil, habitatsFolder)



-- ── โซนที่ 5: สุสานโบราณและดันเจี้ยน Undead Graveyard & Crypt (Lv.8-15, X = 315..420, Z = 15..150) ──

part("GraveyardGround", Vector3.new(105, 0.28, 136), Vector3.new(368, 0.07, 82), PALETTE.graveyardDirt, Enum.Material.Slate, nil, habitatsFolder)

makeZoneSign(Vector3.new(318, 0, 14), "โซน 5: สุสานโบราณ (Lv.8-15)", "Zombie & Skeleton • โครงกระดูกและซอมบี้", Color3.fromRGB(198, 155, 255))



-- ซุ้มประตูเหล็กดัดทางเข้าสุสาน

part("GraveyardGatePillarL", Vector3.new(4.0, 14, 4.0), Vector3.new(326, 7, 24), PALETTE.stoneDark, Enum.Material.Cobblestone, nil, habitatsFolder)

part("GraveyardGatePillarR", Vector3.new(4.0, 14, 4.0), Vector3.new(342, 7, 24), PALETTE.stoneDark, Enum.Material.Cobblestone, nil, habitatsFolder)

part("GraveyardGateArch", Vector3.new(20, 2.6, 2.8), Vector3.new(334, 14.8, 24), PALETTE.stoneDark, Enum.Material.Cobblestone, nil, habitatsFolder, false)

for _, gx in ipairs({326, 342}) do

	part("GateSoulOrb", Vector3.new(2.2, 2.2, 2.2), Vector3.new(gx, 15.5, 24), Color3.fromRGB(178, 112, 255), Enum.Material.Neon, Enum.PartType.Ball, habitatsFolder, false)

end



-- ป้ายหลุมศพหิน 12 หลุมกระจายอย่างเป็นระเบียบ

local tombPositions = {

	Vector3.new(335, 0, 45), Vector3.new(355, 0, 45), Vector3.new(375, 0, 45), Vector3.new(395, 0, 45),

	Vector3.new(335, 0, 75), Vector3.new(355, 0, 75), Vector3.new(375, 0, 75), Vector3.new(395, 0, 75),

	Vector3.new(335, 0, 105), Vector3.new(355, 0, 105), Vector3.new(375, 0, 105), Vector3.new(395, 0, 105),

}

for idx, tPos in ipairs(tombPositions) do

	part("TombBase_" .. idx, Vector3.new(3.0, 0.7, 1.8), tPos + Vector3.new(0, 0.35, 0), PALETTE.stoneDark, Enum.Material.Cobblestone, nil, habitatsFolder)

	part("TombStone_" .. idx, Vector3.new(2.4, 4.0, 0.8), tPos + Vector3.new(0, 2.35, 0), PALETTE.stoneWall, Enum.Material.Slate, nil, habitatsFolder)

	part("DirtMound_" .. idx, Vector3.new(2.6, 0.5, 4.6), tPos + Vector3.new(0, 0.25, 3.0), Color3.fromRGB(62, 54, 48), Enum.Material.Ground, nil, habitatsFolder, false)

end



-- ซากสุสานโบราณ (Ancient Crypt Mausoleum @ X = 390, Z = 80)

local cryptPos = Vector3.new(390, 0, 80)

part("CryptPlatform", Vector3.new(36, 1.8, 26), cryptPos + Vector3.new(0, 0.9, 0), PALETTE.stoneDark, Enum.Material.Cobblestone, nil, habitatsFolder)

for _, px in ipairs({-15, -5, 5, 15}) do

	local h = (math.abs(px) > 10) and 15 or 10

	part("RuinedPillarFront", Vector3.new(3.0, h, 3.0), cryptPos + Vector3.new(px, 1.8 + h / 2, -10), PALETTE.stoneWall, Enum.Material.Cobblestone, nil, habitatsFolder)

	part("RuinedPillarBack",  Vector3.new(3.0, 15, 3.0), cryptPos + Vector3.new(px, 1.8 + 7.5, 10), PALETTE.stoneWall, Enum.Material.Cobblestone, nil, habitatsFolder)

end

local soulFire = part("CryptSoulBrazer", Vector3.new(2.8, 2.8, 2.8), cryptPos + Vector3.new(0, 3.8, 0), Color3.fromRGB(138, 195, 255), Enum.Material.Neon, Enum.PartType.Ball, habitatsFolder, false)

local soulLight = Instance.new("PointLight")

soulLight.Color = soulFire.Color

soulLight.Brightness = 1.6

soulLight.Range = 32

soulLight.Parent = soulFire



-- ── โซนที่ 6: หุบผามังกรและแท่นบูชาบอสเดรค Dragon Crag & Drake Shrine (MVP Boss, X = 420..520, Z = -80..80) ──

part("DragonCragGround", Vector3.new(100, 0.35, 160), Vector3.new(470, 0.08, 0), Color3.fromRGB(48, 42, 45), Enum.Material.Basalt, nil, habitatsFolder)

makeZoneSign(Vector3.new(424, 0, 0), "โซน 6: ลานบอสเดรคและมิโนรัส (MVP Drake & Minorous)", "👑 บอสระดับโลก เกิดทุก 2 ชั่วโมง", Color3.fromRGB(255, 100, 100))



-- แท่นบูชาออบซิเดียนของบอสเดรค (Drake Obsidian Altar @ X = 485, Z = 0)

do

	local altarPos = Vector3.new(485, 0, 0)

	part("DrakeAltarPlatform", Vector3.new(34, 2.2, 34), altarPos + Vector3.new(0, 1.1, 0), Color3.fromRGB(30, 26, 32), Enum.Material.Basalt, nil, habitatsFolder)

	part("DrakeAltarSteps", Vector3.new(38, 0.8, 38), altarPos + Vector3.new(0, 0.4, 0), Color3.fromRGB(40, 35, 42), Enum.Material.Cobblestone, nil, habitatsFolder)

	for angle = 0, 315, 45 do

		local rad = math.rad(angle)

		local px = math.cos(rad) * 14

		local pz = math.sin(rad) * 14

		part("DrakePillar_" .. angle, Vector3.new(3.2, 16, 3.2), altarPos + Vector3.new(px, 8, pz), Color3.fromRGB(24, 20, 26), Enum.Material.Basalt, nil, habitatsFolder)

		local flame = part("DrakeFlame_" .. angle, Vector3.new(2.0, 2.0, 2.0), altarPos + Vector3.new(px, 17, pz), Color3.fromRGB(255, 75, 40), Enum.Material.Neon, Enum.PartType.Ball, habitatsFolder, false)

		local fl = Instance.new("PointLight")

		fl.Color = Color3.fromRGB(255, 90, 50)

		fl.Brightness = 1.2

		fl.Range = 20

		fl.Parent = flame

	end

end



local treesFolder = Instance.new("Folder")

treesFolder.Name = "VillageTrees"

treesFolder.Parent = root



local assetLib = ServerStorage:FindFirstChild("TownAssets")

local treeTemplates = {}

if assetLib then

	for _, m in ipairs(assetLib:GetChildren()) do

		if m:IsA("Model") and m:GetAttribute("Kind") == "Tree" then

			table.insert(treeTemplates, m)

		end

	end

end



local function spawnTree(x, z, targetHeight, seed)

	if isInsideAnyFootprint(x, z, 4) then return end

	if #treeTemplates > 0 then

		local tpl = treeTemplates[(seed % #treeTemplates) + 1]:Clone()

		for _, d in ipairs(tpl:GetDescendants()) do

			if d:IsA("BasePart") then d.Anchored = true end

		end

		local _, sz = tpl:GetBoundingBox()

		if sz.Y > 0 then tpl:ScaleTo(tpl:GetScale() * (targetHeight / sz.Y)) end

		local _, scaledSz = tpl:GetBoundingBox()

		tpl:PivotTo(CFrame.new(x, scaledSz.Y / 2 - 0.3, z) * CFrame.Angles(0, (seed * 1.7) % (math.pi * 2), 0))

		local newCf = tpl:GetBoundingBox()

		tpl:PivotTo(tpl:GetPivot() + Vector3.new(x - newCf.X, 0, z - newCf.Z))

		tpl.Parent = treesFolder

	else

		part("Trunk", Vector3.new(2.2, targetHeight * 0.45, 2.2), Vector3.new(x, targetHeight * 0.22, z), PALETTE.timberDark, Enum.Material.Wood, nil, treesFolder)

		part("Canopy", Vector3.new(targetHeight * 0.55, targetHeight * 0.65, targetHeight * 0.55), Vector3.new(x, targetHeight * 0.62, z), PALETTE.grassDark, Enum.Material.Grass, Enum.PartType.Ball, treesFolder, false)

	end

end



-- ต้นไม้ในเขตป่าหมาป่าและขอบหุบเขาล่ามอนสเตอร์ (Wolf Pine Woods & Valley Rim)

local wolfTreeSpots = {

	{206, -20, 26}, {228, -18, 28}, {246, -20, 26}, {268, -22, 30}, {288, -24, 32},

	{208, -52, 30}, {232, -64, 32}, {262, -58, 28}, {286, -52, 32}, {305, -44, 34},

	{218, -76, 28}, {242, -78, 30}, {296, -74, 34}, {318, -68, 36},

	{92, -76, 26}, {122, -76, 28}, {158, -76, 26}, {188, -76, 28},

	{96,  78, 26}, {128,  78, 28}, {162,  78, 26}, {192,  78, 28},

}

for i, s in ipairs(wolfTreeSpots) do

	spawnTree(s[1], s[2], s[3], i * 2)

end



-- ต้นไม้ตามสวนรอบนอกและชานเมือง (ตรวจ Footprint อัตโนมัติ)

local townTreeSpots = {

	{-72, -135, 26}, {28, -125, 26}, {-28, -140, 28},

	{-75, 115, 24}, {-75, 165, 26}, {28, 115, 25}, {28, 165, 25},

	{-245, -48, 26}, {-245, 48, 26}, {-245, 105, 26},

}

for i, s in ipairs(townTreeSpots) do

	spawnTree(s[1], s[2], s[3], i + 20)

end



-- แนวป่ารอบนอกกำแพงเมือง (หลีกเลี่ยงแม่น้ำทางใต้ Z > 215 และเขตหุบเขาตะวันออก)

registerFootprint(-20, 300, 600, 80)

local rng = Random.new(20261021)

for i = 1, 65 do

	local angle = rng:NextNumber(math.rad(115), math.rad(235))

	local dist = rng:NextNumber(340, 420)

	local tx = math.cos(angle) * dist - 40

	local tz = math.sin(angle) * dist

	if tz < 210 then

		spawnTree(tx, tz, rng:NextNumber(26, 36), i + 100)

	end

end



-- ============================================================

-- 15. แสงบรรยากาศยุคกลางยามบ่ายอบอุ่น

-- ============================================================

Lighting.ClockTime = 15.2

Lighting.Brightness = 2.1

Lighting.Ambient = Color3.fromRGB(116, 119, 132)

Lighting.OutdoorAmbient = Color3.fromRGB(157, 164, 175)

local atmosphere = Lighting:FindFirstChild("RoROK_TownAtmosphere") or Instance.new("Atmosphere")

atmosphere.Name = "RoROK_TownAtmosphere"

atmosphere.Color = Color3.fromRGB(207, 223, 255)

atmosphere.Decay = Color3.fromRGB(135, 149, 171)

atmosphere.Density = 0.16

atmosphere.Haze = 0.8

atmosphere.Glare = 0.08

atmosphere.Parent = Lighting





-- ============================================================

-- 16. ชาวบ้านและบุคคลสำคัญประจำเมือง Prontera (Townsfolk & Villagers)

--     พร้อมระบบ VillagerId, ตำแหน่ง, ทรงผม/ชุดตามบทบาท, และ ProximityPrompt สำหรับบทสนทนา/เควส

-- ============================================================

local villagersFolder = Instance.new("Folder")

villagersFolder.Name = "TownVillagers"

villagersFolder.Parent = root



local function buildVillager(spec)

	local vModel = Instance.new("Model")

	vModel.Name = spec.id

	vModel.Parent = villagersFolder



	local pos = spec.pos

	local cf = CFrame.new(pos) * CFrame.Angles(0, spec.yaw or 0, 0)



	-- HumanoidRootPart (Torso)

	local torso = cframePart(spec.id .. "_Torso", Vector3.new(1.6, 2.0, 0.8), cf * CFrame.new(0, 2.8, 0), spec.coatColor or Color3.fromRGB(85, 110, 145), Enum.Material.SmoothPlastic, vModel, false)

	vModel.PrimaryPart = torso



	-- Head & Face

	cframePart(spec.id .. "_Head", Vector3.new(1.15, 1.15, 1.15), cf * CFrame.new(0, 4.45, 0), Color3.fromRGB(235, 185, 148), Enum.Material.SmoothPlastic, vModel, false, Enum.PartType.Ball)



	-- Hair / Headwear

	if spec.hatType == "NunVeil" then

		cframePart(spec.id .. "_Veil", Vector3.new(1.4, 1.6, 1.4), cf * CFrame.new(0, 4.6, 0.1), Color3.fromRGB(240, 240, 245), Enum.Material.Fabric, vModel, false)

	elseif spec.hatType == "GuardHelmet" then

		cframePart(spec.id .. "_Helmet", Vector3.new(1.35, 1.35, 1.35), cf * CFrame.new(0, 4.6, 0), Color3.fromRGB(165, 175, 185), Enum.Material.Metal, vModel, false)

		cframePart(spec.id .. "_Plume", Vector3.new(0.3, 0.9, 0.8), cf * CFrame.new(0, 5.4, 0), Color3.fromRGB(205, 45, 45), Enum.Material.Fabric, vModel, false)

	elseif spec.hatType == "StrawHat" then

		cframePart(spec.id .. "_HatBrim", Vector3.new(2.4, 0.18, 2.4), cf * CFrame.new(0, 4.95, 0), Color3.fromRGB(215, 185, 95), Enum.Material.Wood, vModel, false, Enum.PartType.Cylinder)

		cframePart(spec.id .. "_HatCrown", Vector3.new(1.2, 0.6, 1.2), cf * CFrame.new(0, 5.3, 0), Color3.fromRGB(200, 170, 85), Enum.Material.Wood, vModel, false, Enum.PartType.Cylinder)

	elseif spec.hatType == "ChefHat" then

		cframePart(spec.id .. "_ChefHat", Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(0, 5.25, 0), Color3.fromRGB(250, 250, 250), Enum.Material.Fabric, vModel, false, Enum.PartType.Ball)

	else

		cframePart(spec.id .. "_Hair", Vector3.new(1.25, 0.5, 1.25), cf * CFrame.new(0, 4.95, 0), spec.hairColor or Color3.fromRGB(95, 60, 40), Enum.Material.SmoothPlastic, vModel, false, Enum.PartType.Ball)

	end



	-- Arms & Legs

	for _, sx in ipairs({-1, 1}) do

		cframePart(spec.id .. "_Arm_" .. sx, Vector3.new(0.45, 1.8, 0.45), cf * CFrame.new(sx * 1.1, 2.8, 0), spec.coatColor or Color3.fromRGB(85, 110, 145), Enum.Material.SmoothPlastic, vModel, false)

		cframePart(spec.id .. "_Leg_" .. sx, Vector3.new(0.55, 1.8, 0.55), cf * CFrame.new(sx * 0.45, 0.9, 0), spec.pantsColor or Color3.fromRGB(55, 50, 60), Enum.Material.SmoothPlastic, vModel, false)

	end



	-- Accessory (e.g. Flower Basket, Spear, Harp, Tool)

	if spec.accessory == "FlowerBasket" then

		cframePart(spec.id .. "_Basket", Vector3.new(1.2, 0.9, 1.2), cf * CFrame.new(1.2, 2.1, 0.6), Color3.fromRGB(165, 118, 65), Enum.Material.Wood, vModel, false)

		cframePart(spec.id .. "_BasketFlowers", Vector3.new(1.0, 0.5, 1.0), cf * CFrame.new(1.2, 2.6, 0.6), Color3.fromRGB(255, 120, 160), Enum.Material.Grass, vModel, false, Enum.PartType.Ball)

	elseif spec.accessory == "GuardSpear" then

		cframePart(spec.id .. "_SpearPole", Vector3.new(0.18, 8.5, 0.18), cf * CFrame.new(1.1, 4.25, 0.3), Color3.fromRGB(90, 65, 45), Enum.Material.Wood, vModel, false)

		cframePart(spec.id .. "_SpearBlade", Vector3.new(0.3, 1.6, 0.6), cf * CFrame.new(1.1, 8.8, 0.3), Color3.fromRGB(210, 215, 225), Enum.Material.Metal, vModel, false)

	elseif spec.accessory == "MiningPick" then

		cframePart(spec.id .. "_PickHandle", Vector3.new(0.2, 3.2, 0.2), cf * CFrame.new(1.1, 2.2, 0.3) * CFrame.Angles(0, 0, math.rad(15)), Color3.fromRGB(110, 75, 45), Enum.Material.Wood, vModel, false)

		cframePart(spec.id .. "_PickHead", Vector3.new(0.4, 0.4, 1.8), cf * CFrame.new(1.3, 3.6, 0.3), Color3.fromRGB(130, 135, 145), Enum.Material.Metal, vModel, false)

	elseif spec.accessory == "BardLute" then

		cframePart(spec.id .. "_LuteBody", Vector3.new(1.1, 1.4, 0.5), cf * CFrame.new(0, 2.7, -0.6) * CFrame.Angles(math.rad(25), 0, math.rad(-15)), Color3.fromRGB(180, 110, 50), Enum.Material.Wood, vModel, false, Enum.PartType.Ball)

		cframePart(spec.id .. "_LuteNeck", Vector3.new(0.25, 2.2, 0.25), cf * CFrame.new(-0.4, 3.7, -0.6) * CFrame.Angles(0, 0, math.rad(-25)), Color3.fromRGB(120, 75, 35), Enum.Material.Wood, vModel, false)

	end



	-- Attributes for Quests and Interaction

	vModel:SetAttribute("VillagerId", spec.id)

	vModel:SetAttribute("VillagerName", spec.displayName)

	vModel:SetAttribute("Role", spec.role)

	vModel:SetAttribute("District", spec.district)

	vModel:SetAttribute("Dialogue", spec.dialogue)



	-- Overhead BillboardGui

	local bb = Instance.new("BillboardGui")

	bb.Name = "NameTag"

	bb.Size = UDim2.fromOffset(170, 42)

	bb.StudsOffset = Vector3.new(0, 3.4, 0)

	bb.MaxDistance = 35

	bb.AlwaysOnTop = false

	bb.Parent = torso



	local nameLabel = Instance.new("TextLabel")

	nameLabel.Size = UDim2.fromScale(1, 0.55)

	nameLabel.BackgroundTransparency = 1

	nameLabel.Font = Enum.Font.GothamBold

	nameLabel.Text = spec.displayName

	nameLabel.TextColor3 = Color3.fromRGB(255, 230, 160)

	nameLabel.TextStrokeTransparency = 0.25

	nameLabel.TextScaled = true

	nameLabel.Parent = bb



	local roleLabel = Instance.new("TextLabel")

	roleLabel.Position = UDim2.fromScale(0, 0.55)

	roleLabel.Size = UDim2.fromScale(1, 0.45)

	roleLabel.BackgroundTransparency = 1

	roleLabel.Font = Enum.Font.GothamMedium

	roleLabel.Text = "<" .. spec.role .. ">"

	roleLabel.TextColor3 = spec.roleColor or Color3.fromRGB(175, 230, 255)

	roleLabel.TextStrokeTransparency = 0.3

	roleLabel.TextScaled = true

	roleLabel.Parent = bb



	-- ProximityPrompt for Dialogue Interaction

	local prompt = Instance.new("ProximityPrompt")

	prompt.ActionText = "พูดคุย"

	prompt.ObjectText = spec.displayName

	prompt.KeyboardKeyCode = Enum.KeyCode.F

	prompt.HoldDuration = 0

	prompt.MaxActivationDistance = 12

	prompt.RequiresLineOfSight = false

	prompt.Parent = torso



	prompt.Triggered:Connect(function(player)

		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")

		local sf = remotes and remotes:FindFirstChild("SkillFeedback")

		if sf then

			sf:FireClient(player, string.format("💬 [%s]: %s", spec.displayName, spec.dialogue))

		end

	end)



	return vModel

end



local VILLAGERS_ROSTER = {

	{

		id = "VIL_FLOWER_GIRL_LILY",

		displayName = "น้องลิลลี่ (Lily)",

		role = "แม่ค้าดอกไม้สด",

		district = "จัตุรัสน้ำพุ / หน้าร้านขายยา",

		dialogue = "ดอกไม้สดๆ จากทุ่ง Poring ค่ะพี่ชาย! อยากได้ดอกไม้หอมๆ สักช่อไหมคะ?",

		pos = Vector3.new(25, 0, 24), yaw = -math.pi * 0.25,

		coatColor = Color3.fromRGB(240, 140, 175), hairColor = Color3.fromRGB(235, 195, 105),

		accessory = "FlowerBasket",

	},

	{

		id = "VIL_OLD_GUARD_VARUS",

		displayName = "นายสิบวารัส (Guard Varus)",

		role = "ทหารยามเฝ้าประตูเมือง",

		district = "ประตูเมืองตะวันออก East Gate",

		dialogue = "ระวังตัวด้วยนะนักผจญภัย นอกประตูไปทางตะวันออกมีทั้ง Poring และหมาป่า Wolf อย่าไปลึกเกินตัวล่ะ!",

		pos = Vector3.new(58, 0, 8), yaw = -math.pi * 0.5,

		coatColor = Color3.fromRGB(75, 90, 115), hatType = "GuardHelmet",

		accessory = "GuardSpear",

	},

	{

		id = "VIL_BAKER_HANS",

		displayName = "เชฟฮันส์ (Baker Hans)",

		role = "คนทำขนมปังประจำเมือง",

		district = "แผงขนมปัง จัตุรัสน้ำพุ",

		dialogue = "ขนมปังบาแก็ตต์อบสดใหม่จากเตาร้อนๆ ครับ! กรอบนอกนุ่มใน หอมกรุ่นทั้งจัตุรัส!",

		pos = Vector3.new(-18, 0, 18), yaw = math.pi * 0.35,

		coatColor = Color3.fromRGB(235, 235, 240), hatType = "ChefHat",

	},

	{

		id = "VIL_FISHERMAN_BARNABY",

		displayName = "ลุงบาร์นาบี้ (Barnaby)",

		role = "ชาวประมงเฒ่า",

		district = "ท่าเทียบเรือ Prontera Harbor",

		dialogue = "ลมทะเลวันนี้พัดแรงดีแท้! เรือที่จะไปเกาะ Amatsu กำลังตระเตรียมเสบียงอยู่ไอ้หนุ่ม",

		pos = Vector3.new(-64, 0, 246), yaw = 0,

		coatColor = Color3.fromRGB(65, 110, 145), hatType = "StrawHat",

	},

	{

		id = "VIL_SCHOLAR_ERASMUS",

		displayName = "นักปราชญ์เอราสมุส (Erasmus)",

		role = "ผู้บันทึกประวัติศาสตร์",

		district = "ทางเดินหินข้างมหาวิหาร",

		dialogue = "สุสานโบราณทิศตะวันออกมีอายุหลายร้อยปี... ว่ากันว่ามีทางลับเชื่อมไปยังดันเจี้ยนใต้ดินด้วยนะ",

		pos = Vector3.new(-44, 0, -65), yaw = math.pi * 0.75,

		coatColor = Color3.fromRGB(115, 65, 140), hairColor = Color3.fromRGB(210, 210, 220),

	},

	{

		id = "VIL_NUN_CECILIA",

		displayName = "ซิสเตอร์เซซิเลีย (Sister Cecilia)",

		role = "นักบวชหญิงแห่งวิหาร",

		district = "หน้าซุ้มประตูมหาวิหาร",

		dialogue = "ขอพรอันบริสุทธิ์จากเทพีคุ้มครองท่านในการเดินทาง อย่าลืมแวะสวดภาวนาในวิหารนะคะ",

		pos = Vector3.new(-58, 0, -42), yaw = 0,

		coatColor = Color3.fromRGB(45, 45, 55), hatType = "NunVeil",

	},

	{

		id = "VIL_MINER_BALIN",

		displayName = "บาลิน (Miner Balin)",

		role = "ช่างเหมืองเหล็ก",

		district = "หน้าโรงตีเหล็ก",

		dialogue = "แร่เหล็ก Iron Ore ช่วงนี้หายากเหลือเกิน ถ้าเจอนอกเมืองนำมาขายให้ตาเฒ่า Hollgrehenn ได้ราคางามเชียว!",

		pos = Vector3.new(-25, 0, -24), yaw = math.pi * 0.85,

		coatColor = Color3.fromRGB(135, 95, 60), hairColor = Color3.fromRGB(75, 55, 45),

		accessory = "MiningPick",

	},

	{

		id = "VIL_TRAVELER_LUNA",

		displayName = "ลูน่า (Traveler Luna)",

		role = "นักเดินทางต่างแดน",

		district = "หน้าโรงเตี๊ยม Prontera Inn",

		dialogue = "ฉันเพิ่งเดินทางมาจากทะเลทราย Morroc แดดที่นั่นร้อนระอุมาก เมือง Prontera นี่ร่มรื่นน่าอยู่กว่าเยอะเลย!",

		pos = Vector3.new(28, 0, 76), yaw = -math.pi * 0.5,

		coatColor = Color3.fromRGB(195, 125, 65), hairColor = Color3.fromRGB(60, 45, 75),

	},

	{

		id = "VIL_FARMER_BOB",

		displayName = "ลุงบ็อบ (Farmer Bob)",

		role = "ชาวสวนแครอท",

		district = "ทุ่งแครอท Lunatic Farm (โซน 2)",

		dialogue = "เฮ้อ! เจ้ากระต่าย Lunatic พวกนี้ชอบมากัดแทะแครอทของฉันเรื่อยเลย ใครช่วยไล่ไปทีนะ!",

		pos = Vector3.new(165, 0, -34), yaw = math.pi * 0.5,

		coatColor = Color3.fromRGB(85, 125, 70), hatType = "StrawHat",

	},

	{

		id = "VIL_HUNTER_ROBIN",

		displayName = "นายพรานโรบิน (Robin)",

		role = "นายพรานแกะรอย",

		district = "แคมป์ไฟป่าสน Wolf (โซน 3)",

		dialogue = "หมาป่าพวกนี้ดุร้ายและล่าเป็นฝูง ถ้าฝีมือยังไม่ถึง Lv.5 อย่าริอาจเดินออกนอกถนนเชียวล่ะ!",

		pos = Vector3.new(218, 0, -26), yaw = math.pi * 0.4,

		coatColor = Color3.fromRGB(70, 85, 65), hairColor = Color3.fromRGB(145, 90, 45),

	},

	{

		id = "VIL_ADVENTURER_KID_TIMMY",

		displayName = "น้องทิมมี่ (Timmy)",

		role = "เด็กฝึกหัดใฝ่ฝันเป็นอัศวิน",

		district = "ลานฝึกซ้อมหุ่นฟางหลวง",

		dialogue = "โตขึ้นผมจะเป็นหัวหน้าอัศวินแห่ง Prontera ให้ได้เลยครับ! ดูดาบไม้ของผมสิ ฟึ่บๆ!",

		pos = Vector3.new(30, 0, -92), yaw = -math.pi * 0.25,

		coatColor = Color3.fromRGB(180, 50, 45), hairColor = Color3.fromRGB(225, 180, 85),

	},

	{

		id = "VIL_MERCHANT_GRETA",

		displayName = "เกรต้า (Merchant Greta)",

		role = "แม่ค้าผลไม้",

		district = "แผงผลไม้ จัตุรัสน้ำพุ",

		dialogue = "แอปเปิลสีแดงฉ่ำๆ หวานกรอบ รับประทานแล้วเพิ่มพลังกายทันตาเห็นเลยจ้า!",

		pos = Vector3.new(18, 0, -18), yaw = -math.pi * 0.6,

		coatColor = Color3.fromRGB(215, 75, 65), hairColor = Color3.fromRGB(110, 60, 40),

	},

	{

		id = "VIL_BARD_ALISTAIR",

		displayName = "กวีอลิสแตร์ (Alistair)",

		role = "กวีพเนจร",

		district = "ริมขอบสระน้ำพุกลางเมือง",

		dialogue = "♪ ยินดีต้อนรับสู่นคร Prontera ดินแดนแห่งเกียรติยศและมิตรภาพ... ♪ อยากฟังบทกวีสักบทไหม?",

		pos = Vector3.new(8, 0, 8), yaw = -math.pi * 0.75,

		coatColor = Color3.fromRGB(65, 145, 135), hairColor = Color3.fromRGB(205, 140, 75),

		accessory = "BardLute",

	},

	{

		id = "VIL_LUMBERJACK_SVEN",

		displayName = "สเวน (Lumberjack Sven)",

		role = "คนตัดฟืนแห่งป่าตะวันตก",

		district = "ชายป่าถนนตะวันตก",

		dialogue = "ฟืนสำหรับโรงเตี๊ยมและเตาหลอมของช่างตีเหล็กต้องใช้ฟืนไม้โอ๊คแห้งสนิทเท่านั้นนะไอ้หนุ่ม",

		pos = Vector3.new(-140, 0, -30), yaw = math.pi * 0.35,

		coatColor = Color3.fromRGB(145, 80, 55), hairColor = Color3.fromRGB(85, 55, 40),

	},

	{

		id = "VIL_CAT_LOVER_MIA",

		displayName = "มีอา (Mia)",

		role = "สาวน้อยรักแมว",

		district = "ย่านพักอาศัย Residential",

		dialogue = "เหมียวๆ~ เจ้าพุดดิ้งแมวส้มตัวอ้วนของฉันแอบหนีไปวิ่งเล่นแถวไหนอีกแล้วนะ...",

		pos = Vector3.new(-115, 0, 52), yaw = -math.pi * 0.45,

		coatColor = Color3.fromRGB(225, 175, 135), hairColor = Color3.fromRGB(240, 205, 120),

	},

}



for _, spec in ipairs(VILLAGERS_ROSTER) do

	buildVillager(spec)

end



-- ============================================================

-- 17. ของตกแต่งเสริมความสวยงามของเมืองและทางเดิน (Town Environment Props)

--     ม้านั่งไม้ยาว, กระถางต้นไม้ดอกไม้, ป้ายบอกทาง, ลานเบียร์โรงเตี๊ยม, ธงกิลด์อัศวิน, บ่อน้ำโบราณ

-- ============================================================

local envFolder = Instance.new("Folder")

envFolder.Name = "TownEnvironmentProps"

envFolder.Parent = root



-- (A) ป้ายบอกทาง 4 ทิศ (Prontera Directional Signposts) บริเวณสี่แยกกลางเมือง

local function buildGuideSignpost(pos)

	part("SignpostPole", Vector3.new(0.65, 9.5, 0.65), pos + Vector3.new(0, 4.75, 0), PALETTE.timberDark, Enum.Material.Wood, nil, envFolder)

	part("SignpostFinial", Vector3.new(1.1, 1.1, 1.1), pos + Vector3.new(0, 9.8, 0), PALETTE.goldTrim, Enum.Material.SmoothPlastic, Enum.PartType.Ball, envFolder, false)



	local arms = {

		{ text = "จัตุรัสกลางเมือง / ตลาด\n← PLAZA & MARKET", y = 8.5, angle = 0, col = Color3.fromRGB(255, 230, 160) },

		{ text = "มหาวิหาร / ลานประลอง\n↑ CATHEDRAL & ARENA", y = 7.4, angle = 90, col = Color3.fromRGB(180, 230, 255) },

		{ text = "ประตูตะวันออก (ทุ่งล่ามอน)\n→ EAST GATE (HUNTING)", y = 6.3, angle = 180, col = Color3.fromRGB(255, 200, 160) },

		{ text = "ท่าเรือ / โรงเตี๊ยม\n↓ HARBOR & TAVERN", y = 5.2, angle = 270, col = Color3.fromRGB(210, 255, 180) },

	}



	for _, arm in ipairs(arms) do

		local rad = math.rad(arm.angle)

		local armCF = CFrame.new(pos + Vector3.new(0, arm.y, 0)) * CFrame.Angles(0, rad, 0)

		local plank = cframePart("GuideSignPlank", Vector3.new(4.8, 0.9, 0.25), armCF * CFrame.new(2.4, 0, 0), PALETTE.timberMed, Enum.Material.WoodPlanks, envFolder, false)



		for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do

			local sg = Instance.new("SurfaceGui")

			sg.Face = face

			sg.CanvasSize = Vector2.new(320, 70)

			sg.Parent = plank

			local tl = Instance.new("TextLabel")

			tl.Size = UDim2.fromScale(1, 1)

			tl.BackgroundTransparency = 1

			tl.Font = Enum.Font.GothamBold

			tl.TextScaled = true

			tl.TextColor3 = arm.col

			tl.TextStrokeTransparency = 0.2

			tl.Text = arm.text

			tl.Parent = sg

		end

	end

end



buildGuideSignpost(Vector3.new(20, 0, 18))

buildGuideSignpost(Vector3.new(-18, 0, -6))



-- (B) ม้านั่งไม้ยาวและกระถางดอกไม้ตามแนวทางเดินถนนหลัก

local benchLocations = {

	{ pos = Vector3.new( 11.5, 0, -55), yaw = -math.pi * 0.5 },

	{ pos = Vector3.new(-11.5, 0, -55), yaw =  math.pi * 0.5 },

	{ pos = Vector3.new( 11.5, 0,  55), yaw = -math.pi * 0.5 },

	{ pos = Vector3.new(-11.5, 0,  55), yaw =  math.pi * 0.5 },

	{ pos = Vector3.new(-75,   0,  11.5), yaw = 0 },

	{ pos = Vector3.new(-75,   0, -11.5), yaw = math.pi },

	{ pos = Vector3.new(-145,  0,  11.5), yaw = 0 },

	{ pos = Vector3.new(-145,  0, -11.5), yaw = math.pi },

}



for i, bl in ipairs(benchLocations) do

	local bCF = CFrame.new(bl.pos) * CFrame.Angles(0, bl.yaw, 0)

	cframePart("StreetBenchSeat_" .. i, Vector3.new(5.2, 0.35, 1.6), bCF * CFrame.new(0, 1.1, 0), PALETTE.timberMed, Enum.Material.WoodPlanks, envFolder, true)

	cframePart("StreetBenchBack_" .. i, Vector3.new(5.2, 1.4, 0.3), bCF * CFrame.new(0, 1.8, -0.65), PALETTE.timberMed, Enum.Material.WoodPlanks, envFolder, true)

	cframePart("StreetBenchLegL_" .. i, Vector3.new(0.5, 1.0, 1.5), bCF * CFrame.new(-2.2, 0.5, 0), PALETTE.stoneDark, Enum.Material.Metal, envFolder, true)

	cframePart("StreetBenchLegR_" .. i, Vector3.new(0.5, 1.0, 1.5), bCF * CFrame.new( 2.2, 0.5, 0), PALETTE.stoneDark, Enum.Material.Metal, envFolder, true)



	-- กระถางดอกไม้ข้างม้านั่ง

	cframePart("StreetPlanter_" .. i, Vector3.new(2.0, 1.4, 2.0), bCF * CFrame.new(3.8, 0.7, 0), PALETTE.stoneWall, Enum.Material.Cobblestone, envFolder, true)

	cframePart("StreetFlowers_" .. i, Vector3.new(1.8, 1.2, 1.8), bCF * CFrame.new(3.8, 1.8, 0), Color3.fromRGB(110, 185, 80), Enum.Material.Grass, envFolder, false, Enum.PartType.Ball)

	local blossomCols = { Color3.fromRGB(255, 120, 140), Color3.fromRGB(255, 215, 60), Color3.fromRGB(120, 190, 255) }

	for bi = 1, 3 do

		cframePart("BlossomDot_" .. i .. "_" .. bi, Vector3.new(0.5, 0.5, 0.5), bCF * CFrame.new(3.8 + (bi - 2) * 0.45, 2.3, (bi % 2 == 0 and 0.3 or -0.3)), blossomCols[bi], Enum.Material.SmoothPlastic, envFolder, false, Enum.PartType.Ball)

	end

end



-- (C) ลานเบียร์และโต๊ะอาหารหน้าโรงเตี๊ยม Prontera Inn (X=36, Z=72)

do

	local innTblPos = Vector3.new(38, 0, 68)

	cframePart("InnPicticTable", Vector3.new(6.5, 2.2, 3.2), CFrame.new(innTblPos + Vector3.new(0, 1.1, 0)), PALETTE.timberMed, Enum.Material.WoodPlanks, envFolder, true)

	for _, tz in ipairs({-2.6, 2.6}) do

		cframePart("InnPicticBench", Vector3.new(6.5, 1.1, 1.2), CFrame.new(innTblPos + Vector3.new(0, 0.55, tz)), PALETTE.timberDark, Enum.Material.Wood, envFolder, true)

	end

	for mx = -1.8, 1.8, 1.8 do

		cframePart("AleMug_" .. mx, Vector3.new(0.85, 0.65, 0.65), CFrame.new(innTblPos + Vector3.new(mx, 2.65, 0)) * CFrame.Angles(0, 0, math.rad(90)), PALETTE.timberDark, Enum.Material.Wood, envFolder, false, Enum.PartType.Cylinder)

		cframePart("AleFoam_" .. mx, Vector3.new(0.25, 0.6, 0.6), CFrame.new(innTblPos + Vector3.new(mx, 3.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(250, 245, 230), Enum.Material.SmoothPlastic, envFolder, false, Enum.PartType.Cylinder)

	end

end



-- (D) ลานหน้ากิลด์อัศวิน Prontera Knight Guild (X=-32, Z=82)

do

	local guildFront = Vector3.new(-38, 0, 68)

	cframePart("KnightSpearRackL", Vector3.new(0.4, 5.2, 0.4), CFrame.new(guildFront + Vector3.new(-2.2, 2.6, 0)), PALETTE.timberDark, Enum.Material.Wood, envFolder, true)

	cframePart("KnightSpearRackR", Vector3.new(0.4, 5.2, 0.4), CFrame.new(guildFront + Vector3.new( 2.2, 2.6, 0)), PALETTE.timberDark, Enum.Material.Wood, envFolder, true)

	cframePart("KnightSpearCrossbar", Vector3.new(4.8, 0.35, 0.35), CFrame.new(guildFront + Vector3.new(0, 4.2, 0)), PALETTE.timberDark, Enum.Material.Wood, envFolder, true)

	for sx = -1.4, 1.4, 1.4 do

		cframePart("StandSpear_" .. sx, Vector3.new(0.18, 7.8, 0.18), CFrame.new(guildFront + Vector3.new(sx, 3.9, 0)), Color3.fromRGB(85, 65, 45), Enum.Material.Wood, envFolder, false)

		cframePart("StandSpearTip_" .. sx, Vector3.new(0.3, 1.5, 0.5), CFrame.new(guildFront + Vector3.new(sx, 8.2, 0)), Color3.fromRGB(215, 220, 230), Enum.Material.Metal, envFolder, false)

	end



	cframePart("GuildBannerPole", Vector3.new(0.4, 14, 0.4), CFrame.new(guildFront + Vector3.new(3.8, 7, -1)), PALETTE.timberDark, Enum.Material.Wood, envFolder, true)

	cframePart("GuildBannerFabric", Vector3.new(0.12, 6.5, 3.2), CFrame.new(guildFront + Vector3.new(3.8, 10.5, 0.8)), Color3.fromRGB(45, 85, 165), Enum.Material.Fabric, envFolder, false)

	cframePart("GuildBannerGoldTrim", Vector3.new(0.15, 0.45, 3.3), CFrame.new(guildFront + Vector3.new(3.8, 7.1, 0.8)), PALETTE.goldTrim, Enum.Material.SmoothPlastic, envFolder, false)

end



-- (E) บ่อน้ำหินโบราณและราวตากผ้าย่านพักอาศัย (Residential District @ X = -140, Z = 50)

do

	local wellPos = Vector3.new(-140, 0, 50)

	-- บ่อน้ำทรงกระบอกแนวตั้ง (X = สูง, Y/Z = เส้นผ่านศูนย์กลาง หมุน Z 90 องศา)

	cframePart("StoneWellBase", Vector3.new(2.6, 6.2, 6.2), CFrame.new(wellPos + Vector3.new(0, 1.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), PALETTE.stoneDark, Enum.Material.Cobblestone, envFolder, true, Enum.PartType.Cylinder)

	cframePart("StoneWellWater", Vector3.new(0.3, 5.0, 5.0), CFrame.new(wellPos + Vector3.new(0, 2.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(65, 145, 195), Enum.Material.Glass, envFolder, false, Enum.PartType.Cylinder)

	for _, wx in ipairs({-2.6, 2.6}) do

		cframePart("WellRoofPost", Vector3.new(0.45, 6.5, 0.45), CFrame.new(wellPos + Vector3.new(wx, 4.5, 0)), PALETTE.timberDark, Enum.Material.Wood, envFolder, false)

	end

	cframePart("WellRoofRidge", Vector3.new(6.4, 0.45, 0.45), CFrame.new(wellPos + Vector3.new(0, 7.8, 0)), PALETTE.timberDark, Enum.Material.Wood, envFolder, false)

	cframePart("WellRoofCanopyL", Vector3.new(6.4, 0.3, 2.6), CFrame.new(wellPos + Vector3.new(0, 7.2, -1.1)) * CFrame.Angles(math.rad(-28), 0, 0), PALETTE.roofRed, Enum.Material.WoodPlanks, envFolder, false)

	cframePart("WellRoofCanopyR", Vector3.new(6.4, 0.3, 2.6), CFrame.new(wellPos + Vector3.new(0, 7.2,  1.1)) * CFrame.Angles(math.rad(28), 0, 0), PALETTE.roofRed, Enum.Material.WoodPlanks, envFolder, false)

	cframePart("WellBucket", Vector3.new(1.2, 1.1, 1.1), CFrame.new(wellPos + Vector3.new(1.8, 2.8, -1.8)) * CFrame.Angles(0, 0, math.rad(90)), PALETTE.timberMed, Enum.Material.Wood, envFolder, false, Enum.PartType.Cylinder)



	local linePos = Vector3.new(-155, 0, 60)

	cframePart("ClothesPostL", Vector3.new(0.35, 7.5, 0.35), CFrame.new(linePos + Vector3.new(-6, 3.75, 0)), PALETTE.timberDark, Enum.Material.Wood, envFolder, false)

	cframePart("ClothesPostR", Vector3.new(0.35, 7.5, 0.35), CFrame.new(linePos + Vector3.new( 6, 3.75, 0)), PALETTE.timberDark, Enum.Material.Wood, envFolder, false)

	cframePart("ClothesRope", Vector3.new(12, 0.08, 0.08), CFrame.new(linePos + Vector3.new(0, 6.8, 0)), PALETTE.timberDark, Enum.Material.Fabric, envFolder, false)

	local shirtCols = { Color3.fromRGB(240, 240, 245), Color3.fromRGB(65, 135, 215), Color3.fromRGB(235, 115, 65), Color3.fromRGB(120, 195, 95) }

	for si, scol in ipairs(shirtCols) do

		local sx = -4.5 + (si - 1) * 3.0

		cframePart("HangingShirt_" .. si, Vector3.new(1.8, 2.2, 0.1), CFrame.new(linePos + Vector3.new(sx, 5.5, 0)) * CFrame.Angles(0, math.rad(si * 8), 0), scol, Enum.Material.Fabric, envFolder, false)

	end



	for fx = -1, 1 do

		for fy = 0, 2 do

			cframePart("Firewood_" .. fx .. "_" .. fy, Vector3.new(3.2, 0.5, 0.5), CFrame.new(linePos + Vector3.new(-10 + fx * 0.3, 0.35 + fy * 0.52, -8)), PALETTE.timberDark, Enum.Material.Wood, envFolder, false, Enum.PartType.Cylinder)

		end

	end

end



print("[StarterMap] เมือง Prontera โฉมใหม่: วงเวียนสมมาตรกลางสี่แยก (0,0,0) + เปิดทางเข้าท่าเรือ & บ้านคนเรือ + ยกระดับหุบเขาล่ามอนสเตอร์ 3D RPG ครบถ้วน")

