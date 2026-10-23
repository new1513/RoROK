local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GameData = ReplicatedStorage:WaitForChild("GameData")
local SkillData = require(GameData:WaitForChild("SkillData"))
local ItemData = require(GameData:WaitForChild("ItemData"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateCharacterData = RemoteEvents:WaitForChild("UpdateCharacterData")
local LearnSkill = RemoteEvents:WaitForChild("LearnSkill")
local SocketCard = RemoteEvents:WaitForChild("SocketCard")
local UnsocketCard = RemoteEvents:WaitForChild("UnsocketCard")
local TeleportToMap = RemoteEvents:WaitForChild("TeleportToMap")
local OpenWorldTravel = RemoteEvents:WaitForChild("OpenWorldTravel")
local GuildAction = RemoteEvents:WaitForChild("GuildAction")
local UpdateGuildData = RemoteEvents:FindFirstChild("UpdateGuildData") or RemoteEvents:WaitForChild("GuildUpdated", 5)

-- Wait briefly for UIManager to initialize HUD
local hudGui = playerGui:WaitForChild("HUD", 10) or playerGui:FindFirstChild("RoROK_HUD")
if not hudGui then
	hudGui = Instance.new("ScreenGui")
	hudGui.Name = "RoROK_ExpansionHUD"
	hudGui.ResetOnSpawn = false
	hudGui.IgnoreGuiInset = true
	hudGui.DisplayOrder = 12
	hudGui.Parent = playerGui
end

local Theme = {
	Obsidian = Color3.fromRGB(16, 18, 28),
	Slate = Color3.fromRGB(24, 28, 42),
	CardBg = Color3.fromRGB(30, 35, 52),
	Gold = Color3.fromRGB(235, 190, 95),
	GoldBright = Color3.fromRGB(255, 220, 120),
	GoldDark = Color3.fromRGB(130, 98, 42),
	Emerald = Color3.fromRGB(46, 204, 113),
	Coral = Color3.fromRGB(231, 76, 60),
	Cyan = Color3.fromRGB(72, 201, 255),
	Purple = Color3.fromRGB(165, 105, 255),
	TextWhite = Color3.fromRGB(245, 247, 252),
	TextMuted = Color3.fromRGB(168, 176, 198),
}

local function applyStyle(frame, radius, strokeColor, strokeThick, bgColor, bgTrans)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = frame
	if strokeColor then
		local s = Instance.new("UIStroke")
		s.Color = strokeColor
		s.Thickness = strokeThick or 1.5
		s.Transparency = 0.15
		s.Parent = frame
	end
	if bgColor then
		frame.BackgroundColor3 = bgColor
	end
	if bgTrans ~= nil then
		frame.BackgroundTransparency = bgTrans
	end
	return frame
end

-- State
local latestCharData = {
	Class = player:GetAttribute("Class") or "Novice",
	SkillPoints = player:GetAttribute("SkillPoints") or 0,
	Skills = {},
	Inventory = {},
	Equipment = {},
	EquipmentCards = {},
	Map = player:GetAttribute("Map") or "Prontera",
	Gold = player:GetAttribute("Gold") or 0,
}

local latestGuildState = {
	MyGuild = nil,
	GuildList = {},
	Message = nil,
}

-- ============================================================
-- 1. LEFT MENU SHORTCUT BUTTONS (Under Inventory E)
-- ============================================================
local function makeLeftShortcutButton(name, yOffset, iconText, labelText, accentColor)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 132, 0, 38)
	btn.Position = UDim2.new(0, 18, 0.5, yOffset)
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = hudGui
	applyStyle(btn, 10, accentColor or Theme.Gold, 1.5, Theme.Obsidian, 0.08)

	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.new(0, 26, 0, 26)
	badge.Position = UDim2.new(0, 7, 0.5, -13)
	badge.Text = iconText
	badge.TextSize = 14
	badge.Font = Enum.Font.GothamBold
	badge.TextColor3 = Theme.Obsidian
	badge.Parent = btn
	applyStyle(badge, 7, nil, 0, accentColor or Theme.Gold, 0)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -40, 1, 0)
	lbl.Position = UDim2.new(0, 38, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.TextColor3 = Theme.TextWhite
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = btn

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(32, 38, 58) }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Obsidian }):Play()
	end)
	return btn
end

-- Guild system is shelved for now (พักระบบกิลด์ไว้ก่อน เอาปุ่มกิลด์ออกตามคำขอ)
local guildToggleBtn = Instance.new("TextButton")
guildToggleBtn.Name = "GuildToggleBtn"
guildToggleBtn.Visible = false

-- ============================================================
-- 2. SKILL TREE & CARD SLOTTING WINDOW (K)
-- ============================================================
local skillWindow = Instance.new("Frame")
skillWindow.Name = "SkillAndCardWindow"
skillWindow.Size = UDim2.new(0, 560, 0, 440)
skillWindow.Position = UDim2.new(0.5, -280, 0.5, -220)
skillWindow.Visible = false
skillWindow.Parent = hudGui
applyStyle(skillWindow, 14, Theme.Gold, 2, Theme.Obsidian, 0.04)

local skillHeader = Instance.new("Frame")
skillHeader.Size = UDim2.new(1, 0, 0, 44)
skillHeader.Parent = skillWindow
applyStyle(skillHeader, 14, nil, 0, Theme.Slate, 0)

local skillTitle = Instance.new("TextLabel")
skillTitle.Size = UDim2.new(1, -180, 1, 0)
skillTitle.Position = UDim2.new(0, 16, 0, 0)
skillTitle.BackgroundTransparency = 1
skillTitle.Text = "✨ ผังสกิลอาชีพ & เสียบการ์ดอุปกรณ์ (K)"
skillTitle.TextColor3 = Theme.GoldBright
skillTitle.Font = Enum.Font.GothamBold
skillTitle.TextSize = 16
skillTitle.TextXAlignment = Enum.TextXAlignment.Left
skillTitle.Parent = skillHeader

local skillPtLabel = Instance.new("TextLabel")
skillPtLabel.Size = UDim2.new(0, 130, 0, 26)
skillPtLabel.Position = UDim2.new(1, -176, 0.5, -13)
skillPtLabel.Text = "Skill Points: 0"
skillPtLabel.TextColor3 = Theme.Cyan
skillPtLabel.Font = Enum.Font.GothamBold
skillPtLabel.TextSize = 12
skillPtLabel.Parent = skillHeader
applyStyle(skillPtLabel, 6, Theme.Cyan, 1, Theme.CardBg, 0.1)

local closeSkillBtn = Instance.new("TextButton")
closeSkillBtn.Size = UDim2.new(0, 30, 0, 30)
closeSkillBtn.Position = UDim2.new(1, -38, 0.5, -15)
closeSkillBtn.Text = "✕"
closeSkillBtn.TextColor3 = Theme.TextWhite
closeSkillBtn.Font = Enum.Font.GothamBold
closeSkillBtn.TextSize = 14
closeSkillBtn.Parent = skillHeader
applyStyle(closeSkillBtn, 8, nil, 0, Theme.Coral, 0.15)
closeSkillBtn.Activated:Connect(function()
	skillWindow.Visible = false
end)

-- Tab Bar
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -24, 0, 34)
tabBar.Position = UDim2.new(0, 12, 0, 50)
tabBar.BackgroundTransparency = 1
tabBar.Parent = skillWindow

local tabSkillsBtn = Instance.new("TextButton")
tabSkillsBtn.Size = UDim2.new(0.5, -4, 1, 0)
tabSkillsBtn.Position = UDim2.new(0, 0, 0, 0)
tabSkillsBtn.Text = "⚡ ผังสกิลอาชีพ (Skill Tree)"
tabSkillsBtn.TextColor3 = Theme.Obsidian
tabSkillsBtn.Font = Enum.Font.GothamBold
tabSkillsBtn.TextSize = 13
tabSkillsBtn.Parent = tabBar
applyStyle(tabSkillsBtn, 8, Theme.Gold, 1, Theme.Gold, 0)

local tabCardsBtn = Instance.new("TextButton")
tabCardsBtn.Size = UDim2.new(0.5, -4, 1, 0)
tabCardsBtn.Position = UDim2.new(0.5, 4, 0, 0)
tabCardsBtn.Text = "🃏 เสียบการ์ดอุปกรณ์ (Card Slots)"
tabCardsBtn.TextColor3 = Theme.TextWhite
tabCardsBtn.Font = Enum.Font.GothamBold
tabCardsBtn.TextSize = 13
tabCardsBtn.Parent = tabBar
applyStyle(tabCardsBtn, 8, Theme.GoldDark, 1, Theme.CardBg, 0)

-- Skills Content Page
local skillsPage = Instance.new("ScrollingFrame")
skillsPage.Size = UDim2.new(1, -24, 1, -98)
skillsPage.Position = UDim2.new(0, 12, 0, 90)
skillsPage.BackgroundTransparency = 1
skillsPage.BorderSizePixel = 0
skillsPage.ScrollBarThickness = 6
skillsPage.ScrollBarImageColor3 = Theme.Gold
skillsPage.CanvasSize = UDim2.new(0, 0, 0, 0)
skillsPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
skillsPage.Parent = skillWindow

local skillsLayout = Instance.new("UIListLayout")
skillsLayout.Padding = UDim.new(0, 8)
skillsLayout.SortOrder = Enum.SortOrder.LayoutOrder
skillsLayout.Parent = skillsPage

-- Cards Content Page
local cardsPage = Instance.new("Frame")
cardsPage.Size = UDim2.new(1, -24, 1, -98)
cardsPage.Position = UDim2.new(0, 12, 0, 90)
cardsPage.BackgroundTransparency = 1
cardsPage.Visible = false
cardsPage.Parent = skillWindow

local activeSkillTab = "Skills"
local refreshSkillAndCardUI

local function switchSkillCardTab(tabName)
	activeSkillTab = tabName
	if tabName == "Skills" then
		skillsPage.Visible = true
		cardsPage.Visible = false
		tabSkillsBtn.BackgroundColor3 = Theme.Gold
		tabSkillsBtn.TextColor3 = Theme.Obsidian
		tabCardsBtn.BackgroundColor3 = Theme.CardBg
		tabCardsBtn.TextColor3 = Theme.TextWhite
	else
		skillsPage.Visible = false
		cardsPage.Visible = true
		tabCardsBtn.BackgroundColor3 = Theme.Gold
		tabCardsBtn.TextColor3 = Theme.Obsidian
		tabSkillsBtn.BackgroundColor3 = Theme.CardBg
		tabSkillsBtn.TextColor3 = Theme.TextWhite
	end
	if refreshSkillAndCardUI then
		refreshSkillAndCardUI()
	end
end

tabSkillsBtn.Activated:Connect(function()
	switchSkillCardTab("Skills")
end)
tabCardsBtn.Activated:Connect(function()
	switchSkillCardTab("Cards")
end)

_G.OpenCardSlottingUI = function()
	skillWindow.Visible = true
	switchSkillCardTab("Cards")
end

refreshSkillAndCardUI = function()
	local sp = latestCharData.SkillPoints or player:GetAttribute("SkillPoints") or 0
	skillPtLabel.Text = "Skill Points: " .. tostring(sp)

	-- Clear Skills Page
	for _, child in ipairs(skillsPage:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local myClass = latestCharData.Class or player:GetAttribute("Class") or "Novice"
	local skillList = SkillData.GetSkillsByClass(myClass)
	if myClass ~= "Novice" then
		local novSkills = SkillData.GetSkillsByClass("Novice")
		for _, ns in ipairs(novSkills) do
			table.insert(skillList, 1, ns)
		end
	end

	for idx, sk in ipairs(skillList) do
		local curLv = (latestCharData.Skills and latestCharData.Skills[sk.id]) or 0
		if sk.id == "NoviceStrike" or sk.id == "FirstAid" then
			curLv = math.max(1, curLv)
		end
		local maxLv = sk.maxLevel or 10

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 76)
		row.LayoutOrder = idx
		row.Parent = skillsPage
		applyStyle(row, 10, curLv > 0 and Theme.Gold or Theme.GoldDark, 1, Theme.CardBg, 0.05)

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(0.58, 0, 0, 22)
		nameLbl.Position = UDim2.new(0, 12, 0, 6)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = string.format("%s (%s)  [Lv.%d/%d]", sk.nameThai or sk.name, sk.name, curLv, maxLv)
		nameLbl.TextColor3 = curLv > 0 and Theme.GoldBright or Theme.TextWhite
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 13
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Parent = row

		local descLbl = Instance.new("TextLabel")
		descLbl.Size = UDim2.new(0.62, 0, 0, 20)
		descLbl.Position = UDim2.new(0, 12, 0, 28)
		descLbl.BackgroundTransparency = 1
		descLbl.Text = sk.descThai or ""
		descLbl.TextColor3 = Theme.TextMuted
		descLbl.Font = Enum.Font.Gotham
		descLbl.TextSize = 11
		descLbl.TextXAlignment = Enum.TextXAlignment.Left
		descLbl.Parent = row

		local metaLbl = Instance.new("TextLabel")
		metaLbl.Size = UDim2.new(0.62, 0, 0, 18)
		metaLbl.Position = UDim2.new(0, 12, 0, 50)
		metaLbl.BackgroundTransparency = 1
		metaLbl.Text = string.format("💧 SP: %d   ⏱️ คูลดาวน์: %.1fs   🎯 ระยะ: %d", sk.spCost or 0, sk.cooldown or 1, sk.range or 6)
		metaLbl.TextColor3 = Theme.Cyan
		metaLbl.Font = Enum.Font.GothamMedium
		metaLbl.TextSize = 11
		metaLbl.TextXAlignment = Enum.TextXAlignment.Left
		metaLbl.Parent = row

		-- Upgrade Button
		local upBtn = Instance.new("TextButton")
		upBtn.Size = UDim2.new(0, 96, 0, 28)
		upBtn.Position = UDim2.new(1, -106, 0, 8)
		local canUp = (sp > 0) and (curLv < maxLv)
		upBtn.Text = curLv >= maxLv and "MAX" or "+ อัปสกิล"
		upBtn.TextColor3 = canUp and Theme.Obsidian or Theme.TextMuted
		upBtn.Font = Enum.Font.GothamBold
		upBtn.TextSize = 12
		upBtn.Parent = row
		applyStyle(upBtn, 7, nil, 0, canUp and Theme.Emerald or Theme.Slate, 0)

		upBtn.Activated:Connect(function()
			LearnSkill:FireServer(sk.id)
		end)

		-- Quick Assign Hotbar 1-5 buttons
		local assignLabel = Instance.new("TextLabel")
		assignLabel.Size = UDim2.new(0, 48, 0, 22)
		assignLabel.Position = UDim2.new(1, -210, 0, 44)
		assignLabel.BackgroundTransparency = 1
		assignLabel.Text = "ใส่ช่อง:"
		assignLabel.TextColor3 = Theme.TextMuted
		assignLabel.Font = Enum.Font.Gotham
		assignLabel.TextSize = 11
		assignLabel.Parent = row

		for slotNum = 1, 5 do
			local sBtn = Instance.new("TextButton")
			sBtn.Size = UDim2.new(0, 26, 0, 24)
			sBtn.Position = UDim2.new(1, -162 + (slotNum - 1) * 30, 0, 43)
			sBtn.Text = tostring(slotNum)
			sBtn.TextColor3 = Theme.TextWhite
			sBtn.Font = Enum.Font.GothamBold
			sBtn.TextSize = 11
			sBtn.Parent = row
			applyStyle(sBtn, 6, Theme.GoldDark, 1, Theme.Slate, 0)
			sBtn.Activated:Connect(function()
				if _G.AssignHotbarSkill then
					_G.AssignHotbarSkill(slotNum, sk.id)
				end
			end)
		end
	end

	-- Clear & Rebuild Cards Page
	for _, child in ipairs(cardsPage:GetChildren()) do
		child:Destroy()
	end

	local equipFrame = Instance.new("Frame")
	equipFrame.Size = UDim2.new(1, 0, 0, 118)
	equipFrame.Parent = cardsPage
	applyStyle(equipFrame, 10, Theme.GoldDark, 1, Theme.Slate, 0.1)

	local eqHeader = Instance.new("TextLabel")
	eqHeader.Size = UDim2.new(1, -16, 0, 24)
	eqHeader.Position = UDim2.new(0, 12, 0, 6)
	eqHeader.BackgroundTransparency = 1
	eqHeader.Text = "🛡️ ช่องการ์ดในอุปกรณ์ที่สวมใส่ (Equipment Card Sockets)"
	eqHeader.TextColor3 = Theme.GoldBright
	eqHeader.Font = Enum.Font.GothamBold
	eqHeader.TextSize = 13
	eqHeader.TextXAlignment = Enum.TextXAlignment.Left
	eqHeader.Parent = equipFrame

	local slotsToShow = {
		{ key = "Weapon", label = "⚔️ อาวุธ (Weapon)" },
		{ key = "Armor", label = "🥋 เกราะ (Armor)" },
	}

	for i, sInfo in ipairs(slotsToShow) do
		local slotBox = Instance.new("Frame")
		slotBox.Size = UDim2.new(0.48, 0, 0, 76)
		slotBox.Position = UDim2.new((i - 1) * 0.5 + 0.01, 0, 0, 34)
		slotBox.Parent = equipFrame
		applyStyle(slotBox, 8, Theme.Gold, 1, Theme.CardBg, 0)

		local eqId = latestCharData.Equipment and latestCharData.Equipment[sInfo.key]
		local eqDef = eqId and ItemData.Items[eqId]
		local cardId = latestCharData.EquipmentCards and latestCharData.EquipmentCards[sInfo.key]
		local cardDef = cardId and ItemData.Items[cardId]

		local stTitle = Instance.new("TextLabel")
		stTitle.Size = UDim2.new(1, -12, 0, 20)
		stTitle.Position = UDim2.new(0, 8, 0, 4)
		stTitle.BackgroundTransparency = 1
		stTitle.Text = sInfo.label .. ": " .. (eqDef and (eqDef.nameThai or eqDef.name) or "ไม่ได้สวมใส่")
		stTitle.TextColor3 = Theme.TextWhite
		stTitle.Font = Enum.Font.GothamBold
		stTitle.TextSize = 12
		stTitle.TextXAlignment = Enum.TextXAlignment.Left
		stTitle.Parent = slotBox

		local cStatus = Instance.new("TextLabel")
		cStatus.Size = UDim2.new(1, -90, 0, 40)
		cStatus.Position = UDim2.new(0, 8, 0, 26)
		cStatus.BackgroundTransparency = 1
		cStatus.TextWrapped = true
		cStatus.Text = cardDef and ("🃏 " .. (cardDef.nameThai or cardDef.name or "การ์ด") .. "\n(" .. (cardDef.descThai or cardDef.description or "") .. ")") or "✨ ช่องการ์ดว่าง (พร้อมเสียบการ์ด)"
		cStatus.TextColor3 = cardDef and Theme.Emerald or Theme.TextMuted
		cStatus.Font = Enum.Font.Gotham
		cStatus.TextSize = 11
		cStatus.TextXAlignment = Enum.TextXAlignment.Left
		cStatus.Parent = slotBox

		if cardId then
			local unBtn = Instance.new("TextButton")
			unBtn.Size = UDim2.new(0, 74, 0, 28)
			unBtn.Position = UDim2.new(1, -82, 0.5, -14)
			unBtn.Text = "ถอดการ์ด"
			unBtn.TextColor3 = Theme.TextWhite
			unBtn.Font = Enum.Font.GothamBold
			unBtn.TextSize = 11
			unBtn.Parent = slotBox
			applyStyle(unBtn, 6, nil, 0, Theme.Coral, 0)
			unBtn.Activated:Connect(function()
				UnsocketCard:FireServer(sInfo.key)
			end)
		end
	end

	-- Owned Cards List
	local ownedHeader = Instance.new("TextLabel")
	ownedHeader.Size = UDim2.new(1, 0, 0, 24)
	ownedHeader.Position = UDim2.new(0, 4, 0, 124)
	ownedHeader.BackgroundTransparency = 1
	ownedHeader.Text = "🎒 การ์ดมอนสเตอร์ในกระเป๋าของคุณ (คลิกเพื่อเสียบเข้าอุปกรณ์)"
	ownedHeader.TextColor3 = Theme.Cyan
	ownedHeader.Font = Enum.Font.GothamBold
	ownedHeader.TextSize = 13
	ownedHeader.TextXAlignment = Enum.TextXAlignment.Left
	ownedHeader.Parent = cardsPage

	local cardScroll = Instance.new("ScrollingFrame")
	cardScroll.Size = UDim2.new(1, 0, 1, -152)
	cardScroll.Position = UDim2.new(0, 0, 0, 150)
	cardScroll.BackgroundTransparency = 1
	cardScroll.BorderSizePixel = 0
	cardScroll.ScrollBarThickness = 5
	cardScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	cardScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	cardScroll.Parent = cardsPage

	local cLayout = Instance.new("UIListLayout")
	cLayout.Padding = UDim.new(0, 6)
	cLayout.Parent = cardScroll

	local foundAnyCard = false
	for _, entry in ipairs(latestCharData.Inventory or {}) do
		local cardId = entry.itemId or entry.id
		local count = tonumber(entry.quantity or entry.count) or 1
		local def = ItemData.Items and ItemData.Items[cardId] or ItemData[cardId]
		if def and def.type == "Card" and count > 0 then
			foundAnyCard = true
			local cRow = Instance.new("Frame")
			cRow.Size = UDim2.new(1, -8, 0, 52)
			cRow.Parent = cardScroll
			applyStyle(cRow, 8, Theme.Purple, 1, Theme.CardBg, 0)

			local cTitle = Instance.new("TextLabel")
			cTitle.Size = UDim2.new(0.68, 0, 0, 22)
			cTitle.Position = UDim2.new(0, 10, 0, 5)
			cTitle.BackgroundTransparency = 1
			cTitle.Text = string.format("🃏 %s x%d  [ช่อง: %s]", def.nameThai or def.name, count, def.slot or "Weapon")
			cTitle.TextColor3 = Theme.GoldBright
			cTitle.Font = Enum.Font.GothamBold
			cTitle.TextSize = 13
			cTitle.TextXAlignment = Enum.TextXAlignment.Left
			cTitle.Parent = cRow

			local cDesc = Instance.new("TextLabel")
			cDesc.Size = UDim2.new(0.68, 0, 0, 20)
			cDesc.Position = UDim2.new(0, 10, 0, 26)
			cDesc.BackgroundTransparency = 1
			cDesc.Text = def.descThai or def.description or ""
			cDesc.TextColor3 = Theme.TextMuted
			cDesc.Font = Enum.Font.Gotham
			cDesc.TextSize = 11
			cDesc.TextXAlignment = Enum.TextXAlignment.Left
			cDesc.Parent = cRow

			local sockBtn = Instance.new("TextButton")
			sockBtn.Size = UDim2.new(0, 110, 0, 32)
			sockBtn.Position = UDim2.new(1, -120, 0.5, -16)
			sockBtn.Text = "✨ เสียบการ์ด"
			sockBtn.TextColor3 = Theme.Obsidian
			sockBtn.Font = Enum.Font.GothamBold
			sockBtn.TextSize = 12
			sockBtn.Parent = cRow
			applyStyle(sockBtn, 7, nil, 0, Theme.Emerald, 0)

			sockBtn.Activated:Connect(function()
				SocketCard:FireServer(cardId)
			end)
		end
	end

	if not foundAnyCard then
		local emptyLbl = Instance.new("TextLabel")
		emptyLbl.Size = UDim2.new(1, 0, 0, 60)
		emptyLbl.BackgroundTransparency = 1
		emptyLbl.Text = "ยังไม่มีการ์ดในกระเป๋า — ล่ามอนสเตอร์หรือบอสเพื่อดรอปการ์ดมาเสียบอุปกรณ์!"
		emptyLbl.TextColor3 = Theme.TextMuted
		emptyLbl.Font = Enum.Font.Gotham
		emptyLbl.TextSize = 12
		emptyLbl.Parent = cardScroll
	end
end

-- ============================================================
-- 3. GUILD & GUILD HOUSE WINDOW (G)
-- ============================================================
local guildWindow = Instance.new("Frame")
guildWindow.Name = "GuildWindow"
guildWindow.Size = UDim2.new(0, 520, 0, 410)
guildWindow.Position = UDim2.new(0.5, -260, 0.5, -205)
guildWindow.Visible = false
guildWindow.Parent = hudGui
applyStyle(guildWindow, 14, Theme.Gold, 2, Theme.Obsidian, 0.04)

local gHeader = Instance.new("Frame")
gHeader.Size = UDim2.new(1, 0, 0, 44)
gHeader.Parent = guildWindow
applyStyle(gHeader, 14, nil, 0, Theme.Slate, 0)

local gTitle = Instance.new("TextLabel")
gTitle.Size = UDim2.new(1, -60, 1, 0)
gTitle.Position = UDim2.new(0, 16, 0, 0)
gTitle.BackgroundTransparency = 1
gTitle.Text = "🛡️ ระบบกิลด์ & บ้านกิลด์ (Guild & Guild House)"
gTitle.TextColor3 = Theme.GoldBright
gTitle.Font = Enum.Font.GothamBold
gTitle.TextSize = 16
gTitle.TextXAlignment = Enum.TextXAlignment.Left
gTitle.Parent = gHeader

local closeGuildBtn = Instance.new("TextButton")
closeGuildBtn.Size = UDim2.new(0, 30, 0, 30)
closeGuildBtn.Position = UDim2.new(1, -38, 0.5, -15)
closeGuildBtn.Text = "✕"
closeGuildBtn.TextColor3 = Theme.TextWhite
closeGuildBtn.Font = Enum.Font.GothamBold
closeGuildBtn.TextSize = 14
closeGuildBtn.Parent = gHeader
applyStyle(closeGuildBtn, 8, nil, 0, Theme.Coral, 0.15)
closeGuildBtn.Activated:Connect(function()
	guildWindow.Visible = false
end)

local guildBody = Instance.new("Frame")
guildBody.Size = UDim2.new(1, -24, 1, -58)
guildBody.Position = UDim2.new(0, 12, 0, 50)
guildBody.BackgroundTransparency = 1
guildBody.Parent = guildWindow

local function refreshGuildUI()
	for _, child in ipairs(guildBody:GetChildren()) do
		child:Destroy()
	end

	local myG = latestGuildState.MyGuild
	if myG then
		local infoCard = Instance.new("Frame")
		infoCard.Size = UDim2.new(1, 0, 0, 185)
		infoCard.Parent = guildBody
		applyStyle(infoCard, 10, Theme.Gold, 1.5, Theme.CardBg, 0)

		local gName = Instance.new("TextLabel")
		gName.Size = UDim2.new(1, -20, 0, 26)
		gName.Position = UDim2.new(0, 12, 0, 8)
		gName.BackgroundTransparency = 1
		gName.Text = string.format("🏰 %s   [บ้านกิลด์ Lv.%d / 5]", myG.name, myG.houseLevel or 1)
		gName.TextColor3 = Theme.GoldBright
		gName.Font = Enum.Font.GothamBold
		gName.TextSize = 16
		gName.TextXAlignment = Enum.TextXAlignment.Left
		gName.Parent = infoCard

		local gDesc = Instance.new("TextLabel")
		gDesc.Size = UDim2.new(1, -20, 0, 20)
		gDesc.Position = UDim2.new(0, 12, 0, 36)
		gDesc.BackgroundTransparency = 1
		gDesc.Text = myG.desc or ""
		gDesc.TextColor3 = Theme.TextMuted
		gDesc.Font = Enum.Font.Gotham
		gDesc.TextSize = 12
		gDesc.TextXAlignment = Enum.TextXAlignment.Left
		gDesc.Parent = infoCard

		local lv = myG.houseLevel or 1
		local buffText = string.format(
			"✨ บัฟบ้านกิลด์ถาวร: ATK +%d | DEF +%d | MaxHP +%d | ลดการเสีย EXP ตอนตาย 50%%\n💰 กองทุนอัปเกรดบ้านกิลด์: %d / %d Zeny   |   👥 สมาชิกออนไลน์: %d คน",
			lv * 3, lv * 2, lv * 20, myG.treasury or 0, myG.nextLevelCost or 500, myG.memberCount or 1
		)
		local buffLbl = Instance.new("TextLabel")
		buffLbl.Size = UDim2.new(1, -24, 0, 44)
		buffLbl.Position = UDim2.new(0, 12, 0, 62)
		buffLbl.BackgroundTransparency = 1
		buffLbl.TextWrapped = true
		buffLbl.Text = buffText
		buffLbl.TextColor3 = Theme.Emerald
		buffLbl.Font = Enum.Font.GothamMedium
		buffLbl.TextSize = 12
		buffLbl.TextXAlignment = Enum.TextXAlignment.Left
		buffLbl.Parent = infoCard

		-- Buttons Row
		local donateBtn = Instance.new("TextButton")
		donateBtn.Size = UDim2.new(0, 165, 0, 36)
		donateBtn.Position = UDim2.new(0, 12, 0, 136)
		donateBtn.Text = "💰 บริจาคอัปบ้าน (100z)"
		donateBtn.TextColor3 = Theme.Obsidian
		donateBtn.Font = Enum.Font.GothamBold
		donateBtn.TextSize = 12
		donateBtn.Parent = infoCard
		applyStyle(donateBtn, 8, nil, 0, Theme.Gold, 0)
		donateBtn.Activated:Connect(function()
			GuildAction:FireServer("Donate", 100)
		end)

		local tpHallBtn = Instance.new("TextButton")
		tpHallBtn.Size = UDim2.new(0, 165, 0, 36)
		tpHallBtn.Position = UDim2.new(0, 186, 0, 136)
		tpHallBtn.Text = "🏰 วาร์ปไปบ้านกิลด์"
		tpHallBtn.TextColor3 = Theme.Obsidian
		tpHallBtn.Font = Enum.Font.GothamBold
		tpHallBtn.TextSize = 12
		tpHallBtn.Parent = infoCard
		applyStyle(tpHallBtn, 8, nil, 0, Theme.Cyan, 0)
		tpHallBtn.Activated:Connect(function()
			GuildAction:FireServer("TeleportGuildHall")
			guildWindow.Visible = false
		end)

		local leaveBtn = Instance.new("TextButton")
		leaveBtn.Size = UDim2.new(0, 120, 0, 36)
		leaveBtn.Position = UDim2.new(1, -132, 0, 136)
		leaveBtn.Text = "ออกจากกิลด์"
		leaveBtn.TextColor3 = Theme.TextWhite
		leaveBtn.Font = Enum.Font.GothamBold
		leaveBtn.TextSize = 12
		leaveBtn.Parent = infoCard
		applyStyle(leaveBtn, 8, nil, 0, Theme.Coral, 0)
		leaveBtn.Activated:Connect(function()
			GuildAction:FireServer("Leave")
		end)
	else
		-- Create Guild Box
		local createBox = Instance.new("Frame")
		createBox.Size = UDim2.new(1, 0, 0, 56)
		createBox.Parent = guildBody
		applyStyle(createBox, 10, Theme.GoldDark, 1, Theme.CardBg, 0)

		local nameInput = Instance.new("TextBox")
		nameInput.Size = UDim2.new(0.62, 0, 0, 36)
		nameInput.Position = UDim2.new(0, 10, 0.5, -18)
		nameInput.PlaceholderText = "พิมพ์ชื่อกิลด์ใหม่ของคุณ..."
		nameInput.Text = ""
		nameInput.TextColor3 = Theme.TextWhite
		nameInput.Font = Enum.Font.Gotham
		nameInput.TextSize = 13
		nameInput.Parent = createBox
		applyStyle(nameInput, 8, Theme.GoldDark, 1, Theme.Slate, 0)

		local createBtn = Instance.new("TextButton")
		createBtn.Size = UDim2.new(0.33, 0, 0, 36)
		createBtn.Position = UDim2.new(0.65, 0, 0.5, -18)
		createBtn.Text = "⚔️ ก่อตั้งกิลด์ (500z)"
		createBtn.TextColor3 = Theme.Obsidian
		createBtn.Font = Enum.Font.GothamBold
		createBtn.TextSize = 12
		createBtn.Parent = createBox
		applyStyle(createBtn, 8, nil, 0, Theme.Gold, 0)
		createBtn.Activated:Connect(function()
			if nameInput.Text ~= "" then
				GuildAction:FireServer("Create", nameInput.Text)
			end
		end)
	end

	-- Server Guild List
	local listY = myG and 196 or 66
	local listScroll = Instance.new("ScrollingFrame")
	listScroll.Size = UDim2.new(1, 0, 1, -listY)
	listScroll.Position = UDim2.new(0, 0, 0, listY)
	listScroll.BackgroundTransparency = 1
	listScroll.BorderSizePixel = 0
	listScroll.ScrollBarThickness = 5
	listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	listScroll.Parent = guildBody

	local gLayout = Instance.new("UIListLayout")
	gLayout.Padding = UDim.new(0, 6)
	gLayout.Parent = listScroll

	for _, g in ipairs(latestGuildState.GuildList or {}) do
		local gRow = Instance.new("Frame")
		gRow.Size = UDim2.new(1, -6, 0, 52)
		gRow.Parent = listScroll
		applyStyle(gRow, 8, Theme.GoldDark, 1, Theme.Slate, 0)

		local glTitle = Instance.new("TextLabel")
		glTitle.Size = UDim2.new(0.7, 0, 0, 22)
		glTitle.Position = UDim2.new(0, 12, 0, 5)
		glTitle.BackgroundTransparency = 1
		glTitle.Text = string.format("🛡️ %s  [บ้านกิลด์ Lv.%d]", g.name, g.houseLevel or 1)
		glTitle.TextColor3 = Theme.GoldBright
		glTitle.Font = Enum.Font.GothamBold
		glTitle.TextSize = 13
		glTitle.TextXAlignment = Enum.TextXAlignment.Left
		glTitle.Parent = gRow

		local glSub = Instance.new("TextLabel")
		glSub.Size = UDim2.new(0.7, 0, 0, 18)
		glSub.Position = UDim2.new(0, 12, 0, 27)
		glSub.BackgroundTransparency = 1
		glSub.Text = g.desc or ""
		glSub.TextColor3 = Theme.TextMuted
		glSub.Font = Enum.Font.Gotham
		glSub.TextSize = 11
		glSub.TextXAlignment = Enum.TextXAlignment.Left
		glSub.Parent = gRow

		if not myG or myG.id ~= g.id then
			local jBtn = Instance.new("TextButton")
			jBtn.Size = UDim2.new(0, 100, 0, 32)
			jBtn.Position = UDim2.new(1, -110, 0.5, -16)
			jBtn.Text = "เข้าร่วมกิลด์"
			jBtn.TextColor3 = Theme.Obsidian
			jBtn.Font = Enum.Font.GothamBold
			jBtn.TextSize = 12
			jBtn.Parent = gRow
			applyStyle(jBtn, 7, nil, 0, Theme.Emerald, 0)
			jBtn.Activated:Connect(function()
				GuildAction:FireServer("Join", g.id)
			end)
		end
	end
end

-- ============================================================
-- 4. WORLD TRAVEL & DUNGEON MAP WINDOW (M / Harbor Ship)
-- ============================================================
local worldWindow = Instance.new("Frame")
worldWindow.Name = "WorldTravelWindow"
worldWindow.Size = UDim2.new(0, 600, 0, 470)
worldWindow.Position = UDim2.new(0.5, -280, 0.5, -215)
worldWindow.Visible = false
worldWindow.Parent = hudGui
applyStyle(worldWindow, 14, Theme.Gold, 2, Theme.Obsidian, 0.04)

local wHeader = Instance.new("Frame")
wHeader.Size = UDim2.new(1, 0, 0, 44)
wHeader.Parent = worldWindow
applyStyle(wHeader, 14, nil, 0, Theme.Slate, 0)

local wTitle = Instance.new("TextLabel")
wTitle.Size = UDim2.new(1, -60, 1, 0)
wTitle.Position = UDim2.new(0, 16, 0, 0)
wTitle.BackgroundTransparency = 1
wTitle.Text = "🌍 แผนที่โลก & วาร์ปดันเจี้ยน (World Map & Realms)"
wTitle.TextColor3 = Theme.GoldBright
wTitle.Font = Enum.Font.GothamBold
wTitle.TextSize = 16
wTitle.TextXAlignment = Enum.TextXAlignment.Left
wTitle.Parent = wHeader

local backToLocalMapBtn = Instance.new("TextButton")
backToLocalMapBtn.Size = UDim2.new(0, 130, 0, 30)
backToLocalMapBtn.Position = UDim2.new(1, -178, 0.5, -15)
backToLocalMapBtn.Text = "📍 แผนที่โซน (Local)"
backToLocalMapBtn.TextColor3 = Theme.TextWhite
backToLocalMapBtn.Font = Enum.Font.GothamBold
backToLocalMapBtn.TextSize = 11
backToLocalMapBtn.Parent = wHeader
applyStyle(backToLocalMapBtn, 8, nil, 0, Theme.CardBg, 0)
backToLocalMapBtn.Activated:Connect(function()
	worldWindow.Visible = false
	if _G.ToggleLocalMap then
		_G.ToggleLocalMap()
	end
end)

local closeWorldBtn = Instance.new("TextButton")
closeWorldBtn.Size = UDim2.new(0, 30, 0, 30)
closeWorldBtn.Position = UDim2.new(1, -38, 0.5, -15)
closeWorldBtn.Text = "✕"
closeWorldBtn.TextColor3 = Theme.TextWhite
closeWorldBtn.Font = Enum.Font.GothamBold
closeWorldBtn.TextSize = 14
closeWorldBtn.Parent = wHeader
applyStyle(closeWorldBtn, 8, nil, 0, Theme.Coral, 0.15)
closeWorldBtn.Activated:Connect(function()
	worldWindow.Visible = false
end)

local realmsData = {
	{
		id = "Prontera",
		title = "🏰 เมืองหลวง Prontera & หุบเขาล่ามอนสเตอร์ (Lv.1–12)",
		desc = "เมืองหลวงแห่งอาณาจักร Rune-Midgards จัตุรัสน้ำพุศักดิ์สิทธิ์ ร้านค้า โบสถ์ ลานประลองหลวง และทุ่งล่า Poring, Lunatic, Wolf, Zombie",
		bossInfo = "📍 ดินแดนเริ่มต้น • ไม่มีบอส MVP ประจำเมือง",
		accent = Theme.Emerald,
	},
	{
		id = "PronteraCulvert",
		title = "💀 ดันเจี้ยนสุสานใต้ดิน Prontera Culvert (Lv.12–20)",
		desc = "ท่อระบายน้ำโบราณและซากเรือโจรสลัดอับปาง! ล่า Thief Bug, Sohee และท้าดวลบอสดันเจี้ยน",
		bossInfo = "👑 [MVP] Drake Lv.20 [🟢 มีชีวิตอยู่/ALIVE]  •  💀 [Mini] Minorous Lv.18 [🟢 มีชีวิตอยู่]",
		accent = Theme.Purple,
	},
	{
		id = "Morroc",
		title = "🏜️ เมืองทะเลทราย Morroc & พีระมิดโบราณ (Lv.20–40)",
		desc = "โอเอซิสกลางทะเลทรายและพีระมิดฟาโรห์ ล่า Scorpion, Mummy, Sand Man และ World Boss",
		bossInfo = "👑 [World Boss] Eddga Lv.40 (พยัคฆ์เพลิง) [🟢 มีชีวิตอยู่ / ALIVE]",
		accent = Theme.Gold,
	},
	{
		id = "Amatsu",
		title = "🌸 เกาะซากุระเมืองน้ำ Amatsu & ปราสาทโชกุน (Lv.35–60)",
		desc = "ดินแดนอาทิตย์อุทัย เสาโทริอิกลางน้ำและปราสาทซากุระ ล่า Swordfish, Tengu",
		bossInfo = "👑 [World Boss] Turtle General Lv.60 (จอมพลเต่าพันปี) [🟢 มีชีวิตอยู่ / ALIVE]",
		accent = Theme.Cyan,
	},
}

for idx, rInfo in ipairs(realmsData) do
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -24, 0, 92)
	card.Position = UDim2.new(0, 12, 0, 54 + (idx - 1) * 100)
	card.Parent = worldWindow
	applyStyle(card, 10, rInfo.accent, 1.5, Theme.CardBg, 0.04)

	local rTitle = Instance.new("TextLabel")
	rTitle.Size = UDim2.new(1, -145, 0, 24)
	rTitle.Position = UDim2.new(0, 12, 0, 8)
	rTitle.BackgroundTransparency = 1
	rTitle.Text = rInfo.title
	rTitle.TextColor3 = rInfo.accent
	rTitle.Font = Enum.Font.GothamBold
	rTitle.TextSize = 14
	rTitle.TextXAlignment = Enum.TextXAlignment.Left
	rTitle.Parent = card

	local rDesc = Instance.new("TextLabel")
	rDesc.Size = UDim2.new(1, -145, 0, 40)
	rDesc.Position = UDim2.new(0, 12, 0, 34)
	rDesc.BackgroundTransparency = 1
	rDesc.TextWrapped = true
	rDesc.Text = rInfo.desc
	rDesc.TextColor3 = Theme.TextMuted
	rDesc.Font = Enum.Font.Gotham
	rDesc.TextSize = 11
	rDesc.TextXAlignment = Enum.TextXAlignment.Left
	rDesc.Parent = card

	local rBoss = Instance.new("TextLabel")
	rBoss.Size = UDim2.new(1, -145, 0, 18)
	rBoss.Position = UDim2.new(0, 12, 1, -22)
	rBoss.BackgroundTransparency = 1
	rBoss.Text = rInfo.bossInfo or ""
	rBoss.TextColor3 = Theme.GoldBright
	rBoss.Font = Enum.Font.GothamMedium
	rBoss.TextSize = 10
	rBoss.TextXAlignment = Enum.TextXAlignment.Left
	rBoss.Parent = card

	local goBtn = Instance.new("TextButton")
	goBtn.Size = UDim2.new(0, 120, 0, 42)
	goBtn.Position = UDim2.new(1, -132, 0.5, -21)
	goBtn.Text = "⚡ เดินทางทันที"
	goBtn.TextColor3 = Theme.Obsidian
	goBtn.Font = Enum.Font.GothamBold
	goBtn.TextSize = 13
	goBtn.Parent = card
	applyStyle(goBtn, 8, nil, 0, rInfo.accent, 0)

	goBtn.Activated:Connect(function()
		TeleportToMap:FireServer(rInfo.id)
		worldWindow.Visible = false
	end)
end

-- ============================================================
-- 4B. ADVENTURER HANDBOOK & MVP RADAR WINDOW (B - Ragnarok M Style)
-- ============================================================
local MonsterData = require(GameData:WaitForChild("MonsterData"))

local bookWindow = Instance.new("Frame")
bookWindow.Name = "AdventurerHandbookWindow"
bookWindow.Size = UDim2.new(0, 580, 0, 440)
bookWindow.Position = UDim2.new(0.5, -290, 0.5, -220)
bookWindow.Visible = false
bookWindow.Parent = hudGui
applyStyle(bookWindow, 14, Theme.Purple, 2, Theme.Obsidian, 0.04)

local bHeader = Instance.new("Frame")
bHeader.Size = UDim2.new(1, 0, 0, 44)
bHeader.Parent = bookWindow
applyStyle(bHeader, 14, nil, 0, Theme.Slate, 0)

local bTitle = Instance.new("TextLabel")
bTitle.Size = UDim2.new(1, -60, 1, 0)
bTitle.Position = UDim2.new(0, 16, 0, 0)
bTitle.BackgroundTransparency = 1
bTitle.Text = "📖 สมุดคู่มือนักผจญภัย & เรดาร์บอส MVP (Adventurer Handbook - B)"
bTitle.TextColor3 = Theme.GoldBright
bTitle.Font = Enum.Font.GothamBold
bTitle.TextSize = 15
bTitle.TextXAlignment = Enum.TextXAlignment.Left
bTitle.Parent = bHeader

local closeBookBtn = Instance.new("TextButton")
closeBookBtn.Size = UDim2.new(0, 30, 0, 30)
closeBookBtn.Position = UDim2.new(1, -38, 0.5, -15)
closeBookBtn.Text = "✕"
closeBookBtn.TextColor3 = Theme.TextWhite
closeBookBtn.Font = Enum.Font.GothamBold
closeBookBtn.TextSize = 14
closeBookBtn.Parent = bHeader
applyStyle(closeBookBtn, 8, nil, 0, Theme.Coral, 0.15)
closeBookBtn.Activated:Connect(function()
	bookWindow.Visible = false
end)

local bookScroll = Instance.new("ScrollingFrame")
bookScroll.Size = UDim2.new(1, -24, 1, -58)
bookScroll.Position = UDim2.new(0, 12, 0, 50)
bookScroll.BackgroundTransparency = 1
bookScroll.BorderSizePixel = 0
bookScroll.ScrollBarThickness = 6
bookScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
bookScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
bookScroll.Parent = bookWindow

local bookLayout = Instance.new("UIListLayout")
bookLayout.Padding = UDim.new(0, 8)
bookLayout.SortOrder = Enum.SortOrder.LayoutOrder
bookLayout.Parent = bookScroll

local monsterOrder = {
	"Poring", "Lunatic", "Wolf", "Zombie", "Skeleton",
	"ThiefBug", "Sohee", "Minorous", "Drake",
	"Scorpion", "Mummy", "SandMan", "Eddga",
	"Swordfish", "Tengu", "TurtleGeneral",
}

local function refreshHandbookUI()
	for _, c in ipairs(bookScroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end

	local mFolder = workspace:FindFirstChild("Monsters")
	local liveStatus = {}
	if mFolder then
		for _, m in ipairs(mFolder:GetChildren()) do
			local mid = m:GetAttribute("MonsterID")
			local hp = m:GetAttribute("HP") or 0
			if mid and hp > 0 then
				liveStatus[mid] = (liveStatus[mid] or 0) + 1
			end
		end
	end

	for idx, mid in ipairs(monsterOrder) do
		local mDef = MonsterData[mid]
		if mDef then
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -8, 0, 68)
			row.LayoutOrder = idx
			row.Parent = bookScroll
			local borderCol = mDef.IsWorldBoss and Theme.Coral or (mDef.IsBoss and Theme.Gold or Theme.GoldDark)
			applyStyle(row, 10, borderCol, 1.5, Theme.CardBg, 0.04)

			local badgeTag = mDef.IsWorldBoss and "👑 [MVP BOSS] " or (mDef.IsBoss and "💀 [MINI BOSS] " or "🐾 ")
			local mTitle = Instance.new("TextLabel")
			mTitle.Size = UDim2.new(0.65, 0, 0, 22)
			mTitle.Position = UDim2.new(0, 12, 0, 6)
			mTitle.BackgroundTransparency = 1
			mTitle.Text = string.format("%s%s (Lv.%d)  •  ธาตุ: %s", badgeTag, mDef.Name, mDef.Level, mDef.Element)
			mTitle.TextColor3 = mDef.IsWorldBoss and Theme.GoldBright or (mDef.IsBoss and Theme.Cyan or Theme.TextWhite)
			mTitle.Font = Enum.Font.GothamBold
			mTitle.TextSize = 13
			mTitle.TextXAlignment = Enum.TextXAlignment.Left
			mTitle.Parent = row

			local dropNames = {}
			for _, d in ipairs(mDef.Drops or {}) do
				local itId = d.itemId or d.ItemID
				local it = ItemData.Items and ItemData.Items[itId] or ItemData[itId]
				table.insert(dropNames, (it and (it.nameThai or it.name) or tostring(itId)))
			end

			local mStats = Instance.new("TextLabel")
			mStats.Size = UDim2.new(0.68, 0, 0, 34)
			mStats.Position = UDim2.new(0, 12, 0, 28)
			mStats.BackgroundTransparency = 1
			mStats.TextWrapped = true
			mStats.Text = string.format("❤️ HP: %d   ⚔️ ATK: %d   🛡️ DEF: %d   🗺️ แผนที่: %s\n🎁 ดรอปแรร์: %s",
				mDef.MaxHP, mDef.ATK, mDef.DEF, mDef.Map or "Prontera", table.concat(dropNames, ", "))
			mStats.TextColor3 = Theme.TextMuted
			mStats.Font = Enum.Font.Gotham
			mStats.TextSize = 11
			mStats.TextXAlignment = Enum.TextXAlignment.Left
			mStats.Parent = row

			local aliveCount = liveStatus[mid] or 0
			local warpBtn = Instance.new("TextButton")
			warpBtn.Size = UDim2.new(0, 132, 0, 38)
			warpBtn.Position = UDim2.new(1, -142, 0.5, -19)
			warpBtn.Text = (aliveCount > 0 and "🟢 มีชีวิต • " or "⏳ รอเกิด • ") .. "วาร์ปล่า"
			warpBtn.TextColor3 = Theme.Obsidian
			warpBtn.Font = Enum.Font.GothamBold
			warpBtn.TextSize = 11
			warpBtn.Parent = row
			applyStyle(warpBtn, 8, nil, 0, aliveCount > 0 and Theme.Emerald or Theme.Gold, 0)

			warpBtn.Activated:Connect(function()
				TeleportToMap:FireServer(mDef.Map or "Prontera")
				bookWindow.Visible = false
			end)
		end
	end
end

-- ============================================================
-- 5. EVENTS & KEYBOARD SHORTCUTS (K, G, M, B)
-- ============================================================
guildToggleBtn.Activated:Connect(function()
	guildWindow.Visible = not guildWindow.Visible
	if guildWindow.Visible then
		skillWindow.Visible = false
		worldWindow.Visible = false
		if bookWindow then bookWindow.Visible = false end
		GuildAction:FireServer("RequestSync")
		refreshGuildUI()
	end
end)

_G.ToggleWorldTravelWindow = function()
	worldWindow.Visible = not worldWindow.Visible
	if worldWindow.Visible then
		skillWindow.Visible = false
		guildWindow.Visible = false
		if bookWindow then bookWindow.Visible = false end
	end
end

UpdateCharacterData.OnClientEvent:Connect(function(data)
	if type(data) == "table" then
		for k, v in pairs(data) do
			latestCharData[k] = v
		end
		if skillWindow.Visible then
			refreshSkillAndCardUI()
		end
	end
end)

UpdateGuildData.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" then
		latestGuildState = payload
		if guildWindow.Visible then
			refreshGuildUI()
		end
	end
end)

OpenWorldTravel.OnClientEvent:Connect(function()
	worldWindow.Visible = true
	skillWindow.Visible = false
	guildWindow.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.K then
		-- K is handled by RagnarokPanels (new Skill Tree)
		skillWindow.Visible = false
	elseif input.KeyCode == Enum.KeyCode.G then
		-- Guild system is shelved for now (พักระบบกิลด์ไว้ก่อน)
		guildWindow.Visible = false
	elseif input.KeyCode == Enum.KeyCode.M then
		worldWindow.Visible = false
	elseif input.KeyCode == Enum.KeyCode.B then
		bookWindow.Visible = not bookWindow.Visible
		if bookWindow.Visible then
			refreshHandbookUI()
		end
	end
end)

_G.OpenCardSlottingUI = function()
	skillWindow.Visible = true
	switchSkillCardTab("Cards")
	if refreshSkillAndCardUI then
		refreshSkillAndCardUI()
	end
end

_G.ToggleLegacySkillCardWindow = function()
	skillWindow.Visible = not skillWindow.Visible
	if skillWindow.Visible then
		guildWindow.Visible = false
		worldWindow.Visible = false
		bookWindow.Visible = false
		refreshSkillAndCardUI()
	end
end

print("[RoROK] ExpansionUI (Skills K, Cards, Guild G, World Map M) initialized!")
