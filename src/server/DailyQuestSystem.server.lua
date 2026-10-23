-- ============================================================
-- DailyQuestSystem.server.lua
-- ระบบกระดานเควสประจำวัน (Mission Board) สไตล์ Ragnarok M
-- สุ่ม 5 ภารกิจต่อวัน ทำได้สูงสุด 3 ภารกิจต่อวัน ได้รับ Base XP, Job XP, Zeny และไอเทมของใช้
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local questDefinitions = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("DailyQuestData"))

local dataStore
repeat
	task.wait(0.1)
	dataStore = _G.DataStore
until dataStore or not script.Parent

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local function getOrCreate(className, name)
	local remote = remoteFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = remoteFolder
	end
	return remote
end

local updateRemote = getOrCreate("RemoteEvent", "DailyQuestUpdate")
local acceptRemote = getOrCreate("RemoteEvent", "AcceptDailyQuest")
local claimRemote  = getOrCreate("RemoteEvent", "ClaimDailyQuest")
local getRemote    = getOrCreate("RemoteFunction", "GetDailyQuests")

local definitionById = {}
for _, definition in ipairs(questDefinitions) do
	definitionById[definition.id] = definition
end

local function getThailandDateKey()
	-- Shift by +07:00 so daily quests reset at midnight in Thailand
	return os.date("!%Y-%m-%d", os.time() + 7 * 60 * 60)
end

local function pickDailyQuests(count)
	local huntPool = {}
	local collectPool = {}
	local visitPool = {}
	for _, def in ipairs(questDefinitions) do
		if def.objective == "Kill" then
			table.insert(huntPool, def.id)
		elseif def.objective == "Collect" then
			table.insert(collectPool, def.id)
		elseif def.objective == "Visit" then
			table.insert(visitPool, def.id)
		end
	end

	local picked = {}
	local function pickFrom(pool, num)
		for _ = 1, num do
			if #pool > 0 then
				local idx = math.random(1, #pool)
				table.insert(picked, pool[idx])
				table.remove(pool, idx)
			end
		end
	end

	-- สุ่มสมดุล: 2 ล่ามอนสเตอร์, 2 หาไอเท็มจากมอนมาส่ง, 1 ส่งของ/เดินตรวจเมือง (ครบ 5 เควส)
	pickFrom(huntPool, 2)
	pickFrom(collectPool, 2)
	pickFrom(visitPool, 1)

	if #picked < (count or 5) then
		local remaining = {}
		for _, def in ipairs(questDefinitions) do
			if not table.find(picked, def.id) then table.insert(remaining, def.id) end
		end
		pickFrom(remaining, (count or 5) - #picked)
	end

	return picked
end

local function getQuestState(player)
	local playerData = dataStore.GetPlayerData(player)
	if not playerData then return nil end
	local today = getThailandDateKey()
	local state = playerData.DailyQuests
	if type(state) ~= "table" or state.date ~= today then
		state = {
			date = today,
			offers = pickDailyQuests(5),
			active = {},
			progress = {},
			claimed = {},
			completedCount = 0,
		}
		playerData.DailyQuests = state
	else
		state.active = type(state.active) == "table" and state.active or {}
		state.progress = type(state.progress) == "table" and state.progress or {}
		state.claimed = type(state.claimed) == "table" and state.claimed or {}
		state.completedCount = tonumber(state.completedCount) or 0
		if type(state.offers) ~= "table" or #state.offers == 0 then
			state.offers = pickDailyQuests(5)
		end
	end
	return state
end

local function getAliasId(itemId)
	if itemId == "StickyMucus" then return "Sticky_Mucus"
	elseif itemId == "Sticky_Mucus" then return "StickyMucus"
	elseif itemId == "IronOre" then return "Iron_Ore"
	elseif itemId == "Iron_Ore" then return "IronOre"
	end
	return itemId
end

local function countItemInInventory(playerData, targetId)
	if not playerData or not playerData.Inventory then return 0 end
	local total = 0
	local altId = getAliasId(targetId)
	for _, entry in ipairs(playerData.Inventory) do
		if type(entry) == "table" and (entry.itemId == targetId or entry.itemId == altId) then
			total += (tonumber(entry.quantity) or 1)
		end
	end
	return total
end

local function buildSnapshot(player)
	local state = getQuestState(player)
	if not state then return { offers = {}, activeCount = 0, completedCount = 0, maxDaily = 3 } end
	local offers = {}
	local activeCount = 0
	local completedCount = tonumber(state.completedCount) or 0

	for _, questId in ipairs(state.offers or {}) do
		local definition = definitionById[questId]
		if definition then
			local active = state.active[definition.id] == true
			local progress = math.clamp(tonumber(state.progress[definition.id]) or 0, 0, definition.amount)
			local claimed = state.claimed[definition.id] == true
			if definition.objective == "Collect" and active and not claimed then
				local inBag = countItemInInventory(dataStore.GetPlayerData(player), definition.target)
				if inBag > progress then
					progress = math.clamp(inBag, 0, definition.amount)
					state.progress[definition.id] = progress
				end
			end
			if active and not claimed then activeCount += 1 end

			table.insert(offers, {
				id = definition.id,
				title = definition.title,
				description = definition.description,
				objective = definition.objective,
				target = definition.target,
				amount = definition.amount,
				progress = progress,
				xp = definition.xp,
				jobXp = definition.jobXp or math.floor(definition.xp * 0.6),
				gold = definition.gold,
				rewardItem = definition.rewardItem,
				rewardItemCount = definition.rewardItemCount or 1,
				rewardItemName = definition.rewardItemName or definition.rewardItem,
				npcName = definition.npcName or "ผู้จ้างวาน",
				location = definition.location or "Prontera",
				targetPos = definition.targetPos and { X = definition.targetPos.X, Y = definition.targetPos.Y, Z = definition.targetPos.Z } or nil,
				active = active,
				claimed = claimed,
				complete = active and progress >= definition.amount and not claimed,
			})
		end
	end

	return {
		offers = offers,
		activeCount = activeCount,
		completedCount = completedCount,
		maxDaily = 3,
	}
end

local function publish(player)
	updateRemote:FireClient(player, buildSnapshot(player))
end

getRemote.OnServerInvoke = function(player)
	return buildSnapshot(player)
end

acceptRemote.OnServerEvent:Connect(function(player, questId)
	if type(questId) ~= "string" or not definitionById[questId] then return end
	local state = getQuestState(player)
	if not state or state.active[questId] or state.claimed[questId] then return end

	-- ตรวจสอบโควตา 3 เควสต่อวัน
	local completed = tonumber(state.completedCount) or 0
	if completed >= 3 then
		local sf = remoteFolder:FindFirstChild("SkillFeedback")
		if sf then sf:FireClient(player, "⚠️ วันนี้คุณทำเควสกระดานครบ 3/3 ภารกิจแล้ว! กลับมาใหม่พรุ่งนี้นะ") end
		return
	end

	local activeCount = 0
	for id, active in pairs(state.active) do
		if active and not state.claimed[id] then activeCount += 1 end
	end
	if activeCount >= (3 - completed) or activeCount >= 3 then
		local sf = remoteFolder:FindFirstChild("SkillFeedback")
		if sf then sf:FireClient(player, "⚠️ คุณรับเควสพร้อมกันได้สูงสุด 3 ภารกิจ") end
		return
	end

	state.active[questId] = true
	local initialProgress = 0
	if definitionById[questId].objective == "Collect" then
		initialProgress = math.clamp(countItemInInventory(dataStore.GetPlayerData(player), definitionById[questId].target), 0, definitionById[questId].amount)
	end
	state.progress[questId] = initialProgress
	publish(player)

	local sf = remoteFolder:FindFirstChild("SkillFeedback")
	if sf then
		sf:FireClient(player, "📜 รับภารกิจ '" .. definitionById[questId].title .. "' แล้ว! สามารถติดตามเป้าหมายได้ที่แผนที่")
	end
end)

claimRemote.OnServerEvent:Connect(function(player, questId)
	if type(questId) ~= "string" then return end
	local definition = definitionById[questId]
	local state = getQuestState(player)
	if not definition or not state or not state.active[questId] or state.claimed[questId] then return end
	if (tonumber(state.progress[questId]) or 0) < definition.amount then return end

	if definition.objective == "Collect" then
		local pData = dataStore.GetPlayerData(player)
		if dataStore.RemoveItem then
			dataStore.RemoveItem(player, definition.target, definition.amount)
		end
		local remotesApi = _G.Remotes
		if pData and remotesApi and remotesApi.UpdateInventory then
			remotesApi.UpdateInventory:FireClient(player, pData.Inventory, pData.Equipment or {}, "ส่งไอเทมเควสเรียบร้อย", pData.EquipmentRefine or {})
		end
	end

	state.claimed[questId] = true
	state.active[questId] = false
	state.completedCount = (tonumber(state.completedCount) or 0) + 1

	local xpGiven = definition.xp or 2000
	local jobXpGiven = definition.jobXp or math.floor(xpGiven * 0.6)
	local goldGiven = definition.gold or 1500

	local didLevelUp = dataStore.AddXP(player, xpGiven, jobXpGiven)
	dataStore.ModifyGold(player, goldGiven)

	if definition.rewardItem and dataStore.AddItem then
		dataStore.AddItem(player, definition.rewardItem, definition.rewardItemCount or 1)
	end

	publish(player)

	local sf = remoteFolder:FindFirstChild("SkillFeedback")
	if sf then
		sf:FireClient(player, string.format("🎉 ทำเควสสำเร็จ! ได้รับ +%d Base XP, +%d Job XP, +%d Zeny และ %s",
			xpGiven, jobXpGiven, goldGiven, definition.rewardItemName or "ไอเทมของใช้"))
	end

	if didLevelUp and remoteFolder:FindFirstChild("LevelUp") then
		remoteFolder.LevelUp:FireClient(player, player:GetAttribute("Level"))
	end
	if _G.PushCharacterData then _G.PushCharacterData(player) end
end)

local function addProgress(player, objective, target, amount)
	local state = getQuestState(player)
	if not state then return end
	local changed = false
	local altTarget = getAliasId(target)
	for _, questId in ipairs(state.offers or {}) do
		local definition = definitionById[questId]
		if definition and state.active[definition.id] and not state.claimed[definition.id]
			and definition.objective == objective and (definition.target == target or definition.target == altTarget) then
			local previous = tonumber(state.progress[definition.id]) or 0
			local nextValue = math.min(definition.amount, previous + math.max(1, math.floor(amount or 1)))
			if nextValue ~= previous then
				state.progress[definition.id] = nextValue
				changed = true
				if nextValue >= definition.amount then
					local sf = remoteFolder:FindFirstChild("SkillFeedback")
					if sf then
						sf:FireClient(player, "🎉 ภารกิจ '" .. definition.title .. "' สำเร็จแล้ว! กดปุ่ม [รับรางวัล] บนหน้าจอเพื่อรับรางวัลได้ทันที")
					end
				end
			end
		end
	end
	if changed then publish(player) end
end

_G.DailyQuestSystem = { AddProgress = addProgress }
shared.DailyQuestSystem = _G.DailyQuestSystem

-- BindableEvent สำหรับให้ script อื่นๆ หรือระบบภายนอกเรียกใช้ AddProgress ได้โดยตรง
local addProgressBindable = script:FindFirstChild("AddProgress")
if not addProgressBindable then
	addProgressBindable = Instance.new("BindableEvent")
	addProgressBindable.Name = "AddProgress"
	addProgressBindable.Parent = script
end
addProgressBindable.Event:Connect(function(player, objective, target, amount)
	addProgress(player, objective, target, amount)
end)

-- Loop ตรวจสอบเควสประเภท "Visit" (เดินไปยังสถานที่เป้าหมาย)
task.spawn(function()
	while true do
		task.wait(2)
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root then
				local state = getQuestState(player)
				if state and state.offers then
					for _, questId in ipairs(state.offers) do
						local def = definitionById[questId]
						if def and def.objective == "Visit" and state.active[def.id] and not state.claimed[def.id] then
							if def.targetPos and (root.Position - def.targetPos).Magnitude <= 20 then
								addProgress(player, "Visit", def.target, 1)
							end
						end
					end
				end
			end
		end
	end
end)

local function onPlayerAdded(player)
	local started = os.clock()
	while player.Parent and not dataStore.GetPlayerData(player) and os.clock() - started < 30 do
		task.wait(0.25)
	end
	if player.Parent and dataStore.GetPlayerData(player) then
		getQuestState(player)
		publish(player)
	end
end

Players.PlayerAdded:Connect(function(player) task.spawn(onPlayerAdded, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, player) end

print("[DailyQuestSystem] Ragnarok M Mission Board daily quest system ready (Max 3/day, 5 random)")
