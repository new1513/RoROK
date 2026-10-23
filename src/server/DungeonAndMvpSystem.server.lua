-- ============================================================
-- DungeonAndMvpSystem.server.lua
-- ServerScriptService — RoROK (Ragnarok Online-inspired MMORPG)
-- ระบบดันเจี้ยนและ MVP Boss Raid (Prontera Culvert & Morroc)
-- รวม: การเกิดของบอส MVP (GTB, Drake, Eddga), ประกาศการสังหารบอส
--      ทั้งเซิร์ฟเวอร์, และการดรอปหีบสมบัติ MVP (Treasure Chest)
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Debris            = game:GetService("Debris")

local GameData    = ReplicatedStorage:WaitForChild("GameData")
local MonsterData = require(GameData:WaitForChild("MonsterData"))

local DataStore
local GameManager

local t0 = tick()
repeat
	task.wait(0.1)
	DataStore = _G.DataStore
	GameManager = _G.GameManager
until (DataStore and GameManager) or (tick() - t0 > 15)

local remotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local RE_SkillFeedback = remotesFolder and remotesFolder:WaitForChild("SkillFeedback", 10)

local mvpFolder = Workspace:FindFirstChild("RoROK_MVPBosses")
if mvpFolder then mvpFolder:Destroy() end
mvpFolder = Instance.new("Folder")
mvpFolder.Name = "RoROK_MVPBosses"
mvpFolder.Parent = Workspace

-- ── 1. SPAWN MVP TREASURE CHEST ──────────────────────────────
local function spawnTreasureChest(pos, bossId, killerPlayer)
	local chest = Instance.new("Model")
	chest.Name = "MVPTreasureChest_" .. tostring(bossId)
	chest.Parent = mvpFolder

	local base = Instance.new("Part")
	base.Name = "ChestBase"
	base.Size = Vector3.new(4, 2.5, 3)
	base.CFrame = CFrame.new(pos + Vector3.new(0, 1.25, 0))
	base.Material = Enum.Material.WoodPlanks
	base.Color = Color3.fromRGB(115, 75, 45)
	base.Anchored = true
	base.CanCollide = true
	base.Parent = chest
	chest.PrimaryPart = base

	local lid = Instance.new("Part")
	lid.Name = "ChestLid"
	lid.Size = Vector3.new(4.2, 1.2, 3.2)
	lid.CFrame = CFrame.new(pos + Vector3.new(0, 2.8, 0))
	lid.Material = Enum.Material.Neon
	lid.Color = Color3.fromRGB(255, 205, 50)
	lid.Anchored = true
	lid.CanCollide = true
	lid.Parent = chest

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 215, 80)
	light.Brightness = 2.5
	light.Range = 22
	light.Parent = base

	local bb = Instance.new("BillboardGui")
	bb.Name = "ChestBillboard"
	bb.Size = UDim2.new(0, 240, 0, 48)
	bb.StudsOffset = Vector3.new(0, 2.8, 0)
	bb.MaxDistance = 45
	bb.AlwaysOnTop = false
	bb.Parent = lid

	local bbText = Instance.new("TextLabel")
	bbText.Size = UDim2.new(1, 0, 1, 0)
	bbText.BackgroundTransparency = 1
	bbText.Text = "💎 หีบสมบัติ MVP ระดับตำนาน\n[กด F หรือคลิกเพื่อรับสมบัติ]"
	bbText.TextColor3 = Color3.fromRGB(255, 235, 120)
	bbText.TextStrokeTransparency = 0.2
	bbText.Font = Enum.Font.GothamBold
	bbText.TextSize = 13
	bbText.Parent = bb

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "หีบสมบัติ MVP (" .. tostring(bossId) .. ")"
	prompt.ActionText = "เปิดรับสมบัติและเหรียญทอง"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = base

	local opened = false
	prompt.Triggered:Connect(function(player)
		if opened then return end
		opened = true
		prompt.Enabled = false

		local goldBonus = 5000
		if DataStore then
			(DataStore.ModifyGold or DataStore.AddGold)(player, goldBonus)
			DataStore.AddItem(player, "BeginnerRefinementStone", 3)
		end

		local cardId = (bossId == "GoldenThiefBug" and "GoldenThiefBugCard") or (bossId == "Drake" and "DrakeCard") or "EddgaCard"
		if math.random(1, 100) <= 60 then
			if DataStore then
				DataStore.AddItem(player, cardId, 1)
			end
			if RE_SkillFeedback then
				RE_SkillFeedback:FireClient(player, string.format("🎉 ยอดเยี่ยม! คุณได้รับ %s จากหีบสมบัติ MVP!", cardId))
			end
		end

		if GameManager and GameManager.PushCharacterData then
			GameManager.PushCharacterData(player)
		end

		if RE_SkillFeedback then
			RE_SkillFeedback:FireClient(player, string.format("💰 คุณเปิดหีบสมบัติ MVP ได้รับ +%d Zeny และหินตีบวก!", goldBonus))
		end

		-- Visual open & cleanup
		lid.CFrame = lid.CFrame * CFrame.Angles(math.rad(45), 0, 0)
		lid.Color = Color3.fromRGB(150, 230, 120)
		bbText.Text = "✓ เปิดสมบัติแล้วโดย " .. player.Name
		bbText.TextColor3 = Color3.fromRGB(140, 230, 140)

		Debris:AddItem(chest, 20)
	end)

	Debris:AddItem(chest, 90)
end

-- Export MVP Treasure Chest for CombatSystem when MVP boss dies
_G.SpawnMvpTreasureChest = spawnTreasureChest

print("[DungeonAndMvpSystem] Instanced Dungeon & MVP Boss Treasure Chest system initialized successfully")
