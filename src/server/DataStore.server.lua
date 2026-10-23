-- ============================================================

-- DataStore.server.lua

-- ServerScriptService — RoROK (Ragnarok Online-inspired MMORPG)

-- ============================================================

-- จัดการบันทึกและโหลดข้อมูลผู้เล่นด้วย DataStoreService

-- Manages player data saving and loading with DataStoreService

-- ============================================================



local Players            = game:GetService("Players")

local DataStoreService   = game:GetService("DataStoreService")

local RunService         = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassData = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("ClassData"))

local ItemData = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("ItemData"))



-- ── DataStore key ──────────────────────────────────────────

local PLAYER_DATA_STORE_NAME = "RoROK_PlayerData_v1"

local PlayerDataStore

local storeOK, storeOrError = pcall(function()

	return DataStoreService:GetDataStore(PLAYER_DATA_STORE_NAME)

end)

if storeOK then

	PlayerDataStore = storeOrError

else

	warn("[DataStore] Persistent saves unavailable; this session will use temporary in-memory data: " .. tostring(storeOrError))

end



-- ── Constants ──────────────────────────────────────────────

local AUTO_SAVE_INTERVAL = 60  -- วินาที / seconds

local MAX_LEVEL          = 99

local MAX_JOB_LEVEL      = 50



-- ============================================================

-- XP TABLE (Level 1 → 99)

-- level 1 ต้องการ 100 XP, แต่ละระดับต้องการ floor(prevXP * 1.15)

-- level 1 needs 100 XP; each subsequent level needs floor(prevXP*1.15)

-- ============================================================

local XP_TABLE = {}  -- XP_TABLE[level] = XP required to reach level+1

do

	local xp = 100

	for lvl = 1, MAX_LEVEL do

		XP_TABLE[lvl] = xp

		xp = math.floor(xp * 1.15)

	end

end



-- ============================================================

-- DEFAULT PLAYER DATA FACTORY

-- สร้างข้อมูลผู้เล่นใหม่เมื่อไม่มีข้อมูลใน DataStore

-- Returns a fresh PlayerData table for brand-new players

-- ============================================================

local function NewPlayerData(player)

	return {

		Name         = player.Name,

		Level        = 1,

		JobLevel     = 1,

		XP           = 0,

		JobXP        = 0,

		XP_NextLevel = XP_TABLE[1],  -- 100 XP สำหรับเลเวล 1->2

		Class        = "Novice",

		Stats = {

			STR = 1,

			AGI = 1,

			VIT = 1,

			INT = 1,

			DEX = 1,

			LUK = 1,

		},

		StatPoints  = 48,  -- สตาทพอยต์เริ่มต้น

		SkillPoints = 2,   -- แต้มสกิลเริ่มต้น

		Skills      = { NoviceStrike = 1, FirstAid = 1 },  -- starter skills

		HP          = 415,  -- HP เริ่มต้น Novice

		SP          = 105,  -- SP เริ่มต้น Novice

		Gold        = 500,

		Inventory   = {

			{ itemId = "NoviceTrainingDagger", quantity = 1 },

			{ itemId = "ApprenticeRod", quantity = 1 },

			{ itemId = "AcolyteTrainingMace", quantity = 1 },

			{ itemId = "KnightTrainingSword", quantity = 1 },

			{ itemId = "ArcherTrainingBow", quantity = 1 },

			{ itemId = "ThiefTrainingDagger", quantity = 1 },

			{ itemId = "MerchantTrainingAxe", quantity = 1 },

			{ itemId = "NoviceClothes", quantity = 1 },

			{ itemId = "BeginnerRefinementStone", quantity = 20 },

			{ itemId = "FireScroll", quantity = 3 },

			{ itemId = "HolyScroll", quantity = 3 },

			{ itemId = "Panacea", quantity = 3 },

			{ itemId = "PoringCard", quantity = 1 },

			{ itemId = "WolfCard", quantity = 1 },

		},  -- { {itemId, quantity, enhancement, slots, enchant} }

		StarterEquipmentKitGranted = true,

		StarterRefinementStonesGranted = true,

		StarterPhase2KitGranted = true,

		Equipment   = {

			HeadTop    = nil,

			Armor      = nil,

			Shield     = nil,

			Robe       = nil,

			Footgear   = nil,

			Accessory1 = nil,

			Accessory2 = nil,

			Weapon     = nil,

		},

		EquipmentRefine = {},

		EquipmentCards  = {},

		Map          = "Prontera",

		Teleports    = { "Prontera" },  -- Prontera ปลดล็อคตั้งแต่ต้น

		GuildId      = nil,

		PartyId      = nil,

		DailyQuests  = {

			-- Keep the stored quest date aligned with the server's Thailand-day reset.

			date      = os.date("!%Y-%m-%d", os.time() + 7 * 60 * 60),

			active    = {},

			progress  = {},

			claimed   = {},

		},

		CompletedStoryQuests = {}, -- One-Time per Account

		ActiveStoryQuests    = {},

		DeathCount      = 0,

		TotalPlayTime   = 0,

		CreatedAt       = os.time(),

	}

end



-- ============================================================

-- DERIVED STAT CALCULATOR

-- คำนวณค่าสถิติที่ได้รับจาก Primary Stats

-- Calculates MaxHP, MaxSP, ATK, MATK, DEF, MDEF, HIT, FLEE, Crit

-- ============================================================

local function CalcDerivedStats(data)

	local s = table.clone(data.Stats)

	local equipmentBonuses = { ATK = 0, MATK = 0, DEF = 0, MDEF = 0, MaxHP = 0, MaxSP = 0 }

	for slot, itemId in pairs(data.Equipment or {}) do

		local item = ItemData[itemId]

		for stat, amount in pairs(item and item.bonuses or {}) do

			if s[stat] ~= nil then s[stat] += amount

			elseif equipmentBonuses[stat] ~= nil then equipmentBonuses[stat] += amount end

		end

		local refineLevel = math.clamp(math.floor(tonumber((data.EquipmentRefine or {})[slot]) or 0), 0, 15)

		if slot == "Weapon" then equipmentBonuses.ATK += refineLevel

		elseif slot == "Armor" then equipmentBonuses.DEF += refineLevel end



		-- โบนัสจากการ์ดมอนสเตอร์ที่เสียบอยู่ในช่องอุปกรณ์ (Card Slotting)

		local cardId = (data.EquipmentCards or {})[slot]

		local cardItem = cardId and ItemData[cardId]

		if cardItem and cardItem.type == "Card" then

			for stat, amount in pairs(cardItem.bonuses or {}) do

				if s[stat] ~= nil then s[stat] += amount

				elseif equipmentBonuses[stat] ~= nil then equipmentBonuses[stat] += amount end

			end

		end

	end



	-- โบนัสจากสกิลบัพชั่วคราว (Blessing, Provoke, Endure, ImproveConcentration, CrazyUproar)

	for stat, amount in pairs(data._ActiveBuffs or {}) do

		if s[stat] ~= nil then s[stat] += amount

		elseif equipmentBonuses[stat] ~= nil then equipmentBonuses[stat] += amount end

	end



	-- โบนัสจากบ้านกิลด์ (Guild House Buffs)

	if data.GuildId and data.GuildId ~= "" and _G.GuildSystem and _G.GuildSystem.GetGuildBonuses then

		local gBonuses = _G.GuildSystem.GetGuildBonuses(data.GuildId)

		for stat, amount in pairs(gBonuses or {}) do

			if s[stat] ~= nil then s[stat] += amount

			elseif equipmentBonuses[stat] ~= nil then equipmentBonuses[stat] += amount end

		end

	end



	-- ผลของสถานะคำสาป (Curse: ลด STR/AGI/DEX 50%)

	if data._StatusCurse then

		s.STR = math.max(1, math.floor(s.STR * 0.5))

		s.AGI = math.max(1, math.floor(s.AGI * 0.5))

		s.DEX = math.max(1, math.floor(s.DEX * 0.5))

	end



	local level = data.Level



	local derived = ClassData.CalculateDerivedStats(
		data.Class or "Novice",
		level,
		s.STR, s.AGI, s.VIT, s.INT, s.DEX, s.LUK,
		equipmentBonuses
	)

	if not derived then
		derived = {
			MaxHP        = 415,
			MaxSP        = 105,
			ATK          = 29,
			MATK_min     = 18,
			MATK_max     = 22,
			DEF          = 12,
			MDEF         = 7,
			HIT          = 22,
			FLEE         = 12,
			ASPD         = 104,
			CritRate     = 1,
			PerfectDodge = 0,
			MaxWeight    = 230,
			HPRegen      = 1,
			SPRegen      = 1.05,
			MoveSpeed    = 10,
		}
	end

	if data._StatusCurse then
		derived.MaxHP = math.max(10, math.floor(derived.MaxHP * 0.75))
	end

	return derived


end



-- ============================================================

-- ATTRIBUTE SYNC

-- ส่งค่า Attribute ไปยัง Player object เพื่อให้ Client อ่านได้

-- Pushes key stats as Attributes on the Player for client replication

-- ============================================================

local function SyncAttributes(player, data)

	local derived = CalcDerivedStats(data)



	-- Cap HP/SP ไม่ให้เกิน Max

	data.HP = math.min(data.HP, derived.MaxHP)

	data.SP = math.min(data.SP, derived.MaxSP)



	-- Character identity

	data.JobXP_NextLevel = math.max(50, (tonumber(data.JobLevel) or 1) * 60)

	player:SetAttribute("Level",           data.Level)

	player:SetAttribute("JobLevel",        data.JobLevel)

	player:SetAttribute("Class",           data.Class)

	player:SetAttribute("XP",              data.XP)

	player:SetAttribute("JobXP",           data.JobXP)

	player:SetAttribute("XP_NextLevel",    data.XP_NextLevel)

	player:SetAttribute("JobXP_NextLevel", data.JobXP_NextLevel)

	player:SetAttribute("StatPoints",      data.StatPoints)

	player:SetAttribute("SkillPoints",     data.SkillPoints)



	-- Primary stats

	player:SetAttribute("STR", data.Stats.STR)

	player:SetAttribute("AGI", data.Stats.AGI)

	player:SetAttribute("VIT", data.Stats.VIT)

	player:SetAttribute("INT", data.Stats.INT)

	player:SetAttribute("DEX", data.Stats.DEX)

	player:SetAttribute("LUK", data.Stats.LUK)



	-- HP / SP (current & max)

	player:SetAttribute("HP",    data.HP)

	player:SetAttribute("MaxHP", derived.MaxHP)

	player:SetAttribute("SP",    data.SP)

	player:SetAttribute("MaxSP", derived.MaxSP)



	-- Combat derived stats

	player:SetAttribute("ATK",          derived.ATK)

	player:SetAttribute("MATK_min",     derived.MATK_min)

	player:SetAttribute("MATK_max",     derived.MATK_max)

	player:SetAttribute("DEF",          derived.DEF)

	player:SetAttribute("MDEF",         derived.MDEF)

	player:SetAttribute("HIT",          derived.HIT)

	player:SetAttribute("FLEE",         derived.FLEE)

	player:SetAttribute("CritRate",     derived.CritRate)

	player:SetAttribute("PerfectDodge", derived.PerfectDodge)

	player:SetAttribute("HPRegen",      derived.HPRegen)

	player:SetAttribute("SPRegen",      derived.SPRegen)

	player:SetAttribute("ASPD",         derived.ASPD)



	-- Economy & social

	player:SetAttribute("Gold",       data.Gold)

	player:SetAttribute("Map",        data.Map)

	player:SetAttribute("GuildId",    data.GuildId or "")

	-- Party membership is session-only. Preserve the live attribute here because

	-- SyncAttributes is called on every XP/stat update during a session.

	player:SetAttribute("PartyId",    player:GetAttribute("PartyId") or "")

	player:SetAttribute("DeathCount", data.DeathCount)



	return derived

end



-- ============================================================

-- SAVE PLAYER DATA

-- บันทึกข้อมูลผู้เล่นลง DataStore (ใช้ pcall)

-- Serializes and saves player data to DataStore safely

-- ============================================================

local function SavePlayer(player, data)

	if not player or not data then

		warn("[DataStore] SavePlayer: ข้อมูลไม่ครบ / missing player or data")

		return false

	end

	if not PlayerDataStore then return false end



	local key = "Player_" .. player.UserId

	local toSave = table.clone(data)

	toSave._ActiveBuffs = nil

	toSave._StatusCurse = nil



	local success, err

	for attempt = 1, 3 do

		success, err = pcall(function()

			PlayerDataStore:SetAsync(key, toSave)

		end)

		if success then break end

		if attempt < 3 then

			task.wait(attempt * 1.0)

		end

	end



	if success then

		print(string.format("[DataStore] บันทึกสำเร็จ / Saved: %s (UserId: %d)", player.Name, player.UserId))

	else

		warn(string.format("[DataStore] บันทึกล้มเหลว / Save failed for %s: %s", player.Name, tostring(err)))

	end



	return success

end



-- ============================================================

-- LOAD PLAYER DATA

-- โหลดข้อมูลผู้เล่นจาก DataStore หรือสร้างใหม่ถ้ายังไม่มี

-- Loads player data, returning (data, isNewPlayer)

-- ============================================================

local function LoadPlayer(player)

	if not PlayerDataStore then

		return NewPlayerData(player), true

	end

	local key = "Player_" .. player.UserId

	local success, result = pcall(function()

		return PlayerDataStore:GetAsync(key)

	end)



	if not success then

		warn(string.format("[DataStore] โหลดล้มเหลว / Load failed for %s: %s", player.Name, tostring(result)))

		return NewPlayerData(player), false

	end



	if result == nil then

		-- ผู้เล่นใหม่

		print(string.format("[DataStore] ผู้เล่นใหม่ / New player: %s", player.Name))

		return NewPlayerData(player), true

	end



	-- Data migration: เพิ่มฟิลด์ใหม่ที่ขาดหายไป

	local defaults = NewPlayerData(player)

	local hadStarterEquipmentKit = result.StarterEquipmentKitGranted == true

	local hadStarterRefinementStones = result.StarterRefinementStonesGranted == true

	local hadStarterPhase2Kit = result.StarterPhase2KitGranted == true

	for k, v in pairs(defaults) do

		if result[k] == nil then result[k] = v end

	end

	-- Old builds could save a party ID; never carry a party across sessions.

	result.PartyId = nil

	if not result.Stats    then result.Stats    = defaults.Stats    end

	if not result.Skills   then result.Skills   = {}                end

	result.Skills.NoviceStrike = math.max(1, tonumber(result.Skills.NoviceStrike) or 0)

	result.Skills.FirstAid     = math.max(1, tonumber(result.Skills.FirstAid) or 0)

	local starterSkillByClass = { Acolyte = "Heal", Knight = "Bash", Mage = "FireBolt", Archer = "DoubleStrafe", Thief = "Envenom", Merchant = "Mammonite" }

	local classStarter = starterSkillByClass[result.Class]

	if classStarter then result.Skills[classStarter] = math.max(1, tonumber(result.Skills[classStarter]) or 0) end

	if not result.SkillPointsBonusGranted then

		result.SkillPoints = (tonumber(result.SkillPoints) or 0) + 3

		result.SkillPointsBonusGranted = true

	end

	result.JobXP_NextLevel = math.max(50, (tonumber(result.JobLevel) or 1) * 60)

	if type(result.Inventory) ~= "table" then result.Inventory = {} end

	if type(result.Equipment) ~= "table" then result.Equipment = table.clone(defaults.Equipment) end

	if type(result.EquipmentRefine) ~= "table" then result.EquipmentRefine = {} end

	if type(result.EquipmentCards) ~= "table" then result.EquipmentCards = {} end

	if not hadStarterEquipmentKit then

		for _, starterEntry in ipairs(defaults.Inventory) do table.insert(result.Inventory, table.clone(starterEntry)) end

		result.StarterEquipmentKitGranted = true

		result.StarterRefinementStonesGranted = true

		result.StarterPhase2KitGranted = true

	elseif not hadStarterPhase2Kit then

		result.SkillPoints = (tonumber(result.SkillPoints) or 0) + 2

		for _, extra in ipairs({

			{ itemId = "FireScroll", quantity = 3 },

			{ itemId = "HolyScroll", quantity = 3 },

			{ itemId = "Panacea", quantity = 3 },

			{ itemId = "PoringCard", quantity = 1 },

			{ itemId = "WolfCard", quantity = 1 },

		}) do

			table.insert(result.Inventory, table.clone(extra))

		end

		result.StarterPhase2KitGranted = true

	end

	if not hadStarterRefinementStones then

		if hadStarterEquipmentKit then

			local foundStone = false

			for _, entry in ipairs(result.Inventory) do

				if entry.itemId == "BeginnerRefinementStone" then entry.quantity = (tonumber(entry.quantity) or 0) + 20; foundStone = true; break end

			end

			if not foundStone then table.insert(result.Inventory, { itemId = "BeginnerRefinementStone", quantity = 20 }) end

		end

		result.StarterRefinementStonesGranted = true

	end

	local savedWeapon = result.Equipment.Weapon

	local savedWeaponInfo = ItemData[savedWeapon]

	if savedWeaponInfo and savedWeaponInfo.weaponType and not ClassData.CanUseWeapon(result.Class, savedWeaponInfo.weaponType) then

		result.Equipment.Weapon = nil

		local refineLevel = tonumber((result.EquipmentRefine or {}).Weapon) or 0

		result.EquipmentRefine.Weapon = nil

		local returned = false

		for _, entry in ipairs(result.Inventory) do

			if entry.itemId == savedWeapon and (tonumber(entry.enhancement) or 0) == refineLevel then entry.quantity = (tonumber(entry.quantity) or 0) + 1; returned = true; break end

		end

		if not returned then table.insert(result.Inventory, { itemId = savedWeapon, quantity = 1, enhancement = refineLevel }) end

		warn(string.format("[DataStore] Returned incompatible saved weapon %s to %s's inventory", savedWeapon, player.Name))

	end

	if not result.Teleports then result.Teleports = { "Prontera" } end

	-- Migrate legacy daily quest saves to the current per-quest state shape.

	if type(result.DailyQuests) ~= "table" then

		result.DailyQuests = defaults.DailyQuests

	else

		local quests = result.DailyQuests

		if type(quests.active) ~= "table" then quests.active = {} end

		if type(quests.progress) ~= "table" then quests.progress = {} end

		if type(quests.claimed) ~= "table" then

			-- Older saves used a single boolean; it cannot identify which quest

			-- was claimed, so reset that legacy flag into the current structure.

			quests.claimed = {}

		end

	end

	if type(result.CompletedStoryQuests) ~= "table" then result.CompletedStoryQuests = {} end

	if type(result.ActiveStoryQuests) ~= "table" then result.ActiveStoryQuests = {} end



	-- Refresh XP_NextLevel & JobXP_NextLevel

	if result.Level >= 1 and result.Level <= MAX_LEVEL then

		result.XP_NextLevel = XP_TABLE[result.Level]

	end

	result.JobXP_NextLevel = math.max(50, (tonumber(result.JobLevel) or 1) * 60)



	-- Ensure starter skills and test StatPoints are available

	result.Skills = type(result.Skills) == "table" and result.Skills or {}

	result.Skills.NoviceStrike = math.max(1, tonumber(result.Skills.NoviceStrike) or 0)

	result.Skills.FirstAid = math.max(1, tonumber(result.Skills.FirstAid) or 0)

	local starterMap = { Acolyte="Heal", Knight="Bash", Mage="FireBolt", Archer="DoubleStrafe", Thief="Envenom", Merchant="Mammonite" }

	local starterSkill = starterMap[result.Class]

	if starterSkill then

		result.Skills[starterSkill] = math.max(1, tonumber(result.Skills[starterSkill]) or 0)

	end

	if not result.StatPointsBonusV2 then

		result.StatPoints = (tonumber(result.StatPoints) or 0) + 24

		result.StatPointsBonusV2 = true

	end



	local derived = CalcDerivedStats(result)
	if not result.HP or result.HP <= 50 then
		result.HP = derived.MaxHP
		result.SP = derived.MaxSP
	end

	print(string.format("[DataStore] โหลดสำเร็จ / Loaded: %s (Lv.%d %s)", player.Name, result.Level, result.Class))

	return result, false

end



-- ============================================================

-- SESSION CACHE

-- เก็บข้อมูลผู้เล่นใน memory ระหว่าง session

-- ============================================================

local PlayerDataCache   = {}  -- [userId] = data table

local SessionStartTimes = {}  -- [userId] = tick()



local function GetPlayerData(player)

	return PlayerDataCache[player.UserId]

end



-- ============================================================

-- LEVEL-UP / JOB LEVEL-UP HELPERS

-- ============================================================

local function CheckLevelUp(player, data)

	local leveledUp = false

	while data.Level < MAX_LEVEL and data.XP >= XP_TABLE[data.Level] do

		data.XP          = data.XP - XP_TABLE[data.Level]

		data.Level        = data.Level + 1

		data.StatPoints   = data.StatPoints + 3

		data.SkillPoints  = data.SkillPoints + 1

		data.XP_NextLevel = (data.Level <= MAX_LEVEL) and XP_TABLE[data.Level] or 0

		leveledUp         = true

		print(string.format("[DataStore] %s LEVEL UP! -> Lv.%d", player.Name, data.Level))

	end

	return leveledUp

end



local function CheckJobLevelUp(player, data)

	local jobedUp = false

	while data.JobLevel < MAX_JOB_LEVEL do

		local needed = math.max(50, data.JobLevel * 60)

		if data.JobXP >= needed then

			data.JobXP           = data.JobXP - needed

			data.JobLevel        = data.JobLevel + 1

			data.SkillPoints     = (tonumber(data.SkillPoints) or 0) + 1

			data.JobXP_NextLevel = math.max(50, data.JobLevel * 60)

			jobedUp              = true

			print(string.format("[DataStore] %s JOB LEVEL UP! -> JLv.%d (SkillPoints=%d)", player.Name, data.JobLevel, data.SkillPoints))

		else

			break

		end

	end

	data.JobXP_NextLevel = math.max(50, (tonumber(data.JobLevel) or 1) * 60)

	return jobedUp

end



-- ============================================================

-- XP / HP / SP / GOLD MUTATION UTILITIES

-- ============================================================

local function AddXP(player, xpAmount, jobXPAmount)

	local data = PlayerDataCache[player.UserId]

	if not data then return false, false end

	data.XP    = data.XP + (xpAmount or 0)

	data.JobXP = data.JobXP + (jobXPAmount or 0)

	local lvlUp = CheckLevelUp(player, data)

	local jobUp = CheckJobLevelUp(player, data)

	SyncAttributes(player, data)

	return lvlUp, jobUp

end



local function SetHP(player, newHP)

	local data = PlayerDataCache[player.UserId]

	if not data then return end

	local derived = CalcDerivedStats(data)

	data.HP = math.max(0, math.min(newHP, derived.MaxHP))

	player:SetAttribute("HP", data.HP)

end



local function SetSP(player, newSP)

	local data = PlayerDataCache[player.UserId]

	if not data then return end

	local derived = CalcDerivedStats(data)

	data.SP = math.max(0, math.min(newSP, derived.MaxSP))

	player:SetAttribute("SP", data.SP)

end



local function ModifyGold(player, amount)

	local data = PlayerDataCache[player.UserId]

	if not data then return false end

	if data.Gold + amount < 0 then return false end

	data.Gold = math.max(0, data.Gold + amount)

	player:SetAttribute("Gold", data.Gold)

	return true

end



local function AddItem(player, itemId, quantity)

	local data = PlayerDataCache[player.UserId]

	quantity = math.floor(tonumber(quantity) or 0)

	if not data or type(itemId) ~= "string" or itemId == "" or quantity < 1 then

		return false

	end

	data.Inventory = data.Inventory or {}

	for _, entry in ipairs(data.Inventory) do

		-- Only stack onto unrefined (+0) entries so a crafted/dropped item never merges

		-- into a refined stack of the same itemId (that would give a free +N).

		if type(entry) == "table" and entry.itemId == itemId and (tonumber(entry.enhancement) or 0) == 0 then

			entry.quantity = (tonumber(entry.quantity) or 0) + quantity

			return true, data.Inventory

		end

	end

	table.insert(data.Inventory, { itemId = itemId, quantity = quantity })

	return true, data.Inventory

end




local function SavePlayerData(player)
	local data = PlayerDataCache[player.UserId]
	if data then
		return SavePlayer(player, data)
	end
	return false
end

local function HasItem(player, itemId, quantity)
	local data = PlayerDataCache[player.UserId]
	quantity = math.floor(tonumber(quantity) or 1)
	if not data or not data.Inventory or type(itemId) ~= "string" then return false, 0 end
	local altId = (itemId == "StickyMucus" and "Sticky_Mucus") or (itemId == "Sticky_Mucus" and "StickyMucus")
	           or (itemId == "IronOre" and "Iron_Ore") or (itemId == "Iron_Ore" and "IronOre") or itemId
	local count = 0
	for _, entry in ipairs(data.Inventory) do
		if type(entry) == "table" and (entry.itemId == itemId or entry.itemId == altId) then
			count = count + (tonumber(entry.quantity) or 1)
		end
	end
	return count >= quantity, count
end

local function RemoveItem(player, itemId, quantity)
	local data = PlayerDataCache[player.UserId]
	quantity = math.floor(tonumber(quantity) or 0)
	if not data or type(itemId) ~= "string" or itemId == "" or quantity < 1 then
		return false, 0
	end
	data.Inventory = data.Inventory or {}
	local altId = (itemId == "StickyMucus" and "Sticky_Mucus") or (itemId == "Sticky_Mucus" and "StickyMucus")
	           or (itemId == "IronOre" and "Iron_Ore") or (itemId == "Iron_Ore" and "IronOre") or itemId
	local remaining = quantity
	for idx = #data.Inventory, 1, -1 do
		local entry = data.Inventory[idx]
		if type(entry) == "table" and (entry.itemId == itemId or entry.itemId == altId) then
			local take = math.min(remaining, tonumber(entry.quantity) or 1)
			entry.quantity = (tonumber(entry.quantity) or 1) - take
			remaining = remaining - take
			if entry.quantity <= 0 then
				table.remove(data.Inventory, idx)
			end
			if remaining <= 0 then break end
		end
	end
	local removed = quantity - remaining
	return removed > 0, removed, data.Inventory
end

-- ============================================================

-- PLAYER ADDED

-- ============================================================

local loadingPlayers = {}

local function OnPlayerAdded(player)

	if loadingPlayers[player.UserId] or PlayerDataCache[player.UserId] then return end

	loadingPlayers[player.UserId] = true

	print(string.format("[DataStore] กำลังโหลดข้อมูล / Loading: %s", player.Name))

	SessionStartTimes[player.UserId] = tick()



	local data, isNewPlayer = LoadPlayer(player)

	PlayerDataCache[player.UserId]  = data



	local derived = SyncAttributes(player, data)



	if isNewPlayer then

		SavePlayer(player, data)

	end



	-- Signal to GameManager that data is ready

	player:SetAttribute("_DataReady",    true)

	player:SetAttribute("_IsNewPlayer",  isNewPlayer)



	print(string.format("[DataStore] พร้อม / Ready: %s | MaxHP=%d MaxSP=%d",

		player.Name, derived.MaxHP, derived.MaxSP))

end

Players.PlayerAdded:Connect(OnPlayerAdded)

-- In Studio Play Solo the test player can exist before this script connects.

for _, player in ipairs(Players:GetPlayers()) do

	task.spawn(OnPlayerAdded, player)

end



-- ============================================================

-- PLAYER REMOVING

-- ============================================================

Players.PlayerRemoving:Connect(function(player)

	loadingPlayers[player.UserId] = nil

	local data = PlayerDataCache[player.UserId]

	if data then

		local sessionStart = SessionStartTimes[player.UserId]

		if sessionStart then

			data.TotalPlayTime = data.TotalPlayTime + math.floor(tick() - sessionStart)

		end

		SavePlayer(player, data)

		PlayerDataCache[player.UserId]   = nil

		SessionStartTimes[player.UserId] = nil

	end

end)



-- ============================================================

-- AUTO-SAVE LOOP (ทุก 60 วินาที / every 60 seconds)

-- ============================================================

task.spawn(function()

	while true do

		task.wait(AUTO_SAVE_INTERVAL)

		local list = Players:GetPlayers()

		for idx, player in ipairs(list) do

			local data = PlayerDataCache[player.UserId]

			if data then

				local s = SessionStartTimes[player.UserId]

				if s then

					data.TotalPlayTime = data.TotalPlayTime + math.floor(tick() - s)

					SessionStartTimes[player.UserId] = tick()

				end

				SavePlayer(player, data)

			end

			if idx < #list then

				task.wait(1.5) -- Staggered save to avoid throttling DataStore budget

			end

		end

		print(string.format("[DataStore] Auto-save สำเร็จ / Saved %d players", #list))

	end

end)



-- ============================================================

-- GLOBAL API (_G.DataStore)

-- เปิดให้ server scripts อื่นเรียกใช้ฟังก์ชัน

-- ============================================================

_G.DataStore = {

	SavePlayer       = SavePlayer,

	LoadPlayer       = LoadPlayer,

	GetPlayerData    = GetPlayerData,

	CalcDerivedStats = CalcDerivedStats,

	SyncAttributes   = SyncAttributes,

	XP_TABLE         = XP_TABLE,

	AddXP            = AddXP,

	CheckLevelUp     = CheckLevelUp,

	CheckJobLevelUp  = CheckJobLevelUp,

	SetHP            = SetHP,

	SetSP            = SetSP,

	ModifyGold       = ModifyGold,

	AddItem          = AddItem,
	RemoveItem       = RemoveItem,
	HasItem          = HasItem,
	SavePlayerData   = SavePlayerData,

	MAX_LEVEL        = MAX_LEVEL,

	MAX_JOB_LEVEL    = MAX_JOB_LEVEL,

}




-- Bindables for robust inter-script communication
local function getOrCreateBF(name)
	local bf = script:FindFirstChild(name)
	if not bf then
		bf = Instance.new("BindableFunction")
		bf.Name = name
		bf.Parent = script
	end
	return bf
end

local BF_AddItem = getOrCreateBF("AddItem")
BF_AddItem.OnInvoke = function(player, itemId, qty)
	return AddItem(player, itemId, qty)
end

local BF_RemoveItem = getOrCreateBF("RemoveItem")
BF_RemoveItem.OnInvoke = function(player, itemId, qty)
	return RemoveItem(player, itemId, qty)
end

local BF_HasItem = getOrCreateBF("HasItem")
BF_HasItem.OnInvoke = function(player, itemId, qty)
	return HasItem(player, itemId, qty)
end

local BF_GetPlayerData = getOrCreateBF("GetPlayerData")
BF_GetPlayerData.OnInvoke = function(player)
	return GetPlayerData(player)
end

print("[DataStore] DataStore.server.lua โหลดเสร็จ / Loaded OK")

print(string.format("[DataStore] XP Lv1->2: %d | Lv50->51: %d | Lv98->99: %d",

	XP_TABLE[1], XP_TABLE[50], XP_TABLE[98]))