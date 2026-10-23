-- ============================================================
-- DamageNumbers.lua
-- RoROK — Floating Damage & Heal Numbers Module
-- ============================================================

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local DamageNumbers = {}

function DamageNumbers.init(playerGui, remotes, UITheme)
	local hex = UITheme.hex
	local makeInstance = UITheme.makeInstance

	local damageGui = makeInstance("ScreenGui", {
		Name           = "DamageNumbers",
		ResetOnSpawn   = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)

	local function showDamageNumber(targetPart, dmgType, amount)
		if not targetPart then return end
		local kind = string.lower(tostring(dmgType or "physical"))
		local worldPosition = typeof(targetPart) == "Vector3" and targetPart
			or (typeof(targetPart) == "Instance" and targetPart.Position)
		if not worldPosition then return end

		local displayText = ""
		local textColor   = Color3.new(1, 1, 1)
		local textSize    = 20

		if kind == "physical" or kind == "phys" or kind == "poison" then
			displayText = tostring(amount)
			textColor   = hex("ff4444")
			textSize    = 20
		elseif kind == "magic" then
			displayText = tostring(amount)
			textColor   = hex("aa44ff")
			textSize    = 20
		elseif kind == "heal" then
			displayText = "+" .. tostring(amount)
			textColor   = hex("44ff88")
			textSize    = 20
		elseif kind == "monster" then
			displayText = "-" .. tostring(amount)
			textColor   = hex("ff5555")
			textSize    = 21
		elseif kind == "crit" then
			displayText = tostring(amount) .. " CRIT!"
			textColor   = hex("ffd700")
			textSize    = 26
		elseif kind == "miss" then
			displayText = "MISS!"
			textColor   = Color3.new(1, 1, 1)
			textSize    = 18
		else
			displayText = tostring(amount)
			textColor   = Color3.new(1, 1, 1)
		end

		local camera = Workspace.CurrentCamera
		if not camera then return end
		local screenPos, onScreen = camera:WorldToScreenPoint(
			worldPosition + Vector3.new(0, 2 + math.random() * 1.5, 0)
		)
		if not onScreen then return end

		local label = makeInstance("TextLabel", {
			Name             = "DmgNum",
			Size             = UDim2.new(0, 150, 0, 40),
			Position         = UDim2.new(0, screenPos.X - 75, 0, screenPos.Y - 20),
			BackgroundTransparency = 1,
			TextColor3       = textColor,
			Font             = Enum.Font.GothamBold,
			TextSize         = textSize,
			Text             = displayText,
			TextStrokeColor3 = Color3.new(0, 0, 0),
			TextStrokeTransparency = 0.3,
			ZIndex           = 10,
		}, damageGui)

		local startY  = screenPos.Y - 20
		local startT  = tick()
		local duration = 1.5
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local elapsed = tick() - startT
			if elapsed >= duration then
				label:Destroy()
				conn:Disconnect()
				return
			end
			local t = elapsed / duration
			label.Position = UDim2.new(0, screenPos.X - 75, 0, startY - t * 60)
			label.TextTransparency = t
			label.TextStrokeTransparency = 0.3 + t * 0.7
		end)
	end

	DamageNumbers.showDamageNumber = showDamageNumber

	local showDamageEvent = (typeof(remotes) == "Instance" and remotes:FindFirstChild("ShowDamageNumber"))
		or (type(remotes) == "table" and (remotes.showDamageEvent or remotes.ShowDamageNumber or (remotes.remoteFolder and remotes.remoteFolder:FindFirstChild("ShowDamageNumber"))))
	if showDamageEvent then
		showDamageEvent.OnClientEvent:Connect(function(position, amount, isCrit, dmgType)
			showDamageNumber(position, isCrit and "crit" or dmgType, amount)
		end)
	end

	local showHealEvent = (typeof(remotes) == "Instance" and remotes:FindFirstChild("ShowHealNumber"))
		or (type(remotes) == "table" and (remotes.showHealEvent or remotes.ShowHealNumber or (remotes.remoteFolder and remotes.remoteFolder:FindFirstChild("ShowHealNumber"))))
	if showHealEvent then
		showHealEvent.OnClientEvent:Connect(function(targetPart, amount)
			showDamageNumber(targetPart, "heal", amount)
		end)
	end

	return DamageNumbers
end

return DamageNumbers
