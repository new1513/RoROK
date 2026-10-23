-- ระบบทิ้งของลงพื้น + เก็บของ (Drop to ground / Item pickup)
-- Client ส่ง DropItem(itemId, enhancement, quantity) -> Server ตัดของจากกระเป๋าแล้วสร้างไอเทมบนพื้น
-- ผู้เล่นกด E ที่ ProximityPrompt เพื่อเก็บกลับ
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local gameData = ReplicatedStorage:WaitForChild("GameData")
local ItemData = require(gameData:WaitForChild("ItemData"))
local ItemRarity = require(gameData:WaitForChild("ItemRarity"))

local dataApi, remotesApi
repeat
	task.wait(0.1)
	dataApi, remotesApi = _G.DataStore, _G.Remotes
until (dataApi and remotesApi) or not script.Parent
if not dataApi or not remotesApi then return end

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local dropRemote = remoteFolder:FindFirstChild("DropItem")
if not dropRemote then
	dropRemote = Instance.new("RemoteEvent")
	dropRemote.Name = "DropItem"
	dropRemote.Parent = remoteFolder
end

local DESPAWN_SECONDS = 180
local DROP_COOLDOWN = 0.25
local MAX_DROPS_PER_PLAYER = 30

local dropsFolder = Workspace:FindFirstChild("DroppedItems")
if not dropsFolder then
	dropsFolder = Instance.new("Folder")
	dropsFolder.Name = "DroppedItems"
	dropsFolder.Parent = Workspace
end

local lastDrop = {}
local dropCount = {}

local function pushInventory(player, data, message)
	remotesApi.UpdateInventory:FireClient(player, data.Inventory or {}, data.Equipment or {}, message, data.EquipmentRefine or {})
end

local function addToInventory(data, itemId, enhancement, quantity)
	data.Inventory = data.Inventory or {}
	for _, entry in ipairs(data.Inventory) do
		if entry.itemId == itemId and (tonumber(entry.enhancement) or 0) == enhancement then
			entry.quantity = (tonumber(entry.quantity) or 0) + quantity
			return
		end
	end
	local created = { itemId = itemId, quantity = quantity }
	if enhancement > 0 then created.enhancement = enhancement end
	table.insert(data.Inventory, created)
end

local function groundPositionAt(root)
	local origin = root.Position + root.CFrame.LookVector * 4 + Vector3.new(0, 2, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { dropsFolder, root.Parent }
	local hit = Workspace:Raycast(origin, Vector3.new(0, -30, 0), params)
	return (hit and hit.Position or (root.Position - Vector3.new(0, 2.5, 0))) + Vector3.new(0, 0.9, 0)
end

local function spawnWorldItem(player, itemId, enhancement, quantity, position)
	local item = ItemData[itemId]
	local tier = ItemRarity.GetTier(itemId)

	local part = Instance.new("Part")
	part.Name = "Drop_" .. itemId
	part.Size = Vector3.new(1.4, 1.4, 1.4)
	part.Shape = item.type == "Card" and Enum.PartType.Block or Enum.PartType.Ball
	part.Material = Enum.Material.Neon
	part.Color = tier.color
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.CFrame = CFrame.new(position)
	part:SetAttribute("ItemId", itemId)
	part:SetAttribute("Quantity", quantity)
	part:SetAttribute("Enhancement", enhancement)
	part:SetAttribute("Rarity", tier.name)

	local light = Instance.new("PointLight")
	light.Color = tier.color
	light.Range = 8 + tier.order * 2
	light.Brightness = 1.2
	light.Parent = part

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(180, 34)
	gui.StudsOffset = Vector3.new(0, 2, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 60
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = tier.color
	label.TextStrokeTransparency = 0.3
	label.Text = string.format("%s%s x%d", item.name, enhancement > 0 and (" +" .. enhancement) or "", quantity)
	label.Parent = gui

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "เก็บ"
	prompt.ObjectText = item.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	local picked = false
	prompt.Triggered:Connect(function(picker)
		if picked or not part.Parent then return end
		local data = dataApi.GetPlayerData(picker)
		if not data then return end
		picked = true
		addToInventory(data, itemId, enhancement, quantity)
		if dropCount[player] then dropCount[player] = math.max(0, dropCount[player] - 1) end
		part:Destroy()
		pushInventory(picker, data, string.format("เก็บ %s x%d แล้ว", item.name, quantity))
		if _G.DailyQuestSystem and _G.DailyQuestSystem.AddProgress then
			_G.DailyQuestSystem.AddProgress(picker, "Collect", itemId, quantity)
		end
	end)

	-- หมุน + ลอยเบา ๆ (เฉพาะฝั่งเซิร์ฟเวอร์แบบเบา ๆ) / gentle spin + bob
	local start = os.clock()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not part.Parent then connection:Disconnect() return end
		local t = os.clock() - start
		part.CFrame = CFrame.new(position + Vector3.new(0, math.sin(t * 2) * 0.25, 0)) * CFrame.Angles(0, t * 1.5, 0)
	end)

	part.Parent = dropsFolder
	task.delay(DESPAWN_SECONDS, function()
		if part.Parent and not picked then
			part:Destroy()
			if dropCount[player] then dropCount[player] = math.max(0, dropCount[player] - 1) end
		end
	end)
end

dropRemote.OnServerEvent:Connect(function(player, itemId, requestedEnhancement, requestedQuantity)
	if type(itemId) ~= "string" then return end
	local item = ItemData[itemId]
	if not item then return end
	local now = os.clock()
	if now - (lastDrop[player] or 0) < DROP_COOLDOWN then return end
	if (dropCount[player] or 0) >= MAX_DROPS_PER_PLAYER then
		remotesApi.SkillFeedback:FireClient(player, "ทิ้งของบนพื้นมากเกินไป เก็บบางส่วนก่อน")
		return
	end
	local enhancement = math.clamp(math.floor(tonumber(requestedEnhancement) or 0), 0, 15)
	local quantity = math.clamp(math.floor(tonumber(requestedQuantity) or 1), 1, 9999)

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local data = dataApi.GetPlayerData(player)
	if not root or not data then return end

	local foundIndex
	for index, entry in ipairs(data.Inventory or {}) do
		if entry.itemId == itemId and (tonumber(entry.enhancement) or 0) == enhancement and (tonumber(entry.quantity) or 0) > 0 then
			foundIndex = index
			break
		end
	end
	if not foundIndex then return end
	local entry = data.Inventory[foundIndex]
	quantity = math.min(quantity, entry.quantity)
	entry.quantity -= quantity
	if entry.quantity <= 0 then table.remove(data.Inventory, foundIndex) end

	lastDrop[player] = now
	dropCount[player] = (dropCount[player] or 0) + 1
	spawnWorldItem(player, itemId, enhancement, quantity, groundPositionAt(root))
	pushInventory(player, data, string.format("ทิ้ง %s x%d", item.name, quantity))
end)

Players.PlayerRemoving:Connect(function(player)
	lastDrop[player] = nil
	dropCount[player] = nil
end)

print("[ItemDropSystem] พร้อมใช้งาน / ready")
