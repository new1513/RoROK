-- ============================================================
-- PetAndMountUI.client.lua
-- StarterPlayerScripts — RoROK (Ragnarok Online-inspired MMORPG)
-- แถบควบคุมสัตว์ขี่ (Peco Peco Mount [R]) และเมนูสัตว์เลี้ยง (Pet Drawer)
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local Debris            = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UITheme
local ok, themeMod = pcall(function()
	return require(script.Parent:WaitForChild("UI"):WaitForChild("UITheme"))
end)
if ok and themeMod then
	UITheme = themeMod
else
	UITheme = {
		hex = function(h)
			h = h:gsub("#", "")
			return Color3.fromRGB(tonumber(h:sub(1,2),16) or 255, tonumber(h:sub(3,4),16) or 255, tonumber(h:sub(5,6),16) or 255)
		end,
		makeInstance = function(cls, props, par)
			local inst = Instance.new(cls)
			for k, v in pairs(props or {}) do inst[k] = v end
			if par then inst.Parent = par end
			return inst
		end,
	}
end

local hex = UITheme.hex
local makeInstance = UITheme.makeInstance

local remotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local RE_ToggleMount = remotesFolder and remotesFolder:WaitForChild("ToggleMount", 10)
local RE_SummonPet   = remotesFolder and remotesFolder:WaitForChild("SummonPet", 10)
local RE_DismissPet  = remotesFolder and remotesFolder:WaitForChild("DismissPet", 10)

-- ── MAIN SCREEN GUI ──────────────────────────────────────────
local petMountGui = makeInstance("ScreenGui", {
	Name = "RoROK_PetMountGui",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 14,
}, playerGui)

-- Control Dock (Bottom Left above Chat / Controls)
local dock = makeInstance("Frame", {
	Name = "PetMountDock",
	Size = UDim2.new(0, 150, 0, 72),
	Position = UDim2.new(0, 18, 1, -195),
	BackgroundColor3 = hex("0f172a"),
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
	ZIndex = 25,
}, petMountGui)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, dock)
makeInstance("UIStroke", { Color = hex("e5c158"), Thickness = 1.2 }, dock)

-- Mount Button
local mountBtn = makeInstance("TextButton", {
	Name = "MountBtn",
	Size = UDim2.new(1, -12, 0, 28),
	Position = UDim2.new(0, 6, 0, 6),
	BackgroundColor3 = hex("b45309"),
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 11,
	Text = "🐤 Peco Peco [R]",
	ZIndex = 26,
}, dock)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 5) }, mountBtn)

mountBtn.Activated:Connect(function()
	if RE_ToggleMount then
		RE_ToggleMount:FireServer()
	end
end)

-- Pet Button
local petBtn = makeInstance("TextButton", {
	Name = "PetBtn",
	Size = UDim2.new(1, -12, 0, 28),
	Position = UDim2.new(0, 6, 0, 38),
	BackgroundColor3 = hex("1e293b"),
	TextColor3 = hex("fde047"),
	Font = Enum.Font.GothamBold,
	TextSize = 11,
	Text = "🐾 สัตว์เลี้ยง (Pets)",
	ZIndex = 26,
}, dock)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 5) }, petBtn)

-- Mini Pet Drawer Window
local petDrawer = makeInstance("Frame", {
	Name = "PetDrawer",
	Size = UDim2.new(0, 160, 0, 120),
	Position = UDim2.new(1, 10, 0, -24),
	BackgroundColor3 = hex("0f172a"),
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 30,
}, dock)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, petDrawer)
makeInstance("UIStroke", { Color = hex("38bdf8"), Thickness = 1.4 }, petDrawer)

local poringBtn = makeInstance("TextButton", {
	Size = UDim2.new(1, -12, 0, 30), Position = UDim2.new(0, 6, 0, 8),
	BackgroundColor3 = hex("ec4899"), TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold, TextSize = 11, Text = "🌸 เลี้ยง Poring", ZIndex = 31,
}, petDrawer)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 5) }, poringBtn)

local lunaticBtn = makeInstance("TextButton", {
	Size = UDim2.new(1, -12, 0, 30), Position = UDim2.new(0, 6, 0, 44),
	BackgroundColor3 = hex("8b5cf6"), TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold, TextSize = 11, Text = "🐰 เลี้ยง Lunatic", ZIndex = 31,
}, petDrawer)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 5) }, lunaticBtn)

local dismissBtn = makeInstance("TextButton", {
	Size = UDim2.new(1, -12, 0, 28), Position = UDim2.new(0, 6, 0, 80),
	BackgroundColor3 = hex("334155"), TextColor3 = hex("cbd5e1"),
	Font = Enum.Font.Gotham, TextSize = 10, Text = "✕ เก็บสัตว์เลี้ยง", ZIndex = 31,
}, petDrawer)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 5) }, dismissBtn)

petBtn.Activated:Connect(function()
	petDrawer.Visible = not petDrawer.Visible
end)

poringBtn.Activated:Connect(function()
	petDrawer.Visible = false
	if RE_SummonPet then RE_SummonPet:FireServer("Poring") end
end)

lunaticBtn.Activated:Connect(function()
	petDrawer.Visible = false
	if RE_SummonPet then RE_SummonPet:FireServer("Lunatic") end
end)

dismissBtn.Activated:Connect(function()
	petDrawer.Visible = false
	if RE_DismissPet then RE_DismissPet:FireServer() end
end)

-- Keybind 'R' toggles mount
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.R then
		if RE_ToggleMount then
			RE_ToggleMount:FireServer()
		end
	end
end)

print("[PetAndMountUI] Pet and Mount Client UI initialized successfully")
