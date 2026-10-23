-- ============================================================
-- GameManager.server.lua
-- ServerScriptService — RoROK (Ragnarok Online-inspired MMORPG)
-- ============================================================
-- ตัวจัดการหลักของเกม: setup RemoteEvents, จัดการผู้เล่น,
-- ระบบ regen, stat points, class change
-- Main game orchestrator: RemoteEvents, player setup, regen, stats
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local ClassData = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("ClassData"))
local ItemData = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("ItemData"))

-- ============================================================
-- WAIT FOR DATASTORE
-- รอให้ DataStore.server.lua โหลดก่อน (ผ่าน _G)
-- Wait for DataStore script to populate _G.DataStore
-- ============================================================
local DataStore
local DS_WAIT_START = tick()
repeat
	task.wait(0.1)
	DataStore = _G.DataStore
until DataStore ~= nil or (tick() - DS_WAIT_START) > 15

if not DataStore then
	error("[GameManager] FATAL: DataStore ไม่พร้อม / DataStore not available after 15s. Check load order.")
end

print("[GameManager] DataStore พร้อม / DataStore ready")

-- ============================================================
-- REMOTE EVENTS SETUP
-- สร้าง RemoteEvents ใน ReplicatedStorage
-- Create all RemoteEvents and RemoteFunctions in ReplicatedStorage
-- ============================================================
local RemoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEventsFolder then
	RemoteEventsFolder = Instance.new("Folder")
	RemoteEventsFolder.Name   = "RemoteEvents"
	RemoteEventsFolder.Parent = ReplicatedStorage
end

-- ── Helper: สร้าง RemoteEvent ถ้ายังไม่มี ──────────────────
local function GetOrCreateRemote(className, name)
	local existing = RemoteEventsFolder:FindFirstChild(name)
	if existing then return existing end
	local r   = Instance.new(className)
	r.Name    = name
	r.Parent  = RemoteEventsFolder
	return r
end

-- Client → Server (ผู้เล่นส่งคำขอมาที่ Server)
local RE_DistributeStatPoint = GetOrCreateRemote("RemoteEvent", "DistributeStatPoint")
local RE_UseSkill            = GetOrCreateRemote("RemoteEvent", "UseSkill")
local RE_RequestAttack       = GetOrCreateRemote("RemoteEvent", "RequestAttack")
local RE_ChangeClass         = GetOrCreateRemote("RemoteEvent", "ChangeClass")

-- Server → Client (Server ส่งข้อมูลไปยัง Client)
local RE_UpdateCharacterData = GetOrCreateRemote("RemoteEvent", "UpdateCharacterData")
local RE_ShowDamageNumber    = GetOrCreateRemote("RemoteEvent", "ShowDamageNumber")
local RE_ShowHealNumber      = GetOrCreateRemote("RemoteEvent", "ShowHealNumber")
local RE_ApplyStatusEffect   = GetOrCreateRemote("RemoteEvent", "ApplyStatusEffect")
local RE_MonsterSpawned      = GetOrCreateRemote("RemoteEvent", "MonsterSpawned")
local RE_MonsterDied         = GetOrCreateRemote("RemoteEvent", "MonsterDied")
local RE_LevelUp             = GetOrCreateRemote("RemoteEvent", "LevelUp")
local RE_OpenTutorial        = GetOrCreateRemote("RemoteEvent", "OpenTutorial")
local RE_OpenDailyQuests     = GetOrCreateRemote("RemoteEvent", "OpenDailyQuests")
local RE_SkillFeedback       = GetOrCreateRemote("RemoteEvent", "SkillFeedback")
local RE_StudioGrantJobXP    = GetOrCreateRemote("RemoteEvent", "StudioGrantJobXP")
local RE_StudioResetToNovice = GetOrCreateRemote("RemoteEvent", "StudioResetToNovice")
local RE_UpdateInventory     = GetOrCreateRemote("RemoteEvent", "UpdateInventory")
local RE_EquipItem           = GetOrCreateRemote("RemoteEvent", "EquipItem")
local RE_UnequipItem         = GetOrCreateRemote("RemoteEvent", "UnequipItem")
local RE_RefineEquipment     = GetOrCreateRemote("RemoteEvent", "RefineEquipment")
local RE_OpenRefinement      = GetOrCreateRemote("RemoteEvent", "OpenRefinement")
local RE_LearnSkill          = GetOrCreateRemote("RemoteEvent", "LearnSkill")
local RE_SocketCard          = GetOrCreateRemote("RemoteEvent", "SocketCard")
local RE_UnsocketCard        = GetOrCreateRemote("RemoteEvent", "UnsocketCard")
local RE_TeleportToMap       = GetOrCreateRemote("RemoteEvent", "TeleportToMap")
local RE_OpenWorldTravel     = GetOrCreateRemote("RemoteEvent", "OpenWorldTravel")
local PushCharacterData
local EQUIPMENT_SLOTS = {
	HeadTop = true,
	HeadMid = true,
	HeadBottom = true,
	Armor = true,
	Shield = true,
	Robe = true,
	Footgear = true,
	Accessory1 = true,
	Accessory2 = true,
	Weapon = true,
}
local RF_RequestInventory = RemoteEventsFolder:FindFirstChild("RequestInventory")
if not RF_RequestInventory then
	RF_RequestInventory = Instance.new("RemoteFunction")
	RF_RequestInventory.Name = "RequestInventory"
	RF_RequestInventory.Parent = RemoteEventsFolder
end
RF_RequestInventory.OnServerInvoke = function(player)
	local data = DataStore.GetPlayerData(player)
	return data and data.Inventory or {}, data and data.Equipment or {}, data and data.EquipmentRefine or {}, data and data.EquipmentCards or {}
end

local function sendInventory(player, data, message)
	RE_UpdateInventory:FireClient(player, data.Inventory or {}, data.Equipment or {}, message, data.EquipmentRefine or {}, data.EquipmentCards or {})
end

local function returnEquipmentToInventory(data, itemId, refineLevel)
	if not itemId then return end
	for _, owned in ipairs(data.Inventory) do
		if owned.itemId == itemId and (tonumber(owned.enhancement) or 0) == (tonumber(refineLevel) or 0) then
			owned.quantity = (tonumber(owned.quantity) or 0) + 1
			return
		end
	end
	table.insert(data.Inventory, { itemId = itemId, quantity = 1, enhancement = tonumber(refineLevel) or 0 })
end

RE_EquipItem.OnServerEvent:Connect(function(player, itemId, requestedEnhancement)
	if type(itemId) ~= "string" then return end
	local requestedRefine = math.clamp(math.floor(tonumber(requestedEnhancement) or 0), 0, 15)
	local data = DataStore.GetPlayerData(player)
	local item = ItemData[itemId]
	if not data or not item or item.type ~= "Equipment" then return end

	local targetSlot = item.slot
	if targetSlot == "Accessory" then
		if not data.Equipment or not data.Equipment.Accessory1 then
			targetSlot = "Accessory1"
		elseif not data.Equipment.Accessory2 then
			targetSlot = "Accessory2"
		else
			targetSlot = "Accessory1"
		end
	end
	if not EQUIPMENT_SLOTS[targetSlot] then return end

	local foundIndex
	for index, entry in ipairs(data.Inventory or {}) do
		local entryRefine = math.clamp(math.floor(tonumber(entry.enhancement) or 0), 0, 15)
		if entry.itemId == itemId and entryRefine == requestedRefine and (tonumber(entry.quantity) or 0) > 0 then
			foundIndex = index
			break
		end
	end
	if not foundIndex then
		for index, entry in ipairs(data.Inventory or {}) do
			if entry.itemId == itemId and (tonumber(entry.quantity) or 0) > 0 then
				foundIndex = index
				break
			end
		end
	end
	if not foundIndex then return end

	if targetSlot == "Weapon" and (not item.weaponType or not ClassData.CanUseWeapon(data.Class, item.weaponType)) then
		RE_SkillFeedback:FireClient(player, "อาชีพนี้ใช้อาวุธชนิดนี้ไม่ได้")
		return
	end

	local oldItemId = data.Equipment[targetSlot]
	local oldRefineLevel = (data.EquipmentRefine or {})[targetSlot] or 0
	local entry = data.Inventory[foundIndex]
	local actualRefine = tonumber(entry.enhancement) or 0
	entry.quantity -= 1
	if entry.quantity <= 0 then
		table.remove(data.Inventory, foundIndex)
	end

	if oldItemId then
		returnEquipmentToInventory(data, oldItemId, oldRefineLevel)
	end

	data.Equipment[targetSlot] = itemId
	data.EquipmentRefine = data.EquipmentRefine or {}
	data.EquipmentRefine[targetSlot] = actualRefine

	DataStore.SyncAttributes(player, data)
	PushCharacterData(player)
	sendInventory(player, data, "สวม " .. item.name .. " แล้ว")
end)

RE_UnequipItem.OnServerEvent:Connect(function(player, slot)
	if type(slot) ~= "string" or not EQUIPMENT_SLOTS[slot] then return end
	local data = DataStore.GetPlayerData(player)
	if not data or type(data.Equipment) ~= "table" then return end
	local itemId = data.Equipment[slot]
	if not itemId then return end
	local refineLevel = (data.EquipmentRefine or {})[slot] or 0
	data.Equipment[slot] = nil
	data.EquipmentRefine = data.EquipmentRefine or {}
	data.EquipmentRefine[slot] = nil
	returnEquipmentToInventory(data, itemId, refineLevel)
	DataStore.SyncAttributes(player, data)
	PushCharacterData(player)
	sendInventory(player, data, "ถอดอุปกรณ์แล้ว")
end)

local REFINE_CHANCES = { [1] = 100, [2] = 100, [3] = 100, [4] = 100, [5] = 60, [6] = 50, [7] = 40, [8] = 30, [9] = 25, [10] = 20, [11] = 17, [12] = 14, [13] = 12, [14] = 10, [15] = 8 }
RE_RefineEquipment.OnServerEvent:Connect(function(player, slot)
	if slot ~= "Weapon" and slot ~= "Armor" then return end
	local plaza = Workspace:FindFirstChild("RoROK_StarterPlaza")
	local blacksmith = plaza and plaza:FindFirstChild("Blacksmith")
	local smithRoot = blacksmith and blacksmith.PrimaryPart
	local character = player.Character
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	if not smithRoot or not playerRoot or (playerRoot.Position - smithRoot.Position).Magnitude > 14 then return end
	local data = DataStore.GetPlayerData(player)
	if not data then return end
	local itemId = data.Equipment and data.Equipment[slot]
	local item = ItemData[itemId]
	if not item or item.type ~= "Equipment" or item.slot ~= slot then
		RE_SkillFeedback:FireClient(player, "ต้องสวมอุปกรณ์ช่องนี้ก่อนตีบวก")
		return
	end
	data.EquipmentRefine = data.EquipmentRefine or {}
	local current = math.clamp(math.floor(tonumber(data.EquipmentRefine[slot]) or 0), 0, 15)
	if current >= 15 then RE_SkillFeedback:FireClient(player, "อุปกรณ์ชิ้นนี้ตีบวกถึง +15 แล้ว"); return end
	local stoneIndex
	for i, entry in ipairs(data.Inventory or {}) do
		if entry.itemId == "BeginnerRefinementStone" and (tonumber(entry.quantity) or 0) > 0 then stoneIndex = i; break end
	end
	if not stoneIndex then RE_SkillFeedback:FireClient(player, "หินตีบวกไม่พอ"); return end
	local targetLevel = current + 1
	local goldCost = targetLevel * 20
	if not DataStore.ModifyGold(player, -goldCost) then RE_SkillFeedback:FireClient(player, string.format("Zeny ไม่พอ (ต้องใช้ %d z)", goldCost)); return end
	local stone = data.Inventory[stoneIndex]
	stone.quantity -= 1
	if stone.quantity <= 0 then table.remove(data.Inventory, stoneIndex) end
	local chance = REFINE_CHANCES[targetLevel]
	local succeeded = math.random(1, 100) <= chance
	if succeeded then data.EquipmentRefine[slot] = targetLevel end
	DataStore.SyncAttributes(player, data)
	PushCharacterData(player)
	local message = succeeded and string.format("ตีบวกสำเร็จ! %s +%d (%d%%)", item.name, targetLevel, chance)
		or string.format("ตีบวกไม่สำเร็จ +%d (%d%%) — ระดับอุปกรณ์คงเดิม", targetLevel, chance)
	sendInventory(player, data, message)
end)

-- Expose remotes globally for CombatSystem / MonsterAI
_G.Remotes = {
	UpdateCharacterData = RE_UpdateCharacterData,
	ShowDamageNumber    = RE_ShowDamageNumber,
	ShowHealNumber      = RE_ShowHealNumber,
	ApplyStatusEffect   = RE_ApplyStatusEffect,
	MonsterSpawned      = RE_MonsterSpawned,
	MonsterDied         = RE_MonsterDied,
	LevelUp             = RE_LevelUp,
	OpenTutorial        = RE_OpenTutorial,
	OpenDailyQuests     = RE_OpenDailyQuests,
	SkillFeedback       = RE_SkillFeedback,
	UpdateInventory     = RE_UpdateInventory,
}

print("[GameManager] RemoteEvents ตั้งค่าเสร็จ / RemoteEvents setup complete")

-- ============================================================
-- VALID CLASSES
-- รายชื่ออาชีพที่ถูกต้องทั้งหมด
-- ============================================================
local VALID_CLASSES = {
	Novice      = true,
	Acolyte     = true,
	Knight      = true,
	Mage        = true,
	Archer      = true,
	Thief       = true,
	Merchant    = true,
	LordKnight  = true,
	Priest      = true,
	Wizard      = true,
	Hunter      = true,
	Assassin    = true,
	Blacksmith  = true,
}

-- Classes that Novice can change into (Novice ไม่นับ)
local NOVICE_ADVANCEMENTS = {
	Acolyte  = true,
	Knight   = true,
	Mage     = true,
	Archer   = true,
	Thief    = true,
	Merchant = true,
}

-- ============================================================
-- MAP SPAWN POINTS
-- จุดเกิดของแต่ละแมป
-- Spawn locations for each map
-- ============================================================
local MAP_SPAWNS = {
	Prontera        = CFrame.new(0, 5, -14),
	PronteraCulvert = CFrame.new(0, 5, -624),
	Morroc          = CFrame.new(950, 5, -16),
	Amatsu          = CFrame.new(-950, 5, -16),
	PvPArena        = CFrame.new(0, 54, 1565),
}

-- ============================================================
-- REGEN STATE
-- เก็บสถานะ regen ต่อ player
-- Per-player regen tracking
-- ============================================================
local PlayerRegenConnections = {}  -- [userId] = task thread handle
local basicAttackNextAt = {}       -- [userId] = timestamp

-- ============================================================
-- PUSH FULL STAT UPDATE TO CLIENT
-- ส่งข้อมูลสถิติทั้งหมดไปยัง client ของผู้เล่นคนนั้น
-- Fires UpdateCharacterData remote to the specific player client
-- ============================================================
PushCharacterData = function(player)
	local data = DataStore.GetPlayerData(player)
	if not data then return end

	local derived = DataStore.CalcDerivedStats(data)

	-- Bundle stats into a table for the client UI
	local payload = {
		Level        = data.Level,
		JobLevel     = data.JobLevel,
		Class        = data.Class,
		XP           = data.XP,
		JobXP        = data.JobXP,
		XP_NextLevel = data.XP_NextLevel,
		JobXP_NextLevel = data.JobXP_NextLevel or math.max(50, (data.JobLevel or 1) * 60),
		StatPoints   = data.StatPoints,
		SkillPoints  = data.SkillPoints,
	Skills       = data.Skills or {},
		Stats        = {
			STR = data.Stats.STR,
			AGI = data.Stats.AGI,
			VIT = data.Stats.VIT,
			INT = data.Stats.INT,
			DEX = data.Stats.DEX,
			LUK = data.Stats.LUK,
		},
		HP     = data.HP,
		MaxHP  = derived.MaxHP,
		SP     = data.SP,
		MaxSP  = derived.MaxSP,
		ATK    = derived.ATK,
		MATK_min  = derived.MATK_min,
		MATK_max  = derived.MATK_max,
		DEF    = derived.DEF,
		MDEF   = derived.MDEF,
		HIT    = derived.HIT,
		FLEE   = derived.FLEE,
		CritRate     = derived.CritRate,
		PerfectDodge = derived.PerfectDodge,
		HPRegen      = derived.HPRegen,
		SPRegen      = derived.SPRegen,
		ASPD         = derived.ASPD,
		AttackRange  = ClassData.GetBasicAttackRange(data.Class),
		Gold   = data.Gold,
		Inventory = data.Inventory or {},
		Equipment = data.Equipment or {},
		EquipmentRefine = data.EquipmentRefine or {},
		EquipmentCards = data.EquipmentCards or {},
		CoatedElement = player:GetAttribute("CoatedElement") or "",
		Map    = data.Map,
		GuildId = data.GuildId or "",
		PartyId = data.PartyId or "",
	}

	RE_UpdateCharacterData:FireClient(player, payload)
end
_G.PushCharacterData = PushCharacterData

-- ============================================================
-- START REGEN LOOP FOR PLAYER
-- HP regenerates every 10 seconds; SP regenerates every second for responsive skills.
-- ============================================================
local function StartRegenLoop(player)
	-- Stop any existing regen loop ก่อน
	if PlayerRegenConnections[player.UserId] then
		task.cancel(PlayerRegenConnections[player.UserId])
		PlayerRegenConnections[player.UserId] = nil
	end
	basicAttackNextAt[player.UserId] = nil

	local thread = task.spawn(function()
		local hpRegenElapsed = 0
		local spRegenAccumulator = 0
		while player.Parent ~= nil do  -- ผู้เล่นยังอยู่ใน game
			task.wait(1)
			hpRegenElapsed += 1

			local data = DataStore.GetPlayerData(player)
			if not data then break end

			local derived = DataStore.CalcDerivedStats(data)

			-- HP keeps its slower 10-second tick.
			if hpRegenElapsed >= 10 and data.HP < derived.MaxHP then
				local newHP = math.min(data.HP + derived.HPRegen, derived.MaxHP)
				DataStore.SetHP(player, newHP)
			end
			if hpRegenElapsed >= 10 then hpRegenElapsed = 0 end

			-- Accumulate fractional SP each second, bounded by the INT-scaled rate.
			if data.SP < derived.MaxSP then
				spRegenAccumulator += derived.SPRegen
				local wholeSP = math.floor(spRegenAccumulator)
				if wholeSP > 0 then
					local newSP = math.min(data.SP + wholeSP, derived.MaxSP)
					local restoredSP = newSP - data.SP
					DataStore.SetSP(player, newSP)
					spRegenAccumulator -= restoredSP
					if newSP >= derived.MaxSP then spRegenAccumulator = 0 end
				end
			else
				spRegenAccumulator = 0
			end

			-- อัพเดต derived stats ผ่าน SyncAttributes
			DataStore.SyncAttributes(player, data)

			-- แจ้ง client ให้อัพเดต UI
			PushCharacterData(player)
		end
	end)

	PlayerRegenConnections[player.UserId] = thread
end

-- ============================================================
-- SPAWN PLAYER AT MAP
-- teleport ผู้เล่นไปยังจุดเกิดของแมปที่บันทึกไว้
-- Teleports the player character to their saved map spawn
-- ============================================================
local function SpawnPlayerAtMap(player, mapName)
	-- รอให้ Character โหลด
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then
		warn(string.format("[GameManager] ไม่พบ HumanoidRootPart สำหรับ %s", player.Name))
		return
	end

	local spawnCF = MAP_SPAWNS[mapName] or MAP_SPAWNS["Prontera"]
	-- Add small random offset เพื่อไม่ให้ผู้เล่นทับกัน
	local offsetX = math.random(-5, 5)
	local offsetZ = math.random(-5, 5)
	spawnCF = spawnCF * CFrame.new(offsetX, 0, offsetZ)

	hrp.CFrame = spawnCF
	print(string.format("[GameManager] Spawn %s ที่แมป %s", player.Name, mapName))
end

-- ============================================================
-- PLAYER ADDED
-- ตั้งค่าผู้เล่นเมื่อเข้าเกม
-- Full player initialization on join
-- ============================================================
local initializedPlayers = {}
local function BindCharacterRespawn(player)
	if player:GetAttribute("_RespawnBound") then return end
	player:SetAttribute("_RespawnBound", true)
	player.CharacterAdded:Connect(function(character)
		local wasDeathRespawn = player:GetAttribute("_RPGDeathHandled") == true
		player:SetAttribute("_RPGDeathHandled", false)
		player:SetAttribute("SpawnProtectedUntil", os.clock() + 6)
		local data = DataStore.GetPlayerData(player)
		if not data then return end
		local humanoid = character:WaitForChild("Humanoid", 5)
		-- รอให้ character ตั้งค่าเสร็จ แล้วย้ายกลับเมืองก่อนเปิดรับความเสียหาย
		task.wait(0.25)
		SpawnPlayerAtMap(player, data.Map or "Prontera")
	BindCharacterRespawn(player)
		if wasDeathRespawn then
			local maxHP = player:GetAttribute("MaxHP") or 40
			DataStore.SetHP(player, math.max(1, math.floor(maxHP * 0.25)))
			if _G.GameManager and _G.GameManager.PushCharacterData then _G.GameManager.PushCharacterData(player) end
		end
		if humanoid and humanoid.Health <= 0 then humanoid.Health = humanoid.MaxHealth end
	end)
end

local function SetupPlayer(player)
	if initializedPlayers[player.UserId] then return end
	initializedPlayers[player.UserId] = true
	-- รอให้ DataStore โหลดข้อมูลผู้เล่น (_DataReady Attribute)
	local readyStart = tick()
	while not player:GetAttribute("_DataReady") do
		task.wait(0.1)
		if tick() - readyStart > 20 then
			warn(string.format("[GameManager] Timeout รอข้อมูล / Timeout waiting for data: %s", player.Name))
			break
		end
	end

	local data = DataStore.GetPlayerData(player)
	if not data then
		warn(string.format("[GameManager] ไม่พบข้อมูล / No data found for %s", player.Name))
		initializedPlayers[player.UserId] = nil
		return
	end

	-- ── 1. Sync attributes (ซิงค์ Attribute) ──────────────
	DataStore.SyncAttributes(player, data)

	-- ── 2. Push full stats to client (ส่งข้อมูลครั้งแรก) ──
	PushCharacterData(player)

	-- ── 3. Wait for character to load then spawn at map ───
	task.spawn(function()
		local character = player.Character or player.CharacterAdded:Wait()
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait(0.5)  -- Short delay เพื่อให้ Character settle
		SpawnPlayerAtMap(player, data.Map or "Prontera")
	end)

	-- ── 4. New player tutorial check ─────────────────────
	-- ถ้าผู้เล่นใหม่ (Novice, Lv1, TotalPlayTime == 0) → เปิด tutorial
	if data.Level == 1 and data.Class == "Novice" and data.TotalPlayTime == 0 then
		task.wait(2)  -- รอให้ client โหลดเสร็จก่อน
		RE_OpenTutorial:FireClient(player)
		print(string.format("[GameManager] เปิด Tutorial สำหรับ / Opening tutorial for: %s", player.Name))
	end

	-- ── 5. Start regen loop (เริ่ม regen HP/SP) ──────────
	StartRegenLoop(player)

	print(string.format("[GameManager] ตั้งค่าผู้เล่นเสร็จ / Player setup complete: %s (Lv.%d %s)",
		player.Name, data.Level, data.Class))
end
Players.PlayerAdded:Connect(SetupPlayer)
-- In Studio Play Solo the test player can exist before this script connects.
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(SetupPlayer, player)
end

-- ============================================================
-- PLAYER REMOVING
-- บันทึกข้อมูลเมื่อผู้เล่นออก
-- Save data and clean up on player leave
-- ============================================================
Players.PlayerRemoving:Connect(function(player)
	initializedPlayers[player.UserId] = nil
	-- หยุด regen loop
	if PlayerRegenConnections[player.UserId] then
		task.cancel(PlayerRegenConnections[player.UserId])
		PlayerRegenConnections[player.UserId] = nil
	end
	-- DataStore.server.lua จัดการ save ผ่าน PlayerRemoving เอง
	print(string.format("[GameManager] ผู้เล่นออก / Player left: %s", player.Name))
end)

-- ============================================================
-- HANDLE: DistributeStatPoint (Client → Server)
-- ผู้เล่นกดเพิ่มสตาท
-- Player spends a stat point into a chosen stat
-- ============================================================
RE_DistributeStatPoint.OnServerEvent:Connect(function(player, statNameOrTable)
	local validStats = { STR=true, AGI=true, VIT=true, INT=true, DEX=true, LUK=true }
	local data = DataStore.GetPlayerData(player)
	if not data then return end

	if statNameOrTable == "ResetStats" then
		local refunded = 0
		for st, val in pairs(data.Stats or {}) do
			for v = 1, (tonumber(val) or 1) - 1 do
				refunded += math.floor(v / 10) + 2
			end
			data.Stats[st] = 1
		end
		data.StatPoints = math.max(48, (tonumber(data.StatPoints) or 0) + refunded)
		DataStore.SyncAttributes(player, data)
		PushCharacterData(player)
		RE_SkillFeedback:FireClient(player, "รีเซ็ตค่าสเตตัสทั้งหมดสำเร็จ! คืนแต้มให้ " .. tostring(data.StatPoints) .. " แต้ม")
		return
	end

	if type(statNameOrTable) == "table" then
		local appliedAny = false
		for _, st in ipairs({"STR", "AGI", "VIT", "INT", "DEX", "LUK"}) do
			local count = math.floor(tonumber(statNameOrTable[st]) or 0)
			for _ = 1, count do
				local cur = data.Stats[st] or 1
				local cost = math.floor(cur / 10) + 2
				if data.StatPoints >= cost then
					data.StatPoints -= cost
					data.Stats[st] = cur + 1
					appliedAny = true
				else
					break
				end
			end
		end
		DataStore.SyncAttributes(player, data)
		PushCharacterData(player)
		if appliedAny then
			RE_SkillFeedback:FireClient(player, "ยืนยันการอัปสเตตัสเรียบร้อยแล้ว!")
		end
		return
	end

	local statName = statNameOrTable
	if not validStats[statName] then return end
	if data.StatPoints <= 0 then return end
	local currentStat = data.Stats[statName]
	local cost = math.floor(currentStat / 10) + 2
	if data.StatPoints < cost then return end
	data.StatPoints = data.StatPoints - cost
	data.Stats[statName] = data.Stats[statName] + 1
	DataStore.SyncAttributes(player, data)
	PushCharacterData(player)
end)

-- ============================================================
-- HANDLE: ChangeClass (Client → Server)
-- ผู้เล่นเปลี่ยนอาชีพ
-- Player changes class (must be Novice with JobLevel >= 10)
-- ============================================================
RE_ChangeClass.OnServerEvent:Connect(function(player, requestedClass)
	-- ── Input validation ─────────────────────────────────
	if not VALID_CLASSES[requestedClass] then
		warn(string.format("[GameManager] ChangeClass: Invalid class '%s' from %s", tostring(requestedClass), player.Name))
		return
	end

	local data = DataStore.GetPlayerData(player)
	if not data then return end

	-- ── ตรวจสอบเงื่อนไขการเปลี่ยนอาชีพ (1st Job หรือ 2nd Job) ──
	local canAdvance, reason = ClassData.CanChangeClass(data.Class, requestedClass, data.JobLevel or 1)
	if not canAdvance then
		RE_SkillFeedback:FireClient(player, "⚠️ ไม่สามารถเปลี่ยนอาชีพได้: " .. tostring(reason))
		return
	end

	-- ── เปลี่ยนอาชีพ ──────────────────────────────────────
	local oldClass    = data.Class
	data.Class        = requestedClass
	local isSecondJob = (ClassData.ParentClass and ClassData.ParentClass[requestedClass]) ~= nil

	local equippedWeaponId = data.Equipment and data.Equipment.Weapon
	local equippedWeapon = equippedWeaponId and ItemData[equippedWeaponId]
	if equippedWeapon and equippedWeapon.weaponType and not ClassData.CanUseWeapon(requestedClass, equippedWeapon.weaponType) then
		local refineLevel = (data.EquipmentRefine or {}).Weapon or 0
		data.Equipment.Weapon = nil
		data.EquipmentRefine.Weapon = nil
		returnEquipmentToInventory(data, equippedWeaponId, refineLevel)
	end

	-- มอบและติดตั้งอาวุธเริ่มต้นประจำอาชีพใหม่
	local starterWeaponId = ({
		Acolyte = "AcolyteTrainingMace",
		Knight = "KnightTrainingSword",
		Mage = "ApprenticeRod",
		Archer = "ArcherTrainingBow",
		Thief = "ThiefTrainingDagger",
		Merchant = "MerchantTrainingAxe",
		LordKnight = "KnightTrainingSword",
		Priest = "AcolyteTrainingMace",
		Wizard = "ApprenticeRod",
		Hunter = "ArcherTrainingBow",
		Assassin = "ThiefTrainingDagger",
		Blacksmith = "MerchantTrainingAxe",
	})[requestedClass]

	if starterWeaponId and (not data.Equipment.Weapon or not ClassData.CanUseWeapon(requestedClass, (ItemData[data.Equipment.Weapon] or {}).weaponType)) then
		data.Equipment.Weapon = starterWeaponId
		data.EquipmentRefine.Weapon = 0
	end
	data.JobLevel     = 1   -- reset Job Level เป็น 1
	data.JobXP        = 0   -- reset Job XP

	if isSecondJob then
		data.StatPoints = (data.StatPoints or 0) + 15
		data.SkillPoints = (data.SkillPoints or 0) + 1
	end
	data.SkillPoints  = data.SkillPoints + 5  -- โบนัส 5 SkillPoints ตอนเปลี่ยนอาชีพ
	local starterSkill = ({ Acolyte="Heal", Knight="Bash", Mage="FireBolt", Archer="DoubleStrafe", Thief="Envenom", Merchant="Mammonite" })[requestedClass]
	if starterSkill then data.Skills[starterSkill] = math.max(1, data.Skills[starterSkill] or 0) end

	-- ── Sync และ push ─────────────────────────────────────
	DataStore.SyncAttributes(player, data)
	PushCharacterData(player)

	print(string.format("[GameManager] %s เปลี่ยนอาชีพจาก %s → %s", player.Name, oldClass, requestedClass))
end)

-- ============================================================
-- HANDLE: UseSkill (Client → Server)
-- ผู้เล่นใช้สกิล (ส่งต่อไปยัง CombatSystem)
-- Player activates a skill — forwards to CombatSystem
-- ============================================================
RE_UseSkill.OnServerEvent:Connect(function(player, skillId, targetId)
	if type(skillId) ~= "string" then return end

	local data = DataStore.GetPlayerData(player)
	if not data then return end
	data.Skills = data.Skills or {}

	local starterMap = { Novice="NoviceStrike", Acolyte="Heal", Knight="Bash", Mage="FireBolt", Archer="DoubleStrafe", Thief="Envenom", Merchant="Mammonite" }
	if skillId == "NoviceStrike" or skillId == "FirstAid" or skillId == starterMap[data.Class] then
		data.Skills[skillId] = math.max(1, tonumber(data.Skills[skillId]) or 0)
	end

	local skillLevel = tonumber(data.Skills[skillId])
	if not skillLevel or skillLevel <= 0 then
		if RE_SkillFeedback then
			RE_SkillFeedback:FireClient(player, "ยังไม่ได้อัปสกิลนี้ — กด K หรือปุ่ม ✨ อัปสกิล เพื่อเรียนรู้สกิลก่อน!")
		end
		return
	end
	local skillInfo = _G.SkillData and _G.SkillData[skillId]
	if not skillInfo or not ClassData.CanLearnSkill(data.Class, skillInfo.class) then return end

	if player:GetAttribute("StatusSilence") then
		return
	end

	-- Check PvP Player Target
	local targetPlayer = nil
	if typeof(targetId) == "Instance" then
		targetPlayer = Players:GetPlayerFromCharacter(targetId)
	elseif type(targetId) == "string" and targetId ~= "" then
		local foundPlr = Players:FindFirstChild(targetId)
		if foundPlr and foundPlr.Character then
			targetPlayer = foundPlr
		end
	end

	if targetPlayer and targetPlayer ~= player and player:GetAttribute("InPvP") and targetPlayer:GetAttribute("InPvP") then
		if _G.PvPArenaSystem and _G.PvPArenaSystem.PlayerSkillPlayer then
			_G.PvPArenaSystem.PlayerSkillPlayer(player, targetPlayer, skillId, skillLevel)
		end
		return
	end

	if _G.CombatSystem and _G.CombatSystem.HandleSkillUse then
		_G.CombatSystem.HandleSkillUse(player, skillId, skillLevel, targetId)
	end
end)

-- ============================================================
-- HANDLE: LearnSkill (Client → Server)
-- ผู้เล่นอัปเลเวลสกิลในผัง Skill Tree ด้วย SkillPoints
-- ============================================================
RE_LearnSkill.OnServerEvent:Connect(function(player, skillId)
	if type(skillId) ~= "string" then return end
	local data = DataStore.GetPlayerData(player)
	if not data or (tonumber(data.SkillPoints) or 0) <= 0 then
		RE_SkillFeedback:FireClient(player, "แต้มสกิล (Skill Points) ไม่เพียงพอ")
		return
	end
	local skillInfo = _G.SkillData and _G.SkillData[skillId]
	if not skillInfo or not ClassData.CanLearnSkill(data.Class, skillInfo.class) then
		RE_SkillFeedback:FireClient(player, "อาชีพของคุณไม่สามารถเรียนสกิลนี้ได้")
		return
	end
	data.Skills = data.Skills or {}
	if skillInfo.prereq and (tonumber(data.Skills[skillInfo.prereq]) or 0) <= 0 and skillInfo.prereq ~= "NoviceStrike" then
		local pre = _G.SkillData[skillInfo.prereq]
		RE_SkillFeedback:FireClient(player, "ต้องเรียน " .. (pre and (pre.nameThai or pre.name) or skillInfo.prereq) .. " ก่อน")
		return
	end
	local currentLv = tonumber(data.Skills[skillId]) or 0
	local maxLv = tonumber(skillInfo.maxLevel) or 5
	if currentLv >= maxLv then
		RE_SkillFeedback:FireClient(player, "สกิลนี้อัปถึงระดับสูงสุดแล้ว (Lv." .. tostring(maxLv) .. ")")
		return
	end
	data.SkillPoints -= 1
	data.Skills[skillId] = currentLv + 1
	DataStore.SyncAttributes(player, data)
	PushCharacterData(player)
	RE_SkillFeedback:FireClient(player, string.format("อัปสกิล %s เป็น Lv.%d สำเร็จ!", skillInfo.nameThai or skillInfo.name, currentLv + 1))
end)

-- ============================================================
-- HANDLE: SocketCard & UnsocketCard (Client → Server)
-- ระบบเสียบการ์ดมอนสเตอร์ลงในรูอุปกรณ์ (Weapon / Armor)
-- ============================================================
RE_SocketCard.OnServerEvent:Connect(function(player, cardItemId)
	if type(cardItemId) ~= "string" then return end
	local data = DataStore.GetPlayerData(player)
	local cardInfo = ItemData[cardItemId]
	if not data or not cardInfo or cardInfo.type ~= "Card" then return end
	local targetSlot = cardInfo.slot or "Weapon"
	local equippedId = data.Equipment and data.Equipment[targetSlot]
	if not equippedId then
		RE_SkillFeedback:FireClient(player, "กรุณาสวมใส่อุปกรณ์ช่อง " .. targetSlot .. " ก่อนเสียบการ์ด")
		return
	end
	local invIdx
	for i, entry in ipairs(data.Inventory or {}) do
		if entry.itemId == cardItemId and (tonumber(entry.quantity) or 0) > 0 then
			invIdx = i
			break
		end
	end
	if not invIdx then return end

	data.EquipmentCards = data.EquipmentCards or {}
	local oldCard = data.EquipmentCards[targetSlot]
	if oldCard then
		DataStore.AddItem(player, oldCard, 1)
	end
	local entry = data.Inventory[invIdx]
	entry.quantity -= 1
	if entry.quantity <= 0 then table.remove(data.Inventory, invIdx) end

	data.EquipmentCards[targetSlot] = cardItemId
	DataStore.SyncAttributes(player, data)
	PushCharacterData(player)
	sendInventory(player, data, string.format("เสียบ %s ลงในช่อง %s สำเร็จ!", cardInfo.name, targetSlot))
	RE_SkillFeedback:FireClient(player, string.format("เสียบ %s ลงในช่อง %s สำเร็จ!", cardInfo.name, targetSlot))
end)

RE_UnsocketCard.OnServerEvent:Connect(function(player, slot)
	if slot ~= "Weapon" and slot ~= "Armor" then return end
	local data = DataStore.GetPlayerData(player)
	if not data or type(data.EquipmentCards) ~= "table" then return end
	local cardId = data.EquipmentCards[slot]
	if not cardId then return end
	data.EquipmentCards[slot] = nil
	DataStore.AddItem(player, cardId, 1)
	DataStore.SyncAttributes(player, data)
	PushCharacterData(player)
	local cardInfo = ItemData[cardId]
	local msg = "ถอดการ์ด " .. (cardInfo and cardInfo.name or cardId) .. " คืนเข้ากระเป๋าแล้ว"
	sendInventory(player, data, msg)
	RE_SkillFeedback:FireClient(player, msg)
end)

-- ============================================================
-- HANDLE: TeleportToMap (Client → Server)
-- เดินทางข้ามแผนที่: Prontera, PronteraCulvert, Morroc, Amatsu
-- ============================================================
RE_TeleportToMap.OnServerEvent:Connect(function(player, targetMap)
	if type(targetMap) ~= "string" or not MAP_SPAWNS[targetMap] then return end
	local data = DataStore.GetPlayerData(player)
	if not data then return end
	data.Map = targetMap
	player:SetAttribute("Map", targetMap)
	player:SetAttribute("SpawnProtectedUntil", os.clock() + 5)
	SpawnPlayerAtMap(player, targetMap)
	PushCharacterData(player)
	local mapTitles = {
		Prontera = "เมืองหลวง Prontera",
		PronteraCulvert = "ดันเจี้ยนสุสานใต้ดิน Prontera Culvert (Lv.12–20)",
		Morroc = "เมืองทะเลทราย Morroc (Lv.20–40)",
		Amatsu = "เกาะซากุระเมืองน้ำ Amatsu (Lv.35–60)",
		PvPArena = "ลานประลองเกียรติยศ Prontera PvP Arena",
	}
	RE_SkillFeedback:FireClient(player, "เดินทางสู่ " .. (mapTitles[targetMap] or targetMap))
end)

-- =========================================================================
-- [TEST ONLY / ADMIN ONLY - ลบออกหรือเปิดให้เฉพาะ Admin ก่อนเปิด Open Beta]
-- [TEST ONLY / ADMIN ONLY - REMOVE BEFORE OPEN BETA OR RESTRICT TO ADMIN]
-- ฟังก์ชันและ Remote สำหรับทดสอบเลเวลเปลี่ยนคลาส (First Class Advancement Test)
--
-- คำแนะนำสำคัญก่อนเปิด Open Beta:
-- 1. ลบ RemoteEvent 'StudioGrantJobXP' และ 'StudioResetToNovice' หรือ
-- 2. บังคับตรวจสอบสิทธิ์ Admin:
--    if player:GetAttribute("IsAdmin") ~= true then return end
-- =========================================================================
local function isTestOrAdminAllowed(player)
	if RunService:IsStudio() then
		return true
	end
	if player:GetAttribute("IsAdmin") == true then
		return true
	end
	return false
end

RE_StudioGrantJobXP.OnServerEvent:Connect(function(player)
	-- [TEST / ADMIN CHECK - ตรวจสอบสิทธิ์]
	if not isTestOrAdminAllowed(player) then
		warn(string.format("[GameManager] StudioGrantJobXP ถูกปฏิเสธสำหรับ %s (ไม่มีสิทธิ์ Admin / ไม่อยู่ใน Studio)", player.Name))
		return
	end

	local data = DataStore.GetPlayerData(player)
	if not data then return end

	-- ปรับ Job Level: Novice ถึง 10 หรือ 1st Job ถึง 50 สำหรับ 2nd Job
	local targetJobLv = (data.Class == "Novice") and 10 or 50
	if data.JobLevel < targetJobLv then
		while data.JobLevel < targetJobLv do
			data.JobLevel = data.JobLevel + 1
			data.SkillPoints = (tonumber(data.SkillPoints) or 0) + 1
		end
		data.JobXP = 0
		data.JobXP_NextLevel = math.max(50, data.JobLevel * 60)
	end

	-- ปรับ Base Level ให้ถึงอย่างน้อย Lv.10 พร้อมแจก StatPoints สำหรับทดสอบอัปสเตตัส
	if data.Level < 10 then
		while data.Level < 10 do
			data.Level = data.Level + 1
			data.StatPoints = (tonumber(data.StatPoints) or 0) + 3
		end
		data.XP = 0
		data.XP_NextLevel = math.floor(100 * (1.15 ^ (data.Level - 1)))
	end

	DataStore.SyncAttributes(player, data)
	PushCharacterData(player)
	RE_SkillFeedback:FireClient(player, "⚡ [โหมดทดสอบ] ปรับเป็น Base Lv.10 / Job Lv.10 สำเร็จ! พร้อมเปลี่ยนอาชีพขั้นที่ 1")
end)

RE_StudioResetToNovice.OnServerEvent:Connect(function(player)
	-- [TEST / ADMIN CHECK - ตรวจสอบสิทธิ์]
	if not isTestOrAdminAllowed(player) then
		warn(string.format("[GameManager] StudioResetToNovice ถูกปฏิเสธสำหรับ %s (ไม่มีสิทธิ์ Admin / ไม่อยู่ใน Studio)", player.Name))
		return
	end

	local data = DataStore.GetPlayerData(player)
	if not data then return end

	data.Class = "Novice"
	data.JobLevel = 1
	data.JobXP = 0
	data.JobXP_NextLevel = 60

	-- ปลดอาวุธที่ Novice ถือไม่ได้คืนกระเป๋า
	local equippedWeaponId = data.Equipment and data.Equipment.Weapon
	local equippedWeapon = equippedWeaponId and ItemData[equippedWeaponId]
	if equippedWeapon and equippedWeapon.weaponType and not ClassData.CanUseWeapon("Novice", equippedWeapon.weaponType) then
		local refineLevel = (data.EquipmentRefine or {}).Weapon or 0
		data.Equipment.Weapon = nil
		if data.EquipmentRefine then
			data.EquipmentRefine.Weapon = nil
		end
		returnEquipmentToInventory(data, equippedWeaponId, refineLevel)
	end

	DataStore.SyncAttributes(player, data)
	PushCharacterData(player)
	RE_SkillFeedback:FireClient(player, "⚡ [โหมดทดสอบ] รีเซ็ตกลับเป็น Novice (Job Lv.1) แล้ว! สามารถทดสอบเปลี่ยนอาชีพใหม่ได้")
end)

-- (basicAttackNextAt lifecycle unified into main PlayerRemoving)

-- ============================================================
-- HANDLE: RequestAttack (Client → Server)
-- ผู้เล่นโจมตีมอนสเตอร์
-- Player initiates a basic attack on a monster
-- ============================================================
RE_RequestAttack.OnServerEvent:Connect(function(player, monsterModelOrName)
	if not monsterModelOrName then return end

	-- ตรวจสอบว่าเป้าหมายเป็นผู้เล่นคนอื่นในโหมด PvP หรือไม่
	local targetPlayer = nil
	if typeof(monsterModelOrName) == "Instance" then
		targetPlayer = Players:GetPlayerFromCharacter(monsterModelOrName)
	elseif type(monsterModelOrName) == "string" then
		local foundPlr = Players:FindFirstChild(monsterModelOrName)
		if foundPlr and foundPlr.Character then
			targetPlayer = foundPlr
		end
	end

	if targetPlayer and targetPlayer ~= player and player:GetAttribute("InPvP") and targetPlayer:GetAttribute("InPvP") then
		if _G.PvPArenaSystem and _G.PvPArenaSystem.PlayerAttackPlayer then
			_G.PvPArenaSystem.PlayerAttackPlayer(player, targetPlayer)
		end
		return
	end

	-- ค้นหา monster model ใน Workspace (รองรับทั้ง instance และ string name)
	local monster = nil
	if typeof(monsterModelOrName) == "Instance" and monsterModelOrName:IsDescendantOf(Workspace) then
		monster = monsterModelOrName
	else
		local monsterModelName = tostring(monsterModelOrName)
		for _, map in ipairs(Workspace:GetChildren()) do
			if map:IsA("Model") or map:IsA("Folder") then
				local monstersFolder = map:FindFirstChild("Monsters")
				if monstersFolder then
					monster = monstersFolder:FindFirstChild(monsterModelName)
					if monster then break end
				end
			end
		end

		if not monster then
			monster = Workspace:FindFirstChild(monsterModelName, true)
		end

		if not monster then
			warn(string.format("[GameManager] RequestAttack: ไม่พบ monster '%s' จาก %s", monsterModelName, player.Name))
			return
		end
	end

	-- ตรวจสอบว่า monster ยังมีชีวิตอยู่
	local monsterHP = monster:GetAttribute("HP")
	if not monsterHP or monsterHP <= 0 then return end
	local character = player.Character
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	local monsterRoot = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart
	local attackRange = ClassData.GetBasicAttackRange(player:GetAttribute("Class") or "Novice")
	if not playerRoot or not monsterRoot or (playerRoot.Position - monsterRoot.Position).Magnitude > attackRange then return end
	local now = os.clock()
	if now < (basicAttackNextAt[player.UserId] or 0) then return end
	local attacksPerMinute = math.clamp(player:GetAttribute("ASPD") or 100, 60, 190)
	basicAttackNextAt[player.UserId] = now + (60 / attacksPerMinute)

	-- ส่งต่อไปยัง CombatSystem
	if _G.CombatSystem and _G.CombatSystem.PlayerAttackMonster then
		_G.CombatSystem.PlayerAttackMonster(player, monster, nil)  -- nil = basic attack
	end
end)

-- ============================================================
-- CHARACTER ADDED (handle respawn)
-- เมื่อ Character ถูกสร้างใหม่ (respawn)
-- Re-teleport player to their current map on respawn
-- ============================================================
-- (BindCharacterRespawn moved above SetupPlayer for unified lifecycle)

-- ============================================================
-- EXPOSE PUBLIC API FOR OTHER SCRIPTS
-- ============================================================
_G.PushCharacterData = PushCharacterData
_G.GameManager = {
	PushCharacterData = PushCharacterData,
	SpawnPlayerAtMap  = SpawnPlayerAtMap,
	StartRegenLoop    = StartRegenLoop,
}

print("[GameManager] GameManager.server.lua โหลดเสร็จ / Loaded OK")
