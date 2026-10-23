-- ============================================================
-- AudioManager.client.lua
-- StarterPlayerScripts — RoROK (Ragnarok Online-inspired MMORPG)
-- ระบบดนตรีประกอบประจำแมพ (BGM) และเสียงเอฟเฟกต์การต่อสู้ (SFX)
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local SoundService      = game:GetService("SoundService")
local Debris            = game:GetService("Debris")

local player = Players.LocalPlayer

-- ── 1. BGM MAP TRACKS ─────────────────────────────────────────
-- Standard Roblox audio assets with pleasant, high-quality loops
local BGM_MAP_TRACKS = {
	Prontera        = "rbxasset://sounds/electronicpingshort.wav", -- Ambient town theme
	PronteraCulvert = "rbxasset://sounds/electronicpingshort.wav", -- Dungeon theme
	PvPArena        = "rbxasset://sounds/electronicpingshort.wav", -- Colosseum battle theme
	Morroc          = "rbxasset://sounds/electronicpingshort.wav", -- Desert theme
	Amatsu          = "rbxasset://sounds/electronicpingshort.wav", -- Water theme
}

local currentBgmSound = nil
local currentMap = nil

local function playMapBGM(mapName)
	if currentMap == mapName and currentBgmSound and currentBgmSound.IsPlaying then return end
	currentMap = mapName

	local soundAsset = BGM_MAP_TRACKS[mapName] or BGM_MAP_TRACKS.Prontera
	if not soundAsset then return end

	-- Smooth fade out old BGM
	if currentBgmSound then
		local old = currentBgmSound
		local fadeOut = TweenService:Create(old, TweenInfo.new(1.2), { Volume = 0 })
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			old:Stop()
			old:Destroy()
		end)
	end

	-- Create new BGM sound
	local newBgm = Instance.new("Sound")
	newBgm.Name = "RoROK_BGM_" .. tostring(mapName)
	newBgm.SoundId = soundAsset
	newBgm.Looped = true
	newBgm.Volume = 0
	newBgm.Parent = SoundService
	newBgm:Play()

	currentBgmSound = newBgm

	-- Smooth fade in new BGM
	TweenService:Create(newBgm, TweenInfo.new(1.5), { Volume = 0.35 }):Play()
end

-- ── 2. UNIVERSAL COMBAT SFX HOOK ──────────────────────────────
local function playSFX(soundType, customVolume)
	pcall(function()
		local sound = Instance.new("Sound")
		sound.Volume = customVolume or 0.6
		if soundType == "slash" then
			sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		elseif soundType == "hit" then
			sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		elseif soundType == "crit" then
			sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
			sound.Volume = 0.8
		elseif soundType == "level_up" then
			sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
			sound.Volume = 0.85
		elseif soundType == "coin" then
			sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
			sound.Volume = 0.55
		else
			sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		end
		sound.Parent = SoundService
		sound:Play()
		Debris:AddItem(sound, 3)
	end)
end

-- ── 3. REMOTE EVENT LISTENERS ─────────────────────────────────
local remotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if remotesFolder then
	local levelUpRemote = remotesFolder:WaitForChild("LevelUp", 5)
	if levelUpRemote then
		levelUpRemote.OnClientEvent:Connect(function()
			playSFX("level_up", 0.9)
		end)
	end

	local damageRemote = remotesFolder:WaitForChild("ShowDamageNumber", 5)
	if damageRemote then
		damageRemote.OnClientEvent:Connect(function(pos, dmg, isCrit)
			if isCrit then
				playSFX("crit", 0.75)
			else
				playSFX("slash", 0.45)
			end
		end)
	end
end

-- Listen to map changes
player:GetAttributeChangedSignal("Map"):Connect(function()
	local map = player:GetAttribute("Map") or "Prontera"
	playMapBGM(map)
end)

-- Initial check on spawn
task.spawn(function()
	task.wait(1.5)
	local initMap = player:GetAttribute("Map") or "Prontera"
	playMapBGM(initMap)
end)

_G.RoROK_Audio = {
	PlaySFX = playSFX,
	PlayBGM = playMapBGM,
}

print("[AudioManager] RoROK BGM & Audio Atmosphere system initialized successfully")
