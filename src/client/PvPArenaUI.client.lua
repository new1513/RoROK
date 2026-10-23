-- ============================================================
-- PvPArenaUI.client.lua
-- StarterPlayerScripts — RoROK (Ragnarok Online-inspired MMORPG)
-- ระบบ UI ลานประลองเกียรติยศ Prontera PvP Arena
-- รวม: แถบสถานะ PvP HUD, ป้ายประกาศสังหาร & สตรีค (Kill Banner),
--      ตารางจัดอันดับ (Leaderboard), และบทสนทนานายทวาร
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
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
		Colors = {
			Gold = Color3.fromRGB(229, 193, 88),
			BgDark = Color3.fromRGB(15, 23, 42),
			BgSlate = Color3.fromRGB(30, 41, 59),
			BorderSlate = Color3.fromRGB(51, 65, 85),
		}
	}
end

local hex = UITheme.hex
local makeInstance = UITheme.makeInstance

-- Remote Events
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local RE_EnterPvPArena        = remoteFolder and remoteFolder:WaitForChild("EnterPvPArena", 10)
local RE_LeavePvPArena        = remoteFolder and remoteFolder:WaitForChild("LeavePvPArena", 10)
local RE_GetPvPLeaderboard    = remoteFolder and remoteFolder:WaitForChild("GetPvPLeaderboard", 10)
local RE_PvPLeaderboardUpdate = remoteFolder and remoteFolder:WaitForChild("PvPLeaderboardUpdate", 10)
local RE_PvPAnnounce          = remoteFolder and remoteFolder:WaitForChild("PvPAnnounce", 10)
local RE_PvPStateChanged      = remoteFolder and remoteFolder:WaitForChild("PvPStateChanged", 10)
local RE_OpenPvPDialogue      = remoteFolder and remoteFolder:WaitForChild("OpenPvPDialogue", 10)

-- ── 1. MAIN SCREEN GUI ────────────────────────────────────────
local pvpHudGui = makeInstance("ScreenGui", {
	Name = "RoROK_PvPHud",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 16,
}, playerGui)

-- ── 2. PVP STATUS HUD BAR (Top-Right under Minimap) ───────────
local pvpHudBar = makeInstance("Frame", {
	Name = "PvPStatusBar",
	Size = UDim2.new(0, 360, 0, 48),
	Position = UDim2.new(1, -370, 0, 195),
	BackgroundColor3 = hex("0f172a"),
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 20,
}, pvpHudGui)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, pvpHudBar)
local hudBarStroke = makeInstance("UIStroke", { Color = hex("e5c158"), Thickness = 1.4 }, pvpHudBar)

local hudTitle = makeInstance("TextLabel", {
	Name = "PvPTitle",
	Size = UDim2.new(0, 100, 0, 20),
	Position = UDim2.new(0, 10, 0, 4),
	BackgroundTransparency = 1,
	Text = "⚔️ PVP ARENA",
	TextColor3 = hex("ffd700"),
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 21,
}, pvpHudBar)

-- Zone Indicator (Safe Zone vs Combat)
local zoneBadge = makeInstance("Frame", {
	Name = "ZoneBadge",
	Size = UDim2.new(0, 100, 0, 18),
	Position = UDim2.new(0, 95, 0, 5),
	BackgroundColor3 = hex("166534"),
	BorderSizePixel = 0,
	ZIndex = 21,
}, pvpHudBar)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, zoneBadge)

local zoneLabel = makeInstance("TextLabel", {
	Name = "ZoneText",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Text = "🛡️ SAFE ZONE",
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 9,
	ZIndex = 22,
}, zoneBadge)

-- Stats Text: Kills / Deaths / Streak / Points
local statsLabel = makeInstance("TextLabel", {
	Name = "StatsLabel",
	Size = UDim2.new(1, -120, 0, 20),
	Position = UDim2.new(0, 10, 0, 24),
	BackgroundTransparency = 1,
	Text = "⚔️ K: 0  |  💀 D: 0  |  🔥 Streak: 0  |  🏅 0 PTS",
	TextColor3 = hex("e2e8f0"),
	Font = Enum.Font.GothamSemibold,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 21,
}, pvpHudBar)

-- Quick Buttons
local lbQuickBtn = makeInstance("TextButton", {
	Name = "LbBtn",
	Size = UDim2.new(0, 68, 0, 36),
	Position = UDim2.new(1, -148, 0, 6),
	BackgroundColor3 = hex("1e293b"),
	TextColor3 = hex("fbbf24"),
	Font = Enum.Font.GothamBold,
	TextSize = 11,
	Text = "🏆 อันดับ\n[P]",
	ZIndex = 22,
}, pvpHudBar)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, lbQuickBtn)
makeInstance("UIStroke", { Color = hex("e5c158"), Thickness = 1 }, lbQuickBtn)

local leaveQuickBtn = makeInstance("TextButton", {
	Name = "LeaveBtn",
	Size = UDim2.new(0, 68, 0, 36),
	Position = UDim2.new(1, -74, 0, 6),
	BackgroundColor3 = hex("7f1d1d"),
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 11,
	Text = "🚪 ออก\n[Prontera]",
	ZIndex = 22,
}, pvpHudBar)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, leaveQuickBtn)

leaveQuickBtn.Activated:Connect(function()
	if RE_LeavePvPArena then
		RE_LeavePvPArena:FireServer()
	end
end)

-- ── 3. KILL FEED & ANNOUNCER BANNER (Top Center) ──────────────
local killBanner = makeInstance("Frame", {
	Name = "KillBanner",
	Size = UDim2.new(0, 440, 0, 54),
	Position = UDim2.new(0.5, -220, 0, -80), -- starts off-screen
	BackgroundColor3 = hex("0b0f19"),
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 30,
}, pvpHudGui)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 10) }, killBanner)
local bannerStroke = makeInstance("UIStroke", { Color = hex("ef4444"), Thickness = 1.8 }, killBanner)

local bannerMainText = makeInstance("TextLabel", {
	Name = "MainText",
	Size = UDim2.new(1, -16, 0, 24),
	Position = UDim2.new(0, 8, 0, 5),
	BackgroundTransparency = 1,
	Text = "Player1 ⚔️ Player2",
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	ZIndex = 31,
}, killBanner)

local bannerSubText = makeInstance("TextLabel", {
	Name = "SubText",
	Size = UDim2.new(1, -16, 0, 20),
	Position = UDim2.new(0, 8, 0, 28),
	BackgroundTransparency = 1,
	Text = "🔥 KILLING SPREE! (+65 แต้ม PvP)",
	TextColor3 = hex("fde047"),
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	ZIndex = 31,
}, killBanner)

local bannerTweenOut = nil

local function showKillBanner(data)
	if bannerTweenOut then bannerTweenOut:Cancel() end

	local kName = data.killerName or "Unknown"
	local vName = data.victimName or "Target"
	local kClass = (data.killerClass and not kName:find("%(")) and (" (" .. data.killerClass .. ")") or ""
	local vClass = (data.victimClass and not vName:find("%(")) and (" (" .. data.victimClass .. ")") or ""
	bannerMainText.Text = string.format("⚔️ %s%s  ➔  %s%s", kName, kClass, vName, vClass)

	if data.streakTitle and data.streakTitle ~= "" then
		bannerSubText.Text = string.format("%s  (+%d แต้ม • +%d Zeny)", data.streakTitle, data.pointsGained or 50, data.zenyGained or 300)
		bannerStroke.Color = hex("f59e0b")
	else
		bannerSubText.Text = string.format("สังหารสำเร็จ!  (+%d แต้ม • +%d Zeny)", data.pointsGained or 50, data.zenyGained or 300)
		bannerStroke.Color = hex("ef4444")
	end

	killBanner.Visible = true
	killBanner.Position = UDim2.new(0.5, -220, 0, -80)

	-- Tween In
	TweenService:Create(killBanner, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -220, 0, 24)
	}):Play()

	-- Play sound effect
	pcall(function()
		local sfx = Instance.new("Sound")
		sfx.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sfx.Volume = 0.65
		sfx.Parent = playerGui
		sfx:Play()
		Debris:AddItem(sfx, 3)
	end)

	-- Auto Tween Out after 3.6s
	task.delay(3.6, function()
		if killBanner.Visible then
			bannerTweenOut = TweenService:Create(killBanner, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, -220, 0, -80)
			})
			bannerTweenOut:Play()
			bannerTweenOut.Completed:Connect(function()
				killBanner.Visible = false
			end)
		end
	end)
end

-- ── 4. FULL PVP LEADERBOARD WINDOW (Toggleable with 'P') ──────
local lbWindow = makeInstance("Frame", {
	Name = "PvPLeaderboardWindow",
	Size = UDim2.new(0, 560, 0, 440),
	Position = UDim2.new(0.5, -280, 0.5, -220),
	BackgroundColor3 = hex("0f172a"),
	BackgroundTransparency = 0.05,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 40,
}, pvpHudGui)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 12) }, lbWindow)
makeInstance("UIStroke", { Color = hex("e5c158"), Thickness = 1.8 }, lbWindow)

-- Window Title Bar
local lbTitleBar = makeInstance("Frame", {
	Name = "TitleBar",
	Size = UDim2.new(1, 0, 0, 42),
	BackgroundColor3 = hex("1e293b"),
	BorderSizePixel = 0,
	ZIndex = 41,
}, lbWindow)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 12) }, lbTitleBar)

makeInstance("TextLabel", {
	Size = UDim2.new(1, -60, 1, 0),
	Position = UDim2.new(0, 16, 0, 0),
	BackgroundTransparency = 1,
	Text = "🏆 ตารางเกียรติยศ • PRONTERA PVP LEADERBOARD",
	TextColor3 = hex("ffd700"),
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 42,
}, lbTitleBar)

local lbCloseBtn = makeInstance("TextButton", {
	Name = "CloseBtn",
	Size = UDim2.new(0, 28, 0, 28),
	Position = UDim2.new(1, -36, 0, 7),
	BackgroundColor3 = hex("ef4444"),
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	Text = "✕",
	ZIndex = 43,
}, lbTitleBar)
makeInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, lbCloseBtn)
lbCloseBtn.Activated:Connect(function() lbWindow.Visible = false end)

-- Table Header
local tableHeader = makeInstance("Frame", {
	Name = "TableHeader",
	Size = UDim2.new(1, -24, 0, 28),
	Position = UDim2.new(0, 12, 0, 48),
	BackgroundColor3 = hex("1e293b"),
	BorderSizePixel = 0,
	ZIndex = 41,
}, lbWindow)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, tableHeader)

local function makeHeaderLabel(text, xPos, width, align)
	return makeInstance("TextLabel", {
		Size = UDim2.new(0, width, 1, 0),
		Position = UDim2.new(0, xPos, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = hex("94a3b8"),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextXAlignment = align or Enum.TextXAlignment.Center,
		ZIndex = 42,
	}, tableHeader)
end

makeHeaderLabel("อันดับ", 6, 44, Enum.TextXAlignment.Center)
makeHeaderLabel("ผู้กล้า (Player)", 54, 150, Enum.TextXAlignment.Left)
makeHeaderLabel("อาชีพ", 208, 70, Enum.TextXAlignment.Center)
makeHeaderLabel("สังหาร", 282, 50, Enum.TextXAlignment.Center)
makeHeaderLabel("พ่ายแพ้", 336, 50, Enum.TextXAlignment.Center)
makeHeaderLabel("สตรีค", 390, 50, Enum.TextXAlignment.Center)
makeHeaderLabel("คะแนน", 444, 80, Enum.TextXAlignment.Right)

-- Scrolling Frame for Rows
local rowsScroll = makeInstance("ScrollingFrame", {
	Name = "RowsScroll",
	Size = UDim2.new(1, -24, 1, -90),
	Position = UDim2.new(0, 12, 0, 80),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 5,
	ScrollBarImageColor3 = hex("e5c158"),
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ZIndex = 41,
}, lbWindow)

local rowsLayout = makeInstance("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 4),
}, rowsScroll)

local function renderLeaderboardRows(entries)
	for _, child in ipairs(rowsScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	if not entries or #entries == 0 then
		local emptyLabel = makeInstance("TextLabel", {
			Size = UDim2.new(1, 0, 0, 80),
			BackgroundTransparency = 1,
			Text = "ยังไม่มีประวัติการประลองในเซิร์ฟเวอร์\nร่วมเป็นผู้กล้าคนแรกในลานประลอง!",
			TextColor3 = hex("64748b"),
			Font = Enum.Font.Gotham,
			TextSize = 12,
			ZIndex = 42,
		}, rowsScroll)
		rowsScroll.CanvasSize = UDim2.new(0, 0, 0, 90)
		return
	end

	for rank, entry in ipairs(entries) do
		local isLocalPlayer = (entry.UserId == localPlayer.UserId or entry.Name == localPlayer.Name)

		local row = makeInstance("Frame", {
			Name = "Row_" .. rank,
			Size = UDim2.new(1, -8, 0, 32),
			BackgroundColor3 = isLocalPlayer and hex("1e3a5f") or ((rank % 2 == 0) and hex("131c2e") or hex("172338")),
			BorderSizePixel = 0,
			ZIndex = 42,
		}, rowsScroll)
		makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, row)

		if isLocalPlayer then
			makeInstance("UIStroke", { Color = hex("38bdf8"), Thickness = 1.2 }, row)
		end

		-- Rank badge
		local rankText = tostring(rank)
		local rankColor = hex("94a3b8")
		if rank == 1 then
			rankText = "🥇 1"
			rankColor = hex("ffd700")
		elseif rank == 2 then
			rankText = "🥈 2"
			rankColor = hex("e2e8f0")
		elseif rank == 3 then
			rankText = "🥉 3"
			rankColor = hex("cd7f32")
		end

		makeInstance("TextLabel", {
			Size = UDim2.new(0, 44, 1, 0), Position = UDim2.new(0, 6, 0, 0),
			BackgroundTransparency = 1, Text = rankText, TextColor3 = rankColor,
			Font = Enum.Font.GothamBold, TextSize = 11, ZIndex = 43,
		}, row)

		-- Player Name
		makeInstance("TextLabel", {
			Size = UDim2.new(0, 150, 1, 0), Position = UDim2.new(0, 54, 0, 0),
			BackgroundTransparency = 1, Text = (isLocalPlayer and "★ " or "") .. (entry.Name or "Player"),
			TextColor3 = isLocalPlayer and hex("7dd3fc") or hex("f8fafc"),
			Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
		}, row)

		-- Class
		makeInstance("TextLabel", {
			Size = UDim2.new(0, 70, 1, 0), Position = UDim2.new(0, 208, 0, 0),
			BackgroundTransparency = 1, Text = entry.Class or "Novice",
			TextColor3 = hex("cbd5e1"), Font = Enum.Font.Gotham, TextSize = 10, ZIndex = 43,
		}, row)

		-- Kills
		makeInstance("TextLabel", {
			Size = UDim2.new(0, 50, 1, 0), Position = UDim2.new(0, 282, 0, 0),
			BackgroundTransparency = 1, Text = tostring(entry.Kills or 0),
			TextColor3 = hex("22c55e"), Font = Enum.Font.GothamBold, TextSize = 11, ZIndex = 43,
		}, row)

		-- Deaths
		makeInstance("TextLabel", {
			Size = UDim2.new(0, 50, 1, 0), Position = UDim2.new(0, 336, 0, 0),
			BackgroundTransparency = 1, Text = tostring(entry.Deaths or 0),
			TextColor3 = hex("ef4444"), Font = Enum.Font.Gotham, TextSize = 10, ZIndex = 43,
		}, row)

		-- Best Streak
		makeInstance("TextLabel", {
			Size = UDim2.new(0, 50, 1, 0), Position = UDim2.new(0, 390, 0, 0),
			BackgroundTransparency = 1, Text = tostring(entry.BestStreak or entry.Streak or 0),
			TextColor3 = hex("f59e0b"), Font = Enum.Font.GothamBold, TextSize = 11, ZIndex = 43,
		}, row)

		-- Points
		makeInstance("TextLabel", {
			Size = UDim2.new(0, 80, 1, 0), Position = UDim2.new(0, 444, 0, 0),
			BackgroundTransparency = 1, Text = string.format("%d PTS", entry.Points or 0),
			TextColor3 = hex("ffd700"), Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 43,
		}, row)
	end

	rowsScroll.CanvasSize = UDim2.new(0, 0, 0, #entries * 36 + 10)
end

lbQuickBtn.Activated:Connect(function()
	lbWindow.Visible = not lbWindow.Visible
	if lbWindow.Visible and RE_GetPvPLeaderboard then
		RE_GetPvPLeaderboard:FireServer()
	end
end)

-- ── 5. NPC DIALOGUE MODAL (Prontera Gatekeeper & Valdis) ───────
local dialogueWin = makeInstance("Frame", {
	Name = "PvPDialogueWindow",
	Size = UDim2.new(0, 480, 0, 290),
	Position = UDim2.new(0.5, -240, 0.5, -145),
	BackgroundColor3 = hex("0f172a"),
	BackgroundTransparency = 0.05,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 50,
}, pvpHudGui)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 12) }, dialogueWin)
makeInstance("UIStroke", { Color = hex("e5c158"), Thickness = 1.6 }, dialogueWin)

local diagTitle = makeInstance("TextLabel", {
	Size = UDim2.new(1, -20, 0, 32),
	Position = UDim2.new(0, 12, 0, 8),
	BackgroundTransparency = 1,
	Text = "⚔️ ผู้คุมลานประลอง PvP",
	TextColor3 = hex("ffd700"),
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 51,
}, dialogueWin)

local diagBody = makeInstance("TextLabel", {
	Size = UDim2.new(1, -24, 0, 95),
	Position = UDim2.new(0, 12, 0, 44),
	BackgroundTransparency = 1,
	Text = "ยินดีต้อนรับสู่นักรบแห่ง RoROK!\nลานประลองเกียรติยศเปิดต้อนรับเหล่านักผจญภัยทุกท่านเข้ามาประลองฝีมือร่วมกัน โดยการพ่ายแพ้ในสังเวียนนี้ \"จะไม่สูญเสีย EXP\" ใดๆ ทั้งสิ้น พร้อมรับ Zeny และแต้มสะสมอันดับเกียรติยศ!",
	TextColor3 = hex("e2e8f0"),
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	ZIndex = 51,
}, dialogueWin)

-- Action 1: Enter Arena
local enterBtn = makeInstance("TextButton", {
	Name = "EnterBtn",
	Size = UDim2.new(1, -24, 0, 36),
	Position = UDim2.new(0, 12, 0, 146),
	BackgroundColor3 = hex("b45309"),
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	Text = "⚔️ เข้าสู่ลานประลอง (Enter PvP Arena)",
	ZIndex = 52,
}, dialogueWin)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, enterBtn)

enterBtn.Activated:Connect(function()
	dialogueWin.Visible = false
	if RE_EnterPvPArena then
		RE_EnterPvPArena:FireServer()
	end
end)

-- Action 2: View Leaderboard
local viewLbBtn = makeInstance("TextButton", {
	Name = "ViewLbBtn",
	Size = UDim2.new(1, -24, 0, 36),
	Position = UDim2.new(0, 12, 0, 190),
	BackgroundColor3 = hex("1e293b"),
	TextColor3 = hex("fbbf24"),
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	Text = "🏆 ตรวจสอบกระดานอันดับ (Leaderboard)",
	ZIndex = 52,
}, dialogueWin)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, viewLbBtn)

viewLbBtn.Activated:Connect(function()
	dialogueWin.Visible = false
	lbWindow.Visible = true
	if RE_GetPvPLeaderboard then
		RE_GetPvPLeaderboard:FireServer()
	end
end)

-- Action 3: Close
local closeDiagBtn = makeInstance("TextButton", {
	Name = "CloseDiagBtn",
	Size = UDim2.new(1, -24, 0, 32),
	Position = UDim2.new(0, 12, 0, 234),
	BackgroundColor3 = hex("0f172a"),
	TextColor3 = hex("94a3b8"),
	Font = Enum.Font.Gotham,
	TextSize = 11,
	Text = "✕ ยกเลิก / ปิดบทสนทนา",
	ZIndex = 52,
}, dialogueWin)
makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, closeDiagBtn)

closeDiagBtn.Activated:Connect(function()
	dialogueWin.Visible = false
end)

-- ── 6. REMOTE LISTENERS & KEYBINDS ────────────────────────────
if RE_OpenPvPDialogue then
	RE_OpenPvPDialogue.OnClientEvent:Connect(function(npcType)
		if npcType == "Valdis" then
			diagTitle.Text = "⚔️ Valdis • ครูฝึกสังเวียนเกียรติยศ"
			diagBody.Text = "ยินดีด้วยที่ก้าวขึ้นสู่สังเวียนแห่งนี้! คุณสามารถต่อสู้กับผู้เล่นคนอื่นในลานกลางได้ทันที แต่จำไว้ว่าเมื่ออยู่ในเขต Safe Zone จะไม่มีใครทำร้ายคุณได้ สนใจดูตารางคะแนนสูงสุดในสังเวียนตอนนี้หรือไม่?"
			enterBtn.Visible = false
			viewLbBtn.Position = UDim2.new(0, 12, 0, 150)
			closeDiagBtn.Position = UDim2.new(0, 12, 0, 194)
		else
			diagTitle.Text = "⚔️ นายทวารลานประลอง PvP (Prontera)"
			diagBody.Text = "ยินดีต้อนรับสู่นักรบแห่ง RoROK!\nลานประลองเกียรติยศเปิดต้อนรับเหล่านักผจญภัยทุกท่านเข้ามาประลองฝีมือร่วมกัน โดยการพ่ายแพ้ในสังเวียนนี้ \"จะไม่สูญเสีย EXP\" ใดๆ ทั้งสิ้น พร้อมรับ Zeny และแต้มสะสมอันดับเกียรติยศ!"
			enterBtn.Visible = true
			viewLbBtn.Position = UDim2.new(0, 12, 0, 190)
			closeDiagBtn.Position = UDim2.new(0, 12, 0, 234)
		end
		dialogueWin.Visible = true
	end)
end

if RE_PvPStateChanged then
	RE_PvPStateChanged.OnClientEvent:Connect(function(inPvP, inSafeZone)
		pvpHudBar.Visible = inPvP
		if inPvP then
			if inSafeZone then
				zoneBadge.BackgroundColor3 = hex("166534")
				zoneLabel.Text = "🛡️ SAFE ZONE"
				hudBarStroke.Color = hex("22c55e")
			else
				zoneBadge.BackgroundColor3 = hex("991b1b")
				zoneLabel.Text = "⚔️ COMBAT ACTIVE"
				hudBarStroke.Color = hex("ef4444")
			end
		end
	end)
end

if RE_PvPAnnounce then
	RE_PvPAnnounce.OnClientEvent:Connect(function(data)
		showKillBanner(data)
	end)
end

if RE_PvPLeaderboardUpdate then
	RE_PvPLeaderboardUpdate.OnClientEvent:Connect(function(topList)
		renderLeaderboardRows(topList)

		-- Update local stats label in HUD bar
		for _, entry in ipairs(topList) do
			if entry.UserId == localPlayer.UserId or entry.Name == localPlayer.Name then
				statsLabel.Text = string.format("⚔️ K: %d  |  💀 D: %d  |  🔥 Streak: %d  |  🏅 %d PTS",
					entry.Kills or 0,
					entry.Deaths or 0,
					entry.Streak or 0,
					entry.Points or 0
				)
				break
			end
		end
	end)
end

-- Keybind: 'P' toggles Leaderboard
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.P then
		lbWindow.Visible = not lbWindow.Visible
		if lbWindow.Visible and RE_GetPvPLeaderboard then
			RE_GetPvPLeaderboard:FireServer()
		end
	end
end)

-- Check initial state on spawn
task.spawn(function()
	task.wait(1)
	local isPvP = (localPlayer:GetAttribute("Map") == "PvPArena")
	local isSafe = localPlayer:GetAttribute("InPvPSafeZone") or true
	pvpHudBar.Visible = isPvP
	if isPvP and RE_GetPvPLeaderboard then
		RE_GetPvPLeaderboard:FireServer()
	end
end)

print("[PvPArenaUI] Prontera PvP Arena Client UI initialized successfully")
