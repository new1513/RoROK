-- ============================================================
-- MinimapView.lua
-- RoROK — Square Minimap, Building Blocks, & Quest Tracker
-- (Ragnarok M Style with High Contrast & Object Pooling)
-- ============================================================

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MinimapView = {}

function MinimapView.init(player, playerGui, remotes, UITheme, openExpandedMapCallback, skillNoticeCallback)
	local hex = UITheme.hex
	local makeInstance = UITheme.makeInstance

	local claimDailyQuestRemote = remotes.claimDailyQuestRemote or remotes.ClaimDailyQuest

	-- ── Minimap ScreenGui ─────────────────────────────────────
	local minimapGui = makeInstance("ScreenGui", {
		Name           = "Minimap",
		ResetOnSpawn   = false,
		IgnoreGuiInset = false,
		DisplayOrder   = 15,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)

	local minimapFrame = makeInstance("Frame", {
		Name             = "MinimapFrame",
		Size             = UDim2.new(0, 160, 0, 160),
		Position         = UDim2.new(1, -172, 0, 10),
		BackgroundColor3 = hex("1e293b"),
		BackgroundTransparency = 0.02,
		BorderSizePixel  = 0,
		ClipsDescendants = true,
		ZIndex           = 1,
	}, minimapGui)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 10) }, minimapFrame)
	makeInstance("UIStroke", { Color = hex("e5c158"), Thickness = 2.4 }, minimapFrame)

	-- ── Click to Expand World Map ─────────────────────────────
	local minimapExpandBtn = makeInstance("TextButton", {
		Name = "MinimapExpandBtn",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.999,
		Text = "",
		Active = true,
		ZIndex = 25,
	}, minimapFrame)

	local lastMapToggle = 0
	local function triggerOpenMap()
		local now = os.clock()
		if now - lastMapToggle < 0.35 then return end
		lastMapToggle = now
		if openExpandedMapCallback then
			openExpandedMapCallback()
		elseif _G.ToggleLocalMap then
			_G.ToggleLocalMap()
		end
	end
	minimapExpandBtn.Activated:Connect(triggerOpenMap)

	local mapHintBadge = makeInstance("TextButton", {
		Name = "MapHintBadge",
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(1, -28, 0, 4),
		BackgroundColor3 = hex("0f172a"),
		BackgroundTransparency = 0.15,
		Text = "🗺️",
		TextSize = 13,
		Active = true,
		ZIndex = 30,
	}, minimapFrame)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, mapHintBadge)
	makeInstance("UIStroke", { Color = hex("e5c158"), Thickness = 1.2 }, mapHintBadge)
	mapHintBadge.Activated:Connect(triggerOpenMap)

	local buildingLayer = makeInstance("Frame", {
		Name             = "BuildingLayer",
		Size             = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex           = 2,
	}, minimapFrame)

	local routeLayer = makeInstance("Frame", {
		Name             = "RouteLayer",
		Size             = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex           = 3,
	}, minimapFrame)

	-- ── Compass Cardinal Directions (N, S, W, E) ─────────────
	for _, dirSpec in ipairs({
		{"N", UDim2.new(0.5, -7, 0, 3), hex("ffd166")},
		{"S", UDim2.new(0.5, -7, 1, -15), hex("94a3b8")},
		{"W", UDim2.new(0, 4, 0.5, -6), hex("94a3b8")},
		{"E", UDim2.new(1, -16, 0.5, -6), hex("94a3b8")},
	}) do
		makeInstance("TextLabel", {
			Size = UDim2.new(0, 14, 0, 12),
			Position = dirSpec[2],
			BackgroundTransparency = 1,
			Text = dirSpec[1],
			TextColor3 = dirSpec[3],
			Font = Enum.Font.GothamBold,
			TextSize = 9,
			ZIndex = 4,
		}, minimapFrame)
	end

	-- ── Player Dot (Center) ──────────────────────────────────
	local playerDot = makeInstance("Frame", {
		Name             = "PlayerDot",
		Size             = UDim2.new(0, 11, 0, 11),
		Position         = UDim2.new(0.5, -5, 0.5, -5),
		BackgroundColor3 = hex("0284c7"),
		ZIndex           = 15,
	}, minimapFrame)
	makeInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, playerDot)
	makeInstance("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2.0 }, playerDot)

	-- ── Prontera City Layout Blocks ───────────────────────────
	local PRONTERA_CITY_BLOCKS = {
		{ name = "MainRoadNS", pos = Vector3.new(0, 0, 0), size = Vector2.new(16, 260), color = hex("f1f5f9"), stroke = hex("94a3b8") },
		{ name = "MainRoadEW", pos = Vector3.new(0, 0, 0), size = Vector2.new(180, 16), color = hex("f1f5f9"), stroke = hex("94a3b8") },
		{ name = "PlazaCircle", pos = Vector3.new(0, 0, 0), size = Vector2.new(50, 50), color = hex("e2e8f0"), stroke = hex("94a3b8"), shape = "circle" },
		{ name = "Roundabout", pos = Vector3.new(0, 0, 0), size = Vector2.new(22, 22), color = hex("0ea5e9"), shape = "circle", label = "⛲" },
		{ name = "GrandCathedral", pos = Vector3.new(0, 0, -220), size = Vector2.new(56, 90), color = hex("7c3aed"), stroke = hex("e0e7ff"), label = "⛪" },
		{ name = "AdventurerGuild", pos = Vector3.new(-58, 0, -95), size = Vector2.new(44, 76), color = hex("d97706"), stroke = hex("fef3c7"), label = "🛡️" },
		{ name = "MissionBoard", pos = Vector3.new(-58, 0, -52), size = Vector2.new(14, 14), color = hex("f59e0b"), stroke = hex("ffffff"), label = "📜" },
		{ name = "Blacksmith", pos = Vector3.new(-32, 0, -28), size = Vector2.new(24, 24), color = hex("ea580c"), stroke = hex("ffedd5"), label = "🔨" },
		{ name = "ItemShop", pos = Vector3.new(32, 0, -25), size = Vector2.new(22, 22), color = hex("10b981"), stroke = hex("d1fae5"), label = "🛒" },
		{ name = "EquipmentShop", pos = Vector3.new(32, 0, 20), size = Vector2.new(22, 22), color = hex("0d9488"), stroke = hex("ccfbf1"), label = "🛡️" },
		{ name = "TrainingGround", pos = Vector3.new(35, 0, -96), size = Vector2.new(26, 46), color = hex("e11d48"), stroke = hex("ffe4e6"), label = "⚔️" },
		{ name = "HarborDock", pos = Vector3.new(65, 0, 65), size = Vector2.new(32, 28), color = hex("0284c7"), stroke = hex("e0f2fe"), label = "⚓" },
		{ name = "WaterPond", pos = Vector3.new(0, 0, 50), size = Vector2.new(42, 42), color = hex("0ea5e9"), stroke = hex("e0f2fe"), shape = "circle", label = "🌊" },
		{ name = "EastGateArch", pos = Vector3.new(80, 0, 0), size = Vector2.new(16, 40), color = hex("64748b"), stroke = hex("f1f5f9"), label = "🚪" },
		{ name = "TownWallNorth", pos = Vector3.new(80, 0, -85), size = Vector2.new(12, 130), color = hex("475569") },
		{ name = "TownWallSouth", pos = Vector3.new(80, 0, 85), size = Vector2.new(12, 130), color = hex("475569") },
		{ name = "EastRiverNorth", pos = Vector3.new(190, 0, -85), size = Vector2.new(18, 150), color = hex("0ea5e9") },
		{ name = "EastRiverSouth", pos = Vector3.new(190, 0, 85), size = Vector2.new(18, 150), color = hex("0ea5e9") },
		{ name = "StoneArchBridge", pos = Vector3.new(190, 0, 0), size = Vector2.new(24, 16), color = hex("f8fafc"), stroke = hex("64748b"), label = "🌉" },
		{ name = "WoodNorthBridge", pos = Vector3.new(190, 0, -80), size = Vector2.new(22, 12), color = hex("b45309"), stroke = hex("451a03"), label = "🪵" },
		{ name = "PoringMeadow", pos = Vector3.new(135, 0, 0), size = Vector2.new(85, 180), color = hex("22c55e"), shape = "rounded", label = "🌱" },
		{ name = "Farmlands", pos = Vector3.new(245, 0, -75), size = Vector2.new(80, 130), color = hex("eab308"), label = "🌾" },
		{ name = "WolfWoods", pos = Vector3.new(255, 0, 75), size = Vector2.new(90, 130), color = hex("16a34a"), label = "🌲" },
		{ name = "DesertRuins", pos = Vector3.new(360, 0, -75), size = Vector2.new(100, 130), color = hex("f59e0b"), label = "🏜️" },
		{ name = "ForgottenCrypt", pos = Vector3.new(370, 0, 75), size = Vector2.new(100, 130), color = hex("9333ea"), label = "⚰️" },
		{ name = "DrakeShrine", pos = Vector3.new(475, 0, 0), size = Vector2.new(70, 90), color = hex("e11d48"), label = "👑" },
	}

	local cityBlockFrames = {}
	for idx, block in ipairs(PRONTERA_CITY_BLOCKS) do
		local f = makeInstance("Frame", {
			Name = "Block_" .. block.name,
			BackgroundColor3 = block.color,
			BorderSizePixel = 0,
			BackgroundTransparency = 0.05,
			ZIndex = 2,
		}, buildingLayer)
		if block.shape == "circle" then
			makeInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
		else
			makeInstance("UICorner", { CornerRadius = UDim.new(0, 3) }, f)
		end
		makeInstance("UIStroke", { Color = block.stroke or hex("0f172a"), Thickness = 1.0, Transparency = 0.2 }, f)
		if block.label then
			makeInstance("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = block.label,
				TextSize = 10,
				TextColor3 = hex("ffffff"),
				Font = Enum.Font.GothamBold,
				ZIndex = 3,
			}, f)
		end
		cityBlockFrames[idx] = f
	end

	-- ── Quest Tracker Widget ──────────────────────────────────
	local questTrackerFrame = makeInstance("Frame", {
		Name             = "QuestTrackerWidget",
		Size             = UDim2.new(0, 160, 0, 0),
		AutomaticSize    = Enum.AutomaticSize.Y,
		Position         = UDim2.new(1, -172, 0, 178),
		BackgroundColor3 = hex("0a1222"),
		BackgroundTransparency = 0.12,
		BorderSizePixel  = 0,
		ZIndex           = 15,
	}, minimapGui)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, questTrackerFrame)
	makeInstance("UIStroke", { Color = hex("c99a3e"), Thickness = 1.2 }, questTrackerFrame)

	local trackerHeader = makeInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundColor3 = hex("14223d"),
		BorderSizePixel = 0,
		ZIndex = 16,
	}, questTrackerFrame)
	makeInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, trackerHeader)
	makeInstance("TextLabel", {
		Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1, Text = "📋 ภารกิจ (Quests)",
		TextColor3 = hex("ffd166"), Font = Enum.Font.GothamBold,
		TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 17,
	}, trackerHeader)

	local trackerList = makeInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 26),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 16,
	}, questTrackerFrame)
	makeInstance("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, trackerList)

	local activeQuestsList = {}
	local currentTrackedQuest = nil
	local worldQuestBeacon = nil

	local function updateWorldBeacon(targetPos, questTitle)
		if not targetPos then
			if worldQuestBeacon then worldQuestBeacon:Destroy() worldQuestBeacon = nil end
			return
		end
		if not worldQuestBeacon or not worldQuestBeacon.Parent then
			worldQuestBeacon = Instance.new("Model")
			worldQuestBeacon.Name = "ClientQuestBeacon"
			worldQuestBeacon.Parent = Workspace
			local beam = Instance.new("Part")
			beam.Name = "Beam"
			beam.Size = Vector3.new(0.6, 32, 0.6)
			beam.Anchored = true
			beam.CanCollide = false
			beam.Material = Enum.Material.Neon
			beam.Color = Color3.fromRGB(56, 189, 248)
			beam.Transparency = 0.3
			beam.Parent = worldQuestBeacon
			worldQuestBeacon.PrimaryPart = beam

			local ring = Instance.new("Part")
			ring.Name = "GroundRing"
			ring.Shape = Enum.PartType.Cylinder
			ring.Size = Vector3.new(0.12, 7.5, 7.5)
			ring.CFrame = CFrame.new(targetPos.X, targetPos.Y + 0.15, targetPos.Z) * CFrame.Angles(0, 0, math.rad(90))
			ring.Anchored = true
			ring.CanCollide = false
			ring.Material = Enum.Material.Neon
			ring.Color = Color3.fromRGB(245, 190, 70)
			ring.Transparency = 0.35
			ring.Parent = worldQuestBeacon

			local pointLight = Instance.new("PointLight")
			pointLight.Color = Color3.fromRGB(56, 189, 248)
			pointLight.Range = 24
			pointLight.Brightness = 2.5
			pointLight.Parent = beam

			local bgui = Instance.new("BillboardGui")
			bgui.Size = UDim2.fromOffset(150, 36)
			bgui.StudsOffset = Vector3.new(0, 16, 0)
			bgui.AlwaysOnTop = true
			bgui.Adornee = beam
			bgui.Parent = beam

			local lbl = Instance.new("TextLabel")
			lbl.Name = "BeaconLabel"
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
			lbl.BackgroundTransparency = 0.15
			lbl.TextColor3 = Color3.fromRGB(255, 230, 100)
			lbl.Font = Enum.Font.GothamBold
			lbl.TextSize = 11
			lbl.Text = "🎯 " .. (questTitle or "เป้าหมายเควส")
			lbl.Parent = bgui
			Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)
			local stroke = Instance.new("UIStroke", lbl)
			stroke.Color = Color3.fromRGB(56, 189, 248)
			stroke.Thickness = 1.6
		end
		if worldQuestBeacon and worldQuestBeacon:FindFirstChild("Beam") then
			worldQuestBeacon.Beam.Position = Vector3.new(targetPos.X, targetPos.Y + 16, targetPos.Z)
			if worldQuestBeacon:FindFirstChild("GroundRing") then
				worldQuestBeacon.GroundRing.CFrame = CFrame.new(targetPos.X, targetPos.Y + 0.15, targetPos.Z) * CFrame.Angles(0, 0, math.rad(90))
			end
			local blbl = worldQuestBeacon.Beam:FindFirstChild("BillboardGui") and worldQuestBeacon.Beam.BillboardGui:FindFirstChild("BeaconLabel")
			if blbl then blbl.Text = "🎯 " .. (questTitle or "เป้าหมายเควส") end
		end
	end

	local function renderQuestTracker()
		for _, child in ipairs(trackerList:GetChildren()) do
			if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
				child:Destroy()
			end
		end
		if #activeQuestsList == 0 then
			makeInstance("TextLabel", {
				Name = "EmptyLabel",
				Size = UDim2.new(1, -10, 0, 36),
				BackgroundTransparency = 1,
				Text = "ไม่มีภารกิจที่รับอยู่\n(ไปรับได้ที่กระดานเควส)",
				TextColor3 = hex("94a3b8"),
				Font = Enum.Font.Gotham,
				TextSize = 10,
				ZIndex = 17,
			}, trackerList)
			updateWorldBeacon(nil)
			return
		end

		for _, quest in ipairs(activeQuestsList) do
			local isTracked = currentTrackedQuest and currentTrackedQuest.id == quest.id
			local isDone = (quest.progress or 0) >= (quest.amount or 1) or quest.complete
			local card = makeInstance("TextButton", {
				Name = "QuestCard_" .. quest.id,
				Size = UDim2.new(1, -6, 0, isDone and 82 or 56),
				BackgroundColor3 = isDone and hex("0d2e1c") or (isTracked and hex("1b2a48") or hex("111b2e")),
				BorderSizePixel = 0,
				AutoButtonColor = true,
				Text = "",
				ZIndex = 17,
			}, trackerList)
			makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, card)
			makeInstance("UIStroke", {
				Color = isDone and hex("22c55e") or (isTracked and hex("38bdf8") or hex("334155")),
				Thickness = isDone and 2 or (isTracked and 1.6 or 1),
			}, card)

			makeInstance("TextLabel", {
				Size = UDim2.new(1, -12, 0, 16), Position = UDim2.new(0, 6, 0, 4),
				BackgroundTransparency = 1,
				Text = (isDone and "🎉 " or (isTracked and "🧭 " or "• ")) .. quest.title .. (isDone and " (เสร็จแล้ว!)" or ""),
				TextColor3 = isDone and hex("fef08a") or (isTracked and hex("38bdf8") or hex("ffd166")),
				Font = Enum.Font.GothamBold, TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 18,
			}, card)

			local progStr = isDone and string.format("✓ สำเร็จครบแล้ว (%d/%d)", quest.progress or quest.amount, quest.amount or 1)
				or string.format("ความคืบหน้า: %d/%d", quest.progress or 0, quest.amount or 1)
			makeInstance("TextLabel", {
				Size = UDim2.new(1, -12, 0, 14), Position = UDim2.new(0, 6, 0, 20),
				BackgroundTransparency = 1, Text = progStr,
				TextColor3 = isDone and hex("4ade80") or hex("f1f5f9"),
				Font = isDone and Enum.Font.GothamBold or Enum.Font.Gotham,
				TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 18,
			}, card)

			if isDone then
				local claimBtn = makeInstance("TextButton", {
					Name = "ClaimQuestBtn",
					Size = UDim2.new(1, -12, 0, 26),
					Position = UDim2.new(0, 6, 0, 44),
					BackgroundColor3 = hex("16a34a"),
					Text = "✨ กดรับรางวัล (Claim)",
					TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.GothamBold,
					TextSize = 10,
					AutoButtonColor = true,
					ZIndex = 19,
				}, card)
				makeInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, claimBtn)
				makeInstance("UIStroke", { Color = hex("86efac"), Thickness = 1.2 }, claimBtn)
				claimBtn.Activated:Connect(function()
					if claimDailyQuestRemote then
						claimDailyQuestRemote:FireServer(quest.id)
						updateWorldBeacon(nil)
						if skillNoticeCallback then
							skillNoticeCallback("🎉 กำลังรับรางวัล: " .. quest.title)
						end
					end
				end)
			else
				makeInstance("TextLabel", {
					Name = "DistLabel",
					Size = UDim2.new(1, -12, 0, 14), Position = UDim2.new(0, 6, 0, 36),
					BackgroundTransparency = 1, Text = "🚩 " .. (quest.location or "Prontera"),
					TextColor3 = hex("4ade80"), Font = Enum.Font.GothamMedium,
					TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ZIndex = 18,
				}, card)
			end

			card.Activated:Connect(function()
				currentTrackedQuest = quest
				renderQuestTracker()
				if not isDone then
					local tPos = quest.targetPos and Vector3.new(quest.targetPos.X, quest.targetPos.Y, quest.targetPos.Z)
					updateWorldBeacon(tPos, quest.title)
					if skillNoticeCallback then
						skillNoticeCallback("🧭 นำทางสู่: " .. quest.title)
					end
				else
					updateWorldBeacon(nil)
				end
			end)
		end
	end

	local function trackQuest(qId)
		for _, q in ipairs(activeQuestsList) do
			if q.id == qId then
				currentTrackedQuest = q
				renderQuestTracker()
				if q.targetPos then
					updateWorldBeacon(Vector3.new(q.targetPos.X, q.targetPos.Y, q.targetPos.Z), q.title)
				end
				return true
			end
		end
		return false
	end

	_G.TrackQuest = trackQuest
	shared.TrackQuest = trackQuest

	-- ── Route Dots & Object Pooling ───────────────────────────
	local normalDotPool = {}
	local bossDotPool = {}
	local MINIMAP_RANGE = 160  -- studs
	local minimapRefreshElapsed = 0
	local ROUTE_DOT_COUNT = 8
	local routeDotParts = {}

	for i = 1, ROUTE_DOT_COUNT do
		local rDot = makeInstance("Frame", {
			Name = "RouteDot_" .. i,
			Size = UDim2.fromOffset(5, 5),
			BackgroundColor3 = hex("38bdf8"),
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 4,
		}, routeLayer)
		makeInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, rDot)
		table.insert(routeDotParts, rDot)
	end

	local routePin = makeInstance("TextLabel", {
		Name = "TargetPin",
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		Text = "🎯",
		TextColor3 = hex("f59e0b"),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		Visible = false,
		ZIndex = 5,
	}, routeLayer)

	-- ── Heartbeat Update Loop ─────────────────────────────────
	RunService.Heartbeat:Connect(function(dt)
		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local playerPos = root.Position

		if playerPos.X > 80 then
			minimapFrame.BackgroundColor3 = hex("14321a") -- Field green tone
		else
			minimapFrame.BackgroundColor3 = hex("1e293b") -- Town stone tone
		end

		-- 1. City block frames
		for idx, block in ipairs(PRONTERA_CITY_BLOCKS) do
			local f = cityBlockFrames[idx]
			if f then
				local diff = block.pos - playerPos
				local nx = (diff.X / MINIMAP_RANGE) * 0.5 + 0.5
				local nz = (diff.Z / MINIMAP_RANGE) * 0.5 + 0.5
				local sw = (block.size.X / MINIMAP_RANGE) * 0.5 * 160
				local sh = (block.size.Y / MINIMAP_RANGE) * 0.5 * 160
				f.Position = UDim2.new(nx, -sw / 2, nz, -sh / 2)
				f.Size = UDim2.new(0, sw, 0, sh)
			end
		end

		-- 2. Quest Route Breadcrumbs
		local isTrackedDone = currentTrackedQuest and ((currentTrackedQuest.progress or 0) >= (currentTrackedQuest.amount or 1) or currentTrackedQuest.complete)
		if currentTrackedQuest and currentTrackedQuest.targetPos and not isTrackedDone then
			local tPos = Vector3.new(currentTrackedQuest.targetPos.X, currentTrackedQuest.targetPos.Y, currentTrackedQuest.targetPos.Z)
			local diff = tPos - playerPos
			local dist = diff.Magnitude

			for s = 1, ROUTE_DOT_COUNT do
				local dot = routeDotParts[s]
				local frac = s / (ROUTE_DOT_COUNT + 1)
				local p = playerPos:Lerp(tPos, frac)
				local d = p - playerPos
				local nx = math.clamp((d.X / MINIMAP_RANGE) * 0.5 + 0.5, 0.04, 0.96)
				local nz = math.clamp((d.Z / MINIMAP_RANGE) * 0.5 + 0.5, 0.04, 0.96)
				dot.Position = UDim2.new(nx, -2, nz, -2)
				dot.Visible = true
			end

			local pinX = (diff.X / MINIMAP_RANGE) * 0.5 + 0.5
			local pinZ = (diff.Z / MINIMAP_RANGE) * 0.5 + 0.5
			local isOffscreen = (pinX < 0.06 or pinX > 0.94 or pinZ < 0.06 or pinZ > 0.94)
			pinX = math.clamp(pinX, 0.06, 0.94)
			pinZ = math.clamp(pinZ, 0.06, 0.94)
			routePin.Position = UDim2.new(pinX, -9, pinZ, -9)
			routePin.Text = isOffscreen and "▶" or "🎯"
			routePin.Visible = true

			local activeCard = trackerList:FindFirstChild("QuestCard_" .. currentTrackedQuest.id)
			if activeCard then
				local distLbl = activeCard:FindFirstChild("DistLabel")
				if distLbl then
					distLbl.Text = string.format("🚩 %s (~%dm)", currentTrackedQuest.location or "Prontera", math.floor(dist))
				end
			end
		else
			for _, dot in ipairs(routeDotParts) do dot.Visible = false end
			routePin.Visible = false
		end

		-- 3. Monster Dots with Object Pooling
		minimapRefreshElapsed += dt
		if minimapRefreshElapsed >= 0.4 then
			minimapRefreshElapsed = 0
			local activeNormal = 0
			local activeBoss = 0
			local monstersFolder = Workspace:FindFirstChild("Monsters")
			if monstersFolder then
				for _, obj in ipairs(monstersFolder:GetChildren()) do
					local mId = obj:GetAttribute("MonsterID") or obj.Name
					local mHP = obj:GetAttribute("HP") or 0
					if mId and mHP > 0 then
						local monRoot = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
						if monRoot then
							local diff = monRoot.Position - playerPos
							local dist = diff.Magnitude
							local isWorldBoss = obj:GetAttribute("IsWorldBoss") or mId == "Eddga" or mId == "Turtle_General"
							local isBoss = obj:GetAttribute("IsBoss") or mId == "Drake" or isWorldBoss
							local isMini = obj:GetAttribute("IsMiniBoss") or mId == "Minorous"
							if isBoss or isMini then
								activeBoss += 1
								local bFrame = bossDotPool[activeBoss]
								if not bFrame then
									bFrame = makeInstance("Frame", {
										Size = UDim2.fromOffset(20, 20),
										BorderSizePixel = 0,
										ZIndex = 6,
									}, minimapFrame)
									makeInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, bFrame)
									makeInstance("UIStroke", { Thickness = 1.6 }, bFrame)
									makeInstance("TextLabel", {
										Name = "Icon",
										Size = UDim2.fromScale(1, 1),
										BackgroundTransparency = 1,
										TextSize = 12,
										ZIndex = 7,
									}, bFrame)
									table.insert(bossDotPool, bFrame)
								end
								local nx = math.clamp((diff.X / MINIMAP_RANGE) * 0.5 + 0.5, 0.08, 0.92)
								local nz = math.clamp((diff.Z / MINIMAP_RANGE) * 0.5 + 0.5, 0.08, 0.92)
								bFrame.Position = UDim2.new(nx, -10, nz, -10)
								bFrame.BackgroundColor3 = isBoss and hex("7f1d1d") or hex("7c2d12")
								local st = bFrame:FindFirstChildOfClass("UIStroke")
								if st then st.Color = isBoss and hex("f59e0b") or hex("fdba74") end
								local ic = bFrame:FindFirstChild("Icon")
								if ic then ic.Text = isBoss and "👑" or "💀" end
								bFrame.Visible = true
							elseif dist <= MINIMAP_RANGE then
								activeNormal += 1
								local dot = normalDotPool[activeNormal]
								if not dot then
									dot = makeInstance("Frame", {
										Size = UDim2.fromOffset(8, 8),
										BackgroundColor3 = Color3.fromRGB(255, 45, 45),
										BorderSizePixel = 0,
										ZIndex = 12,
									}, minimapFrame)
									makeInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
									makeInstance("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1.0, Transparency = 0.2 }, dot)
									table.insert(normalDotPool, dot)
								end
								local nx = math.clamp((diff.X / MINIMAP_RANGE) * 0.5 + 0.5, 0.05, 0.95)
								local nz = math.clamp((diff.Z / MINIMAP_RANGE) * 0.5 + 0.5, 0.05, 0.95)
								dot.Position = UDim2.new(nx, -4, nz, -4)
								dot.Visible = true
							end
						end
					end
				end
			end
			for i = activeBoss + 1, #bossDotPool do bossDotPool[i].Visible = false end
			for i = activeNormal + 1, #normalDotPool do normalDotPool[i].Visible = false end
		end
	end)

	local function updateQuests(questsList)
		activeQuestsList = questsList or {}
		renderQuestTracker()
		if currentTrackedQuest then
			local found = false
			for _, q in ipairs(activeQuestsList) do
				if q.id == currentTrackedQuest.id then
					currentTrackedQuest = q
					found = true
					break
				end
			end
			if not found then
				currentTrackedQuest = activeQuestsList[1] or nil
			end
		else
			currentTrackedQuest = activeQuestsList[1] or nil
		end
		if currentTrackedQuest and currentTrackedQuest.targetPos then
			updateWorldBeacon(Vector3.new(currentTrackedQuest.targetPos.X, currentTrackedQuest.targetPos.Y, currentTrackedQuest.targetPos.Z), currentTrackedQuest.title)
		else
			updateWorldBeacon(nil)
		end
	end

	return {
		minimapGui = minimapGui,
		minimapFrame = minimapFrame,
		trackQuest = trackQuest,
		updateQuests = updateQuests,
		getTrackedQuest = function() return currentTrackedQuest end,
	}
end

return MinimapView
