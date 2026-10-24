-- Central market (ตลาดกลาง): server-owned listings, supply/demand price bands,
-- cheapest-then-oldest queues, and timed auctions for unique equipment.
-- The client only displays state and sends intents; every rule is checked here.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")

local GameData = ReplicatedStorage:WaitForChild("GameData")
local ItemData = require(GameData:WaitForChild("ItemData"))
local Config = require(GameData:WaitForChild("MarketData"))

local dataApi
repeat
	task.wait(0.1)
	dataApi = _G.DataStore
until dataApi or not script.Parent
if not dataApi then return end

local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local function getOrCreate(className, name)
	local existing = remotes:FindFirstChild(name)
	if existing then return existing end
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local marketState = getOrCreate("RemoteEvent", "MarketState")       -- server -> client: full view
local marketAction = getOrCreate("RemoteEvent", "MarketAction")     -- client -> server: intent
local marketFeedback = getOrCreate("RemoteEvent", "MarketFeedback") -- server -> client: message
local updateInventory = remotes:WaitForChild("UpdateInventory")

-- ============================================================
-- State
-- ============================================================
local listings = {}   -- [id] = listing (flat table of primitives: safe to save as-is)
local nextId = 1
local mailbox = {}    -- [tostring(userId)] = { zeny = n, items = { {itemId, enhancement, quantity} } }
local salesLog = {}   -- [itemId] = { {t = os.time(), q = units} }
local viewers = {}    -- [player] = true while the market window is open
local leaving = {}    -- [userId] = true once PlayerRemoving fired (treated as offline)
local lastAction = {} -- [userId] = os.clock() for rate limiting
local dirtyView = false
local dirtyStore = false
local ready = false -- set after the saved snapshot is restored; actions are ignored before that

local function touch()
	dirtyView = true
	dirtyStore = true
end

-- ============================================================
-- Small helpers
-- ============================================================
local function itemName(itemId)
	local item = ItemData[itemId]
	return item and item.name or tostring(itemId)
end

local function labelFor(itemId, enhancement)
	if (enhancement or 0) > 0 then
		return string.format("%s +%d", itemName(itemId), enhancement)
	end
	return itemName(itemId)
end

-- Accepts only finite whole numbers inside [minV, maxV]; rejects NaN/inf/strings.
local function toInt(value, minV, maxV)
	if type(value) ~= "number" or value ~= value or value % 1 ~= 0 then return nil end
	if value < minV or value > maxV then return nil end
	return value
end

local function feedback(player, message)
	if player and player.Parent then marketFeedback:FireClient(player, message) end
end

local function pushInventory(player, data, message)
	updateInventory:FireClient(player, data.Inventory or {}, data.Equipment or {}, message, data.EquipmentRefine or {})
end

local function canAct(player, interval)
	local now = os.clock()
	if now - (lastAction[player.UserId] or 0) < interval then return false end
	lastAction[player.UserId] = now
	return true
end

local function isNearBroker(player)
	local plaza = Workspace:FindFirstChild("RoROK_StarterPlaza")
	local broker = plaza and plaza:FindFirstChild("MarketBroker")
	local root = broker and broker.PrimaryPart
	local character = player.Character
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and playerRoot ~= nil
		and (playerRoot.Position - root.Position).Magnitude <= Config.InteractDistance
end

-- ============================================================
-- Inventory access. Entries look like { itemId, quantity, enhancement? }.
-- Entries that carry any other field (future slots/enchant data) are never listed,
-- so this system cannot silently destroy data it does not understand.
-- ============================================================
local function isPlainEntry(entry)
	if type(entry) ~= "table" then return false end
	for key in pairs(entry) do
		if key ~= "itemId" and key ~= "quantity" and key ~= "enhancement" then return false end
	end
	return true
end

local function entryRefine(entry)
	return math.clamp(math.floor(tonumber(entry.enhancement) or 0), 0, 15)
end

local ITEM_ALIAS_MAP = {
	Sticky_Mucus = "StickyMucus",
	Iron_Ore     = "IronOre",
	Poring_Card  = "PoringCard",
	Lunatic_Card = "LunaticCard",
}
local function normalizeItemId(id)
	return ITEM_ALIAS_MAP[id] or id
end

local function entryMatches(entry, itemId, enhancement)
	return isPlainEntry(entry)
		and normalizeItemId(entry.itemId) == normalizeItemId(itemId)
		and entryRefine(entry) == enhancement
end

local function countInInventory(data, itemId, enhancement)
	local total = 0
	for _, entry in ipairs(data.Inventory or {}) do
		if entryMatches(entry, itemId, enhancement) then
			total += math.max(0, math.floor(tonumber(entry.quantity) or 0))
		end
	end
	return total
end

local function takeFromInventory(data, itemId, enhancement, quantity)
	if countInInventory(data, itemId, enhancement) < quantity then return false end
	local remaining = quantity
	for index = #data.Inventory, 1, -1 do
		local entry = data.Inventory[index]
		if entryMatches(entry, itemId, enhancement) then
			local take = math.min(remaining, math.max(0, math.floor(tonumber(entry.quantity) or 0)))
			entry.quantity = (tonumber(entry.quantity) or 0) - take
			remaining -= take
			if entry.quantity <= 0 then table.remove(data.Inventory, index) end
			if remaining <= 0 then break end
		end
	end
	return true
end

local function giveToData(data, itemId, enhancement, quantity)
	data.Inventory = data.Inventory or {}
	for _, entry in ipairs(data.Inventory) do
		if entryMatches(entry, itemId, enhancement) then
			entry.quantity = (tonumber(entry.quantity) or 0) + quantity
			return
		end
	end
	local created = { itemId = itemId, quantity = quantity }
	if enhancement > 0 then created.enhancement = enhancement end
	table.insert(data.Inventory, created)
end

local function isTradable(itemId)
	local item = ItemData[itemId]
	if not item or Config.Untradable[itemId] then return false end
	return item.type == "Equipment" or item.type == "Material"
		or item.type == "Consumable" or item.type == "Card"
end

-- ============================================================
-- Pricing: base value -> supply/demand pressure -> allowed band
-- ============================================================
local function baseUnitPrice(itemId)
	local override = Config.BasePrices[itemId]
	if override then return override end
	local item = ItemData[itemId]
	if not item then return Config.MinUnitPrice end
	if item.type == "Equipment" then
		local score = 0
		for stat, value in pairs(item.bonuses or {}) do
			score += (Config.EquipmentStatWeights[stat] or 1) * (tonumber(value) or 0)
		end
		return math.max(Config.MinUnitPrice, math.floor(score * Config.EquipmentPointValue + 0.5))
	end
	local npcValue = tonumber(item.sellPrice) or 1
	return math.max(Config.MinUnitPrice, math.floor(npcValue * Config.MaterialMarkup + 0.5))
end

local function variantFactor(itemId, enhancement)
	local item = ItemData[itemId]
	if not item or item.type ~= "Equipment" then return 1 end
	return 1 + Config.RefineLinear * enhancement + Config.RefineQuadratic * enhancement * enhancement
end

local function recentDemand(itemId, now)
	local total = 0
	local cutoff = now - Config.DemandWindowSeconds
	for _, record in ipairs(salesLog[itemId] or {}) do
		if record.t >= cutoff then total += record.q end
	end
	return total
end

local function recordSale(itemId, quantity)
	local log = salesLog[itemId]
	if not log then
		log = {}
		salesLog[itemId] = log
	end
	table.insert(log, { t = os.time(), q = quantity })
end

-- Units currently on the board per itemId (fixed stacks plus one per auction).
local function supplyMap()
	local supply = {}
	for _, listing in pairs(listings) do
		supply[listing.itemId] = (supply[listing.itemId] or 0) + listing.quantity
	end
	return supply
end

local function priceBand(itemId, enhancement, supply, now)
	local base = baseUnitPrice(itemId) * variantFactor(itemId, enhancement)
	local listed = supply[itemId] or 0
	local sold = recentDemand(itemId, now)
	local pressure = (sold - listed) / (sold + listed + Config.PressureSmoothing)
	local center = base * (1 + Config.PressureSwing * pressure)
	local floorPrice = math.max(Config.MinUnitPrice, math.ceil(base * Config.FloorMultiplier))
	local ceilPrice = math.max(floorPrice + 1, math.floor(base * Config.CeilingMultiplier))
	local low = math.clamp(math.floor(center * (1 - Config.BandHalfWidth)), floorPrice, ceilPrice)
	local high = math.clamp(math.ceil(center * (1 + Config.BandHalfWidth)), low, ceilPrice)
	return low, high
end

-- A listing becomes an auction when its item type is auctionable and the market
-- holds no comparable listing (same itemId and refine level) yet.
local function variantExists(itemId, enhancement)
	for _, listing in pairs(listings) do
		if listing.itemId == itemId and listing.enhancement == enhancement then return true end
	end
	return false
end

local function wouldAuction(itemId, enhancement)
	local item = ItemData[itemId]
	return item ~= nil and Config.AuctionItemTypes[item.type] == true and not variantExists(itemId, enhancement)
end

local function countActiveFor(userId)
	local total = 0
	for _, listing in pairs(listings) do
		if listing.sellerId == userId then total += 1 end
	end
	return total
end

local function minNextBid(auction)
	if auction.currentBid <= 0 then return auction.startPrice end
	local raise = math.max(1, math.ceil(auction.currentBid * Config.AuctionMinRaiseFraction))
	return auction.currentBid + raise
end

-- ============================================================
-- Delivery: pay directly when the target is online with loaded data, else mailbox.
-- ============================================================
local function mailboxFor(userId)
	local key = tostring(userId)
	local box = mailbox[key]
	if not box then
		box = { zeny = 0, items = {} }
		mailbox[key] = box
	end
	return box
end

local function getOnline(userId)
	if leaving[userId] then return nil end
	local player = Players:GetPlayerByUserId(userId)
	if player and player.Parent == Players and dataApi.GetPlayerData(player) then return player end
	return nil
end

local function payZeny(userId, amount, note)
	if amount <= 0 then return end
	local player = getOnline(userId)
	if player and dataApi.ModifyGold(player, amount) then
		feedback(player, note)
		return
	end
	mailboxFor(userId).zeny += amount
end

local function deliverItem(userId, itemId, enhancement, quantity, note)
	local player = getOnline(userId)
	if player then
		local data = dataApi.GetPlayerData(player)
		giveToData(data, itemId, enhancement, quantity)
		pushInventory(player, data, note)
		feedback(player, note)
		return
	end
	table.insert(mailboxFor(userId).items, { itemId = itemId, enhancement = enhancement, quantity = quantity })
end

local function flushMailbox(player)
	local key = tostring(player.UserId)
	local box = mailbox[key]
	if not box then return end
	local data = dataApi.GetPlayerData(player)
	if not data then return end
	mailbox[key] = nil
	if box.zeny > 0 then dataApi.ModifyGold(player, box.zeny) end
	for _, item in ipairs(box.items) do
		giveToData(data, item.itemId, item.enhancement, item.quantity)
	end
	local parts = {}
	if box.zeny > 0 then table.insert(parts, string.format("%d z", box.zeny)) end
	if #box.items > 0 then table.insert(parts, string.format("ไอเท็ม %d รายการ", #box.items)) end
	local message = "ตลาดกลางส่งของที่ค้างอยู่: " .. table.concat(parts, " + ")
	pushInventory(player, data, message)
	feedback(player, message)
	touch()
end

local function saleProceeds(total)
	local tax = math.floor(total * Config.SaleTaxRate)
	return total - tax, tax
end

-- ============================================================
-- View model sent to clients (built once per flush, then personalised)
-- ============================================================
local MAX_FIXED_ROWS = 400

local function buildShared(now)
	local supply = supplyMap()
	local fixed, auctions = {}, {}
	for _, listing in pairs(listings) do
		if listing.kind == "Auction" then
			table.insert(auctions, {
				id = listing.id, itemId = listing.itemId, name = labelFor(listing.itemId, listing.enhancement),
				enhancement = listing.enhancement, sellerId = listing.sellerId, sellerName = listing.sellerName,
				startPrice = listing.startPrice, currentBid = listing.currentBid,
				bidderId = listing.bidderId, bidderName = listing.bidderName,
				endsAt = listing.endsAt, minNext = minNextBid(listing),
			})
		else
			table.insert(fixed, {
				id = listing.id, itemId = listing.itemId, name = labelFor(listing.itemId, listing.enhancement),
				enhancement = listing.enhancement, quantity = listing.quantity, unitPrice = listing.unitPrice,
				sellerId = listing.sellerId, sellerName = listing.sellerName,
			})
		end
	end
	-- Cheapest first; equal prices keep listing order (lower id = listed earlier).
	table.sort(fixed, function(a, b)
		if a.name ~= b.name then return a.name < b.name end
		if a.unitPrice ~= b.unitPrice then return a.unitPrice < b.unitPrice end
		return a.id < b.id
	end)
	table.sort(auctions, function(a, b)
		if a.endsAt ~= b.endsAt then return a.endsAt < b.endsAt end
		return a.id < b.id
	end)
	local truncated = false
	while #fixed > MAX_FIXED_ROWS do
		table.remove(fixed)
		truncated = true
	end
	return { now = now, supply = supply, fixed = fixed, auctions = auctions, truncated = truncated }
end

local function buildView(player, shared)
	local data = dataApi.GetPlayerData(player)
	local inventory = {}
	local seen = {}
	for _, entry in ipairs(data and data.Inventory or {}) do
		if isPlainEntry(entry) and isTradable(entry.itemId) then
			local enhancement = entryRefine(entry)
			local key = entry.itemId .. "|" .. enhancement
			local row = seen[key]
			if row then
				row.quantity += math.max(0, math.floor(tonumber(entry.quantity) or 0))
			else
				local low, high = priceBand(entry.itemId, enhancement, shared.supply, shared.now)
				row = {
					itemId = entry.itemId, name = labelFor(entry.itemId, enhancement), enhancement = enhancement,
					quantity = math.max(0, math.floor(tonumber(entry.quantity) or 0)),
					low = low, high = high, auction = wouldAuction(entry.itemId, enhancement),
				}
				seen[key] = row
				table.insert(inventory, row)
			end
		end
	end
	table.sort(inventory, function(a, b)
		if a.name ~= b.name then return a.name < b.name end
		return a.enhancement < b.enhancement
	end)
	return {
		serverTime = shared.now,
		fixed = shared.fixed,
		auctions = shared.auctions,
		truncated = shared.truncated,
		inventory = inventory,
		taxRate = Config.SaleTaxRate,
		auctionSeconds = Config.AuctionDurationSeconds,
		maxListings = Config.MaxActiveListingsPerPlayer,
		myListings = countActiveFor(player.UserId),
	}
end

local function sendView(player, opened)
	local shared = buildShared(os.time())
	local view = buildView(player, shared)
	view.open = opened == true
	marketState:FireClient(player, view)
end

-- ============================================================
-- Actions
-- ============================================================
local function handleList(player, payload)
	if type(payload) ~= "table" then return end
	local itemId = payload.itemId
	local enhancement = toInt(payload.enhancement, 0, 15)
	local quantity = toInt(payload.quantity, 1, Config.MaxQuantityPerListing)
	local price = toInt(payload.unitPrice, 1, Config.MaxPriceAllowed)
	if type(itemId) ~= "string" or not enhancement or not quantity or not price then
		feedback(player, "ข้อมูลการลงขายไม่ถูกต้อง")
		return
	end
	local item = ItemData[itemId]
	if not isTradable(itemId) then
		feedback(player, "ไอเท็มนี้ลงขายในตลาดกลางไม่ได้")
		return
	end
	if item.type ~= "Equipment" and enhancement ~= 0 then return end
	local data = dataApi.GetPlayerData(player)
	if not data then return end
	if countActiveFor(player.UserId) >= Config.MaxActiveListingsPerPlayer then
		feedback(player, string.format("ลงขายพร้อมกันได้สูงสุด %d รายการ", Config.MaxActiveListingsPerPlayer))
		return
	end
	if countInInventory(data, itemId, enhancement) < quantity then
		feedback(player, "มีไอเท็มไม่พอสำหรับลงขาย")
		return
	end

	local now = os.time()
	local isAuction = wouldAuction(itemId, enhancement)
	if isAuction then quantity = 1 end -- one auction = one item
	local low, high = priceBand(itemId, enhancement, supplyMap(), now)
	if price < low or price > high then
		feedback(player, string.format("ราคาต้องอยู่ในช่วง %d - %d z", low, high))
		return
	end
	if not takeFromInventory(data, itemId, enhancement, quantity) then return end

	local id = nextId
	nextId += 1
	local listing = {
		id = id, kind = isAuction and "Auction" or "Fixed",
		sellerId = player.UserId, sellerName = player.Name,
		itemId = itemId, enhancement = enhancement, quantity = quantity,
		unitPrice = isAuction and 0 or price, startPrice = isAuction and price or 0,
		currentBid = 0, bidderId = 0, bidderName = "",
		endsAt = isAuction and (now + Config.AuctionDurationSeconds) or 0,
		createdAt = now,
	}
	listings[id] = listing
	local message
	if isAuction then
		message = string.format("เปิดประมูล %s เริ่มที่ %d z (นาน %d นาที)", labelFor(itemId, enhancement), price, Config.AuctionDurationSeconds // 60)
	else
		message = string.format("ลงขาย %s x%d ราคา %d z/ชิ้น", labelFor(itemId, enhancement), quantity, price)
	end
	pushInventory(player, data, message)
	feedback(player, message)
	touch()
end

local function handleBuy(player, payload)
	if type(payload) ~= "table" then return end
	local id = toInt(payload.id, 1, 2 ^ 31)
	local quantity = toInt(payload.quantity, 1, Config.MaxQuantityPerListing)
	local listing = id and listings[id]
	if not listing or listing.kind ~= "Fixed" or not quantity then
		feedback(player, "รายการนี้ไม่มีแล้ว")
		touch()
		return
	end
	if listing.sellerId == player.UserId then
		feedback(player, "ซื้อของที่ตัวเองลงขายไม่ได้")
		return
	end
	if quantity > listing.quantity then
		feedback(player, "จำนวนในตลาดเหลือไม่พอ")
		touch()
		return
	end
	local data = dataApi.GetPlayerData(player)
	if not data then return end
	local total = listing.unitPrice * quantity
	if not dataApi.ModifyGold(player, -total) then
		feedback(player, string.format("Zeny ไม่พอ (ต้องใช้ %d z)", total))
		return
	end
	-- No yielding between here and the end: the sale is atomic.
	giveToData(data, listing.itemId, listing.enhancement, quantity)
	listing.quantity -= quantity
	if listing.quantity <= 0 then listings[listing.id] = nil end
	recordSale(listing.itemId, quantity)
	local proceeds, tax = saleProceeds(total)
	local label = labelFor(listing.itemId, listing.enhancement)
	payZeny(listing.sellerId, proceeds,
		string.format("ขาย %s x%d ได้ %d z (หักภาษี %d z)", label, quantity, proceeds, tax))
	local message = string.format("ซื้อ %s x%d จ่าย %d z", label, quantity, total)
	pushInventory(player, data, message)
	feedback(player, message)
	touch()
end

local function handleBid(player, payload)
	if type(payload) ~= "table" then return end
	local id = toInt(payload.id, 1, 2 ^ 31)
	local amount = toInt(payload.amount, 1, Config.MaxPriceAllowed * 10)
	local auction = id and listings[id]
	local now = os.time()
	if not auction or auction.kind ~= "Auction" or auction.endsAt <= now or not amount then
		feedback(player, "การประมูลนี้จบแล้วหรือไม่มีอยู่")
		touch()
		return
	end
	if auction.sellerId == player.UserId then
		feedback(player, "ประมูลของที่ตัวเองลงขายไม่ได้")
		return
	end
	if auction.bidderId == player.UserId then
		feedback(player, "คุณเป็นผู้ประมูลสูงสุดอยู่แล้ว")
		return
	end
	local minimum = minNextBid(auction)
	if amount < minimum then
		feedback(player, string.format("ต้องประมูลอย่างน้อย %d z", minimum))
		touch()
		return
	end
	if not dataApi.ModifyGold(player, -amount) then
		feedback(player, string.format("Zeny ไม่พอ (ต้องใช้ %d z)", amount))
		return
	end
	-- Escrow: the bid is already withheld; refund the previous leader.
	local previousId, previousBid = auction.bidderId, auction.currentBid
	auction.currentBid = amount
	auction.bidderId = player.UserId
	auction.bidderName = player.Name
	local label = labelFor(auction.itemId, auction.enhancement)
	if previousId ~= 0 and previousBid > 0 then
		payZeny(previousId, previousBid, string.format("มีคนประมูล %s สูงกว่า คืน %d z", label, previousBid))
	end
	feedback(player, string.format("ประมูล %s ที่ %d z แล้ว", label, amount))
	touch()
end

local function handleCancel(player, payload)
	if type(payload) ~= "table" then return end
	local id = toInt(payload.id, 1, 2 ^ 31)
	local listing = id and listings[id]
	if not listing or listing.sellerId ~= player.UserId then return end
	if listing.kind == "Auction" and listing.currentBid > 0 then
		feedback(player, "มีผู้ประมูลแล้ว ยกเลิกไม่ได้")
		return
	end
	local data = dataApi.GetPlayerData(player)
	if not data then return end
	listings[listing.id] = nil
	giveToData(data, listing.itemId, listing.enhancement, listing.quantity)
	local message = string.format("ยกเลิกการขาย %s คืนเข้ากระเป๋าแล้ว", labelFor(listing.itemId, listing.enhancement))
	pushInventory(player, data, message)
	feedback(player, message)
	touch()
end

marketAction.OnServerEvent:Connect(function(player, action, payload)
	if not ready or type(action) ~= "string" then return end
	if action == "Close" then
		viewers[player] = nil
		return
	end
	if not canAct(player, 0.25) then return end
	if not isNearBroker(player) then
		viewers[player] = nil
		marketState:FireClient(player, { closed = true })
		feedback(player, "อยู่ไกลจากพ่อค้าตลาดกลางเกินไป")
		return
	end
	if action == "Refresh" then
		viewers[player] = true
		sendView(player, false)
	elseif action == "List" then
		handleList(player, payload)
	elseif action == "Buy" then
		handleBuy(player, payload)
	elseif action == "Bid" then
		handleBid(player, payload)
	elseif action == "Cancel" then
		handleCancel(player, payload)
	end
end)

-- ============================================================
-- Auction resolution and view flushing (1 Hz)
-- ============================================================
local function resolveAuction(auction)
	listings[auction.id] = nil
	local label = labelFor(auction.itemId, auction.enhancement)
	if auction.bidderId ~= 0 and auction.currentBid > 0 then
		deliverItem(auction.bidderId, auction.itemId, auction.enhancement, auction.quantity,
			string.format("ชนะประมูล %s ที่ %d z", label, auction.currentBid))
		recordSale(auction.itemId, auction.quantity)
		local proceeds, tax = saleProceeds(auction.currentBid)
		payZeny(auction.sellerId, proceeds,
			string.format("ประมูล %s สำเร็จ ได้ %d z (หักภาษี %d z)", label, proceeds, tax))
	else
		deliverItem(auction.sellerId, auction.itemId, auction.enhancement, auction.quantity,
			string.format("ประมูล %s ไม่มีผู้เสนอราคา คืนของแล้ว", label))
	end
	touch()
end

local function resolveEndedAuctions(now)
	local ended = {}
	for _, listing in pairs(listings) do
		if listing.kind == "Auction" and listing.endsAt <= now then table.insert(ended, listing) end
	end
	table.sort(ended, function(a, b) return a.id < b.id end)
	for _, auction in ipairs(ended) do
		if listings[auction.id] == auction then resolveAuction(auction) end
	end
end

task.spawn(function()
	local lastPrune = os.time()
	while true do
		task.wait(1)
		local now = os.time()
		resolveEndedAuctions(now)
		-- Close the window for anyone who walked away from the broker.
		for player in pairs(viewers) do
			if player.Parent ~= Players or not isNearBroker(player) then
				viewers[player] = nil
				if player.Parent == Players then marketState:FireClient(player, { closed = true }) end
			end
		end
		if dirtyView then
			dirtyView = false
			local shared = buildShared(now)
			for player in pairs(viewers) do
				local view = buildView(player, shared)
				view.open = false
				marketState:FireClient(player, view)
			end
		end
		if now - lastPrune >= 60 then
			lastPrune = now
			local cutoff = now - Config.DemandWindowSeconds
			for itemId, log in pairs(salesLog) do
				local kept = {}
				for _, record in ipairs(log) do
					if record.t >= cutoff then table.insert(kept, record) end
				end
				salesLog[itemId] = #kept > 0 and kept or nil
			end
		end
	end
end)

-- ============================================================
-- Persistence: one snapshot document, best-effort.
-- Assumes ONE active server. Several live servers would overwrite each other's
-- snapshot; that needs MemoryStoreService/UpdateAsync work (see MARKET_NOTES_TH.md).
-- ============================================================
local store
local persistent = false
local saving = false

local function sanitizeListing(raw)
	if type(raw) ~= "table" then return nil end
	local id = toInt(raw.id, 1, 2 ^ 31)
	local sellerId = toInt(raw.sellerId, 1, 2 ^ 53)
	local enhancement = toInt(raw.enhancement, 0, 15)
	local quantity = toInt(raw.quantity, 1, Config.MaxQuantityPerListing)
	if not id or not sellerId or not enhancement or not quantity then return nil end
	if type(raw.itemId) ~= "string" or (raw.kind ~= "Fixed" and raw.kind ~= "Auction") then return nil end
	return {
		id = id, kind = raw.kind, sellerId = sellerId, sellerName = tostring(raw.sellerName or "?"),
		itemId = raw.itemId, enhancement = enhancement, quantity = quantity,
		unitPrice = math.max(0, math.floor(tonumber(raw.unitPrice) or 0)),
		startPrice = math.max(0, math.floor(tonumber(raw.startPrice) or 0)),
		currentBid = math.max(0, math.floor(tonumber(raw.currentBid) or 0)),
		bidderId = math.max(0, math.floor(tonumber(raw.bidderId) or 0)),
		bidderName = tostring(raw.bidderName or ""),
		endsAt = math.max(0, math.floor(tonumber(raw.endsAt) or 0)),
		createdAt = math.max(0, math.floor(tonumber(raw.createdAt) or 0)),
	}
end

local function restoreSnapshot(snapshot)
	if type(snapshot) ~= "table" then return end
	nextId = math.max(nextId, math.floor(tonumber(snapshot.nextId) or 1))
	for _, raw in ipairs(snapshot.listings or {}) do
		local listing = sanitizeListing(raw)
		if listing then
			listings[listing.id] = listing
			nextId = math.max(nextId, listing.id + 1)
		end
	end
	for key, box in pairs(snapshot.mailbox or {}) do
		if type(box) == "table" then
			local restored = { zeny = math.max(0, math.floor(tonumber(box.zeny) or 0)), items = {} }
			for _, item in ipairs(box.items or {}) do
				local enhancement = toInt(item.enhancement, 0, 15)
				local quantity = toInt(item.quantity, 1, Config.MaxQuantityPerListing)
				if type(item.itemId) == "string" and enhancement and quantity then
					table.insert(restored.items, { itemId = item.itemId, enhancement = enhancement, quantity = quantity })
				end
			end
			mailbox[tostring(key)] = restored
		end
	end
end

local function takeSnapshot()
	local out = { version = 1, nextId = nextId, listings = {}, mailbox = {} }
	for _, listing in pairs(listings) do table.insert(out.listings, table.clone(listing)) end
	for key, box in pairs(mailbox) do
		local items = {}
		for _, item in ipairs(box.items) do table.insert(items, table.clone(item)) end
		out.mailbox[key] = { zeny = box.zeny, items = items }
	end
	return out
end

local function saveSnapshot()
	if not persistent or saving then return end
	saving = true
	local snapshot = takeSnapshot()
	local ok, err = pcall(function() store:SetAsync("Snapshot", snapshot) end)
	saving = false
	if not ok then
		dirtyStore = true
		warn("[MarketSystem] บันทึกตลาดไม่สำเร็จ / save failed: " .. tostring(err))
	end
end

do
	local okStore, result = pcall(function() return DataStoreService:GetDataStore("RoROK_Market_v1") end)
	if okStore then store = result end
	if store then
		for attempt = 1, 3 do
			local ok, snapshot = pcall(function() return store:GetAsync("Snapshot") end)
			if ok then
				-- Never enable saving unless the restore worked: a failed restore must not
				-- be followed by an empty snapshot overwriting the stored market.
				local restored, restoreErr = pcall(restoreSnapshot, snapshot)
				if restored then
					persistent = true
				else
					warn("[MarketSystem] snapshot เสียหาย ไม่เปิดการบันทึก: " .. tostring(restoreErr))
				end
				break
			end
			warn(string.format("[MarketSystem] โหลดตลาดไม่ได้ (ครั้งที่ %d): %s", attempt, tostring(snapshot)))
			task.wait(2 * attempt)
		end
	end
	ready = true
	if not persistent then
		warn("[MarketSystem] DataStore ใช้ไม่ได้ ตลาดกลางจะอยู่แค่ในหน่วยความจำ (หายเมื่อปิดเซิร์ฟเวอร์) / market runs in memory only")
	end
end

task.spawn(function()
	while true do
		task.wait(5)
		if dirtyStore and persistent and not saving then
			dirtyStore = false
			saveSnapshot()
		end
	end
end)

game:BindToClose(function()
	if not persistent then return end
	local waited = 0
	while saving and waited < 10 do
		task.wait(0.2)
		waited += 0.2
	end
	saveSnapshot()
end)

-- ============================================================
-- Players: deliver mailbox when data is ready; stop viewing when leaving.
-- ============================================================
local function onPlayerAdded(player)
	leaving[player.UserId] = nil
	task.spawn(function()
		for _ = 1, 240 do
			if player.Parent ~= Players then return end
			if dataApi.GetPlayerData(player) then
				flushMailbox(player)
				return
			end
			task.wait(0.5)
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do onPlayerAdded(player) end

Players.PlayerRemoving:Connect(function(player)
	leaving[player.UserId] = true
	viewers[player] = nil
	lastAction[player.UserId] = nil
end)

-- ============================================================
-- Broker NPC in the plaza, between the two existing market stalls.
-- ============================================================
local function buildBroker()
	local town = Workspace:WaitForChild("RoROK_StarterPlaza")
	local previous = town:FindFirstChild("MarketBroker")
	if previous then previous:Destroy() end
	local npc = Instance.new("Model")
	npc.Name = "MarketBroker"
	npc.Parent = town

	local function makePart(name, size, position, color, material, shape)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Position = position
		part.Anchored = true
		part.CanCollide = false
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		part.Shape = shape or Enum.PartType.Block
		part.Parent = npc
		return part
	end

	local mx, my, mz = -32, 2.75, 27.5
	local torso = makePart("HumanoidRootPart", Vector3.new(1.5, 1.8, 0.75), Vector3.new(mx, my, mz), Color3.fromRGB(120, 70, 96))
	npc.PrimaryPart = torso
	makePart("Sash", Vector3.new(1.55, 0.5, 0.12), Vector3.new(mx, my + 0.25, mz - 0.42), Color3.fromRGB(226, 184, 80))
	makePart("Head", Vector3.new(1.05, 1.05, 1.05), Vector3.new(mx, my + 1.45, mz), Color3.fromRGB(224, 174, 137), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	makePart("Hat", Vector3.new(1.5, 0.3, 1.5), Vector3.new(mx, my + 2.0, mz), Color3.fromRGB(226, 184, 80))
	makePart("LegL", Vector3.new(0.55, 1.4, 0.6), Vector3.new(mx - 0.36, 1.15, mz), Color3.fromRGB(64, 58, 54))
	makePart("LegR", Vector3.new(0.55, 1.4, 0.6), Vector3.new(mx + 0.36, 1.15, mz), Color3.fromRGB(64, 58, 54))
	makePart("Ledger", Vector3.new(3.2, 0.4, 1.5), Vector3.new(mx, 3.05, mz - 1.5), Color3.fromRGB(111, 77, 49), Enum.Material.WoodPlanks)

	local brokerBB = Instance.new("BillboardGui")
	brokerBB.Size = UDim2.fromOffset(160, 36)
	brokerBB.StudsOffset = Vector3.new(0, 2.7, 0)
	brokerBB.MaxDistance = 32
	brokerBB.AlwaysOnTop = false
	brokerBB.Parent = torso
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "นายหน้าตลาดกลาง\n[F] เปิดตลาดกลาง"
	label.TextColor3 = Color3.fromRGB(255, 226, 160)
	label.TextStrokeTransparency = 0.2
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = brokerBB

	local promptPoint = Instance.new("Attachment")
	promptPoint.Name = "MarketPromptPoint"
	promptPoint.Position = Vector3.new(0, 2, -0.45)
	promptPoint.Parent = torso
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenMarket"
	prompt.ActionText = "เปิดตลาดกลาง"
	prompt.ObjectText = "นายหน้าตลาดกลาง"
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptPoint
	prompt.Triggered:Connect(function(player)
		if not ready then
			feedback(player, "ตลาดกลางกำลังเตรียมข้อมูล ลองใหม่อีกครั้ง")
			return
		end
		if not dataApi.GetPlayerData(player) then
			feedback(player, "กำลังโหลดข้อมูลตัวละคร รอสักครู่แล้วคุยกับพ่อค้าอีกครั้ง")
			return
		end
		viewers[player] = true
		sendView(player, true)
	end)
end

task.spawn(buildBroker)
print("[MarketSystem] central market ready")
