-- Party controls are kept outside UIManager to keep its large HUD chunk small.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("RemoteEvents", 20)
if not remotes then return end
local createParty = remotes:WaitForChild("CreateParty")
local invitePlayer = remotes:WaitForChild("InvitePartyPlayer")
local respondInvite = remotes:WaitForChild("RespondPartyInvite")
local leaveParty = remotes:WaitForChild("LeaveParty")
local partyUpdate = remotes:WaitForChild("PartyUpdate")
local requestSnapshot = remotes:WaitForChild("RequestPartySnapshot")

local function color(hex)
	return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
end

local gui = Instance.new("ScreenGui")
gui.Name = "PartyControls"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Name = "PartyButton"
button.Size = UDim2.fromOffset(146, 32)
button.Position = UDim2.new(0, 14, 0, 144)
button.BackgroundColor3 = color("141e33")
button.BackgroundTransparency = 0.06
button.TextColor3 = color("f8fafc")
button.Font = Enum.Font.GothamBold
button.TextSize = 12
button.Text = "👥 ปาร์ตี้ / ทีม"
button.Parent = gui
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 9)
local btnStroke = Instance.new("UIStroke", button)
btnStroke.Color = color("e5c158")
btnStroke.Thickness = 1.3

local panel = Instance.new("Frame")
panel.Name = "PartyPanel"
panel.Size = UDim2.fromOffset(440, 470)
panel.Position = UDim2.new(0.5, -220, 0.5, -235)
panel.BackgroundColor3 = color("151626")
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = color("ffd34f")
stroke.Thickness = 2

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -58, 0, 38)
title.Position = UDim2.fromOffset(14, 6)
title.BackgroundTransparency = 1
title.Text = "👥 ปาร์ตี้ (สูงสุด 5 คน)"
title.TextColor3 = color("ffe082")
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(32, 30)
close.Position = UDim2.new(1, -42, 0, 8)
close.BackgroundColor3 = color("842d37")
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBold
close.TextSize = 13
close.Parent = panel
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
close.Activated:Connect(function() panel.Visible = false end)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -28, 0, 32)
status.Position = UDim2.fromOffset(14, 44)
status.BackgroundTransparency = 1
status.Text = "สร้างปาร์ตี้หรือเชิญผู้เล่นในเซิร์ฟเวอร์"
status.TextColor3 = color("c7cbe0")
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextWrapped = true
status.Parent = panel

local create = Instance.new("TextButton")
create.Size = UDim2.fromOffset(132, 32)
create.Position = UDim2.fromOffset(14, 78)
create.BackgroundColor3 = color("315a4a")
create.Text = "＋ สร้างปาร์ตี้"
create.TextColor3 = Color3.new(1, 1, 1)
create.Font = Enum.Font.GothamBold
create.TextSize = 12
create.Parent = panel
Instance.new("UICorner", create).CornerRadius = UDim.new(0, 6)
create.Activated:Connect(function() createParty:FireServer() end)

local leave = Instance.new("TextButton")
leave.Size = UDim2.fromOffset(132, 32)
leave.Position = UDim2.fromOffset(154, 78)
leave.BackgroundColor3 = color("6a3740")
leave.Text = "ออกจากปาร์ตี้"
leave.TextColor3 = Color3.new(1, 1, 1)
leave.Font = Enum.Font.GothamBold
leave.TextSize = 12
leave.Parent = panel
Instance.new("UICorner", leave).CornerRadius = UDim.new(0, 6)
leave.Activated:Connect(function() leaveParty:FireServer() end)

local incoming = Instance.new("Frame")
incoming.Size = UDim2.new(1, -28, 0, 42)
incoming.Position = UDim2.fromOffset(14, 118)
incoming.BackgroundColor3 = color("292945")
incoming.BorderSizePixel = 0
incoming.Visible = false
incoming.Parent = panel
Instance.new("UICorner", incoming).CornerRadius = UDim.new(0, 6)
local inviteText = Instance.new("TextLabel")
inviteText.Size = UDim2.new(1, -170, 1, 0)
inviteText.Position = UDim2.fromOffset(8, 0)
inviteText.BackgroundTransparency = 1
inviteText.TextColor3 = Color3.new(1, 1, 1)
inviteText.Font = Enum.Font.GothamSemibold
inviteText.TextSize = 11
inviteText.TextXAlignment = Enum.TextXAlignment.Left
inviteText.Parent = incoming
local accept = Instance.new("TextButton")
accept.Size = UDim2.fromOffset(70, 28)
accept.Position = UDim2.new(1, -152, 0.5, -14)
accept.BackgroundColor3 = color("287a48")
accept.Text = "เข้าร่วม"
accept.TextColor3 = Color3.new(1, 1, 1)
accept.Font = Enum.Font.GothamBold
accept.TextSize = 11
accept.Parent = incoming
local decline = Instance.new("TextButton")
decline.Size = UDim2.fromOffset(70, 28)
decline.Position = UDim2.new(1, -76, 0.5, -14)
decline.BackgroundColor3 = color("65353d")
decline.Text = "ปฏิเสธ"
decline.TextColor3 = Color3.new(1, 1, 1)
decline.Font = Enum.Font.GothamBold
decline.TextSize = 11
decline.Parent = incoming
for _, b in ipairs({accept, decline}) do Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5) end
accept.Activated:Connect(function() respondInvite:FireServer(true) end)
decline.Activated:Connect(function() respondInvite:FireServer(false) end)

local memberTitle = Instance.new("TextLabel")
memberTitle.Size = UDim2.new(1, -28, 0, 22)
memberTitle.Position = UDim2.fromOffset(14, 164)
memberTitle.BackgroundTransparency = 1
memberTitle.Text = "สมาชิก"
memberTitle.TextColor3 = color("ffe082")
memberTitle.Font = Enum.Font.GothamBold
memberTitle.TextSize = 12
memberTitle.TextXAlignment = Enum.TextXAlignment.Left
memberTitle.Parent = panel
local memberList = Instance.new("TextLabel")
memberList.Size = UDim2.new(1, -28, 0, 54)
memberList.Position = UDim2.fromOffset(14, 186)
memberList.BackgroundColor3 = color("202038")
memberList.TextColor3 = color("e5e8f2")
memberList.Font = Enum.Font.Gotham
memberList.TextSize = 12
memberList.TextXAlignment = Enum.TextXAlignment.Left
memberList.TextYAlignment = Enum.TextYAlignment.Top
memberList.TextWrapped = true
memberList.Parent = panel
Instance.new("UICorner", memberList).CornerRadius = UDim.new(0, 6)

local onlineTitle = Instance.new("TextLabel")
onlineTitle.Size = UDim2.new(1, -28, 0, 22)
onlineTitle.Position = UDim2.fromOffset(14, 247)
onlineTitle.BackgroundTransparency = 1
onlineTitle.Text = "ผู้เล่นในเซิร์ฟเวอร์ • เชิญได้โดยหัวหน้าปาร์ตี้"
onlineTitle.TextColor3 = color("ffe082")
onlineTitle.Font = Enum.Font.GothamBold
onlineTitle.TextSize = 12
onlineTitle.TextXAlignment = Enum.TextXAlignment.Left
onlineTitle.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Name = "OnlinePlayers"
list.Size = UDim2.new(1, -28, 0, 188)
list.Position = UDim2.fromOffset(14, 273)
list.BackgroundColor3 = color("10111d")
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel
Instance.new("UICorner", list).CornerRadius = UDim.new(0, 6)
local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0, 4)
local padding = Instance.new("UIPadding", list)
padding.PaddingTop = UDim.new(0, 4)
padding.PaddingLeft = UDim.new(0, 4)
padding.PaddingRight = UDim.new(0, 4)

local busy = false
local function refresh()
	if busy then return end
	busy = true
	local ok, snapshot = pcall(function() return requestSnapshot:InvokeServer() end)
	busy = false
	if not ok or type(snapshot) ~= "table" then
		status.Text = "โหลดข้อมูลปาร์ตี้ไม่สำเร็จ ลองเปิดหน้าต่างอีกครั้ง"
		return
	end
	local isInParty = snapshot.partyId ~= nil and snapshot.partyId ~= ""
	local isLeader = snapshot.leaderUserId == player.UserId
	create.Visible = not isInParty
	leave.Visible = isInParty
	memberTitle.Text = isInParty and string.format("สมาชิก (%d/5)", #snapshot.members) or "สมาชิก (ยังไม่มีปาร์ตี้)"
	local names = {}
	for _, entry in ipairs(snapshot.members) do
		table.insert(names, (entry.isLeader and "👑 " or "• ") .. entry.name .. (entry.isLeader and " — หัวหน้า" or ""))
	end
	memberList.Text = #names > 0 and ("  " .. table.concat(names, "\n  ")) or "  สร้างปาร์ตี้เพื่อเริ่มเชิญสมาชิก"
	incoming.Visible = snapshot.invite ~= nil
	if snapshot.invite then inviteText.Text = snapshot.invite.fromName .. " เชิญเข้าปาร์ตี้" end
	for _, child in ipairs(list:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
	for index, entry in ipairs(snapshot.players) do
		local row = Instance.new("Frame")
		row.Name = "Player_" .. entry.userId
		row.Size = UDim2.new(1, -8, 0, 34)
		row.BackgroundColor3 = color("22243a")
		row.BorderSizePixel = 0
		row.LayoutOrder = index
		row.Parent = list
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(1, -112, 1, 0)
		name.Position = UDim2.fromOffset(8, 0)
		name.BackgroundTransparency = 1
		name.Text = entry.name .. (entry.inParty and " • อยู่ในปาร์ตี้" or "")
		name.TextColor3 = color("eeeeF7")
		name.Font = Enum.Font.Gotham
		name.TextSize = 11
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = row
		local invite = Instance.new("TextButton")
		invite.Size = UDim2.fromOffset(92, 26)
		invite.Position = UDim2.new(1, -98, 0.5, -13)
		invite.BackgroundColor3 = color("315a9b")
		invite.Text = entry.inParty and "ไม่ว่าง" or (isLeader and "เชิญ" or "หัวหน้าเท่านั้น")
		invite.TextColor3 = Color3.new(1, 1, 1)
		invite.Font = Enum.Font.GothamBold
		invite.TextSize = 10
		invite.Active = isLeader and not entry.inParty
		invite.AutoButtonColor = invite.Active
		invite.Parent = row
		Instance.new("UICorner", invite).CornerRadius = UDim.new(0, 5)
		local targetUserId = entry.userId
		invite.Activated:Connect(function()
			if isLeader and not entry.inParty then invitePlayer:FireServer(targetUserId) end
		end)
	end
end

button.Activated:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then refresh() end
end)
partyUpdate.OnClientEvent:Connect(function(message)
	if typeof(message) == "string" then status.Text = message end
	if typeof(message) == "string" and message:find("เชิญคุณเข้าปาร์ตี้", 1, true) then panel.Visible = true end
	if panel.Visible then task.defer(refresh) end
end)
player:GetAttributeChangedSignal("PartyId"):Connect(function()
	if panel.Visible then refresh() end
end)
Players.PlayerAdded:Connect(function() if panel.Visible then refresh() end end)
Players.PlayerRemoving:Connect(function() if panel.Visible then task.defer(refresh) end end)
