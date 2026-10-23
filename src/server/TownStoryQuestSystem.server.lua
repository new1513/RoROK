-- ============================================================
-- TownStoryQuestSystem.server.lua
-- ServerScriptService — RoROK (Ragnarok Online-inspired MMORPG)
-- ระบบเควสเนื้อเรื่องประจำเมืองสไตล์ Ragnarok M (Town Story Quests)
-- ทำได้เพียง 1 ครั้งต่อบัญชี (One-Time per Account)
-- มอบ EXP & Job EXP มหาศาล อุปกรณ์เริ่มต้น อาวุธประจำอาชีพ และเงิน Zeny
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local StoryQuestData = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("StoryQuestData"))

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

local RF_GetStoryQuestState  = getOrCreate("RemoteFunction", "GetStoryQuestState")
local RE_AcceptStoryQuest    = getOrCreate("RemoteEvent", "AcceptStoryQuest")
local RE_ClaimStoryQuest     = getOrCreate("RemoteEvent", "ClaimStoryQuest")
local RE_StoryQuestUpdate    = getOrCreate("RemoteEvent", "StoryQuestUpdate")
local RE_OpenNpcDialogue     = getOrCreate("RemoteEvent", "OpenNpcDialogue")

local function getPlayerData(player)
	return dataStore and dataStore.GetPlayerData(player)
end

-- ── 1. Quest State Resolver ───────────────────────────────────
local function resolveNpcQuestState(player, npcId)
	local pData = getPlayerData(player)
	if not pData then
		return { status = "error", message = "กำลังโหลดข้อมูลผู้เล่น..." }
	end

	pData.CompletedStoryQuests = pData.CompletedStoryQuests or {}
	pData.ActiveStoryQuests = pData.ActiveStoryQuests or {}

	local quest = StoryQuestData.GetQuestByNpc(npcId)
	if not quest then
		return { status = "no_quest", npcId = npcId }
	end

	-- Check if permanently finished (1-time only)
	if pData.CompletedStoryQuests[quest.id] == true then
		return {
			status = "completed",
			quest = quest,
			dialogue = quest.dialogueFinished,
			npcName = quest.npcName,
			npcTitle = quest.npcTitle,
		}
	end

	-- Check prerequisite quest
	if quest.prerequisite and not pData.CompletedStoryQuests[quest.prerequisite] then
		local prereqQuest = StoryQuestData.GetQuestById(quest.prerequisite)
		return {
			status = "locked",
			quest = quest,
			dialogue = string.format("เจ้ายังไม่พร้อมสำหรับภารกิจนี้ จงไปทำภารกิจ '%s' ก่อนนะ!", prereqQuest and prereqQuest.title or "ก่อนหน้า"),
			npcName = quest.npcName,
			npcTitle = quest.npcTitle,
		}
	end

	-- Check player level requirement
	local playerLevel = tonumber(pData.Level) or 1
	if playerLevel < (quest.levelReq or 1) then
		return {
			status = "locked_level",
			quest = quest,
			dialogue = string.format("ภารกิจนี้ต้องการเลเวล %d ขึ้นไป (เลเวลปัจจุบันของเจ้าคือ %d)", quest.levelReq, playerLevel),
			npcName = quest.npcName,
			npcTitle = quest.npcTitle,
		}
	end

	local activeEntry = pData.ActiveStoryQuests[quest.id]
	if not activeEntry then
		-- Available to accept
		return {
			status = "available",
			quest = quest,
			dialogue = quest.dialogueStart,
			npcName = quest.npcName,
			npcTitle = quest.npcTitle,
		}
	end

	local function getItemCount(itemId)
		if not pData.Inventory or type(itemId) ~= "string" then return 0 end
		local altId = (itemId == "StickyMucus" and "Sticky_Mucus") or (itemId == "Sticky_Mucus" and "StickyMucus")
		           or (itemId == "IronOre" and "Iron_Ore") or (itemId == "Iron_Ore" and "IronOre") or itemId
		local total = 0
		for _, entry in ipairs(pData.Inventory) do
			if type(entry) == "table" and (entry.itemId == itemId or entry.itemId == altId) then
				total += (tonumber(entry.quantity) or 1)
			end
		end
		return total
	end

	-- In Progress or Ready to Claim
	local currentProgress = tonumber(activeEntry.progress) or 0
	local isReady = false

	if quest.objective == "Collect" then
		currentProgress = getItemCount(quest.target)
		activeEntry.progress = currentProgress
		isReady = currentProgress >= quest.amount
		if quest.secondaryCollectTarget then
			local secCount = getItemCount(quest.secondaryCollectTarget)
			if secCount < (quest.secondaryCollectAmount or 1) then
				isReady = false
			end
		end
	elseif quest.objective == "Kill" then
		isReady = currentProgress >= quest.amount
		if quest.collectTarget then
			local colCount = getItemCount(quest.collectTarget)
			if colCount < (quest.collectAmount or 1) then
				isReady = false
			end
		end
	elseif quest.objective == "Visit" then
		isReady = currentProgress >= quest.amount
	end

	return {
		status = isReady and "ready_to_claim" or "in_progress",
		quest = quest,
		progress = currentProgress,
		targetAmount = quest.amount,
		dialogue = isReady and quest.dialogueReady or quest.dialogueInProgress,
		npcName = quest.npcName,
		npcTitle = quest.npcTitle,
	}
end

RF_GetStoryQuestState.OnServerInvoke = function(player, npcId)
	if type(npcId) ~= "string" then return { status = "invalid" } end
	return resolveNpcQuestState(player, npcId)
end

-- ── 2. Accept Quest ───────────────────────────────────────────
RE_AcceptStoryQuest.OnServerEvent:Connect(function(player, questId)
	if type(questId) ~= "string" then return end
	local quest = StoryQuestData.GetQuestById(questId)
	if not quest then return end

	local pData = getPlayerData(player)
	if not pData then return end

	pData.CompletedStoryQuests = pData.CompletedStoryQuests or {}
	pData.ActiveStoryQuests = pData.ActiveStoryQuests or {}

	if pData.CompletedStoryQuests[quest.id] == true then return end
	if quest.prerequisite and not pData.CompletedStoryQuests[quest.prerequisite] then return end

	local initialProgress = 0
	if quest.objective == "Visit" then
		initialProgress = 1
	elseif quest.objective == "Collect" and pData.Inventory then
		for _, entry in ipairs(pData.Inventory) do
			if entry.itemId == quest.target then
				initialProgress += (tonumber(entry.quantity) or 1)
			end
		end
	end

	pData.ActiveStoryQuests[quest.id] = {
		progress = initialProgress,
		startedAt = os.time(),
	}

	dataStore.SavePlayerData(player)
	RE_StoryQuestUpdate:FireClient(player, quest.id, "accepted", initialProgress, quest.amount)

	local remotesApi = _G.Remotes
	if remotesApi and remotesApi.SkillFeedback then
		remotesApi.SkillFeedback:FireClient(player, "📜 รับเควสเนื้อเรื่อง: " .. quest.title)
	end
end)

-- ── 3. Claim Quest Rewards ────────────────────────────────────
RE_ClaimStoryQuest.OnServerEvent:Connect(function(player, questId)
	if type(questId) ~= "string" then return end
	local quest = StoryQuestData.GetQuestById(questId)
	if not quest then return end

	local pData = getPlayerData(player)
	if not pData then return end

	pData.CompletedStoryQuests = pData.CompletedStoryQuests or {}
	pData.ActiveStoryQuests = pData.ActiveStoryQuests or {}

	if pData.CompletedStoryQuests[quest.id] == true then return end
	local activeEntry = pData.ActiveStoryQuests[quest.id]
	if not activeEntry then return end

	local progress = tonumber(activeEntry.progress) or 0

	local function getItemCount(itemId)
		if not pData.Inventory or type(itemId) ~= "string" then return 0 end
		local altId = (itemId == "StickyMucus" and "Sticky_Mucus") or (itemId == "Sticky_Mucus" and "StickyMucus")
		           or (itemId == "IronOre" and "Iron_Ore") or (itemId == "Iron_Ore" and "IronOre") or itemId
		local total = 0
		for _, entry in ipairs(pData.Inventory) do
			if type(entry) == "table" and (entry.itemId == itemId or entry.itemId == altId) then
				total += (tonumber(entry.quantity) or 1)
			end
		end
		return total
	end

	-- Verify objectives before claim
	if quest.objective == "Collect" then
		if getItemCount(quest.target) < quest.amount then return end
		if quest.secondaryCollectTarget and getItemCount(quest.secondaryCollectTarget) < (quest.secondaryCollectAmount or 1) then
			return
		end
	elseif quest.objective == "Kill" then
		if progress < quest.amount then return end
		if quest.collectTarget and getItemCount(quest.collectTarget) < (quest.collectAmount or 1) then
			return
		end
	elseif quest.objective == "Visit" then
		if progress < quest.amount then return end
	end

	-- Deduct quest items from inventory
	if quest.objective == "Collect" then
		if dataStore.RemoveItem then
			dataStore.RemoveItem(player, quest.target, quest.amount)
			if quest.secondaryCollectTarget then
				dataStore.RemoveItem(player, quest.secondaryCollectTarget, quest.secondaryCollectAmount or 1)
			end
		end
	end
	if quest.collectTarget and dataStore.RemoveItem then
		dataStore.RemoveItem(player, quest.collectTarget, quest.collectAmount or 1)
	end

	-- Mark completed permanently (1-time only per account)
	pData.CompletedStoryQuests[quest.id] = true
	pData.ActiveStoryQuests[quest.id] = nil

	-- 1. Award Massive EXP & Job EXP
	local didLevelUp = dataStore.AddXP(player, quest.rewardXP or 0, quest.rewardJobXP or 0)

	-- 2. Award Zeny
	if (quest.rewardGold or 0) > 0 then
		dataStore.ModifyGold(player, quest.rewardGold)
	end

	-- 3. Award Starter Items & Potions
	if quest.rewardItems then
		for _, itemReward in ipairs(quest.rewardItems) do
			dataStore.AddItem(player, itemReward.itemId, itemReward.count or 1)
		end
	end

	-- 4. Award Class-Tailored Weapon if requested
	if quest.rewardClassWeapon then
		local classWeaponId = StoryQuestData.GetClassWeapon(pData.Class or "Novice")
		dataStore.AddItem(player, classWeaponId, 1)
	end

	-- Save & Sync
	dataStore.SavePlayerData(player)
	dataStore.SyncAttributes(player, pData)

	if _G.GameManager and _G.GameManager.PushCharacterData then
		_G.GameManager.PushCharacterData(player)
	end

	-- Notify inventory & UI
	local remotesApi = _G.Remotes
	if remotesApi and remotesApi.UpdateInventory then
		remotesApi.UpdateInventory:FireClient(player, pData.Inventory or {}, pData.Equipment or {}, "สำเร็จเควส: " .. quest.title .. "!", pData.EquipmentRefine or {})
	end

	RE_StoryQuestUpdate:FireClient(player, quest.id, "claimed", quest.amount, quest.amount)

	if remotesApi and remotesApi.SkillFeedback then
		remotesApi.SkillFeedback:FireClient(player, string.format("🎉 สำเร็จเควสเนื้อเรื่อง! ได้รับ EXP +%d, Job +%d, %d z", quest.rewardXP or 0, quest.rewardJobXP or 0, quest.rewardGold or 0))
	end
end)

-- ── 4. Global Progress Dispatcher ─────────────────────────────
local TownStoryQuestSystem = {}

function TownStoryQuestSystem.AddProgress(player, actionType, targetId, count)
	if not player or not player:IsA("Player") then return end
	count = tonumber(count) or 1
	local pData = getPlayerData(player)
	if not pData or not pData.ActiveStoryQuests then return end

	for qId, activeEntry in pairs(pData.ActiveStoryQuests) do
		local quest = StoryQuestData.GetQuestById(qId)
		if quest and quest.objective == actionType then
			local match = (quest.target == targetId)
			-- Fallback for name variants
			if not match and targetId and quest.target then
				if targetId:lower() == quest.target:lower() then match = true end
			end

			if match then
				local current = tonumber(activeEntry.progress) or 0
				local newProg = math.min(quest.amount, current + count)
				activeEntry.progress = newProg

				RE_StoryQuestUpdate:FireClient(player, quest.id, "progress", newProg, quest.amount)

				if newProg >= quest.amount and current < quest.amount then
					local remotesApi = _G.Remotes
					if remotesApi and remotesApi.SkillFeedback then
						remotesApi.SkillFeedback:FireClient(player, string.format("✓ ภารกิจเนื้อเรื่อง '%s' สำเร็จแล้ว! กลับไปคุยกับ %s เพื่อรับรางวัล", quest.title, quest.npcName))
					end
				end
			end
		end
	end
end

_G.TownStoryQuestSystem = TownStoryQuestSystem
shared.TownStoryQuestSystem = TownStoryQuestSystem

local BE_AddStoryProgress = script:FindFirstChild("AddStoryQuestProgress")
if not BE_AddStoryProgress then
	BE_AddStoryProgress = Instance.new("BindableEvent")
	BE_AddStoryProgress.Name = "AddStoryQuestProgress"
	BE_AddStoryProgress.Parent = script
end
BE_AddStoryProgress.Event:Connect(function(player, actionType, targetId, count)
	TownStoryQuestSystem.AddProgress(player, actionType, targetId, count)
end)

-- ── 5. Attach Dynamic 3D Over-Head Marks to Town NPCs ─────────
task.spawn(function()
	task.wait(2.0) -- wait for map generation
	local plaza = Workspace:FindFirstChild("RoROK_StarterPlaza")
	if not plaza then return end

	for _, quest in ipairs(StoryQuestData.Quests) do
		local npcModel = plaza:FindFirstChild(quest.npcId, true)
		if npcModel and npcModel:IsA("Model") then
			local root = npcModel.PrimaryPart or npcModel:FindFirstChild("HumanoidRootPart") or npcModel:FindFirstChild("Head")
			if root and not root:FindFirstChild("StoryQuestMark") then
				local markGui = Instance.new("BillboardGui")
				markGui.Name = "StoryQuestMark"
				markGui.Size = UDim2.new(0, 48, 0, 48)
				markGui.StudsOffset = Vector3.new(0, 3.8, 0)
				markGui.AlwaysOnTop = true
				markGui.MaxDistance = 75
				markGui.Parent = root

				local markLabel = Instance.new("TextLabel")
				markLabel.Name = "MarkLabel"
				markLabel.Size = UDim2.fromScale(1, 1)
				markLabel.BackgroundTransparency = 1
				markLabel.Text = "📜"
				markLabel.TextSize = 26
				markLabel.Parent = markGui

				-- Gentle floating animation
				task.spawn(function()
					local t = 0
					while markGui and markGui.Parent do
						t += 0.05
						markGui.StudsOffset = Vector3.new(0, 3.8 + math.sin(t * 3) * 0.35, 0)
						task.wait(0.05)
					end
				end)
			end

			-- Enhance ProximityPrompt to fire OpenNpcDialogue
			local prompt = npcModel:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				prompt.Triggered:Connect(function(player)
					RE_OpenNpcDialogue:FireClient(player, quest.npcId)
				end)
			end
		end
	end
end)

-- ── 6. Player Reconnect Sync ──────────────────────────────────
local function syncPlayerStoryQuest(player)
	local pData = getPlayerData(player)
	if not pData or not pData.ActiveStoryQuests then return end
	for qId, activeEntry in pairs(pData.ActiveStoryQuests) do
		local quest = StoryQuestData.GetQuestById(qId)
		if quest then
			local progress = tonumber(activeEntry.progress) or 0
			if quest.objective == "Collect" and pData.Inventory then
				local count = 0
				local altId = (quest.target == "StickyMucus" and "Sticky_Mucus") or (quest.target == "Sticky_Mucus" and "StickyMucus")
				           or (quest.target == "IronOre" and "Iron_Ore") or (quest.target == "Iron_Ore" and "IronOre") or quest.target
				for _, entry in ipairs(pData.Inventory) do
					if type(entry) == "table" and (entry.itemId == quest.target or entry.itemId == altId) then
						count += (tonumber(entry.quantity) or 1)
					end
				end
				progress = count
				activeEntry.progress = progress
			end
			RE_StoryQuestUpdate:FireClient(player, quest.id, "accepted", progress, quest.amount)
			if progress > 0 then
				RE_StoryQuestUpdate:FireClient(player, quest.id, "progress", progress, quest.amount)
			end
			break
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	task.wait(1.5)
	syncPlayerStoryQuest(player)
end)

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		task.wait(1.0)
		syncPlayerStoryQuest(p)
	end)
end
