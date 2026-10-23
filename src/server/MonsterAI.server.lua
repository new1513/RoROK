-- ============================================================

-- MonsterAI.server.lua

-- Server-authoritative monster spawner, clean 3D monster

-- builder, and AI for RoROK (Ragnarok M inspired).

-- ============================================================

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Workspace = game:GetService("Workspace")

local TweenService = game:GetService("TweenService")

local gameData = ReplicatedStorage:WaitForChild("GameData")

local monsters = require(gameData:WaitForChild("MonsterData"))

-- Clear any old duplicate monsters on reload so models never overlap

local folder = Workspace:FindFirstChild("Monsters")

if folder then

	for _, m in ipairs(folder:GetChildren()) do

		if not string.find(m.Name, "^TrainingDummy") then

			m:Destroy()

		end

	end

else

	folder = Instance.new("Folder")

	folder.Name = "Monsters"

	folder.Parent = Workspace

end

-- ── Tunables ────────────────────────────────────────────────

local MONSTER_SIGHT_RANGE = 50

local AI_TICK = 0.1

local DEFAULT_MOVE_SPEED = 6

local LEASH_RANGE = 40

local GIVE_UP_DISTANCE = 60

local RETURN_SPEED_MULT = 2

local FIRST_STRIKE_DELAY = 0.6

local ARRIVE_DISTANCE = 1.5

local STOP_FRACTION = 0.8

local SAFE_MIN_X, SAFE_MAX_X, SAFE_MIN_Z, SAFE_MAX_Z = -350, 62, -320, 320

local function canMonsterSeeCharacter(monster, monsterRoot, character, playerRoot)

	local offset = playerRoot.Position - monsterRoot.Position

	if offset.Magnitude > MONSTER_SIGHT_RANGE then return false end

	local params = RaycastParams.new()

	params.FilterType = Enum.RaycastFilterType.Exclude

	params.FilterDescendantsInstances = {monster}

	local origin = monsterRoot.Position + Vector3.new(0, 0.5, 0)

	local destination = playerRoot.Position + Vector3.new(0, 1, 0)

	local hit = Workspace:Raycast(origin, destination - origin, params)

	return not hit or hit.Instance:IsDescendantOf(character)

end

if not Workspace:FindFirstChild("RoROK_TestGround") and not Workspace:FindFirstChild("Baseplate") then

	local ground = Instance.new("Part")

	ground.Name = "RoROK_TestGround"

	ground.Size = Vector3.new(420, 1, 280)

	ground.Position = Vector3.new(220, -0.5, 0)

	ground.Anchored = true

	ground.Material = Enum.Material.Grass

	ground.Color = Color3.fromRGB(91, 145, 72)

	ground.Parent = Workspace

end

local function inSafeZone(position)

	if position.X > SAFE_MIN_X and position.X < SAFE_MAX_X and position.Z > SAFE_MIN_Z and position.Z < SAFE_MAX_Z then

		return true

	end

	if position.X > -24 and position.X < 24 and position.Z > -642 and position.Z < -608 then

		return true

	end

	if position.X > 905 and position.X < 995 and position.Z > -48 and position.Z < 24 then

		return true

	end

	if position.X > -995 and position.X < -905 and position.Z > -48 and position.Z < 24 then

		return true

	end

	return false

end

local function pushOutOfSafeZone(position)

	if not inSafeZone(position) then return position end

	local toMinX, toMaxX = position.X - SAFE_MIN_X, SAFE_MAX_X - position.X

	local toMinZ, toMaxZ = position.Z - SAFE_MIN_Z, SAFE_MAX_Z - position.Z

	local nearest = math.min(toMinX, toMaxX, toMinZ, toMaxZ)

	if nearest == toMaxX then return Vector3.new(SAFE_MAX_X, position.Y, position.Z) end

	if nearest == toMinX then return Vector3.new(SAFE_MIN_X, position.Y, position.Z) end

	if nearest == toMaxZ then return Vector3.new(position.X, position.Y, SAFE_MAX_Z) end

	return Vector3.new(position.X, position.Y, SAFE_MIN_Z)

end

local function flatDistance(a, b)

	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude

end

local function setMonsterHP(monster, hp)

	monster:SetAttribute("HP", hp)

	local fill = monster:FindFirstChild("HPFill", true)

	if fill then

		local maxHP = monster:GetAttribute("MaxHP") or 1

		fill.Size = UDim2.fromScale(math.clamp(hp / maxHP, 0, 1), 1)

	end

end

-- ============================================================

-- CLEAN 3D MONSTER MODEL BUILDER

-- Uses SurfaceGui faces (never clipping!) + clean welded silhouette

-- ============================================================

local ServerStorage = game:GetService("ServerStorage")

local TEMPLATE_MAP = {

	Poring        = "Poring",

	Fabre         = "Poring",

	Lunatic       = "Lunatic",

	Goblin        = "Lunatic",

	Wolf          = "Wolf",

	Spider        = "Wolf",

	ThiefBug      = "Poring",

	PoisonSnake   = "Poring",

	GoblinRaider  = "Skeleton",

	Scorpion      = "Wolf",

	Merman        = "Skeleton",

	Eddga         = "Wolf",

	Zombie        = "Zombie",

	Mummy         = "Zombie",

	Sohee         = "Zombie",

	Skeleton      = "Skeleton",

	Drake         = "Skeleton",

	Minorous      = "Skeleton",

	SandMan       = "Zombie",

	Swordfish     = "Wolf",

	Tengu         = "Skeleton",

	TurtleGeneral = "Skeleton",

}

local FALLBACK_MESHES = {

	Poring   = { meshId = "rbxassetid://2365740410", texId = "", scale = Vector3.new(2.8, 2.5, 2.8) },

	Lunatic  = { meshId = "rbxassetid://6943570754", texId = "", scale = Vector3.new(2.5, 2.7, 2.5) },

	Wolf     = { meshId = "rbxassetid://1808874182", texId = "rbxassetid://1808874283", scale = Vector3.new(1.5, 3.4, 5.5) },

	Zombie   = { meshId = "", texId = "", scale = Vector3.new(1, 1, 1) },

	Skeleton = { meshId = "", texId = "", scale = Vector3.new(1, 1, 1) },

}

local function buildMonsterVisualFromTemplate(id, def, scale, position)

	local templatesFolder = ServerStorage:FindFirstChild("RoROK_MonsterTemplates")

	local tplName = TEMPLATE_MAP[id] or "Poring"

	local tpl = templatesFolder and templatesFolder:FindFirstChild(tplName)

	local model

	local core

	if tpl then

		model = tpl:Clone()

		if math.abs(scale - 1) > 0.05 then

			model:ScaleTo(scale)

		end

		core = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart

		-- Tint variants (e.g., Mummy, Eddga, Drake, ThiefBug, Scorpion) so each monster type has its distinct theme color

		if id ~= tplName then

			for _, p in ipairs(model:GetDescendants()) do

				if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then

					p.Color = def.Color

				end

			end

		end

		local _, bboxSize = model:GetBoundingBox()

		model:PivotTo(CFrame.new(position.X, position.Y + bboxSize.Y * 0.5, position.Z))

	else

		model = Instance.new("Model")

		local radius = 3 * scale

		core = Instance.new("Part")

		core.Name = "HumanoidRootPart"

		core.Size = Vector3.new(radius, radius, radius)

		core.Color = def.Color

		core.Material = Enum.Material.SmoothPlastic

		core.Anchored = true

		core.CanCollide = true

		core.Position = position + Vector3.new(0, radius * 0.55, 0)

		core.Parent = model

		model.PrimaryPart = core

		local fb = FALLBACK_MESHES[tplName]

		if fb and fb.meshId ~= "" then

			local sm = Instance.new("SpecialMesh")

			sm.MeshType = Enum.MeshType.FileMesh

			sm.MeshId = fb.meshId

			sm.TextureId = fb.texId

			sm.Scale = fb.scale * scale

			sm.Parent = core

		end

	end

	if def.IsBoss and core then

		local aura = Instance.new("Part")

		aura.Name = "BossAuraRing"

		aura.Shape = Enum.PartType.Cylinder

		aura.Size = Vector3.new(0.2, 5.2 * scale, 5.2 * scale)

		aura.Color = def.IsWorldBoss and Color3.fromRGB(255, 85, 45) or Color3.fromRGB(255, 210, 65)

		aura.Material = Enum.Material.Neon

		aura.Transparency = 0.35

		aura.Anchored = true

		aura.CanCollide = false

		aura.CFrame = CFrame.new(position.X, position.Y + 0.15, position.Z) * CFrame.Angles(0, 0, math.rad(90))

		aura.Parent = model

		local light = Instance.new("PointLight")

		light.Color = aura.Color

		light.Range = def.IsWorldBoss and 22 or 14

		light.Brightness = 1.6

		light.Parent = core

	end

	return model, core

end

local function makeMonster(id, position, mapName)

	local def = monsters[id]

	if not def then return nil end

	local scale = tonumber(def.Scale) or 1

	local radius = 3 * scale

	local model, core = buildMonsterVisualFromTemplate(id, def, scale, position)

	model.Name = id .. "_" .. tostring(math.random(10000, 99999))

	model:SetAttribute("MonsterID", id)

	model:SetAttribute("Level", def.Level)

	model:SetAttribute("HP", def.MaxHP)

	model:SetAttribute("MaxHP", def.MaxHP)

	model:SetAttribute("ATK", def.ATK)

	model:SetAttribute("DEF", def.DEF)

	model:SetAttribute("MDEF", def.MDEF)

	model:SetAttribute("HIT", def.HIT)

	model:SetAttribute("FLEE", def.FLEE)

	model:SetAttribute("PerfectDodge", def.PerfectDodge)

	model:SetAttribute("Element", def.Element)
	model:SetAttribute("Size", def.Size or "Medium")

	model:SetAttribute("XP_Reward", def.XP)

	model:SetAttribute("JobXP_Reward", def.JobXP)

	model:SetAttribute("RespawnTime", def.RespawnTime)

	model:SetAttribute("MapName", mapName)

	model:SetAttribute("SpawnPosition", position)

	model:SetAttribute("SpawnPos", tostring(position))

	model:SetAttribute("AggroRange", def.AggroRange)

	model:SetAttribute("AttackRange", def.AttackRange)

	model:SetAttribute("AttackCooldown", def.AttackCooldown)

	model:SetAttribute("MoveSpeed", def.MoveSpeed or DEFAULT_MOVE_SPEED)

	model:SetAttribute("IsBoss", def.IsBoss == true)

	model:SetAttribute("IsWorldBoss", def.IsWorldBoss == true)

	model.PrimaryPart = core

	local _, extSize = model:GetBoundingBox()

	local billboard = Instance.new("BillboardGui")

	billboard.Name = "MonsterBillboard"

	billboard.Size = def.IsBoss and UDim2.fromOffset(185, 40) or UDim2.fromOffset(120, 30)

	billboard.StudsOffset = Vector3.new(0, extSize.Y * 0.55 + 1.6, 0)

	billboard.MaxDistance = def.IsBoss and 80 or 45

	billboard.AlwaysOnTop = false

	billboard.Parent = core

	local hpBar = Instance.new("Frame")

	hpBar.Name = "HPBar"

	hpBar.Size = UDim2.new(1, 0, 0, 10)

	hpBar.Position = UDim2.new(0, 0, 0, 17)

	hpBar.BackgroundColor3 = Color3.fromRGB(45, 18, 22)

	hpBar.BorderSizePixel = 0

	hpBar.Parent = billboard

	local hpCorner = Instance.new("UICorner")

	hpCorner.CornerRadius = UDim.new(1, 0)

	hpCorner.Parent = hpBar

	local fill = Instance.new("Frame")

	fill.Name = "HPFill"

	fill.Size = UDim2.fromScale(1, 1)

	fill.BackgroundColor3 = def.IsBoss and Color3.fromRGB(245, 185, 55) or Color3.fromRGB(70, 220, 90)

	fill.BorderSizePixel = 0

	fill.Parent = hpBar

	local fillCorner = Instance.new("UICorner")

	fillCorner.CornerRadius = UDim.new(1, 0)

	fillCorner.Parent = fill

	local label = Instance.new("TextLabel")

	label.Size = UDim2.new(1, 0, 0, 15)

	label.BackgroundTransparency = 1

	label.Text = (def.IsWorldBoss and "👑 [MVP] " or (def.IsBoss and "💀 [MINI] " or "")) .. def.Name .. " Lv." .. def.Level

	label.TextColor3 = def.IsBoss and Color3.fromRGB(255, 225, 115) or Color3.new(1, 1, 1)

	label.TextStrokeTransparency = 0.2

	label.TextScaled = true

	label.Font = Enum.Font.GothamBold

	label.Parent = billboard

	model.Parent = folder

	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")

	local spawned = remotes and remotes:FindFirstChild("MonsterSpawned")

	if spawned then spawned:FireAllClients(model) end

	return model

end

local function playerDied(player)

	if player:GetAttribute("InPvP") then return end

	if player:GetAttribute("_RPGDeathHandled") then return end

	player:SetAttribute("_RPGDeathHandled", true)

	local character = player.Character

	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	local dataApi = _G.DataStore

	local data = dataApi and dataApi.GetPlayerData(player)

	if data then

		local penaltyMult = 0.02

		if data.GuildId and data.GuildId ~= "" and _G.GuildSystem and _G.GuildSystem.GetDeathPenaltyMult then

			penaltyMult = penaltyMult * _G.GuildSystem.GetDeathPenaltyMult(data.GuildId)

		end

		local penalty = (data.Level >= 10) and math.floor(data.XP * penaltyMult) or 0

		data.XP = math.max(0, data.XP - penalty)

		data.DeathCount = (data.DeathCount or 0) + 1

		dataApi.SetHP(player, 0)

		dataApi.SyncAttributes(player, data)

		if _G.GameManager then _G.GameManager.PushCharacterData(player) end

	end

	if humanoid and humanoid.Health > 0 then

		humanoid.Health = 0

	end

end

_G.MonsterAI = { SpawnMonster = makeMonster, PlayerDied = playerDied }

-- Placed well off the central road (road is Z = -7..+7, creek is X = 136..144)

-- ============================================================

-- PRONTERA GATE 7-ZONE MONSTER SPAWN MAPPING (118 Active Spawns)

-- Designed for 10-50 concurrent players with instant/lively respawns

-- Respects central highway (Z = -8..+8) and creek crossing (X = 136..144)

-- ============================================================

local spawnPoints = {

	-- ── ZONE 1: ทุ่งหญ้าซากุระ Poring Blossom Meadow (Lv.1, X = 90..175, Z = -120..120) [16 Spawns] ──

	{ id = "Poring", pos = Vector3.new( 95, 0, -35), map = "Prontera" },

	{ id = "Poring", pos = Vector3.new(115, 0, -50), map = "Prontera" },

	{ id = "Poring", pos = Vector3.new(135, 0, -35), map = "Prontera" },

	{ id = "Poring", pos = Vector3.new(155, 0, -55), map = "Prontera" },

	{ id = "Poring", pos = Vector3.new(105, 0, -85), map = "Prontera" },

	{ id = "Poring", pos = Vector3.new(130, 0, -95), map = "Prontera" },

	{ id = "Poring", pos = Vector3.new(160, 0, -85), map = "Prontera" },

	{ id = "Poring", pos = Vector3.new(145, 0, -115), map = "Prontera" },

	{ id = "Poring", pos = Vector3.new( 95, 0,  35), map = "Prontera" },

	{ id = "Poring", pos = Vector3.new(115, 0,  50), map = "Prontera" },

	{ id = "Poring", pos = Vector3.new(135, 0,  35), map = "Prontera" },

	{ id = "Poring", pos = Vector3.new(155, 0,  55), map = "Prontera" },

	{ id = "Poring", pos = Vector3.new(105, 0,  85), map = "Prontera" },

	{ id = "Poring", pos = Vector3.new(130, 0,  95), map = "Prontera" },

	{ id = "Poring", pos = Vector3.new(160, 0,  85), map = "Prontera" },

	{ id = "Poring", pos = Vector3.new(145, 0, 115), map = "Prontera" },

	-- ── ZONE 2: ฟาร์มและทุ่งโคลเวอร์ Lunatic & Fabre Farmlands (Lv.2-15, X = 205..285, Z = -140..-20) [22 Spawns] ──

	{ id = "Fabre",   pos = Vector3.new(210, 0, -40), map = "Prontera" },

	{ id = "Fabre",   pos = Vector3.new(225, 0, -30), map = "Prontera" },

	{ id = "Fabre",   pos = Vector3.new(240, 0, -45), map = "Prontera" },

	{ id = "Fabre",   pos = Vector3.new(255, 0, -35), map = "Prontera" },

	{ id = "Fabre",   pos = Vector3.new(220, 0, -75), map = "Prontera" },

	{ id = "Fabre",   pos = Vector3.new(235, 0, -85), map = "Prontera" },

	{ id = "Fabre",   pos = Vector3.new(250, 0, -70), map = "Prontera" },

	{ id = "Fabre",   pos = Vector3.new(265, 0, -80), map = "Prontera" },

	{ id = "Lunatic", pos = Vector3.new(215, 0, -105), map = "Prontera" },

	{ id = "Lunatic", pos = Vector3.new(230, 0, -115), map = "Prontera" },

	{ id = "Lunatic", pos = Vector3.new(245, 0, -125), map = "Prontera" },

	{ id = "Lunatic", pos = Vector3.new(260, 0, -110), map = "Prontera" },

	{ id = "Lunatic", pos = Vector3.new(275, 0, -120), map = "Prontera" },

	{ id = "Lunatic", pos = Vector3.new(235, 0, -135), map = "Prontera" },

	{ id = "Lunatic", pos = Vector3.new(255, 0, -135), map = "Prontera" },

	{ id = "Lunatic", pos = Vector3.new(270, 0, -100), map = "Prontera" },

	{ id = "Goblin",  pos = Vector3.new(270, 0, -40), map = "Prontera" },

	{ id = "Goblin",  pos = Vector3.new(280, 0, -60), map = "Prontera" },

	{ id = "Goblin",  pos = Vector3.new(285, 0, -80), map = "Prontera" },

	{ id = "Goblin",  pos = Vector3.new(275, 0, -50), map = "Prontera" },

	{ id = "Goblin",  pos = Vector3.new(285, 0, -110), map = "Prontera" },

	{ id = "Goblin",  pos = Vector3.new(280, 0, -130), map = "Prontera" },

	-- ── ZONE 3: ป่าสนหมาป่าและแมงมุม Whispering Wolf Woods (Lv.5-24, X = 205..315, Z = 20..140) [22 Spawns] ──

	{ id = "Wolf", pos = Vector3.new(215, 0, 35), map = "Prontera" },

	{ id = "Wolf", pos = Vector3.new(230, 0, 45), map = "Prontera" },

	{ id = "Wolf", pos = Vector3.new(245, 0, 35), map = "Prontera" },

	{ id = "Wolf", pos = Vector3.new(260, 0, 50), map = "Prontera" },

	{ id = "Wolf", pos = Vector3.new(220, 0, 75), map = "Prontera" },

	{ id = "Wolf", pos = Vector3.new(238, 0, 85), map = "Prontera" },

	{ id = "Wolf", pos = Vector3.new(255, 0, 70), map = "Prontera" },

	{ id = "Wolf", pos = Vector3.new(272, 0, 80), map = "Prontera" },

	{ id = "Wolf", pos = Vector3.new(230, 0, 110), map = "Prontera" },

	{ id = "Wolf", pos = Vector3.new(248, 0, 120), map = "Prontera" },

	{ id = "Wolf", pos = Vector3.new(265, 0, 105), map = "Prontera" },

	{ id = "Wolf", pos = Vector3.new(285, 0, 115), map = "Prontera" },

	{ id = "Wolf", pos = Vector3.new(295, 0, 95), map = "Prontera" },

	{ id = "Wolf", pos = Vector3.new(305, 0, 125), map = "Prontera" },

	{ id = "Spider",   pos = Vector3.new(280, 0, 40), map = "Prontera" },

	{ id = "Spider",   pos = Vector3.new(295, 0, 55), map = "Prontera" },

	{ id = "Spider",   pos = Vector3.new(310, 0, 45), map = "Prontera" },

	{ id = "Spider",   pos = Vector3.new(300, 0, 75), map = "Prontera" },

	{ id = "ThiefBug", pos = Vector3.new(275, 0, 60), map = "Prontera" },

	{ id = "ThiefBug", pos = Vector3.new(290, 0, 35), map = "Prontera" },

	{ id = "ThiefBug", pos = Vector3.new(305, 0, 60), map = "Prontera" },

	{ id = "ThiefBug", pos = Vector3.new(315, 0, 80), map = "Prontera" },

	-- ── ZONE 4: ซากปรักหักพังทะเลทราย Sunken Desert Ruins (Lv.20-28, X = 325..415, Z = -140..-20) [18 Spawns] ──

	{ id = "Scorpion", pos = Vector3.new(330, 0, -35), map = "Prontera" },

	{ id = "Scorpion", pos = Vector3.new(345, 0, -50), map = "Prontera" },

	{ id = "Scorpion", pos = Vector3.new(360, 0, -35), map = "Prontera" },

	{ id = "Scorpion", pos = Vector3.new(375, 0, -55), map = "Prontera" },

	{ id = "Scorpion", pos = Vector3.new(390, 0, -40), map = "Prontera" },

	{ id = "Scorpion", pos = Vector3.new(405, 0, -55), map = "Prontera" },

	{ id = "Scorpion", pos = Vector3.new(340, 0, -80), map = "Prontera" },

	{ id = "Scorpion", pos = Vector3.new(360, 0, -95), map = "Prontera" },

	{ id = "Scorpion", pos = Vector3.new(380, 0, -85), map = "Prontera" },

	{ id = "Scorpion", pos = Vector3.new(400, 0, -90), map = "Prontera" },

	{ id = "GoblinRaider", pos = Vector3.new(345, 0, -115), map = "Prontera" },

	{ id = "GoblinRaider", pos = Vector3.new(365, 0, -125), map = "Prontera" },

	{ id = "GoblinRaider", pos = Vector3.new(385, 0, -115), map = "Prontera" },

	{ id = "GoblinRaider", pos = Vector3.new(405, 0, -125), map = "Prontera" },

	{ id = "GoblinRaider", pos = Vector3.new(355, 0, -70), map = "Prontera" },

	{ id = "GoblinRaider", pos = Vector3.new(375, 0, -70), map = "Prontera" },

	{ id = "GoblinRaider", pos = Vector3.new(395, 0, -70), map = "Prontera" },

	{ id = "GoblinRaider", pos = Vector3.new(410, 0, -35), map = "Prontera" },

	-- ── ZONE 5: สุสานโบราณและดันเจี้ยน Undead Graveyard & Crypt (Lv.8-15, X = 330..425, Z = 20..140) [22 Spawns] ──

	{ id = "Skeleton", pos = Vector3.new(335, 0, 35), map = "Prontera" },

	{ id = "Skeleton", pos = Vector3.new(350, 0, 50), map = "Prontera" },

	{ id = "Skeleton", pos = Vector3.new(365, 0, 35), map = "Prontera" },

	{ id = "Skeleton", pos = Vector3.new(380, 0, 55), map = "Prontera" },

	{ id = "Skeleton", pos = Vector3.new(395, 0, 40), map = "Prontera" },

	{ id = "Skeleton", pos = Vector3.new(410, 0, 55), map = "Prontera" },

	{ id = "Skeleton", pos = Vector3.new(340, 0, 75), map = "Prontera" },

	{ id = "Skeleton", pos = Vector3.new(360, 0, 85), map = "Prontera" },

	{ id = "Skeleton", pos = Vector3.new(375, 0, 70), map = "Prontera" },

	{ id = "Skeleton", pos = Vector3.new(395, 0, 80), map = "Prontera" },

	{ id = "Skeleton", pos = Vector3.new(415, 0, 75), map = "Prontera" },

	{ id = "Zombie",   pos = Vector3.new(345, 0, 105), map = "Prontera" },

	{ id = "Zombie",   pos = Vector3.new(360, 0, 120), map = "Prontera" },

	{ id = "Zombie",   pos = Vector3.new(375, 0, 105), map = "Prontera" },

	{ id = "Zombie",   pos = Vector3.new(390, 0, 120), map = "Prontera" },

	{ id = "Zombie",   pos = Vector3.new(405, 0, 105), map = "Prontera" },

	{ id = "Zombie",   pos = Vector3.new(420, 0, 120), map = "Prontera" },

	{ id = "Zombie",   pos = Vector3.new(350, 0, 95), map = "Prontera" },

	{ id = "Zombie",   pos = Vector3.new(370, 0, 95), map = "Prontera" },

	{ id = "Zombie",   pos = Vector3.new(385, 0, 95), map = "Prontera" },

	{ id = "Zombie",   pos = Vector3.new(400, 0, 95), map = "Prontera" },

	{ id = "Zombie",   pos = Vector3.new(415, 0, 95), map = "Prontera" },

	-- ── ZONE 6: ลานบอสเดรคและมิโนรัส Dragon Crag & Drake Shrine (MVP Boss, X = 435..495, Z = -60..60) [5 Spawns] ──

	{ id = "Minorous", pos = Vector3.new(445, 0, -35), map = "Prontera" },

	{ id = "Minorous", pos = Vector3.new(445, 0,  35), map = "Prontera" },

	{ id = "Minorous", pos = Vector3.new(465, 0, -20), map = "Prontera" },

	{ id = "Minorous", pos = Vector3.new(465, 0,  20), map = "Prontera" },

	{ id = "Drake",    pos = Vector3.new(485, 2,   0), map = "Prontera" },

}

for _, point in ipairs(spawnPoints) do makeMonster(point.id, point.pos, point.map) end

local function getTargetRoot(player)

	if not player or not player.Parent then return nil end

	local character = player.Character

	local root = character and character:FindFirstChild("HumanoidRootPart")

	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not root or not humanoid or humanoid.Health <= 0 then return nil end

	local hp = player:GetAttribute("HP")

	if not hp or hp <= 0 then return nil end

	if os.clock() < (player:GetAttribute("SpawnProtectedUntil") or 0) then return nil end

	if inSafeZone(root.Position) then return nil end

	return root

end

local function findNewTarget(monster, root)

	local provokerId = monster:GetAttribute("AggroUserId")

	if type(provokerId) == "number" then

		local provoker = Players:GetPlayerByUserId(provokerId)

		local provokerRoot = getTargetRoot(provoker)

		if provokerRoot and (provokerRoot.Position - root.Position).Magnitude <= GIVE_UP_DISTANCE

			and canMonsterSeeCharacter(monster, root, provoker.Character, provokerRoot) then

			return provoker

		end

		monster:SetAttribute("AggroUserId", nil)

	end

	local nearest, best = nil, tonumber(monster:GetAttribute("AggroRange")) or 18

	for _, player in ipairs(Players:GetPlayers()) do

		local targetRoot = getTargetRoot(player)

		if targetRoot then

			local distance = (targetRoot.Position - root.Position).Magnitude

			if distance < best and canMonsterSeeCharacter(monster, root, player.Character, targetRoot) then

				nearest, best = player, distance

			end

		end

	end

	return nearest

end

local groundRayParams = RaycastParams.new()

groundRayParams.FilterType = Enum.RaycastFilterType.Exclude

local function getGroundHeightAt(x, z, currentY, fallbackY, monster)

	groundRayParams.FilterDescendantsInstances = {monster, folder}

	local origin = Vector3.new(x, (currentY or 2) + 12, z)

	local hit = Workspace:Raycast(origin, Vector3.new(0, -35, 0), groundRayParams)

	if hit then

		return hit.Position.Y

	end

	return fallbackY or 0

end

local function moveToward(monster, root, goal, maxStep, stopDistance, baseHeight, isSlime, now)

	local position = root.Position

	local flat = Vector3.new(goal.X - position.X, 0, goal.Z - position.Z)

	local dist = flat.Magnitude

	local remaining = dist - stopDistance

	if remaining <= 0.05 then return true end

	local direction = flat.Unit

	-- Check obstacle in front (walls, high fences, large rocks)

	groundRayParams.FilterDescendantsInstances = {monster, folder}

	local fwdRayOrigin = position + Vector3.new(0, 0.5, 0)

	local fwdHit = Workspace:Raycast(fwdRayOrigin, direction * math.min(maxStep + 1.2, 3), groundRayParams)

	if fwdHit and fwdHit.Instance and fwdHit.Instance.CanCollide and not fwdHit.Instance:IsDescendantOf(monster) then

		return true -- blocked, treat as arrived

	end

	local nextPosition = pushOutOfSafeZone(position + direction * math.min(maxStep, remaining))

	local groundY = getGroundHeightAt(nextPosition.X, nextPosition.Z, position.Y, 0, monster)

	local hopOffset = 0

	if isSlime then

		hopOffset = math.abs(math.sin((now or os.clock()) * 9)) * 0.45

	end

	local finalY = groundY + (baseHeight or 1.5) + hopOffset

	local finalPos = Vector3.new(nextPosition.X, finalY, nextPosition.Z)

	monster:PivotTo(CFrame.lookAt(finalPos, finalPos + direction))

	return false

end

local states = setmetatable({}, { __mode = "k" })

local function getState(monster)

	local state = states[monster]

	if not state then

		state = { mode = "Idle", target = nil, nextAttackAt = 0, nextWanderAt = os.clock() + math.random(1, 5) }

		states[monster] = state

	end

	return state

end

local function stepMonster(monster, combat, now, dt)

	local root = monster.PrimaryPart

	if not root or (monster:GetAttribute("HP") or 0) <= 0 then return end

	if monster:GetAttribute("StatusStun") or monster:GetAttribute("StatusFrozen") then return end

	local state = getState(monster)

	local spawnPosition = monster:GetAttribute("SpawnPosition")

	local mId = monster:GetAttribute("MonsterID") or ""

	local def = monsters[mId] or {}

	local scale = def.Scale or 1

	local baseHeight = 3 * scale * 0.55

	local home = typeof(spawnPosition) == "Vector3" and (spawnPosition + Vector3.new(0, baseHeight, 0)) or root.Position

	local speed = tonumber(monster:GetAttribute("MoveSpeed")) or DEFAULT_MOVE_SPEED

	local isSlime = (mId == "Poring" or mId == "Fabre" or mId == "ThiefBug" or mId == "Lunatic")

	local position = root.Position

	local homeDistance = flatDistance(position, home)

	-- Mode: Return to home position

	if state.mode == "Return" then

		if homeDistance <= ARRIVE_DISTANCE then

			state.mode = "Idle"

			state.wanderGoal = nil

			state.nextWanderAt = now + math.random(2, 6)

			setMonsterHP(monster, monster:GetAttribute("MaxHP") or 1)

		else

			moveToward(monster, root, home, speed * RETURN_SPEED_MULT * dt, 0, baseHeight, isSlime, now)

		end

		return

	end

	-- Check for player target in sight / aggro range (throttle scans to save server CPU)

	if state.target or (state.nextScanAt or 0) <= now then

		state.nextScanAt = now + (state.target and 0.3 or 0.6)

		local found = findNewTarget(monster, root)

		if found then

			if state.target ~= found then

				state.target = found

				state.mode = "Chase"

				state.wanderGoal = nil

				state.nextAttackAt = math.max(state.nextAttackAt, now + FIRST_STRIKE_DELAY)

			end

		end

	end

	-- If chasing a target

	if state.target then

		local targetRoot = getTargetRoot(state.target)

		local distance = targetRoot and (targetRoot.Position - position).Magnitude or math.huge

		if not targetRoot or homeDistance > LEASH_RANGE or distance > GIVE_UP_DISTANCE then

			state.target = nil

			state.mode = "Return"

			state.wanderGoal = nil

			monster:SetAttribute("AggroUserId", nil)

			return

		end

		local attackRange = tonumber(monster:GetAttribute("AttackRange")) or 5

		if distance <= attackRange then

			if state.nextAttackAt <= now then

				state.nextAttackAt = now + (tonumber(monster:GetAttribute("AttackCooldown")) or 2.5)

				local dir = Vector3.new(targetRoot.Position.X - position.X, 0, targetRoot.Position.Z - position.Z)

				if dir.Magnitude > 0.05 then

					local lookCF = CFrame.lookAt(position, position + dir.Unit)

					monster:PivotTo(lookCF * CFrame.new(0, 0.25, -0.85))

					task.delay(0.14, function()

						if monster and monster.Parent and (monster:GetAttribute("HP") or 0) > 0 then

							monster:PivotTo(lookCF)

						end

					end)

				end

				combat.MonsterAttackPlayer(monster, state.target)

			end

		else

			moveToward(monster, root, targetRoot.Position, speed * dt, attackRange * STOP_FRACTION, baseHeight, isSlime, now)

		end

		return

	end

	-- No player target: Idle & Natural Wander (Patrol) around home spawn

	if state.mode == "Wander" and state.wanderGoal then

		if now >= (state.wanderEndTime or 0) then

			state.mode = "Idle"

			state.wanderGoal = nil

			state.nextWanderAt = now + math.random(3, 7)

		else

			local arrived = moveToward(monster, root, state.wanderGoal, (speed * 0.5) * dt, 0.6, baseHeight, isSlime, now)

			if arrived then

				state.mode = "Idle"

				state.wanderGoal = nil

				state.nextWanderAt = now + math.random(3, 7)

			end

		end

	else

		-- State is Idle

		state.mode = "Idle"

		if not state.nextWanderAt then

			state.nextWanderAt = now + math.random(1, 5)

		end

		if now >= state.nextWanderAt then

			local angle = math.random() * math.pi * 2

			local wanderDist = math.random(6, 14)

			local candidate = home + Vector3.new(math.cos(angle) * wanderDist, 0, math.sin(angle) * wanderDist)

			candidate = pushOutOfSafeZone(candidate)

			state.wanderGoal = candidate

			state.mode = "Wander"

			state.wanderEndTime = now + (wanderDist / math.max(speed * 0.5, 2)) + 1.2

		end

	end

end

local lastTick = os.clock()

while true do

	task.wait(AI_TICK)

	local now = os.clock()

	local dt = math.min(now - lastTick, 0.25)

	lastTick = now

	local combat = _G.CombatSystem

	if combat then

		for _, monster in ipairs(folder:GetChildren()) do

			if monster:IsA("Model") then

				local ok, err = pcall(stepMonster, monster, combat, now, dt)

				if not ok then warn("[MonsterAI] " .. monster.Name .. ": " .. tostring(err)) end

			end

		end

	end

end