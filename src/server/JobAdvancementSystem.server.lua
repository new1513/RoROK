-- ============================================================
-- JobAdvancementSystem.server.lua
-- ServerScriptService — RoROK (Ragnarok Online-inspired MMORPG)
-- ระบบเลื่อนขั้นสู่อาชีพระดับสูง (2nd Job Class Promotion System)
-- NPC: มหาปุโรหิตเอเลน่า (Grand Master Elena) ณ โบสถ์ Prontera
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local GameData    = ReplicatedStorage:WaitForChild("GameData")
local ClassData   = require(GameData:WaitForChild("ClassData"))
local ItemData    = require(GameData:WaitForChild("ItemData"))

local DataStore
local GameManager

local t0 = tick()
repeat
	task.wait(0.1)
	DataStore = _G.DataStore
	GameManager = _G.GameManager
until (DataStore and GameManager) or (tick() - t0 > 15)

local remotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "RemoteEvents"
	remotesFolder.Parent = ReplicatedStorage
end

local function getRemote(name)
	local r = remotesFolder:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = remotesFolder
	end
	return r
end

local RE_OpenJobAdvance      = getRemote("OpenJobAdvanceDialogue")
local RE_RequestJobAdvance   = getRemote("RequestJobAdvance")
local RE_SkillFeedback       = getRemote("SkillFeedback")

-- ── 1. SPAWN GRAND MASTER ELENA NPC ──────────────────────────
local function spawnJobMasterElena()
	local old = Workspace:FindFirstChild("GrandMaster_Elena")
	if old then old:Destroy() end

	local npc = Instance.new("Model")
	npc.Name = "GrandMaster_Elena"
	npc.Parent = Workspace

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.CFrame = CFrame.new(-18, 3, 48) * CFrame.Angles(0, math.rad(90), 0)
	torso.Material = Enum.Material.SmoothPlastic
	torso.Color = Color3.fromRGB(245, 245, 255)
	torso.Anchored = true
	torso.CanCollide = true
	torso.Parent = npc
	npc.PrimaryPart = torso

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.CFrame = CFrame.new(-18, 4.6, 48)
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(250, 220, 195)
	head.Anchored = true
	head.CanCollide = false
	head.Parent = npc

	-- Golden Crown / Halo
	local halo = Instance.new("Part")
	halo.Name = "Halo"
	halo.Size = Vector3.new(1.8, 0.2, 1.8)
	halo.CFrame = CFrame.new(-18, 5.4, 48)
	halo.Material = Enum.Material.Neon
	halo.Color = Color3.fromRGB(255, 220, 80)
	halo.Anchored = true
	halo.CanCollide = false
	halo.Parent = npc

	-- Priestess Robe Lower
	local robe = Instance.new("Part")
	robe.Name = "Legs"
	robe.Size = Vector3.new(2.1, 2.2, 1.2)
	robe.CFrame = CFrame.new(-18, 1, 48)
	robe.Material = Enum.Material.SmoothPlastic
	robe.Color = Color3.fromRGB(50, 90, 175)
	robe.Anchored = true
	robe.CanCollide = false
	robe.Parent = npc

	-- Sacred Staff
	local staff = Instance.new("Part")
	staff.Name = "SacredStaff"
	staff.Size = Vector3.new(0.3, 5.5, 0.3)
	staff.CFrame = CFrame.new(-19.2, 3.2, 48)
	staff.Material = Enum.Material.Neon
	staff.Color = Color3.fromRGB(255, 215, 100)
	staff.Anchored = true
	staff.CanCollide = false
	staff.Parent = npc

	-- Overhead Title Billboard
	local bb = Instance.new("BillboardGui")
	bb.Name = "JobAdvancementBillboard"
	bb.Size = UDim2.new(0, 280, 0, 52)
	bb.StudsOffset = Vector3.new(0, 2.8, 0)
	bb.MaxDistance = 45
	bb.AlwaysOnTop = false
	bb.Parent = head

	local bbText = Instance.new("TextLabel")
	bbText.Size = UDim2.new(1, 0, 1, 0)
	bbText.BackgroundTransparency = 1
	bbText.Text = "🌟 มหาปุโรหิตเอเลน่า\n[ผู้ประกอบพิธีเลื่อนขั้นอาชีพ 2nd Job]"
	bbText.TextColor3 = Color3.fromRGB(255, 230, 120)
	bbText.TextStrokeTransparency = 0.2
	bbText.TextStrokeColor3 = Color3.fromRGB(15, 20, 35)
	bbText.Font = Enum.Font.GothamBold
	bbText.TextSize = 13
	bbText.Parent = bb

	-- ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "มหาปุโรหิตเอเลน่า"
	prompt.ActionText = "ประกอบพิธีเลื่อนขั้นอาชีพ (2nd Job)"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = torso

	prompt.Triggered:Connect(function(player)
		local data = DataStore.GetPlayerData(player)
		if not data then return end

		local currentClass = data.Class or "Novice"
		local jobLevel = tonumber(data.JobLevel) or 1
		local classDef = ClassData.Classes[currentClass]
		local advanceOpts = classDef and classDef.AdvanceOptions or {}
		local targetClass = advanceOpts[1]

		local state = "Ready"
		local targetInfo = targetClass and ClassData.Classes[targetClass]

		if currentClass == "Novice" then
			state = "IsNovice"
		elseif #advanceOpts == 0 then
			state = "AlreadyMaxJob"
		elseif jobLevel < 40 then
			state = "JobLevelLow"
		else
			state = "Eligible"
		end

		RE_OpenJobAdvance:FireClient(player, {
			state        = state,
			currentClass = currentClass,
			currentThai  = classDef and classDef.NameThai or currentClass,
			jobLevel     = jobLevel,
			targetClass  = targetClass,
			targetThai   = targetInfo and targetInfo.NameThai or targetClass,
			targetDesc   = targetInfo and targetInfo.Description or "",
		})
	end)
end

-- คืนอุปกรณ์และระดับตีบวกเดิมกลับเข้ากระเป๋า ป้องกันของหายเมื่อสวมใส่อาวุธ 2nd Job
local function returnEquipmentToInventory(data, itemId, refineLevel)
	if not itemId then return end
	data.Inventory = data.Inventory or {}
	local refineNum = tonumber(refineLevel) or 0
	for _, owned in ipairs(data.Inventory) do
		if type(owned) == "table" and owned.itemId == itemId and (tonumber(owned.enhancement) or 0) == refineNum then
			owned.quantity = (tonumber(owned.quantity) or 0) + 1
			return
		end
	end
	table.insert(data.Inventory, { itemId = itemId, quantity = 1, enhancement = refineNum })
end

-- ── 2. HANDLE JOB ADVANCE REQUEST ─────────────────────────────
RE_RequestJobAdvance.OnServerEvent:Connect(function(player, requestedClass)
	local data = DataStore.GetPlayerData(player)
	if not data then return end

	local canAdvance, reason = ClassData.CanChangeClass(data.Class, requestedClass, data.JobLevel or 1)
	if not canAdvance then
		RE_SkillFeedback:FireClient(player, "⚠️ ไม่สามารถเลื่อนขั้นได้: " .. tostring(reason))
		return
	end

	-- Execute Class Change
	data.Class = requestedClass
	data.JobLevel = 1
	data.JobXP = 0
	data.StatPoints = (data.StatPoints or 0) + 15
	data.SkillPoints = (data.SkillPoints or 0) + 1

	data.Equipment = data.Equipment or {}
	data.EquipmentRefine = data.EquipmentRefine or {}

	local starterWeapon = ({
		LordKnight = "HalberdOfValor",
		Priest     = "HolyJudgementCross",
		Wizard     = "ArchMageStaff",
		Hunter     = "HunterGaleBow",
		Assassin   = "KatarOfShadows",
		Blacksmith = "WarhammerOfTitans",
	})[requestedClass]

	if starterWeapon then
		local oldWeaponId = data.Equipment.Weapon
		local oldRefine = tonumber(data.EquipmentRefine.Weapon) or 0
		if oldWeaponId then
			returnEquipmentToInventory(data, oldWeaponId, oldRefine)
		end

		data.Equipment.Weapon = starterWeapon
		data.EquipmentRefine.Weapon = 1 -- Granted with +1 refine!
	end

	DataStore.SyncAttributes(player, data)
	if GameManager and GameManager.PushCharacterData then
		GameManager.PushCharacterData(player)
	end

	-- Update inventory UI on client
	local RE_UpdateInventory = remotesFolder:FindFirstChild("UpdateInventory")
	if RE_UpdateInventory then
		local weaponName = (ItemData[starterWeapon] and ItemData[starterWeapon].name) or starterWeapon or ""
		RE_UpdateInventory:FireClient(player, data.Inventory or {}, data.Equipment or {}, "เลื่อนขั้นสำเร็จ! ได้รับ " .. weaponName .. " (+1)", data.EquipmentRefine or {}, data.EquipmentCards or {})
	end

	-- Rebuild weapon model on character
	if _G.RebuildCharacterWeaponRig then
		_G.RebuildCharacterWeaponRig(player)
	end

	local classThai = (ClassData.Classes[requestedClass] and ClassData.Classes[requestedClass].NameThai) or requestedClass
	RE_SkillFeedback:FireAllClients(string.format("🌟 [เลื่อนขั้นอาชีพ] ขอแสดงความยินดีกับ %s ที่ได้บรรลุการเลื่อนขั้นสู่อาชีพระดับสูง %s!", player.Name, classThai))
	RE_SkillFeedback:FireClient(player, string.format("🎉 ยินดีด้วย! คุณเลื่อนขั้นเป็น %s แล้ว พร้อมรับอาวุธระดับสูงและ +15 Stat Points!", classThai))
end)

spawnJobMasterElena()
print("[JobAdvancementSystem] Grand Master Elena 2nd Job Promotion NPC initialized successfully")
