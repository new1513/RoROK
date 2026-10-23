-- ============================================================
-- JobAdvancementUI.client.lua
-- StarterPlayerScripts — RoROK (Ragnarok Online-inspired MMORPG)
-- หน้าต่างพิธีเลื่อนขั้นสู่อาชีพระดับสูง (2nd Job Promotion Modal)
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Debris            = game:GetService("Debris")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

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
local RE_OpenJobAdvance    = remotesFolder and remotesFolder:WaitForChild("OpenJobAdvanceDialogue", 10)
local RE_RequestJobAdvance = remotesFolder and remotesFolder:WaitForChild("RequestJobAdvance", 10)

-- ── MAIN SCREEN GUI ──────────────────────────────────────────
local advanceGui = makeInstance("ScreenGui", {
	Name = "RoROK_JobAdvancement",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 17,
}, playerGui)

-- Modal Window
local win = makeInstance("Frame", {
	Name = "JobAdvanceWindow",
	Size = UDim2.new(0, 520, 0, 390),
	Position = UDim2.new(0.5, -260, 0.5, -195),
	BackgroundColor3 = hex("0b0f19"),
	BackgroundTransparency = 0.05,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 40,
}, advanceGui)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 14) }, win)
makeInstance("UIStroke", { Color = hex("e5c158"), Thickness = 1.8 }, win)

-- Title Bar
local titleBar = makeInstance("Frame", {
	Name = "TitleBar",
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundColor3 = hex("172033"),
	BorderSizePixel = 0,
	ZIndex = 41,
}, win)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 14) }, titleBar)

local titleLabel = makeInstance("TextLabel", {
	Size = UDim2.new(1, -60, 1, 0),
	Position = UDim2.new(0, 16, 0, 0),
	BackgroundTransparency = 1,
	Text = "🌟 วิหารแห่งการเลื่อนขั้นอาชีพ • 2ND JOB ADVANCEMENT",
	TextColor3 = hex("ffd700"),
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 42,
}, titleBar)

local closeBtn = makeInstance("TextButton", {
	Name = "CloseBtn",
	Size = UDim2.new(0, 28, 0, 28),
	Position = UDim2.new(1, -36, 0, 8),
	BackgroundColor3 = hex("ef4444"),
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	Text = "✕",
	ZIndex = 43,
}, titleBar)
makeInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, closeBtn)
closeBtn.Activated:Connect(function() win.Visible = false end)

-- Content Frame
local content = makeInstance("Frame", {
	Name = "Content",
	Size = UDim2.new(1, -32, 1, -64),
	Position = UDim2.new(0, 16, 0, 52),
	BackgroundTransparency = 1,
	ZIndex = 41,
}, win)

local subtitle = makeInstance("TextLabel", {
	Name = "Subtitle",
	Size = UDim2.new(1, 0, 0, 24),
	BackgroundTransparency = 1,
	Text = "พิธีศักดิ์สิทธิ์ปลดล็อกขีดจำกัดพลังขั้นสูงสุดแห่งนักรบ",
	TextColor3 = hex("94a3b8"),
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 42,
}, content)

-- Class Preview Card
local classCard = makeInstance("Frame", {
	Name = "ClassCard",
	Size = UDim2.new(1, 0, 0, 160),
	Position = UDim2.new(0, 0, 0, 28),
	BackgroundColor3 = hex("131c2e"),
	BorderSizePixel = 0,
	ZIndex = 42,
}, content)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 10) }, classCard)
makeInstance("UIStroke", { Color = hex("3b82f6"), Thickness = 1.2 }, classCard)

local targetClassName = makeInstance("TextLabel", {
	Name = "TargetClassName",
	Size = UDim2.new(1, -20, 0, 30),
	Position = UDim2.new(0, 14, 0, 10),
	BackgroundTransparency = 1,
	Text = "🌟 ลอร์ดไนท์ (Lord Knight)",
	TextColor3 = hex("fde047"),
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 43,
}, classCard)

local targetDesc = makeInstance("TextLabel", {
	Name = "TargetDesc",
	Size = UDim2.new(1, -28, 0, 48),
	Position = UDim2.new(0, 14, 0, 42),
	BackgroundTransparency = 1,
	Text = "คำอธิบายอาชีพ",
	TextColor3 = hex("cbd5e1"),
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	ZIndex = 43,
}, classCard)

local perksLabel = makeInstance("TextLabel", {
	Name = "PerksLabel",
	Size = UDim2.new(1, -28, 0, 56),
	Position = UDim2.new(0, 14, 0, 96),
	BackgroundTransparency = 1,
	Text = "🎁 สิทธิประโยชน์เมื่อเลื่อนขั้น:\n • ปลดล็อก 4 มหาสกิลประจำสายอาชีพขั้นที่ 2 ในผังสกิล\n • รับอาวุธระดับสูงประจำอาชีพทันที พร้อมโบนัส +15 Stat Points ฟรี!",
	TextColor3 = hex("86efac"),
	Font = Enum.Font.GothamSemibold,
	TextSize = 11,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 43,
}, classCard)

-- Message Label (when low job level or not eligible)
local msgLabel = makeInstance("TextLabel", {
	Name = "MsgLabel",
	Size = UDim2.new(1, 0, 0, 60),
	Position = UDim2.new(0, 0, 0, 200),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = hex("f87171"),
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextWrapped = true,
	Visible = false,
	ZIndex = 42,
}, content)

-- Action Button
local confirmBtn = makeInstance("TextButton", {
	Name = "ConfirmBtn",
	Size = UDim2.new(1, 0, 0, 44),
	Position = UDim2.new(0, 0, 1, -50),
	BackgroundColor3 = hex("b45309"),
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	Text = "🌟 ยืนยันการเลื่อนขั้นอาชีพระดับสูง!",
	ZIndex = 44,
}, content)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, confirmBtn)
local confirmStroke = makeInstance("UIStroke", { Color = hex("fde047"), Thickness = 1.4 }, confirmBtn)

local selectedAdvanceClass = nil

confirmBtn.Activated:Connect(function()
	if selectedAdvanceClass and RE_RequestJobAdvance then
		win.Visible = false
		RE_RequestJobAdvance:FireServer(selectedAdvanceClass)
		
		-- Play celebratory chime
		pcall(function()
			local sfx = Instance.new("Sound")
			sfx.SoundId = "rbxasset://sounds/electronicpingshort.wav"
			sfx.Volume = 0.8
			sfx.Parent = playerGui
			sfx:Play()
			Debris:AddItem(sfx, 3)
		end)
	end
end)

-- ── REMOTE LISTENER ──────────────────────────────────────────
if RE_OpenJobAdvance then
	RE_OpenJobAdvance.OnClientEvent:Connect(function(payload)
		selectedAdvanceClass = payload.targetClass

		if payload.state == "IsNovice" then
			classCard.Visible = false
			msgLabel.Visible = true
			msgLabel.Text = "เจ้ายังเป็น Novice ผู้เดินทางใหม่!\nจงฝึกฝนตนจนถึง Job Level 10 แล้วเลือกอาชีพขั้นต้นก่อนนะ"
			confirmBtn.Visible = false
		elseif payload.state == "AlreadyMaxJob" then
			classCard.Visible = false
			msgLabel.Visible = true
			msgLabel.TextColor3 = hex("38bdf8")
			msgLabel.Text = string.format("ยินดีด้วย! คุณได้บรรลุจุดสูงสุดแห่งอาชีพระดับสูง %s เรียบร้อยแล้ว!\nจงนำพลังอันยิ่งใหญ่นี้ไปปกป้องดินแดน RoROK ต่อไป", payload.currentThai or payload.currentClass)
			confirmBtn.Visible = false
		elseif payload.state == "JobLevelLow" then
			classCard.Visible = true
			targetClassName.Text = string.format("🔒 อาชีพถัดไป: %s", payload.targetThai or payload.targetClass)
			targetDesc.Text = payload.targetDesc or ""
			msgLabel.Visible = true
			msgLabel.TextColor3 = hex("fbbf24")
			msgLabel.Text = string.format("⚠️ เงื่อนไขยังไม่ครบ: ต้องการ Job Level 40 ขึ้นไป\n(ปัจจุบันของคุณ: Job Lv. %d/40) — ทำเควสเนื้อเรื่อง Chapter 1-6 เพื่อรับ Job EXP มหาศาล!", payload.jobLevel or 1)
			confirmBtn.Visible = false
		elseif payload.state == "Eligible" then
			classCard.Visible = true
			msgLabel.Visible = false
			targetClassName.Text = string.format("🌟 เลื่อนขั้นสู่: %s", payload.targetThai or payload.targetClass)
			targetDesc.Text = payload.targetDesc or ""
			confirmBtn.Visible = true
			confirmBtn.Text = string.format("🌟 ประกอบพิธีเลื่อนขั้นสู่ %s!", payload.targetThai or payload.targetClass)
		end

		win.Visible = true
	end)
end

print("[JobAdvancementUI] 2nd Job Advancement UI initialized successfully")
