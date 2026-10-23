-- ============================================================
-- RagnarokPanels.client.lua
-- หน้าต่าง "สเตตัส" และ "ผังสกิล" สไตล์ Ragnarok M
--  • Stats: เรดาร์ 6 เหลี่ยม + ค่าสถานะรอง + ปุ่ม -/+ แบบจองแต้ม แล้วกด "ยืนยัน"
--  • Skill Tree: โหนดสกิลเรียงเป็นผัง มีเส้นเชื่อมสกิลก่อนหน้า, Lv x/max,
--    แผงรายละเอียด, ปุ่มอัปสกิล และแถบช่องสกิล 1-8 สำหรับวางสกิล
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GameData = ReplicatedStorage:WaitForChild("GameData")
local SkillData = require(GameData:WaitForChild("SkillData"))
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateCharacterData = Remotes:WaitForChild("UpdateCharacterData")
local DistributeStatPoint = Remotes:WaitForChild("DistributeStatPoint")
local LearnSkill = Remotes:WaitForChild("LearnSkill")
local ChangeClass = Remotes:WaitForChild("ChangeClass")
local StudioGrantJobXP = Remotes:WaitForChild("StudioGrantJobXP", 5)
local StudioResetToNovice = Remotes:WaitForChild("StudioResetToNovice", 5)

local function isTestAllowed()
	return RunService:IsStudio() or player:GetAttribute("IsAdmin") == true
end

local STATS = { "STR", "AGI", "VIT", "INT", "DEX", "LUK" }
local STAT_COLOR = {
	STR = Color3.fromRGB(255, 110, 100), AGI = Color3.fromRGB(110, 230, 140),
	VIT = Color3.fromRGB(255, 180, 90), INT = Color3.fromRGB(120, 170, 255),
	DEX = Color3.fromRGB(255, 225, 100), LUK = Color3.fromRGB(255, 140, 210),
}
local STAT_DESC = {
	STR = "พลังโจมตีกายภาพ • น้ำหนักแบก",
	AGI = "ความเร็วโจมตี • หลบหลีก (FLEE)",
	VIT = "HP สูงสุด • ป้องกัน • ฟื้นฟู HP",
	INT = "พลังเวท MATK • SP • ป้องกันเวท",
	DEX = "ความแม่นยำ (HIT) • ลดเวลาร่าย",
	LUK = "คริติคอล • หลบสมบูรณ์",
}

local C = {
	Bg = Color3.fromRGB(236, 240, 247), Panel = Color3.fromRGB(250, 251, 254),
	Dark = Color3.fromRGB(28, 36, 56), Header = Color3.fromRGB(46, 104, 196),
	HeaderLight = Color3.fromRGB(86, 150, 236), Text = Color3.fromRGB(40, 48, 66),
	Muted = Color3.fromRGB(120, 130, 150), Blue = Color3.fromRGB(70, 140, 235),
	Green = Color3.fromRGB(60, 190, 110), Red = Color3.fromRGB(220, 70, 60),
	Gold = Color3.fromRGB(245, 190, 70), Line = Color3.fromRGB(205, 212, 226),
}

local data = {
	Class = player:GetAttribute("Class") or "Novice",
	Level = player:GetAttribute("Level") or 1,
	JobLevel = player:GetAttribute("JobLevel") or 1,
	StatPoints = player:GetAttribute("StatPoints") or 0,
	SkillPoints = player:GetAttribute("SkillPoints") or 0,
	Stats = {}, Skills = {},
}
for _, s in ipairs(STATS) do data.Stats[s] = player:GetAttribute(s) or 1 end

-- ── helpers ────────────────────────────────────────────────
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		if string.sub(k, 1, 1) ~= "_" then
			o[k] = v
		end
	end
	if parent then o.Parent = parent end
	return o
end
local function corner(o, r) new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o) return o end
local function stroke(o, col, t) new("UIStroke", { Color = col, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o) return o end
local function label(parent, props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or Enum.Font.GothamBold
	props.TextColor3 = props.TextColor3 or C.Text
	props.TextSize = props.TextSize or 13
	return new("TextLabel", props, parent)
end
local function button(parent, props)
	props.Font = props.Font or Enum.Font.GothamBold
	props.TextSize = props.TextSize or 13
	props.AutoButtonColor = true
	props.BorderSizePixel = 0
	local b = new("TextButton", props, parent)
	corner(b, props._r or 8)
	return b
end
local function line(parent, p1, p2, color, thick, z)
	local d = p2 - p1
	local f = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0,
		BackgroundColor3 = color, Size = UDim2.fromOffset(d.Magnitude, thick or 2),
		Position = UDim2.fromOffset((p1.X + p2.X) / 2, (p1.Y + p2.Y) / 2),
		Rotation = math.deg(math.atan2(d.Y, d.X)), ZIndex = z or 3,
	}, parent)
	return f
end
local function statCost(v) return math.floor(v / 10) + 2 end

local gui = new("ScreenGui", { Name = "RagnarokPanels", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)

local toast = label(gui, {
	Size = UDim2.fromOffset(420, 34), Position = UDim2.new(0.5, -210, 0, 70),
	BackgroundTransparency = 0.15, BackgroundColor3 = C.Dark, TextColor3 = Color3.new(1, 1, 1),
	Text = "", Visible = false, ZIndex = 50,
})
corner(toast, 10)
local function showToast(msg)
	toast.Text = msg
	toast.Visible = true
	local stamp = os.clock()
	toast:SetAttribute("Stamp", stamp)
	task.delay(2.4, function() if toast:GetAttribute("Stamp") == stamp then toast.Visible = false end end)
end

local function makeWindow(name, w, h, title)
	local win = new("Frame", {
		Name = name, Size = UDim2.fromOffset(w, h), Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2),
		BackgroundColor3 = C.Bg, BorderSizePixel = 0, Visible = false, ZIndex = 2,
	}, gui)
	corner(win, 14)
	stroke(win, Color3.fromRGB(150, 175, 215), 2)
	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.Dark, BorderSizePixel = 0, ZIndex = 3 }, win)
	corner(head, 14)
	new("Frame", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14), BackgroundColor3 = C.Dark, BorderSizePixel = 0, ZIndex = 3 }, head)
	local t = label(head, { Size = UDim2.new(1, -120, 1, 0), Position = UDim2.fromOffset(18, 0), Text = title, TextColor3 = Color3.new(1, 1, 1), TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
	local close = button(head, { Size = UDim2.fromOffset(40, 34), Position = UDim2.new(1, -48, 0, 6), Text = "✕", TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Color3.fromRGB(224, 82, 60), TextSize = 18, ZIndex = 5 })
	close.Activated:Connect(function() win.Visible = false end)
	-- drag
	local dragging, startPos, startMouse
	head.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, startPos, startMouse = true, win.Position, i.Position
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startMouse
			win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	return win, t, head
end

local function openAnim(win)
	win.Visible = true
	local s = new("UIScale", { Scale = 0.92 }, win)
	TweenService:Create(s, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(0.2, function() s:Destroy() end)
end

-- ============================================================
-- 1) STATUS WINDOW
-- ============================================================
local charWin, winTitle, winHead = makeWindow("RagnarokCharacterWindow", 840, 530, "⚔️ ข้อมูลตัวละคร & ผังสกิล")
local pending = { STR = 0, AGI = 0, VIT = 0, INT = 0, DEX = 0, LUK = 0 }

-- Tab Buttons in Window Header
local tabBtnStatus = button(winHead, {
	Size = UDim2.fromOffset(130, 32), Position = UDim2.fromOffset(260, 7),
	Text = "📊 สเตตัส (C)", TextColor3 = Color3.new(1, 1, 1),
	BackgroundColor3 = C.Header, TextSize = 13, ZIndex = 5,
})
corner(tabBtnStatus, 8)

local tabBtnSkills = button(winHead, {
	Size = UDim2.fromOffset(130, 32), Position = UDim2.fromOffset(398, 7),
	Text = "✨ ผังสกิล (K)", TextColor3 = Color3.fromRGB(180, 195, 220),
	BackgroundColor3 = Color3.fromRGB(50, 60, 85), TextSize = 13, ZIndex = 5,
})
corner(tabBtnSkills, 8)

-- Tab Pages
local statusPage = new("Frame", {
	Name = "StatusPage",
	Size = UDim2.new(1, 0, 1, -48), Position = UDim2.fromOffset(0, 48),
	BackgroundTransparency = 1, Visible = true, ZIndex = 2,
}, charWin)

local skillsPage = new("Frame", {
	Name = "SkillsPage",
	Size = UDim2.new(1, 0, 1, -48), Position = UDim2.fromOffset(0, 48),
	BackgroundTransparency = 1, Visible = false, ZIndex = 2,
}, charWin)

-- Left: radar + derived
local left = new("Frame", { Size = UDim2.new(0, 330, 1, -16), Position = UDim2.fromOffset(10, 8), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 3 }, statusPage)
corner(left, 12)
local radar = new("Frame", { Size = UDim2.fromOffset(300, 196), Position = UDim2.fromOffset(10, 6), BackgroundTransparency = 1, ZIndex = 3 }, left)
local radarDyn = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 4 }, radar)
local RC = Vector2.new(150, 102)
local RR = 74
local function radarPoint(i, r)
	local a = math.rad(-90 + (i - 1) * 60)
	return RC + Vector2.new(math.cos(a) * r, math.sin(a) * r)
end
for ring = 1, 3 do
	local r = RR * ring / 3
	for i = 1, 6 do line(radar, radarPoint(i, r), radarPoint(i % 6 + 1, r), Color3.fromRGB(160, 185, 225), 1, 3) end
end
for i, s in ipairs(STATS) do
	line(radar, RC, radarPoint(i, RR), Color3.fromRGB(200, 212, 235), 1, 3)
	local p = radarPoint(i, RR + 16)
	label(radar, { Size = UDim2.fromOffset(40, 16), Position = UDim2.fromOffset(p.X - 20, p.Y - 8), Text = s, TextSize = 12, TextColor3 = STAT_COLOR[s], ZIndex = 5 })
end

local derivedFrame = new("Frame", { Size = UDim2.new(1, -20, 0, 196), Position = UDim2.fromOffset(10, 206), BackgroundTransparency = 1, ZIndex = 3 }, left)
new("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 26), CellPadding = UDim2.fromOffset(8, 2), SortOrder = Enum.SortOrder.LayoutOrder }, derivedFrame)
local derivedLabels = {}
for idx, key in ipairs({ "HP", "SP", "ATK", "DEF", "MATK", "MDEF", "HIT", "FLEE", "CRIT", "ASPD", "HP Regen", "SP Regen", "หลบสมบูรณ์", "ระยะโจมตี" }) do
	local cell = new("Frame", { BackgroundTransparency = 1, LayoutOrder = idx, ZIndex = 3 }, derivedFrame)
	new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = C.Line, BorderSizePixel = 0, ZIndex = 3 }, cell)
	label(cell, { Size = UDim2.new(0.55, 0, 1, 0), Text = key, TextSize = 12, TextColor3 = C.Muted, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
	derivedLabels[key] = label(cell, { Size = UDim2.new(0.45, 0, 1, 0), Position = UDim2.fromScale(0.55, 0), Text = "-", TextSize = 13, TextColor3 = C.Blue, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4 })
end

-- Right: header + stat rows
local right = new("Frame", { Size = UDim2.new(1, -360, 1, -16), Position = UDim2.fromOffset(350, 8), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 3 }, statusPage)
corner(right, 12)
local nameLbl = label(right, { Size = UDim2.new(1, -140, 0, 22), Position = UDim2.fromOffset(14, 8), Text = player.DisplayName, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
local classLbl = label(right, { Size = UDim2.new(0, 160, 0, 18), Position = UDim2.fromOffset(14, 30), Text = "Novice", TextSize = 12, TextColor3 = C.Blue, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
local baseLbl = label(right, { Size = UDim2.fromOffset(110, 16), Position = UDim2.fromOffset(170, 10), Text = "Base: Lv1", TextSize = 11, TextColor3 = C.Blue, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
local jobLbl = label(right, { Size = UDim2.fromOffset(110, 16), Position = UDim2.fromOffset(170, 30), Text = "Job: Lv1", TextSize = 11, TextColor3 = C.Blue, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
local function bar(y, col)
	local bg = new("Frame", { Size = UDim2.new(1, -290, 0, 9), Position = UDim2.fromOffset(278, y + 4), BackgroundColor3 = C.Line, BorderSizePixel = 0, ZIndex = 4 }, right)
	corner(bg, 5)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 5 }, bg)
	corner(fill, 5)
	return fill
end
local baseFill = bar(10, Color3.fromRGB(90, 130, 230))
local jobFill = bar(30, C.Gold)

local rowsHolder = new("Frame", { Size = UDim2.new(1, -20, 0, 6 * 44), Position = UDim2.fromOffset(10, 58), BackgroundTransparency = 1, ZIndex = 3 }, right)
local rowRefs = {}
for i, s in ipairs(STATS) do
	local y = (i - 1) * 44
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, y), BackgroundColor3 = Color3.fromRGB(242, 245, 251), BorderSizePixel = 0, ZIndex = 3 }, rowsHolder)
	corner(row, 8)
	label(row, { Size = UDim2.fromOffset(44, 40), Position = UDim2.fromOffset(10, 0), Text = s, TextSize = 15, TextColor3 = STAT_COLOR[s], TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
	local box = new("Frame", { Size = UDim2.fromOffset(110, 28), Position = UDim2.fromOffset(56, 6), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 4 }, row)
	corner(box, 7)
	stroke(box, C.Line, 1)
	local val = label(box, { Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.fromOffset(8, 0), Text = "1", TextSize = 14, TextColor3 = C.Blue, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
	local add = label(box, { Size = UDim2.new(0.5, -8, 1, 0), Position = UDim2.fromScale(0.5, 0), Text = "", TextSize = 14, TextColor3 = C.Green, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 5 })
	local cost = label(row, { Size = UDim2.fromOffset(50, 40), Position = UDim2.fromOffset(172, 0), Text = "▶ 2", TextSize = 13, TextColor3 = C.Muted, ZIndex = 4 })
	local desc = label(row, { Size = UDim2.new(1, -330, 1, 0), Position = UDim2.fromOffset(226, 0), Text = STAT_DESC[s], TextSize = 10, TextColor3 = C.Muted, Font = Enum.Font.Gotham, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
	local minus = button(row, { Size = UDim2.fromOffset(34, 32), Position = UDim2.new(1, -80, 0, 4), Text = "−", TextSize = 20, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Color3.fromRGB(150, 160, 180), ZIndex = 4, _r = 16 })
	local plus = button(row, { Size = UDim2.fromOffset(34, 32), Position = UDim2.new(1, -40, 0, 4), Text = "+", TextSize = 20, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = C.Blue, ZIndex = 4, _r = 16 })
	rowRefs[s] = { val = val, add = add, cost = cost, minus = minus, plus = plus, desc = desc }
end

local pointsLbl = label(right, { Size = UDim2.fromOffset(130, 34), Position = UDim2.new(0, 10, 1, -44), Text = "แต้มคงเหลือ: 0", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
local recommendBtn = button(right, { Size = UDim2.fromOffset(92, 34), Position = UDim2.new(1, -284, 1, -44), Text = "วิธีเพิ่มแต้ม", TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Color3.fromRGB(54, 114, 198), ZIndex = 4 })
local resetBtn = button(right, { Size = UDim2.fromOffset(88, 34), Position = UDim2.new(1, -188, 1, -44), Text = "รีเซ็ต", TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Color3.fromRGB(120, 130, 160), ZIndex = 4 })
local confirmBtn = button(right, { Size = UDim2.fromOffset(92, 34), Position = UDim2.new(1, -96, 1, -44), Text = "ยืนยัน", TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = C.Blue, ZIndex = 4 })

-- Banner เปลี่ยนอาชีพเมื่อ Novice Job Lv >= 10
local classBanner = new("Frame", { Size = UDim2.new(1, -20, 0, 34), Position = UDim2.new(0, 10, 1, -84), BackgroundColor3 = Color3.fromRGB(246, 230, 180), BorderSizePixel = 0, Visible = false, ZIndex = 4 }, right)
corner(classBanner, 8)
stroke(classBanner, C.Gold, 1.2)
label(classBanner, { Size = UDim2.new(1, -100, 1, 0), Position = UDim2.fromOffset(10, 0), Text = "🎉 Job Lv.10 พร้อมเปลี่ยนอาชีพขั้นที่ 1!", TextSize = 11, TextColor3 = Color3.fromRGB(130, 80, 20), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
local chooseClassBtn = button(classBanner, { Size = UDim2.fromOffset(84, 26), Position = UDim2.new(1, -90, 0.5, -13), Text = "เลือกอาชีพ", TextSize = 11, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Color3.fromRGB(205, 120, 30), ZIndex = 5 })

-- =========================================================================
-- [TEST ONLY / ADMIN ONLY - REMOVE BEFORE OPEN BETA OR RESTRICT PERMISSION TO ADMIN]
-- [เฉพาะช่วงทดสอบ / สำหรับ Admin - ลบโค้ดบล็อกนี้ออก หรือจำกัดสิทธิ์เฉพาะแอดมินก่อนเปิด Open Beta]
-- ส่วนควบคุมปุ่มทดสอบสำหรับเร่งเลเวลเปลี่ยนอาชีพ (Class Advancement Test)
--
-- คำแนะนำสำคัญก่อนเปิด Open Beta:
-- 1. ลบ testJobBanner, testJobBtn, testResetNoviceBtn ออกจากสคริปต์นี้ หรือ
-- 2. ให้แสดงเฉพาะผู้เล่นที่มี Attribute: player:GetAttribute("IsAdmin") == true
-- =========================================================================
local testJobBanner = new("Frame", {
	Size = UDim2.new(1, -20, 0, 34),
	Position = UDim2.new(0, 10, 1, -84),
	BackgroundColor3 = Color3.fromRGB(232, 245, 255),
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 4,
}, right)
corner(testJobBanner, 8)
stroke(testJobBanner, Color3.fromRGB(65, 140, 235), 1.2)

label(testJobBanner, {
	Size = UDim2.new(1, -150, 1, 0),
	Position = UDim2.fromOffset(10, 0),
	Text = "⚡ [โหมดทดสอบ] เร่งเป็น Job Lv.10 เพื่อทดสอบเปลี่ยนอาชีพ",
	TextSize = 11,
	TextColor3 = Color3.fromRGB(25, 75, 155),
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 5,
})

local testJobBtn = button(testJobBanner, {
	Size = UDim2.fromOffset(140, 26),
	Position = UDim2.new(1, -146, 0.5, -13),
	Text = "⚡ รับ Job Lv.10 ทันที",
	TextSize = 11,
	TextColor3 = Color3.new(1, 1, 1),
	BackgroundColor3 = Color3.fromRGB(46, 120, 220),
	ZIndex = 5,
})

testJobBtn.Activated:Connect(function()
	if StudioGrantJobXP then
		StudioGrantJobXP:FireServer()
		showToast("⚡ ส่งคำขออัป Job Lv.10 สำหรับทดสอบเปลี่ยนอาชีพแล้ว...")
	end
end)

-- ปุ่มทดสอบ: รีเซ็ตกลับเป็น Novice เมื่อต้องการทดสอบเปลี่ยนเป็นอาชีพอื่นซ้ำ
local testResetNoviceBtn = button(right, {
	Size = UDim2.fromOffset(116, 22),
	Position = UDim2.new(1, -126, 0, 8),
	Text = "⚡ รีเซ็ตเป็น Novice",
	TextSize = 10,
	TextColor3 = Color3.new(1, 1, 1),
	BackgroundColor3 = Color3.fromRGB(180, 80, 70),
	Visible = false,
	ZIndex = 6,
})
corner(testResetNoviceBtn, 6)
testResetNoviceBtn.Activated:Connect(function()
	if StudioResetToNovice then
		StudioResetToNovice:FireServer()
		showToast("⚡ รีเซ็ตกลับเป็น Novice เพื่อทดสอบเปลี่ยนอาชีพใหม่...")
	end
end)


-- Class Selection Modal
local classModal = new("Frame", { Size = UDim2.fromOffset(360, 220), Position = UDim2.new(0.5, -180, 0.5, -110), BackgroundColor3 = C.Dark, BorderSizePixel = 0, Visible = false, ZIndex = 20 }, statusPage)
corner(classModal, 12)
stroke(classModal, C.Gold, 1.8)
label(classModal, { Size = UDim2.new(1, 0, 0, 32), Position = UDim2.fromOffset(0, 8), Text = "เลือกอาชีพขั้นที่ 1 (First Class)", TextSize = 14, TextColor3 = C.Gold, ZIndex = 21 })
local classGrid = new("Frame", { Size = UDim2.new(1, -20, 0, 120), Position = UDim2.fromOffset(10, 44), BackgroundTransparency = 1, ZIndex = 21 }, classModal)
new("UIGridLayout", { CellSize = UDim2.new(0.33, -6, 0, 48), CellPadding = UDim2.fromOffset(6, 8) }, classGrid)

local classList = {
    { id = "Knight", name = "⚔️ Knight", desc = "นักรบดาบ/หอก" },
    { id = "Mage", name = "🔮 Mage", desc = "นักเวทมนตร์" },
    { id = "Archer", name = "🏹 Archer", desc = "นักธนู" },
    { id = "Acolyte", name = "🙏 Acolyte", desc = "นักบวช/ฮีล" },
    { id = "Thief", name = "🗡️ Thief", desc = "โจร/ลอบโจมตี" },
    { id = "Merchant", name = "💰 Merchant", desc = "พ่อค้า/ทุบทอง" },
}
for _, cDef in ipairs(classList) do
    local b = button(classGrid, { Text = cDef.name .. "\n" .. cDef.desc, TextSize = 10, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Color3.fromRGB(48, 62, 92), ZIndex = 22 })
    b.Activated:Connect(function()
        ChangeClass:FireServer(cDef.id)
        classModal.Visible = false
        showToast("เปลี่ยนอาชีพเป็น " .. cDef.id .. " เรียบร้อยแล้ว!")
    end)
end
local closeClassModal = button(classModal, { Size = UDim2.fromOffset(80, 28), Position = UDim2.new(0.5, -40, 1, -36), Text = "ยกเลิก", TextSize = 11, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Color3.fromRGB(100, 110, 130), ZIndex = 22 })
closeClassModal.Activated:Connect(function() classModal.Visible = false end)
chooseClassBtn.Activated:Connect(function() classModal.Visible = not classModal.Visible end)

local function pendingTotals()
	-- คำนวณแต้มที่จองไว้ตามสูตรต้นทุนที่เพิ่มขึ้นทุกขั้น
	local spent = 0
	for _, s in ipairs(STATS) do
		local base = data.Stats[s] or 1
		for k = 0, pending[s] - 1 do spent += statCost(base + k) end
	end
	return spent, (data.StatPoints or 0) - spent
end

local function drawRadar()
	radarDyn:ClearAllChildren()
	local maxV = 10
	for _, s in ipairs(STATS) do maxV = math.max(maxV, (data.Stats[s] or 1) + pending[s]) end
	maxV = math.ceil(maxV / 10) * 10
	local pts = {}
	for i, s in ipairs(STATS) do
		local v = (data.Stats[s] or 1) + pending[s]
		pts[i] = radarPoint(i, math.max(4, RR * v / maxV))
	end
	for i = 1, 6 do
		line(radarDyn, pts[i], pts[i % 6 + 1], Color3.fromRGB(230, 70, 70), 3, 6)
		line(radarDyn, RC, pts[i], Color3.fromRGB(240, 120, 120), 2, 5)
		local dot = new("Frame", { Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(pts[i].X, pts[i].Y), BackgroundColor3 = Color3.fromRGB(230, 60, 60), BorderSizePixel = 0, ZIndex = 7 }, radarDyn)
		corner(dot, 4)
	end
end

local function refreshStats()
	local _, remaining = pendingTotals()
	classLbl.Text = string.format("%s  •  Lv.%d", data.Class or "Novice", data.Level or 1)
	baseLbl.Text = string.format("Base: Lv%d", data.Level or 1)
	jobLbl.Text = string.format("Job: Lv%d", data.JobLevel or 1)
	baseFill.Size = UDim2.fromScale(math.clamp((data.XP or 0) / math.max(data.XP_NextLevel or 1, 1), 0, 1), 1)
	jobFill.Size = UDim2.fromScale(math.clamp((data.JobXP or 0) / math.max(data.JobXP_NextLevel or 1, 1), 0, 1), 1)
	pointsLbl.Text = "แต้มคงเหลือ: " .. tostring(remaining)
	for _, s in ipairs(STATS) do
		local r = rowRefs[s]
		local cur = (data.Stats[s] or 1) + pending[s]
		local c = statCost(cur)
		r.val.Text = tostring(data.Stats[s] or 1)
		r.add.Text = pending[s] > 0 and ("+" .. pending[s]) or ""
		r.cost.Text = "▶ " .. c
		r.cost.TextColor3 = remaining >= c and C.Muted or C.Red
		r.plus.BackgroundColor3 = (remaining >= c and cur < 99) and C.Blue or Color3.fromRGB(180, 188, 205)
		r.minus.BackgroundColor3 = pending[s] > 0 and Color3.fromRGB(110, 120, 150) or Color3.fromRGB(200, 205, 215)
	end
	local anyPending = false
	for _, s in ipairs(STATS) do if pending[s] > 0 then anyPending = true end end
	confirmBtn.BackgroundColor3 = anyPending and C.Green or Color3.fromRGB(170, 180, 200)
	local matkTxt = string.format("%d~%d", data.MATK_min or 0, data.MATK_max or 0)
	local vals = {
		["HP"] = string.format("%d/%d", data.HP or 0, data.MaxHP or 0),
		["SP"] = string.format("%d/%d", data.SP or 0, data.MaxSP or 0),
		["ATK"] = data.ATK or 0, ["DEF"] = data.DEF or 0, ["MATK"] = matkTxt, ["MDEF"] = data.MDEF or 0,
		["HIT"] = data.HIT or 0, ["FLEE"] = data.FLEE or 0, ["CRIT"] = data.CritRate or 0,
		["ASPD"] = data.ASPD or 0, ["HP Regen"] = data.HPRegen or 0, ["SP Regen"] = data.SPRegen or 0,
		["หลบสมบูรณ์"] = data.PerfectDodge or 0, ["ระยะโจมตี"] = data.AttackRange or 0,
	}
	for k, lbl in pairs(derivedLabels) do lbl.Text = tostring(vals[k] or "-") end
	drawRadar()
		local isTester = isTestAllowed()
	local canAdvance = (data.Class == "Novice") and ((data.JobLevel or 1) >= 10)
	local canTestAdvance = isTester and (data.Class == "Novice") and ((data.JobLevel or 1) < 10)

	classBanner.Visible = canAdvance
	testJobBanner.Visible = canTestAdvance
	testResetNoviceBtn.Visible = isTester and (data.Class ~= "Novice")

	if canAdvance or canTestAdvance then
		rowsHolder.Size = UDim2.new(1, -20, 0, 6 * 38)
	else
		rowsHolder.Size = UDim2.new(1, -20, 0, 6 * 44)
	end
end

for _, s in ipairs(STATS) do
	local r = rowRefs[s]
	r.plus.Activated:Connect(function()
		local _, remaining = pendingTotals()
		local c = statCost((data.Stats[s] or 1) + pending[s])
		if remaining >= c and (data.Stats[s] or 1) + pending[s] < 99 then
			pending[s] += 1
			refreshStats()
		else
			showToast("แต้มสเตตัสไม่พอ (ต้องใช้ " .. c .. " แต้ม)")
		end
	end)
	r.minus.Activated:Connect(function()
		if pending[s] > 0 then pending[s] -= 1 refreshStats() end
	end)
end
recommendBtn.Activated:Connect(function()
	local cls = data.Class or "Novice"
	local priority
	if cls == "Mage" or cls == "Wizard" then
		priority = { { "INT", 3 }, { "DEX", 1 } }
	elseif cls == "Knight" or cls == "LordKnight" then
		priority = { { "STR", 2 }, { "VIT", 2 } }
	elseif cls == "Archer" or cls == "Hunter" then
		priority = { { "DEX", 3 }, { "AGI", 2 } }
	elseif cls == "Thief" or cls == "Assassin" then
		priority = { { "AGI", 2 }, { "STR", 1 }, { "LUK", 1 } }
	elseif cls == "Acolyte" or cls == "Priest" then
		priority = { { "INT", 2 }, { "VIT", 2 } }
	elseif cls == "Merchant" or cls == "Blacksmith" then
		priority = { { "STR", 2 }, { "DEX", 1 }, { "LUK", 1 } }
	else
		priority = { { "STR", 1 }, { "AGI", 1 }, { "VIT", 1 }, { "DEX", 1 } }
	end
	for _, s in ipairs(STATS) do pending[s] = 0 end
	local changed = true
	local loopGuard = 0
	while changed and loopGuard < 300 do
		loopGuard += 1
		changed = false
		for _, pair in ipairs(priority) do
			local stat, weight = pair[1], pair[2]
			for w = 1, weight do
				local _, rem = pendingTotals()
				local cur = (data.Stats[stat] or 1) + pending[stat]
				local c = statCost(cur)
				if rem >= c and cur < 99 then
					pending[stat] += 1
					changed = true
				else
					break
				end
			end
		end
	end
	refreshStats()
	showToast("จัดแต้มแนะนำสาย " .. cls .. " ให้เรียบร้อย • กดยืนยันเพื่อบันทึก")
end)

confirmBtn.Activated:Connect(function()
	local send, any = {}, false
	for _, s in ipairs(STATS) do if pending[s] > 0 then send[s] = pending[s] any = true end end
	if not any then showToast("กด + เพื่อจองแต้มก่อน แล้วกดยืนยัน") return end
	DistributeStatPoint:FireServer(send)
	for _, s in ipairs(STATS) do pending[s] = 0 end
end)
resetBtn.Activated:Connect(function()
	local anyPending = false
	for _, s in ipairs(STATS) do if pending[s] > 0 then anyPending = true end pending[s] = 0 end
	if anyPending then refreshStats() return end
	DistributeStatPoint:FireServer("ResetStats")
end)

-- ============================================================
-- 2) SKILL TREE WINDOW
-- ============================================================
local spLbl = label(skillsPage, { Size = UDim2.fromOffset(220, 20), Position = UDim2.fromOffset(16, 12), Text = "แต้มสกิลที่เหลือ: 0", TextColor3 = Color3.fromRGB(150, 255, 170), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
local tabJob = button(skillsPage, { Size = UDim2.fromOffset(116, 28), Position = UDim2.new(1, -250, 0, 8), Text = "สกิลอาชีพ", TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = C.Header, TextSize = 12, ZIndex = 5 })
local tabNov = button(skillsPage, { Size = UDim2.fromOffset(116, 28), Position = UDim2.new(1, -126, 0, 8), Text = "สกิลผจญภัย", TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Color3.fromRGB(70, 80, 105), TextSize = 12, ZIndex = 5 })
local currentTab = "Job"

local treeArea = new("Frame", { Size = UDim2.new(0, 530, 1, -142), Position = UDim2.fromOffset(10, 42), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 3 }, skillsPage)
corner(treeArea, 12)
local detail = new("Frame", { Size = UDim2.new(1, -560, 1, -142), Position = UDim2.fromOffset(550, 42), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 3 }, skillsPage)
corner(detail, 12)
local dIcon = label(detail, { Size = UDim2.fromOffset(56, 56), Position = UDim2.fromOffset(12, 12), Text = "", TextSize = 30, BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(225, 232, 245), ZIndex = 4 })
corner(dIcon, 10)
local dName = label(detail, { Size = UDim2.new(1, -84, 0, 22), Position = UDim2.fromOffset(76, 12), Text = "เลือกสกิล", TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 4 })
local dLv = label(detail, { Size = UDim2.new(1, -84, 0, 18), Position = UDim2.fromOffset(76, 38), Text = "", TextSize = 12, TextColor3 = C.Blue, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
local dDesc = label(detail, { Size = UDim2.new(1, -24, 0, 110), Position = UDim2.fromOffset(12, 76), Text = "คลิกที่ไอคอนสกิลในผังด้านซ้ายเพื่อดูรายละเอียด อัปสกิล และวางลงช่องสกิล", TextSize = 12, Font = Enum.Font.Gotham, TextColor3 = C.Text, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 4 })
local dMeta = label(detail, { Size = UDim2.new(1, -24, 0, 40), Position = UDim2.fromOffset(12, 190), Text = "", TextSize = 11, Font = Enum.Font.GothamMedium, TextColor3 = C.Muted, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 4 })
local upBtn = button(detail, { Size = UDim2.new(1, -24, 0, 38), Position = UDim2.new(0, 12, 1, -48), Text = "+ อัปสกิล", TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = C.Green, TextSize = 15, ZIndex = 4, Visible = false })

local barArea = new("Frame", { Size = UDim2.new(1, -20, 0, 84), Position = UDim2.new(0, 10, 1, -92), BackgroundColor3 = C.Dark, BorderSizePixel = 0, ZIndex = 3 }, skillsPage)
corner(barArea, 12)
label(barArea, { Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(12, 4), Text = "ช่องใส่สกิล (กด 1-8) — เลือกสกิลในผัง แล้วคลิกช่องที่ต้องการวาง • คลิกขวาที่ช่องเพื่อเอาออก", TextColor3 = Color3.fromRGB(190, 200, 225), TextSize = 11, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
local barSlots = {}
for i = 1, 8 do
	local b = button(barArea, { Size = UDim2.fromOffset(84, 54), Position = UDim2.fromOffset(12 + (i - 1) * 98, 24), Text = "", BackgroundColor3 = Color3.fromRGB(52, 62, 88), ZIndex = 4 })
	stroke(b, Color3.fromRGB(110, 130, 175), 1)
	label(b, { Size = UDim2.fromOffset(16, 14), Position = UDim2.fromOffset(4, 2), Text = tostring(i), TextColor3 = C.Gold, TextSize = 11, ZIndex = 6 })
	local ic = label(b, { Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 4), Text = "", TextSize = 22, TextColor3 = Color3.new(1, 1, 1), ZIndex = 5 })
	local nm = label(b, { Size = UDim2.new(1, -6, 0, 16), Position = UDim2.new(0, 3, 1, -18), Text = "ว่าง", TextSize = 9, Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(200, 210, 230), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 5 })
	barSlots[i] = { btn = b, icon = ic, name = nm }
end

local selectedSkill = nil
local refreshTree

local function skillLevel(id)
	local lv = tonumber(data.Skills and data.Skills[id]) or 0
	if id == "NoviceStrike" or id == "FirstAid" then lv = math.max(1, lv) end
	return lv
end

local function refreshBar()
	local hot = _G.GetHotbarSkills and _G.GetHotbarSkills() or {}
	for i, s in ipairs(barSlots) do
		local id = hot[i]
		local def = id and SkillData[id]
		s.icon.Text = def and (def.icon or "✦") or ""
		s.name.Text = def and (def.nameThai or def.name) or "ว่าง"
		s.btn.BackgroundColor3 = def and Color3.fromRGB(64, 88, 140) or Color3.fromRGB(52, 62, 88)
	end
end

local function showDetail(id)
	selectedSkill = id
	local def = SkillData[id]
	if not def then return end
	local lv = skillLevel(id)
	local maxLv = def.maxLevel or 10
	dIcon.Text = def.icon or "✦"
	dName.Text = (def.nameThai or def.name)
	dLv.Text = string.format("%s  •  Lv.%d / %d", def.name, lv, maxLv)
	local kind = def.isAttack and (def.aoeRadius and "โจมตีวงกว้าง (AoE)" or "โจมตีเป้าหมายเดียว") or (def.isHeal and "ฟื้นฟู" or "บัฟ/เสริมพลัง")
	dDesc.Text = (def.descThai or "") .. "\n\nประเภท: " .. kind
	local sp = (def.spCost or 0) + math.max(0, lv - 1) * (def.spCostPerLevel or 0)
	dMeta.Text = string.format("💧 SP %d   ⏱ คูลดาวน์ %.1fs%s%s", sp, def.cooldown or 1,
		def.range and ("   🎯 ระยะ " .. def.range) or "", def.goldCost and ("   💰 " .. def.goldCost .. "z") or "")
	local prereqOk = not def.prereq or skillLevel(def.prereq) > 0
	upBtn.Visible = true
	if lv >= maxLv then
		upBtn.Text, upBtn.BackgroundColor3 = "เลเวลสูงสุดแล้ว (MAX)", Color3.fromRGB(150, 160, 180)
	elseif not prereqOk then
		local pd = SkillData[def.prereq]
		upBtn.Text, upBtn.BackgroundColor3 = "ต้องเรียน " .. (pd and (pd.nameThai or pd.name) or def.prereq) .. " ก่อน", Color3.fromRGB(150, 160, 180)
	elseif (data.SkillPoints or 0) <= 0 then
		upBtn.Text, upBtn.BackgroundColor3 = "แต้มสกิลไม่พอ (เก็บ Job Lv เพิ่ม)", Color3.fromRGB(150, 160, 180)
	else
		upBtn.Text, upBtn.BackgroundColor3 = (lv == 0 and "+ เรียนสกิล (ใช้ 1 แต้ม)" or "+ อัปสกิล (ใช้ 1 แต้ม)"), C.Green
	end
end

upBtn.Activated:Connect(function()
	if selectedSkill then LearnSkill:FireServer(selectedSkill) end
end)

for i, s in ipairs(barSlots) do
	s.btn.Activated:Connect(function()
		if not selectedSkill then showToast("เลือกสกิลในผังก่อน แล้วค่อยคลิกช่อง") return end
		local def = SkillData[selectedSkill]
		if def and not def.isAttack and not def.isHeal and not def.isBuff and not def.isDebuff then return end
		if skillLevel(selectedSkill) <= 0 then showToast("ต้องเรียนสกิลนี้ก่อนจึงจะวางลงช่องได้") return end
		if _G.AssignHotbarSkill then _G.AssignHotbarSkill(i, selectedSkill) end
		refreshBar()
		showToast("วาง " .. (def.nameThai or def.name) .. " ในช่อง " .. i)
	end)
	s.btn.MouseButton2Click:Connect(function()
		if _G.AssignHotbarSkill then _G.AssignHotbarSkill(i, nil) end
		refreshBar()
	end)
end

local previewClass = nil
refreshTree = function()
	for _, c in ipairs(treeArea:GetChildren()) do if not c:IsA("UICorner") then c:Destroy() end end
	local myClass = data.Class or "Novice"
	local cls
	if currentTab == "Novice" then
		cls = "Novice"
	else
		cls = (myClass ~= "Novice") and myClass or (previewClass or "Knight")
	end

	winTitle.Text = "✨ ผังสกิลอาชีพและการจัดช่องสกิล (" .. cls .. ")"
	spLbl.Text = "แต้มสกิลที่เหลือ: " .. tostring(data.SkillPoints or 0)

	-- If Novice viewing Job skills, show Job Class Selector chips at top of treeArea
	local topOffset = 16
	if myClass == "Novice" and currentTab == "Job" then
		topOffset = 52
		local chipBar = new("Frame", {
			Size = UDim2.new(1, -20, 0, 32), Position = UDim2.fromOffset(10, 8),
			BackgroundColor3 = Color3.fromRGB(240, 244, 252), BorderSizePixel = 0, ZIndex = 4
		}, treeArea)
		corner(chipBar, 8)
		label(chipBar, {
			Size = UDim2.new(0, 100, 1, 0), Position = UDim2.fromOffset(8, 0),
			Text = "ดูผังสกิลอาชีพ:", TextSize = 11, TextColor3 = C.Dark, Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5
		})
		local chipClasses = { "Knight", "Mage", "Archer", "Acolyte", "Thief", "Merchant" }
		for cIdx, cName in ipairs(chipClasses) do
			local isSel = (cls == cName)
			local chip = button(chipBar, {
				Size = UDim2.fromOffset(64, 24), Position = UDim2.fromOffset(106 + (cIdx - 1) * 68, 4),
				Text = cName, TextSize = 11,
				TextColor3 = isSel and Color3.new(1, 1, 1) or Color3.fromRGB(60, 70, 95),
				BackgroundColor3 = isSel and C.Blue or Color3.fromRGB(220, 226, 238),
				ZIndex = 5
			})
			corner(chip, 6)
			chip.Activated:Connect(function()
				previewClass = cName
				selectedSkill = nil
				refreshTree()
			end)
		end
	end

	local list = SkillData.GetSkillsByClass(cls)
	if #list == 0 then
		label(treeArea, { Size = UDim2.fromScale(1, 1), Text = "ไม่มีข้อมูลสกิลสำหรับ " .. cls, TextColor3 = C.Muted, TextSize = 13, TextWrapped = true, ZIndex = 4 })
		return
	end
	local pos = {}
	local NODE_W, COL_X, ROW_Y = 200, { 22, 280 }, 70
	for _, sk in ipairs(list) do
		local r, c = sk.treeRow or 1, sk.treeCol or 1
		pos[sk.id] = Vector2.new(COL_X[c] or 22, topOffset + (r - 1) * ROW_Y)
	end
	-- prereq connectors
	for _, sk in ipairs(list) do
		if sk.prereq and pos[sk.prereq] then
			local a = pos[sk.prereq] + Vector2.new(NODE_W, 24)
			local b = pos[sk.id] + Vector2.new(0, 24)
			local unlocked = skillLevel(sk.prereq) > 0
			line(treeArea, a, b, unlocked and C.Green or C.Line, 3, 3)
		end
	end
	for _, sk in ipairs(list) do
		local p = pos[sk.id]
		local lv = skillLevel(sk.id)
		local maxLv = sk.maxLevel or 10
		local locked = sk.prereq and skillLevel(sk.prereq) <= 0
		local node = new("TextButton", { Size = UDim2.fromOffset(NODE_W, 48), Position = UDim2.fromOffset(p.X, p.Y), Text = "", AutoButtonColor = true, BorderSizePixel = 0,
			BackgroundColor3 = lv > 0 and Color3.new(1, 1, 1) or Color3.fromRGB(196, 202, 214), ZIndex = 4 }, treeArea)
		corner(node, 24)
		if selectedSkill == sk.id then stroke(node, C.Blue, 2.5) end
		local iconBox = label(node, { Size = UDim2.fromOffset(48, 48), Text = sk.icon or "✦", TextSize = 24, BackgroundTransparency = 0,
			BackgroundColor3 = lv > 0 and Color3.fromRGB(214, 168, 70) or Color3.fromRGB(140, 148, 165), TextColor3 = Color3.new(1, 1, 1), ZIndex = 5 })
		corner(iconBox, 10)
		label(iconBox, { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14), Text = lv .. "/" .. maxLv, TextSize = 10, BackgroundTransparency = 0.35, BackgroundColor3 = Color3.new(0, 0, 0), TextColor3 = Color3.new(1, 1, 1), ZIndex = 6 })
		label(node, { Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(56, 0), Text = (locked and "🔒 " or "") .. (sk.nameThai or sk.name), TextSize = 12, TextWrapped = true,
			TextColor3 = lv > 0 and C.Text or Color3.fromRGB(90, 98, 115), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
		if lv < maxLv and not locked and (data.SkillPoints or 0) > 0 then
			local plus = button(node, { Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -30, 0.5, -13), Text = "+", TextSize = 18, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = C.Green, ZIndex = 6, _r = 13 })
			plus.Activated:Connect(function() selectedSkill = sk.id LearnSkill:FireServer(sk.id) end)
		end
		node.Activated:Connect(function()
			showDetail(sk.id)
			refreshTree()
		end)
	end
	if not selectedSkill or not SkillData[selectedSkill] then
		if #list > 0 then selectedSkill = list[1].id end
	end
	if selectedSkill and SkillData[selectedSkill] then showDetail(selectedSkill) end
	refreshBar()
end

local function setTab(t)
	currentTab = t
	tabJob.BackgroundColor3 = t == "Job" and C.Header or Color3.fromRGB(70, 80, 105)
	tabNov.BackgroundColor3 = t == "Novice" and C.Header or Color3.fromRGB(70, 80, 105)
	refreshTree()
end
tabJob.Activated:Connect(function() setTab("Job") end)
tabNov.Activated:Connect(function() setTab("Novice") end)

-- ============================================================
-- 3) PUBLIC TOGGLES + DATA SYNC
-- ============================================================
local function switchMainTab(target)
	if target == "Stats" then
		statusPage.Visible = true
		skillsPage.Visible = false
		tabBtnStatus.BackgroundColor3 = C.Header
		tabBtnStatus.TextColor3 = Color3.new(1, 1, 1)
		tabBtnSkills.BackgroundColor3 = Color3.fromRGB(50, 60, 85)
		tabBtnSkills.TextColor3 = Color3.fromRGB(180, 195, 220)
		winTitle.Text = "📊 ค่าสถานะและข้อมูลตัวละคร (Character Status)"
		refreshStats()
	else
		statusPage.Visible = false
		skillsPage.Visible = true
		tabBtnSkills.BackgroundColor3 = C.Header
		tabBtnSkills.TextColor3 = Color3.new(1, 1, 1)
		tabBtnStatus.BackgroundColor3 = Color3.fromRGB(50, 60, 85)
		tabBtnStatus.TextColor3 = Color3.fromRGB(180, 195, 220)
		winTitle.Text = "✨ ผังสกิลอาชีพและการจัดช่องสกิล (Skill Tree)"
		if (data.Class or "Novice") == "Novice" then currentTab = "Novice" end
		setTab(currentTab)
		refreshTree()
		refreshBar()
	end
end

tabBtnStatus.Activated:Connect(function() switchMainTab("Stats") end)
tabBtnSkills.Activated:Connect(function() switchMainTab("Skills") end)

_G.ToggleRagnarokStatsWindow = function(targetTab)
	targetTab = targetTab or "Stats"
	if charWin.Visible then
		if (targetTab == "Skills" and not skillsPage.Visible) or (targetTab == "Stats" and not statusPage.Visible) then
			switchMainTab(targetTab)
			return
		end
		charWin.Visible = false
		return
	end
	for _, s in ipairs(STATS) do pending[s] = 0 end
	switchMainTab(targetTab)
	openAnim(charWin)
end

_G.ToggleSkillTreeWindow = function()
	_G.ToggleRagnarokStatsWindow("Skills")
end

UpdateCharacterData.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	local oldClass = data.Class
	for k, v in pairs(payload) do data[k] = v end
	if oldClass ~= data.Class then currentTab = "Job" end
	if charWin.Visible then
		if statusPage.Visible then refreshStats() end
		if skillsPage.Visible then refreshTree() end
	end
end)

local SkillFeedback = Remotes:FindFirstChild("SkillFeedback")
if SkillFeedback then
	SkillFeedback.OnClientEvent:Connect(function(msg, cd)
		if cd == nil and type(msg) == "string" and (charWin.Visible) then showToast(msg) end
	end)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.K then
		_G.ToggleSkillTreeWindow()
	elseif input.KeyCode == Enum.KeyCode.C then
		_G.ToggleRagnarokStatsWindow()
	end
end)

-- ขอข้อมูลตัวละครล่าสุดจาก server (ตารางว่าง = ไม่เปลี่ยนสเตตัส แค่ส่งข้อมูลกลับ)
task.delay(2, function() DistributeStatPoint:FireServer({}) end)

charWin:GetPropertyChangedSignal("Visible"):Connect(function()
	if charWin.Visible then
		if skillsPage.Visible then
			refreshTree()
			refreshBar()
		else
			refreshStats()
		end
	end
end)

print("[RagnarokPanels] Ragnarok M style Status (C) & Skill Tree (K) ready")
