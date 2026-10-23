-- ============================================================
-- HotbarView.lua
-- RoROK — Hotbar HUD (8 Skill Slots, Cooldowns, Keybinds 1-8)
-- ============================================================

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HotbarView = {}

function HotbarView.init(player, playerGui, remotes, UITheme, onCastSlotCallback, onOpenSkillTreeCallback)
	local hex = UITheme.hex
	local makeInstance = UITheme.makeInstance

	local skillData = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("SkillData"))
	local classData = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("ClassData"))

	local skillFeedbackRemote = remotes.skillFeedbackRemote or remotes.SkillFeedback
	local shopFeedbackRemote = remotes.shopFeedbackRemote or remotes.ShopFeedback

	-- ── Hotbar ScreenGui ──────────────────────────────────────
	local hotbarGui = makeInstance("ScreenGui", {
		Name           = "Hotbar",
		ResetOnSpawn   = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)

	local hotbarFrame = makeInstance("Frame", {
		Name             = "HotbarFrame",
		Size             = UDim2.new(0, 456, 0, 62),
		Position         = UDim2.new(0.5, -228, 1, -72),
		BackgroundColor3 = hex("0c1220"),
		BackgroundTransparency = 0.08,
		BorderSizePixel  = 0,
	}, hotbarGui)
	makeInstance("UICorner", {CornerRadius = UDim.new(0, 12)}, hotbarFrame)
	makeInstance("UIStroke", {Color = hex("e5c158"), Thickness = 1.6}, hotbarFrame)
	makeInstance("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, hex("1b253d")),
			ColorSequenceKeypoint.new(1, hex("0b101d")),
		}),
		Rotation = 90,
	}, hotbarFrame)

	-- ── Skill Use Notice Toast (High-Contrast White Dialogue Box) ─
	local skillUseNotice = makeInstance("TextLabel", {
		Name = "SkillUseNotice",
		Size = UDim2.new(0, 520, 0, 44),
		Position = UDim2.new(0.5, -260, 1, -155),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0,
		TextColor3 = Color3.fromRGB(20, 20, 25),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		Text = "",
		TextWrapped = true,
		Visible = false,
		ZIndex = 20,
	}, hotbarGui)
	makeInstance("UICorner", {CornerRadius = UDim.new(0, 8)}, skillUseNotice)
	makeInstance("UIStroke", {Color = Color3.fromRGB(45, 50, 60), Thickness = 2.0}, skillUseNotice)
	makeInstance("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
	}, skillUseNotice)

	local function showNotice(text, duration)
		if not text or text == "" then return end
		skillUseNotice.Text = tostring(text)
		skillUseNotice.Visible = true
		local thisText = skillUseNotice.Text
		task.delay(duration or 2.2, function()
			if skillUseNotice.Parent and skillUseNotice.Text == thisText then
				skillUseNotice.Visible = false
			end
		end)
	end

	makeInstance("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding       = UDim.new(0, 6),
		SortOrder     = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, hotbarFrame)
	makeInstance("UIPadding", {
		PaddingLeft  = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingTop   = UDim.new(0, 5),
		PaddingBottom= UDim.new(0, 5),
	}, hotbarFrame)

	-- ── Hotbar Slots 1-8 ──────────────────────────────────────
	local hotbarSlots = {}
	for i = 1, 8 do
		local slot = makeInstance("TextButton", {
			Name             = "Slot"..i,
			Size             = UDim2.new(0, 48, 0, 48),
			BackgroundColor3 = hex("151d30"),
			BorderSizePixel  = 0,
			Text             = "",
			AutoButtonColor  = false,
			LayoutOrder      = i,
		}, hotbarFrame)
		makeInstance("UICorner", {CornerRadius = UDim.new(0, 8)}, slot)
		makeInstance("UIStroke", {
			Color     = hex("465a7e"),
			Thickness = 1.2,
		}, slot)

		local icon = makeInstance("TextLabel", {
			Name             = "SkillIcon",
			Size             = UDim2.new(1, -4, 0, 22),
			Position         = UDim2.new(0, 2, 0, 9),
			BackgroundTransparency = 1,
			Text             = "",
			TextColor3       = hex("ffd166"),
			Font             = Enum.Font.GothamBlack,
			TextSize         = 18,
			ZIndex           = 2,
		}, slot)

		local skillNameLabel = makeInstance("TextLabel", {
			Name             = "SkillName",
			Size             = UDim2.new(1, -4, 0, 16),
			Position         = UDim2.new(0, 2, 1, -17),
			BackgroundTransparency = 1,
			TextColor3       = hex("e8e8f0"),
			Font             = Enum.Font.GothamSemibold,
			TextSize         = 8,
			TextWrapped      = true,
			TextTruncate     = Enum.TextTruncate.AtEnd,
			Text             = "",
			ZIndex           = 2,
		}, slot)

		local keyBadge = makeInstance("TextLabel", {
			Name             = "KeyLabel",
			Size             = UDim2.new(0, 15, 0, 14),
			Position         = UDim2.new(0, 2, 0, 2),
			BackgroundColor3 = hex("0b101d"),
			BackgroundTransparency = 0.25,
			TextColor3       = hex("f3cf7a"),
			Font             = Enum.Font.GothamBold,
			TextSize         = 9,
			Text             = tostring(i == 10 and 0 or i),
			ZIndex           = 3,
		}, slot)
		makeInstance("UICorner", {CornerRadius = UDim.new(0, 4)}, keyBadge)

		local spCost = makeInstance("TextLabel", {
			Name             = "SPCost",
			Size             = UDim2.new(0, 24, 0, 14),
			Position         = UDim2.new(1, -25, 0, 1),
			BackgroundTransparency = 1,
			TextColor3       = hex("66aaff"),
			Font             = Enum.Font.Gotham,
			TextSize         = 9,
			Text             = "",
			ZIndex           = 3,
		}, slot)

		local cdOverlay = makeInstance("Frame", {
			Name             = "Cooldown",
			Size             = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = hex("000000"),
			BackgroundTransparency = 1,
			Active           = false,
			ZIndex           = 4,
		}, slot)
		makeInstance("UICorner", {CornerRadius = UDim.new(0, 6)}, cdOverlay)

		local cdText = makeInstance("TextLabel", {
			Name             = "CDText",
			Size             = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			TextColor3       = Color3.new(1, 1, 1),
			Font             = Enum.Font.GothamBold,
			TextSize         = 14,
			Text             = "",
			ZIndex           = 5,
		}, cdOverlay)

		slot.Activated:Connect(function()
			if onCastSlotCallback then
				onCastSlotCallback(i)
			elseif _G.CastHotbarSlot then
				_G.CastHotbarSlot(i)
			end
		end)

		hotbarSlots[i] = {
			frame      = slot,
			icon       = icon,
			skillName  = skillNameLabel,
			spCost     = spCost,
			cdOverlay  = cdOverlay,
			cdText     = cdText,
			onCooldown = false,
		}
	end

	-- ── Cooldown Animation ────────────────────────────────────
	local function triggerCooldown(slotIndex, duration)
		local slot = hotbarSlots[slotIndex]
		if not slot or slot.onCooldown then return end
		slot.onCooldown = true
		local overlay = slot.cdOverlay
		local cdText  = slot.cdText
		overlay.BackgroundTransparency = 0.4
		local remaining = duration
		local heartbeat
		heartbeat = RunService.Heartbeat:Connect(function(dt)
			remaining = remaining - dt
			if remaining <= 0 then
				heartbeat:Disconnect()
				overlay.BackgroundTransparency = 1
				cdText.Text = ""
				slot.onCooldown = false
			else
				cdText.Text = string.format("%.1f", remaining)
			end
		end)
	end

	-- ── Keybind 1-8 ───────────────────────────────────────────
	local keyToSlot = {
		[Enum.KeyCode.One]   = 1, [Enum.KeyCode.Two]   = 2,
		[Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four]  = 4,
		[Enum.KeyCode.Five]  = 5, [Enum.KeyCode.Six]   = 6,
		[Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8,
	}

	local skillByClass = {
		Novice   = { "NoviceStrike", "FirstAid" },
		Acolyte  = { "Heal", "HolyLight", "Blessing", "AquaBenedicta", "FirstAid" },
		Knight   = { "Bash", "MagnumBreak", "Provoke", "Endure", "FirstAid" },
		Mage     = { "FireBolt", "ColdBolt", "LightningBolt", "StormGust", "MeteorStorm" },
		Archer   = { "DoubleStrafe", "ArrowShower", "ImproveConcentration", "FirstAid" },
		Thief    = { "Envenom", "Backstab", "Detox", "FirstAid" },
		Merchant = { "Mammonite", "CartRevolution", "CrazyUproar", "FirstAid" },
	}

	local currentOwnedSkills = {}
	local autoSkillCooldownUntil = {}

	local function renderHotbar(data)
		data = data or {}
		local class = data.Class or player:GetAttribute("Class") or "Novice"
		local owned = type(data.Skills) == "table" and data.Skills or {}
		currentOwnedSkills = owned
		skillByClass[class] = skillByClass[class] or {}

		for sId, sLv in pairs(owned) do
			local def = skillData[sId]
			local canUse = (def and (def.class == class or def.class == "Novice" or (classData and classData.CanLearnSkill and classData.CanLearnSkill(class, def.class))))
			if (tonumber(sLv) or 0) > 0 and def and not def.isPassive and canUse then
				local alreadyInBar = false
				for idx = 1, 8 do
					if skillByClass[class][idx] == sId then
						alreadyInBar = true
						break
					end
				end
				if not alreadyInBar then
					for idx = 1, 8 do
						if not skillByClass[class][idx] then
							skillByClass[class][idx] = sId
							break
						end
					end
				end
			end
		end

		for slotIndex, slot in ipairs(hotbarSlots) do
			local skillId = skillByClass[class] and skillByClass[class][slotIndex]
			local definition = skillId and skillData[skillId]
			local skillLevel = skillId and (tonumber(owned[skillId]) or 0) or 0
			if skillId == "NoviceStrike" or skillId == "FirstAid" or slotIndex == 1 then
				skillLevel = math.max(1, skillLevel)
			end
			local hasDef = definition ~= nil
			local isLearned = hasDef and skillLevel > 0
			slot.icon.Text = hasDef and (definition.icon or "✦") or "+"
			slot.icon.TextColor3 = isLearned and hex("ffd166") or hex("64748b")
			slot.skillName.Text = hasDef and (isLearned and ((definition.name or "") .. " Lv." .. tostring(skillLevel)) or ((definition.name or "") .. " (อัป)")) or "ว่าง"
			slot.skillName.TextColor3 = isLearned and hex("e8e8f0") or hex("94a3b8")
			slot.spCost.Text = isLearned and (definition.spCost and definition.spCost > 0
				and ("SP " .. tostring(definition.spCost)) or (definition.goldCost and ("Z " .. tostring(definition.goldCost)) or "")) or ""
			slot.frame.BackgroundColor3 = isLearned and hex("1e293b") or hex("0f172a")
			slot.frame.BackgroundTransparency = isLearned and 0 or 0.25
		end
	end

	local function assignHotbarSkill(slotIndex, skillId)
		local class = player:GetAttribute("Class") or "Novice"
		skillByClass[class] = skillByClass[class] or {}
		if skillId then
			for idx = 1, 8 do
				if skillByClass[class][idx] == skillId and idx ~= slotIndex then
					skillByClass[class][idx] = nil
				end
			end
		end
		skillByClass[class][slotIndex] = skillId
		renderHotbar({ Class = class, Skills = currentOwnedSkills })
	end

	local function getHotbarSkills()
		local class = player:GetAttribute("Class") or "Novice"
		return skillByClass[class] or {}
	end

	_G.AssignHotbarSkill = assignHotbarSkill
	_G.GetHotbarSkills = getHotbarSkills

	local function showSkillFeedback(skillId, cooldown)
		local definition = skillData[skillId]
		if not definition and cooldown == nil then
			showNotice(tostring(skillId), 2.6)
			return
		end
		autoSkillCooldownUntil[skillId] = os.clock() + (tonumber(cooldown) or (definition and definition.cooldown) or 1.5)
		local class = player:GetAttribute("Class") or "Novice"
		local slots = skillByClass[class] or {}
		for slotIndex, assignedSkill in ipairs(slots) do
			if assignedSkill == skillId then
				triggerCooldown(slotIndex, tonumber(cooldown) or 1.5)
				break
			end
		end
		showNotice("ใช้สกิล: " .. (definition and (definition.nameThai or definition.name) or skillId), 2.0)
	end

	if skillFeedbackRemote then
		skillFeedbackRemote.OnClientEvent:Connect(showSkillFeedback)
	end

	if shopFeedbackRemote then
		shopFeedbackRemote.OnClientEvent:Connect(function(message)
			showNotice("ร้านค้า: " .. tostring(message), 2.5)
		end)
	end

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp or UserInputService:GetFocusedTextBox() then return end
		local slot = keyToSlot[input.KeyCode]
		if slot then
			if onCastSlotCallback then
				onCastSlotCallback(slot)
			elseif _G.CastHotbarSlot then
				_G.CastHotbarSlot(slot)
			end
		end
	end)

	local initialClass = player:GetAttribute("Class") or "Novice"
	local initialSkills = {}
	local firstSkill = skillByClass[initialClass] and skillByClass[initialClass][1]
	if firstSkill then initialSkills[firstSkill] = 1 end
	renderHotbar({ Class = initialClass, Skills = initialSkills })

	return {
		hotbarGui = hotbarGui,
		hotbarFrame = hotbarFrame,
		skillUseNotice = skillUseNotice,
		showNotice = showNotice,
		triggerCooldown = triggerCooldown,
		renderHotbar = renderHotbar,
		assignHotbarSkill = assignHotbarSkill,
		getHotbarSkills = getHotbarSkills,
		getSkillByClass = function() return skillByClass end,
		getCurrentOwnedSkills = function() return currentOwnedSkills end,
	}
end

return HotbarView
