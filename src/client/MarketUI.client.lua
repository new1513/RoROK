-- Central market window. Separate LocalScript so the main HUD (UIManager) stays under
-- Luau's 200-local limit, same approach as CraftingUI and PartyUI.
-- The client only draws what the server sends and forwards intents; the server decides.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local marketState = remotes:WaitForChild("MarketState")
local marketAction = remotes:WaitForChild("MarketAction")
local marketFeedback = remotes:WaitForChild("MarketFeedback")

local C = {
	panel = Color3.fromRGB(20, 21, 36),
	row = Color3.fromRGB(38, 38, 61),
	input = Color3.fromRGB(28, 28, 46),
	gold = Color3.fromRGB(255, 211, 79),
	text = Color3.fromRGB(239, 239, 248),
	sub = Color3.fromRGB(176, 178, 200),
	good = Color3.fromRGB(49, 90, 74),
	bad = Color3.fromRGB(132, 45, 55),
	tabOn = Color3.fromRGB(86, 74, 150),
	tabOff = Color3.fromRGB(38, 38, 61),
}

-- ===== small UI helpers =====
local function make(className, props, parent)
	local inst = Instance.new(className)
	for key, value in pairs(props) do inst[key] = value end
	inst.Parent = parent
	return inst
end

local function corner(inst, radius)
	make("UICorner", { CornerRadius = UDim.new(0, radius or 6) }, inst)
end

local function newLabel(parent, props)
	local base = {
		BackgroundTransparency = 1, TextColor3 = C.text, Font = Enum.Font.Gotham, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
	}
	for key, value in pairs(props) do base[key] = value end
	return make("TextLabel", base, parent)
end

local function newButton(parent, props)
	local base = {
		BackgroundColor3 = C.good, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 12,
	}
	for key, value in pairs(props) do base[key] = value end
	local button = make("TextButton", base, parent)
	corner(button)
	return button
end

local function newBox(parent, props)
	local base = {
		BackgroundColor3 = C.input, TextColor3 = C.text, PlaceholderColor3 = C.sub, Font = Enum.Font.GothamSemibold,
		TextSize = 13, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0,
	}
	for key, value in pairs(props) do base[key] = value end
	local box = make("TextBox", base, parent)
	corner(box)
	make("UIPadding", { PaddingLeft = UDim.new(0, 8) }, box)
	return box
end

local function newScroll(parent, props)
	local base = {
		BackgroundColor3 = C.input, BackgroundTransparency = 0.35, BorderSizePixel = 0, ScrollBarThickness = 5,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
	}
	for key, value in pairs(props) do base[key] = value end
	local scroll = make("ScrollingFrame", base, parent)
	corner(scroll, 8)
	make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 8),
	}, scroll)
	return scroll
end

-- Clears rows but returns the previous scroll offset so a refresh does not jump.
local function clearRows(scroll)
	local position = scroll.CanvasPosition
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
	return position
end

local function addRow(scroll, order, height, className)
	local row = make(className or "Frame", {
		Size = UDim2.new(1, 0, 0, height or 46), BackgroundColor3 = C.row, BorderSizePixel = 0, LayoutOrder = order,
	}, scroll)
	if className == "TextButton" then row.Text = "" end
	corner(row, 7)
	return row
end

local function addNote(scroll, text)
	local row = addRow(scroll, 100000, 40) -- always sorts after the real rows
	newLabel(row, {
		Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), Text = text,
		TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Center,
	})
end

local function fmt(n)
	local digits = tostring(math.floor(tonumber(n) or 0))
	local out = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then out = out:sub(2) end
	return out
end

local function digitsOnly(box)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		local cleaned = box.Text:gsub("%D", "")
		if cleaned ~= box.Text then box.Text = cleaned end
	end)
end

-- ===== window =====
local gui = make("ScreenGui", { Name = "MarketUI", ResetOnSpawn = false, DisplayOrder = 32 }, player:WaitForChild("PlayerGui"))

local panel = make("Frame", {
	Name = "MarketPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(700, 460), BackgroundColor3 = C.panel, BorderSizePixel = 0, Visible = false,
}, gui)
corner(panel, 10)
make("UIStroke", { Color = C.gold, Thickness = 2 }, panel)
local uiScale = make("UIScale", {}, panel)

local function rescale()
	local camera = Workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	uiScale.Scale = math.clamp(math.min(viewport.X / 740, viewport.Y / 500), 0.5, 1)
end
rescale()
if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
end

newLabel(panel, {
	Size = UDim2.new(0, 260, 0, 34), Position = UDim2.fromOffset(14, 8), Text = "🏛 ตลาดกลาง",
	TextColor3 = Color3.fromRGB(255, 224, 130), Font = Enum.Font.GothamBold, TextSize = 18, TextWrapped = false,
})
local zenyLabel = newLabel(panel, {
	Size = UDim2.new(0, 220, 0, 34), Position = UDim2.new(1, -300, 0, 8), Text = "Zeny: 0 z",
	TextColor3 = C.gold, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right,
})
local closeButton = newButton(panel, {
	Size = UDim2.fromOffset(32, 30), Position = UDim2.new(1, -42, 0, 10), BackgroundColor3 = C.bad, Text = "X",
})

local status = newLabel(panel, {
	Size = UDim2.new(1, -28, 0, 22), Position = UDim2.fromOffset(14, 84), TextColor3 = C.sub, TextWrapped = false,
	Text = "ราคาถูกสุดอยู่บนสุด ราคาเท่ากันขายตามคิวที่ลงก่อน",
})

local pages = {}
local tabButtons = {}
local tabs = {
	{ id = "Buy", text = "🛒 ซื้อ" },
	{ id = "Auction", text = "⏳ ประมูล" },
	{ id = "Sell", text = "📦 ลงขาย" },
	{ id = "Mine", text = "📋 ของฉัน" },
}
local currentTab = "Buy"

local function showTab(id)
	currentTab = id
	for tabId, page in pairs(pages) do page.Visible = (tabId == id) end
	for tabId, button in pairs(tabButtons) do
		button.BackgroundColor3 = (tabId == id) and C.tabOn or C.tabOff
	end
end

for index, tab in ipairs(tabs) do
	local button = newButton(panel, {
		Size = UDim2.fromOffset(150, 30), Position = UDim2.fromOffset(14 + (index - 1) * 158, 48),
		BackgroundColor3 = C.tabOff, Text = tab.text,
	})
	tabButtons[tab.id] = button
	local page = make("Frame", {
		Size = UDim2.new(1, -28, 0, 336), Position = UDim2.fromOffset(14, 112), BackgroundTransparency = 1, Visible = false,
	}, panel)
	pages[tab.id] = page
	button.Activated:Connect(function() showTab(tab.id) end)
end

-- ===== state =====
local view = nil
local receivedAt = 0
local filterText = ""
local selectedKey = nil
local bidTexts = {}
local timerLabels = {}
local pendingRender = false
local renderAll -- assigned below; used by the bid box after typing

-- ===== Buy page =====
local searchBox = newBox(pages.Buy, {
	Size = UDim2.new(1, 0, 0, 30), PlaceholderText = "ค้นหาชื่อไอเท็ม...", Text = "",
})
local buyScroll = newScroll(pages.Buy, { Size = UDim2.new(1, 0, 1, -36), Position = UDim2.fromOffset(0, 36) })

local function renderBuy()
	local saved = clearRows(buyScroll)
	local needle = filterText:lower()
	local queue = {}
	local shown = 0
	for _, entry in ipairs(view.fixed) do
		if needle == "" or entry.name:lower():find(needle, 1, true) then
			shown += 1
			local queueKey = entry.name .. "|" .. entry.unitPrice
			queue[queueKey] = (queue[queueKey] or 0) + 1
			local mine = entry.sellerId == player.UserId
			local row = addRow(buyScroll, shown, 46)
			local sub = string.format("%s z/ชิ้น • ผู้ขาย %s", fmt(entry.unitPrice), entry.sellerName)
			if queue[queueKey] > 1 then sub ..= string.format(" • คิวที่ %d (ราคาเท่ากัน)", queue[queueKey]) end
			newLabel(row, {
				Size = UDim2.new(1, -200, 1, -6), Position = UDim2.fromOffset(10, 3),
				Text = string.format("%s  x%d\n%s", entry.name, entry.quantity, sub),
				Font = Enum.Font.GothamSemibold, TextYAlignment = Enum.TextYAlignment.Center,
			})
			if mine then
				newLabel(row, {
					Size = UDim2.fromOffset(150, 40), Position = UDim2.new(1, -160, 0, 3), Text = "ของคุณ",
					TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Center,
				})
			elseif entry.quantity > 1 then
				newButton(row, {
					Size = UDim2.fromOffset(60, 34), Position = UDim2.new(1, -196, 0, 6), Text = "ซื้อ 1",
				}).Activated:Connect(function()
					marketAction:FireServer("Buy", { id = entry.id, quantity = 1 })
				end)
				newButton(row, {
					Size = UDim2.fromOffset(122, 34), Position = UDim2.new(1, -130, 0, 6), TextSize = 11,
					Text = string.format("ซื้อทั้งหมด\n%s z", fmt(entry.unitPrice * entry.quantity)),
				}).Activated:Connect(function()
					marketAction:FireServer("Buy", { id = entry.id, quantity = entry.quantity })
				end)
			else
				newButton(row, {
					Size = UDim2.fromOffset(122, 34), Position = UDim2.new(1, -130, 0, 6),
					Text = string.format("ซื้อ %s z", fmt(entry.unitPrice)),
				}).Activated:Connect(function()
					marketAction:FireServer("Buy", { id = entry.id, quantity = 1 })
				end)
			end
		end
	end
	if shown == 0 then addNote(buyScroll, "ยังไม่มีสินค้าที่ตรงกับการค้นหา") end
	if view.truncated then addNote(buyScroll, "แสดงเฉพาะรายการแรก ใช้ช่องค้นหาเพื่อกรอง") end
	buyScroll.CanvasPosition = saved
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	filterText = searchBox.Text
	if view and view.fixed then renderBuy() end
end)

-- ===== Auction page =====
local auctionScroll = newScroll(pages.Auction, { Size = UDim2.fromScale(1, 1) })

local function renderAuctions()
	local saved = clearRows(auctionScroll)
	table.clear(timerLabels)
	for index, entry in ipairs(view.auctions) do
		local mine = entry.sellerId == player.UserId
		local row = addRow(auctionScroll, index, 58)
		local bidLine
		if entry.currentBid > 0 then
			bidLine = string.format("ราคาตอนนี้ %s z • ผู้นำ %s", fmt(entry.currentBid), entry.bidderName)
		else
			bidLine = string.format("เริ่มที่ %s z • ยังไม่มีผู้ประมูล", fmt(entry.startPrice))
		end
		newLabel(row, {
			Size = UDim2.new(1, -250, 0, 40), Position = UDim2.fromOffset(10, 3),
			Text = string.format("%s\n%s • ผู้ขาย %s", entry.name, bidLine, entry.sellerName),
			Font = Enum.Font.GothamSemibold, TextYAlignment = Enum.TextYAlignment.Top,
		})
		local timer = newLabel(row, {
			Size = UDim2.new(1, -250, 0, 16), Position = UDim2.fromOffset(10, 39), Text = "",
			TextColor3 = C.gold, TextWrapped = false,
		})
		timerLabels[entry.id] = { label = timer, endsAt = entry.endsAt }
		if mine then
			newLabel(row, {
				Size = UDim2.fromOffset(220, 50), Position = UDim2.new(1, -230, 0, 4), Text = "ของคุณ",
				TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Center,
			})
		else
			local savedBid = tonumber(bidTexts[entry.id])
			local box = newBox(row, {
				Size = UDim2.fromOffset(110, 32), Position = UDim2.new(1, -236, 0, 13),
				Text = tostring((savedBid and savedBid >= entry.minNext) and savedBid or entry.minNext),
			})
			digitsOnly(box)
			box:GetPropertyChangedSignal("Text"):Connect(function() bidTexts[entry.id] = box.Text end)
			local function submit()
				local amount = tonumber(box.Text)
				if not amount then
					status.Text = "กรอกราคาประมูลเป็นตัวเลข"
					return
				end
				marketAction:FireServer("Bid", { id = entry.id, amount = amount })
			end
			newButton(row, {
				Size = UDim2.fromOffset(112, 32), Position = UDim2.new(1, -120, 0, 13),
				Text = (entry.bidderId == player.UserId) and "คุณนำอยู่" or "ประมูล",
				BackgroundColor3 = (entry.bidderId == player.UserId) and C.tabOn or C.good,
			}).Activated:Connect(submit)
			box.FocusLost:Connect(function(enterPressed)
				if enterPressed then submit() end
				if pendingRender then
					pendingRender = false
					task.defer(renderAll)
				end
			end)
		end
	end
	if #view.auctions == 0 then
		addNote(auctionScroll, "ยังไม่มีการประมูล • ของที่ไม่เหมือนใครในตลาดจะเปิดประมูลอัตโนมัติ")
	end
	auctionScroll.CanvasPosition = saved
end

-- ===== Sell page =====
local sellList = newScroll(pages.Sell, { Size = UDim2.new(0, 322, 1, 0) })
local form = make("Frame", {
	Size = UDim2.new(1, -332, 1, 0), Position = UDim2.fromOffset(332, 0), BackgroundColor3 = C.input,
	BackgroundTransparency = 0.35, BorderSizePixel = 0,
}, pages.Sell)
corner(form, 8)
local formTitle = newLabel(form, {
	Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 8), Text = "เลือกไอเท็มจากรายการด้านซ้าย",
	Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.fromRGB(255, 224, 130),
})
local formInfo = newLabel(form, {
	Size = UDim2.new(1, -20, 0, 74), Position = UDim2.fromOffset(10, 50), Text = "", TextColor3 = C.sub,
	TextYAlignment = Enum.TextYAlignment.Top,
})
newLabel(form, { Size = UDim2.fromOffset(110, 28), Position = UDim2.fromOffset(10, 130), Text = "จำนวน" })
local qtyBox = newBox(form, { Size = UDim2.new(1, -140, 0, 28), Position = UDim2.fromOffset(120, 130), Text = "" })
newLabel(form, { Size = UDim2.fromOffset(110, 28), Position = UDim2.fromOffset(10, 166), Text = "ราคา/ชิ้น (z)" })
local priceBox = newBox(form, { Size = UDim2.new(1, -140, 0, 28), Position = UDim2.fromOffset(120, 166), Text = "" })
local netLabel = newLabel(form, {
	Size = UDim2.new(1, -20, 0, 36), Position = UDim2.fromOffset(10, 204), Text = "", TextColor3 = C.sub,
	TextYAlignment = Enum.TextYAlignment.Top,
})
local listButton = newButton(form, {
	Size = UDim2.new(1, -20, 0, 38), Position = UDim2.fromOffset(10, 250), Text = "ลงขาย", BackgroundColor3 = C.good,
})
digitsOnly(qtyBox)
digitsOnly(priceBox)

local function selectedRow()
	if not view or not selectedKey then return nil end
	for _, row in ipairs(view.inventory) do
		if row.itemId .. "|" .. row.enhancement == selectedKey then return row end
	end
	return nil
end

local function updateNet()
	local row = selectedRow()
	local qty = tonumber(qtyBox.Text)
	local price = tonumber(priceBox.Text)
	if not row or not qty or not price or not view then
		netLabel.Text = ""
		return
	end
	local total = qty * price
	local tax = math.floor(total * view.taxRate)
	netLabel.Text = string.format("รวม %s z • ภาษีขาย %d%% (%s z) • รับสุทธิ %s z",
		fmt(total), math.floor(view.taxRate * 100 + 0.5), fmt(tax), fmt(total - tax))
end
qtyBox:GetPropertyChangedSignal("Text"):Connect(updateNet)
priceBox:GetPropertyChangedSignal("Text"):Connect(updateNet)

local function updateForm()
	local row = selectedRow()
	if not row then
		formTitle.Text = "เลือกไอเท็มจากรายการด้านซ้าย"
		formInfo.Text = "ตลาดจะกำหนดช่วงราคาที่ตั้งได้ตามอุปสงค์/อุปทานของไอเท็มนั้น"
		listButton.Active = false
		listButton.AutoButtonColor = false
		listButton.BackgroundColor3 = C.tabOff
		qtyBox.TextEditable = false
		netLabel.Text = ""
		return
	end
	formTitle.Text = string.format("%s (มี %d)", row.name, row.quantity)
	if row.auction then
		formInfo.Text = string.format(
			"รุ่นนี้ยังไม่มีในตลาด จึงเข้าประมูล %d นาที (ลงทีละ 1 ชิ้น)\nราคาเริ่มต้นตั้งได้ %s - %s z ผู้เสนอสูงสุดเมื่อหมดเวลาเป็นผู้ชนะ",
			view.auctionSeconds // 60, fmt(row.low), fmt(row.high))
		qtyBox.Text = "1"
		qtyBox.TextEditable = false
	else
		formInfo.Text = string.format(
			"ขายราคาคงที่ ตั้งราคาได้ %s - %s z/ชิ้น\nราคาต่ำสุดจะอยู่บนสุด ถ้าราคาเท่ากันจะต่อคิวตามลำดับที่ลง",
			fmt(row.low), fmt(row.high))
		qtyBox.TextEditable = true
	end
	listButton.Active = true
	listButton.AutoButtonColor = true
	listButton.BackgroundColor3 = C.good
	updateNet()
end

local function renderSellList()
	local saved = clearRows(sellList)
	if selectedKey and not selectedRow() then selectedKey = nil end
	for index, row in ipairs(view.inventory) do
		local key = row.itemId .. "|" .. row.enhancement
		local button = addRow(sellList, index, 44, "TextButton")
		button.BackgroundColor3 = (key == selectedKey) and C.tabOn or C.row
		newLabel(button, {
			Size = UDim2.new(1, -16, 1, -6), Position = UDim2.fromOffset(8, 3),
			Text = string.format("%s  x%d\n%s z%s", row.name, row.quantity,
				string.format("%s-%s", fmt(row.low), fmt(row.high)), row.auction and " • ประมูล" or ""),
			Font = Enum.Font.GothamSemibold, TextYAlignment = Enum.TextYAlignment.Center,
		})
		button.Activated:Connect(function()
			selectedKey = key
			qtyBox.Text = "1"
			priceBox.Text = tostring(row.low)
			renderSellList()
			updateForm()
		end)
	end
	if #view.inventory == 0 then addNote(sellList, "ไม่มีไอเท็มที่ลงขายได้ (ของเริ่มต้นลงขายไม่ได้)") end
	sellList.CanvasPosition = saved
end

listButton.Activated:Connect(function()
	local row = selectedRow()
	if not row then return end
	local qty = tonumber(qtyBox.Text)
	local price = tonumber(priceBox.Text)
	if not qty or not price or qty < 1 or price < 1 then
		status.Text = "กรอกจำนวนและราคาให้ถูกต้อง"
		return
	end
	marketAction:FireServer("List", {
		itemId = row.itemId, enhancement = row.enhancement,
		quantity = math.min(qty, row.quantity), unitPrice = price,
	})
end)

-- ===== My listings page =====
local mineHeader = newLabel(pages.Mine, { Size = UDim2.new(1, 0, 0, 24), Text = "", TextColor3 = C.sub })
local mineScroll = newScroll(pages.Mine, { Size = UDim2.new(1, 0, 1, -30), Position = UDim2.fromOffset(0, 30) })

local function renderMine()
	local saved = clearRows(mineScroll)
	local order = 0
	for _, entry in ipairs(view.auctions) do
		if entry.sellerId == player.UserId then
			order += 1
			local row = addRow(mineScroll, order, 46)
			local line = entry.currentBid > 0
				and string.format("ประมูลอยู่ %s z โดย %s", fmt(entry.currentBid), entry.bidderName)
				or string.format("เริ่มที่ %s z • ยังไม่มีผู้ประมูล", fmt(entry.startPrice))
			newLabel(row, {
				Size = UDim2.new(1, -170, 1, -6), Position = UDim2.fromOffset(10, 3),
				Text = string.format("⏳ %s\n%s", entry.name, line),
				Font = Enum.Font.GothamSemibold, TextYAlignment = Enum.TextYAlignment.Center,
			})
			if entry.currentBid > 0 then
				newLabel(row, {
					Size = UDim2.fromOffset(150, 40), Position = UDim2.new(1, -160, 0, 3), Text = "มีผู้ประมูลแล้ว",
					TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Center,
				})
			else
				newButton(row, {
					Size = UDim2.fromOffset(140, 34), Position = UDim2.new(1, -150, 0, 6), Text = "ยกเลิก",
					BackgroundColor3 = C.bad,
				}).Activated:Connect(function()
					marketAction:FireServer("Cancel", { id = entry.id })
				end)
			end
		end
	end
	for _, entry in ipairs(view.fixed) do
		if entry.sellerId == player.UserId then
			order += 1
			local row = addRow(mineScroll, order, 46)
			newLabel(row, {
				Size = UDim2.new(1, -170, 1, -6), Position = UDim2.fromOffset(10, 3),
				Text = string.format("%s  x%d\n%s z/ชิ้น", entry.name, entry.quantity, fmt(entry.unitPrice)),
				Font = Enum.Font.GothamSemibold, TextYAlignment = Enum.TextYAlignment.Center,
			})
			newButton(row, {
				Size = UDim2.fromOffset(140, 34), Position = UDim2.new(1, -150, 0, 6), Text = "ยกเลิก (คืนของ)",
				BackgroundColor3 = C.bad,
			}).Activated:Connect(function()
				marketAction:FireServer("Cancel", { id = entry.id })
			end)
		end
	end
	if order == 0 then addNote(mineScroll, "คุณยังไม่มีรายการลงขาย") end
	mineHeader.Text = string.format("ลงขายอยู่ %d / %d รายการ", view.myListings, view.maxListings)
	mineScroll.CanvasPosition = saved
end

-- ===== wiring =====
local function updateZeny()
	zenyLabel.Text = string.format("Zeny: %s z", fmt(player:GetAttribute("Gold") or 0))
end
updateZeny()
player:GetAttributeChangedSignal("Gold"):Connect(updateZeny)

renderAll = function()
	if not view or not view.fixed then return end
	renderBuy()
	renderAuctions()
	renderSellList()
	updateForm()
	renderMine()
	updateZeny()
end

local function bidBoxFocused()
	local focused = UserInputService:GetFocusedTextBox()
	return focused ~= nil and focused:IsDescendantOf(auctionScroll)
end

closeButton.Activated:Connect(function()
	panel.Visible = false
	marketAction:FireServer("Close")
end)

marketState.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	if payload.closed then
		panel.Visible = false
		return
	end
	if not payload.fixed then return end
	view = payload
	receivedAt = os.clock()
	if payload.open then
		panel.Visible = true
		showTab(currentTab)
		status.Text = "ราคาถูกสุดอยู่บนสุด ราคาเท่ากันขายตามคิวที่ลงก่อน"
	end
	if not panel.Visible then return end
	-- Do not rebuild rows while the player is typing a bid; apply it when they finish.
	if bidBoxFocused() then
		pendingRender = true
	else
		renderAll()
	end
end)

marketFeedback.OnClientEvent:Connect(function(message)
	status.Text = tostring(message)
end)

-- Countdown labels tick locally using the server clock offset from the last push.
task.spawn(function()
	while true do
		task.wait(0.5)
		if panel.Visible and view then
			local nowEstimate = view.serverTime + (os.clock() - receivedAt)
			for _, info in pairs(timerLabels) do
				if info.label.Parent then
					local remaining = math.floor(info.endsAt - nowEstimate)
					if remaining > 0 then
						info.label.Text = string.format("เหลือเวลา %02d:%02d", remaining // 60, remaining % 60)
					else
						info.label.Text = "สิ้นสุดแล้ว • รอสรุปผล"
					end
				end
			end
		end
	end
end)

showTab("Buy")
updateForm()
