-- Small Prontera supply stall: server-owned purchases and consumable use.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ItemData = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("ItemData"))
local dataApi
repeat
	task.wait(0.1)
	dataApi = _G.DataStore
until dataApi or not script.Parent
if not dataApi then return end

local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local function getOrCreate(className, name)
	local remote = remotes:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = remotes
	end
	return remote
end

local openShop = getOrCreate("RemoteEvent", "OpenSupplyShop")
local purchaseItem = getOrCreate("RemoteEvent", "PurchaseShopItem")
local sellItem = getOrCreate("RemoteEvent", "SellShopItem")
local useConsumable = getOrCreate("RemoteEvent", "UseConsumable")
local shopFeedback = getOrCreate("RemoteEvent", "ShopFeedback")
local updateInventory = remotes:WaitForChild("UpdateInventory")

local shopItems = {
	RedPotion = true, WhitePotion = true, BluePotion = true, Panacea = true,
	FireScroll = true, WaterScroll = true, WindScroll = true, EarthScroll = true, HolyScroll = true, ShadowScroll = true,
	BeginnerRefinementStone = true,
}
local actionTimes = {}
local function canAct(player, action, interval)
	local key = tostring(player.UserId) .. ":" .. action
	local now = os.clock()
	if now - (actionTimes[key] or 0) < interval then return false end
	actionTimes[key] = now
	return true
end

local function sendInventory(player, data, message)
	updateInventory:FireClient(player, data.Inventory or {}, data.Equipment or {}, message, data.EquipmentRefine or {})
end

local function isNearVendor(player)
	local vendor = Workspace:FindFirstChild("RoROK_TownShop")
	local model = vendor and vendor:FindFirstChild("SupplyVendor")
	local vendorRoot = model and model.PrimaryPart
	local character = player.Character
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	return vendorRoot ~= nil and playerRoot ~= nil and (playerRoot.Position - vendorRoot.Position).Magnitude <= 14
end

purchaseItem.OnServerEvent:Connect(function(player, itemId, quantity)
	if type(itemId) ~= "string" or not shopItems[itemId] or (quantity ~= 1 and quantity ~= 5) then return end
	if not canAct(player, "buy", 0.2) or not isNearVendor(player) then return end
	local item = ItemData[itemId]
	local data = dataApi.GetPlayerData(player)
	if not item or (item.type ~= "Consumable" and item.type ~= "Material") or not data then return end
	local totalCost = (tonumber(item.buyPrice) or 0) * quantity
	if totalCost <= 0 or not dataApi.ModifyGold(player, -totalCost) then
		shopFeedback:FireClient(player, string.format("Zeny ไม่พอ (ต้องใช้ %d z)", totalCost))
		return
	end
	local added = dataApi.AddItem(player, itemId, quantity)
	if not added then
		dataApi.ModifyGold(player, totalCost)
		return
	end
	local message = string.format("ซื้อ %s x%d แล้ว • จ่าย %d z", item.name, quantity, totalCost)
	sendInventory(player, data, message)
	shopFeedback:FireClient(player, message)
end)

sellItem.OnServerEvent:Connect(function(player, itemId, quantity)
	if type(itemId) ~= "string" or type(quantity) ~= "number" or quantity % 1 ~= 0 or quantity < 1 then return end
	if not canAct(player, "sell", 0.2) or not isNearVendor(player) then return end
	local item = ItemData[itemId]
	local sellableType = item and (item.type == "Material" or item.type == "Card"
		or (item.type == "Consumable" and item.buyPrice == nil))
	local unitPrice = item and math.floor(tonumber(item.sellPrice) or 0) or 0
	if not sellableType or unitPrice <= 0 then return end
	local data = dataApi.GetPlayerData(player)
	if not data then return end
	local entry
	for _, owned in ipairs(data.Inventory or {}) do
		if owned.itemId == itemId and (tonumber(owned.quantity) or 0) >= quantity then entry = owned; break end
	end
	if not entry then
		shopFeedback:FireClient(player, "มีไอเท็มไม่พอสำหรับขาย")
		return
	end
	local totalValue = unitPrice * quantity
	entry.quantity -= quantity
	if entry.quantity <= 0 then
		for index, owned in ipairs(data.Inventory) do
			if owned == entry then table.remove(data.Inventory, index); break end
		end
	end
	dataApi.ModifyGold(player, totalValue)
	local message = string.format("ขาย %s x%d ได้ %d z", item.name, quantity, totalValue)
	sendInventory(player, data, message)
	shopFeedback:FireClient(player, message)
end)

useConsumable.OnServerEvent:Connect(function(player, itemId)
	if type(itemId) ~= "string" or not canAct(player, "use", 0.35) then return end
	local data = dataApi.GetPlayerData(player)
	local item = ItemData[itemId]
	if not data or not item or item.type ~= "Consumable" or type(item.use) ~= "table" then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	local inventoryEntry
	for _, entry in ipairs(data.Inventory or {}) do
		if entry.itemId == itemId and (tonumber(entry.quantity) or 0) > 0 then inventoryEntry = entry; break end
	end
	if not inventoryEntry then return end

	local derived = dataApi.CalcDerivedStats(data)
	local healedHP, restoredSP = 0, 0
	local coatEl = item.use.CoatElement
	local cureAll = item.use.CureAll == true
	if tonumber(item.use.HP) then
		local nextHP = math.min(derived.MaxHP, data.HP + math.max(0, math.floor(item.use.HP)))
		healedHP = nextHP - data.HP
	end
	if tonumber(item.use.SP) then
		local nextSP = math.min(derived.MaxSP, data.SP + math.max(0, math.floor(item.use.SP)))
		restoredSP = nextSP - data.SP
	end
	if healedHP <= 0 and restoredSP <= 0 and not coatEl and not cureAll then
		shopFeedback:FireClient(player, "ค่าสถานะเต็มอยู่แล้ว ใช้ไอเท็มไม่ได้")
		return
	end
	if healedHP > 0 then dataApi.SetHP(player, data.HP + healedHP) end
	if restoredSP > 0 then dataApi.SetSP(player, data.SP + restoredSP) end
	if cureAll and _G.CombatSystem and _G.CombatSystem.ClearPlayerStatuses then
		_G.CombatSystem.ClearPlayerStatuses(player)
	end
	if coatEl and _G.CombatSystem and _G.CombatSystem.ApplyWeaponCoating then
		_G.CombatSystem.ApplyWeaponCoating(player, coatEl, tonumber(item.use.Duration) or 300)
	end
	inventoryEntry.quantity -= 1
	if inventoryEntry.quantity <= 0 then
		for index, entry in ipairs(data.Inventory) do
			if entry == inventoryEntry then table.remove(data.Inventory, index); break end
		end
	end
	if healedHP > 0 then
		local root = character:FindFirstChild("HumanoidRootPart")
		local healNumber = remotes:FindFirstChild("ShowHealNumber")
		if root and healNumber then healNumber:FireClient(player, root.Position, healedHP) end
	end
	if _G.PushCharacterData then _G.PushCharacterData(player) end
	local effect = coatEl and ("เคลือบธาตุ " .. tostring(coatEl) .. " 5 นาที")
		or (cureAll and "ล้างสถานะผิดปกติทั้งหมด")
		or (healedHP > 0 and string.format("ฟื้นฟู HP %d", healedHP) or string.format("ฟื้นฟู SP %d", restoredSP))
	local message = string.format("ใช้ %s แล้ว • %s", item.name, effect)
	sendInventory(player, data, message)
	shopFeedback:FireClient(player, message)
end)

-- Build a compact, recognizable stall next to the Prontera plaza.
local old = Workspace:FindFirstChild("RoROK_TownShop")
if old then old:Destroy() end
local shopRoot = Instance.new("Folder")
shopRoot.Name = "RoROK_TownShop"
shopRoot.Parent = Workspace
local vendor = Instance.new("Model")
vendor.Name = "SupplyVendor"
vendor.Parent = shopRoot

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
	part.Parent = vendor
	return part
end

local vx, vy, vz = 32, 2.75, 27.5
local torso = makePart("VendorRoot", Vector3.new(1.5, 1.8, 0.75), Vector3.new(vx, vy, vz), Color3.fromRGB(66, 104, 95))
vendor.PrimaryPart = torso
makePart("Apron", Vector3.new(1.55, 0.9, 0.12), Vector3.new(vx, vy - 0.25, vz - 0.42), Color3.fromRGB(115, 83, 47))
makePart("Head", Vector3.new(1.05, 1.05, 1.05), Vector3.new(vx, vy + 1.45, vz), Color3.fromRGB(224, 174, 137), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
makePart("Hair", Vector3.new(1.1, 0.3, 1.1), Vector3.new(vx, vy + 1.9, vz), Color3.fromRGB(78, 47, 38), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
makePart("LegL", Vector3.new(0.55, 1.4, 0.6), Vector3.new(vx - 0.36, 1.15, vz), Color3.fromRGB(64, 58, 54))
makePart("LegR", Vector3.new(0.55, 1.4, 0.6), Vector3.new(vx + 0.36, 1.15, vz), Color3.fromRGB(64, 58, 54))
makePart("RedPotionDisplay", Vector3.new(0.55, 0.75, 0.55), Vector3.new(vx - 1.4, 3.15, vz - 1.5), Color3.fromRGB(216, 61, 75), Enum.Material.Neon, Enum.PartType.Ball)
makePart("BluePotionDisplay", Vector3.new(0.55, 0.75, 0.55), Vector3.new(vx + 1.4, 3.15, vz - 1.5), Color3.fromRGB(70, 143, 235), Enum.Material.Neon, Enum.PartType.Ball)

local vendorBB = Instance.new("BillboardGui")
vendorBB.Size = UDim2.fromOffset(160, 36)
vendorBB.StudsOffset = Vector3.new(0, 2.7, 0)
vendorBB.MaxDistance = 32
vendorBB.AlwaysOnTop = false
vendorBB.Parent = torso
local signText = Instance.new("TextLabel")
signText.Size = UDim2.fromScale(1, 1)
signText.BackgroundTransparency = 1
signText.Text = "แม่ค้าขายยา Elise\n[F] ซื้อยาและของใช้"
signText.TextColor3 = Color3.fromRGB(255, 226, 160)
signText.TextStrokeTransparency = 0.2
signText.TextScaled = true
signText.Font = Enum.Font.GothamBold
signText.Parent = vendorBB

local prompt = Instance.new("ProximityPrompt")
prompt.Name = "OpenSupplyShop"
prompt.ActionText = "ซื้อยาและของใช้"
prompt.ObjectText = "แม่ค้าขายยา Elise"
prompt.KeyboardKeyCode = Enum.KeyCode.F
prompt.HoldDuration = 0
prompt.MaxActivationDistance = 12
prompt.RequiresLineOfSight = false
local promptPoint = Instance.new("Attachment")
promptPoint.Name = "SupplyShopPromptPoint"
promptPoint.Position = Vector3.new(0, 2, -0.45)
promptPoint.Parent = torso
prompt.Parent = promptPoint
prompt.Triggered:Connect(function(player)
	openShop:FireClient(player)
end)

Players.PlayerRemoving:Connect(function(player)
	local prefix = tostring(player.UserId) .. ":"
	for key in pairs(actionTimes) do
		if key:sub(1, #prefix) == prefix then actionTimes[key] = nil end
	end
end)

print("[TownShop] Prontera supply shop ready")
