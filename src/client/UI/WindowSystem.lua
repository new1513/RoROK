-- ============================================================
-- WindowSystem.lua
-- RoROK — Windows (Character Stats, Inventory, Refine, Shop,
--                  World Map, Mission Board, Skills, Esc Menu)
-- ============================================================

local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WindowSystem = {}

function WindowSystem.init(player, playerGui, remotes, UITheme, minimapView, callbacks)
	local hex = UITheme.hex
	local makeInstance = UITheme.makeInstance
	callbacks = callbacks or {}

	local classData = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("ClassData"))
	local itemData = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("ItemData"))
	local itemRarity = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("ItemRarity"))

	-- Remote references
	local distributeStatRemote = remotes.distributeStatRemote or remotes.DistributeStatPoint
	local changeClassRemote = remotes.changeClassRemote or remotes.ChangeClass
	local studioGrantJobXPRemote = remotes.studioGrantJobXPRemote or remotes.StudioGrantJobXP
	local openTutorialEvent = remotes.openTutorialEvent or remotes.OpenTutorial
	local requestInventoryRemote = remotes.requestInventoryRemote or remotes.RequestInventory
	local equipItemRemote = remotes.equipItemRemote or remotes.EquipItem
	local unequipItemRemote = remotes.unequipItemRemote or remotes.UnequipItem
	local dropItemRemote = remotes.dropItemRemote or remotes.DropItem
	local useConsumableRemote = remotes.useConsumableRemote or remotes.UseConsumable
	local refineEquipmentRemote = remotes.refineEquipmentRemote or remotes.RefineEquipment
	local openRefinementEvent = remotes.openRefinementEvent or remotes.OpenRefinement
	local openSupplyShopEvent = remotes.openSupplyShopEvent or remotes.OpenSupplyShop
	local purchaseShopItemRemote = remotes.purchaseShopItemRemote or remotes.PurchaseShopItem
	local sellShopItemRemote = remotes.sellShopItemRemote or remotes.SellShopItem
	local openDailyQuestsEvent = remotes.openDailyQuestsEvent or remotes.OpenDailyQuests
	local dailyQuestUpdateEvent = remotes.dailyQuestUpdateEvent or remotes.DailyQuestUpdate
	local acceptDailyQuestRemote = remotes.acceptDailyQuestRemote or remotes.AcceptDailyQuest
	local claimDailyQuestRemote = remotes.claimDailyQuestRemote or remotes.ClaimDailyQuest
	local getDailyQuestsRemote = remotes.getDailyQuestsRemote or remotes.GetDailyQuests

	-- ── Windows ScreenGui ─────────────────────────────────────
	local windowGui = makeInstance("ScreenGui", {
		Name           = "Windows",
		ResetOnSpawn   = false,
		IgnoreGuiInset = true,
		DisplayOrder   = 25,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)

	-- ── Window Factory ────────────────────────────────────────
	local function createWindow(name, title, size, position)
		local win = makeInstance("Frame", {
			Name             = name,
			Size             = size or UDim2.new(0, 400, 0, 500),
			Position         = position or UDim2.new(0.5, -200, 0.5, -250),
			BackgroundColor3 = hex("0d1322"),
			BackgroundTransparency = 0.04,
			BorderSizePixel  = 0,
			Visible          = false,
			ZIndex           = 5,
		}, windowGui)
		makeInstance("UICorner", {CornerRadius = UDim.new(0, 12)}, win)
		makeInstance("UIStroke", {Color = hex("e5c158"), Thickness = 1.8}, win)
		makeInstance("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, hex("1a243d")),
				ColorSequenceKeypoint.new(1, hex("0c111d")),
			}),
			Rotation = 90,
		}, win)

		local titleBar = makeInstance("Frame", {
			Name             = "TitleBar",
			Size             = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = hex("141d33"),
			BorderSizePixel  = 0,
			ZIndex           = 6,
		}, win)
		makeInstance("UICorner", {CornerRadius = UDim.new(0, 12)}, titleBar)

		makeInstance("Frame", {
			Name = "TitleAccentLine",
			Size = UDim2.new(1, -20, 0, 1),
			Position = UDim2.new(0, 10, 1, -1),
			BackgroundColor3 = hex("e5c158"),
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			ZIndex = 7,
		}, titleBar)

		makeInstance("TextLabel", {
			Size             = UDim2.new(1, -48, 1, 0),
			Position         = UDim2.new(0, 14, 0, 0),
			BackgroundTransparency = 1,
			TextColor3       = hex("f3cf7a"),
			Font             = Enum.Font.GothamBold,
			TextSize         = 15,
			TextXAlignment   = Enum.TextXAlignment.Left,
			Text             = title,
			ZIndex           = 7,
		}, titleBar)

		local closeBtn = makeInstance("TextButton", {
			Name             = "CloseBtn",
			Size             = UDim2.new(0, 28, 0, 28),
			Position         = UDim2.new(1, -34, 0, 6),
			BackgroundColor3 = hex("9e2a35"),
			TextColor3       = Color3.new(1, 1, 1),
			Font             = Enum.Font.GothamBold,
			TextSize         = 13,
			Text             = "✕",
			ZIndex           = 7,
		}, titleBar)
		makeInstance("UICorner", {CornerRadius = UDim.new(1, 0)}, closeBtn)
		makeInstance("UIStroke", {Color = hex("f48c96"), Thickness = 1}, closeBtn)
		closeBtn.Activated:Connect(function() win.Visible = false end)

		local content = makeInstance("Frame", {
			Name             = "Content",
			Size             = UDim2.new(1, -20, 1, -50),
			Position         = UDim2.new(0, 10, 0, 44),
			BackgroundTransparency = 1,
			ZIndex           = 5,
		}, win)

		local dragging = false
		local dragStart, startPos
		titleBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging  = true
				dragStart = input.Position
				startPos  = win.Position
			end
		end)
		titleBar.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				win.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end)

		return win, content
	end

	local function openWindow(win)
		win.Visible = true
		win.BackgroundTransparency = 1
		local tween = TweenService:Create(win,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 0.05}
		)
		tween:Play()
	end

	local function closeWindow(win)
		win.Visible = false
	end

	local function toggleWindow(win)
		if win.Visible then
			closeWindow(win)
		else
			openWindow(win)
		end
	end

	-- ── 1. Character Status Window (C Key) ─────────────────────
	local statsWin, statsContent = createWindow(
		"Stats", "📊 ค่าสถานะ / Status",
		UDim2.new(0, 390, 0, 510),
		UDim2.new(0.5, -195, 0.5, -255)
	)

	local statPointsLabel = makeInstance("TextLabel", {
		Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1, TextColor3 = hex("ffd700"),
		Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "แต้มคงเหลือ: 0",
	}, statsContent)

	local statDescriptions = {
		STR = "โจมตีกายภาพ / น้ำหนัก", AGI = "ความเร็วโจมตี / หลบหลีก",
		VIT = "HP / ฟื้นฟู / ป้องกันกายภาพ", INT = "เวทมนตร์ / SP / ป้องกันเวท",
		DEX = "แม่นยำ / ลดเวลาร่าย", LUK = "คริติคอล / หลบสมบูรณ์",
	}
	local statLabels = {}

	local combatSummary = makeInstance("TextLabel", {
		Name = "CombatSummary", Size = UDim2.new(1, 0, 0, 38), Position = UDim2.new(0, 0, 0, 284),
		BackgroundTransparency = 1, TextColor3 = hex("9fe8ff"), Font = Enum.Font.GothamBold,
		TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		Text = "ATK --  MATK --  DEF --  ASPD --  ระยะ --\nMaxHP --",
	}, statsContent)

	for index, statName in ipairs({"STR", "AGI", "VIT", "INT", "DEX", "LUK"}) do
		local y = 34 + (index - 1) * 42
		local label = makeInstance("TextLabel", {
			Name = statName .. "Row", Size = UDim2.new(1, -54, 0, 38),
			Position = UDim2.new(0, 0, 0, y), BackgroundColor3 = hex("252542"),
			TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.Gotham,
			TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
			Text = statName .. "  1  |  " .. statDescriptions[statName],
		}, statsContent)
		makeInstance("UICorner", {CornerRadius = UDim.new(0, 6)}, label)
		statLabels[statName] = label

		local addButton = makeInstance("TextButton", {
			Name = "Add" .. statName, Size = UDim2.new(0, 44, 0, 38),
			Position = UDim2.new(1, -46, 0, y), BackgroundColor3 = hex("287a48"),
			TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
			TextSize = 20, Text = "+",
		}, statsContent)
		makeInstance("UICorner", {CornerRadius = UDim.new(0, 6)}, addButton)
		addButton.Activated:Connect(function()
			if distributeStatRemote then distributeStatRemote:FireServer(statName) end
		end)
	end

	local classHeader = makeInstance("TextLabel", {
		Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 308),
		BackgroundTransparency = 1, TextColor3 = hex("ffd700"),
		Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "เลือกอาชีพขั้นแรก (Novice Job Lv.10)",
	}, statsContent)

	local classButtons = {}
	for index, className in ipairs({"Acolyte", "Knight", "Mage", "Archer", "Thief", "Merchant"}) do
		local column = (index - 1) % 2
		local row = math.floor((index - 1) / 2)
		local button = makeInstance("TextButton", {
			Name = "Choose" .. className, Size = UDim2.new(0.5, -4, 0, 30),
			Position = UDim2.new(column * 0.5, column == 1 and 4 or 0, 0, 336 + row * 31),
			BackgroundColor3 = hex("34446a"), TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBold, TextSize = 12, Text = className, Visible = false,
		}, statsContent)
		makeInstance("UICorner", {CornerRadius = UDim.new(0, 6)}, button)
		button.Activated:Connect(function()
			if changeClassRemote then changeClassRemote:FireServer(className) end
		end)
		classButtons[className] = button
	end

	local studioJobTestButton = makeInstance("TextButton", {
		Name = "StudioJobLevelTest",
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 0, 432),
		BackgroundColor3 = hex("725b2a"),
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		Text = "ทดสอบใน Studio: รับ Job EXP ถึง Lv.10",
		Visible = RunService:IsStudio(),
	}, statsContent)
	makeInstance("UICorner", {CornerRadius = UDim.new(0, 6)}, studioJobTestButton)
	studioJobTestButton.Activated:Connect(function()
		if studioGrantJobXPRemote then studioGrantJobXPRemote:FireServer() end
	end)

	local function renderStats(data)
		if not data or not statsWin.Visible then return end
		local values = data.Stats or {}
		statPointsLabel.Text = string.format("แต้มคงเหลือ: %d", data.StatPoints or 0)
		local descriptions = table.clone(statDescriptions)
		if data.Class == "Archer" then
			descriptions.STR = "น้ำหนัก / พลังโจมตีรอง"
			descriptions.DEX = "พลังโจมตีธนู / แม่นยำ / ลดเวลาร่าย"
		elseif data.Class == "Mage" then
			descriptions.STR = "พลังโจมตีประชิด / น้ำหนัก"
			descriptions.INT = "พลังเวท / SP / ป้องกันเวท"
		end
		for statName, label in pairs(statLabels) do
			label.Text = string.format("%s  %d  |  %s", statName, values[statName] or 1, descriptions[statName])
		end
		combatSummary.Text = string.format("ATK %d  MATK %d-%d  DEF %d  ASPD %d  ระยะ %d\nMaxHP %d",
			data.ATK or 0, data.MATK_min or 0, data.MATK_max or 0, data.DEF or 0,
			data.ASPD or 0, data.AttackRange or 18, data.MaxHP or 0)
		local canChooseClass = data.Class == "Novice" and (data.JobLevel or 1) >= 10
		classHeader.Visible = canChooseClass
		for _, button in pairs(classButtons) do button.Visible = canChooseClass end
	end

	-- ── 2. Tutorial Overlay ───────────────────────────────────
	local tutorialOverlay = makeInstance("Frame", {
		Name = "TutorialOverlay", Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35,
		Visible = false, ZIndex = 30,
	}, playerGui:WaitForChild("HUD", 5) or windowGui)

	local tutorialCard = makeInstance("Frame", {
		Size = UDim2.new(0, 510, 0, 310), Position = UDim2.new(0.5, -255, 0.5, -155),
		BackgroundColor3 = hex("1a1a2e"), BorderSizePixel = 0, ZIndex = 31,
	}, tutorialOverlay)
	makeInstance("UICorner", {CornerRadius = UDim.new(0, 12)}, tutorialCard)
	makeInstance("UIStroke", {Color = hex("ffd700"), Thickness = 2}, tutorialCard)

	makeInstance("TextLabel", {
		Size = UDim2.new(1, -32, 0, 42), Position = UDim2.new(0, 16, 0, 12),
		BackgroundTransparency = 1, TextColor3 = hex("ffd700"), Font = Enum.Font.GothamBold,
		TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, Text = "ยินดีต้อนรับสู่ Prontera!",
		ZIndex = 32,
	}, tutorialCard)

	makeInstance("TextLabel", {
		Size = UDim2.new(1, -32, 0, 178), Position = UDim2.new(0, 16, 0, 58),
		BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.Gotham, TextSize = 15, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		Text = "WASD เดิน • คลิกมอนเพื่อเลือก/โจมตี • เปิด Auto เพื่อโจมตีซ้ำ • กด 1 แล้วคลิกเพื่อเลือกเป้าสกิล\nกด C เปิดค่าสถานะ • กด E หรือปุ่มกระเป๋า • กด F เก็บของ/โต้ตอบ • กด J ดูเควสประจำวัน\nกด + เพื่อใช้ Stat Points ในหน้าต่าง C\nSTR=โจมตีกายภาพ  AGI=เร็ว/หลบ  VIT=HP/ป้องกัน\nINT=เวท/SP  DEX=แม่นยำ/ร่ายไว  LUK=คริติคอล/หลบสมบูรณ์\nเก็บเลเวล Job ให้ถึง 10 แล้วเลือกอาชีพในหน้าต่าง C",
		ZIndex = 32,
	}, tutorialCard)

	local tutorialClose = makeInstance("TextButton", {
		Size = UDim2.new(0, 150, 0, 38), Position = UDim2.new(1, -166, 1, -52),
		BackgroundColor3 = hex("287a48"), TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold, TextSize = 15, Text = "เริ่มผจญภัย",
		ZIndex = 32,
	}, tutorialCard)
	makeInstance("UICorner", {CornerRadius = UDim.new(0, 8)}, tutorialClose)
	tutorialClose.Activated:Connect(function() tutorialOverlay.Visible = false end)

	-- Note: openTutorialEvent is handled centrally by UIManager.client.lua -> HelpWindow
	-- to prevent duplicate/overlapping modals.

	-- ── 3. Inventory & Equipment Window (Ragnarok M Visual Grid Style) ───
	-- =========================================================================
	-- 2. Ragnarok M Visual Grid Inventory & Equipment Window
	-- =========================================================================
	local inventoryWin, invContent = createWindow(
		"Inventory", "🎒 กระเป๋า & อุปกรณ์ / Inventory",
		UDim2.new(0, 750, 0, 480),
		UDim2.new(0.5, -375, 0.5, -240)
	)

	local ITEM_ICONS = {
		NoviceTrainingDagger = "🗡️", Dagger = "🗡️", ShortSword = "🗡️",
		Sword = "⚔️", KnightTrainingSword = "⚔️", TwoHandSword = "⚔️",
		Spear = "🔱", TwoHandSpear = "🔱", Bow = "🏹", ArcherTrainingBow = "🏹",
		Rod = "🪄", Staff = "🪄", ApprenticeRod = "🪄",
		Axe = "🪓", TwoHandAxe = "🪓", MerchantTrainingAxe = "🪓",
		Mace = "🔨", AcolyteTrainingMace = "🔨", Katar = "🪒", ThiefTrainingDagger = "🗡️",
		NoviceClothes = "🥋", CottonShirt = "🥋", LeatherArmor = "🥋", ChainMail = "🥋", PlateArmor = "🥋",
		Buckler = "🛡️", Shield = "🛡️", Hood = "🧢", PoringHood = "🧢", Helm = "👑",
		Shoes = "👢", Boots = "👢", Ring = "💍", Necklace = "📿",
		RedPotion = "🧪", OrangePotion = "🧪", YellowPotion = "🧪", WhitePotion = "🧪", BluePotion = "🧪",
		Panacea = "💊", Carrot = "🥕", Apple = "🍎", GreenHerb = "🌿", BlueHerb = "🍀",
		FireScroll = "🔥", WaterScroll = "💧", WindScroll = "⚡", EarthScroll = "🌿", HolyScroll = "✝️", ShadowScroll = "🌑",
		BeginnerRefinementStone = "💎", Jellopy = "💧", StickyMucus = "🟢", Feather = "🪶", Hide = "📜",
		Bone = "🦴", RawMeat = "🥩", Tooth = "🦷", IronOre = "🪨", GoldOre = "🪙", Coal = "⬛",
		PoringCard = "🃏", WolfCard = "🃏", ZombieCard = "🃏", SkeletonCard = "🃏", LunaticCard = "🃏",
		FabreCard = "🃏", SoheeCard = "🃏", MinorousCard = "🃏", DrakeCard = "🃏", EddgaCard = "🃏",
	}

	local function getItemIcon(itemId, itemInfo)
		if ITEM_ICONS[itemId] then return ITEM_ICONS[itemId] end
		if not itemInfo then return "📦" end
		if itemInfo.type == "Equipment" then
			if itemInfo.slot == "Weapon" then return "⚔️"
			elseif itemInfo.slot == "Shield" then return "🛡️"
			elseif itemInfo.slot == "Armor" then return "🥋"
			elseif itemInfo.slot == "Footgear" then return "👢"
			elseif itemInfo.slot == "Robe" then return "🧣"
			elseif itemInfo.slot == "Accessory1" or itemInfo.slot == "Accessory2" then return "💍"
			else return "👑" end
		elseif itemInfo.type == "Consumable" then return "🧪"
		elseif itemInfo.type == "Card" then return "🃏"
		end
		return "📦"
	end

	local currentEquipment = {}
	local currentEquipmentRefine = {}
	local currentInventorySnapshot = {}
	local selectedCategory = "All"
	local currentSelectedDetail = nil -- active item for detail modal

	-- Sound effects helper
	local function playInventorySound(soundType)
		pcall(function()
			local sfx = Instance.new("Sound")
			sfx.Volume = 0.5
			if soundType == "equip" then
				sfx.SoundId = "rbxassetid://9114223171"
			elseif soundType == "unequip" then
				sfx.SoundId = "rbxassetid://9114223171"
				sfx.PlaybackSpeed = 0.85
			else
				sfx.SoundId = "rbxassetid://6895079853"
			end
			sfx.Parent = playerGui
			sfx:Play()
			game:GetService("Debris"):AddItem(sfx, 1.5)
		end)
	end

	-- Forward declarations
	local renderInventoryGrid
	local refreshEquipmentSlots
	local refreshAvatarPreview
	local showItemDetail

	-- ── Left Panel: Character Avatar & 10 Equipment Slots ─────
	local charPanel = makeInstance("Frame", {
		Name = "CharacterPanel", Size = UDim2.new(0, 310, 1, 0), Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = hex("141829"), BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 6,
	}, invContent)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, charPanel)
	makeInstance("UIStroke", { Color = hex("2e3852"), Thickness = 1.2 }, charPanel)

	-- Character Header (Class, Level & Zeny)
	local charHeader = makeInstance("Frame", {
		Name = "CharHeader", Size = UDim2.new(1, -16, 0, 32), Position = UDim2.new(0, 8, 0, 6),
		BackgroundColor3 = hex("1f1f38"), BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 7,
	}, charPanel)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, charHeader)
	makeInstance("UIStroke", { Color = hex("38385e"), Thickness = 1 }, charHeader)

	local charClassLabel = makeInstance("TextLabel", {
		Name = "CharClassLabel", Size = UDim2.new(0.55, 0, 1, 0), Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1, TextColor3 = hex("ffd700"), Font = Enum.Font.GothamBold,
		TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Text = "Novice", ZIndex = 8,
	}, charHeader)

	local walletBox = makeInstance("Frame", {
		Name = "WalletBox", Size = UDim2.new(0.42, 0, 0, 24), Position = UDim2.new(0.56, 0, 0.5, -12),
		BackgroundColor3 = hex("171728"), BorderSizePixel = 0, ZIndex = 8,
	}, charHeader)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 5) }, walletBox)
	makeInstance("UIStroke", { Color = hex("ffd700"), Thickness = 1 }, walletBox)

	local walletLabel = makeInstance("TextLabel", {
		Name = "WalletLabel", Size = UDim2.fromScale(1, 1), Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1, TextColor3 = hex("ffd700"), Font = Enum.Font.GothamBold,
		TextSize = 11, TextXAlignment = Enum.TextXAlignment.Center, Text = "0 z", ZIndex = 9,
	}, walletBox)

	local function refreshCharHeader()
		local myClass = player:GetAttribute("Class") or "Novice"
		local myLevel = player:GetAttribute("Level") or 1
		local myGold = player:GetAttribute("Gold") or 0
		charClassLabel.Text = string.format("Lv.%d %s", myLevel, myClass)
		walletLabel.Text = string.format("%s z", tostring(myGold))
	end
	player:GetAttributeChangedSignal("Class"):Connect(refreshCharHeader)
	player:GetAttributeChangedSignal("Level"):Connect(refreshCharHeader)
	player:GetAttributeChangedSignal("Gold"):Connect(refreshCharHeader)
	task.spawn(refreshCharHeader)

	-- 3D Character Preview ViewportFrame (Taller and Centered)
	local avatarViewport = makeInstance("ViewportFrame", {
		Name = "AvatarViewport", Size = UDim2.new(0, 170, 0, 360), Position = UDim2.new(0.5, -85, 0, 48),
		BackgroundTransparency = 1, ZIndex = 7,
	}, charPanel)

	local vCamera = Instance.new("Camera")
	vCamera.FieldOfView = 34
	avatarViewport.CurrentCamera = vCamera
	vCamera.Parent = avatarViewport

	refreshAvatarPreview = function()
		avatarViewport:ClearAllChildren()
		avatarViewport.CurrentCamera = vCamera
		local char = player.Character
		if not char then return end
		char.Archivable = true
		local clone = char:Clone()
		char.Archivable = false
		clone.Name = "PreviewAvatar"
		clone.Parent = avatarViewport

		local hrp = clone:FindFirstChild("HumanoidRootPart") or clone:FindFirstChild("Torso")
		if hrp then
			clone.PrimaryPart = hrp
			clone:PivotTo(CFrame.new(0, 0, 0))
			vCamera.CFrame = CFrame.new(Vector3.new(0, 0.4, 7.8), Vector3.new(0, 0.2, 0))
		end

		for _, desc in ipairs(clone:GetDescendants()) do
			if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("Sound") or desc:IsA("BillboardGui") then
				desc:Destroy()
			elseif desc:IsA("BasePart") then
				desc.Anchored = true
				desc.CanCollide = false
			end
		end
	end

	-- 10 Equipment Slots Definition
	local EQUIP_SLOT_DEFS = {
		-- Left Column (Row 1..5)
		{ key = "Shield",     label = "โล่",      defaultIcon = "🛡️", side = "left",  row = 1 },
		{ key = "Armor",      label = "เกราะ",    defaultIcon = "🥋", side = "left",  row = 2 },
		{ key = "Robe",       label = "คลุม",     defaultIcon = "🧣", side = "left",  row = 3 },
		{ key = "Footgear",   label = "รองเท้า",  defaultIcon = "👢", side = "left",  row = 4 },
		{ key = "Accessory1", label = "ประดับ 1", defaultIcon = "💍", side = "left",  row = 5 },
		-- Right Column (Row 1..5)
		{ key = "Weapon",     label = "อาวุธ",    defaultIcon = "⚔️", side = "right", row = 1 },
		{ key = "HeadTop",    label = "หมวกบน",   defaultIcon = "👑", side = "right", row = 2 },
		{ key = "HeadMid",    label = "แว่น/หน้า", defaultIcon = "🕶️", side = "right", row = 3 },
		{ key = "HeadBottom", label = "คาบปาก",   defaultIcon = "🎭", side = "right", row = 4 },
		{ key = "Accessory2", label = "ประดับ 2", defaultIcon = "📿", side = "right", row = 5 },
	}

	local equipSlotButtons = {}
	for _, sDef in ipairs(EQUIP_SLOT_DEFS) do
		local xPos = sDef.side == "left" and UDim.new(0, 10) or UDim.new(1, -62)
		local yPos = UDim.new(0, 50 + (sDef.row - 1) * 72)

		local sBox = makeInstance("Frame", {
			Name = "EquipSlot_" .. sDef.key, Size = UDim2.new(0, 52, 0, 52), Position = UDim2.new(xPos, yPos),
			BackgroundColor3 = hex("252542"), BorderSizePixel = 0, ZIndex = 8,
		}, charPanel)
		makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, sBox)
		local stroke = makeInstance("UIStroke", { Color = hex("3d3d64"), Thickness = 1.3 }, sBox)

		local iconLbl = makeInstance("TextLabel", {
			Name = "Icon", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			Text = sDef.defaultIcon, TextSize = 24, ZIndex = 9,
		}, sBox)

		local refineBadge = makeInstance("Frame", {
			Name = "RefineBadge", Size = UDim2.new(0, 22, 0, 14), Position = UDim2.new(1, -23, 0, 2),
			BackgroundColor3 = hex("d97706"), BorderSizePixel = 0, Visible = false, ZIndex = 10,
		}, sBox)
		makeInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, refineBadge)
		makeInstance("TextLabel", {
			Name = "RefineText", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 9,
			Text = "+0", ZIndex = 11,
		}, refineBadge)

		local slotBtn = makeInstance("TextButton", {
			Name = "ClickBtn", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			Text = "", ZIndex = 12,
		}, sBox)

		slotBtn.Activated:Connect(function()
			playInventorySound("click")
			local itemId = currentEquipment[sDef.key]
			if itemId then
				local ref = tonumber(currentEquipmentRefine[sDef.key]) or 0
				showItemDetail({
					itemId = itemId,
					quantity = 1,
					enhancement = ref,
					isEquipped = true,
					equipSlot = sDef.key,
				})
			else
				-- If slot is empty, switch to Equip tab to help player find gear
				selectedCategory = "Equip"
				renderInventoryGrid()
			end
		end)

		equipSlotButtons[sDef.key] = { box = sBox, stroke = stroke, icon = iconLbl, badge = refineBadge, def = sDef }
	end

	refreshEquipmentSlots = function()
		for _, sDef in ipairs(EQUIP_SLOT_DEFS) do
			local slotBtnObj = equipSlotButtons[sDef.key]
			if slotBtnObj then
				local eqId = currentEquipment[sDef.key]
				if eqId then
					local info = itemData[eqId]
					local ref = tonumber(currentEquipmentRefine[sDef.key]) or 0
					slotBtnObj.icon.Text = getItemIcon(eqId, info)
					slotBtnObj.box.BackgroundColor3 = hex("2a2a4e")
					slotBtnObj.stroke.Color = hex("e5c158")
					slotBtnObj.stroke.Thickness = 1.8
					if ref > 0 then
						slotBtnObj.badge.Visible = true
						local rText = slotBtnObj.badge:FindFirstChild("RefineText")
						if rText then rText.Text = string.format("+%d", ref) end
					else
						slotBtnObj.badge.Visible = false
					end
				else
					slotBtnObj.icon.Text = sDef.defaultIcon
					slotBtnObj.box.BackgroundColor3 = hex("252542")
					slotBtnObj.stroke.Color = hex("3d3d64")
					slotBtnObj.stroke.Thickness = 1.2
					slotBtnObj.badge.Visible = false
				end
			end
		end
	end

	-- ── Right Panel: Category Tabs & 5-Column Grid ─────────────
	local gridPanel = makeInstance("Frame", {
		Name = "GridPanel", Size = UDim2.new(1, -320, 1, 0), Position = UDim2.new(0, 320, 0, 0),
		BackgroundColor3 = hex("141829"), BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 6,
	}, invContent)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, gridPanel)
	makeInstance("UIStroke", { Color = hex("2e3852"), Thickness = 1.2 }, gridPanel)

	-- Category Tabs
	local CATEGORIES = {
		{ id = "All",   label = "📋 ทั้งหมด" },
		{ id = "Equip", label = "⚔️ สวมใส่" },
		{ id = "Item",  label = "🧪 ยา/ใช้" },
		{ id = "Mat",   label = "📦 วัตถุดิบ" },
		{ id = "Card",  label = "🃏 การ์ด" },
	}

	local categoryButtons = {}
	local categoryBar = makeInstance("Frame", {
		Name = "CategoryBar", Size = UDim2.new(1, -16, 0, 32), Position = UDim2.new(0, 8, 0, 6),
		BackgroundTransparency = 1, ZIndex = 7,
	}, gridPanel)
	local catLayout = makeInstance("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, categoryBar)

	local function updateCategoryTabColors()
		for cId, btn in pairs(categoryButtons) do
			local isActive = (cId == selectedCategory)
			btn.BackgroundColor3 = isActive and hex("2e3b5e") or hex("1f1f35")
			btn.TextColor3 = isActive and hex("ffd700") or hex("94a3b8")
			local stroke = btn:FindFirstChildWhichIsA("UIStroke")
			if stroke then
				stroke.Color = isActive and hex("e5c158") or hex("383858")
			end
		end
	end

	for idx, cat in ipairs(CATEGORIES) do
		local catBtn = makeInstance("TextButton", {
			Name = "CatTab_" .. cat.id, Size = UDim2.new(0, 76, 1, 0),
			BackgroundColor3 = cat.id == "All" and hex("2e3b5e") or hex("1f1f35"),
			TextColor3 = cat.id == "All" and hex("ffd700") or hex("94a3b8"),
			Font = Enum.Font.GothamBold, TextSize = 10, Text = cat.label,
			LayoutOrder = idx, ZIndex = 8,
		}, categoryBar)
		makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, catBtn)
		makeInstance("UIStroke", {
			Color = cat.id == "All" and hex("e5c158") or hex("383858"),
			Thickness = 1.2
		}, catBtn)
		categoryButtons[cat.id] = catBtn

		catBtn.Activated:Connect(function()
			playInventorySound("click")
			selectedCategory = cat.id
			updateCategoryTabColors()
			renderInventoryGrid()
		end)
	end

	-- Grid ScrollingFrame
	local gridScroll = makeInstance("ScrollingFrame", {
		Name = "InventoryGridScroll", Size = UDim2.new(1, -16, 1, -80), Position = UDim2.new(0, 8, 0, 42),
		BackgroundColor3 = hex("10101e"), BackgroundTransparency = 0.3, BorderSizePixel = 0,
		ScrollBarThickness = 5, CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 7,
	}, gridPanel)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, gridScroll)
	makeInstance("UIPadding", {
		PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
	}, gridScroll)

	local gridLayout = makeInstance("UIGridLayout", {
		CellSize = UDim2.new(0, 72, 0, 72),
		CellPadding = UDim2.new(0, 8, 0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, gridScroll)

	-- Bottom Status Bar
	local gridBottomBar = makeInstance("Frame", {
		Name = "GridBottomBar", Size = UDim2.new(1, -16, 0, 26), Position = UDim2.new(0, 8, 1, -32),
		BackgroundTransparency = 1, ZIndex = 7,
	}, gridPanel)

	local bagCapacityLabel = makeInstance("TextLabel", {
		Name = "CapacityLabel", Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1, TextColor3 = hex("94a3b8"), Font = Enum.Font.Gotham,
		TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Text = "ความจุ: 0/100 ช่อง", ZIndex = 8,
	}, gridBottomBar)

	local gridActionHint = makeInstance("TextLabel", {
		Name = "ActionHint", Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundTransparency = 1, TextColor3 = hex("ffd700"), Font = Enum.Font.Gotham,
		TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, Text = "แตะที่ไอเท็มเพื่อดูข้อมูล / สวมใส่", ZIndex = 8,
	}, gridBottomBar)

	-- ── Item Detail Modal Popup ───────────────────────────────
	local detailPopup = makeInstance("Frame", {
		Name = "ItemDetailPopup", Size = UDim2.new(0, 300, 0, 340), Position = UDim2.new(0.5, -150, 0.5, -170),
		BackgroundColor3 = hex("16172b"), BackgroundTransparency = 0.02, BorderSizePixel = 0,
		Visible = false, ZIndex = 30,
	}, invContent)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 10) }, detailPopup)
	local detailStroke = makeInstance("UIStroke", { Color = hex("e5c158"), Thickness = 1.8 }, detailPopup)

	local detailClose = makeInstance("TextButton", {
		Name = "CloseBtn", Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -30, 0, 8),
		BackgroundColor3 = hex("b91c1c"), TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold, TextSize = 12, Text = "✕", ZIndex = 32,
	}, detailPopup)
	makeInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, detailClose)
	detailClose.Activated:Connect(function()
		playInventorySound("click")
		detailPopup.Visible = false
		currentSelectedDetail = nil
	end)

	local detailIcon = makeInstance("TextLabel", {
		Name = "DetailIcon", Size = UDim2.new(0, 48, 0, 48), Position = UDim2.new(0, 14, 0, 14),
		BackgroundColor3 = hex("252542"), Text = "📦", TextSize = 28, ZIndex = 31,
	}, detailPopup)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, detailIcon)
	makeInstance("UIStroke", { Color = hex("3d3d64"), Thickness = 1.2 }, detailIcon)

	local detailTitle = makeInstance("TextLabel", {
		Name = "DetailTitle", Size = UDim2.new(1, -100, 0, 24), Position = UDim2.new(0, 70, 0, 14),
		BackgroundTransparency = 1, TextColor3 = hex("f8fafc"), Font = Enum.Font.GothamBold,
		TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Text = "ชื่อไอเท็ม", ZIndex = 31,
	}, detailPopup)

	local detailSubtitle = makeInstance("TextLabel", {
		Name = "DetailSubtitle", Size = UDim2.new(1, -100, 0, 18), Position = UDim2.new(0, 70, 0, 40),
		BackgroundTransparency = 1, TextColor3 = hex("94a3b8"), Font = Enum.Font.Gotham,
		TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Text = "หมวดหมู่", ZIndex = 31,
	}, detailPopup)

	local detailStatsBox = makeInstance("Frame", {
		Name = "DetailStatsBox", Size = UDim2.new(1, -28, 0, 110), Position = UDim2.new(0, 14, 0, 72),
		BackgroundColor3 = hex("252542"), BorderSizePixel = 0, ZIndex = 31,
	}, detailPopup)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, detailStatsBox)
	makeInstance("UIStroke", { Color = hex("38385e"), Thickness = 1 }, detailStatsBox)

	local detailStatsText = makeInstance("TextLabel", {
		Name = "StatsText", Size = UDim2.new(1, -16, 1, -12), Position = UDim2.new(0, 8, 0, 6),
		BackgroundTransparency = 1, TextColor3 = hex("9fe8ff"), Font = Enum.Font.GothamSemibold,
		TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, Text = "", ZIndex = 32,
	}, detailStatsBox)

	local detailDesc = makeInstance("TextLabel", {
		Name = "DetailDesc", Size = UDim2.new(1, -28, 0, 52), Position = UDim2.new(0, 14, 0, 190),
		BackgroundTransparency = 1, TextColor3 = hex("cbd5e1"), Font = Enum.Font.Gotham,
		TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, Text = "คำอธิบายไอเท็ม...", ZIndex = 31,
	}, detailPopup)

	local detailActionBtn1 = makeInstance("TextButton", {
		Name = "ActionBtn1", Size = UDim2.new(0.48, -4, 0, 32), Position = UDim2.new(0, 14, 1, -44),
		BackgroundColor3 = hex("287a48"), TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold, TextSize = 11, Text = "สวมใส่", ZIndex = 32,
	}, detailPopup)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, detailActionBtn1)

	local detailActionBtn2 = makeInstance("TextButton", {
		Name = "ActionBtn2", Size = UDim2.new(0.48, -4, 0, 32), Position = UDim2.new(0.52, 4, 1, -44),
		BackgroundColor3 = hex("854d0e"), TextColor3 = hex("ffd700"),
		Font = Enum.Font.GothamBold, TextSize = 11, Text = "⚒ ตีบวก", ZIndex = 32,
	}, detailPopup)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, detailActionBtn2)

	-- Single persistent click handlers (Bug Fix: prevents multiple stacked listeners)
	detailActionBtn1.Activated:Connect(function()
		if not currentSelectedDetail then return end
		local entry = currentSelectedDetail
		local info = itemData[entry.itemId]
		local myClass = player:GetAttribute("Class") or "Novice"

		if entry.isEquipped then
			-- Action: Unequip
			local slotKey = entry.equipSlot or (info and info.slot)
			if slotKey and unequipItemRemote then
				unequipItemRemote:FireServer(slotKey)
				playInventorySound("unequip")
				if callbacks.showNotice then callbacks.showNotice("ถอดอุปกรณ์แล้ว", 2) end
			end
			detailPopup.Visible = false
			currentSelectedDetail = nil
		elseif info and info.type == "Equipment" then
			-- Action: Equip
			if info.slot == "Weapon" and info.weaponType and not classData.CanUseWeapon(myClass, info.weaponType) then
				if callbacks.showNotice then callbacks.showNotice("❌ อาชีพ " .. myClass .. " ไม่สามารถใช้อาวุธชนิดนี้ได้", 2.5) end
				return
			end
			local ref = tonumber(entry.enhancement) or 0
			if equipItemRemote then
				equipItemRemote:FireServer(entry.itemId, ref)
				playInventorySound("equip")
				if callbacks.showNotice then callbacks.showNotice("สวมใส่ " .. (info.name or entry.itemId) .. " สำเร็จ", 2) end
			end
			detailPopup.Visible = false
			currentSelectedDetail = nil
		elseif info and info.type == "Consumable" then
			-- Action: Use Consumable
			if useConsumableRemote then
				useConsumableRemote:FireServer(entry.itemId)
				playInventorySound("click")
			end
			detailPopup.Visible = false
			currentSelectedDetail = nil
		elseif info and info.type == "Card" then
			-- Action: Open Card Slotting UI
			detailPopup.Visible = false
			currentSelectedDetail = nil
			if _G.OpenCardSlottingUI then
				_G.OpenCardSlottingUI()
			elseif callbacks.showNotice then
				callbacks.showNotice("เปิดหน้าต่างเสียบการ์ดอุปกรณ์", 2)
			end
		end
	end)

	detailActionBtn2.Activated:Connect(function()
		detailPopup.Visible = false
		currentSelectedDetail = nil
		if not refineWin.Visible then toggleWindow(refineWin) end
		refreshRefinementPanel(currentInventorySnapshot)
	end)

	showItemDetail = function(itemDataObj)
		if not itemDataObj then
			detailPopup.Visible = false
			currentSelectedDetail = nil
			return
		end
		currentSelectedDetail = itemDataObj
		local itemId = itemDataObj.itemId
		local info = itemData[itemId]
		local name = info and info.name or itemId
		local ref = tonumber(itemDataObj.enhancement) or 0
		local isEquipped = itemDataObj.isEquipped == true
		local rarityCol = itemRarity.GetColor(itemId)
		local myClass = player:GetAttribute("Class") or "Novice"

		detailPopup.Visible = true
		detailStroke.Color = rarityCol
		detailTitle.Text = name .. (ref > 0 and string.format(" +%d", ref) or "")
		detailTitle.TextColor3 = rarityCol
		detailIcon.Text = getItemIcon(itemId, info)

		-- Build stats text
		local statsLines = {}
		local canEquipWeapon = true

		if info and info.type == "Equipment" then
			table.insert(statsLines, "📌 ช่องสวมใส่: " .. tostring(info.slot or "อาวุธ"))
			if info.bonuses then
				local bList = {}
				for k, v in pairs(info.bonuses) do table.insert(bList, string.format("%s +%d", k, v)) end
				table.insert(statsLines, "⚔️ ค่าสถานะ: " .. table.concat(bList, ", "))
			end
			if ref > 0 then
				if info.slot == "Weapon" then
					table.insert(statsLines, string.format("✨ Refine ATK (ทะลุ DEF): +%d", ref * 6))
				else
					table.insert(statsLines, string.format("🛡️ Refine DEF (ทะลุ MDEF): +%d", ref * 4))
				end
			end

			-- Class Usability Check
			if info.slot == "Weapon" and info.weaponType then
				canEquipWeapon = classData.CanUseWeapon(myClass, info.weaponType)
				if not canEquipWeapon then
					local usableList = {}
					for cName, cData in pairs(classData.Classes) do
						if classData.CanUseWeapon(cName, info.weaponType) then
							table.insert(usableList, cData.NameThai or cName)
						end
					end
					table.insert(statsLines, string.format("⚠️ ข้อจำกัด: อาชีพ %s ใช้ไม่ได้\n(สำหรับ: %s)", myClass, table.concat(usableList, ", ")))
				end
			end
		elseif info and info.type == "Consumable" then
			if info.use then
				if info.use.HP then table.insert(statsLines, string.format("💚 ฟื้นฟู HP: +%d", info.use.HP)) end
				if info.use.SP then table.insert(statsLines, string.format("💙 ฟื้นฟู SP: +%d", info.use.SP)) end
				if info.use.CoatElement then table.insert(statsLines, string.format("⚡ เคลือบธาตุ: %s (%d วิ)", info.use.CoatElement, info.use.Duration or 300)) end
				if info.use.CureAll then table.insert(statsLines, "✨ ล้างสถานะผิดปกติทั้งหมด") end
			end
		elseif info and info.type == "Card" then
			table.insert(statsLines, "🃏 ประเภท: การ์ดมอนสเตอร์สำหรับเสียบรูอุปกรณ์")
			if info.bonuses then
				local bList = {}
				for k, v in pairs(info.bonuses) do table.insert(bList, string.format("%s +%d", k, v)) end
				table.insert(statsLines, "🌟 คุณสมบัติ: " .. table.concat(bList, ", "))
			end
		end
		if #statsLines == 0 then table.insert(statsLines, "📦 ไอเท็มทั่วไปในกระเป๋า") end
		detailStatsText.Text = table.concat(statsLines, "\n")

		detailDesc.Text = info and info.description or "ไม่มีข้อมูลคำอธิบาย"
		detailSubtitle.Text = info and string.format("ประเภท: %s  |  จำนวน: %d", info.type or "ทั่วไป", itemDataObj.quantity or 1) or ""

		-- Configure action buttons
		detailActionBtn1.Visible = true
		detailActionBtn2.Visible = false

		if info and info.type == "Equipment" then
			if isEquipped then
				detailActionBtn1.Text = "ถอดอุปกรณ์"
				detailActionBtn1.BackgroundColor3 = hex("991b1b") -- crimson red
				detailActionBtn1.AutoButtonColor = true
				detailActionBtn2.Visible = true
				detailActionBtn2.Text = "⚒ ตีบวก"
			else
				if not canEquipWeapon then
					detailActionBtn1.Text = "❌ อาชีพนี้ใช้ไม่ได้"
					detailActionBtn1.BackgroundColor3 = hex("475569") -- disabled slate
					detailActionBtn1.AutoButtonColor = false
				else
					detailActionBtn1.Text = "สวมใส่"
					detailActionBtn1.BackgroundColor3 = hex("287a48") -- emerald green
					detailActionBtn1.AutoButtonColor = true
				end
				detailActionBtn2.Visible = true
				detailActionBtn2.Text = "⚒ ตีบวก"
			end
		elseif info and info.type == "Consumable" then
			detailActionBtn1.Text = "ดื่ม / ใช้งาน"
			detailActionBtn1.BackgroundColor3 = hex("2563eb")
			detailActionBtn1.AutoButtonColor = true
		elseif info and info.type == "Card" then
			detailActionBtn1.Text = "🃏 ข้อมูลการ์ด"
			detailActionBtn1.BackgroundColor3 = hex("7c3aed")
			detailActionBtn1.AutoButtonColor = true
		else
			detailActionBtn1.Visible = false
		end
	end

	-- ── Render Inventory Grid ─────────────────────────────────
	renderInventoryGrid = function()
		for _, child in ipairs(gridScroll:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
		end

		local myClass = player:GetAttribute("Class") or "Novice"

		-- Filter entries
		local visibleEntries = {}
		for _, entry in ipairs(currentInventorySnapshot) do
			if type(entry) == "table" and type(entry.itemId) == "string" and (tonumber(entry.quantity) or 0) > 0 then
				local info = itemData[entry.itemId]
				local match = false
				if selectedCategory == "All" then match = true
				elseif selectedCategory == "Equip" and info and info.type == "Equipment" then match = true
				elseif selectedCategory == "Item" and info and info.type == "Consumable" then match = true
				elseif selectedCategory == "Mat" and info and info.type == "Material" then match = true
				elseif selectedCategory == "Card" and info and info.type == "Card" then match = true
				end
				if match then table.insert(visibleEntries, entry) end
			end
		end
		table.sort(visibleEntries, function(a, b) return a.itemId < b.itemId end)

		bagCapacityLabel.Text = string.format("ความจุ: %d/100 ช่อง", #currentInventorySnapshot)

		local totalSlots = math.max(#visibleEntries, 35) -- render at least 35 slots (7 rows)
		for i = 1, totalSlots do
			local entry = visibleEntries[i]
			local slotTile = makeInstance("Frame", {
				Name = entry and ("Item_" .. entry.itemId) or ("EmptySlot_" .. i),
				Size = UDim2.new(0, 72, 0, 72),
				BackgroundColor3 = hex("252542"), -- Matching Stats row slate
				BackgroundTransparency = entry and 0.1 or 0.5,
				BorderSizePixel = 0,
				LayoutOrder = i,
				ZIndex = 8,
			}, gridScroll)
			makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, slotTile)

			if entry then
				local info = itemData[entry.itemId]
				local rarityCol = itemRarity.GetColor(entry.itemId)
				local ref = tonumber(entry.enhancement) or 0
				local canUse = true
				if info and info.type == "Equipment" and info.slot == "Weapon" and info.weaponType then
					canUse = classData.CanUseWeapon(myClass, info.weaponType)
				end

				makeInstance("UIStroke", { Color = canUse and rarityCol or hex("64748b"), Thickness = 1.4 }, slotTile)

				-- Center icon
				local iconLbl = makeInstance("TextLabel", {
					Size = UDim2.new(1, 0, 1, -16), Position = UDim2.new(0, 0, 0, 4),
					BackgroundTransparency = 1, Text = getItemIcon(entry.itemId, info),
					TextTransparency = canUse and 0 or 0.45,
					TextSize = 28, ZIndex = 9,
				}, slotTile)

				-- Unusable Class Badge
				if not canUse then
					local unBadge = makeInstance("Frame", {
						Size = UDim2.new(1, -6, 0, 14), Position = UDim2.new(0, 3, 0, 3),
						BackgroundColor3 = Color3.fromRGB(185, 28, 28), BackgroundTransparency = 0.1,
						BorderSizePixel = 0, ZIndex = 11,
					}, slotTile)
					makeInstance("UICorner", { CornerRadius = UDim.new(0, 3) }, unBadge)
					makeInstance("TextLabel", {
						Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
						TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
						TextSize = 8, Text = "ต่างอาชีพ", ZIndex = 12,
					}, unBadge)
				end

				-- Quantity badge at bottom-right
				if (tonumber(entry.quantity) or 1) > 1 then
					local qBadge = makeInstance("Frame", {
						Size = UDim2.new(0, 28, 0, 14), Position = UDim2.new(1, -30, 1, -16),
						BackgroundColor3 = hex("151525"), BackgroundTransparency = 0.2,
						BorderSizePixel = 0, ZIndex = 10,
					}, slotTile)
					makeInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, qBadge)
					makeInstance("TextLabel", {
						Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
						TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
						TextSize = 9, Text = string.format("x%d", entry.quantity), ZIndex = 11,
					}, qBadge)
				end

				-- Refine badge at top-right
				if ref > 0 then
					local rBadge = makeInstance("Frame", {
						Size = UDim2.new(0, 22, 0, 14), Position = UDim2.new(1, -24, 0, 2),
						BackgroundColor3 = hex("d97706"), BorderSizePixel = 0, ZIndex = 10,
					}, slotTile)
					makeInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, rBadge)
					makeInstance("TextLabel", {
						Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
						TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
						TextSize = 9, Text = string.format("+%d", ref), ZIndex = 11,
					}, rBadge)
				end

				-- Click handler
				local clickBtn = makeInstance("TextButton", {
					Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
					Text = "", ZIndex = 12,
				}, slotTile)
				clickBtn.Activated:Connect(function()
					playInventorySound("click")
					showItemDetail(entry)
				end)
			else
				-- Empty slot
				makeInstance("UIStroke", { Color = hex("323254"), Thickness = 1 }, slotTile)
			end
		end

		refreshEquipmentSlots()
	end

	local function renderInventory(inventory, equipment, equipmentRefine)
		currentInventorySnapshot = type(inventory) == "table" and inventory or {}
		if type(equipment) == "table" then currentEquipment = equipment end
		if type(equipmentRefine) == "table" then currentEquipmentRefine = equipmentRefine end
		if inventoryWin and inventoryWin.Visible then
			renderInventoryGrid()
			task.spawn(refreshAvatarPreview)
		end
	end

	local function toggleInventory()
		toggleWindow(inventoryWin)
	end

	inventoryWin:GetPropertyChangedSignal("Visible"):Connect(function()
		if inventoryWin.Visible then
			local req = requestInventoryRemote or remotes.RequestInventory or (ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("RequestInventory"))
			if req then
				task.spawn(function()
					local ok, inventory, equipment, equipmentRefine = pcall(function() return req:InvokeServer() end)
					if ok and type(inventory) == "table" then
						renderInventory(inventory, equipment, equipmentRefine)
					end
				end)
			end
		end
	end)

	-- ── 4. Blacksmith Refinement Window ───────────────────────
	local refineWin, refineContent = createWindow("BlacksmithRefinement", "⚒ ช่างตีเหล็ก / Refinement", UDim2.new(0, 420, 0, 250), UDim2.new(0.5, -210, 0.5, -125))

	makeInstance("TextLabel", {
		Size = UDim2.new(1, -8, 0, 48), Position = UDim2.new(0, 4, 0, 2), BackgroundTransparency = 1,
		TextColor3 = hex("e8e8f0"), Font = Enum.Font.Gotham, TextSize = 13, TextWrapped = true,
		Text = "ใช้ Beginner Refinement Stone 1 ก้อน และ Zeny 20 × ระดับเป้าหมาย\nระดับ +1 ถึง +4 สำเร็จแน่นอน; ตั้งแต่ +5 มีโอกาสลดลง",
	}, refineContent)

	local refineWeaponStatus = makeInstance("TextLabel", {
		Size = UDim2.new(1, -8, 0, 28), Position = UDim2.new(0, 4, 0, 55), BackgroundColor3 = hex("202038"),
		TextColor3 = hex("e8e8f0"), Font = Enum.Font.GothamSemibold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "อาวุธ: -",
	}, refineContent)

	local refineArmorStatus = makeInstance("TextLabel", {
		Size = UDim2.new(1, -8, 0, 28), Position = UDim2.new(0, 4, 0, 87), BackgroundColor3 = hex("202038"),
		TextColor3 = hex("e8e8f0"), Font = Enum.Font.GothamSemibold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "เกราะ: -",
	}, refineContent)

	local refineWeaponButton = makeInstance("TextButton", {
		Size = UDim2.new(0.49, -2, 0, 34), Position = UDim2.new(0, 0, 0, 123),
		BackgroundColor3 = hex("68502d"), TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
		TextSize = 12, Text = "ตีบวกอาวุธ",
	}, refineContent)

	local refineArmorButton = makeInstance("TextButton", {
		Size = UDim2.new(0.49, -2, 0, 34), Position = UDim2.new(0.51, 2, 0, 123),
		BackgroundColor3 = hex("68502d"), TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
		TextSize = 12, Text = "ตีบวกเกราะ",
	}, refineContent)

	local refineStoneCount = makeInstance("TextLabel", {
		Size = UDim2.new(1, -8, 0, 26), Position = UDim2.new(0, 4, 0, 164), BackgroundTransparency = 1,
		TextColor3 = hex("aaaacc"), Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "หินตีบวก: 0 | Zeny: 0 z",
	}, refineContent)

	local refineResult = makeInstance("TextLabel", {
		Size = UDim2.new(1, -8, 0, 22), Position = UDim2.new(0, 4, 0, 192), BackgroundTransparency = 1,
		TextColor3 = hex("ffe082"), Font = Enum.Font.GothamSemibold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
	}, refineContent)

	local function isNearBlacksmith()
		local plaza = Workspace:FindFirstChild("RoROK_StarterPlaza")
		local blacksmith = plaza and plaza:FindFirstChild("Blacksmith")
		local smithRoot = blacksmith and blacksmith.PrimaryPart
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		return smithRoot ~= nil and root ~= nil and (root.Position - smithRoot.Position).Magnitude <= 14
	end

	local function playRefineSound(success)
		local sound = Instance.new("Sound")
		sound.SoundId = success and "rbxasset://sounds/electronicpingshort.wav" or "rbxasset://sounds/switch.wav"
		sound.Volume = 0.95
		sound.PlaybackSpeed = success and 1.35 or 0.75
		sound.Parent = Workspace
		sound:Play()
		task.delay(2.5, function() if sound.Parent then sound:Destroy() end end)
	end

	local function refreshRefinementPanel(inventory, message)
		local weaponInfo = itemData[currentEquipment.Weapon]
		local armorInfo = itemData[currentEquipment.Armor]
		local weaponLevel = tonumber(currentEquipmentRefine.Weapon) or 0
		local armorLevel = tonumber(currentEquipmentRefine.Armor) or 0
		local refineChances = { [1] = 100, [2] = 100, [3] = 100, [4] = 100, [5] = 60, [6] = 50, [7] = 40, [8] = 30, [9] = 25, [10] = 20, [11] = 17, [12] = 14, [13] = 12, [14] = 10, [15] = 8 }
		refineWeaponStatus.Text = string.format("อาวุธ: %s +%d  (Refine ATK +%d)", weaponInfo and weaponInfo.name or "-", weaponLevel, weaponLevel * 6)
		refineArmorStatus.Text = string.format("เกราะ: %s +%d  (Refine DEF +%d)", armorInfo and armorInfo.name or "-", armorLevel, armorLevel * 4)
		local stones = 0
		for _, entry in ipairs(inventory or {}) do
			if entry.itemId == "BeginnerRefinementStone" then stones += tonumber(entry.quantity) or 0 end
		end
		refineStoneCount.Text = string.format("หินตีบวก: %d | Zeny: %d z", stones, player:GetAttribute("Gold") or 0)
		local weaponNext = weaponLevel < 15 and weaponLevel + 1 or nil
		local armorNext = armorLevel < 15 and armorLevel + 1 or nil
		refineWeaponButton.Text = weaponNext and string.format("อาวุธ +%d • %d%% • %dz", weaponNext, refineChances[weaponNext], weaponNext * 20) or "อาวุธ +15 (เต็มแล้ว)"
		refineArmorButton.Text = armorNext and string.format("เกราะ +%d • %d%% • %dz", armorNext, refineChances[armorNext], armorNext * 20) or "เกราะ +15 (เต็มแล้ว)"
		refineWeaponButton.Active = weaponInfo ~= nil and weaponNext ~= nil
		refineArmorButton.Active = armorInfo ~= nil and armorNext ~= nil

		if message and message ~= "" then
			refineResult.Text = message
			if string.find(message, "สำเร็จ!") then
				playRefineSound(true)
				refineResult.TextColor3 = Color3.fromRGB(100, 255, 120)
				local stroke = refineWin:FindFirstChildOfClass("UIStroke")
				if stroke then
					local origColor = stroke.Color
					stroke.Color = Color3.fromRGB(255, 220, 60)
					stroke.Thickness = 2.5
					task.delay(0.6, function()
						if stroke then stroke.Color = origColor; stroke.Thickness = 1.8 end
					end)
				end
			elseif string.find(message, "ไม่สำเร็จ") then
				playRefineSound(false)
				refineResult.TextColor3 = Color3.fromRGB(255, 90, 90)
				local stroke = refineWin:FindFirstChildOfClass("UIStroke")
				if stroke then
					local origColor = stroke.Color
					stroke.Color = Color3.fromRGB(255, 60, 60)
					task.delay(0.6, function()
						if stroke then stroke.Color = origColor end
					end)
				end
			end
		end
	end

	refineWeaponButton.Activated:Connect(function()
		if not isNearBlacksmith() then
			local hint = "⚠️ ต้องอยู่ที่เตาช่างตีเหล็ก Hollgrehenn ในเมือง Prontera (ระยะ 14 studs)"
			refineResult.Text = hint
			refineResult.TextColor3 = Color3.fromRGB(255, 200, 80)
			if callbacks and callbacks.showNotice then callbacks.showNotice(hint, 3) end
			return
		end
		if refineEquipmentRemote then refineEquipmentRemote:FireServer("Weapon") end
	end)

	refineArmorButton.Activated:Connect(function()
		if not isNearBlacksmith() then
			local hint = "⚠️ ต้องอยู่ที่เตาช่างตีเหล็ก Hollgrehenn ในเมือง Prontera (ระยะ 14 studs)"
			refineResult.Text = hint
			refineResult.TextColor3 = Color3.fromRGB(255, 200, 80)
			if callbacks and callbacks.showNotice then callbacks.showNotice(hint, 3) end
			return
		end
		if refineEquipmentRemote then refineEquipmentRemote:FireServer("Armor") end
	end)

	if openRefinementEvent then
		openRefinementEvent.OnClientEvent:Connect(function()
			if requestInventoryRemote then
				local ok, inventory, equipment, equipmentRefine = pcall(function() return requestInventoryRemote:InvokeServer() end)
				if ok then renderInventory(inventory, equipment, equipmentRefine); refreshRefinementPanel(inventory) end
			end
			if not refineWin.Visible then toggleWindow(refineWin) end
		end)
	end

	-- ── 5. Supply Shop Window ─────────────────────────────────
	local shopWin, shopContent = createWindow("SupplyShop", "🧪 ร้านค้า Prontera / Supplies", UDim2.new(0, 460, 0, 390), UDim2.new(0.5, -230, 0.5, -195))

	makeInstance("TextLabel", {
		Size = UDim2.new(1, -8, 0, 28), Position = UDim2.new(0, 4, 0, 0),
		BackgroundTransparency = 1, TextColor3 = hex("e8e8f0"), Font = Enum.Font.Gotham,
		TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "ซื้อยาฟื้นฟู หรือขายของที่หาได้จากมอนสเตอร์",
	}, shopContent)

	local shopGoldLabel = makeInstance("TextLabel", {
		Size = UDim2.new(0.48, 0, 0, 24), Position = UDim2.new(0, 4, 0, 29),
		BackgroundTransparency = 1, TextColor3 = hex("ffd700"), Font = Enum.Font.GothamBold,
		TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.format("Zeny: %d z", player:GetAttribute("Gold") or 0),
	}, shopContent)

	local buyTab = makeInstance("TextButton", {
		Size = UDim2.new(0.49, -2, 0, 30), Position = UDim2.new(0, 4, 0, 55),
		BackgroundColor3 = hex("51416b"), TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold, TextSize = 13, Text = "ซื้อยา",
	}, shopContent)

	local sellTab = makeInstance("TextButton", {
		Size = UDim2.new(0.49, -2, 0, 30), Position = UDim2.new(0.51, 2, 0, 55),
		BackgroundColor3 = hex("365b46"), TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold, TextSize = 13, Text = "ขายของดรอป",
	}, shopContent)

	local buyPanel = makeInstance("ScrollingFrame", {
		Name = "BuyPanel", Size = UDim2.new(1, -8, 1, -96), Position = UDim2.new(0, 4, 0, 91),
		BackgroundColor3 = hex("10101e"), BackgroundTransparency = 0.15, BorderSizePixel = 0,
		ScrollBarThickness = 6, CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, shopContent)
	makeInstance("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, buyPanel)
	makeInstance("UIPadding", {PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)}, buyPanel)

	local sellPanel = makeInstance("ScrollingFrame", {
		Name = "SellPanel", Size = UDim2.new(1, -8, 1, -96), Position = UDim2.new(0, 4, 0, 91),
		BackgroundColor3 = hex("10101e"), BackgroundTransparency = 0.15, BorderSizePixel = 0,
		ScrollBarThickness = 6, CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
	}, shopContent)
	makeInstance("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, sellPanel)
	makeInstance("UIPadding", {PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)}, sellPanel)

	local function makeShopOffer(itemId, order)
		local info = itemData[itemId]
		if not info then return end
		local row = makeInstance("Frame", {
			Size = UDim2.new(1, -8, 0, 56), LayoutOrder = order,
			BackgroundColor3 = hex("25253d"), BackgroundTransparency = 0.08,
		}, buyPanel)
		makeInstance("TextLabel", {
			Size = UDim2.new(1, -190, 1, 0), Position = UDim2.new(0, 8, 0, 0),
			BackgroundTransparency = 1, TextColor3 = hex("e8e8f0"), Font = Enum.Font.GothamSemibold,
			TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			Text = string.format("%s\n%s • %d z/ชิ้น", info.name, info.description or "ของใช้", info.buyPrice or 0),
		}, row)
		for buttonIndex, quantity in ipairs({1, 5}) do
			local cost = (info.buyPrice or 0) * quantity
			local button = makeInstance("TextButton", {
				Size = UDim2.new(0, 82, 0, 34), Position = UDim2.new(1, -178 + (buttonIndex - 1) * 88, 0.5, -17),
				BackgroundColor3 = hex("51416b"), TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.GothamBold, TextSize = 11,
				Text = string.format("ซื้อ x%d\n%d z", quantity, cost),
			}, row)
			button.Activated:Connect(function()
				if purchaseShopItemRemote then purchaseShopItemRemote:FireServer(itemId, quantity) end
			end)
		end
	end

	for idx, shopId in ipairs({"RedPotion", "WhitePotion", "BluePotion", "Panacea", "FireScroll", "WaterScroll", "WindScroll", "EarthScroll", "HolyScroll", "ShadowScroll", "BeginnerRefinementStone"}) do
		makeShopOffer(shopId, idx)
	end

	local function refreshShopSellList()
		for _, child in ipairs(sellPanel:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
		end
		local sellableCount = 0
		for _, entry in ipairs(currentInventorySnapshot) do
			local info = itemData[entry.itemId]
			local sellableType = info and (info.type == "Material" or info.type == "Card"
				or (info.type == "Consumable" and info.buyPrice == nil))
			local unitPrice = info and math.floor(tonumber(info.sellPrice) or 0) or 0
			local quantity = math.max(0, math.floor(tonumber(entry.quantity) or 0))
			if sellableType and unitPrice > 0 and quantity > 0 then
				sellableCount += 1
				local row = makeInstance("Frame", {
					Size = UDim2.new(1, -8, 0, 44), BackgroundColor3 = hex("25253d"),
					BackgroundTransparency = 0.08, LayoutOrder = sellableCount,
				}, sellPanel)
				makeInstance("TextLabel", {
					Size = UDim2.new(1, -176, 1, 0), Position = UDim2.new(0, 7, 0, 0),
					BackgroundTransparency = 1, TextColor3 = hex("e8e8f0"), Font = Enum.Font.GothamSemibold,
					TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
					Text = string.format("%s x%d • %d z/ชิ้น", info.name, quantity, unitPrice),
				}, row)
				local oneButton = makeInstance("TextButton", {
					Size = UDim2.new(0, 68, 0, 30), Position = UDim2.new(1, -168, 0.5, -15),
					BackgroundColor3 = hex("51416b"), TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.GothamBold, TextSize = 11, Text = "ขาย 1",
				}, row)
				oneButton.Activated:Connect(function()
					if sellShopItemRemote then sellShopItemRemote:FireServer(entry.itemId, 1) end
				end)
				local allButton = makeInstance("TextButton", {
					Size = UDim2.new(0, 88, 0, 30), Position = UDim2.new(1, -94, 0.5, -15),
					BackgroundColor3 = hex("365b46"), TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.GothamBold, TextSize = 11,
					Text = string.format("ขายหมด +%d", unitPrice * quantity),
				}, row)
				allButton.Activated:Connect(function()
					if sellShopItemRemote then sellShopItemRemote:FireServer(entry.itemId, quantity) end
				end)
			end
		end
		if sellableCount == 0 then
			makeInstance("TextLabel", {
				Size = UDim2.new(1, -10, 0, 40), BackgroundTransparency = 1,
				TextColor3 = hex("aaaacc"), Font = Enum.Font.Gotham, TextSize = 13,
				Text = "ยังไม่มีของดรอปที่ร้านรับซื้อ",
			}, sellPanel)
		end
	end

	buyTab.Activated:Connect(function()
		buyPanel.Visible, sellPanel.Visible = true, false
		buyTab.BackgroundColor3, sellTab.BackgroundColor3 = hex("51416b"), hex("365b46")
	end)
	sellTab.Activated:Connect(function()
		buyPanel.Visible, sellPanel.Visible = false, true
		buyTab.BackgroundColor3, sellTab.BackgroundColor3 = hex("365b46"), hex("51416b")
		if requestInventoryRemote then
			local ok, inventory = pcall(function() return requestInventoryRemote:InvokeServer() end)
			if ok and type(inventory) == "table" then currentInventorySnapshot = inventory end
		end
		refreshShopSellList()
	end)

	player:GetAttributeChangedSignal("Gold"):Connect(function()
		shopGoldLabel.Text = string.format("Zeny: %d z", player:GetAttribute("Gold") or 0)
	end)

	if openSupplyShopEvent then
		openSupplyShopEvent.OnClientEvent:Connect(function()
			shopGoldLabel.Text = string.format("Zeny: %d z", player:GetAttribute("Gold") or 0)
			buyPanel.Visible, sellPanel.Visible = true, false
			toggleWindow(shopWin)
		end)
	end

	-- ── 6. World Map Window (M Key) ───────────────────────────
	local mapWin, mapContent = createWindow(
		"MapWindow", "🏰 Prontera (เมืองหลวง Prontera) • OC1",
		UDim2.new(0, 620, 0, 510),
		UDim2.new(0.5, -310, 0.5, -255)
	)

	local localMapCanvas = makeInstance("Frame", {
		Name = "LocalMapCanvas", Size = UDim2.new(1, -20, 1, -56),
		Position = UDim2.fromOffset(10, 10), BackgroundColor3 = hex("0f1929"),
		BorderSizePixel = 0, ClipsDescendants = true,
	}, mapContent)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 12) }, localMapCanvas)
	makeInstance("UIStroke", { Color = hex("d4af37"), Thickness = 2 }, localMapCanvas)

	local mapGrid = makeInstance("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, localMapCanvas)
	makeInstance("Frame", { Name = "RoadNS", Size = UDim2.new(0, 32, 1, 0), Position = UDim2.new(0.5, -16, 0, 0), BackgroundColor3 = hex("1e293b"), BorderSizePixel = 0, ZIndex = 2 }, mapGrid)
	makeInstance("Frame", { Name = "RoadEW", Size = UDim2.new(1, 0, 0, 32), Position = UDim2.new(0, 0, 0.5, -16), BackgroundColor3 = hex("1e293b"), BorderSizePixel = 0, ZIndex = 2 }, mapGrid)

	local PRONTERA_MAP_POIS = {
		{ title = "⛲ น้ำพุกลางเมือง", icon = "⛲", pos = UDim2.new(0.5, -24, 0.5, -24), size = UDim2.fromOffset(48, 48), color = hex("0284c7") },
		{ title = "📜 กระดานภารกิจ", icon = "📜", pos = UDim2.new(0.55, 6, 0.44, 0), size = UDim2.fromOffset(36, 36), color = hex("f59e0b") },
		{ title = "⛪ มหาวิหารหลวง", icon = "⛪", pos = UDim2.new(0.32, -20, 0.18, -20), size = UDim2.fromOffset(48, 48), color = hex("6366f1") },
		{ title = "🏰 พระราชวังหลวง", icon = "🏰", pos = UDim2.new(0.5, -30, 0.04, 0), size = UDim2.fromOffset(60, 36), color = hex("475569") },
		{ title = "🔨 โรงตีเหล็ก", icon = "🔨", pos = UDim2.new(0.24, 0, 0.42, 0), size = UDim2.fromOffset(40, 40), color = hex("d97706") },
		{ title = "🛒 ร้านค้าเสบียง", icon = "🛒", pos = UDim2.new(0.72, 0, 0.42, 0), size = UDim2.fromOffset(40, 40), color = hex("10b981") },
		{ title = "🛡️ ร้านขายอุปกรณ์", icon = "🛡️", pos = UDim2.new(0.72, 0, 0.60, 0), size = UDim2.fromOffset(40, 40), color = hex("059669") },
		{ title = "⚔️ ลานฝึกหุ่นฟาง", icon = "⚔️", pos = UDim2.new(0.74, 0, 0.18, 0), size = UDim2.fromOffset(44, 44), color = hex("ef4444") },
		{ title = "⚓ ท่าเรือ Prontera", icon = "⚓", pos = UDim2.new(0.82, 0, 0.80, 0), size = UDim2.fromOffset(42, 42), color = hex("0284c7") },
		{ title = "🕳️ ทางลงท่อระบายน้ำ", icon = "🕳️", pos = UDim2.new(0.16, 0, 0.80, 0), size = UDim2.fromOffset(42, 42), color = hex("7c3aed") },
		{ title = "🌊 สระน้ำทางใต้", icon = "🌊", pos = UDim2.new(0.5, -28, 0.74, 0), size = UDim2.fromOffset(56, 42), color = hex("0284c7") },
	}
	for _, poi in ipairs(PRONTERA_MAP_POIS) do
		local f = makeInstance("Frame", {
			Name = "POI_" .. poi.icon, Size = poi.size, Position = poi.pos,
			BackgroundColor3 = poi.color, BorderSizePixel = 0, ZIndex = 3,
		}, mapGrid)
		makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, f)
		makeInstance("UIStroke", { Color = hex("fed7aa"), Thickness = 1.2 }, f)
		makeInstance("TextLabel", {
			Size = UDim2.new(1, 0, 0.65, 0), BackgroundTransparency = 1,
			Text = poi.icon, TextSize = 16, ZIndex = 4,
		}, f)
		makeInstance("TextLabel", {
			Size = UDim2.new(1, 0, 0.35, 0), Position = UDim2.new(0, 0, 0.65, 0),
			BackgroundTransparency = 1, Text = poi.title, TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamMedium, TextSize = 8, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 4,
		}, f)
	end

	local bossBadge = makeInstance("Frame", {
		Size = UDim2.new(0, 310, 0, 32), Position = UDim2.new(0, 12, 0, 10),
		BackgroundColor3 = hex("1e1b4b"), BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 5,
	}, localMapCanvas)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, bossBadge)
	makeInstance("UIStroke", { Color = hex("fbbf24"), Thickness = 1.3 }, bossBadge)
	makeInstance("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Text = "👑 [MVP] Drake Lv.20 [🟢 มีชีวิตอยู่]  •  💀 [Mini] Minorous [🟢]",
		TextColor3 = hex("fde047"), Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 6,
	}, bossBadge)

	local playerPin = makeInstance("Frame", {
		Name = "PlayerMapPin", Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(0.5, -12, 0.5, -12),
		BackgroundColor3 = hex("38bdf8"), BorderSizePixel = 0, ZIndex = 7,
	}, localMapCanvas)
	makeInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, playerPin)
	makeInstance("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }, playerPin)
	makeInstance("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Text = "▲", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 13, ZIndex = 8,
	}, playerPin)

	local worldMapPillBtn = makeInstance("TextButton", {
		Name = "WorldMapPillBtn", Size = UDim2.fromOffset(130, 38),
		Position = UDim2.new(0, 14, 1, -48), BackgroundColor3 = hex("1d4ed8"),
		Text = "🌐 World (แผนที่โลก)", TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = true, ZIndex = 10,
	}, localMapCanvas)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 10) }, worldMapPillBtn)
	makeInstance("UIStroke", { Color = hex("60a5fa"), Thickness = 2 }, worldMapPillBtn)
	worldMapPillBtn.Activated:Connect(function()
		mapWin.Visible = false
		if _G.ToggleWorldTravelWindow then _G.ToggleWorldTravelWindow() end
	end)

	_G.ToggleLocalMap = function() toggleWindow(mapWin) end

	-- ── 7. Mission Board Window (J Key) ───────────────────────
	local missionBoardWin, missionBoardContent = createWindow(
		"MissionBoard", "📜 กระดานภารกิจ (Mission Board)",
		UDim2.new(0, 720, 0, 480),
		UDim2.new(0.5, -360, 0.5, -240)
	)
	missionBoardWin.BackgroundColor3 = hex("2a1a12")

	local ribbonHeader = makeInstance("Frame", {
		Size = UDim2.new(0, 260, 0, 32), Position = UDim2.new(0.5, -130, 0, -14),
		BackgroundColor3 = hex("d97706"), BorderSizePixel = 0, ZIndex = 30,
	}, missionBoardWin)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, ribbonHeader)
	makeInstance("UIStroke", { Color = hex("fde68a"), Thickness = 1.6 }, ribbonHeader)
	makeInstance("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Text = "กระดานภารกิจ", TextColor3 = hex("ffffff"),
		Font = Enum.Font.GothamBold, TextSize = 15, ZIndex = 31,
	}, ribbonHeader)

	local scrollCardsContainer = makeInstance("ScrollingFrame", {
		Name = "QuestScrolls", Size = UDim2.new(1, -24, 1, -86), Position = UDim2.new(0, 12, 0, 36),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6,
		CanvasSize = UDim2.new(0, 1030, 0, 0), ScrollBarImageColor3 = hex("e5c158"), ZIndex = 10,
	}, missionBoardContent)
	makeInstance("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, scrollCardsContainer)

	local boardFooter = makeInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 1, -40),
		BackgroundColor3 = hex("180f0a"), BorderSizePixel = 0, ZIndex = 12,
	}, missionBoardContent)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, boardFooter)

	local footerProgressLbl = makeInstance("TextLabel", {
		Size = UDim2.new(0.5, -16, 1, 0), Position = UDim2.new(0, 16, 0, 0),
		BackgroundTransparency = 1, Text = "🏆 วันนี้ทำสำเร็จแล้ว : 0 / 3 ภารกิจ",
		TextColor3 = hex("fbbf24"), Font = Enum.Font.GothamBold, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 13,
	}, boardFooter)

	local footerTimerLbl = makeInstance("TextLabel", {
		Size = UDim2.new(0.5, -16, 1, 0), Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundTransparency = 1, Text = "⏳ รีเฟรชเวลา : 16:00:00",
		TextColor3 = hex("cbd5e1"), Font = Enum.Font.GothamMedium, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 13,
	}, boardFooter)

	task.spawn(function()
		while true do
			local now = os.time() + 7 * 60 * 60
			local secondsPassedInDay = now % 86400
			local secondsRemaining = 86400 - secondsPassedInDay
			local h = math.floor(secondsRemaining / 3600)
			local m = math.floor((secondsRemaining % 3600) / 60)
			local s = secondsRemaining % 60
			footerTimerLbl.Text = string.format("⏳ รีเฟรชเวลา : %02d:%02d:%02d", h, m, s)
			task.wait(1)
		end
	end)

	local function renderDailyQuests(snapshot)
		if type(snapshot) ~= "table" then return end
		local activeList = {}
		for _, quest in ipairs(snapshot.offers or {}) do
			if quest.active and not quest.claimed then
				table.insert(activeList, quest)
			end
		end
		if minimapView and minimapView.updateQuests then
			minimapView.updateQuests(activeList)
		end

		local completed = tonumber(snapshot.completedCount) or 0
		footerProgressLbl.Text = string.format("🏆 วันนี้ทำสำเร็จแล้ว : %d / 3 ภารกิจ (รางวัล XP & ของใช้ประจำวัน)", completed)

		for _, child in ipairs(scrollCardsContainer:GetChildren()) do
			if child:IsA("Frame") and child.Name:match("^NoticeCard_") then
				child:Destroy()
			end
		end

		for index, quest in ipairs(snapshot.offers or {}) do
			local card = makeInstance("Frame", {
				Name = "NoticeCard_" .. quest.id, Size = UDim2.new(0, 192, 0, 335),
				BackgroundColor3 = hex("d8c29d"), BorderSizePixel = 0, LayoutOrder = index, ZIndex = 15,
			}, scrollCardsContainer)
			makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, card)
			makeInstance("UIStroke", { Color = hex("8c6239"), Thickness = 2 }, card)

			makeInstance("TextLabel", {
				Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 12),
				BackgroundTransparency = 1, Text = quest.title, TextColor3 = hex("3d1f05"),
				Font = Enum.Font.GothamBold, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 16,
			}, card)

			local descText = quest.description or quest.desc or ""
			local xp = quest.xp or quest.rewardXP or 0
			local jobXp = quest.jobXp or quest.rewardJobXP or 0
			local gold = quest.gold or quest.rewardGold or 0
			local itemReward = quest.rewardItemName and (quest.rewardItemName .. " x" .. tostring(quest.rewardItemCount or 1)) or nil

			makeInstance("TextLabel", {
				Size = UDim2.new(1, -20, 0, 72), Position = UDim2.new(0, 10, 0, 40),
				BackgroundTransparency = 1, Text = descText, TextColor3 = hex("5c3a21"),
				Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 16,
			}, card)

			local targetText = ""
			if quest.objective == "Kill" then
				targetText = string.format("🎯 ปราบ %s (%d/%d ตัว)", quest.target or "มอน", quest.progress or 0, quest.amount or 1)
			elseif quest.objective == "Collect" then
				targetText = string.format("📦 สะสม %s (%d/%d ชิ้น)", quest.target or "ของ", quest.progress or 0, quest.amount or 1)
			else
				targetText = string.format("📍 สถานที่: %s", quest.location or "Prontera")
			end

			local targetBox = makeInstance("Frame", {
				Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 10, 0, 116),
				BackgroundColor3 = hex("eed8b8"), BorderSizePixel = 0, ZIndex = 16,
			}, card)
			makeInstance("UICorner", { CornerRadius = UDim.new(0, 5) }, targetBox)
			makeInstance("TextLabel", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
				Text = targetText, TextColor3 = hex("4a2105"),
				Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 17,
			}, targetBox)

			local rewardLines = { string.format("EXP +%s  •  Job +%s  •  %s z", string.format("%d", xp), string.format("%d", jobXp), string.format("%d", gold)) }
			if itemReward then table.insert(rewardLines, "🎁 " .. itemReward) end
			local rewardStr = table.concat(rewardLines, "\n")

			local rewardBox = makeInstance("Frame", {
				Size = UDim2.new(1, -20, 0, itemReward and 48 or 38), Position = UDim2.new(0, 10, 0, 146),
				BackgroundColor3 = hex("f5e6cc"), BorderSizePixel = 0, ZIndex = 16,
			}, card)
			makeInstance("UICorner", { CornerRadius = UDim.new(0, 5) }, rewardBox)
			makeInstance("UIStroke", { Color = hex("d8b584"), Thickness = 1 }, rewardBox)
			makeInstance("TextLabel", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
				Text = "รางวัลภารกิจ:\n" .. rewardStr,
				TextColor3 = hex("78350f"), Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 17,
			}, rewardBox)

			if quest.claimed then
				local stamp = makeInstance("Frame", {
					Size = UDim2.new(0, 110, 0, 36), Position = UDim2.new(0.5, -55, 1, -48),
					BackgroundColor3 = hex("fee2e2"), BorderSizePixel = 0, ZIndex = 20,
				}, card)
				makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, stamp)
				makeInstance("UIStroke", { Color = hex("dc2626"), Thickness = 2 }, stamp)
				makeInstance("TextLabel", {
					Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
					Text = "✓ สำเร็จแล้ว", TextColor3 = hex("dc2626"),
					Font = Enum.Font.GothamBold, TextSize = 12, ZIndex = 21,
				}, stamp)
			else
				local btnText, btnColor, canClick, clickAction
				if quest.complete then
					btnText = "รับรางวัล"
					btnColor = hex("16a34a")
					canClick = true
					clickAction = function()
						if claimDailyQuestRemote then claimDailyQuestRemote:FireServer(quest.id) end
					end
				elseif quest.active then
					btnText = string.format("กำลังทำ (%d/%d)", quest.progress or 0, quest.amount or 1)
					btnColor = hex("2563eb")
					canClick = false
				elseif completed >= 3 then
					btnText = "ทำครบ 3 เควสแล้ว"
					btnColor = hex("64748b")
					canClick = false
				elseif (snapshot.activeCount or 0) >= (3 - completed) then
					btnText = "รับเควสเต็มโควตา"
					btnColor = hex("64748b")
					canClick = false
				else
					btnText = "รับภารกิจ"
					btnColor = hex("b45309")
					canClick = true
					clickAction = function()
						if acceptDailyQuestRemote then acceptDailyQuestRemote:FireServer(quest.id) end
					end
				end

				local actionBtn = makeInstance("TextButton", {
					Size = UDim2.new(1, -24, 0, 34), Position = UDim2.new(0, 12, 1, -44),
					BackgroundColor3 = btnColor, Text = btnText, TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.GothamBold, TextSize = 11, AutoButtonColor = canClick, ZIndex = 20,
				}, card)
				makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, actionBtn)
				if canClick and clickAction then actionBtn.Activated:Connect(clickAction) end
			end
		end
	end

	local function refreshDailyQuests()
		if not getDailyQuestsRemote then return end
		task.spawn(function()
			local ok, snapshot = pcall(function() return getDailyQuestsRemote:InvokeServer() end)
			if ok then renderDailyQuests(snapshot) end
		end)
	end

	if dailyQuestUpdateEvent then dailyQuestUpdateEvent.OnClientEvent:Connect(renderDailyQuests) end
	if openDailyQuestsEvent then
		openDailyQuestsEvent.OnClientEvent:Connect(function()
			missionBoardWin.Visible = true
			refreshDailyQuests()
		end)
	end
	refreshDailyQuests()

	-- ── 8. Skills Window (K Key) ──────────────────────────────
	local skillsWin, skillContent = createWindow(
		"Skills", "✨ สกิล / Skills",
		UDim2.new(0, 450, 0, 520),
		UDim2.new(0.5, -225, 0.5, -260)
	)
	makeInstance("TextLabel", {
		Size             = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		TextColor3       = hex("aaaacc"),
		Font             = Enum.Font.Gotham,
		TextSize         = 13,
		Text             = "(ระบบ Skill Tree สามารถเปิดดูได้ผ่านปุ่มด่วน)",
	}, skillContent)

	-- ── 9. Esc Menu (ESC Key) ─────────────────────────────────
	local escMenu, escContent = createWindow(
		"EscMenu", "⚙️ เมนู / Menu",
		UDim2.new(0, 260, 0, 320),
		UDim2.new(0.5, -130, 0.5, -160)
	)
	-- ── 10. Help & Controls Window ────────────────────────────
	local helpWin, helpContent = createWindow(
		"HelpWindow", "❓ คู่มือการเล่น & ปุ่มควบคุม / Help",
		UDim2.new(0, 500, 0, 420),
		UDim2.new(0.5, -250, 0.5, -210)
	)

	local helpScroll = makeInstance("ScrollingFrame", {
		Name = "HelpScroll",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = hex("e5c158"),
		CanvasSize = UDim2.new(0, 0, 0, 480),
	}, helpContent)

	local helpLayout = makeInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	}, helpScroll)

	local function addHelpSection(secTitle, secItems, secOrder)
		local sec = makeInstance("Frame", {
			Name = "Section_" .. secOrder,
			Size = UDim2.new(1, -8, 0, 28 + #secItems * 22),
			BackgroundColor3 = hex("1c1d35"),
			LayoutOrder = secOrder,
		}, helpScroll)
		makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, sec)
		makeInstance("UIStroke", { Color = hex("2f3358"), Thickness = 1 }, sec)

		makeInstance("TextLabel", {
			Size = UDim2.new(1, -16, 0, 24),
			Position = UDim2.new(0, 8, 0, 2),
			BackgroundTransparency = 1,
			TextColor3 = hex("ffd700"),
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = secTitle,
		}, sec)

		for idx, it in ipairs(secItems) do
			makeInstance("TextLabel", {
				Size = UDim2.new(1, -16, 0, 20),
				Position = UDim2.new(0, 8, 0, 26 + (idx - 1) * 22),
				BackgroundTransparency = 1,
				TextColor3 = hex("d1d5db"),
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = it,
			}, sec)
		end
	end

	addHelpSection("⌨️ ปุ่มควบคุมบนคอมพิวเตอร์ (PC Controls)", {
		"🎒 [E] : เปิด / ปิด กระเป๋าและอุปกรณ์ (Inventory)",
		"📊 [C] : เปิด / ปิด ข้อมูลตัวละคร & จัดสรรสเตตัส (Status)",
		"✨ [K] : เปิด / ปิด ผังสกิลและการอัปเลเวลสกิล (Skill Tree)",
		"📜 [J] : เปิด / ปิด กระดานเควสประจำวัน (Mission Board)",
		"🗺️ [M] : เปิด / ปิด แผนที่เมือง Prontera (World Map)",
		"💬 [F] : พูดคุยกับ NPC / ช่างตีเหล็ก / ร้านค้า (Interact)",
		"⚔️ [1 - 8] : กดใช้สกิลต่อสู้ตามช่องลัด Hotbar",
		"⚙️ [ESC] : เปิดเมนูระบบ ตั้งค่า หรือออกจากเกม (System Menu)",
	}, 1)

	addHelpSection("📱 การควบคุมบนมือถือ & แท็บเล็ต (Mobile Controls)", {
		"👤 แตะที่การ์ดรูปโปรไฟล์บนซ้าย : เปิดหน้าต่างสเตตัส & สกิล",
		"🎒 แตะปุ่ม [🎒 กระเป๋า] : เปิดหน้าต่างจัดการไอเทมและอุปกรณ์",
		"✨ แตะปุ่ม [✨ สกิล] : เปิดผังสกิลเพื่อเรียนรู้สกิลใหม่",
		"⚔️ แตะปุ่ม [⚔ Auto] : เปิด/ปิด บอทต่อสู้และดื่มยาอัตโนมัติ",
		"⚙️ แตะปุ่มเฟือง [⚙] : ตั้งค่าเป้าหมายและสกิลที่บอทจะใช้",
		"💬 แตะกล่องข้อความบนหัว NPC : พูดคุยและรับเควส",
	}, 2)

	addHelpSection("💡 ระบบสำคัญในเกม (Game Mechanics & Tips)", {
		"🔥 ระบบธาตุ 10 ธาตุ : ธาตุชนะทางทำดาเมจแรงขึ้นถึง 175%!",
		"⚒️ ช่างตีเหล็ก Hollgrehenn : ตีบวกปลอดภัย 100% ที่ระดับ +1 ถึง +4",
		"📜 เควสเนื้อเรื่องเมือง : ทำได้ 1 ครั้งต่อบัญชี อัปเลเวลไวถึง Lv.47!",
	}, 3)

	_G.OpenHelpWindow = function()
		toggleWindow(helpWin)
	end

	local escButtons = {
		{"↩ กลับเล่น",  function() closeWindow(escMenu) end},
		{"⚙️ ตั้งค่าบอท Auto", function()
			closeWindow(escMenu)
			local autoSettingsWin = windowGui:FindFirstChild("AutoSettings")
			if autoSettingsWin then
				toggleWindow(autoSettingsWin)
			end
		end},
		{"❓ คู่มือ & ปุ่มกด", function()
			closeWindow(escMenu)
			toggleWindow(helpWin)
		end},
		{"🚪 ออกจากเกม", function() player:Kick("ออกจากเกมโดยผู้เล่น") end},
	}
	for i, pair in ipairs(escButtons) do
		local btn = makeInstance("TextButton", {
			Name             = "EscBtn"..i,
			Size             = UDim2.new(1, 0, 0, 44),
			Position         = UDim2.new(0, 0, 0, (i-1)*52),
			BackgroundColor3 = hex("2a2a4a"),
			TextColor3       = Color3.new(1, 1, 1),
			Font             = Enum.Font.GothamBold,
			TextSize         = 14,
			Text             = pair[1],
		}, escContent)
		makeInstance("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)
		btn.Activated:Connect(pair[2])
	end

	-- ── Keyboard Shortcuts (J, M, Esc, E, C) ──────────────────
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp or UserInputService:GetFocusedTextBox() then return end
		if input.KeyCode == Enum.KeyCode.J then
			toggleWindow(missionBoardWin)
			if missionBoardWin.Visible then refreshDailyQuests() end
		elseif input.KeyCode == Enum.KeyCode.M then
			toggleWindow(mapWin)
		elseif input.KeyCode == Enum.KeyCode.Escape then
			toggleWindow(escMenu)
		end
	end)

	ContextActionService:BindActionAtPriority("RoROK_ToggleInventory", function(_, state)
		if state == Enum.UserInputState.Begin then
			if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
			toggleInventory()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value + 10000, Enum.KeyCode.E)

	local function toggleStats()
		if _G.ToggleRagnarokStatsWindow then
			_G.ToggleRagnarokStatsWindow("Stats")
		else
			toggleWindow(statsWin)
		end
	end

	local function toggleSkillTree()
		if _G.ToggleSkillTreeWindow then
			_G.ToggleSkillTreeWindow()
		else
			toggleWindow(skillsWin)
		end
	end

	return {
		windowGui = windowGui,
		createWindow = createWindow,
		openWindow = openWindow,
		closeWindow = closeWindow,
		toggleWindow = toggleWindow,
		statsWin = statsWin,
		inventoryWin = inventoryWin,
		refineWin = refineWin,
		shopWin = shopWin,
		mapWin = mapWin,
		missionBoardWin = missionBoardWin,
		skillsWin = skillsWin,
		escMenu = escMenu,
		renderStats = renderStats,
		renderInventory = renderInventory,
		refreshDailyQuests = refreshDailyQuests,
		refreshRefinementPanel = refreshRefinementPanel,
		refreshShopSellList = refreshShopSellList,
		getInventory = function() return currentInventorySnapshot end,
		getEquipment = function() return currentEquipment end,
		getEquipmentRefine = function() return currentEquipmentRefine end,
		openRefine = function()
			if not refineWin.Visible then toggleWindow(refineWin) end
			refreshRefinementPanel(currentInventorySnapshot)
		end,
		toggleInventory = toggleInventory,
		toggleStats = toggleStats,
		toggleMap = function() toggleWindow(mapWin) end,
		toggleSkillTree = toggleSkillTree,
		toggleMissionBoard = function() toggleWindow(missionBoardWin); if missionBoardWin.Visible then refreshDailyQuests() end end,
		helpWin = helpWin,
		toggleHelp = function() toggleWindow(helpWin) end,
		openHelp = function() if not helpWin.Visible then toggleWindow(helpWin) end end,
		getMapWindow = function() return mapWin end,
	}
end

return WindowSystem
