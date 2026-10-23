-- ============================================================
-- GuildSystem.server.lua
-- ระบบกิลด์และบ้านกิลด์ (Guild System & Guild House Upgrades)
-- มอบบัพ ATK/DEF/MaxHP และลดการเสีย EXP ตอนตาย 50%
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStore
repeat
	task.wait(0.1)
	DataStore = _G.DataStore
until DataStore or not script.Parent
if not DataStore then return end

local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local function getOrCreate(className, name)
	local r = remotes:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = remotes
	end
	return r
end

local RE_GuildAction  = getOrCreate("RemoteEvent", "GuildAction")
local RE_GuildUpdated = getOrCreate("RemoteEvent", "GuildUpdated")
local RF_GetGuildInfo = getOrCreate("RemoteFunction", "GetGuildInfo")
local RE_SkillFeedback = getOrCreate("RemoteEvent", "SkillFeedback")

-- ตารางกิลด์ในเซิร์ฟเวอร์ (มีกิลด์ทางการของเมืองเริ่มต้นให้เข้าร่วมได้ทันทีแม้เล่นคนเดียว)
local Guilds = {
	["PronteraRoyalOrder"] = {
		id          = "PronteraRoyalOrder",
		name        = "ภาคีอัศวินหลวง Prontera",
		emblem      = "🛡️",
		leaderName  = "หัวหน้าอัศวิน Herman",
		houseLevel  = 2,
		treasury    = 200,
		nextUpgrade = 500,
		members     = {}, -- [userId] = playerName
	},
}

local function getGuildBonuses(guildId)
	local g = guildId and Guilds[guildId]
	if not g then return nil end
	local lv = math.clamp(tonumber(g.houseLevel) or 1, 1, 5)
	return {
		ATK   = lv * 3,
		DEF   = lv * 2,
		MaxHP = lv * 20,
	}
end

local function getDeathPenaltyMult(guildId)
	local g = guildId and Guilds[guildId]
	if not g then return 1.0 end
	return 0.5 -- บ้านกิลด์ช่วยลดการเสีย EXP ตอนตายลง 50%
end

local function serializeGuildsForClient(player)
	local data = DataStore.GetPlayerData(player)
	local myGuildId = data and data.GuildId or ""
	local list = {}
	for _, g in pairs(Guilds) do
		local memberNames = {}
		for _, mName in pairs(g.members) do
			table.insert(memberNames, mName)
		end
		table.insert(list, {
			id          = g.id,
			name        = g.name,
			emblem      = g.emblem,
			leaderName  = g.leaderName,
			houseLevel  = g.houseLevel,
			treasury    = g.treasury,
			nextUpgrade = g.houseLevel * 300,
			memberCount = #memberNames,
			members     = memberNames,
			bonuses     = getGuildBonuses(g.id),
		})
	end
	table.sort(list, function(a, b) return a.houseLevel > b.houseLevel end)
	local myGuildObj = nil
	for _, gInfo in ipairs(list) do
		if gInfo.id == myGuildId then
			myGuildObj = gInfo
			break
		end
	end
	return {
		myGuildId = myGuildId,
		guilds    = list,
		MyGuild   = myGuildObj,
		GuildList = list,
	}
end

local function broadcastGuildUpdate()
	for _, p in ipairs(Players:GetPlayers()) do
		RE_GuildUpdated:FireClient(p, serializeGuildsForClient(p))
	end
end

RF_GetGuildInfo.OnServerInvoke = function(player)
	return serializeGuildsForClient(player)
end

RE_GuildAction.OnServerEvent:Connect(function(player, action, arg1, arg2)
	local data = DataStore.GetPlayerData(player)
	if not data then return end

	if action == "RequestSync" then
		RE_GuildUpdated:FireClient(player, serializeGuildsForClient(player))
		return
	end

	if action == "Join" and type(arg1) == "string" then
		local g = Guilds[arg1]
		if not g then return end
		if data.GuildId and Guilds[data.GuildId] then
			Guilds[data.GuildId].members[player.UserId] = nil
		end
		g.members[player.UserId] = player.Name
		data.GuildId = g.id
		DataStore.SyncAttributes(player, data)
		if _G.PushCharacterData then _G.PushCharacterData(player) end
		RE_SkillFeedback:FireClient(player, "เข้าร่วมกิลด์ [" .. g.name .. "] สำเร็จ! ได้รับบัพบ้านกิลด์ Lv." .. tostring(g.houseLevel))
		broadcastGuildUpdate()

	elseif action == "Create" and type(arg1) == "string" then
		local gName = arg1:gsub("^%s+", ""):gsub("%s+$", "")
		if #gName < 2 or #gName > 28 then
			RE_SkillFeedback:FireClient(player, "ชื่อกิลด์ต้องยาว 2–28 ตัวอักษร")
			return
		end
		local createCost = 500
		if not DataStore.ModifyGold(player, -createCost) then
			RE_SkillFeedback:FireClient(player, "ต้องการ 500 Zeny ในการก่อตั้งกิลด์")
			return
		end
		if data.GuildId and Guilds[data.GuildId] then
			Guilds[data.GuildId].members[player.UserId] = nil
		end
		local newId = "Guild_" .. tostring(player.UserId) .. "_" .. tostring(math.random(100, 999))
		local emblem = (type(arg2) == "string" and #arg2 > 0) and arg2 or "⚔️"
		Guilds[newId] = {
			id          = newId,
			name        = gName,
			emblem      = emblem,
			leaderName  = player.Name,
			houseLevel  = 1,
			treasury    = 0,
			nextUpgrade = 300,
			members     = { [player.UserId] = player.Name },
		}
		data.GuildId = newId
		DataStore.SyncAttributes(player, data)
		if _G.PushCharacterData then _G.PushCharacterData(player) end
		RE_SkillFeedback:FireClient(player, "ก่อตั้งกิลด์ [" .. gName .. "] สำเร็จ!")
		broadcastGuildUpdate()

	elseif action == "Leave" then
		if data.GuildId and Guilds[data.GuildId] then
			Guilds[data.GuildId].members[player.UserId] = nil
		end
		data.GuildId = nil
		DataStore.SyncAttributes(player, data)
		if _G.PushCharacterData then _G.PushCharacterData(player) end
		RE_SkillFeedback:FireClient(player, "ออกจากกิลด์เรียบร้อยแล้ว")
		broadcastGuildUpdate()

	elseif action == "Donate" then
		local g = data.GuildId and Guilds[data.GuildId]
		if not g then
			RE_SkillFeedback:FireClient(player, "คุณยังไม่ได้สังกัดกิลด์")
			return
		end
		if g.houseLevel >= 5 then
			RE_SkillFeedback:FireClient(player, "บ้านกิลด์พัฒนาถึงระดับสูงสุด (Lv.5) แล้ว!")
			return
		end
		local amount = 100
		if not DataStore.ModifyGold(player, -amount) then
			RE_SkillFeedback:FireClient(player, "Zeny ไม่พอสำหรับบริจาค (ต้องใช้ 100 z)")
			return
		end
		g.treasury += amount
		local req = g.houseLevel * 300
		if g.treasury >= req then
			g.treasury -= req
			g.houseLevel += 1
			RE_SkillFeedback:FireClient(player, string.format("🎉 บ้านกิลด์ [%s] อัปเกรดเป็น Lv.%d แล้ว!", g.name, g.houseLevel))
			for uid in pairs(g.members) do
				local mPlayer = Players:GetPlayerByUserId(uid)
				local mData = mPlayer and DataStore.GetPlayerData(mPlayer)
				if mPlayer and mData then
					DataStore.SyncAttributes(mPlayer, mData)
					if _G.PushCharacterData then _G.PushCharacterData(mPlayer) end
				end
			end
		else
			RE_SkillFeedback:FireClient(player, string.format("บริจาค 100 z เข้าบ้านกิลด์แล้ว (%d / %d z)", g.treasury, req))
			if _G.PushCharacterData then _G.PushCharacterData(player) end
		end
		broadcastGuildUpdate()

	elseif action == "TeleportGuildHall" then
		if not data.GuildId or not Guilds[data.GuildId] then
			RE_SkillFeedback:FireClient(player, "ต้องเข้าร่วมกิลด์ก่อนจึงจะวาร์ปกลับบ้านกิลด์ได้")
			return
		end
		data.Map = "Prontera"
		player:SetAttribute("Map", "Prontera")
		player:SetAttribute("SpawnProtectedUntil", os.clock() + 5)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(-22, 4, 82) * CFrame.Angles(0, math.rad(90), 0)
		end
		if _G.PushCharacterData then _G.PushCharacterData(player) end
		RE_SkillFeedback:FireClient(player, "วาร์ปมายังบ้านกิลด์ (Prontera Guild Hall) เรียบร้อย!")
	end
end)

Players.PlayerAdded:Connect(function(player)
	task.wait(1.5)
	local data = DataStore.GetPlayerData(player)
	if data and data.GuildId and Guilds[data.GuildId] then
		Guilds[data.GuildId].members[player.UserId] = player.Name
		DataStore.SyncAttributes(player, data)
	end
end)

_G.GuildSystem = {
	GetGuildBonuses     = getGuildBonuses,
	GetDeathPenaltyMult = getDeathPenaltyMult,
}

print("[GuildSystem] ระบบกิลด์และบ้านกิลด์พร้อมทำงาน / GuildSystem ready")
