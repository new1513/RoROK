-- Session-only party creation, invitations, membership and roster snapshots.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local remotes = ReplicatedStorage:WaitForChild("RemoteEvents", 15)
if not remotes then error("[PartySystem] RemoteEvents folder did not initialize") end

local function getRemote(className, name)
	local remote = remotes:FindFirstChild(name)
	if remote then return remote end
	remote = Instance.new(className)
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local createParty = getRemote("RemoteEvent", "CreateParty")
local invitePlayer = getRemote("RemoteEvent", "InvitePartyPlayer")
local respondInvite = getRemote("RemoteEvent", "RespondPartyInvite")
local leaveParty = getRemote("RemoteEvent", "LeaveParty")
local partyUpdate = getRemote("RemoteEvent", "PartyUpdate")
local partySnapshot = getRemote("RemoteFunction", "RequestPartySnapshot")

local MAX_MEMBERS = 5
local INVITE_LIFETIME = 120
local parties = {} -- [partyId] = {leader = userId, members = {[userId] = true}}
local pendingInvites = {} -- [targetUserId] = {partyId, fromUserId, expiresAt}

local function notify(userId, message)
	local member = Players:GetPlayerByUserId(userId)
	if member then partyUpdate:FireClient(member, message) end
end

local function partyMembers(party)
	local result = {}
	for userId in pairs(party.members) do
		local member = Players:GetPlayerByUserId(userId)
		if member then table.insert(result, member) end
	end
	table.sort(result, function(a, b)
		if a.UserId == party.leader then return true end
		if b.UserId == party.leader then return false end
		return a.UserId < b.UserId
	end)
	return result
end

local function partySize(party)
	local count = 0
	for _ in pairs(party.members) do count += 1 end
	return count
end

local function updateParty(party, message)
	for _, member in ipairs(partyMembers(party)) do
		partyUpdate:FireClient(member, message)
	end
end

local function createFor(player)
	local oldId = player:GetAttribute("PartyId")
	if oldId and parties[oldId] then return parties[oldId] end
	local id = HttpService:GenerateGUID(false)
	local party = { leader = player.UserId, members = { [player.UserId] = true } }
	parties[id] = party
	player:SetAttribute("PartyId", id)
	return party, id
end

local function findParty(player)
	local id = player:GetAttribute("PartyId")
	return id and parties[id], id
end

createParty.OnServerEvent:Connect(function(player)
	local party = findParty(player)
	if party then
		partyUpdate:FireClient(player, "คุณอยู่ในปาร์ตี้แล้ว")
		return
	end
	local _, id = createFor(player)
	local createdParty = parties[id]
	updateParty(createdParty, "สร้างปาร์ตี้แล้ว เชิญสมาชิกได้สูงสุด 4 คน")
end)

invitePlayer.OnServerEvent:Connect(function(player, targetUserId)
	if typeof(targetUserId) ~= "number" then return end
	local party, partyId = findParty(player)
	if not party then
		party, partyId = createFor(player)
	end
	if party.leader ~= player.UserId then
		partyUpdate:FireClient(player, "เฉพาะหัวหน้าปาร์ตี้เท่านั้นที่เชิญสมาชิกได้")
		return
	end
	local target = Players:GetPlayerByUserId(math.floor(targetUserId))
	if not target or target == player then return end
	if target:GetAttribute("PartyId") and target:GetAttribute("PartyId") ~= "" then
		partyUpdate:FireClient(player, "ผู้เล่นนี้อยู่ในปาร์ตี้แล้ว")
		return
	end
	if partySize(party) >= MAX_MEMBERS then
		partyUpdate:FireClient(player, "ปาร์ตี้เต็มแล้ว (สูงสุด 5 คน)")
		return
	end
	pendingInvites[target.UserId] = { partyId = partyId, fromUserId = player.UserId, expiresAt = os.clock() + INVITE_LIFETIME }
	partyUpdate:FireClient(target, player.DisplayName .. " เชิญคุณเข้าปาร์ตี้")
	partyUpdate:FireClient(player, "ส่งคำเชิญให้ " .. target.DisplayName .. " แล้ว (หมดอายุใน 120 วินาที)")
end)

respondInvite.OnServerEvent:Connect(function(player, accepted)
	local invite = pendingInvites[player.UserId]
	pendingInvites[player.UserId] = nil
	if not invite or invite.expiresAt < os.clock() then
		partyUpdate:FireClient(player, "คำเชิญหมดอายุหรือไม่มีคำเชิญค้างอยู่")
		return
	end
	local party = parties[invite.partyId]
	local leader = Players:GetPlayerByUserId(invite.fromUserId)
	if not party or not leader or leader:GetAttribute("PartyId") ~= invite.partyId then
		partyUpdate:FireClient(player, "ปาร์ตี้ของผู้เชิญไม่มีอยู่แล้ว")
		return
	end
	if accepted ~= true then
		partyUpdate:FireClient(player, "ปฏิเสธคำเชิญแล้ว")
		notify(leader.UserId, player.DisplayName .. " ปฏิเสธคำเชิญ")
		return
	end
	if player:GetAttribute("PartyId") and player:GetAttribute("PartyId") ~= "" then
		partyUpdate:FireClient(player, "คุณอยู่ในปาร์ตี้อื่นแล้ว")
		return
	end
	if partySize(party) >= MAX_MEMBERS then
		partyUpdate:FireClient(player, "ปาร์ตี้เต็มแล้ว")
		return
	end
	party.members[player.UserId] = true
	player:SetAttribute("PartyId", invite.partyId)
	updateParty(party, player.DisplayName .. " เข้าร่วมปาร์ตี้แล้ว")
end)

leaveParty.OnServerEvent:Connect(function(player)
	local party, partyId = findParty(player)
	if not party then
		player:SetAttribute("PartyId", "")
		return
	end
	party.members[player.UserId] = nil
	player:SetAttribute("PartyId", "")
	if next(party.members) == nil then
		parties[partyId] = nil
	else
		if party.leader == player.UserId then
			local nextLeader
			for userId in pairs(party.members) do
				if not nextLeader or userId < nextLeader then nextLeader = userId end
			end
			party.leader = nextLeader
		end
		updateParty(party, player.DisplayName .. " ออกจากปาร์ตี้แล้ว")
	end
	partyUpdate:FireClient(player, "ออกจากปาร์ตี้แล้ว")
end)

partySnapshot.OnServerInvoke = function(player)
	local party, partyId = findParty(player)
	local snapshot = {
		partyId = partyId,
		leaderUserId = party and party.leader or nil,
		members = {},
		players = {},
		invite = nil,
	}
	if party then
		for _, member in ipairs(partyMembers(party)) do
			table.insert(snapshot.members, { userId = member.UserId, name = member.DisplayName, isLeader = member.UserId == party.leader })
		end
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			table.insert(snapshot.players, { userId = other.UserId, name = other.DisplayName, inParty = (other:GetAttribute("PartyId") or "") ~= "" })
		end
	end
	table.sort(snapshot.players, function(a, b) return a.name:lower() < b.name:lower() end)
	local invite = pendingInvites[player.UserId]
	if invite and invite.expiresAt >= os.clock() then
		local from = Players:GetPlayerByUserId(invite.fromUserId)
		if from then snapshot.invite = { fromUserId = from.UserId, fromName = from.DisplayName } end
	else
		pendingInvites[player.UserId] = nil
	end
	return snapshot
end

Players.PlayerRemoving:Connect(function(player)
	pendingInvites[player.UserId] = nil
	local party, partyId = findParty(player)
	if not party then return end
	party.members[player.UserId] = nil
	if next(party.members) == nil then
		parties[partyId] = nil
	else
		if party.leader == player.UserId then
			local nextLeader
			for userId in pairs(party.members) do if not nextLeader or userId < nextLeader then nextLeader = userId end end
			party.leader = nextLeader
		end
		updateParty(party, player.DisplayName .. " ออกจากเกมแล้ว")
	end
end)

print("[PartySystem] Session party system ready (max 5)")
