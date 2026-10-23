-- ============================================================
-- CombatTargeting.lua
-- RoROK — Monster Targeting, Attack Rings, Auto-Battle System
-- ============================================================

local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatTargeting = {}

function CombatTargeting.init(player, playerGui, remotes, UITheme, hotbarView, hudView, callbacks)
	local hex = UITheme.hex
	local makeInstance = UITheme.makeInstance
	callbacks = callbacks or {}

	local classData = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("ClassData"))
	local monsterData = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("MonsterData"))
	local skillData = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("SkillData"))

	local requestAttackRemote = remotes.requestAttackRemote or remotes.RequestAttack
	local useSkillRemote = remotes.useSkillRemote or remotes.UseSkill

	local selectedTargetModel = nil
	local selectedMonsterName = nil
	local pendingSkillId = nil
	local rangeSkillId = nil
	local MONSTER_TARGET_RANGE = 65

	-- ── Target Hint Toast ─────────────────────────────────────
	local targetHint = makeInstance("TextLabel", {
		Name = "TargetHint", Size = UDim2.new(0, 360, 0, 30),
		Position = UDim2.new(0.5, -180, 1, -154), BackgroundColor3 = hex("172033"),
		BackgroundTransparency = 0.12, TextColor3 = hex("ffe082"),
		Font = Enum.Font.GothamBold, TextSize = 14, Visible = false,
		Text = "", ZIndex = 25,
	}, hudView.hudGui)
	makeInstance("UICorner", {CornerRadius = UDim.new(0, 7)}, targetHint)

	local function showNotice(text, duration)
		if hotbarView and hotbarView.showNotice then
			hotbarView.showNotice(text, duration)
		end
	end

	local autoAttackEnabled = false

	-- ── Cast Bar UI (หลอดร่ายเวทมนตร์ & DEX Scaling) ───────────
	local castBarContainer = makeInstance("Frame", {
		Name = "CastBarContainer",
		Size = UDim2.new(0, 320, 0, 24),
		Position = UDim2.new(0.5, -160, 1, -108),
		BackgroundColor3 = hex("0b101c"),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 30,
	}, hudView.hudGui)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, castBarContainer)
	local castBarStroke = makeInstance("UIStroke", { Color = hex("e5c158"), Thickness = 1.5 }, castBarContainer)

	local castBarFill = makeInstance("Frame", {
		Name = "Fill",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(0, 190, 255),
		BorderSizePixel = 0,
		ZIndex = 31,
	}, castBarContainer)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, castBarFill)

	local castBarLabel = makeInstance("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -12, 1, 0),
		Position = UDim2.new(0, 6, 0, 0),
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		Text = "กำลังร่ายเวท...",
		ZIndex = 32,
	}, castBarContainer)

	local isCasting = false
	local currentCastThread = nil
	local castGeneration = 0

	local function cancelCast(reason)
		if not isCasting then return end
		isCasting = false
		castGeneration += 1
		if currentCastThread then
			task.cancel(currentCastThread)
			currentCastThread = nil
		end
		castBarFill.Size = UDim2.new(1, 0, 1, 0)
		castBarFill.BackgroundColor3 = Color3.fromRGB(240, 60, 60)
		castBarStroke.Color = Color3.fromRGB(240, 60, 60)
		castBarLabel.Text = reason or "✕ การร่ายเวทถูกยกเลิก!"
		local gen = castGeneration
		task.delay(0.65, function()
			if castGeneration == gen and not isCasting then
				castBarContainer.Visible = false
				castBarStroke.Color = hex("e5c158")
				castBarFill.BackgroundColor3 = Color3.fromRGB(0, 190, 255)
			end
		end)
	end

	local function executeCast(skillId, definition, target, onFinished)
		local baseCastTime = tonumber(definition.castTime) or 0
		local dex = tonumber(player:GetAttribute("DEX")) or 1
		-- Ragnarok DEX Reduction: ActualCast = CastTime * max(0.20, 1 - DEX/150)
		local castReduction = math.clamp(1 - (dex / 150), 0.20, 1.0)
		local actualDuration = baseCastTime * castReduction

		if actualDuration <= 0.05 then
			if onFinished then onFinished() end
			return
		end

		cancelCast()
		isCasting = true
		castGeneration += 1
		local thisGen = castGeneration

		castBarContainer.Visible = true
		castBarFill.Size = UDim2.new(0, 0, 1, 0)
		castBarFill.BackgroundColor3 = Color3.fromRGB(0, 190, 255)
		castBarStroke.Color = hex("e5c158")
		local skillName = definition.nameThai or definition.name
		castBarLabel.Text = string.format("⚡ กำลังร่าย %s... (%.1fs)", skillName, actualDuration)

		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local startPos = root and root.Position or Vector3.zero

		currentCastThread = task.spawn(function()
			local startTime = os.clock()
			while isCasting and thisGen == castGeneration do
				local elapsed = os.clock() - startTime
				local progress = math.clamp(elapsed / actualDuration, 0, 1)
				castBarFill.Size = UDim2.new(progress, 0, 1, 0)
				castBarLabel.Text = string.format("⚡ กำลังร่าย %s... (%.1fs)", skillName, math.max(0, actualDuration - elapsed))

				if not autoAttackEnabled and root then
					if (root.Position - startPos).Magnitude > 2.0 then
						cancelCast("✕ การร่ายถูกยกเลิก (เคลื่อนที่)!")
						return
					end
				end

				if progress >= 1 then break end
				RunService.RenderStepped:Wait()
			end

			if isCasting and thisGen == castGeneration then
				isCasting = false
				castBarFill.Size = UDim2.new(1, 0, 1, 0)
				castBarFill.BackgroundColor3 = Color3.fromRGB(80, 240, 120)
				castBarStroke.Color = Color3.fromRGB(80, 240, 120)
				castBarLabel.Text = "✓ ร่ายสำเร็จ!"
				if onFinished then onFinished() end
				task.delay(0.35, function()
					if not isCasting and thisGen == castGeneration then
						castBarContainer.Visible = false
						castBarStroke.Color = hex("e5c158")
						castBarFill.BackgroundColor3 = Color3.fromRGB(0, 190, 255)
					end
				end)
			end
		end)
	end

	-- ── Auto Potion System ────────────────────────────────────
	local autoPotionEnabled = true
	local autoPotionLastUsedAt = 0
	local POTION_COOLDOWN = 1.2
	local HP_POTION_ORDER = { "WhitePotion", "YellowPotion", "OrangePotion", "RedPotion", "Carrot", "Apple" }
	local SP_POTION_ORDER = { "BluePotion" }

	local function checkAndUseAutoPotion()
		if not autoPotionEnabled then return end
		local now = os.clock()
		if now - autoPotionLastUsedAt < POTION_COOLDOWN then return end

		local hp = tonumber(player:GetAttribute("HP")) or 0
		local maxHP = math.max(tonumber(player:GetAttribute("MaxHP")) or 1, 1)
		local sp = tonumber(player:GetAttribute("SP")) or 0
		local maxSP = math.max(tonumber(player:GetAttribute("MaxSP")) or 1, 1)

		local inv = callbacks.getInventory and callbacks.getInventory() or {}
		local useRemote = remotes.useConsumableRemote or remotes.UseConsumable
		if not useRemote then return end

		-- HP check: below 50%
		if (hp / maxHP) < 0.50 then
			for _, potionId in ipairs(HP_POTION_ORDER) do
				for _, entry in ipairs(inv) do
					if entry.itemId == potionId and (tonumber(entry.quantity) or 0) > 0 then
						autoPotionLastUsedAt = now
						useRemote:FireServer(potionId)
						showNotice(string.format("🥤 Auto-Potion: ดื่ม %s ฟื้นฟู HP!", potionId))
						return
					end
				end
			end
		end

		-- SP check: below 30%
		if (sp / maxSP) < 0.30 then
			for _, potionId in ipairs(SP_POTION_ORDER) do
				for _, entry in ipairs(inv) do
					if entry.itemId == potionId and (tonumber(entry.quantity) or 0) > 0 then
						autoPotionLastUsedAt = now
						useRemote:FireServer(potionId)
						showNotice(string.format("🧪 Auto-Potion: ดื่ม %s ฟื้นฟู SP!", potionId))
						return
					end
				end
			end
		end
	end

	task.spawn(function()
		while true do
			checkAndUseAutoPotion()
			task.wait(0.6)
		end
	end)

	-- ── Target Validity ───────────────────────────────────────
	local function canAcquireMonsterTarget(monster, character, playerRoot)
		if not monster or not playerRoot or (monster:GetAttribute("HP") or 0) <= 0 then return false end
		local monsterRoot = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart
		if not monsterRoot then return false end
		local offset = monsterRoot.Position - playerRoot.Position
		return offset.Magnitude <= MONSTER_TARGET_RANGE
	end

	-- ── Target Indicator Ring (Ground Neon Ring) ──────────────
	local targetIndicatorFolder = Instance.new("Folder")
	targetIndicatorFolder.Name = "LocalTargetIndicator"
	targetIndicatorFolder.Parent = Workspace

	local targetIndicatorParts = {}
	local function clearTargetIndicator()
		for _, part in ipairs(targetIndicatorParts) do
			if part.Parent then part:Destroy() end
		end
		table.clear(targetIndicatorParts)
	end

	local function setSelectedTarget(monster)
		if selectedTargetModel == monster then return end
		selectedTargetModel = monster
		selectedMonsterName = monster and monster.Name or nil
		clearTargetIndicator()
		if not monster then return end

		local segmentCount = 48
		local radius = 2.2
		local segmentLength = 2 * radius * math.sin(math.pi / segmentCount) * 1.12
		for index = 1, segmentCount do
			local part = Instance.new("Part")
			part.Name = "TargetRingSegment"
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.CastShadow = false
			part.Material = Enum.Material.Neon
			part.Color = Color3.fromRGB(255, 55, 65)
			part.Size = Vector3.new(segmentLength, 0.055, 0.09)
			part.Parent = targetIndicatorFolder
			table.insert(targetIndicatorParts, part)
		end
	end

	RunService.RenderStepped:Connect(function()
		local monster = selectedTargetModel
		if not monster then return end
		local root = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart
		local targetPlr = game:GetService("Players"):GetPlayerFromCharacter(monster)
		local isAlive = false
		if targetPlr then
			isAlive = (targetPlr:GetAttribute("HP") or 0) > 0
		else
			isAlive = (monster:GetAttribute("HP") or 0) > 0
		end
		if not monster.Parent or not isAlive or not root then
			setSelectedTarget(nil)
			return
		end

		local groundParams = RaycastParams.new()
		groundParams.FilterType = Enum.RaycastFilterType.Exclude
		groundParams.FilterDescendantsInstances = {monster, targetIndicatorFolder}
		local rayOrigin = Vector3.new(root.Position.X, root.Position.Y + 8, root.Position.Z)
		local groundHit = Workspace:Raycast(rayOrigin, Vector3.new(0, -25, 0), groundParams)
		local ringY = groundHit and (groundHit.Position.Y + 0.08) or (root.Position.Y - 2.8)

		local segmentCount = #targetIndicatorParts
		local radius = 2.2
		local now = os.clock()
		for index, part in ipairs(targetIndicatorParts) do
			local angle = (index / segmentCount) * math.pi * 2 + now * 1.2
			local px = root.Position.X + math.cos(angle) * radius
			local pz = root.Position.Z + math.sin(angle) * radius
			part.CFrame = CFrame.new(px, ringY, pz) * CFrame.Angles(0, -angle + math.pi/2, 0)
		end
	end)

	-- ── Character Attack Range Ring ───────────────────────────
	local rangeRoot = nil
	local rangeAttachments = {}
	local rangeBeams = {}
	local RANGE_SEGMENTS = 48
	local rangeColorByClass = {
		Novice = hex("fff1a8"), Acolyte = hex("8ffff2"), Knight = hex("ff7777"),
		Mage = hex("b78cff"), Archer = hex("8dff9c"), Thief = hex("eeeeee"), Merchant = hex("ffc36b"),
	}

	local function clearRangeRing()
		for _, object in ipairs(rangeBeams) do if object.Parent then object:Destroy() end end
		for _, object in ipairs(rangeAttachments) do if object.Parent then object:Destroy() end end
		table.clear(rangeAttachments)
		table.clear(rangeBeams)
		rangeRoot = nil
	end

	local function buildRangeRing(root)
		clearRangeRing()
		rangeRoot = root
		for index = 1, RANGE_SEGMENTS do
			local attachment = Instance.new("Attachment")
			attachment.Name = "RoROKRangePoint" .. index
			attachment.Parent = root
			rangeAttachments[index] = attachment
		end
		for index = 1, RANGE_SEGMENTS do
			local beam = Instance.new("Beam")
			beam.Name = "RoROKRangeLine" .. index
			beam.Attachment0 = rangeAttachments[index]
			beam.Attachment1 = rangeAttachments[(index % RANGE_SEGMENTS) + 1]
			beam.FaceCamera = true
			beam.Width0 = 0.18
			beam.Width1 = 0.18
			beam.Segments = 1
			beam.LightEmission = 0.65
			beam.LightInfluence = 0
			beam.Parent = root
			rangeBeams[index] = beam
		end
	end

	local rangeElapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		rangeElapsed += dt
		if rangeElapsed < 0.08 then return end
		rangeElapsed = 0

		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local rangeHumanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or (rangeHumanoid and rangeHumanoid.Health <= 0) then
			clearRangeRing()
			return
		end

		if rangeRoot ~= root then buildRangeRing(root) end
		local className = player:GetAttribute("Class") or "Novice"
		local skillDefinition = rangeSkillId and skillData[rangeSkillId]
		local radius = skillDefinition and tonumber(skillDefinition.range) or classData.GetBasicAttackRange(className)

		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local ignoreList = {character}
		local monstersFolder = Workspace:FindFirstChild("Monsters")
		if monstersFolder then table.insert(ignoreList, monstersFolder) end
		rayParams.FilterDescendantsInstances = ignoreList

		local floorHit = Workspace:Raycast(root.Position + Vector3.new(0, 2, 0), Vector3.new(0, -12, 0), rayParams)
		local floorOffset = (floorHit and floorHit.Position.Y or root.Position.Y - 3) - root.Position.Y + 0.07
		local color = rangeColorByClass[className] or Color3.new(1, 1, 1)

		for index, attachment in ipairs(rangeAttachments) do
			local angle = (index - 1) * (2 * math.pi / RANGE_SEGMENTS)
			attachment.Position = Vector3.new(math.cos(angle) * radius, floorOffset, math.sin(angle) * radius)
			local beam = rangeBeams[index]
			beam.Color = ColorSequence.new(color)
			beam.Transparency = NumberSequence.new(0.12)
		end
	end)

	-- ── Auto Attack & Manual Pursuit State ────────────────────
	autoAttackEnabled = false
	local autoLockedMonster = nil
	local manualPursuitActive = false
	local manualPursuitGeneration = 0
	local autoAttackGeneration = 0
	local autoAttackAll = false
	local autoBasicNextAt = 0
	local autoProfiles = {}
	local autoTargetTypes = {}
	local autoSkillCooldownUntil = {}
	local autoSkillAttemptUntil = {}

	for monsterId in pairs(monsterData) do autoTargetTypes[monsterId] = false end

	local function autoAttackInterval()
		local aspd = math.clamp(player:GetAttribute("ASPD") or 100, 60, 190)
		return 60 / aspd
	end

	local function startManualAttackPursuit(monster)
		if autoAttackEnabled or not monster then return end
		manualPursuitGeneration += 1
		local generation = manualPursuitGeneration
		manualPursuitActive = true
		task.spawn(function()
			local nextAttackAt = 0
			while manualPursuitActive and generation == manualPursuitGeneration do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local monsterRoot = monster and (monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart)
				if not root or not humanoid or not monster or not monster.Parent or not monsterRoot
					or (monster:GetAttribute("HP") or 0) <= 0 or humanoid.Health <= 0 then
					break
				end
				local className = player:GetAttribute("Class") or "Novice"
				local range = classData.GetBasicAttackRange(className)
				local dist = (monsterRoot.Position - root.Position).Magnitude
				if dist > range then
					local towardPlayer = (root.Position - monsterRoot.Position).Unit
					humanoid:MoveTo(monsterRoot.Position + towardPlayer * math.max(range - 2, 2))
				elseif os.clock() >= nextAttackAt and requestAttackRemote then
					local lookVec = Vector3.new(monsterRoot.Position.X - root.Position.X, 0, monsterRoot.Position.Z - root.Position.Z)
					if lookVec.Magnitude > 0.1 then
						root.CFrame = CFrame.lookAt(root.Position, root.Position + lookVec.Unit)
					end
					requestAttackRemote:FireServer(monster)
					nextAttackAt = os.clock() + autoAttackInterval()
				end
				task.wait(0.18)
			end
			if generation == manualPursuitGeneration then manualPursuitActive = false end
		end)
	end

	-- ── Cast Hotbar Slot ──────────────────────────────────────
	local function castHotbarSlot(slotIndex)
		if not useSkillRemote then return end
		local class = player:GetAttribute("Class") or "Novice"
		local slots = hotbarView.getSkillByClass()[class]
		local skill = slots and slots[slotIndex]
		if not skill then
			if callbacks.onOpenSkillTree then callbacks.onOpenSkillTree() end
			return
		end
		local definition = skillData[skill]
		if not definition then return end
		local currentOwned = hotbarView.getCurrentOwnedSkills()
		local lv = tonumber(currentOwned[skill]) or 0
		if skill == "NoviceStrike" or skill == "FirstAid" or slotIndex == 1 then
			lv = math.max(1, lv)
		end
		if lv <= 0 then
			showNotice("ยังไม่ได้อัปสกิล " .. (definition.nameThai or definition.name) .. " — กด + ในผังสกิลเพื่อเรียนรู้!")
			if callbacks.onOpenSkillTree then callbacks.onOpenSkillTree() end
			return
		end

		if definition.isAttack then
			rangeSkillId = skill
			task.delay(0.9, function() if rangeSkillId == skill then rangeSkillId = nil end end)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not selectedTargetModel or not selectedTargetModel.Parent or (selectedTargetModel:GetAttribute("HP") or 0) <= 0
				or not canAcquireMonsterTarget(selectedTargetModel, character, root) then
				local mFolder = Workspace:FindFirstChild("Monsters")
				local bestM, bestDist = nil, MONSTER_TARGET_RANGE
				if root and mFolder then
					for _, m in ipairs(mFolder:GetChildren()) do
						local mRoot = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
						if m:GetAttribute("MonsterID") and (m:GetAttribute("HP") or 0) > 0 and mRoot then
							local d = (mRoot.Position - root.Position).Magnitude
							if d <= bestDist then
								bestDist = d
								bestM = m
							end
						end
					end
				end
				if bestM then setSelectedTarget(bestM) end
			end

			local target = selectedTargetModel
			if target and root and humanoid then
				local mRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
				local sRange = tonumber(definition.range) or classData.GetBasicAttackRange(class)
				if mRoot then
					local dist = (mRoot.Position - root.Position).Magnitude
					if dist > sRange and humanoid.Health > 0 then
						local towardPlayer = (root.Position - mRoot.Position).Unit
						humanoid:MoveTo(mRoot.Position + towardPlayer * math.max(sRange - 2, 2))
						task.spawn(function()
							local t0 = os.clock()
							while os.clock() - t0 < 2.2 and target.Parent and (target:GetAttribute("HP") or 0) > 0 do
								if (mRoot.Position - root.Position).Magnitude <= sRange + 2 then
									local lookVec = Vector3.new(mRoot.Position.X - root.Position.X, 0, mRoot.Position.Z - root.Position.Z)
									if lookVec.Magnitude > 0.1 then
										root.CFrame = CFrame.lookAt(root.Position, root.Position + lookVec.Unit)
									end
									useSkillRemote:FireServer(skill, target.Name)
									if not autoAttackEnabled then startManualAttackPursuit(target) end
									break
								end
								task.wait(0.1)
							end
						end)
						return
					else
						local lookVec = Vector3.new(mRoot.Position.X - root.Position.X, 0, mRoot.Position.Z - root.Position.Z)
						if lookVec.Magnitude > 0.1 then
							root.CFrame = CFrame.lookAt(root.Position, root.Position + lookVec.Unit)
						end
						if definition.castTime and tonumber(definition.castTime) > 0 then
							executeCast(skill, definition, target, function()
								useSkillRemote:FireServer(skill, target)
								if not autoAttackEnabled then startManualAttackPursuit(target) end
							end)
						else
							useSkillRemote:FireServer(skill, target)
							if not autoAttackEnabled then startManualAttackPursuit(target) end
						end
						return
					end
				end
			end
			if definition.castTime and tonumber(definition.castTime) > 0 then
				executeCast(skill, definition, selectedTargetModel, function()
					useSkillRemote:FireServer(skill, selectedTargetModel or "")
				end)
			else
				useSkillRemote:FireServer(skill, selectedTargetModel or "")
			end
		else
			if definition.castTime and tonumber(definition.castTime) > 0 then
				executeCast(skill, definition, nil, function()
					useSkillRemote:FireServer(skill, selectedTargetModel or "")
				end)
			else
				useSkillRemote:FireServer(skill, selectedTargetModel or "")
			end
		end
	end

	_G.CastHotbarSlot = castHotbarSlot

	-- ── Mouse Click Selection ─────────────────────────────────
	local mouse = player:GetMouse()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local target = mouse.Target
		local model = target and target:FindFirstAncestorOfClass("Model")
		local character = player.Character
		local playerRoot = character and character:FindFirstChild("HumanoidRootPart")

		-- ตรวจสอบเป้าหมายผู้เล่นคนอื่นในโหมด PvP
		local targetPlr = model and game:GetService("Players"):GetPlayerFromCharacter(model)
		if targetPlr and targetPlr ~= player and player:GetAttribute("InPvP") and targetPlr:GetAttribute("InPvP") then
			local tRoot = model:FindFirstChild("HumanoidRootPart")
			if tRoot and playerRoot and (tRoot.Position - playerRoot.Position).Magnitude <= MONSTER_TARGET_RANGE then
				setSelectedTarget(model)
				if pendingSkillId and useSkillRemote then
					local skill = pendingSkillId
					pendingSkillId = nil
					rangeSkillId = nil
					targetHint.Visible = false
					useSkillRemote:FireServer(skill, model)
				elseif requestAttackRemote then
					requestAttackRemote:FireServer(model)
				end
				return
			end
		end

		if model and model:GetAttribute("MonsterID") and canAcquireMonsterTarget(model, character, playerRoot) then
			setSelectedTarget(model)
			if autoAttackEnabled then autoLockedMonster = model end
			if pendingSkillId and useSkillRemote then
				local skill = pendingSkillId
				pendingSkillId = nil
				rangeSkillId = nil
				targetHint.Visible = false
				useSkillRemote:FireServer(skill, model.Name)
			elseif requestAttackRemote then
				if not autoAttackEnabled then startManualAttackPursuit(model) end
			end
		end
	end)

	-- ── Auto Battle Settings Window ───────────────────────────
	local autoSettingsWin = makeInstance("Frame", {
		Name = "AutoSettings",
		Size = UDim2.new(0, 480, 0, 520),
		Position = UDim2.new(0.5, -240, 0.5, -260),
		BackgroundColor3 = hex("0d1322"),
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 5,
	}, playerGui:WaitForChild("Windows", 5) or hudView.hudGui)
	makeInstance("UICorner", {CornerRadius = UDim.new(0, 12)}, autoSettingsWin)
	makeInstance("UIStroke", {Color = hex("e5c158"), Thickness = 1.8}, autoSettingsWin)

	local autoSettingsTitleBar = makeInstance("Frame", {
		Name = "TitleBar", Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = hex("141d33"), BorderSizePixel = 0, ZIndex = 6,
	}, autoSettingsWin)
	makeInstance("UICorner", {CornerRadius = UDim.new(0, 12)}, autoSettingsTitleBar)
	makeInstance("TextLabel", {
		Size = UDim2.new(1, -48, 1, 0), Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1, TextColor3 = hex("f3cf7a"), Font = Enum.Font.GothamBold,
		TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "⚙ ตั้งค่าการต่อสู้อัตโนมัติ", ZIndex = 7,
	}, autoSettingsTitleBar)

	local autoSettingsClose = makeInstance("TextButton", {
		Name = "CloseBtn", Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -34, 0, 6),
		BackgroundColor3 = hex("9e2a35"), TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold, TextSize = 13, Text = "✕", ZIndex = 7,
	}, autoSettingsTitleBar)
	makeInstance("UICorner", {CornerRadius = UDim.new(1, 0)}, autoSettingsClose)
	autoSettingsClose.Activated:Connect(function() autoSettingsWin.Visible = false end)

	local autoSettingsContent = makeInstance("Frame", {
		Name = "Content", Size = UDim2.new(1, -20, 1, -50), Position = UDim2.new(0, 10, 0, 44),
		BackgroundTransparency = 1, ZIndex = 5,
	}, autoSettingsWin)

	makeInstance("TextLabel", {
		Name = "AutoTargetTitle", Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1, Text = "เป้าหมาย • แสดง/เลือกได้ในระยะ 50 studs และไม่มีสิ่งบัง",
		TextColor3 = hex("ffe082"), Font = Enum.Font.GothamBold, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, autoSettingsContent)

	local allTargetsButton = makeInstance("TextButton", {
		Name = "AutoTargetAll", Size = UDim2.new(0, 106, 0, 30),
		Position = UDim2.new(0, 0, 0, 24), BackgroundColor3 = hex("343445"),
		TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 11, ZIndex = 6,
		Visible = true,
	}, autoSettingsContent)
	makeInstance("UICorner", {CornerRadius = UDim.new(0, 6)}, allTargetsButton)

	local targetTypesFrame = makeInstance("ScrollingFrame", {
		Name = "AutoTargetTypes", Size = UDim2.new(1, -116, 0, 34), Position = UDim2.new(0, 114, 0, 24),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 6,
	}, autoSettingsContent)
	makeInstance("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, targetTypesFrame)

	local targetTypeButtons = {}
	local monsterIds = {}
	for monsterId in pairs(monsterData) do table.insert(monsterIds, monsterId) end
	table.sort(monsterIds)
	for index, monsterId in ipairs(monsterIds) do
		local button = makeInstance("TextButton", {
			Name = "AutoTarget_" .. monsterId, Size = UDim2.new(0, 100, 0, 28),
			BackgroundColor3 = hex("343445"), TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBold, TextSize = 11, LayoutOrder = index, ZIndex = 7,
			Visible = true,
		}, targetTypesFrame)
		makeInstance("UICorner", {CornerRadius = UDim.new(0, 6)}, button)
		targetTypeButtons[monsterId] = button
	end

	local function updateAutoTargetButtons()
		allTargetsButton.Text = autoAttackAll and "☑ ทั้งหมด" or "□ ทั้งหมด"
		allTargetsButton.BackgroundColor3 = autoAttackAll and hex("315a4a") or hex("343445")
		for monsterId, button in pairs(targetTypeButtons) do
			button.Text = (autoTargetTypes[monsterId] and "☑ " or "□ ") .. monsterId
			button.BackgroundColor3 = autoTargetTypes[monsterId] and hex("315a4a") or hex("343445")
		end
	end
	updateAutoTargetButtons()

	local targetAvailabilityLabel = makeInstance("TextLabel", {
		Name = "VisibleTargetTypes", Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 0, 57),
		BackgroundTransparency = 1, TextColor3 = hex("aeb7d0"), Font = Enum.Font.Gotham,
		TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "แสดงชนิดมอนเฉพาะที่อยู่ในระยะหาเป้า 50 studs • “ทั้งหมด” เลือกได้เสมอ",
	}, autoSettingsContent)

	local updatePotionInfoDisplay
	local function refreshVisibleTargetFilters()
		if updatePotionInfoDisplay then updatePotionInfoDisplay() end
		local visibleTypes = {}
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local folder = Workspace:FindFirstChild("Monsters")
		if root and folder then
			for _, monster in ipairs(folder:GetChildren()) do
				local monsterId = monster:GetAttribute("MonsterID")
				if monsterId and targetTypeButtons[monsterId] and (monster:GetAttribute("HP") or 0) > 0
					and canAcquireMonsterTarget(monster, character, root) then
					visibleTypes[monsterId] = true
				end
			end
		end
		local visibleCount = 0
		for monsterId, button in pairs(targetTypeButtons) do
			button.Visible = visibleTypes[monsterId] == true
			if visibleTypes[monsterId] then visibleCount += 1 end
		end
		allTargetsButton.Visible = true
		if visibleCount == 0 then
			targetAvailabilityLabel.Text = "ไม่มีมอนในระยะหาเป้า 50 studs • เลือก “ทั้งหมด” ได้เสมอ"
		else
			local visibleNames = {}
			for monsterId in pairs(visibleTypes) do table.insert(visibleNames, monsterId) end
			table.sort(visibleNames)
			targetAvailabilityLabel.Text = "ชนิดมอนในระยะ 50 studs: " .. table.concat(visibleNames, ", ")
		end
		updateAutoTargetButtons()
	end
	refreshVisibleTargetFilters()

	allTargetsButton.Activated:Connect(function()
		autoAttackAll = not autoAttackAll
		updateAutoTargetButtons()
	end)

	for monsterId, button in pairs(targetTypeButtons) do
		local targetId = monsterId
		button.Activated:Connect(function()
			autoAttackAll = false
			autoTargetTypes[targetId] = not autoTargetTypes[targetId]
			updateAutoTargetButtons()
		end)
	end

	makeInstance("TextLabel", {
		Name = "AutoOrderTitle", Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 78),
		BackgroundTransparency = 1, Text = "ลำดับการโจมตี • เรียงจากบนลงล่าง (สกิลติดคูลดาวน์จะข้ามไปอันถัดไป)",
		TextColor3 = hex("cbd3ed"), Font = Enum.Font.GothamBold, TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, autoSettingsContent)

	local autoActionList = makeInstance("ScrollingFrame", {
		Name = "AutoActionList", Size = UDim2.new(1, 0, 0, 195), Position = UDim2.new(0, 0, 0, 102),
		BackgroundColor3 = hex("121222"), BackgroundTransparency = 0.15, BorderSizePixel = 0,
		ScrollBarThickness = 5, CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 5,
	}, autoSettingsContent)
	makeInstance("UICorner", {CornerRadius = UDim.new(0, 6)}, autoActionList)
	makeInstance("UIPadding", {
		PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5),
		PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5),
	}, autoActionList)
	makeInstance("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, autoActionList)

	-- ── Auto Potion UI Controls in Auto Settings ─────────────
	local autoPotionFrame = makeInstance("Frame", {
		Name = "AutoPotionFrame", Size = UDim2.new(1, 0, 0, 62), Position = UDim2.new(0, 0, 0, 305),
		BackgroundColor3 = hex("17223b"), BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 6,
	}, autoSettingsContent)
	makeInstance("UICorner", {CornerRadius = UDim.new(0, 8)}, autoPotionFrame)
	makeInstance("UIStroke", {Color = hex("2a4365"), Thickness = 1.2}, autoPotionFrame)

	local autoPotionButton = makeInstance("TextButton", {
		Name = "AutoPotionToggle", Size = UDim2.new(1, -12, 0, 28), Position = UDim2.new(0, 6, 0, 4),
		BackgroundColor3 = hex("287a48"), TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "☑ ดื่มยาอัตโนมัติ (Auto-Potion): เปิด (HP < 50% หรือ SP < 30%)", ZIndex = 7,
	}, autoPotionFrame)
	makeInstance("UICorner", {CornerRadius = UDim.new(0, 6)}, autoPotionButton)

	local autoPotionInfo = makeInstance("TextLabel", {
		Name = "AutoPotionInfo", Size = UDim2.new(1, -12, 0, 24), Position = UDim2.new(0, 8, 0, 32),
		BackgroundTransparency = 1, TextColor3 = hex("90cdf4"), Font = Enum.Font.Gotham,
		TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "ยาในกระเป๋า: ตรวจสอบ...", ZIndex = 7,
	}, autoPotionFrame)

	updatePotionInfoDisplay = function()
		local inv = callbacks.getInventory and callbacks.getInventory() or {}
		local counts = { WhitePotion = 0, YellowPotion = 0, OrangePotion = 0, RedPotion = 0, BluePotion = 0 }
		for _, entry in ipairs(inv) do
			if counts[entry.itemId] ~= nil then
				counts[entry.itemId] = counts[entry.itemId] + (tonumber(entry.quantity) or 0)
			end
		end
		autoPotionInfo.Text = string.format("ยาในตัว: White(%d) Yellow(%d) Orange(%d) Red(%d) Blue(%d)",
			counts.WhitePotion, counts.YellowPotion, counts.OrangePotion, counts.RedPotion, counts.BluePotion)
	end

	autoPotionButton.Activated:Connect(function()
		autoPotionEnabled = not autoPotionEnabled
		autoPotionButton.Text = autoPotionEnabled and "☑ ดื่มยาอัตโนมัติ (Auto-Potion): เปิด (HP < 50% หรือ SP < 30%)" or "□ ดื่มยาอัตโนมัติ (Auto-Potion): ปิด"
		autoPotionButton.BackgroundColor3 = autoPotionEnabled and hex("287a48") or hex("4a3030")
	end)

	local autoSettingsStatus = makeInstance("TextLabel", {
		Name = "AutoSettingsStatus", Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 374),
		BackgroundTransparency = 1, TextColor3 = hex("fff1a8"), Font = Enum.Font.Gotham,
		TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Auto: ปิด • เลือกเป้าหมายและลำดับการโจมตีได้ที่นี่",
	}, autoSettingsContent)

	local function getAutoProfile(classId)
		local currentOwned = hotbarView.getCurrentOwnedSkills()
		local skillByClass = hotbarView.getSkillByClass()
		if not autoProfiles[classId] then
			local profile = {{id = "BasicAttack", enabled = classId ~= "Mage"}}
			for _, skillId in ipairs(skillByClass[classId] or {}) do
				if (tonumber(currentOwned[skillId]) or 0) > 0 then
					local defaultOn = classId == "Mage" or classId == "Knight" or classId == "Thief"
					if classId == "Archer" or classId == "Acolyte" or classId == "Merchant" or classId == "Novice" then
						defaultOn = false
					end
					table.insert(profile, {id = skillId, enabled = defaultOn})
				end
			end
			autoProfiles[classId] = profile
		end
		local profile = autoProfiles[classId]
		for _, skillId in ipairs(skillByClass[classId] or {}) do
			if (tonumber(currentOwned[skillId]) or 0) > 0 then
				local found = false
				for _, entry in ipairs(profile) do if entry.id == skillId then found = true; break end end
				if not found then table.insert(profile, {id = skillId, enabled = false}) end
			end
		end
		return profile
	end

	local function renderAutoActionList()
		for _, child in ipairs(autoActionList:GetChildren()) do
			if child:IsA("Frame") and child.Name:match("^AutoActionRow") then child:Destroy() end
		end
		local classId = player:GetAttribute("Class") or "Novice"
		local profile = getAutoProfile(classId)
		local currentOwned = hotbarView.getCurrentOwnedSkills()
		for index, entry in ipairs(profile) do
			local actionId = entry.id
			local definition = skillData[actionId]
			local isBasic = actionId == "BasicAttack"
			local learned = isBasic or (tonumber(currentOwned[actionId]) or 0) > 0
			if learned then
				local rowIndex = index
				local label = isBasic and "โจมตีปกติ" or (definition and definition.name or actionId)
				if definition and definition.isHeal then label = label .. " (ใช้เมื่อ HP ต่ำกว่า 60%)" end
				local row = makeInstance("Frame", {
					Name = "AutoActionRow_" .. actionId, Size = UDim2.new(1, -2, 0, 34),
					BackgroundColor3 = hex("25253d"), BorderSizePixel = 0, LayoutOrder = rowIndex, ZIndex = 5,
				}, autoActionList)
				makeInstance("UICorner", {CornerRadius = UDim.new(0, 5)}, row)
				local toggle = makeInstance("TextButton", {
					Name = "Toggle", Size = UDim2.new(1, -88, 1, 0), BackgroundTransparency = 1,
					Text = (entry.enabled and "☑ " or "□ ") .. label,
					TextColor3 = entry.enabled and hex("ffffff") or hex("9292a8"),
					Font = Enum.Font.GothamSemibold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 6,
				}, row)
				local up = makeInstance("TextButton", {
					Name = "MoveUp", Size = UDim2.new(0, 34, 0, 28), Position = UDim2.new(1, -78, 0, 3),
					BackgroundColor3 = hex("3b3b58"), Text = "▲", TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 6,
				}, row)
				local down = makeInstance("TextButton", {
					Name = "MoveDown", Size = UDim2.new(0, 34, 0, 28), Position = UDim2.new(1, -40, 0, 3),
					BackgroundColor3 = hex("3b3b58"), Text = "▼", TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 6,
				}, row)
				for _, button in ipairs({up, down}) do
					makeInstance("UICorner", {CornerRadius = UDim.new(0, 4)}, button)
				end
				toggle.Activated:Connect(function()
					entry.enabled = not entry.enabled
					renderAutoActionList()
				end)
				up.Activated:Connect(function()
					if rowIndex > 1 then
						profile[rowIndex], profile[rowIndex - 1] = profile[rowIndex - 1], profile[rowIndex]
						renderAutoActionList()
					end
				end)
				down.Activated:Connect(function()
					if rowIndex < #profile then
						profile[rowIndex], profile[rowIndex + 1] = profile[rowIndex + 1], profile[rowIndex]
						renderAutoActionList()
					end
				end)
			end
		end
	end
	renderAutoActionList()

	-- ── Target & Action Selection for Auto Battle ─────────────
	local function findAutoAttackTarget()
		local character = player.Character
		local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
		if not playerRoot then return nil end
		local monstersFolder = Workspace:FindFirstChild("Monsters")
		if not monstersFolder then return nil end
		local nearest, nearestDistance = nil, MONSTER_TARGET_RANGE
		for _, monster in ipairs(monstersFolder:GetChildren()) do
			local monsterId = monster:GetAttribute("MonsterID")
			local monsterRoot = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart
			if monsterId and (autoAttackAll or autoTargetTypes[monsterId] == true) and monsterRoot and (monster:GetAttribute("HP") or 0) > 0 then
				local offset = monsterRoot.Position - playerRoot.Position
				local distance = offset.Magnitude
				if distance <= nearestDistance then
					if canAcquireMonsterTarget(monster, character, playerRoot) then
						nearest, nearestDistance = monster, distance
					end
				end
			end
		end
		return nearest
	end

	local function autoTargetTypeEnabled(monster)
		local monsterId = monster and monster:GetAttribute("MonsterID")
		return monsterId ~= nil and (autoAttackAll or autoTargetTypes[monsterId] == true)
	end

	local function getNextAutoAction(now)
		local classId = player:GetAttribute("Class") or "Novice"
		local profile = getAutoProfile(classId)
		local currentOwned = hotbarView.getCurrentOwnedSkills()
		local hp = tonumber(player:GetAttribute("HP")) or 0
		local maxHP = math.max(tonumber(player:GetAttribute("MaxHP")) or 1, 1)
		local sp = tonumber(player:GetAttribute("SP")) or 0
		local gold = tonumber(player:GetAttribute("Gold")) or 0
		local waitingForSP, waitingForGold, waitingForCooldown, waitingForSkillConfirmation

		for _, entry in ipairs(profile) do
			if entry.enabled then
				if entry.id == "BasicAttack" then
					if now >= autoBasicNextAt then return entry end
					waitingForCooldown = true
				else
					local definition = skillData[entry.id]
					local skillLevel = tonumber(currentOwned[entry.id]) or 0
					if definition and useSkillRemote and skillLevel > 0 then
						local spCost = (definition.spCost or 0) + (skillLevel - 1) * (definition.spCostPerLevel or 0)
						local goldCost = definition.goldCost or 0
						local shouldHeal = definition.isHeal and hp / maxHP <= 0.6
						local canAttack = definition.isAttack
						if shouldHeal or canAttack then
							if now < (autoSkillCooldownUntil[entry.id] or 0) then
								waitingForCooldown = true
							elseif now < (autoSkillAttemptUntil[entry.id] or 0) then
								waitingForSkillConfirmation = true
							elseif sp < spCost then
								waitingForSP = string.format("SP %d/%d", sp, spCost)
							elseif gold < goldCost then
								waitingForGold = string.format("Zeny %d/%d", gold, goldCost)
							else
								return entry
							end
						end
					end
				end
			end
		end
		if waitingForSP then return nil, "Auto: รอ " .. waitingForSP end
		if waitingForGold then return nil, "Auto: รอ " .. waitingForGold end
		if waitingForCooldown then return nil, "Auto: รอคูลดาวน์สกิล" end
		if waitingForSkillConfirmation then return nil, "Auto: กำลังยืนยันการใช้สกิล" end
		return nil, "Auto: ไม่มีรายการโจมตีที่เปิดใช้งาน"
	end

	local function getAutoApproachRange()
		local classId = player:GetAttribute("Class") or "Novice"
		local basicRange = classData.GetBasicAttackRange(classId)
		local currentOwned = hotbarView.getCurrentOwnedSkills()
		for _, entry in ipairs(getAutoProfile(classId)) do
			if entry.enabled then
				if entry.id == "BasicAttack" then return basicRange end
				local definition = skillData[entry.id]
				if definition and definition.isAttack and (tonumber(currentOwned[entry.id]) or 0) > 0 then
					return tonumber(definition.range) or basicRange
				end
			end
		end
		return nil
	end

	local function getAutoSafeRange(range)
		return math.max(2, (tonumber(range) or 10) - 3)
	end

	-- ── Toggle Auto Attack ────────────────────────────────────
	local function toggleAutoAttack()
		autoAttackEnabled = not autoAttackEnabled
		manualPursuitGeneration += 1
		manualPursuitActive = false
		autoAttackGeneration += 1
		local generation = autoAttackGeneration

		hudView.autoAttackButton.Text = autoAttackEnabled and "⚔ Auto: เปิด" or "⚔ Auto: ปิด"
		hudView.autoAttackButton.BackgroundColor3 = autoAttackEnabled and hex("287a48") or hex("4a3030")

		if autoAttackEnabled then
			renderAutoActionList()
			refreshVisibleTargetFilters()
			autoSettingsWin.Visible = true

			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if selectedTargetModel and selectedTargetModel.Parent
				and (selectedTargetModel:GetAttribute("HP") or 0) > 0
				and autoTargetTypeEnabled(selectedTargetModel)
				and canAcquireMonsterTarget(selectedTargetModel, character, root) then
				autoLockedMonster = selectedTargetModel
			else
				if selectedTargetModel then setSelectedTarget(nil) end
				autoLockedMonster = nil
			end
			autoBasicNextAt = 0

			task.spawn(function()
				local lastApproachTarget = nil
				local lastApproachGoal = nil
				local lastApproachCommandAt = 0
				while autoAttackEnabled and generation == autoAttackGeneration do
					local now = os.clock()
					local target = autoLockedMonster
					if not target or not target.Parent or (target:GetAttribute("HP") or 0) <= 0 then
						if target and selectedTargetModel == target then setSelectedTarget(nil) end
						target = findAutoAttackTarget()
						autoLockedMonster = target
						if target then setSelectedTarget(target) end
					end

					local action, waitReason = getNextAutoAction(now)
					local definition = action and action.id ~= "BasicAttack" and skillData[action.id] or nil

					if action and definition and definition.isHeal then
						autoSkillCooldownUntil[action.id] = now + (tonumber(definition.cooldown) or 1.5)
						useSkillRemote:FireServer(action.id, nil)
						autoSettingsStatus.Text = "Auto: ใช้ " .. definition.name
					elseif action then
						if target and requestAttackRemote then
							autoSettingsStatus.Text = "Auto: " .. (definition and (definition.nameThai or definition.name) or "โจมตีปกติ") .. " → " .. (target:GetAttribute("MonsterID") or "มอน")
							local character = player.Character
							local root = character and character:FindFirstChild("HumanoidRootPart")
							local humanoid = character and character:FindFirstChildOfClass("Humanoid")
							local monsterRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
							local attackRange = definition and tonumber(definition.range)
								or classData.GetBasicAttackRange(player:GetAttribute("Class") or "Novice")
							local safeRange = getAutoSafeRange(attackRange)
							local castRange = math.max(2, attackRange - 1.5)

							if root and humanoid and monsterRoot then
								if (monsterRoot.Position - root.Position).Magnitude > castRange then
									local towardPlayer = (root.Position - monsterRoot.Position).Unit
									local goal = monsterRoot.Position + towardPlayer * safeRange
									if lastApproachTarget ~= target or not lastApproachGoal
										or (goal - lastApproachGoal).Magnitude >= 2
										or now - lastApproachCommandAt >= 0.75 then
										humanoid:MoveTo(goal)
										lastApproachTarget = target
										lastApproachGoal = goal
										lastApproachCommandAt = now
									end
								elseif action.id == "BasicAttack" then
									lastApproachTarget = nil
									lastApproachGoal = nil
									requestAttackRemote:FireServer(target)
									autoBasicNextAt = now + autoAttackInterval()
								else
									autoSkillAttemptUntil[action.id] = now + 0.45
									local castTime = definition and tonumber(definition.castTime) or 0
									if castTime > 0 then
										humanoid:MoveTo(root.Position)
										local castDone = false
										executeCast(action.id, definition, target, function()
											castDone = true
											useSkillRemote:FireServer(action.id, target)
										end)
										while not castDone and isCasting and autoAttackEnabled and generation == autoAttackGeneration do
											task.wait(0.05)
										end
									else
										useSkillRemote:FireServer(action.id, target)
									end
								end
							end
						else
							autoSettingsStatus.Text = "Auto: ไม่มีเป้าในระยะมองเห็น 50 studs"
							local character = player.Character
							local root = character and character:FindFirstChild("HumanoidRootPart")
							local humanoid = character and character:FindFirstChildOfClass("Humanoid")
							if root and humanoid then humanoid:MoveTo(root.Position) end
						end
					else
						autoSettingsStatus.Text = waitReason or "Auto: กำลังรอ"
						local character = player.Character
						local root = character and character:FindFirstChild("HumanoidRootPart")
						local humanoid = character and character:FindFirstChildOfClass("Humanoid")
						local monsterRoot = target and (target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart)
						local approachRange = getAutoApproachRange()
						local safeRange = approachRange and getAutoSafeRange(approachRange)
						if root and humanoid and monsterRoot and safeRange
							and (monsterRoot.Position - root.Position).Magnitude > safeRange then
							local towardPlayer = (root.Position - monsterRoot.Position).Unit
							local goal = monsterRoot.Position + towardPlayer * safeRange
							if lastApproachTarget ~= target or not lastApproachGoal
								or (goal - lastApproachGoal).Magnitude >= 2
								or now - lastApproachCommandAt >= 0.75 then
								humanoid:MoveTo(goal)
								lastApproachTarget = target
								lastApproachGoal = goal
								lastApproachCommandAt = now
							end
						elseif root and humanoid then
							lastApproachTarget = nil
							lastApproachGoal = nil
						end
					end
					if autoSettingsWin.Visible then refreshVisibleTargetFilters() end
					task.wait(0.2)
				end
			end)
		else
			autoLockedMonster = nil
			autoSettingsStatus.Text = "Auto: ปิด"
			refreshVisibleTargetFilters()
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid then humanoid:MoveTo(root.Position) end
		end
	end

	local function toggleAutoSettings()
		renderAutoActionList()
		refreshVisibleTargetFilters()
		autoSettingsWin.Visible = not autoSettingsWin.Visible
	end

	-- ── Cancel Automation on Manual Move ──────────────────────
	local function cancelAutomationForManualMovement()
		if autoAttackEnabled or not manualPursuitActive then return end
		manualPursuitGeneration += 1
		manualPursuitActive = false
		setSelectedTarget(nil)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid then humanoid:MoveTo(root.Position) end
	end

	ContextActionService:BindActionAtPriority(
		"RoROK_CancelAutoOnManualMove",
		function(_, state)
			if state == Enum.UserInputState.Begin and not UserInputService:GetFocusedTextBox() then
				cancelAutomationForManualMovement()
			end
			return Enum.ContextActionResult.Pass
		end,
		false,
		Enum.ContextActionPriority.Default.Value + 1,
		Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
		Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right
	)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Gamepad1
			and input.KeyCode == Enum.KeyCode.Thumbstick1
			and input.Position.Magnitude > 0.25 then
			cancelAutomationForManualMovement()
		end
	end)

	return {
		setSelectedTarget = setSelectedTarget,
		getSelectedTarget = function() return selectedTargetModel end,
		castHotbarSlot = castHotbarSlot,
		toggleAutoAttack = toggleAutoAttack,
		toggleAutoSettings = toggleAutoSettings,
		isAutoAttackEnabled = function() return autoAttackEnabled end,
	}
end

return CombatTargeting
