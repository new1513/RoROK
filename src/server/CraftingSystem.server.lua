-- Starter crafting service: recipes consume monster materials and Zeny on the server.
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
	local existing = remotes:FindFirstChild(name)
	if existing then return existing end
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local openCrafting = getOrCreate("RemoteEvent", "OpenCrafting")
local craftItem = getOrCreate("RemoteEvent", "CraftItem")
local feedback = getOrCreate("RemoteEvent", "CraftingFeedback")
local updateInventory = remotes:WaitForChild("UpdateInventory")

local recipes = {
	PoringHood = {
		name = ItemData.PoringHood.name, output = "PoringHood", quantity = 1, zeny = 20,
		ingredients = { Jellopy = 10, StickyMucus = 5 },
	},
	CloverRod = {
		name = ItemData.CloverRod.name, output = "CloverRod", quantity = 1, zeny = 50,
		ingredients = { Jellopy = 8, FourLeafClover = 2 },
	},
}

local function getCraftingNpc()
	local town = Workspace:FindFirstChild("RoROK_StarterPlaza")
	return town and town:FindFirstChild("Craftsman")
end

local function isNearCraftingNpc(player)
	local npc = getCraftingNpc()
	local root = npc and npc.PrimaryPart
	local character = player.Character
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and playerRoot ~= nil and (playerRoot.Position - root.Position).Magnitude <= 14
end

local cooldowns = {}
local function hasIngredients(player, requirements)
	for itemId, required in pairs(requirements) do
		local ok, count = dataApi.HasItem(player, itemId, required)
		if not ok then
			return false, itemId, required - (tonumber(count) or 0)
		end
	end
	return true
end

local function consumeIngredients(player, requirements)
	for itemId, required in pairs(requirements) do
		dataApi.RemoveItem(player, itemId, required)
	end
end

openCrafting.OnServerEvent:Connect(function(player)
	if isNearCraftingNpc(player) then openCrafting:FireClient(player) end
end)

craftItem.OnServerEvent:Connect(function(player, outputId)
	if type(outputId) ~= "string" or not recipes[outputId] or not isNearCraftingNpc(player) then return end
	local now = os.clock()
	if now - (cooldowns[player.UserId] or 0) < 0.5 then return end
	cooldowns[player.UserId] = now
	local recipe = recipes[outputId]
	local data = dataApi.GetPlayerData(player)
	if not data then return end
	local hasAll, missingId, missingCount = hasIngredients(player, recipe.ingredients)
	if not hasAll then
		feedback:FireClient(player, string.format("วัตถุดิบไม่พอ: %s ขาด %d", ItemData[missingId] and ItemData[missingId].name or missingId, missingCount))
		return
	end
	if (tonumber(data.Gold) or 0) < recipe.zeny then
		feedback:FireClient(player, string.format("Zeny ไม่พอ (ต้องใช้ %d z)", recipe.zeny))
		return
	end
	if not ItemData[recipe.output] or not dataApi.ModifyGold(player, -recipe.zeny) then return end
	consumeIngredients(player, recipe.ingredients)
	local added, inventory = dataApi.AddItem(player, recipe.output, recipe.quantity)
	if not added then
		-- Recipe output is validated above; refund if the data layer rejects it unexpectedly.
		dataApi.ModifyGold(player, recipe.zeny)
		return
	end
	local message = string.format("คราฟต์ %s สำเร็จ!", recipe.name)
	updateInventory:FireClient(player, inventory, data.Equipment or {}, message, data.EquipmentRefine or {})
	feedback:FireClient(player, message)
end)

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player.UserId] = nil
end)

-- Add a visible craftsman beside the supply stall in the plaza.
local town = Workspace:WaitForChild("RoROK_StarterPlaza")
local previous = town:FindFirstChild("Craftsman")
if previous then previous:Destroy() end
local npc = Instance.new("Model")
npc.Name = "Craftsman"
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

local cx, cy, cz = 32, 2.75, -27.5
local torso = makePart("HumanoidRootPart", Vector3.new(1.5, 1.8, 0.75), Vector3.new(cx, cy, cz), Color3.fromRGB(74, 104, 119))
npc.PrimaryPart = torso
makePart("Apron", Vector3.new(1.55, 0.9, 0.12), Vector3.new(cx, cy - 0.25, cz + 0.42), Color3.fromRGB(98, 71, 46))
makePart("Head", Vector3.new(1.05, 1.05, 1.05), Vector3.new(cx, cy + 1.45, cz), Color3.fromRGB(224, 174, 137), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
makePart("Hair", Vector3.new(1.1, 0.3, 1.1), Vector3.new(cx, cy + 1.9, cz), Color3.fromRGB(75, 54, 42), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
makePart("LegL", Vector3.new(0.55, 1.4, 0.6), Vector3.new(cx - 0.36, 1.15, cz), Color3.fromRGB(64, 58, 54))
makePart("LegR", Vector3.new(0.55, 1.4, 0.6), Vector3.new(cx + 0.36, 1.15, cz), Color3.fromRGB(64, 58, 54))
makePart("Worktable", Vector3.new(3.4, 0.4, 1.5), Vector3.new(cx + 2.6, 1.4, cz + 1.2), Color3.fromRGB(111, 77, 49), Enum.Material.WoodPlanks)

local craftBB = Instance.new("BillboardGui")
craftBB.Size = UDim2.fromOffset(160, 36)
craftBB.StudsOffset = Vector3.new(0, 2.7, 0)
craftBB.MaxDistance = 32
craftBB.AlwaysOnTop = false
craftBB.Parent = torso
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.Text = "ช่างทำอุปกรณ์ Galt\n[F] คราฟต์อุปกรณ์"
label.TextColor3 = Color3.fromRGB(255, 226, 160)
label.TextStrokeTransparency = 0.2
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Parent = craftBB

local promptPoint = Instance.new("Attachment")
promptPoint.Name = "CraftingPromptPoint"
promptPoint.Position = Vector3.new(0, 2, 0.45)
promptPoint.Parent = torso
local prompt = Instance.new("ProximityPrompt")
prompt.Name = "OpenCrafting"
prompt.ActionText = "คราฟต์อุปกรณ์"
prompt.ObjectText = "ช่างทำอุปกรณ์ Galt"
prompt.KeyboardKeyCode = Enum.KeyCode.F
prompt.HoldDuration = 0
prompt.MaxActivationDistance = 12
prompt.RequiresLineOfSight = false
prompt.Parent = promptPoint
prompt.Triggered:Connect(function(player)
	openCrafting:FireClient(player)
end)

print("[CraftingSystem] Prontera crafting service ready")
