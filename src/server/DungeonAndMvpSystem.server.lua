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
		DataStore.AddGold(player, goldBonus)

		-- Grant Refinement stones
		local pData = DataStore.GetPlayerData(player)
		if pData then
			pData.Inventory = pData.Inventory or {}
			table.insert(pData.Inventory, { itemId = "BeginnerRefinementStone", quantity = 3 })
			
			local cardId = (bossId == "GoldenThiefBug" and "GoldenThiefBugCard") or (bossId == "Drake" and "DrakeCard") or "EddgaCard"
			if math.random(1, 100) <= 60 then
				table.insert(pData.Inventory, { itemId = cardId, quantity = 1 })
				if RE_SkillFeedback then
					RE_SkillFeedback:FireClient(player, string.format("🎉 ยอดเยี่ยม! คุณได้รับ %s จากหีบสมบัติ MVP!", cardId))
				end
			end
			DataStore.SyncAttributes(player, pData)
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

-- ── 2. MVP BOSS SPAWN DEFINITIONS ────────────────────────────
local MVP_SPAWNS = {
	{
		id = "GoldenThiefBug",
		name = "Golden Thief Bug (Culvert MVP)",
		map = "PronteraCulvert",
		pos = Vector3.new(0, 5, -760),
		scale = 2.4,
		color = Color3.fromRGB(255, 200, 40),
	},
	{
		id = "Drake",
		name = "Captain Drake (Dungeon Boss)",
		map = "PronteraCulvert",
		pos = Vector3.new(0, 5, -840),
		scale = 2.2,
		color = Color3.fromRGB(130, 70, 210),
	},
	{
		id = "Eddga",
		name = "Eddga (Morroc World Boss)",
		map = "Morroc",
		pos = Vector3.new(950, 5, -150),
		scale = 2.6,
		color = Color3.fromRGB(240, 95, 30),
	},
}

local function spawnMVPBoss(spec)
	local mData = MonsterData[spec.id]
	if not mData then return end

	local bossModel = Instance.new("Model")
	bossModel.Name = spec.id
	bossModel.Parent = mvpFolder

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(4 * spec.scale, 4 * spec.scale, 4 * spec.scale)
	root.CFrame = CFrame.new(spec.pos + Vector3.new(0, 2.5 * spec.scale, 0))
	root.Material = Enum.Material.Neon
	root.Color = spec.color
	root.Anchored = false
	root.CanCollide = true
	root.Parent = bossModel
	bossModel.PrimaryPart = root

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = mData.MaxHP
	humanoid.Health = mData.MaxHP
	humanoid.WalkSpeed = mData.MoveSpeed or 9
	humanoid.Parent = bossModel

	-- Set Boss Attributes
	bossModel:SetAttribute("MonsterID", spec.id)
	bossModel:SetAttribute("HP", mData.MaxHP)
	bossModel:SetAttribute("MaxHP", mData.MaxHP)
	bossModel:SetAttribute("ATK", mData.ATK)
	bossModel:SetAttribute("DEF", mData.DEF)
	bossModel:SetAttribute("MDEF", mData.MDEF)
	bossModel:SetAttribute("Element", mData.Element or "Neutral")
	bossModel:SetAttribute("Level", mData.Level or 50)
	bossModel:SetAttribute("IsBoss", true)
	bossModel:SetAttribute("IsMVP", true)
	bossModel:SetAttribute("MapName", spec.map)

	-- Overhead Title Billboard
	local bb = Instance.new("BillboardGui")
	bb.Name = "BossBillboard"
	bb.Size = UDim2.new(0, 320, 0, 58)
	bb.StudsOffset = Vector3.new(0, 3.5 * spec.scale, 0)
	bb.MaxDistance = 70
	bb.AlwaysOnTop = false
	bb.Parent = root

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 24)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "👑 " .. (mData.Name or spec.name)
	nameLabel.TextColor3 = Color3.fromRGB(255, 215, 60)
	nameLabel.TextStrokeTransparency = 0.1
	nameLabel.TextStrokeColor3 = Color3.fromRGB(15, 20, 30)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 15
	nameLabel.Parent = bb

	local hpBarBg = Instance.new("Frame")
	hpBarBg.Size = UDim2.new(0.85, 0, 0, 10)
	hpBarBg.Position = UDim2.new(0.075, 0, 0, 28)
	hpBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	hpBarBg.BorderSizePixel = 0
	hpBarBg.Parent = bb

	local hpFill = Instance.new("Frame")
	hpFill.Name = "Fill"
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.BackgroundColor3 = Color3.fromRGB(240, 50, 50)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBarBg

	-- Boss Heartbeat & Death listener
	local isDead = false
	bossModel:GetAttributeChangedSignal("HP"):Connect(function()
		local curHP = bossModel:GetAttribute("HP") or 0
		local maxHP = bossModel:GetAttribute("MaxHP") or 1
		hpFill.Size = UDim2.new(math.clamp(curHP / maxHP, 0, 1), 0, 1, 0)

		if curHP <= 0 and not isDead then
			isDead = true
			local killerName = bossModel:GetAttribute("LastHitPlayer") or "เหล่านักผจญภัย"
			local killerClass = bossModel:GetAttribute("LastHitClass") or "Adventurer"

			if RE_SkillFeedback then
				RE_SkillFeedback:FireAllClients(string.format("🏆 [MVP DEFEATED] บอส %s ถูกปราบแล้วโดย %s (%s)!", spec.name, killerName, killerClass))
			end

			spawnTreasureChest(root.Position, spec.id, nil)
			bossModel:Destroy()

			-- Schedule respawn
			task.delay(mData.RespawnTime or 90, function()
				spawnMVPBoss(spec)
			end)
		end
	end)

	print("[DungeonAndMvpSystem] Spawned MVP Boss:", spec.name, "at", tostring(spec.pos))
end

-- Spawn all MVP Bosses
for _, spec in ipairs(MVP_SPAWNS) do
	task.spawn(function()
		task.wait(1.5)
		spawnMVPBoss(spec)
	end)
end

print("[DungeonAndMvpSystem] Instanced Dungeon & MVP Boss Raid system initialized successfully")
