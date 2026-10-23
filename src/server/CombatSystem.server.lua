-- ============================================================

-- CombatSystem.server.lua

-- ServerScriptService — RoROK (Ragnarok Online-inspired MMORPG)

-- ============================================================

-- ระบบต่อสู้: ดาเมจ, hit/miss, critical, status effects,

-- ฆ่ามอนสเตอร์, แจก XP/drop ไอเทม

-- Combat system: damage formulas, hit/miss, crits, status effects,

-- monster killing, XP awards, item drops

-- ============================================================

local Players           = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Workspace         = game:GetService("Workspace")

local RunService        = game:GetService("RunService")

local GameData = ReplicatedStorage:WaitForChild("GameData")

local SkillData = require(GameData:WaitForChild("SkillData"))

local MonsterData = require(GameData:WaitForChild("MonsterData"))

local ItemData = require(GameData:WaitForChild("ItemData"))

local ClassData = require(GameData:WaitForChild("ClassData"))

_G.SkillData = SkillData

_G.MonsterData = MonsterData

_G.ItemData = ItemData

-- ============================================================

-- WAIT FOR DEPENDENCIES

-- รอให้ DataStore และ GameManager พร้อม

-- ============================================================

local DataStore

local Remotes

local DS_WAIT = tick()

repeat task.wait(0.1) DataStore = _G.DataStore; Remotes = _G.Remotes

until (DataStore and Remotes) or (tick() - DS_WAIT > 15)

if not DataStore or not Remotes then

	error("[CombatSystem] FATAL: DataStore หรือ Remotes ไม่พร้อม / not available")

end

print("[CombatSystem] Dependencies พร้อม / Dependencies ready")

local COMBAT_VFX_MAX_DISTANCE = 120

local function FireNearbyClients(remote, position, ...)

	if not remote then return end

	for _, plr in ipairs(Players:GetPlayers()) do

		local char = plr.Character

		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		if hrp and (hrp.Position - position).Magnitude <= COMBAT_VFX_MAX_DISTANCE then

			remote:FireClient(plr, position, ...)

		end

	end

end

-- ============================================================

-- ELEMENT CHART (ตารางธาตุ)

-- มัลติพลายเออร์สำหรับแต่ละคู่ (ธาตุโจมตี, ธาตุป้องกัน)

-- Elemental multiplier table: [attackElement][defendElement]

-- ============================================================

local ElementMultiplier = {

	--        Neutral  Fire  Water  Wind  Earth  Holy  Shadow  Ghost  Undead

	Neutral = { 1.0,  1.0,  1.0,  1.0,  1.0,  1.0,   1.0,   0.25,  1.0   },

	Fire    = { 1.0,  0.5,  0.5,  2.0,  1.0,  1.0,   1.0,   0.0,   1.5   },

	Water   = { 1.0,  2.0,  0.25, 1.0,  1.0,  1.0,   1.0,   0.0,   1.0   },

	Wind    = { 1.0,  1.0,  2.0,  0.25, 1.0,  1.0,   1.0,   0.0,   1.0   },

	Earth   = { 1.0,  1.0,  1.0,  2.0,  0.25, 1.0,   1.0,   0.0,   1.0   },

	Holy    = { 1.0,  1.0,  1.0,  1.0,  1.0,  0.5,   2.0,   1.0,   2.0   },

	Shadow  = { 1.0,  1.0,  1.0,  1.0,  1.0,  2.0,   0.5,   1.0,   0.5   },

	Ghost   = { 0.0,  1.0,  1.0,  1.0,  1.0,  1.0,   1.0,   1.5,   1.0   },

	Undead  = { 1.0,  1.5,  1.0,  1.0,  1.0,  2.0,   0.5,   1.0,   0.0   },

}

-- Index ลำดับธาตุสำหรับ lookup

local ELEMENT_INDEX = {

	Neutral = 1, Fire = 2, Water = 3, Wind = 4,

	Earth   = 5, Holy = 6, Shadow = 7, Ghost = 8, Undead = 9,

}

-- ── ดึงมัลติพลายเออร์ธาตุ ──────────────────────────────────

local function GetElementMultiplier(attackEl, defendEl)

	local row = ElementMultiplier[attackEl]

	if not row then return 1.0 end

	local idx = ELEMENT_INDEX[defendEl]

	if not idx then return 1.0 end

	return row[idx]

end

-- ============================================================

-- STATUS EFFECTS TABLE

-- ข้อมูลสถานะผิดปกติแต่ละประเภท

-- Status effect definitions

-- ============================================================

local STATUS_EFFECTS = {

	Poison = {

		duration    = 10,   -- วินาที / seconds

		tickInterval = 2,   -- ทิ้กทุก 2 วินาที

		description = "ลดพิษ 2% MaxHP ทุก 2s / Poison: 2% MaxHP dmg per 2s",

	},

	Frozen = {

		duration    = 3,

		description = "หยุดเคลื่อนไหว / Frozen: cannot move",

	},

	Stun = {

		duration    = 2,

		description = "หยุดทุกการกระทำ / Stun: cannot act",

	},

	Blind = {

		duration    = 15,

		description = "HIT -50%, FLEE -50% / Blind",

		hitMult     = 0.5,

		fleeMult    = 0.5,

	},

	Silence = {

		duration    = 10,

		description = "ใช้สกิลไม่ได้ / Silence: cannot use skills",

	},

	Curse = {

		duration    = 30,

		description = "STR/AGI/DEX -50%, MaxHP -25% / Curse",

		statMult    = 0.5,

		maxHPMult   = 0.75,

	},

}

local KillMonster -- forward declaration for lethal monster poison ticks

-- Active status effects per player: [userId] = { [effectName] = {endTime, thread} }

local PlayerStatusEffects  = {}

-- Active status effects per monster: [monsterModel] = { [effectName] = {endTime, thread} }

local MonsterStatusEffects = {}

-- ============================================================

-- APPLY STATUS EFFECT TO PLAYER

-- ใส่ status effect ให้ผู้เล่น

-- ============================================================

local function ApplyStatusToPlayer(player, effectName, duration)

	local def = STATUS_EFFECTS[effectName]

	if not def then return end

	if not PlayerStatusEffects[player.UserId] then

		PlayerStatusEffects[player.UserId] = {}

	end

	local effects = PlayerStatusEffects[player.UserId]

	-- ยกเลิก effect เก่าถ้ามี (reset duration)

	if effects[effectName] and effects[effectName].thread then

		task.cancel(effects[effectName].thread)

	end

	local endTime = tick() + (duration or def.duration)

	local data    = DataStore.GetPlayerData(player)

	-- Set Attribute เพื่อให้ CombatSystem อ่านได้

	player:SetAttribute("Status" .. effectName, true)

	if effectName == "Curse" and data then

		data._StatusCurse = true

		DataStore.SyncAttributes(player, data)

		if _G.PushCharacterData then _G.PushCharacterData(player) end

	end

	if effectName == "Frozen" or effectName == "Stun" then

		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

		if hum then hum.WalkSpeed = 0 end

	end

	-- แจ้ง Client เพื่อแสดง visual effect

	local statusVisuals = {

		Poison = {"☠", "6f8c45"}, Frozen = {"❄", "55aadd"}, Stun = {"⚡", "e0a83a"},

		Blind = {"◉", "6857a5"}, Silence = {"🔇", "777788"}, Curse = {"☠", "8d4b9e"},

	}

	local visual = statusVisuals[effectName] or {"!", "555555"}

	Remotes.ApplyStatusEffect:FireClient(player, "add", effectName, visual[1], visual[2], duration or def.duration)

	local function cleanupEffect()

		player:SetAttribute("Status" .. effectName, nil)

		if PlayerStatusEffects[player.UserId] then

			PlayerStatusEffects[player.UserId][effectName] = nil

		end

		if effectName == "Curse" then

			local pdata = DataStore.GetPlayerData(player)

			if pdata then

				pdata._StatusCurse = nil

				DataStore.SyncAttributes(player, pdata)

				if _G.PushCharacterData then _G.PushCharacterData(player) end

			end

		end

		if (effectName == "Frozen" or effectName == "Stun") and not player:GetAttribute("StatusFrozen") and not player:GetAttribute("StatusStun") then

			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

			if hum then hum.WalkSpeed = 16 end

		end

		Remotes.ApplyStatusEffect:FireClient(player, "remove", effectName)

	end

	-- ── Poison: ลด HP ทุก tickInterval ──────────────────

	local thread

	if effectName == "Poison" then

		thread = task.spawn(function()

			while tick() < endTime and player.Parent ~= nil do

				task.wait(def.tickInterval)

				local pdata = DataStore.GetPlayerData(player)

				if not pdata then break end

				local derived = DataStore.CalcDerivedStats(pdata)

				local poisonDmg = math.max(1, math.floor(derived.MaxHP * 0.02))

				local newHP = pdata.HP - poisonDmg

				DataStore.SetHP(player, newHP)

				-- แสดงตัวเลขดาเมจ

				local character = player.Character

				if character and character:FindFirstChild("HumanoidRootPart") then

					local pos = character.HumanoidRootPart.Position

					FireNearbyClients(Remotes.ShowDamageNumber, pos, poisonDmg, false, "Poison")

				end

				if newHP <= 0 then

					-- PlayerDied จัดการโดย MonsterAI

					break

				end

			end

			cleanupEffect()

		end)

	else

		-- Non-damage effects: รอให้หมดเวลาแล้วลบ

		thread = task.spawn(function()

			task.wait(duration or def.duration)

			cleanupEffect()

		end)

	end

	effects[effectName] = { endTime = endTime, thread = thread }

end

local function ClearPlayerStatuses(player)

	local effects = PlayerStatusEffects[player.UserId]

	for _, effectName in ipairs({"Poison", "Frozen", "Stun", "Blind", "Silence", "Curse"}) do

		if effects and effects[effectName] and effects[effectName].thread then

			task.cancel(effects[effectName].thread)

			effects[effectName] = nil

		end

		player:SetAttribute("Status" .. effectName, nil)

		Remotes.ApplyStatusEffect:FireClient(player, "remove", effectName)

	end

	local data = DataStore.GetPlayerData(player)

	if data and data._StatusCurse then

		data._StatusCurse = nil

		DataStore.SyncAttributes(player, data)

		if _G.PushCharacterData then _G.PushCharacterData(player) end

	end

	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

	if hum then hum.WalkSpeed = 16 end

end

local PlayerCoatingThreads = {}

local function ApplyWeaponCoating(player, element, duration)

	duration = tonumber(duration) or 180

	if PlayerCoatingThreads[player.UserId] then

		task.cancel(PlayerCoatingThreads[player.UserId])

	end

	player:SetAttribute("CoatedElement", element)

	local coatVisuals = {

		Fire = {"🔥", "e05838"}, Water = {"💧", "3898e0"}, Wind = {"⚡", "48b868"},

		Earth = {"🪨", "b88848"}, Holy = {"✦", "e8c858"}, Shadow = {"🌑", "7858b8"},

	}

	local vis = coatVisuals[element] or {"✦", "e8c858"}

	Remotes.ApplyStatusEffect:FireClient(player, "add", "Coat_" .. element, vis[1], vis[2], duration)

	if _G.PushCharacterData then _G.PushCharacterData(player) end

	PlayerCoatingThreads[player.UserId] = task.spawn(function()

		task.wait(duration)

		if player.Parent and player:GetAttribute("CoatedElement") == element then

			player:SetAttribute("CoatedElement", nil)

			Remotes.ApplyStatusEffect:FireClient(player, "remove", "Coat_" .. element)

			if _G.PushCharacterData then _G.PushCharacterData(player) end

		end

	end)

end

-- ============================================================

-- APPLY STATUS EFFECT TO MONSTER

-- ใส่ status effect ให้มอนสเตอร์

-- ============================================================

local function ApplyStatusToMonster(monster, effectName, duration, sourcePlayer)

	local def = STATUS_EFFECTS[effectName]

	if not def then return end

	if not MonsterStatusEffects[monster] then

		MonsterStatusEffects[monster] = {}

	end

	local effects = MonsterStatusEffects[monster]

	if effects[effectName] and effects[effectName].thread then

		task.cancel(effects[effectName].thread)

	end

	monster:SetAttribute("Status" .. effectName, true)

	local endTime = tick() + (duration or def.duration)

	local thread

	if effectName == "Poison" then

		thread = task.spawn(function()

			while tick() < endTime and monster.Parent ~= nil do

				task.wait(def.tickInterval)

				if not monster.Parent then break end

				local monHP    = monster:GetAttribute("HP") or 0

				local monMaxHP = monster:GetAttribute("MaxHP") or 1

				local poisonDmg = math.max(1, math.floor(monMaxHP * 0.02))

				local newHP     = monHP - poisonDmg

				monster:SetAttribute("HP", math.max(0, newHP))

				local fill = monster:FindFirstChild("HPFill", true)

				if fill then fill.Size = UDim2.fromScale(math.clamp(newHP / monMaxHP, 0, 1), 1) end

				-- แสดงดาเมจ

				local rootPart = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart

				if rootPart then

					FireNearbyClients(Remotes.ShowDamageNumber, rootPart.Position, math.min(monHP, poisonDmg), false, "Poison")

				end

				if newHP <= 0 then

					local partyMembers

					local partyId = sourcePlayer and (sourcePlayer:GetAttribute("PartyId") or "")

					if partyId ~= "" then

						partyMembers = {}

						for _, member in ipairs(Players:GetPlayers()) do

							if (member:GetAttribute("PartyId") or "") == partyId then table.insert(partyMembers, member) end

						end

					end

					if KillMonster then KillMonster(monster, sourcePlayer, partyMembers) end

					break

				end

			end

			if monster.Parent then

				monster:SetAttribute("Status" .. effectName, nil)

			end

			if MonsterStatusEffects[monster] then

				MonsterStatusEffects[monster][effectName] = nil

			end

		end)

	else

		thread = task.spawn(function()

			task.wait(duration or def.duration)

			if monster.Parent then

				monster:SetAttribute("Status" .. effectName, nil)

			end

			if MonsterStatusEffects[monster] then

				MonsterStatusEffects[monster][effectName] = nil

			end

		end)

	end

	effects[effectName] = { endTime = endTime, thread = thread }

end

-- ============================================================

-- HIT / MISS CHECK

-- ตรวจสอบว่าโจมตีถูกหรือพลาด

-- hitChance = attackerHIT - targetFLEE + 80 (base 80%)

-- ============================================================

local function RollHitMiss(attackerHIT, targetFLEE)

	local hitChance = math.clamp(attackerHIT - targetFLEE + 80, 5, 100)

	local roll      = math.random(1, 100)

	local isMiss    = roll > hitChance

	return not isMiss, hitChance  -- (didHit, hitChance)

end

-- ============================================================

-- PERFECT DODGE CHECK

-- pdRoll <= targetPerfectDodge*10 (per 1000)

-- ============================================================

local function RollPerfectDodge(targetPerfectDodge)

	local pdRoll = math.random(1, 1000)

	return pdRoll <= (targetPerfectDodge * 10)

end

-- ============================================================

-- CRITICAL HIT CHECK

-- critRoll <= attackerCritRate

-- ============================================================

local function RollCritical(attackerCritRate)

	local critRoll = math.random(1, 100)

	return critRoll <= attackerCritRate

end

-- ============================================================

-- ============================================================
-- WEAPON SIZE PENALTY TABLE (Ragnarok M 1:1)
-- ตารางตัวคูณขนาดอาวุธต่อขนาดมอนสเตอร์ (Small, Medium, Large)
-- ============================================================
local WeaponSizeModifier = {
	Dagger        = { Small = 1.00, Medium = 0.75, Large = 0.50 },
	Short_Sword   = { Small = 0.85, Medium = 1.00, Large = 0.75 },
	Sword         = { Small = 0.75, Medium = 1.00, Large = 0.75 },
	TwoHandSword  = { Small = 0.75, Medium = 0.75, Large = 1.00 },
	Spear         = { Small = 0.75, Medium = 0.75, Large = 1.00 },
	TwoHandSpear  = { Small = 0.75, Medium = 0.75, Large = 1.00 },
	Mace          = { Small = 0.75, Medium = 1.00, Large = 1.00 },
	Axe           = { Small = 0.50, Medium = 0.75, Large = 1.00 },
	TwoHandAxe    = { Small = 0.50, Medium = 0.75, Large = 1.00 },
	Bow           = { Small = 1.00, Medium = 1.00, Large = 0.75 },
	Rod           = { Small = 1.00, Medium = 1.00, Large = 1.00 },
	Staff         = { Small = 1.00, Medium = 1.00, Large = 1.00 },
	Katar         = { Small = 0.75, Medium = 1.00, Large = 0.75 },
}

-- ============================================================
-- PHYSICAL DAMAGE FORMULA (Ragnarok M 1:1 Scale)
-- Hard DEF Asymptotic Mitigation: (4000 + DEF) / (4000 + DEF * 10)
-- rawDmg = (ATK * defFactor * sizeFactor) + refineATK
-- crit ignores DEF and size penalty
-- ============================================================
local function CalcPhysicalDamage(attackerATK, targetDEF, isCrit, attackElement, defendElement, weaponType, targetSize, ignoreDefPercent, refineATK)
	ignoreDefPercent = math.clamp(tonumber(ignoreDefPercent) or 0, 0, 1)
	refineATK = math.max(0, tonumber(refineATK) or 0)
	targetSize = targetSize or "Medium"

	local sizeFactor = 1.0
	if weaponType and WeaponSizeModifier[weaponType] then
		sizeFactor = WeaponSizeModifier[weaponType][targetSize] or 1.0
	end

	local rawDmg
	if isCrit then
		-- Critical: 150% base damage, bypasses normal DEF & size penalty
		rawDmg = math.floor(attackerATK * 1.5) + refineATK
	else
		-- Ragnarok M Hard DEF Reduction Formula: (4000 + DEF) / (4000 + DEF*10)
		local effectiveDEF = math.max(0, targetDEF * (1 - ignoreDefPercent))
		local defFactor = (4000 + effectiveDEF) / (4000 + (effectiveDEF * 10))
		rawDmg = math.floor(attackerATK * defFactor * sizeFactor) + refineATK
	end

	local elementMult = GetElementMultiplier(attackElement or "Neutral", defendElement or "Neutral")

	-- ±10% variance
	local variance = 1.0 + (math.random(-100, 100) / 1000)

	local finalDmg = math.floor(rawDmg * elementMult * variance)
	return math.max(1, finalDmg)
end

-- ============================================================
-- MAGIC DAMAGE FORMULA (Ragnarok M 1:1 Scale)
-- Hard MDEF Asymptotic Mitigation: (4000 + MDEF) / (4000 + MDEF * 10)
-- rawDmg = (matkRoll * mdefFactor) + refineMATK
-- ============================================================
local function CalcMagicDamage(matkMin, matkMax, targetMDEF, spellElement, defendElement, skillPowerMult, ignoreMdefPercent, refineMATK)
	ignoreMdefPercent = math.clamp(tonumber(ignoreMdefPercent) or 0, 0, 1)
	refineMATK = math.max(0, tonumber(refineMATK) or 0)

	local matkRoll = math.random(matkMin, math.max(matkMin, matkMax))
	local effectiveMDEF = math.max(0, targetMDEF * (1 - ignoreMdefPercent))
	local mdefFactor = (4000 + effectiveMDEF) / (4000 + (effectiveMDEF * 10))
	local rawDmg = math.floor(matkRoll * mdefFactor) + refineMATK

	local elementMult = GetElementMultiplier(spellElement or "Neutral", defendElement or "Neutral")
	skillPowerMult    = skillPowerMult or 1.0

	local finalDmg = math.floor(rawDmg * elementMult * skillPowerMult)
	return math.max(1, finalDmg)
end

-- ============================================================

-- KILL MONSTER

-- ฆ่ามอนสเตอร์: แจก XP, JobXP, drop ไอเทม, respawn

-- ============================================================

KillMonster = function(monster, killerPlayer, partyMembers)

	if not monster or not monster.Parent or monster:GetAttribute("DeathProcessed") then return end

	monster:SetAttribute("DeathProcessed", true)

	-- ดึงข้อมูลจาก monster attributes

	local monsterID = monster:GetAttribute("MonsterID") or "Unknown"

	local baseXP    = monster:GetAttribute("XP_Reward")   or 10

	local baseJobXP = monster:GetAttribute("JobXP_Reward") or 5

	local monLevel  = monster:GetAttribute("Level")        or 1

	local spawnPos  = monster:GetAttribute("SpawnPosition")

	local respawnTime = monster:GetAttribute("RespawnTime") or 30

	local mapName   = monster:GetAttribute("MapName")      or "Prontera"

	-- ── XP Distribution ────────────────────────────────────

	-- แชร์ XP ให้สมาชิกปาร์ตี้ทุกคนที่อยู่ในแผนที่เดียวกับมอนสเตอร์

	local rootPart = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart

	local monsterPos = rootPart and rootPart.Position or Vector3.new(0,0,0)

	if typeof(spawnPos) ~= "Vector3" then

		-- Older spawned monsters have no Vector3 spawn attribute. Their core is

		-- centered two studs above the saved floor position.

		spawnPos = monsterPos - Vector3.new(0, 2, 0)

	end

	local recipients = {}  -- { player, levelDiff }

	if partyMembers and #partyMembers > 0 then

		for _, member in ipairs(partyMembers) do

			if member and member.Parent then

				local memberMap = member:GetAttribute("Map")

				if type(memberMap) ~= "string" or memberMap == "" then

					local memberData = DataStore.GetPlayerData(member)

					memberMap = memberData and memberData.Map

				end

				if memberMap == mapName then

					table.insert(recipients, member)

				end

			end

		end

	else

		-- Solo: แค่ killer

		if killerPlayer and killerPlayer.Parent then

			table.insert(recipients, killerPlayer)

		end

	end

	-- ── คำนวณและแจก XP ──────────────────────────────────────

	local recipientCount = math.max(1, #recipients)

	local highestPartyLevel = 0

	for _, member in ipairs(recipients) do

		highestPartyLevel = math.max(highestPartyLevel, tonumber(member:GetAttribute("Level")) or 1)

	end

	for _, member in ipairs(recipients) do

		local memberData = DataStore.GetPlayerData(member)

		if memberData then

			-- XP penalty only applies when the player out-levels the monster by more than

			-- OVERLEVEL_GRACE. Fighting a stronger monster is never punished (it used to be:

			-- a Lv1 player got 17 XP from Lunatic Lv3 but 18 XP from the easier Poring).

			local OVERLEVEL_GRACE = 5

			local overLevel = memberData.Level - monLevel

			local xpMult = 1.0

			if overLevel <= OVERLEVEL_GRACE then

				xpMult = 1.0     -- 100%

			elseif overLevel <= OVERLEVEL_GRACE + 10 then

				xpMult = 0.5     -- 50%

			else

				xpMult = 0.2     -- 20%

			end

			-- Under-leveled party members get the requested party-gap penalty:

			-- 0 gap = 100%, 10 levels = 50%, 20+ levels = 20%.

			local partyLevelGap = math.max(0, highestPartyLevel - memberData.Level)

			local partyLevelMult

			if partyLevelGap <= 10 then

				partyLevelMult = 1 - (partyLevelGap * 0.05)

			elseif partyLevelGap < 20 then

				partyLevelMult = 0.5 - ((partyLevelGap - 10) * 0.03)

			else

				partyLevelMult = 0.2

			end

			-- แบ่ง XP ตามจำนวนสมาชิก (ลด 10% ต่อคนเพิ่ม, ขั้นต่ำ 60%)

			local partyShareMult = math.max(0.6, 1.0 - ((recipientCount - 1) * 0.10))

			local xpGain    = math.floor(baseXP    * xpMult * partyShareMult * partyLevelMult)

			local jobXPGain = math.floor(baseJobXP * xpMult * partyShareMult * partyLevelMult)

			local didLevelUp, didJobLevelUp = DataStore.AddXP(member, xpGain, jobXPGain)

			if _G.DailyQuestSystem then

				_G.DailyQuestSystem.AddProgress(member, "Kill", monsterID, 1)

			end

			if _G.TownStoryQuestSystem then

				_G.TownStoryQuestSystem.AddProgress(member, "Kill", monsterID, 1)

			end

			if didLevelUp then

				-- แจ้ง client ว่าเลเวลอัพ

				Remotes.LevelUp:FireClient(member, memberData.Level)

				print(string.format("[CombatSystem] %s LEVEL UP! -> Lv.%d", member.Name, memberData.Level))

			end

			if _G.GameManager and _G.GameManager.PushCharacterData then

				_G.GameManager.PushCharacterData(member)

			elseif _G.PushCharacterData then

				_G.PushCharacterData(member)

			end

			print(string.format("[CombatSystem] %s รับ +%d XP +%d JobXP จาก %s",

				member.Name, xpGain, jobXPGain, monsterID))

		end

	end

	-- ── Item Drop Roll ──────────────────────────────────────

	-- ดึง drop table จาก MonsterData (ผ่าน _G หรือ attribute)

	-- ใช้ simple approach: spawn drops ที่ตำแหน่งมอนสเตอร์

	local dropTable = nil

	if _G.MonsterData then

		local mData = _G.MonsterData[monsterID]

		if mData then dropTable = mData.Drops end

	end

	if dropTable then

		for _, dropEntry in ipairs(dropTable) do

			-- dropEntry = { itemId=string, chance=number(0-100), quantity=number }

			local roll = math.random(1, 10000)

			if roll <= (dropEntry.chance * 100) then

				-- Spawn a world pickup. The server awards it after its prompt triggers.

				local qty = dropEntry.quantity or 1

				local itemInfo = ItemData[dropEntry.itemId]

				if not itemInfo then

					warn("[CombatSystem] Drop item is not defined: " .. tostring(dropEntry.itemId))

					continue

				end

				local dropPart = Instance.new("Part")

				dropPart.Name    = "Drop_" .. dropEntry.itemId

				dropPart.Size    = Vector3.new(0.8, 0.8, 0.8)

				dropPart.Shape = Enum.PartType.Ball

				dropPart.Material = Enum.Material.Neon

				dropPart.Color = itemInfo.type == "Card" and Color3.fromRGB(255, 205, 70)

					or Color3.fromRGB(125, 235, 170)

				dropPart.Anchored   = true

				dropPart.CanCollide = false

				dropPart.CanTouch = false

				dropPart:SetAttribute("ItemId",   dropEntry.itemId)

				dropPart:SetAttribute("Quantity", qty)

				-- Scatter drops ใกล้มอนสเตอร์

				local offset = Vector3.new(

					math.random(-3, 3),

					1,

					math.random(-3, 3)

				)

				dropPart.CFrame = CFrame.new(monsterPos + offset)

				dropPart.Parent = Workspace

				local prompt = Instance.new("ProximityPrompt")

				prompt.ActionText = "เก็บ"

				prompt.ObjectText = itemInfo.name

				prompt.KeyboardKeyCode = Enum.KeyCode.F

				prompt.HoldDuration = 0

				prompt.MaxActivationDistance = 10

				prompt.RequiresLineOfSight = false

				prompt.Parent = dropPart

				local claimed = false

				prompt.Triggered:Connect(function(player)

					if claimed or not dropPart.Parent then return end

					local success, inventory = DataStore.AddItem(player, dropEntry.itemId, qty)

					if not success then return end

					claimed = true

					if Remotes.UpdateInventory then

						Remotes.UpdateInventory:FireClient(player, inventory, dropEntry.itemId, qty)

					end

					if _G.DailyQuestSystem then

						_G.DailyQuestSystem.AddProgress(player, "Collect", dropEntry.itemId, qty)

					end

					if _G.TownStoryQuestSystem then

						_G.TownStoryQuestSystem.AddProgress(player, "Collect", dropEntry.itemId, qty)

					end

					dropPart:Destroy()

				end)

				-- ลบ drop หลัง 60 วินาที ถ้าไม่มีคนหยิบ

				task.delay(60, function()

					if dropPart and dropPart.Parent then

						dropPart:Destroy()

					end

				end)

			end

		end

	end

	-- ── Fire MonsterDied Remote ─────────────────────────────

	Remotes.MonsterDied:FireAllClients(monster.Name, monsterPos)

	-- MVP Boss Defeat Announcement & Treasure Chest
	local isMvpBoss = monster:GetAttribute("IsWorldBoss") == true or monster:GetAttribute("IsMVP") == true or (monsterID == "GoldenThiefBug" or monsterID == "Drake" or monsterID == "Eddga" or monsterID == "TurtleGeneral")
	if isMvpBoss then
		local mDef = _G.MonsterData and _G.MonsterData[monsterID]
		local bossName = (mDef and mDef.Name) or monsterID
		local killerName = killerPlayer and killerPlayer.Name or "เหล่านักผจญภัย"
		local killerClass = killerPlayer and (killerPlayer:GetAttribute("Class") or "Adventurer") or "Adventurer"
		local RE_SkillFeedback = Remotes.SkillFeedback or (ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("SkillFeedback"))
		if RE_SkillFeedback then
			RE_SkillFeedback:FireAllClients(string.format("🏆 [MVP DEFEATED] บอส %s ถูกปราบแล้วโดย %s (%s)!", bossName, killerName, killerClass))
		end
		if _G.SpawnMvpTreasureChest then
			_G.SpawnMvpTreasureChest(monsterPos, monsterID, killerPlayer)
		end
	end

	-- ── Schedule Respawn ────────────────────────────────────

	-- เก็บข้อมูลก่อนทำลาย model

	local storedMonsterID = monsterID

	local storedMapName   = mapName

	local storedPos       = spawnPos

	-- ทำลาย monster model

	-- ล้าง status effects

	MonsterStatusEffects[monster] = nil

	monster:Destroy()

	-- Respawn หลัง respawnTime วินาที

	task.delay(respawnTime, function()

		if _G.MonsterAI and _G.MonsterAI.SpawnMonster then

			_G.MonsterAI.SpawnMonster(storedMonsterID, storedPos, storedMapName)

		end

	end)

	print(string.format("[CombatSystem] %s ตาย / Killed, respawn in %ds", storedMonsterID, respawnTime))

end

-- ============================================================

-- PLAYER ATTACK MONSTER

-- ผู้เล่นโจมตีมอนสเตอร์ (basic attack หรือ physical skill)

-- Returns: { damage, isCrit, isMiss, isPerfectDodge }

-- ============================================================

local function PlayerAttackMonster(player, monster, skillId)

	if not player or not monster or not monster.Parent then

		return { damage = 0, isCrit = false, isMiss = true, isPerfectDodge = false }

	end

	-- ── ดึง stats ผู้เล่นจาก Attributes ─────────────────

	local attackerATK    = player:GetAttribute("ATK")          or 1

	local attackerHIT    = player:GetAttribute("HIT")          or 1

	local attackerCrit   = player:GetAttribute("CritRate")     or 1

	local attackerMatkMin = player:GetAttribute("MATK_min")   or 1

	local attackerMatkMax = player:GetAttribute("MATK_max")   or 1

	local attackerClass  = player:GetAttribute("Class")        or "Novice"

	-- ── ดึง stats มอนสเตอร์จาก Attributes ───────────────

	local targetDEF      = monster:GetAttribute("DEF")         or 0

	local targetMDEF     = monster:GetAttribute("MDEF")        or 0

	local targetFLEE     = monster:GetAttribute("FLEE")        or 0

	local targetPD       = monster:GetAttribute("PerfectDodge") or 0

	local targetElement  = monster:GetAttribute("Element")     or "Neutral"

	local monsterHP      = monster:GetAttribute("HP")          or 0

	-- ── ธาตุของผู้โจมตี (default Neutral หรืออ่านจาก CoatedElement ของใบธาตุ/สกิลเคลือบ) ──

	local coatedEl = player:GetAttribute("CoatedElement")

	local attackElement = (type(coatedEl) == "string" and coatedEl ~= "") and coatedEl or "Neutral"

	-- ── Skill override ───────────────────────────────────

	local isMagicSkill       = false

	local skillPowerMult     = 1.0

	local skillElement       = attackElement

	local skillDataRef       = nil

	if skillId and _G.SkillData then

		local sData = _G.SkillData[skillId]

		if sData then

			skillDataRef   = sData

			isMagicSkill   = sData.isMagic   or false

			local pData    = DataStore.GetPlayerData(player)

			local sLevel   = math.max(1, tonumber(pData and pData.Skills and pData.Skills[skillId]) or 1)

			skillPowerMult = (sData.powerMult or 1.0) + (sLevel - 1) * (sData.powerPerLevel or 0.08)

			skillElement   = sData.element or attackElement

			attackElement  = skillElement

			-- Physical job skills gain a small bonus from their declared primary stat.

			if not isMagicSkill and sData.scalingStat then

				local primaryValue = player:GetAttribute(sData.scalingStat) or 1

				skillPowerMult *= (1 + math.max(0, primaryValue - 1) * 0.005)

			end

		end

	end

	-- ── ตรวจสอบ Stun (ถ้าติด Stun โจมตีไม่ได้) ──────────

	if player:GetAttribute("StatusStun") then

		return { damage = 0, isCrit = false, isMiss = true, isPerfectDodge = false }

	end

	-- ── ตรวจสอบ Blind (ลด HIT ลง 50%) ──────────────────

	if player:GetAttribute("StatusBlind") then

		attackerHIT = math.floor(attackerHIT * 0.5)

	end

	-- Any attack attempt (hit or miss) provokes the monster so MonsterAI chases the

	-- attacker; without this a ranged Archer could never be fought back.

	monster:SetAttribute("AggroUserId", player.UserId)

	-- ── Perfect Dodge ────────────────────────────────────

	local isPerfectDodge = RollPerfectDodge(targetPD)

	if isPerfectDodge then

		-- แสดง "Miss" ใน floating text

		local rootPart = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart

		if rootPart then

			FireNearbyClients(Remotes.ShowDamageNumber, rootPart.Position, 0, false, "MISS")

		end

		return { damage = 0, isCrit = false, isMiss = true, isPerfectDodge = true }

	end

	-- ── Hit / Miss Check ────────────────────────────────

	local didHit, _ = RollHitMiss(attackerHIT, targetFLEE)

	if not didHit then

		local rootPart = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart

		if rootPart then

			FireNearbyClients(Remotes.ShowDamageNumber, rootPart.Position, 0, false, "MISS")

		end

		return { damage = 0, isCrit = false, isMiss = true, isPerfectDodge = false }

	end

	-- ── Critical Roll ────────────────────────────────────

	-- ── Weapon Type and Target Size (Ragnarok M 1:1) ───────
	local targetSize = monster:GetAttribute("Size") or "Medium"
	local weaponType = "Dagger"
	local pData = DataStore.GetPlayerData(player)
	if pData and pData.Equipment and pData.Equipment.Weapon then
		local wItem = ItemData[pData.Equipment.Weapon]
		if wItem and wItem.weaponType then
			weaponType = wItem.weaponType
		end
	end

	-- ── Critical Roll ────────────────────────────────────
	-- ── Refine ATK / MATK & Ignore DEF ───────────────────
	local weaponRefineLevel = math.clamp(math.floor(tonumber(pData and pData.EquipmentRefine and pData.EquipmentRefine.Weapon) or 0), 0, 15)
	local refineATK = weaponRefineLevel * 6
	local refineMATK = isMagicSkill and (weaponRefineLevel * 6) or 0
	local ignoreDefPercent = (skillDataRef and (skillDataRef.ignoreDefPercent or skillDataRef.ignoreDef)) or 0
	if player:GetAttribute("BuffAuraBlade") then
		ignoreDefPercent = math.max(ignoreDefPercent, 0.25)
	end

	local isCrit = (not isMagicSkill) and RollCritical(attackerCrit)

	-- ── Calculate Damage ─────────────────────────────────
	local finalDamage
	if isMagicSkill then
		finalDamage = CalcMagicDamage(
			attackerMatkMin, attackerMatkMax,
			targetMDEF,
			skillElement, targetElement,
			skillPowerMult,
			ignoreDefPercent, refineMATK
		)
	else
		finalDamage = CalcPhysicalDamage(
			attackerATK, targetDEF,
			isCrit,
			attackElement, targetElement,
			weaponType, targetSize,
			ignoreDefPercent, refineATK
		)
		finalDamage = math.floor(finalDamage * skillPowerMult)
	end

	-- ── Apply Damage to Monster ───────────────────────────

	local newMonsterHP = math.max(0, monsterHP - finalDamage)

	monster:SetAttribute("HP", newMonsterHP)

	-- อัพเดต HP bar บน BillboardGui

	local billboardGui = monster:FindFirstChild("MonsterBillboard", true)

	if billboardGui then

		local hpBar      = billboardGui:FindFirstChild("HPBar")

		local maxHP      = monster:GetAttribute("MaxHP") or 1

		if hpBar and hpBar:IsA("Frame") then

			local hpFill = hpBar:FindFirstChild("HPFill")

			if hpFill then

				hpFill.Size = UDim2.new(math.max(0, newMonsterHP / maxHP), 0, 1, 0)

			end

		end

	end

	-- ── Floating Damage Number ────────────────────────────

	local rootPart = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart

	if rootPart then

		local dmgType = isCrit and "CRIT" or (isMagicSkill and "MAGIC" or "PHYS")

		FireNearbyClients(Remotes.ShowDamageNumber, rootPart.Position, finalDamage, isCrit, dmgType)

	end

	print(string.format("[CombatSystem] %s โจมตี %s: %d dmg (Crit=%s)",

		player.Name, monster:GetAttribute("MonsterID") or "?", finalDamage, tostring(isCrit)))

	-- ── Check Monster Death or Inflict Skill Status ───────

	if newMonsterHP <= 0 then

		if string.find(monster.Name, "^TrainingDummy") then

			local maxHP = monster:GetAttribute("MaxHP") or 20000

			monster:SetAttribute("HP", maxHP)

			if billboardGui then

				local hpBar = billboardGui:FindFirstChild("HPBar")

				local hpFill = hpBar and hpBar:FindFirstChild("HPFill")

				if hpFill then hpFill.Size = UDim2.fromScale(1, 1) end

			end

			local didLevelUp = DataStore.AddXP(player, 10, 8)

			if didLevelUp and Remotes.LevelUp then

				local pData = DataStore.GetPlayerData(player)

				if pData then Remotes.LevelUp:FireClient(player, pData.Level) end

			end

			if _G.DailyQuestSystem then

				_G.DailyQuestSystem.AddProgress(player, "Kill", "TrainingDummy", 1)

			end

			if _G.TownStoryQuestSystem then

				_G.TownStoryQuestSystem.AddProgress(player, "Kill", "TrainingDummy", 1)

			end

			if _G.GameManager and _G.GameManager.PushCharacterData then

				_G.GameManager.PushCharacterData(player)

			elseif _G.PushCharacterData then

				_G.PushCharacterData(player)

			end

			return {

				damage         = finalDamage,

				isCrit         = isCrit,

				isMiss         = false,

				isPerfectDodge = false,

			}

		end

		-- รวบรวม party members (ถ้ามี)

		local partyId = player:GetAttribute("PartyId") or ""

		local partyMembers = {}

		if partyId ~= "" then

			for _, p in ipairs(Players:GetPlayers()) do

				if (p:GetAttribute("PartyId") or "") == partyId then

					table.insert(partyMembers, p)

				end

			end

		end

		KillMonster(monster, player, partyMembers)

	elseif skillDataRef and skillDataRef.statusEffect then

		local chance = tonumber(skillDataRef.statusChance) or 25

		if math.random(1, 100) <= chance then

			ApplyStatusToMonster(monster, skillDataRef.statusEffect, nil, player)

		end

	end

	return {

		damage         = finalDamage,

		isCrit         = isCrit,

		isMiss         = false,

		isPerfectDodge = false,

	}

end

-- ============================================================

-- MONSTER ATTACK PLAYER

-- มอนสเตอร์โจมตีผู้เล่น

-- Called by MonsterAI; deducts player HP

-- ============================================================

local function MonsterAttackPlayer(monster, player)

	if not monster or not player or not player.Character then return 0 end

	local character = player.Character

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if (humanoid and humanoid.Health <= 0) or os.clock() < (player:GetAttribute("SpawnProtectedUntil") or 0) then return 0 end

	local monsterRoot = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart

	local playerRoot = character:FindFirstChild("HumanoidRootPart")

	local attackRange = tonumber(monster:GetAttribute("AttackRange")) or 5

	if not monsterRoot or not playerRoot or (playerRoot.Position - monsterRoot.Position).Magnitude > attackRange then

		return 0

	end

	local losParams = RaycastParams.new()

	losParams.FilterType = Enum.RaycastFilterType.Exclude

	losParams.FilterDescendantsInstances = {monster}

	local losOrigin = monsterRoot.Position + Vector3.new(0, 0.5, 0)

	local losTarget = playerRoot.Position + Vector3.new(0, 1, 0)

	local obstruction = Workspace:Raycast(losOrigin, losTarget - losOrigin, losParams)

	if obstruction and not obstruction.Instance:IsDescendantOf(character) then return 0 end

	local data = DataStore.GetPlayerData(player)

	if not data then return 0 end

	-- ── Stats ─────────────────────────────────────────────

	local monATK       = monster:GetAttribute("ATK")     or 1

	local monElement   = monster:GetAttribute("Element") or "Neutral"

	local playerDEF    = player:GetAttribute("DEF")      or 0

	local playerFLEE   = player:GetAttribute("FLEE")     or 0

	local playerPD     = player:GetAttribute("PerfectDodge") or 0

	-- ── ตรวจสอบ Frozen/Stun บน player (monster ไม่โจมตีเพิ่มถ้า stunned?)

	-- มอนสเตอร์ยังคงโจมตีแม้ player จะ stun

	-- ── ตรวจสอบ FLEE ของ player ────────────────────────

	-- ถ้า player ติด Blind ลด FLEE

	if player:GetAttribute("StatusBlind") then

		playerFLEE = math.floor(playerFLEE * 0.5)

	end

	-- Perfect Dodge

	local isPerfectDodge = RollPerfectDodge(playerPD)

	if isPerfectDodge then

		local char = player.Character

		local hrp  = char and char:FindFirstChild("HumanoidRootPart")

		if hrp then

			FireNearbyClients(Remotes.ShowDamageNumber, hrp.Position, 0, false, "MISS")

		end

		return 0

	end

	-- Hit check (monster HIT ดึงจาก attribute)

	local monHIT = monster:GetAttribute("HIT") or 50

	local didHit, _ = RollHitMiss(monHIT, playerFLEE)

	if not didHit then

		local char = player.Character

		local hrp  = char and char:FindFirstChild("HumanoidRootPart")

		if hrp then

			FireNearbyClients(Remotes.ShowDamageNumber, hrp.Position, 0, false, "MISS")

		end

		return 0

	end

	-- ── Damage ───────────────────────────────────────────

	-- ธาตุของผู้เล่น (default Neutral — สามารถขยายให้อ่านจาก Equipment ได้)

	-- ── Damage (Ragnarok M 1:1 Asymptotic DEF Mitigation) ──
	local playerElement = "Neutral"
	local elementMult   = GetElementMultiplier(monElement, playerElement)
	local effectiveDEF  = math.max(0, playerDEF)
	local defFactor     = (4000 + effectiveDEF) / (4000 + (effectiveDEF * 10))
	local rawDmg        = monATK * defFactor
	local variance      = 1.0 + (math.random(-100, 100) / 1000)
	local finalDmg      = math.max(1, math.floor(rawDmg * elementMult * variance))

	-- ── Curse: MaxHP -25% ────────────────────────────────

	-- (handled via SyncAttributes; damage cap is already applied)

	-- ── Apply HP Damage ──────────────────────────────────

	local oldHP = data.HP

	local newHP = oldHP - finalDmg

	DataStore.SetHP(player, newHP)

	local actualDamage = math.max(0, oldHP - data.HP)

	-- Show the exact HP lost over the player who was hit.

	local char = player.Character

	local hrp  = char and char:FindFirstChild("HumanoidRootPart")

	if hrp then

		FireNearbyClients(Remotes.ShowDamageNumber, hrp.Position, actualDamage, false, "MONSTER")

	end

	print(string.format("[CombatSystem] %s โจมตี %s: %d dmg (HP %d->%d)",

		monster:GetAttribute("MonsterID") or "Monster", player.Name,

		actualDamage, oldHP, data.HP))

	if data.HP > 0 and _G.GameManager and _G.GameManager.PushCharacterData then

		_G.GameManager.PushCharacterData(player)

	end

	-- ── Check Player Death or Monster StatusOnHit ─────────

	if newHP <= 0 then

		-- PlayerDied จัดการโดย MonsterAI (เพื่อลด circular dependency)

		if _G.MonsterAI and _G.MonsterAI.PlayerDied then

			_G.MonsterAI.PlayerDied(player)

		end

	else

		local monId = monster:GetAttribute("MonsterID")

		local mDef = monId and MonsterData[monId]

		if mDef and mDef.StatusOnHit then

			local chance = tonumber(mDef.StatusChance) or 20

			if math.random(1, 100) <= chance then

				ApplyStatusToPlayer(player, mDef.StatusOnHit)

			end

		end

	end

	return finalDmg

end

-- ============================================================

-- HANDLE SKILL USE (called by GameManager)

-- จัดการเมื่อผู้เล่นใช้สกิล

-- ============================================================

local SkillCooldownUntil = {}

local PlayerBuffThreads = {}

Players.PlayerRemoving:Connect(function(player)

	SkillCooldownUntil[player.UserId] = nil

	PlayerBuffThreads[player.UserId] = nil

	PlayerCoatingThreads[player.UserId] = nil

end)

local function HandleSkillUse(player, skillId, skillLevel, targetId)

	if not _G.SkillData then

		warn("[CombatSystem] ไม่พบ SkillData module")

		return false

	end

	local sData = _G.SkillData[skillId]

	if not sData then

		warn(string.format("[CombatSystem] ไม่พบสกิล / Unknown skill: %s", tostring(skillId)))

		return false

	end

	local data = DataStore.GetPlayerData(player)

	if not data then return false end

	local cooldowns = SkillCooldownUntil[player.UserId]

	if not cooldowns then

		cooldowns = {}

		SkillCooldownUntil[player.UserId] = cooldowns

	end

	local now = os.clock()

	if now < (cooldowns[skillId] or 0) then return false end

	local cooldown = math.max(0.5, tonumber(sData.cooldown) or 1.5)

	local character = player.Character

	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")

	if not playerRoot then return false end

	local targetMonster

	if sData.isAttack then

		local skillRange = (tonumber(sData.range) or ClassData.GetBasicAttackRange(player:GetAttribute("Class") or data.Class or "Novice")) + 6

		if typeof(targetId) == "Instance" and targetId:IsDescendantOf(Workspace) then
			targetMonster = targetId
		elseif type(targetId) == "string" and targetId ~= "" then
			targetMonster = Workspace:FindFirstChild(targetId, true)
		end

		-- ถ้าไม่ได้ล็อกเป้า หรือเป้าหมายเดิมตาย/อยู่นอกระยะ ให้หาเป้าหมายใกล้สุดในระยะสกิลอัตโนมัติ

		local validTarget = targetMonster and targetMonster:GetAttribute("MonsterID") and (targetMonster:GetAttribute("HP") or 0) > 0

		if validTarget then

			local mRoot = targetMonster:FindFirstChild("HumanoidRootPart") or targetMonster.PrimaryPart

			if not mRoot or (playerRoot.Position - mRoot.Position).Magnitude > skillRange then

				validTarget = false

			end

		end

		if not validTarget then

			targetMonster = nil

			local bestDist = skillRange + 10

			local mFolder = Workspace:FindFirstChild("Monsters")

			for _, m in ipairs(mFolder and mFolder:GetChildren() or {}) do

				local mRoot = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart

				if mRoot and (m:GetAttribute("HP") or 0) > 0 then

					local d = (mRoot.Position - playerRoot.Position).Magnitude

					if d <= bestDist then

						bestDist = d

						targetMonster = m

					end

				end

			end

		end

		if not targetMonster or not targetMonster:GetAttribute("MonsterID")

			or (targetMonster:GetAttribute("HP") or 0) <= 0 then

			if Remotes.SkillFeedback then

				Remotes.SkillFeedback:FireClient(player, "ไม่มีเป้าหมายในระยะสกิล — เดินเข้าใกล้มอนสเตอร์หรือหุ่นฟางก่อนกดสกิล")

			end

			return false

		end

		local monsterRoot = targetMonster:FindFirstChild("HumanoidRootPart") or targetMonster.PrimaryPart

		if not monsterRoot or (playerRoot.Position - monsterRoot.Position).Magnitude > (skillRange + 10) then

			if Remotes.SkillFeedback then

				Remotes.SkillFeedback:FireClient(player, "เป้าหมายอยู่นอกระยะสกิล")

			end

			return false

		end

	elseif not sData.isHeal and not sData.isBuff then

		return false

	end

	-- ตรวจสอบ SP และ Gold เพียงพอ

	local spCost = (sData.spCost or 0) + (skillLevel - 1) * (sData.spCostPerLevel or 0)

	local goldCost = sData.goldCost or 0

	if data.SP < spCost then

		if Remotes.SkillFeedback then

			Remotes.SkillFeedback:FireClient(player, string.format("SP ไม่เพียงพอ (%d/%d)", data.SP, spCost))

		end

		return false

	end

	if data.Gold < goldCost then

		if Remotes.SkillFeedback then

			Remotes.SkillFeedback:FireClient(player, string.format("Zeny ไม่เพียงพอ (%d/%d z)", data.Gold, goldCost))

		end

		return false

	end

	cooldowns[skillId] = now + cooldown

	DataStore.SetSP(player, data.SP - spCost)

	if goldCost > 0 then DataStore.ModifyGold(player, -goldCost) end

	if sData.cureStatus then

		ClearPlayerStatuses(player)

	end

	if sData.coatElement then

		ApplyWeaponCoating(player, sData.coatElement, sData.buffDuration or 60)

	end

	-- ── Buff Skill ───────────────────────────────────────

	if sData.isBuff and sData.buffStats then

		local duration = tonumber(sData.buffDuration) or 45

		data._ActiveBuffs = data._ActiveBuffs or {}

		local bonusPerLv = (skillLevel - 1) * (tonumber(sData.buffPerLevel) or 1)

		for stat, baseAmt in pairs(sData.buffStats) do

			data._ActiveBuffs[stat] = baseAmt + bonusPerLv

		end

		DataStore.SyncAttributes(player, data)

		Remotes.ApplyStatusEffect:FireClient(player, "add", "Buff_" .. skillId, sData.icon or "✦", "d4af37", duration)

		PlayerBuffThreads[player.UserId] = PlayerBuffThreads[player.UserId] or {}

		if PlayerBuffThreads[player.UserId][skillId] then

			task.cancel(PlayerBuffThreads[player.UserId][skillId])

		end

		PlayerBuffThreads[player.UserId][skillId] = task.spawn(function()

			task.wait(duration)

			local pData = DataStore.GetPlayerData(player)

			if pData and pData._ActiveBuffs then

				for stat in pairs(sData.buffStats) do

					pData._ActiveBuffs[stat] = nil

				end

				DataStore.SyncAttributes(player, pData)

				if _G.PushCharacterData then _G.PushCharacterData(player) end

			end

			if player.Parent then

				Remotes.ApplyStatusEffect:FireClient(player, "remove", "Buff_" .. skillId)

			end

		end)

	end

	-- ── Healing Skill ────────────────────────────────────

	local vfxTargetPos = playerRoot.Position

	if sData.isHeal then

		local derived = DataStore.CalcDerivedStats(data)

		local healAmt

		if sData.flatHeal then

			healAmt = sData.flatHeal + (skillLevel - 1) * (sData.flatHealPerLevel or 10)

		else

			local mult = (sData.powerMult or 1.2) + (skillLevel - 1) * (sData.powerPerLevel or 0.2)

			healAmt = math.floor((derived.MATK_min + derived.MATK_max) / 2 * mult * skillLevel)

		end

		local newHP = math.min(data.HP + healAmt, derived.MaxHP)

		DataStore.SetHP(player, newHP)

		FireNearbyClients(Remotes.ShowHealNumber, playerRoot.Position, healAmt)

	end

	if sData.isAttack and targetMonster then

		local centerRoot = targetMonster:FindFirstChild("HumanoidRootPart") or targetMonster.PrimaryPart

		local centerPos = centerRoot and centerRoot.Position or playerRoot.Position

		vfxTargetPos = centerPos

		PlayerAttackMonster(player, targetMonster, skillId)

		-- ถ้าเป็นสกิลวงกว้าง (AoE) โจมตีมอนสเตอร์ทุกตัวในรัศมี aoeRadius!

		if sData.aoeRadius then

			local mFolder = Workspace:FindFirstChild("Monsters")

			for _, other in ipairs(mFolder and mFolder:GetChildren() or {}) do

				if other ~= targetMonster and (other:GetAttribute("HP") or 0) > 0 then

					local oRoot = other:FindFirstChild("HumanoidRootPart") or other.PrimaryPart

					if oRoot and (oRoot.Position - centerPos).Magnitude <= sData.aoeRadius then

						PlayerAttackMonster(player, other, skillId)

					end

				end

			end

		end

	end

	if _G.GameManager and _G.GameManager.PushCharacterData then

		_G.GameManager.PushCharacterData(player)

	elseif _G.PushCharacterData then

		_G.PushCharacterData(player)

	end

	if Remotes.SkillFeedback then

		Remotes.SkillFeedback:FireClient(player, skillId, cooldown)

	end

	return true, vfxTargetPos

end

-- ============================================================

-- EXPOSE PUBLIC API

-- ============================================================

_G.CombatSystem = {

	PlayerAttackMonster  = PlayerAttackMonster,

	MonsterAttackPlayer  = MonsterAttackPlayer,

	KillMonster          = KillMonster,

	HandleSkillUse       = HandleSkillUse,

	ApplyStatusToPlayer  = ApplyStatusToPlayer,

	ApplyStatusToMonster = ApplyStatusToMonster,

	ClearPlayerStatuses  = ClearPlayerStatuses,

	ApplyWeaponCoating   = ApplyWeaponCoating,

	CalcPhysicalDamage   = CalcPhysicalDamage,

	CalcMagicDamage      = CalcMagicDamage,

	GetElementMultiplier = GetElementMultiplier,

	RollHitMiss          = RollHitMiss,

	RollCritical         = RollCritical,

	RollPerfectDodge     = RollPerfectDodge,

	STATUS_EFFECTS       = STATUS_EFFECTS,

}

print("[CombatSystem] CombatSystem.server.lua โหลดเสร็จ / Loaded OK")