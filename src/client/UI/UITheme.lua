-- ============================================================
-- UITheme.lua
-- RoROK — Shared UI Utilities & Theme Constants
-- ============================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UITheme = {}

-- ── Color Utilities ───────────────────────────────────────────
function UITheme.hex(hexStr)
	hexStr = hexStr:gsub("#", "")
	local r = tonumber(hexStr:sub(1, 2), 16) or 255
	local g = tonumber(hexStr:sub(3, 4), 16) or 255
	local b = tonumber(hexStr:sub(5, 6), 16) or 255
	return Color3.fromRGB(r, g, b)
end

local hex = UITheme.hex

-- ── Color Palette ─────────────────────────────────────────────
UITheme.Colors = {
	Gold          = hex("e5c158"),
	GoldLight     = hex("fde047"),
	GoldDark      = hex("b45309"),
	BgDark        = hex("0f172a"),
	BgSlate       = hex("1e293b"),
	BgParchment   = hex("d8d2c0"),
	BorderSlate   = hex("334155"),
	TextWhite     = hex("ffffff"),
	TextLight     = hex("f8fafc"),
	TextMuted     = hex("94a3b8"),
	TextDark      = hex("141419"),
	HpRed         = hex("ef4444"),
	SpBlue        = hex("38bdf8"),
	XpYellow      = hex("eab308"),
	GreenSuccess  = hex("22c55e"),
	CyanWater     = hex("0ea5e9"),
	PurpleMagic   = hex("a855f7"),
	RedDamage     = Color3.fromRGB(255, 45, 45),
	YellowCrit    = Color3.fromRGB(250, 204, 21),
	GreenHeal     = Color3.fromRGB(34, 197, 94),
}

-- ── Instance Creation Helper ──────────────────────────────────
function UITheme.makeInstance(className, properties, parent)
	local inst = Instance.new(className)
	for k, v in pairs(properties or {}) do
		inst[k] = v
	end
	if parent then inst.Parent = parent end
	return inst
end

-- ── Draggable Window Helper ───────────────────────────────────
function UITheme.makeDraggable(dragHandle, targetFrame)
	local dragging = false
	local dragInput = nil
	local dragStart = nil
	local startPos = nil

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = targetFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			targetFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- ── Pop / Scale Animation ─────────────────────────────────────
function UITheme.animatePop(guiObject, scaleMultiplier, duration)
	local origSize = guiObject.Size
	local bigSize = UDim2.new(
		origSize.X.Scale * (scaleMultiplier or 1.08),
		origSize.X.Offset,
		origSize.Y.Scale * (scaleMultiplier or 1.08),
		origSize.Y.Offset
	)
	local t1 = TweenService:Create(guiObject, TweenInfo.new((duration or 0.15) * 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = bigSize })
	local t2 = TweenService:Create(guiObject, TweenInfo.new((duration or 0.15) * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = origSize })
	t1:Play()
	t1.Completed:Connect(function() t2:Play() end)
end

return UITheme
