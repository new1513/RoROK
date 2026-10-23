-- Standalone crafting window keeps the main HUD script below Luau's local limit.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local openCrafting = remotes:WaitForChild("OpenCrafting")
local craftItem = remotes:WaitForChild("CraftItem")
local feedback = remotes:WaitForChild("CraftingFeedback")
local gui = Instance.new("ScreenGui")
gui.Name = "CraftingUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 31
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "CraftingPanel"
panel.Size = UDim2.fromOffset(470, 330)
panel.Position = UDim2.new(0.5, -235, 0.5, -165)
panel.BackgroundColor3 = Color3.fromRGB(20, 21, 36)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(255, 211, 79)
stroke.Thickness = 2

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -58, 0, 38)
title.Position = UDim2.fromOffset(14, 8)
title.BackgroundTransparency = 1
title.Text = "🔨 ช่างทำอุปกรณ์"
title.TextColor3 = Color3.fromRGB(255, 224, 130)
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(32, 30)
close.Position = UDim2.new(1, -42, 0, 8)
close.BackgroundColor3 = Color3.fromRGB(132, 45, 55)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBold
close.TextSize = 13
close.Parent = panel
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
close.Activated:Connect(function() panel.Visible = false end)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -28, 0, 28)
status.Position = UDim2.fromOffset(14, 48)
status.BackgroundTransparency = 1
status.Text = "ใช้วัตถุดิบจากมอนสเตอร์เพื่อทำอุปกรณ์"
status.TextColor3 = Color3.fromRGB(206, 208, 225)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = panel

local function addRecipe(order, name, detail, outputId)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -28, 0, 102)
	row.Position = UDim2.fromOffset(14, 82 + (order - 1) * 110)
	row.BackgroundColor3 = Color3.fromRGB(38, 38, 61)
	row.BorderSizePixel = 0
	row.Parent = panel
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -126, 1, -8)
	label.Position = UDim2.fromOffset(10, 4)
	label.BackgroundTransparency = 1
	label.Text = name .. "\n" .. detail
	label.TextColor3 = Color3.fromRGB(239, 239, 248)
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = true
	label.Parent = row
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(98, 38)
	button.Position = UDim2.new(1, -108, 0.5, -19)
	button.BackgroundColor3 = Color3.fromRGB(49, 90, 74)
	button.Text = "คราฟต์"
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 12
	button.Parent = row
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
	button.Activated:Connect(function() craftItem:FireServer(outputId) end)
end

addRecipe(1, "Poring Hood", "Jellopy x10 • Sticky Mucus x5 • 20 z\nโบนัสเมื่อสวม: DEF +3, MaxHP +10", "PoringHood")
addRecipe(2, "Four-Leaf Apprentice Rod", "Jellopy x8 • Four-Leaf Clover x2 • 50 z\nโบนัสเมื่อสวม: MATK +5", "CloverRod")

openCrafting.OnClientEvent:Connect(function()
	status.Text = "ใช้วัตถุดิบจากมอนสเตอร์เพื่อทำอุปกรณ์"
	panel.Visible = true
end)
feedback.OnClientEvent:Connect(function(message)
	status.Text = tostring(message)
end)
