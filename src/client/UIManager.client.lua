-- ============================================================
-- UIManager.client.lua
-- RoROK — Modular Client UI Orchestrator
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Remote Events Setup ───────────────────────────────────────
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 15)
if not remoteFolder then
	warn("[UIManager] RemoteEvents ไม่พร้อม — หยุดโหลด HUD เพื่อป้องกัน client error")
	return
end

local remotes = {
	remoteFolder            = remoteFolder,
	updateCharData          = remoteFolder:WaitForChild("UpdateCharacterData", 10),
	showDamageEvent         = remoteFolder:WaitForChild("ShowDamageNumber", 10),
	showHealEvent           = remoteFolder:WaitForChild("ShowHealNumber", 10),
	applyStatusEvent        = remoteFolder:WaitForChild("ApplyStatusEffect", 10),
	levelUpEvent            = remoteFolder:WaitForChild("LevelUp", 10),
	requestAttackRemote     = remoteFolder:WaitForChild("RequestAttack", 10),
	useSkillRemote          = remoteFolder:WaitForChild("UseSkill", 10),
	skillFeedbackRemote     = remoteFolder:WaitForChild("SkillFeedback", 10),
	distributeStatRemote    = remoteFolder:WaitForChild("DistributeStatPoint", 10),
	changeClassRemote       = remoteFolder:WaitForChild("ChangeClass", 10),
	openTutorialEvent       = remoteFolder:WaitForChild("OpenTutorial", 10),
	openDailyQuestsEvent    = remoteFolder:WaitForChild("OpenDailyQuests", 10),
	dailyQuestUpdateEvent   = remoteFolder:WaitForChild("DailyQuestUpdate", 10),
	acceptDailyQuestRemote  = remoteFolder:WaitForChild("AcceptDailyQuest", 10),
	claimDailyQuestRemote   = remoteFolder:WaitForChild("ClaimDailyQuest", 10),
	getDailyQuestsRemote    = remoteFolder:WaitForChild("GetDailyQuests", 10),
	studioGrantJobXPRemote  = remoteFolder:WaitForChild("StudioGrantJobXP", 10),
	updateInventoryEvent    = remoteFolder:WaitForChild("UpdateInventory", 10),
	requestInventoryRemote  = remoteFolder:WaitForChild("RequestInventory", 10),
	equipItemRemote         = remoteFolder:WaitForChild("EquipItem", 10),
	unequipItemRemote       = remoteFolder:WaitForChild("UnequipItem", 10),
	dropItemRemote          = remoteFolder:WaitForChild("DropItem", 10),
	useConsumableRemote     = remoteFolder:WaitForChild("UseConsumable", 10),
	refineEquipmentRemote   = remoteFolder:WaitForChild("RefineEquipment", 10),
	openRefinementEvent     = remoteFolder:WaitForChild("OpenRefinement", 10),
	openSupplyShopEvent     = remoteFolder:WaitForChild("OpenSupplyShop", 10),
	purchaseShopItemRemote  = remoteFolder:WaitForChild("PurchaseShopItem", 10),
	sellShopItemRemote      = remoteFolder:WaitForChild("SellShopItem", 10),
	shopFeedbackRemote      = remoteFolder:WaitForChild("ShopFeedback", 10),
}

-- ── Load Modular UI Components ────────────────────────────────
local uiFolder = script.Parent:WaitForChild("UI", 10)
if not uiFolder then
	warn("[UIManager] UI Folder ไม่พบใน StarterPlayerScripts — หยุดการทำงาน")
	return
end

local UITheme         = require(uiFolder:WaitForChild("UITheme"))
local DamageNumbers   = require(uiFolder:WaitForChild("DamageNumbers"))
local HUDView         = require(uiFolder:WaitForChild("HUDView"))
local HotbarView      = require(uiFolder:WaitForChild("HotbarView"))
local MinimapView     = require(uiFolder:WaitForChild("MinimapView"))
local WindowSystem    = require(uiFolder:WaitForChild("WindowSystem"))
local CombatTargeting = require(uiFolder:WaitForChild("CombatTargeting"))
local NpcDialogueUI   = require(uiFolder:WaitForChild("NpcDialogueUI"))

local hex = UITheme.hex
local makeInstance = UITheme.makeInstance

-- ── Initialize Subsystems ─────────────────────────────────────
-- 1. Floating Damage Numbers
DamageNumbers.init(playerGui, remotes, UITheme)

-- 2. Windows System forward declaration
local windowSystem
local combatTargeting
local hotbarView
local hudView
local minimapView

-- 3. Minimap & Quest Tracker
minimapView = MinimapView.init(
	player,
	playerGui,
	remotes,
	UITheme,
	function()
		if windowSystem then windowSystem.toggleMap() end
	end,
	function(notice)
		if hotbarView and hotbarView.showNotice then
			hotbarView.showNotice(notice)
		end
	end
)

-- 4. Main HUD (Party Roster, XP Bars, Status Badges)
hudView = HUDView.init(player, playerGui, remotes, UITheme, {
	onToggleStats = function()
		if windowSystem then windowSystem.toggleStats() end
	end,
	onToggleInventory = function()
		if windowSystem then windowSystem.toggleInventory() end
	end,
	onOpenSkillTree = function()
		if windowSystem then windowSystem.toggleSkillTree() end
	end,
	onToggleAutoAttack = function()
		if combatTargeting then combatTargeting.toggleAutoAttack() end
	end,
	onToggleAutoSettings = function()
		if combatTargeting then combatTargeting.toggleAutoSettings() end
	end,
})

-- 5. Hotbar View (8 Slots, Cooldowns, Keybinds 1-8)
hotbarView = HotbarView.init(
	player,
	playerGui,
	remotes,
	UITheme,
	function(slotIndex)
		if combatTargeting then
			combatTargeting.castHotbarSlot(slotIndex)
		end
	end,
	function()
		if windowSystem then windowSystem.toggleSkillTree() end
	end
)

-- 6. Window System (Stats, Inventory, Refine, Shop, Map, Quests, Esc)
windowSystem = WindowSystem.init(player, playerGui, remotes, UITheme, minimapView, {
	showNotice = function(text, duration)
		if hotbarView then hotbarView.showNotice(text, duration) end
	end,
})

-- 7. Combat & Targeting System (Ground Ring, Range Ring, Auto Battle)
combatTargeting = CombatTargeting.init(player, playerGui, remotes, UITheme, hotbarView, hudView, {
	onOpenSkillTree = function()
		if windowSystem then windowSystem.toggleSkillTree() end
	end,
	getInventory = function()
		return windowSystem and windowSystem.getInventory and windowSystem.getInventory() or {}
	end,
	openRefineWindow = function()
		if windowSystem and windowSystem.openRefine then
			windowSystem.openRefine()
		end
	end,
})

-- 8. NPC Dialogue & Story Quest System (Ragnarok M Town Quests)
local npcDialogueUI = NpcDialogueUI.init(player, playerGui, remotes, UITheme, minimapView, {
	showNotice = function(text, duration)
		if hotbarView then hotbarView.showNotice(text, duration) end
	end,
})

-- ── Export Globals for Inter-Script Compatibility ─────────────
_G.CastHotbarSlot = combatTargeting.castHotbarSlot
_G.TrackQuest = minimapView.trackQuest
shared.TrackQuest = minimapView.trackQuest
_G.ToggleLocalMap = windowSystem.toggleMap
_G.ToggleSkillTreeWindow = windowSystem.toggleSkillTree
_G.ToggleInventory = windowSystem.toggleInventory
_G.ToggleMissionBoard = windowSystem.toggleMissionBoard
_G.AssignHotbarSkill = hotbarView.assignHotbarSkill
_G.GetHotbarSkills = hotbarView.getHotbarSkills
_G.ToggleHelpWindow = windowSystem.toggleHelp
_G.OpenHelpWindow = windowSystem.openHelp

-- ── Remote Event Listeners ────────────────────────────────────
local latestData = nil

if remotes.updateCharData then
	remotes.updateCharData.OnClientEvent:Connect(function(data)
		latestData = data
		hudView.updateData(data)
		windowSystem.renderStats(data)
		hotbarView.renderHotbar(data)
		if data.Inventory then
			windowSystem.renderInventory(data.Inventory, data.Equipment, data.EquipmentRefine)
			if windowSystem.refineWin and windowSystem.refineWin.Visible then
				windowSystem.refreshRefinementPanel(data.Inventory)
			end
		end
	end)
end

if remotes.updateInventoryEvent then
	remotes.updateInventoryEvent.OnClientEvent:Connect(function(inventory, second, third, fourth)
		local equipment, message, equipmentRefine
		if type(second) == "table" then
			equipment, message, equipmentRefine = second, third, fourth
		end
		windowSystem.renderInventory(inventory, equipment, equipmentRefine)
		if windowSystem.shopWin and windowSystem.shopWin.Visible then
			windowSystem.refreshShopSellList()
		end
		if windowSystem.refineWin and windowSystem.refineWin.Visible then
			windowSystem.refreshRefinementPanel(inventory, message)
		end
		if message and hotbarView then
			hotbarView.showNotice(tostring(message), 2.5)
		end
	end)
end

if remotes.requestInventoryRemote then
	task.spawn(function()
		local ok, inventory, equipment, equipmentRefine = pcall(function()
			return remotes.requestInventoryRemote:InvokeServer()
		end)
		if ok then
			windowSystem.renderInventory(inventory, equipment, equipmentRefine)
		end
	end)
end

-- Level Up Burst Animation
if remotes.levelUpEvent then
	remotes.levelUpEvent.OnClientEvent:Connect(function(newLevel)
		local overlay = makeInstance("Frame", {
			Name             = "LevelUpOverlay",
			Size             = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = hex("ffd700"),
			BackgroundTransparency = 0.85,
			ZIndex           = 20,
		}, hudView.hudGui)

		makeInstance("TextLabel", {
			Size             = UDim2.new(1, 0, 0, 80),
			Position         = UDim2.new(0, 0, 0.4, 0),
			BackgroundTransparency = 1,
			TextColor3       = hex("ffd700"),
			Font             = Enum.Font.GothamBold,
			TextSize         = 48,
			Text             = "✨ LEVEL UP! Lv." .. tostring(newLevel) .. " ✨",
			TextStrokeColor3 = Color3.new(0, 0, 0),
			TextStrokeTransparency = 0,
			ZIndex           = 21,
		}, overlay)

		local tIn = TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.7})
		tIn:Play()
		tIn.Completed:Connect(function()
			task.wait(1.5)
			local tOut = TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 1})
			tOut:Play()
			tOut.Completed:Connect(function()
				overlay:Destroy()
			end)
		end)
	end)
end

-- Status Effects (Buffs / Debuffs)
if remotes.applyStatusEvent then
	remotes.applyStatusEvent.OnClientEvent:Connect(function(action, effectName, iconText, bgColorHex, duration)
		if action == "add" then
			local color = bgColorHex and hex(bgColorHex) or hex("555555")
			hudView.addStatusIcon(effectName, iconText or "✦", color, duration)
		elseif action == "remove" then
			hudView.removeStatusIcon(effectName)
		end
	end)
end

-- Tutorial / Help Trigger for new adventurers
if remotes.openTutorialEvent then
	remotes.openTutorialEvent.OnClientEvent:Connect(function()
		if windowSystem.openHelp then
			windowSystem.openHelp()
		elseif _G.OpenHelpWindow then
			_G.OpenHelpWindow()
		end
	end)
end

-- Initial HUD Refresh from Player Attributes
latestData = {
	HP = player:GetAttribute("HP"),
	MaxHP = player:GetAttribute("MaxHP"),
	SP = player:GetAttribute("SP"),
	MaxSP = player:GetAttribute("MaxSP"),
	XP = player:GetAttribute("XP"),
	XP_NextLevel = player:GetAttribute("XP_NextLevel"),
	Level = player:GetAttribute("Level"),
	Class = player:GetAttribute("Class"),
	Gold = player:GetAttribute("Gold"),
	StatPoints = player:GetAttribute("StatPoints"),
	JobLevel = player:GetAttribute("JobLevel"),
	Stats = {
		STR = player:GetAttribute("STR"),
		AGI = player:GetAttribute("AGI"),
		VIT = player:GetAttribute("VIT"),
		INT = player:GetAttribute("INT"),
		DEX = player:GetAttribute("DEX"),
		LUK = player:GetAttribute("LUK"),
	},
}
hudView.updateData(latestData)
windowSystem.renderStats(latestData)

print("[UIManager] Modular HUD orchestrator initialized successfully (RoROK Client)")
