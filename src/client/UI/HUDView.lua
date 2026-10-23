-- ============================================================
-- HUDView.lua
-- RoROK — Main HUD (Party Roster, XP Bars, Status Icons, Gold)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local HUDView = {}

function HUDView.init(player, playerGui, remotes, UITheme, callbacks)
	local hex = UITheme.hex
	local makeInstance = UITheme.makeInstance
	callbacks = callbacks or {}

	-- ── Main HUD ScreenGui ────────────────────────────────────
	local hudGui = makeInstance("ScreenGui", {
		Name             = "HUD",
		ResetOnSpawn     = false,
		IgnoreGuiInset   = true,
		ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
	}, playerGui)

	-- ── Party Roster (Top-Left) ───────────────────────────────
	local partyRoster = makeInstance("Frame", {
		Name = "PartyRoster", Size = UDim2.new(0, 860, 0, 88),
		Position = UDim2.new(0, 14, 0, 52), BackgroundTransparency = 1,
	}, hudGui)

	makeInstance("TextLabel", {
		Name = "PartyRosterTitle", Size = UDim2.new(0, 260, 0, 18),
		BackgroundTransparency = 1, Text = "✦ PARTY ROSTER • สมาชิกทีม",
		TextColor3 = hex("f3cf7a"), Font = Enum.Font.GothamBold, TextSize = 11,
		TextStrokeTransparency = 0.3,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, partyRoster)

	local partyMemberStrip = makeInstance("Frame", {
		Name = "Members", Size = UDim2.new(1, 0, 0, 64), Position = UDim2.new(0, 0, 0, 20),
		BackgroundTransparency = 1,
	}, partyRoster)
	makeInstance("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, partyMemberStrip)

	local partyCards = {}
	local partyThumbnailCache = {}
	local latestLocalHudData = nil

	local function memberValue(member, key, defaultValue)
		if member == player and latestLocalHudData and latestLocalHudData[key] ~= nil then
			return latestLocalHudData[key]
		end
		local value = member:GetAttribute(key)
		return value ~= nil and value or defaultValue
	end

	local function createPartyCard(member)
		local card = makeInstance("Frame", {
			Name = "Member_" .. tostring(member.UserId), Size = UDim2.new(0, 178, 0, 62),
			BackgroundColor3 = hex("0c1220"), BackgroundTransparency = 0.08,
			BorderSizePixel = 0, LayoutOrder = member == player and 0 or member.UserId,
		}, partyMemberStrip)
		makeInstance("UICorner", {CornerRadius = UDim.new(0, 10)}, card)
		makeInstance("UIStroke", {
			Color = member == player and hex("e5c158") or hex("465a7e"), Thickness = member == player and 1.6 or 1.2,
		}, card)
		makeInstance("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, hex("1b253d")),
				ColorSequenceKeypoint.new(1, hex("0c111d")),
			}),
			Rotation = 90,
		}, card)

		local avatar = makeInstance("ImageLabel", {
			Name = "Avatar", Size = UDim2.new(0, 42, 0, 42), Position = UDim2.new(0, 8, 0, 10),
			BackgroundColor3 = hex("182238"), BorderSizePixel = 0, Image = "",
		}, card)
		makeInstance("UICorner", {CornerRadius = UDim.new(1, 0)}, avatar)
		makeInstance("UIStroke", {Color = member == player and hex("e5c158") or hex("5b7099"), Thickness = 1.2}, avatar)

		local memberName = makeInstance("TextLabel", {
			Name = "MemberName", Size = UDim2.new(1, -60, 0, 15), Position = UDim2.new(0, 56, 0, 4),
			BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, Text = member.DisplayName,
		}, card)

		local classLabel = makeInstance("TextLabel", {
			Name = "ClassLevel", Size = UDim2.new(1, -60, 0, 12), Position = UDim2.new(0, 56, 0, 18),
			BackgroundTransparency = 1, TextColor3 = hex("f3cf7a"),
			Font = Enum.Font.GothamSemibold, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, Text = "Lv.1 Novice",
		}, card)

		local hpTrack = makeInstance("Frame", {
			Name = "HPTrack", Size = UDim2.new(1, -64, 0, 11), Position = UDim2.new(0, 56, 0, 33),
			BackgroundColor3 = hex("2a1219"), BorderSizePixel = 0,
		}, card)
		makeInstance("UICorner", {CornerRadius = UDim.new(1, 0)}, hpTrack)
		local hpFill = makeInstance("Frame", {
			Name = "HPFill", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = hex("e63946"), BorderSizePixel = 0,
		}, hpTrack)
		makeInstance("UICorner", {CornerRadius = UDim.new(1, 0)}, hpFill)
		makeInstance("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, hex("d62839")),
				ColorSequenceKeypoint.new(1, hex("ff6b6b")),
			}),
		}, hpFill)

		local hpValue = makeInstance("TextLabel", {
			Name = "HPValue", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.25,
			Font = Enum.Font.GothamBold, TextSize = 8, ZIndex = 2, Text = "HP 0/0",
		}, hpTrack)

		local spTrack = makeInstance("Frame", {
			Name = "SPTrack", Size = UDim2.new(1, -64, 0, 11), Position = UDim2.new(0, 56, 0, 46),
			BackgroundColor3 = hex("10203b"), BorderSizePixel = 0,
		}, card)
		makeInstance("UICorner", {CornerRadius = UDim.new(1, 0)}, spTrack)
		local spFill = makeInstance("Frame", {
			Name = "SPFill", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = hex("2563eb"), BorderSizePixel = 0,
		}, spTrack)
		makeInstance("UICorner", {CornerRadius = UDim.new(1, 0)}, spFill)
		makeInstance("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, hex("2563eb")),
				ColorSequenceKeypoint.new(1, hex("38bdf8")),
			}),
		}, spFill)

		local spValue = makeInstance("TextLabel", {
			Name = "SPValue", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.25,
			Font = Enum.Font.GothamBold, TextSize = 8, ZIndex = 2, Text = "SP 0/0",
		}, spTrack)

		partyCards[member] = {
			frame = card, avatar = avatar, name = memberName, class = classLabel,
			hpFill = hpFill, hpValue = hpValue, spFill = spFill, spValue = spValue,
		}

		task.spawn(function()
			local cached = partyThumbnailCache[member.UserId]
			if not cached then
				local ok, image = pcall(function()
					return Players:GetUserThumbnailAsync(member.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
				end)
				if ok then cached = image; partyThumbnailCache[member.UserId] = image end
			end
			if cached and avatar.Parent then avatar.Image = cached end
		end)

		if member == player then
			card.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if callbacks.onToggleStats then
						callbacks.onToggleStats()
					elseif _G.ToggleRagnarokStatsWindow then
						_G.ToggleRagnarokStatsWindow()
					end
				end
			end)
		end

		return partyCards[member]
	end

	local function renderPartyRoster()
		local members = {player}
		local partyId = player:GetAttribute("PartyId") or ""
		if partyId ~= "" then
			local teammates = {}
			for _, other in ipairs(Players:GetPlayers()) do
				if other ~= player and other:GetAttribute("PartyId") == partyId then
					table.insert(teammates, other)
				end
			end
			table.sort(teammates, function(a, b) return a.UserId < b.UserId end)
			for _, teammate in ipairs(teammates) do table.insert(members, teammate) end
		end

		local wanted = {}
		for index, member in ipairs(members) do
			wanted[member] = true
			local card = partyCards[member] or createPartyCard(member)
			card.frame.LayoutOrder = index
			card.frame.Visible = true
			card.name.Text = member.DisplayName .. (member == player and " (คุณ)" or "")
			local level = memberValue(member, "Level", 1)
			local jobLevel = memberValue(member, "JobLevel", 1)
			local className = memberValue(member, "Class", "Novice")
			card.class.Text = string.format("Lv.%s • Job Lv.%s %s", tostring(level), tostring(jobLevel), tostring(className))
			local hp = tonumber(memberValue(member, "HP", 0)) or 0
			local maxHP = math.max(tonumber(memberValue(member, "MaxHP", 1)) or 1, 1)
			local sp = tonumber(memberValue(member, "SP", 0)) or 0
			local maxSP = math.max(tonumber(memberValue(member, "MaxSP", 1)) or 1, 1)
			card.hpFill.Size = UDim2.new(math.clamp(hp / maxHP, 0, 1), 0, 1, 0)
			card.hpValue.Text = string.format("HP %d/%d", hp, maxHP)
			card.spFill.Size = UDim2.new(math.clamp(sp / maxSP, 0, 1), 0, 1, 0)
			card.spValue.Text = string.format("SP %d/%d", sp, maxSP)
		end

		for member, card in pairs(partyCards) do
			if not wanted[member] then
				card.frame:Destroy()
				partyCards[member] = nil
			end
		end
	end

	local function watchPartyMember(member)
		for _, attribute in ipairs({"PartyId", "HP", "MaxHP", "SP", "MaxSP", "Level", "Class"}) do
			member:GetAttributeChangedSignal(attribute):Connect(renderPartyRoster)
		end
		member:GetPropertyChangedSignal("DisplayName"):Connect(renderPartyRoster)
	end

	for _, member in ipairs(Players:GetPlayers()) do watchPartyMember(member) end
	Players.PlayerAdded:Connect(function(member)
		watchPartyMember(member)
		renderPartyRoster()
	end)
	Players.PlayerRemoving:Connect(function() task.defer(renderPartyRoster) end)
	renderPartyRoster()

	-- ── XP & Job XP Progress Bars (Bottom Center) ────────────
	local barContainer = makeInstance("Frame", {
		Name            = "BarContainer",
		Size            = UDim2.new(0, 456, 0, 32),
		Position        = UDim2.new(0.5, -228, 1, -108),
		BackgroundColor3 = hex("0b101d"),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
	}, hudGui)
	makeInstance("UICorner", {CornerRadius = UDim.new(0, 10)}, barContainer)
	makeInstance("UIStroke", {Color = hex("e5c158"), Thickness = 1.2}, barContainer)

	local xpBack = makeInstance("Frame", {
		Name             = "XPBack",
		Size             = UDim2.new(1, -118, 0, 12),
		Position         = UDim2.new(0, 4, 0, 3),
		BackgroundColor3 = hex("111827"),
		BorderSizePixel  = 0,
	}, barContainer)
	makeInstance("UICorner", {CornerRadius = UDim.new(1, 0)}, xpBack)

	local xpBar = makeInstance("Frame", {
		Name             = "XPBar",
		Size             = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = hex("f59e0b"),
		BorderSizePixel  = 0,
	}, xpBack)
	makeInstance("UICorner", {CornerRadius = UDim.new(1, 0)}, xpBar)
	makeInstance("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, hex("d97706")),
			ColorSequenceKeypoint.new(1, hex("fbbf24")),
		}),
		Rotation = 0,
	}, xpBar)

	local xpPercentText = makeInstance("TextLabel", {
		Name = "XPPercentText", Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0, 0),
		BackgroundTransparency = 1, TextColor3 = hex("fef3c7"),
		TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.2,
		Font = Enum.Font.GothamBold, TextSize = 9, Text = "Base Lv.1 • EXP 0.00%", ZIndex = 3,
	}, xpBack)

	local jobXpBack = makeInstance("Frame", {
		Name             = "JobXPBack",
		Size             = UDim2.new(1, -118, 0, 12),
		Position         = UDim2.new(0, 4, 0, 17),
		BackgroundColor3 = hex("111827"),
		BorderSizePixel  = 0,
	}, barContainer)
	makeInstance("UICorner", {CornerRadius = UDim.new(1, 0)}, jobXpBack)

	local jobXpBar = makeInstance("Frame", {
		Name             = "JobXPBar",
		Size             = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = hex("38bdf8"),
		BorderSizePixel  = 0,
	}, jobXpBack)
	makeInstance("UICorner", {CornerRadius = UDim.new(1, 0)}, jobXpBar)
	makeInstance("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, hex("0284c7")),
			ColorSequenceKeypoint.new(1, hex("34d399")),
		}),
		Rotation = 0,
	}, jobXpBar)

	local jobXpPercentText = makeInstance("TextLabel", {
		Name = "JobXPPercentText", Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0, 0),
		BackgroundTransparency = 1, TextColor3 = hex("e0f2fe"),
		TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.2,
		Font = Enum.Font.GothamBold, TextSize = 9, Text = "Job/Skill Lv.1 • 0.00%", ZIndex = 3,
	}, jobXpBack)

	local quickSkillUpgradeBtn = makeInstance("TextButton", {
		Name             = "QuickSkillUpgradeBtn",
		Size             = UDim2.new(0, 106, 1, -6),
		Position         = UDim2.new(1, -110, 0, 3),
		BackgroundColor3 = hex("1e293b"),
		TextColor3       = hex("ffe082"),
		Font             = Enum.Font.GothamBold,
		TextSize         = 10,
		Text             = "✨ สกิล (K)",
		AutoButtonColor  = true,
		ZIndex           = 5,
	}, barContainer)
	makeInstance("UICorner", {CornerRadius = UDim.new(0, 7)}, quickSkillUpgradeBtn)
	local quickSkillStroke = makeInstance("UIStroke", {Color = hex("38bdf8"), Thickness = 1.2}, quickSkillUpgradeBtn)

	quickSkillUpgradeBtn.Activated:Connect(function()
		if callbacks.onOpenSkillTree then
			callbacks.onOpenSkillTree()
		elseif _G.ToggleSkillTreeWindow then
			_G.ToggleSkillTreeWindow()
		end
	end)

	-- ── Status Effect Badges & Popup ──────────────────────────
	local STATUS_EFFECT_INFO = {
		Poison = {
			title = "ติดพิษ (Poison)", category = "debuff",
			desc = "ถูกพิษกัดกร่อน เลือดลดลง 2% ของ MaxHP ทุก 2 วินาที",
			icon = "☠", color = hex("6f8c45"),
		},
		Frozen = {
			title = "แช่แข็ง (Frozen)", category = "debuff",
			desc = "ร่างกายถูกแช่แข็ง ไม่สามารถขยับหรือเคลื่อนที่ได้",
			icon = "❄", color = hex("55aadd"),
		},
		Stun = {
			title = "มึนงง (Stun)", category = "debuff",
			desc = "ติดสตัน เสียจังหวะ ไม่สามารถเคลื่อนที่หรือใช้สกิลได้",
			icon = "⚡", color = hex("e0a83a"),
		},
		Blind = {
			title = "ตาบอด (Blind)", category = "debuff",
			desc = "วิสัยทัศน์มืดมัว ความแม่นยำ (HIT) และการหลบหลีก (FLEE) ลดลง 50%",
			icon = "◉", color = hex("6857a5"),
		},
		Silence = {
			title = "ติดใบ้ (Silence)", category = "debuff",
			desc = "ถูกปิดกั้นพลังเวท ไม่สามารถกดใช้สกิลใดๆ ได้",
			icon = "🔇", color = hex("777788"),
		},
		Curse = {
			title = "ติดคำสาป (Curse)", category = "debuff",
			desc = "ถูกคำสาปชั่วร้าย พลัง STR, AGI, DEX ลดลง 50% และ MaxHP ลดลง 25%",
			icon = "☠", color = hex("8d4b9e"),
		},
		Blessing = {
			title = "พรแห่งทวยเทพ (Blessing)", category = "buff",
			desc = "ได้รับพรอันศักดิ์สิทธิ์ เพิ่มค่า STR, INT, DEX +10 หน่วย",
			icon = "✨", color = hex("f0c33c"),
		},
		IncreaseAGI = {
			title = "เร่งฝีเท้า (Increase AGI)", category = "buff",
			desc = "ร่างกายเบาคล่องแคล่ว เพิ่ม AGI +10 และ FLEE +10 หน่วย",
			icon = "💨", color = hex("4bc878"),
		},
		Endure = {
			title = "ความอดทนเหล็กไหล (Endure)", category = "buff",
			desc = "ต้านทานการกระเด็น (Knockback) และเพิ่ม DEF +10 หน่วย",
			icon = "🛡️", color = hex("3c82dc"),
		},
		ImproveConcentration = {
			title = "รวมสมาธิ (Improve Concentration)", category = "buff",
			desc = "เพิ่มสมาธิแม่นยำ DEX +10, AGI +5, และความเร็วโจมตี ASPD +10%",
			icon = "🎯", color = hex("dc8c32"),
		},
	}

	local statusFrame = makeInstance("Frame", {
		Name             = "StatusIcons",
		Size             = UDim2.new(0, 320, 0, 32),
		Position         = UDim2.new(0.5, -160, 1, -132),
		BackgroundTransparency = 1,
	}, hudGui)
	makeInstance("UIListLayout", {
		FillDirection  = Enum.FillDirection.Horizontal,
		Padding        = UDim.new(0, 5),
		SortOrder      = Enum.SortOrder.LayoutOrder,
	}, statusFrame)

	local statusDetailPopup = makeInstance("Frame", {
		Name             = "StatusDetailPopup",
		Size             = UDim2.new(0, 260, 0, 115),
		Position         = UDim2.new(0.5, -130, 1, -256),
		BackgroundColor3 = hex("0e1628"),
		BackgroundTransparency = 0.05,
		BorderSizePixel  = 0,
		Visible          = false,
		ZIndex           = 60,
	}, hudGui)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 10) }, statusDetailPopup)
	makeInstance("UIStroke", { Color = hex("e5c158"), Thickness = 1.6 }, statusDetailPopup)

	local statusPopupTitle = makeInstance("TextLabel", {
		Size = UDim2.new(1, -36, 0, 24), Position = UDim2.new(0, 12, 0, 8),
		BackgroundTransparency = 1, Text = "สถานะ", Font = Enum.Font.GothamBold,
		TextSize = 13, TextColor3 = hex("ffd700"), TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 61,
	}, statusDetailPopup)

	local statusPopupClose = makeInstance("TextButton", {
		Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -28, 0, 6),
		BackgroundTransparency = 1, Text = "✕", TextColor3 = hex("ffffff"),
		Font = Enum.Font.GothamBold, TextSize = 13, ZIndex = 62,
	}, statusDetailPopup)
	statusPopupClose.Activated:Connect(function() statusDetailPopup.Visible = false end)

	local statusPopupBadge = makeInstance("TextLabel", {
		Size = UDim2.new(0, 92, 0, 18), Position = UDim2.new(0, 12, 0, 33),
		BackgroundColor3 = hex("ef4444"), Text = "[ดีบัฟ]", TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 61,
	}, statusDetailPopup)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, statusPopupBadge)

	local statusPopupDesc = makeInstance("TextLabel", {
		Size = UDim2.new(1, -24, 0, 34), Position = UDim2.new(0, 12, 0, 54),
		BackgroundTransparency = 1, Text = "คำอธิบายสถานะ...", TextColor3 = hex("e2e8f0"),
		Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 61,
	}, statusDetailPopup)

	local statusPopupTime = makeInstance("TextLabel", {
		Size = UDim2.new(1, -24, 0, 16), Position = UDim2.new(0, 12, 1, -20),
		BackgroundTransparency = 1, Text = "⏳ เหลือเวลา: -", TextColor3 = hex("38bdf8"),
		Font = Enum.Font.GothamMedium, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 61,
	}, statusDetailPopup)

	local inspectedEffectName = nil
	local activeStatusRegistry = {}
	local activeStatusIcons = {}

	local function showStatusDetail(effectName)
		local reg = activeStatusRegistry[effectName]
		if not reg then statusDetailPopup.Visible = false return end
		local info = STATUS_EFFECT_INFO[effectName] or {
			title = effectName,
			category = "status",
			desc = "สถานะพิเศษที่มีผลต่อตัวละคร",
			icon = "✦",
			color = hex("e5c158"),
		}
		inspectedEffectName = effectName
		statusPopupTitle.Text = info.title
		statusPopupDesc.Text = info.desc
		if info.category == "buff" then
			statusPopupBadge.Text = "🛡️ บัฟสนับสนุน"
			statusPopupBadge.BackgroundColor3 = hex("16a34a")
		elseif info.category == "debuff" then
			statusPopupBadge.Text = "⚠️ ดีบัฟผิดปกติ"
			statusPopupBadge.BackgroundColor3 = hex("dc2626")
		else
			statusPopupBadge.Text = "✦ สถานะพิเศษ"
			statusPopupBadge.BackgroundColor3 = hex("475569")
		end
		statusDetailPopup.Visible = true
	end

	RunService.Heartbeat:Connect(function()
		if inspectedEffectName and statusDetailPopup.Visible then
			local reg = activeStatusRegistry[inspectedEffectName]
			if reg and reg.expireTick then
				local rem = math.max(0, reg.expireTick - tick())
				statusPopupTime.Text = string.format("⏳ เหลือเวลา: %.1f วินาที", rem)
				if rem <= 0 then
					statusDetailPopup.Visible = false
					inspectedEffectName = nil
				end
			elseif reg then
				statusPopupTime.Text = "⏳ ไม่จำกัดเวลา / ต่อเนื่อง"
			else
				statusDetailPopup.Visible = false
				inspectedEffectName = nil
			end
		end
	end)

	local function addStatusIcon(effectName, iconText, bgColor, duration)
		if activeStatusIcons[effectName] then
			activeStatusIcons[effectName]:Destroy()
			activeStatusIcons[effectName] = nil
		end
		local info = STATUS_EFFECT_INFO[effectName]
		local finalColor = (info and info.color) or bgColor or hex("555555")
		local finalIcon = (info and info.icon) or iconText or "✦"

		local iconBtn = makeInstance("TextButton", {
			Name = "Status_" .. effectName,
			Size = UDim2.new(0, 32, 0, 32),
			BackgroundColor3 = finalColor,
			Text = finalIcon,
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			AutoButtonColor = true,
		}, statusFrame)
		makeInstance("UICorner", { CornerRadius = UDim.new(0, 7) }, iconBtn)
		makeInstance("UIStroke", {
			Color = (info and info.category == "buff") and hex("86efac") or hex("fca5a5"),
			Thickness = 1.4,
		}, iconBtn)

		local timerLabel = nil
		if duration and duration > 0 then
			timerLabel = makeInstance("TextLabel", {
				Name = "TimerLabel",
				Size = UDim2.new(1, 0, 0, 11),
				Position = UDim2.new(0, 0, 1, -11),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.35,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.GothamBold,
				TextSize = 8,
				Text = tostring(math.ceil(duration)),
				ZIndex = 3,
			}, iconBtn)
			makeInstance("UICorner", { CornerRadius = UDim.new(0, 3) }, timerLabel)
		end

		activeStatusIcons[effectName] = iconBtn
		activeStatusRegistry[effectName] = {
			expireTick = (duration and duration > 0) and (tick() + duration) or nil,
			duration = duration,
		}

		iconBtn.Activated:Connect(function()
			showStatusDetail(effectName)
		end)

		if duration and duration > 0 then
			task.spawn(function()
				local t0 = tick()
				while (tick() - t0) < duration do
					task.wait(0.2)
					if not iconBtn.Parent then return end
					local rem = math.max(0, duration - (tick() - t0))
					if timerLabel and timerLabel.Parent then
						timerLabel.Text = tostring(math.ceil(rem))
					end
				end
				if iconBtn.Parent then
					iconBtn:Destroy()
					activeStatusIcons[effectName] = nil
					activeStatusRegistry[effectName] = nil
					if inspectedEffectName == effectName then
						statusDetailPopup.Visible = false
						inspectedEffectName = nil
					end
				end
			end)
		end
	end

	local function removeStatusIcon(effectName)
		if activeStatusIcons[effectName] then
			activeStatusIcons[effectName]:Destroy()
			activeStatusIcons[effectName] = nil
		end
		activeStatusRegistry[effectName] = nil
		if inspectedEffectName == effectName then
			statusDetailPopup.Visible = false
			inspectedEffectName = nil
		end
	end

	-- ── Gold Display ──────────────────────────────────────────
	local goldFrame = makeInstance("Frame", {
		Name             = "GoldDisplay",
		Visible          = false,
		Size             = UDim2.new(0, 148, 0, 32),
		Position         = UDim2.new(1, -325, 0, 12),
		BackgroundColor3 = hex("0c1220"),
		BackgroundTransparency = 0.08,
		BorderSizePixel  = 0,
	}, hudGui)
	makeInstance("UICorner", {CornerRadius = UDim.new(1, 0)}, goldFrame)
	makeInstance("UIStroke", {Color = hex("e5c158"), Thickness = 1.4}, goldFrame)

	local goldLabel = makeInstance("TextLabel", {
		Name             = "GoldAmount",
		Size             = UDim2.new(1, -38, 1, 0),
		Position         = UDim2.new(0, 34, 0, 0),
		BackgroundTransparency = 1,
		TextColor3       = hex("ffe082"),
		Font             = Enum.Font.GothamBold,
		TextSize         = 13,
		TextXAlignment   = Enum.TextXAlignment.Left,
		Text             = "0 z",
	}, goldFrame)

	-- ── Screen Action Buttons (Bottom Left) ───────────────────
	local inventoryButton = makeInstance("TextButton", {
		Name = "InventoryButton", Size = UDim2.new(0, 146, 0, 36),
		Position = UDim2.new(0, 14, 1, -48), BackgroundColor3 = hex("1c1836"),
		BackgroundTransparency = 0.06, BorderSizePixel = 0,
		Text = "🎒 กระเป๋า (E)", TextColor3 = hex("f8fafc"),
		Font = Enum.Font.GothamBold, TextSize = 12, ZIndex = 20,
	}, hudGui)
	makeInstance("UICorner", {CornerRadius = UDim.new(0, 9)}, inventoryButton)
	makeInstance("UIStroke", {Color = hex("7c65b8"), Thickness = 1.3}, inventoryButton)
	inventoryButton.Activated:Connect(function()
		if callbacks.onToggleInventory then callbacks.onToggleInventory() end
	end)

	local autoAttackButton = makeInstance("TextButton", {
		Name = "AutoAttackButton", Size = UDim2.new(0, 146, 0, 36),
		Position = UDim2.new(0, 14, 1, -90), BackgroundColor3 = hex("2b1820"),
		BackgroundTransparency = 0.06, BorderSizePixel = 0,
		Text = "⚔ Auto: ปิด", TextColor3 = hex("f8fafc"),
		Font = Enum.Font.GothamBold, TextSize = 12, ZIndex = 20,
	}, hudGui)
	makeInstance("UICorner", {CornerRadius = UDim.new(0, 9)}, autoAttackButton)
	makeInstance("UIStroke", {Color = hex("c9646e"), Thickness = 1.3}, autoAttackButton)
	autoAttackButton.Activated:Connect(function()
		if callbacks.onToggleAutoAttack then callbacks.onToggleAutoAttack() end
	end)

	local autoSettingsButton = makeInstance("TextButton", {
		Name = "AutoSettingsButton", Size = UDim2.new(0, 38, 0, 36),
		Position = UDim2.new(0, 166, 1, -90), BackgroundColor3 = hex("161f33"),
		Text = "⚙", TextColor3 = hex("f3cf7a"), Font = Enum.Font.GothamBold,
		TextSize = 18, ZIndex = 20,
	}, hudGui)
	makeInstance("UICorner", {CornerRadius = UDim.new(0, 9)}, autoSettingsButton)
	makeInstance("UIStroke", {Color = hex("e5c158"), Thickness = 1.2}, autoSettingsButton)
	autoSettingsButton.Activated:Connect(function()
		if callbacks.onToggleAutoSettings then callbacks.onToggleAutoSettings() end
	end)

	local function updateData(data)
		if not data then return end
		latestLocalHudData = data
		renderPartyRoster()

		local xpRatio = math.clamp((data.XP or 0) / math.max(data.MaxXP or data.XP_NextLevel or 1, 1), 0, 1)
		xpBar.Size = UDim2.new(xpRatio, 0, 1, 0)
		xpPercentText.Text = string.format("Base Lv.%d • EXP %.1f%% (%d/%d)", data.Level or 1, xpRatio * 100, data.XP or 0, math.max(data.XP_NextLevel or 100, 1))

		local jobMax = math.max(data.JobXP_NextLevel or ((data.JobLevel or 1) * 60), 1)
		local jobRatio = math.clamp((data.JobXP or 0) / jobMax, 0, 1)
		jobXpBar.Size = UDim2.new(jobRatio, 0, 1, 0)
		jobXpPercentText.Text = string.format("Job/Skill Lv.%d • %.1f%% (%d/%d)", data.JobLevel or 1, jobRatio * 100, data.JobXP or 0, jobMax)

		local spPts = tonumber(data.SkillPoints) or 0
		if spPts > 0 then
			quickSkillUpgradeBtn.Text = string.format("✨ อัปสกิล (+%d)", spPts)
			quickSkillUpgradeBtn.BackgroundColor3 = hex("287a48")
			quickSkillStroke.Color = hex("ffd166")
		else
			quickSkillUpgradeBtn.Text = "✨ สกิล (K)"
			quickSkillUpgradeBtn.BackgroundColor3 = hex("1e293b")
			quickSkillStroke.Color = hex("38bdf8")
		end

		goldLabel.Text = string.format("%d z", data.Gold or 0)
	end

	return {
		hudGui = hudGui,
		updateData = updateData,
		renderPartyRoster = renderPartyRoster,
		addStatusIcon = addStatusIcon,
		removeStatusIcon = removeStatusIcon,
		autoAttackButton = autoAttackButton,
		autoSettingsButton = autoSettingsButton,
		inventoryButton = inventoryButton,
		statusButton = statusButton,
	}
end

return HUDView
