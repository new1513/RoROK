-- ============================================================
-- PvPArenaSystem.server.lua
-- ServerScriptService — RoROK (Ragnarok Online-inspired MMORPG)
-- ระบบลานประลองเกียรติยศ Prontera PvP Arena
-- รวม: การสร้างสังเวียนโคลอสเซียม, Safe Zone, NPC นายทวาร,
--      การต่อสู้ระหว่างผู้เล่น (PvP Formulas), Kill Streak,
--      และกระดานจัดอันดับ Leaderboard
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local Debris            = game:GetService("Debris")

local GameData    = ReplicatedStorage:WaitForChild("GameData")
local SkillData   = require(GameData:WaitForChild("SkillData"))
local ClassData   = require(GameData:WaitForChild("ClassData"))
local ItemData    = require(GameData:WaitForChild("ItemData"))

-- ============================================================
-- DEPENDENCIES WAIT
-- ============================================================
local DataStore
local GameManager
local RemotesFolder
local leaveArena

local t0 = tick()
repeat
	task.wait(0.1)
	DataStore = _G.DataStore
	GameManager = _G.GameManager
until (DataStore and GameManager) or (tick() - t0 > 15)

RemotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemotesFolder then
	RemotesFolder = Instance.new("Folder")
	RemotesFolder.Name = "RemoteEvents"
	RemotesFolder.Parent = ReplicatedStorage
end

local function GetOrCreateRemote(className, name)
	local rem = RemotesFolder:FindFirstChild(name)
	if not rem then
		rem = Instance.new(className)
		rem.Name = name
		rem.Parent = RemotesFolder
	end
	return rem
end

-- Remote definitions for PvP
local RE_EnterPvPArena         = GetOrCreateRemote("RemoteEvent", "EnterPvPArena")
local RE_LeavePvPArena         = GetOrCreateRemote("RemoteEvent", "LeavePvPArena")
local RE_GetPvPLeaderboard     = GetOrCreateRemote("RemoteEvent", "GetPvPLeaderboard")
local RE_PvPLeaderboardUpdate  = GetOrCreateRemote("RemoteEvent", "PvPLeaderboardUpdate")
local RE_PvPAnnounce           = GetOrCreateRemote("RemoteEvent", "PvPAnnounce")
local RE_PvPStateChanged       = GetOrCreateRemote("RemoteEvent", "PvPStateChanged")
local RE_OpenPvPDialogue       = GetOrCreateRemote("RemoteEvent", "OpenPvPDialogue")
local RE_ShowDamageNumber      = GetOrCreateRemote("RemoteEvent", "ShowDamageNumber")
local RE_SkillFeedback         = GetOrCreateRemote("RemoteEvent", "SkillFeedback")

-- ============================================================
-- CONSTANTS & SETTINGS
-- ============================================================
local ARENA_CENTER         = Vector3.new(0, 48, 1500)
local ARENA_RADIUS         = 62
local SAFE_ZONE_Z_MIN      = 1546
local SAFE_ZONE_SPAWN_CF   = CFrame.new(0, 54, 1565)
local PRONTERA_SPAWN_CF    = CFrame.new(0, 5, -14)
local PVP_DAMAGE_MODIFIER  = 0.55 -- Balanced RO PvP damage scaling (55% normal damage)

-- Per-player PvP cooldowns & streak state
local playerAttackNextAt   = {} -- [userId] = timestamp
local playerSkillNextAt    = {} -- [userId][skillId] = timestamp
local inMemoryScores       = {} -- [userId] = { Name, Class, Level, Kills, Deaths, Streak, BestStreak, Points }

-- ============================================================
-- 1. BUILD THE COLOSSEUM ARENA ENVIRONMENT
-- ============================================================
local function buildColosseumArena()
	local oldArena = Workspace:FindFirstChild("RoROK_PvPArena")
	if oldArena then oldArena:Destroy() end

	local arenaRoot = Instance.new("Folder")
	arenaRoot.Name = "RoROK_PvPArena"
	arenaRoot.Parent = Workspace

	local function makePart(name, size, cf, material, color, canCollide)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = cf
		part.Material = material or Enum.Material.Slate
		part.Color = color or Color3.fromRGB(90, 85, 80)
		part.Anchored = true
		part.CanCollide = (canCollide ~= false)
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = arenaRoot
		return part
	end

	-- ── Main Arena Floor ───────────────────────────────────────
	-- Massive circular/octagonal base
	local floorBase = makePart("ArenaFloorBase", Vector3.new(140, 6, 140), CFrame.new(0, 45, 1500), Enum.Material.Cobblestone, Color3.fromRGB(75, 70, 65))
	
	-- Arena fighting pit surface
	local fightingPit = makePart("FightingPit", Vector3.new(124, 1, 124), CFrame.new(0, 48.5, 1500), Enum.Material.Sandstone, Color3.fromRGB(150, 135, 115))

	-- Inlaid Center Combat Ring (Crimson & Gold Neon)
	local centerEmblem1 = makePart("CenterRingOuter", Vector3.new(38, 0.2, 38), CFrame.new(0, 48.9, 1500), Enum.Material.Neon, Color3.fromRGB(180, 40, 40), false)
	local centerEmblem2 = makePart("CenterRingInner", Vector3.new(24, 0.3, 24), CFrame.new(0, 48.95, 1500), Enum.Material.Cobblestone, Color3.fromRGB(60, 55, 50), false)
	local centerStar = makePart("CenterEmblemCore", Vector3.new(10, 0.4, 10), CFrame.new(0, 49, 1500) * CFrame.Angles(0, math.rad(45), 0), Enum.Material.Neon, Color3.fromRGB(240, 195, 50), false)

	-- ── Perimeter Columns & Flaming Torches ────────────────────
	local numColumns = 16
	for i = 1, numColumns do
		local angle = (i / numColumns) * math.pi * 2
		local colX = math.cos(angle) * ARENA_RADIUS
		local colZ = 1500 + math.sin(angle) * ARENA_RADIUS

		-- Skip columns that would block the Safe Zone staircase entrance (around Z > 1545)
		if colZ < 1550 then
			-- Stone Column
			local col = makePart("ArenaColumn_" .. i, Vector3.new(5, 26, 5), CFrame.new(colX, 61, colZ), Enum.Material.Slate, Color3.fromRGB(120, 115, 110))
			-- Column Capital
			makePart("ColCapital_" .. i, Vector3.new(7, 2, 7), CFrame.new(colX, 74, colZ), Enum.Material.Cobblestone, Color3.fromRGB(160, 150, 135))
			
			-- Flaming Torch on top
			local brazier = makePart("Brazier_" .. i, Vector3.new(3, 2, 3), CFrame.new(colX, 76, colZ), Enum.Material.Metal, Color3.fromRGB(40, 40, 40))
			local fire = Instance.new("Fire")
			fire.Size = 8
			fire.Heat = 12
			fire.Color = Color3.fromRGB(255, 130, 30)
			fire.SecondaryColor = Color3.fromRGB(220, 50, 20)
			fire.Parent = brazier

			local light = Instance.new("PointLight")
			light.Brightness = 2.2
			light.Range = 32
			light.Color = Color3.fromRGB(255, 170, 70)
			light.Parent = brazier

			-- Hanging Battle Banners (Alternating Red and Blue)
			local bannerColor = (i % 2 == 0) and Color3.fromRGB(180, 30, 40) or Color3.fromRGB(35, 90, 190)
			local banner = makePart("Banner_" .. i, Vector3.new(2.4, 12, 0.4), CFrame.new(colX * 0.94, 62, colZ * 0.94) * CFrame.Angles(0, -angle, 0), Enum.Material.Fabric, bannerColor, false)
		end
	end

	-- ── Safe Zone / Staging Area (Hall of Champions) ───────────
	local safePlatform = makePart("SafeZonePlatform", Vector3.new(46, 5, 30), CFrame.new(0, 51.5, 1566), Enum.Material.Marble, Color3.fromRGB(180, 190, 205))
	
	-- Safe Zone Boundary Line (Glowing Yellow/Amber Stripe)
	local boundaryStripe = makePart("SafeBoundaryStripe", Vector3.new(46, 0.3, 2), CFrame.new(0, 53.95, 1551), Enum.Material.Neon, Color3.fromRGB(255, 200, 40), false)
	
	-- Billboard over the boundary line
	local bbPart = makePart("BoundaryLabelPart", Vector3.new(1, 1, 1), CFrame.new(0, 59, 1551), Enum.Material.Air, Color3.new(1, 1, 1), false)
	bbPart.Transparency = 1
	local bb = Instance.new("BillboardGui")
	bb.Name = "SafeZoneBoundaryBillboard"
	bb.Size = UDim2.new(0, 360, 0, 50)
	bb.StudsOffset = Vector3.new(0, 1, 0)
	bb.MaxDistance = 70
	bb.AlwaysOnTop = false
	bb.Parent = bbPart

	local bbText = Instance.new("TextLabel")
	bbText.Size = UDim2.new(1, 0, 1, 0)
	bbText.BackgroundTransparency = 1
	bbText.Text = "🛡️ เขตปลอดภัย (SAFE ZONE) ▲\n▼ ⚔️ สนามประลอง (COMBAT ZONE)"
	bbText.TextColor3 = Color3.fromRGB(255, 230, 110)
	bbText.TextStrokeTransparency = 0.2
	bbText.TextStrokeColor3 = Color3.fromRGB(20, 20, 30)
	bbText.Font = Enum.Font.GothamBold
	bbText.TextSize = 14
	bbText.Parent = bb

	-- Grand Staircase leading down from Safe Zone to Arena Pit
	local numSteps = 7
	for s = 1, numSteps do
		local stepY = 51.5 - (s * 0.5)
		local stepZ = 1551 - (s * 2.2)
		makePart("Step_" .. s, Vector3.new(34, 1.2, 2.4), CFrame.new(0, stepY, stepZ), Enum.Material.Cobblestone, Color3.fromRGB(130, 125, 120))
	end

	-- Safe Zone Railings & Decorative Pillars
	makePart("SafeRailingLeft", Vector3.new(2, 6, 30), CFrame.new(-22, 55, 1566), Enum.Material.Cobblestone, Color3.fromRGB(110, 105, 100))
	makePart("SafeRailingRight", Vector3.new(2, 6, 30), CFrame.new(22, 55, 1566), Enum.Material.Cobblestone, Color3.fromRGB(110, 105, 100))
	makePart("SafeBackWall", Vector3.new(46, 12, 2), CFrame.new(0, 58, 1581), Enum.Material.Slate, Color3.fromRGB(90, 85, 80))

	-- ── Return Portal (Back to Prontera) ──────────────────────
	local portalFrameL = makePart("PortalFrameL", Vector3.new(1.8, 14, 1.8), CFrame.new(-6, 60, 1578), Enum.Material.Cobblestone, Color3.fromRGB(100, 95, 90))
	local portalFrameR = makePart("PortalFrameR", Vector3.new(1.8, 14, 1.8), CFrame.new(6, 60, 1578), Enum.Material.Cobblestone, Color3.fromRGB(100, 95, 90))
	local portalFrameTop = makePart("PortalFrameTop", Vector3.new(13.8, 2, 2), CFrame.new(0, 67, 1578), Enum.Material.Cobblestone, Color3.fromRGB(120, 115, 110))
	
	local portalSurface = makePart("ReturnPortalSurface", Vector3.new(10, 12, 0.4), CFrame.new(0, 60, 1578), Enum.Material.Neon, Color3.fromRGB(60, 190, 255), false)
	portalSurface.Transparency = 0.25

	local portalLight = Instance.new("PointLight")
	portalLight.Color = Color3.fromRGB(80, 220, 255)
	portalLight.Brightness = 2.5
	portalLight.Range = 20
	portalLight.Parent = portalSurface

	-- Portal Prompt
	local portalPrompt = Instance.new("ProximityPrompt")
	portalPrompt.ObjectText = "ประตูมิติกลับเมือง"
	portalPrompt.ActionText = "กลับสู่ Prontera"
	portalPrompt.HoldDuration = 0.3
	portalPrompt.MaxActivationDistance = 14
	portalPrompt.RequiresLineOfSight = false
	portalPrompt.Parent = portalSurface

	portalPrompt.Triggered:Connect(function(player)
		if leaveArena then
			leaveArena(player)
		elseif _G.PvPArenaSystem and _G.PvPArenaSystem.LeaveArena then
			_G.PvPArenaSystem.LeaveArena(player)
		end
	end)

	-- Direct touch trigger for portal
	portalSurface.Touched:Connect(function(hit)
		local char = hit and hit:FindFirstAncestorOfClass("Model")
		local plr = char and Players:GetPlayerFromCharacter(char)
		if plr and (tick() - (plr:GetAttribute("_LastPortalTeleport") or 0)) > 3 then
			plr:SetAttribute("_LastPortalTeleport", tick())
			if _G.PvPArenaSystem and _G.PvPArenaSystem.LeaveArena then
				_G.PvPArenaSystem.LeaveArena(plr)
			end
		end
	end)

	-- ── Arena NPC in Safe Zone (Valdis - Arena Master) ─────────
	local valdisModel = Instance.new("Model")
	valdisModel.Name = "PvPInstructorValdis"
	valdisModel.Parent = arenaRoot

	local npcTorso = makePart("Torso", Vector3.new(2, 2, 1), CFrame.new(10, 55, 1564), Enum.Material.SmoothPlastic, Color3.fromRGB(160, 40, 45))
	npcTorso.Parent = valdisModel
	valdisModel.PrimaryPart = npcTorso

	local npcHead = makePart("Head", Vector3.new(1.2, 1.2, 1.2), CFrame.new(10, 56.6, 1564), Enum.Material.SmoothPlastic, Color3.fromRGB(240, 200, 170))
	npcHead.Parent = valdisModel
	local npcLegs = makePart("Legs", Vector3.new(2, 2, 1), CFrame.new(10, 53, 1564), Enum.Material.SmoothPlastic, Color3.fromRGB(40, 40, 50))
	npcLegs.Parent = valdisModel

	local valdisPrompt = Instance.new("ProximityPrompt")
	valdisPrompt.ObjectText = "Valdis • ครูฝึกการประลอง"
	valdisPrompt.ActionText = "สนทนา / ดูกระดานเกียรติยศ"
	valdisPrompt.MaxActivationDistance = 12
	valdisPrompt.RequiresLineOfSight = false
	valdisPrompt.Parent = npcTorso

	valdisPrompt.Triggered:Connect(function(player)
		RE_OpenPvPDialogue:FireClient(player, "Valdis")
	end)

	local valdisBB = Instance.new("BillboardGui")
	valdisBB.Name = "ValdisBillboard"
	valdisBB.Size = UDim2.new(0, 200, 0, 40)
	valdisBB.StudsOffset = Vector3.new(0, 2.5, 0)
	valdisBB.MaxDistance = 45
	valdisBB.AlwaysOnTop = false
	valdisBB.Parent = npcHead
	local valdisLabel = Instance.new("TextLabel")
	valdisLabel.Size = UDim2.new(1, 0, 1, 0)
	valdisLabel.BackgroundTransparency = 1
	valdisLabel.Text = "⚔️ Valdis\nครูฝึกสังเวียนเกียรติยศ"
	valdisLabel.TextColor3 = Color3.fromRGB(255, 215, 80)
	valdisLabel.TextStrokeTransparency = 0.2
	valdisLabel.Font = Enum.Font.GothamBold
	valdisLabel.TextSize = 13
	valdisLabel.Parent = valdisBB
end

-- ============================================================
-- 2. BUILD PRONTERA TOWN GATEKEEPER NPC
-- ============================================================
local function spawnPronteraGatekeeper()
	local oldNpc = Workspace:FindFirstChild("PvPGatekeeper")
	if oldNpc then oldNpc:Destroy() end

	local gatekeeper = Instance.new("Model")
	gatekeeper.Name = "PvPGatekeeper"
	gatekeeper.Parent = Workspace

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.CFrame = CFrame.new(16, 3, 18) * CFrame.Angles(0, math.rad(-90), 0)
	torso.Material = Enum.Material.Metal
	torso.Color = Color3.fromRGB(180, 160, 60)
	torso.Anchored = true
	torso.CanCollide = true
	torso.Parent = gatekeeper
	gatekeeper.PrimaryPart = torso

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.CFrame = CFrame.new(16, 4.6, 18)
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(240, 205, 175)
	head.Anchored = true
	head.CanCollide = false
	head.Parent = gatekeeper

	local legs = Instance.new("Part")
	legs.Name = "Legs"
	legs.Size = Vector3.new(2, 2, 1)
	legs.CFrame = CFrame.new(16, 1, 18)
	legs.Material = Enum.Material.Metal
	legs.Color = Color3.fromRGB(120, 110, 50)
	legs.Anchored = true
	legs.CanCollide = false
	legs.Parent = gatekeeper

	-- Shield on left arm
	local shield = Instance.new("Part")
	shield.Name = "Shield"
	shield.Size = Vector3.new(0.4, 2.8, 1.8)
	shield.CFrame = CFrame.new(16, 3, 19.4)
	shield.Material = Enum.Material.Neon
	shield.Color = Color3.fromRGB(220, 50, 50)
	shield.Anchored = true
	shield.CanCollide = false
	shield.Parent = gatekeeper

	-- Overhead Title
	local bb = Instance.new("BillboardGui")
	bb.Name = "PvPGatekeeperBillboard"
	bb.Size = UDim2.new(0, 260, 0, 50)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.MaxDistance = 45
	bb.AlwaysOnTop = false
	bb.Parent = head

	local bbText = Instance.new("TextLabel")
	bbText.Size = UDim2.new(1, 0, 1, 0)
	bbText.BackgroundTransparency = 1
	bbText.Text = "⚔️ ผู้คุมลานประลอง PvP\n[สังเวียนเกียรติยศ Prontera Arena]"
	bbText.TextColor3 = Color3.fromRGB(255, 220, 90)
	bbText.TextStrokeTransparency = 0.2
	bbText.TextStrokeColor3 = Color3.fromRGB(20, 20, 30)
	bbText.Font = Enum.Font.GothamBold
	bbText.TextSize = 13
	bbText.Parent = bb

	-- ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "สังเวียนเกียรติยศ Prontera"
	prompt.ActionText = "สนทนา / เข้าสู่ลานประลอง"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = torso

	prompt.Triggered:Connect(function(player)
		RE_OpenPvPDialogue:FireClient(player, "Gatekeeper")
	end)
end

-- ============================================================
-- 3. PLAYER PVP DATA & LEADERBOARD MANAGEMENT
-- ============================================================
local function getPlayerPvPData(player)
	local pData = DataStore.GetPlayerData(player)
	if not pData then return nil end

	if not pData.PvPStats then
		pData.PvPStats = {
			Kills      = 0,
			Deaths     = 0,
			Streak     = 0,
			BestStreak = 0,
			Points     = 0,
		}
	end

	-- Also cache in inMemoryScores
	inMemoryScores[player.UserId] = {
		UserId     = player.UserId,
		Name       = player.Name,
		Class      = player:GetAttribute("Class") or pData.Class or "Novice",
		Level      = player:GetAttribute("Level") or pData.Level or 1,
		Kills      = pData.PvPStats.Kills or 0,
		Deaths     = pData.PvPStats.Deaths or 0,
		Streak     = pData.PvPStats.Streak or 0,
		BestStreak = pData.PvPStats.BestStreak or 0,
		Points     = pData.PvPStats.Points or 0,
	}

	return pData.PvPStats
end

local function getLeaderboardTable()
	local list = {}
	for _, entry in pairs(inMemoryScores) do
		table.insert(list, entry)
	end

	-- Sort by Points descending, then Kills descending
	table.sort(list, function(a, b)
		if a.Points == b.Points then
			return a.Kills > b.Kills
		end
		return a.Points > b.Points
	end)

	-- Return Top 20
	local topList = {}
	for i = 1, math.min(#list, 20) do
		table.insert(topList, list[i])
	end
	return topList
end

local function broadcastLeaderboard()
	local topList = getLeaderboardTable()
	RE_PvPLeaderboardUpdate:FireAllClients(topList)
end

-- ============================================================
-- 4. ARENA ENTER / LEAVE LIFECYCLE
-- ============================================================
local function enterArena(player)
	local pData = DataStore.GetPlayerData(player)
	if not pData then return end

	pData.Map = "PvPArena"
	player:SetAttribute("Map", "PvPArena")
	player:SetAttribute("InPvP", true)
	player:SetAttribute("InPvPSafeZone", true)
	player:SetAttribute("SpawnProtectedUntil", os.clock() + 4)

	local char = player.Character
	if char and char.PrimaryPart then
		char:PivotTo(SAFE_ZONE_SPAWN_CF)
	end

	getPlayerPvPData(player)
	if GameManager and GameManager.PushCharacterData then
		GameManager.PushCharacterData(player)
	end

	RE_PvPStateChanged:FireClient(player, true, true)
	RE_SkillFeedback:FireClient(player, "⚔️ เข้าสู่ลานประลองเกียรติยศ Prontera PvP Arena! (คุณอยู่ใน Safe Zone)")
	broadcastLeaderboard()
end

leaveArena = function(player)
	local pData = DataStore.GetPlayerData(player)
	if not pData then return end

	pData.Map = "Prontera"
	player:SetAttribute("Map", "Prontera")
	player:SetAttribute("InPvP", false)
	player:SetAttribute("InPvPSafeZone", false)
	player:SetAttribute("SpawnProtectedUntil", os.clock() + 3)

	local char = player.Character
	if char and char.PrimaryPart then
		char:PivotTo(PRONTERA_SPAWN_CF)
	end

	if GameManager and GameManager.PushCharacterData then
		GameManager.PushCharacterData(player)
	end

	RE_PvPStateChanged:FireClient(player, false, false)
	RE_SkillFeedback:FireClient(player, "🏰 กลับสู่จัตุรัสน้ำพุเมืองหลวง Prontera แล้ว")
end

RE_EnterPvPArena.OnServerEvent:Connect(enterArena)
RE_LeavePvPArena.OnServerEvent:Connect(leaveArena)

RE_GetPvPLeaderboard.OnServerEvent:Connect(function(player)
	local topList = getLeaderboardTable()
	RE_PvPLeaderboardUpdate:FireClient(player, topList)
end)

-- ============================================================
-- 5. HEARTBEAT ZONE CHECK & SAFETY DOME
-- ============================================================
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("Map") == "PvPArena" then
			local char = player.Character
			local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
			if root then
				-- Fall protection: if player falls off the ring platform
				if root.Position.Y < 20 then
					char:PivotTo(SAFE_ZONE_SPAWN_CF)
					RE_SkillFeedback:FireClient(player, "⚠️ ตกจากสนามประลอง! นำตัวกลับสู่จุดปลอดภัย Safe Zone")
				end

				-- Safe Zone boundary check
				local wasInSafe = player:GetAttribute("InPvPSafeZone") or false
				local isNowInSafe = (root.Position.Z > SAFE_ZONE_Z_MIN)

				if wasInSafe ~= isNowInSafe then
					player:SetAttribute("InPvPSafeZone", isNowInSafe)
					RE_PvPStateChanged:FireClient(player, true, isNowInSafe)
					if isNowInSafe then
						RE_SkillFeedback:FireClient(player, "🛡️ คุณเข้าสู่เขตปลอดภัย (Safe Zone)")
					else
						RE_SkillFeedback:FireClient(player, "⚔️ เข้าสู่สนามประลอง! ระบบต่อสู้ PvP เปิดใช้งานแล้ว")
					end
				end

				-- ForceField management
				local hasFF = char:FindFirstChildOfClass("ForceField") ~= nil
				local shouldHaveFF = isNowInSafe or (now < (player:GetAttribute("SpawnProtectedUntil") or 0))
				if shouldHaveFF and not hasFF then
					local ff = Instance.new("ForceField")
					ff.Visible = false
					ff.Parent = char
				elseif not shouldHaveFF and hasFF then
					for _, f in ipairs(char:GetChildren()) do
						if f:IsA("ForceField") then f:Destroy() end
					end
				end
			end
		end
	end
end)

-- ============================================================
-- 6. PVP DEATH & KILL STREAK HANDLER
-- ============================================================
local function handlePvPKill(killer, victim)
	if not killer or not victim or killer == victim then return end

	local killerStats = getPlayerPvPData(killer)
	local victimStats = getPlayerPvPData(victim)

	if killerStats then
		killerStats.Kills      = (killerStats.Kills or 0) + 1
		killerStats.Streak     = (killerStats.Streak or 0) + 1
		killerStats.BestStreak = math.max(killerStats.BestStreak or 0, killerStats.Streak)
		
		local bonusPoints = 50 + (killerStats.Streak * 15)
		local bonusZeny   = 350 + (killerStats.Streak * 50)
		killerStats.Points = (killerStats.Points or 0) + bonusPoints

		if DataStore then
			(DataStore.ModifyGold or DataStore.AddGold)(killer, bonusZeny)
		end

		-- Streak Title
		local streakTitle = ""
		if killerStats.Streak == 2 then
			streakTitle = "⚔️ Double Kill!"
		elseif killerStats.Streak == 3 then
			streakTitle = "🔥 Killing Spree! (สังหาร 3 ตัวรวด!)"
		elseif killerStats.Streak == 5 then
			streakTitle = "⚡ Rampage! (สังหาร 5 ตัวรวด!)"
		elseif killerStats.Streak == 7 then
			streakTitle = "💀 Dominating! (สังหาร 7 ตัวรวด!)"
		elseif killerStats.Streak >= 10 then
			streakTitle = "👑 GODLIKE ไร้พ่าย! (" .. killerStats.Streak .. " ตัวรวด!)"
		end

		-- Broadcast Kill Announce to ALL clients in PvP Arena
		local announcePayload = {
			killerName    = killer.Name,
			killerClass   = killer:GetAttribute("Class") or "Novice",
			victimName    = victim.Name,
			victimClass   = victim:GetAttribute("Class") or "Novice",
			streak        = killerStats.Streak,
			streakTitle   = streakTitle,
			pointsGained  = bonusPoints,
			zenyGained    = bonusZeny,
		}
		RE_PvPAnnounce:FireAllClients(announcePayload)
		RE_SkillFeedback:FireClient(killer, string.format("🏆 สังหาร %s! ได้รับ +%d แต้ม PvP และ +%d Zeny", victim.Name, bonusPoints, bonusZeny))
	end

	if victimStats then
		victimStats.Deaths = (victimStats.Deaths or 0) + 1
		victimStats.Streak = 0
	end

	broadcastLeaderboard()

	-- Respawn victim in Safe Zone after brief delay
	task.delay(2.2, function()
		if victim and victim.Parent and victim:GetAttribute("Map") == "PvPArena" then
			local vChar = victim.Character
			local vRoot = vChar and (vChar:FindFirstChild("HumanoidRootPart") or vChar.PrimaryPart)
			local maxHP = victim:GetAttribute("MaxHP") or 100
			local maxSP = victim:GetAttribute("MaxSP") or 50

			DataStore.SetHP(victim, maxHP)
			DataStore.SetSP(victim, maxSP)
			victim:SetAttribute("InPvPSafeZone", true)
			victim:SetAttribute("SpawnProtectedUntil", os.clock() + 5)

			if vChar and vChar.PrimaryPart then
				vChar:PivotTo(SAFE_ZONE_SPAWN_CF)
			end

			if GameManager and GameManager.PushCharacterData then
				GameManager.PushCharacterData(victim)
			end

			RE_SkillFeedback:FireClient(victim, "🛡️ คุณพ่ายแพ้ในลานประลอง! ถูกนำตัวกลับสู่ Safe Zone (ไม่เสีย EXP)")
		end
	end)
end

-- ============================================================
-- 7. PVP COMBAT EXECUTION (BASIC ATTACK & SKILLS)
-- ============================================================
local function playerAttackPlayer(attacker, victim)
	if not attacker or not victim or attacker == victim then return end

	-- Check PvP Map & Safe Zones
	if attacker:GetAttribute("Map") ~= "PvPArena" or victim:GetAttribute("Map") ~= "PvPArena" then
		return
	end
	if attacker:GetAttribute("InPvPSafeZone") or victim:GetAttribute("InPvPSafeZone") then
		RE_SkillFeedback:FireClient(attacker, "⚠️ ไม่สามารถโจมตีภายในเขตปลอดภัย (Safe Zone)")
		return
	end
	if os.clock() < (victim:GetAttribute("SpawnProtectedUntil") or 0) then
		RE_SkillFeedback:FireClient(attacker, "🛡️ เป้าหมายกำลังอยู่ในช่วงคุ้มกันการเกิด (Spawn Protected)")
		return
	end

	local victimHP = victim:GetAttribute("HP") or 0
	if victimHP <= 0 then return end

	local aChar = attacker.Character
	local vChar = victim.Character
	local aRoot = aChar and aChar:FindFirstChild("HumanoidRootPart")
	local vRoot = vChar and vChar:FindFirstChild("HumanoidRootPart")
	if not aRoot or not vRoot then return end

	-- Range & ASPD check
	local attackerClass = attacker:GetAttribute("Class") or "Novice"
	local attackRange = ClassData.GetBasicAttackRange(attackerClass) + 4
	if (aRoot.Position - vRoot.Position).Magnitude > attackRange then return end

	local now = os.clock()
	if now < (playerAttackNextAt[attacker.UserId] or 0) then return end
	local aspd = math.clamp(attacker:GetAttribute("ASPD") or 100, 60, 190)
	playerAttackNextAt[attacker.UserId] = now + (60 / aspd)

	-- ── Ragnarok PvP Physical Formula ──────────────────────────
	local atk  = attacker:GetAttribute("ATK") or 20
	local hit  = attacker:GetAttribute("HIT") or 50
	local crit = attacker:GetAttribute("CritRate") or 5
	local def  = victim:GetAttribute("DEF") or 10
	local flee = victim:GetAttribute("FLEE") or 20

	-- Hit / Miss
	local hitChance = math.clamp(hit - flee + 80, 25, 100)
	local isMiss = (math.random(1, 100) > hitChance)

	-- Critical
	local isCrit = not isMiss and (math.random(1, 100) <= crit)

	local rawDamage = 0
	if not isMiss then
		if isCrit then
			rawDamage = atk * 1.5
		else
			rawDamage = math.max(1, atk - (def * 0.75))
		end
		-- Apply PvP Reduction
		rawDamage = math.floor(rawDamage * PVP_DAMAGE_MODIFIER * (math.random(95, 105) / 100))
	end

	local finalDamage = math.max(isMiss and 0 or 1, rawDamage)

	-- Damage number display
	RE_ShowDamageNumber:FireAllClients(vRoot.Position, finalDamage, isCrit, isMiss and "MISS" or "PHYS")

	-- Deduct victim HP
	local newHP = math.max(0, victimHP - finalDamage)
	DataStore.SetHP(victim, newHP)
	if GameManager and GameManager.PushCharacterData then
		GameManager.PushCharacterData(victim)
	end

	-- Check for kill
	if newHP <= 0 then
		handlePvPKill(attacker, victim)
	end
end

local function playerSkillPlayer(attacker, victim, skillId, skillLevel)
	if not attacker or not victim or attacker == victim then return end

	if attacker:GetAttribute("Map") ~= "PvPArena" or victim:GetAttribute("Map") ~= "PvPArena" then
		return
	end
	if attacker:GetAttribute("InPvPSafeZone") or victim:GetAttribute("InPvPSafeZone") then
		RE_SkillFeedback:FireClient(attacker, "⚠️ ไม่สามารถใช้สกิลภายในเขตปลอดภัย (Safe Zone)")
		return
	end
	if os.clock() < (victim:GetAttribute("SpawnProtectedUntil") or 0) then
		RE_SkillFeedback:FireClient(attacker, "🛡️ เป้าหมายกำลังอยู่ในช่วงคุ้มกันการเกิด (Spawn Protected)")
		return
	end

	local sData = SkillData[skillId]
	if not sData then return end

	local cooldowns = playerSkillNextAt[attacker.UserId]
	if not cooldowns then
		cooldowns = {}
		playerSkillNextAt[attacker.UserId] = cooldowns
	end

	local now = os.clock()
	if now < (cooldowns[skillId] or 0) then return end
	cooldowns[skillId] = now + math.max(0.6, tonumber(sData.cooldown) or 1.5)

	-- SP check
	local spCost = (sData.spCost or 5) + ((skillLevel - 1) * (sData.spCostPerLevel or 2))
	local curSP  = attacker:GetAttribute("SP") or 0
	if curSP < spCost then
		RE_SkillFeedback:FireClient(attacker, "SP ไม่เพียงพอสำหรับการใช้สกิลนี้")
		return
	end
	DataStore.SetSP(attacker, curSP - spCost)

	local aChar = attacker.Character
	local vChar = victim.Character
	local aRoot = aChar and aChar:FindFirstChild("HumanoidRootPart")
	local vRoot = vChar and vChar:FindFirstChild("HumanoidRootPart")
	if not aRoot or not vRoot then return end

	local skillRange = (tonumber(sData.range) or 15) + 6
	if (aRoot.Position - vRoot.Position).Magnitude > skillRange then return end

	local victimHP = victim:GetAttribute("HP") or 0
	if victimHP <= 0 then return end

	local isMagic = sData.isMagic or false
	local powerMult = (sData.powerMult or 1.2) + ((skillLevel - 1) * (sData.powerPerLevel or 0.15))
	local finalDamage = 0

	if isMagic then
		local matkMin = attacker:GetAttribute("MATK_min") or 20
		local matkMax = attacker:GetAttribute("MATK_max") or 40
		local matk = math.random(matkMin, matkMax)
		local mdef = victim:GetAttribute("MDEF") or 5
		local raw = math.max(1, (matk * powerMult) - (mdef * 0.8))
		finalDamage = math.max(1, math.floor(raw * PVP_DAMAGE_MODIFIER))
	else
		local atk = attacker:GetAttribute("ATK") or 20
		local def = victim:GetAttribute("DEF") or 10
		local raw = math.max(1, (atk * powerMult) - (def * 0.75))
		finalDamage = math.max(1, math.floor(raw * PVP_DAMAGE_MODIFIER))
	end

	local isCrit = false
	RE_ShowDamageNumber:FireAllClients(vRoot.Position, finalDamage, isCrit, isMagic and "MAGIC" or "PHYS")

	local newHP = math.max(0, victimHP - finalDamage)
	DataStore.SetHP(victim, newHP)
	if GameManager and GameManager.PushCharacterData then
		GameManager.PushCharacterData(victim)
	end

	if newHP <= 0 then
		handlePvPKill(attacker, victim)
	end
end

-- ============================================================
-- 8. INITIALIZE & EXPOSE MODULE
-- ============================================================
buildColosseumArena()
spawnPronteraGatekeeper()

_G.PvPArenaSystem = {
	EnterArena         = enterArena,
	LeaveArena         = leaveArena,
	PlayerAttackPlayer = playerAttackPlayer,
	PlayerSkillPlayer  = playerSkillPlayer,
	GetLeaderboard     = getLeaderboardTable,
}

print("[PvPArenaSystem] Prontera Colosseum PvP Arena system initialized successfully")
