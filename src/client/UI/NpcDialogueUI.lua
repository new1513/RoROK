-- ============================================================
-- NpcDialogueUI.lua
-- StarterPlayerScripts.UI — RoROK (Ragnarok M Style NPC Dialogue & Story Quest)
-- หน้าต่างบทสนทนา NPC ประจำเมือง และระบบเควสเนื้อเรื่อง (1 ครั้งต่อบัญชี)
-- ============================================================

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local StoryQuestData = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("StoryQuestData"))

local NpcDialogueUI = {}

function NpcDialogueUI.init(player, playerGui, remotes, UITheme, minimapView, callbacks)
	local hex = UITheme.hex
	local makeInstance = UITheme.makeInstance
	callbacks = callbacks or {}

	local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
	local getStoryQuestRemote = remoteFolder:WaitForChild("GetStoryQuestState", 10)
	local acceptStoryQuestRemote = remoteFolder:WaitForChild("AcceptStoryQuest", 10)
	local claimStoryQuestRemote = remoteFolder:WaitForChild("ClaimStoryQuest", 10)
	local storyQuestUpdateRemote = remoteFolder:WaitForChild("StoryQuestUpdate", 10)
	local openNpcDialogueRemote = remoteFolder:WaitForChild("OpenNpcDialogue", 10)

	-- Sound effects
	local function playSfx(soundType)
		pcall(function()
			local sfx = Instance.new("Sound")
			sfx.Volume = 0.55
			if soundType == "accept" then
				sfx.SoundId = "rbxassetid://9114223171"
			elseif soundType == "complete" then
				sfx.SoundId = "rbxassetid://6023774844"
			else
				sfx.SoundId = "rbxassetid://6895079853"
			end
			sfx.Parent = playerGui
			sfx:Play()
			game:GetService("Debris"):AddItem(sfx, 2.0)
		end)
	end

	-- ── 1. Create Main Dialogue ScreenGui ─────────────────────
	local dialogueGui = makeInstance("ScreenGui", {
		Name = "RoROK_NpcDialogue",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 18,
	}, playerGui)

	-- Dialogue Modal Window
	local dialogWin = makeInstance("Frame", {
		Name = "DialogueWindow",
		Size = UDim2.new(0, 560, 0, 380),
		Position = UDim2.new(0.5, -280, 0.5, -190),
		BackgroundColor3 = hex("16172b"),
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 30,
	}, dialogueGui)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 12) }, dialogWin)
	makeInstance("UIStroke", { Color = hex("e5c158"), Thickness = 1.8 }, dialogWin)
	makeInstance("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, hex("1c1d35")),
			ColorSequenceKeypoint.new(1, hex("10101d")),
		}),
		Rotation = 90,
	}, dialogWin)

	-- Title Bar
	local titleBar = makeInstance("Frame", {
		Name = "TitleBar", Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = hex("1f1f38"), BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 31,
	}, dialogWin)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 12) }, titleBar)
	makeInstance("UIStroke", { Color = hex("38385e"), Thickness = 1 }, titleBar)

	local npcAvatarLabel = makeInstance("TextLabel", {
		Name = "NpcAvatar", Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(0, 10, 0, 6),
		BackgroundColor3 = hex("252542"), Text = "👤", TextSize = 22, ZIndex = 32,
	}, titleBar)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, npcAvatarLabel)
	makeInstance("UIStroke", { Color = hex("e5c158"), Thickness = 1 }, npcAvatarLabel)

	local npcNameLabel = makeInstance("TextLabel", {
		Name = "NpcName", Size = UDim2.new(0.65, 0, 0, 20), Position = UDim2.new(0, 54, 0, 6),
		BackgroundTransparency = 1, TextColor3 = hex("ffd700"), Font = Enum.Font.GothamBold,
		TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Text = "ชื่อ NPC", ZIndex = 32,
	}, titleBar)

	local npcTitleLabel = makeInstance("TextLabel", {
		Name = "NpcTitle", Size = UDim2.new(0.65, 0, 0, 16), Position = UDim2.new(0, 54, 0, 26),
		BackgroundTransparency = 1, TextColor3 = hex("94a3b8"), Font = Enum.Font.Gotham,
		TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Text = "ตำแหน่ง / ฉายา", ZIndex = 32,
	}, titleBar)

	local closeBtn = makeInstance("TextButton", {
		Name = "CloseBtn", Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -34, 0, 11),
		BackgroundColor3 = hex("b91c1c"), TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold, TextSize = 13, Text = "✕", ZIndex = 32,
	}, titleBar)
	makeInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, closeBtn)
	closeBtn.Activated:Connect(function()
		playSfx("click")
		dialogWin.Visible = false
	end)

	-- Speech Area
	local speechBox = makeInstance("Frame", {
		Name = "SpeechBox", Size = UDim2.new(1, -24, 0, 95), Position = UDim2.new(0, 12, 0, 56),
		BackgroundColor3 = hex("1f1f38"), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 31,
	}, dialogWin)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, speechBox)
	makeInstance("UIStroke", { Color = hex("38385e"), Thickness = 1 }, speechBox)

	local dialogueText = makeInstance("TextLabel", {
		Name = "DialogueText", Size = UDim2.new(1, -20, 1, -12), Position = UDim2.new(0, 10, 0, 6),
		BackgroundTransparency = 1, TextColor3 = hex("f1f5f9"), Font = Enum.Font.Gotham,
		TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, Text = "บทสนทนา...", ZIndex = 32,
	}, speechBox)

	-- Quest Details Card
	local questCard = makeInstance("Frame", {
		Name = "QuestCard", Size = UDim2.new(1, -24, 0, 160), Position = UDim2.new(0, 12, 0, 160),
		BackgroundColor3 = hex("141424"), BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 31,
	}, dialogWin)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, questCard)
	makeInstance("UIStroke", { Color = hex("e5c158"), Thickness = 1.2 }, questCard)

	local questTitleLabel = makeInstance("TextLabel", {
		Name = "QuestTitle", Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 10, 0, 6),
		BackgroundTransparency = 1, TextColor3 = hex("ffd700"), Font = Enum.Font.GothamBold,
		TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Text = "📜 เควสเนื้อเรื่อง: ก้าวแรกของนักผจญภัย", ZIndex = 32,
	}, questCard)

	local objectiveLabel = makeInstance("TextLabel", {
		Name = "ObjectiveLabel", Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 30),
		BackgroundTransparency = 1, TextColor3 = hex("7dd3fc"), Font = Enum.Font.GothamBold,
		TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Text = "🎯 เป้าหมาย: ปราบ Poring (0/5 ตัว)", ZIndex = 32,
	}, questCard)

	-- Progress Bar Background
	local progBarBg = makeInstance("Frame", {
		Name = "ProgBarBg", Size = UDim2.new(1, -20, 0, 8), Position = UDim2.new(0, 10, 0, 54),
		BackgroundColor3 = hex("252542"), BorderSizePixel = 0, ZIndex = 32,
	}, questCard)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, progBarBg)

	local progBarFill = makeInstance("Frame", {
		Name = "ProgBarFill", Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = hex("22c55e"), BorderSizePixel = 0, ZIndex = 33,
	}, progBarBg)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, progBarFill)

	-- Rewards Box
	local rewardsHeader = makeInstance("TextLabel", {
		Name = "RewardsHeader", Size = UDim2.new(1, -20, 0, 18), Position = UDim2.new(0, 10, 0, 68),
		BackgroundTransparency = 1, TextColor3 = hex("fef08a"), Font = Enum.Font.GothamBold,
		TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Text = "🎁 รางวัลตอบแทนภารกิจ:", ZIndex = 32,
	}, questCard)

	local rewardsText = makeInstance("TextLabel", {
		Name = "RewardsText", Size = UDim2.new(1, -20, 0, 62), Position = UDim2.new(0, 10, 0, 88),
		BackgroundTransparency = 1, TextColor3 = hex("cbd5e1"), Font = Enum.Font.Gotham,
		TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = "• Base EXP +10,000  • Job EXP +7,000  • 2,500 z\n• Poring Hood (ฮู้ดโพริ่ง) x1\n• Red Potion x25, Blue Potion x15",
		ZIndex = 32,
	}, questCard)

	-- Bottom Actions Frame
	local actionsFrame = makeInstance("Frame", {
		Name = "ActionsFrame", Size = UDim2.new(1, -24, 0, 40), Position = UDim2.new(0, 12, 1, -50),
		BackgroundTransparency = 1, ZIndex = 31,
	}, dialogWin)

	local acceptBtn = makeInstance("TextButton", {
		Name = "AcceptBtn", Size = UDim2.new(0, 170, 0, 36), Position = UDim2.new(0.5, -85, 0, 2),
		BackgroundColor3 = hex("287a48"), TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold, TextSize = 12, Text = "⚔️ รับภารกิจ", ZIndex = 32,
	}, actionsFrame)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, acceptBtn)
	makeInstance("UIStroke", { Color = hex("e5c158"), Thickness = 1.2 }, acceptBtn)

	local claimBtn = makeInstance("TextButton", {
		Name = "ClaimBtn", Size = UDim2.new(0, 240, 0, 36), Position = UDim2.new(0.5, -120, 0, 2),
		BackgroundColor3 = hex("d97706"), TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold, TextSize = 13, Text = "🎁 ส่งภารกิจ & รับรางวัล!",
		Visible = false, ZIndex = 32,
	}, actionsFrame)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, claimBtn)
	makeInstance("UIStroke", { Color = hex("ffd700"), Thickness = 1.5 }, claimBtn)

	local inProgBtn = makeInstance("TextButton", {
		Name = "InProgBtn", Size = UDim2.new(0, 220, 0, 36), Position = UDim2.new(0.5, -110, 0, 2),
		BackgroundColor3 = hex("334155"), TextColor3 = hex("94a3b8"),
		Font = Enum.Font.GothamBold, TextSize = 12, Text = "🏃 กำลังดำเนินการ (ยังไม่เสร็จ)",
		AutoButtonColor = false, Visible = false, ZIndex = 32,
	}, actionsFrame)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, inProgBtn)

	local dismissBtn = makeInstance("TextButton", {
		Name = "DismissBtn", Size = UDim2.new(0, 140, 0, 36), Position = UDim2.new(0.5, -70, 0, 2),
		BackgroundColor3 = hex("1e293b"), TextColor3 = hex("cbd5e1"),
		Font = Enum.Font.GothamBold, TextSize = 12, Text = "✓ รับทราบ",
		Visible = false, ZIndex = 32,
	}, actionsFrame)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, dismissBtn)

	dismissBtn.Activated:Connect(function()
		playSfx("click")
		dialogWin.Visible = false
	end)

	-- ── 2. HUD Active Story Quest Tracker (Right Screen) ───────
	local hudTracker = makeInstance("Frame", {
		Name = "StoryQuestTracker",
		Size = UDim2.new(0, 230, 0, 64),
		Position = UDim2.new(1, -242, 0, 185), -- Right side below minimap
		BackgroundColor3 = hex("141829"),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 15,
	}, dialogueGui)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, hudTracker)
	makeInstance("UIStroke", { Color = hex("e5c158"), Thickness = 1.2 }, hudTracker)

	local trackerHeader = makeInstance("TextLabel", {
		Name = "TrackerHeader", Size = UDim2.new(1, -16, 0, 18), Position = UDim2.new(0, 8, 0, 4),
		BackgroundTransparency = 1, TextColor3 = hex("ffd700"), Font = Enum.Font.GothamBold,
		TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Text = "📜 เควสเนื้อเรื่อง (Story)", ZIndex = 16,
	}, hudTracker)

	local trackerTitle = makeInstance("TextLabel", {
		Name = "TrackerTitle", Size = UDim2.new(1, -16, 0, 18), Position = UDim2.new(0, 8, 0, 22),
		BackgroundTransparency = 1, TextColor3 = hex("f1f5f9"), Font = Enum.Font.GothamSemibold,
		TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Text = "ชื่อเควส", ZIndex = 16,
	}, hudTracker)

	local trackerObjective = makeInstance("TextLabel", {
		Name = "TrackerObjective", Size = UDim2.new(1, -16, 0, 18), Position = UDim2.new(0, 8, 0, 40),
		BackgroundTransparency = 1, TextColor3 = hex("7dd3fc"), Font = Enum.Font.Gotham,
		TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Text = "🎯 ปราบ Poring: 0/5 ตัว", ZIndex = 16,
	}, hudTracker)

	-- ── 3. Open Dialogue Logic ─────────────────────────────────
	
	local function formatObjectiveText(q, prog)
		prog = prog or 0
		if q.objective == "Collect" then
			if q.secondaryCollectTarget then
				return string.format("📦 เป้าหมาย: รวบรวม %s (%d/%d ชิ้น) & %s", q.targetName, prog, q.amount, q.secondaryCollectTarget)
			else
				return string.format("📦 เป้าหมาย: รวบรวม %s (%d/%d ชิ้น)", q.targetName, prog, q.amount)
			end
		elseif q.objective == "Kill" then
			if q.collectTarget then
				return string.format("🎯 เป้าหมาย: ปราบ %s (%d/%d ตัว) & 🥕 หา %s", q.targetName, prog, q.amount, q.collectTarget)
			else
				return string.format("🎯 เป้าหมาย: ปราบ %s (%d/%d ตัว)", q.targetName, prog, q.amount)
			end
		elseif q.objective == "Visit" then
			return string.format("📍 เป้าหมาย: ไปพบและสนทนากับ %s", q.npcName or q.targetName)
		end
		return string.format("🎯 เป้าหมาย: %s (%d/%d)", q.targetName, prog, q.amount)
	end

	local function formatTrackerText(q, prog, total)
		prog = prog or 0
		total = total or q.amount or 1
		if q.objective == "Collect" then
			return string.format("📦 %s: %d/%d ชิ้น", q.targetName, prog, total)
		elseif q.objective == "Kill" then
			return string.format("🎯 %s: %d/%d ตัว", q.targetName, prog, total)
		elseif q.objective == "Visit" then
			return string.format("📍 ไปพบ: %s", q.npcName or q.targetName)
		end
		return string.format("🎯 %s: %d/%d", q.targetName, prog, total)
	end

	local currentActiveQuest = nil

	local function openDialogueForNpc(npcId)
		if not getStoryQuestRemote then return end
		local stateData = getStoryQuestRemote:InvokeServer(npcId)
		if not stateData then return end

		dialogWin.Visible = true
		currentActiveQuest = stateData.quest

		npcNameLabel.Text = stateData.npcName or npcId
		npcTitleLabel.Text = stateData.npcTitle or "ชาวเมือง Prontera"
		npcAvatarLabel.Text = stateData.quest and stateData.quest.npcAvatar or "👤"
		dialogueText.Text = stateData.dialogue or "สวัสดีนักผจญภัย!"

		-- Hide all buttons first
		acceptBtn.Visible = false
		claimBtn.Visible = false
		inProgBtn.Visible = false
		dismissBtn.Visible = false

		if stateData.status == "no_quest" or stateData.status == "locked" or stateData.status == "locked_level" or stateData.status == "completed" then
			questCard.Visible = false
			dismissBtn.Visible = true
		elseif stateData.status == "available" and stateData.quest then
			questCard.Visible = true
			acceptBtn.Visible = true
			local q = stateData.quest
			questTitleLabel.Text = "📜 เควสเนื้อเรื่อง: " .. q.title
			objectiveLabel.Text = formatObjectiveText(q, 0)
			progBarFill.Size = UDim2.new(0, 0, 1, 0)

			-- Rewards format
			local rLines = {
				string.format("• Base EXP +%d  • Job EXP +%d  • %d z", q.rewardXP, q.rewardJobXP, q.rewardGold),
			}
			if q.rewardItems then
				local itemStrs = {}
				for _, it in ipairs(q.rewardItems) do
					table.insert(itemStrs, string.format("%s x%d", it.name or it.itemId, it.count or 1))
				end
				table.insert(rLines, "• " .. table.concat(itemStrs, ", "))
			end
			if q.rewardClassWeapon then
				table.insert(rLines, "• อาวุธฝึกหัดประจำสายอาชีพ x1")
			end
			rewardsText.Text = table.concat(rLines, "\n")

		elseif stateData.status == "in_progress" and stateData.quest then
			questCard.Visible = true
			inProgBtn.Visible = true
			local q = stateData.quest
			local prog = stateData.progress or 0
			local pct = math.clamp(prog / q.amount, 0, 1)
			questTitleLabel.Text = "📜 เควสเนื้อเรื่อง: " .. q.title
			objectiveLabel.Text = formatObjectiveText(q, prog)
			progBarFill.Size = UDim2.new(pct, 0, 1, 0)
			inProgBtn.Text = string.format("🏃 กำลังดำเนินการ (%d/%d)", prog, q.amount)

		elseif stateData.status == "ready_to_claim" and stateData.quest then
			questCard.Visible = true
			claimBtn.Visible = true
			local q = stateData.quest
			questTitleLabel.Text = "📜 เควสเนื้อเรื่อง: " .. q.title
			objectiveLabel.Text = string.format("✓ เป้าหมายสำเร็จครบถ้วน! (%d/%d)", q.amount, q.amount)
			progBarFill.Size = UDim2.new(1, 0, 1, 0)
			progBarFill.BackgroundColor3 = hex("eab308")
		end
	end

	-- Connect Accept Button
	acceptBtn.Activated:Connect(function()
		if currentActiveQuest and acceptStoryQuestRemote then
			playSfx("accept")
			acceptStoryQuestRemote:FireServer(currentActiveQuest.id)
			dialogWin.Visible = false
			hudTracker.Visible = true
			trackerTitle.Text = currentActiveQuest.title
			trackerObjective.Text = formatTrackerText(currentActiveQuest, 0, currentActiveQuest.amount)
		end
	end)

	-- Connect Claim Button
	claimBtn.Activated:Connect(function()
		if currentActiveQuest and claimStoryQuestRemote then
			playSfx("complete")
			claimStoryQuestRemote:FireServer(currentActiveQuest.id)
			dialogWin.Visible = false
			hudTracker.Visible = false
			currentActiveQuest = nil
		end
	end)

	-- ── 4. Remote Listeners ────────────────────────────────────
	if openNpcDialogueRemote then
		openNpcDialogueRemote.OnClientEvent:Connect(function(npcId)
			openDialogueForNpc(npcId)
		end)
	end

	if storyQuestUpdateRemote then
		storyQuestUpdateRemote.OnClientEvent:Connect(function(questId, action, progress, totalAmount)
			local quest = StoryQuestData.GetQuestById(questId)
			if not quest then return end

			if action == "accepted" then
				hudTracker.Visible = true
				trackerTitle.Text = quest.title
				trackerObjective.Text = formatTrackerText(quest, progress or 0, totalAmount or quest.amount)
			elseif action == "progress" then
				hudTracker.Visible = true
				trackerTitle.Text = quest.title
				if progress >= totalAmount then
					trackerObjective.Text = string.format("🎁 สำเร็จ! กลับไปหา %s", quest.npcName)
					trackerObjective.TextColor3 = hex("ffd700")
				else
					trackerObjective.Text = formatTrackerText(quest, progress, totalAmount)
					trackerObjective.TextColor3 = hex("7dd3fc")
				end
			elseif action == "claimed" then
				hudTracker.Visible = false
			end
		end)
	end

	_G.OpenTownNpcDialogue = openDialogueForNpc

	return {
		openDialogue = openDialogueForNpc,
		dialogueWin = dialogWin,
		hudTracker = hudTracker,
	}
end

return NpcDialogueUI
