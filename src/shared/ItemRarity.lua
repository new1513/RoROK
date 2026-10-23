-- ระบบความหายากของไอเทม / Item rarity system
-- ใช้ร่วมกันทั้ง Client (สีใน Inventory) และ Server (แสงของที่ดรอป)
local ItemData = require(script.Parent:WaitForChild("ItemData"))

local ItemRarity = {}

ItemRarity.Tiers = {
	Common    = { order = 1, name = "Common",    nameThai = "ธรรมดา",     color = Color3.fromRGB(220, 220, 228) },
	Uncommon  = { order = 2, name = "Uncommon",  nameThai = "ไม่ธรรมดา",  color = Color3.fromRGB(110, 220, 120) },
	Rare      = { order = 3, name = "Rare",      nameThai = "หายาก",      color = Color3.fromRGB(90, 160, 255) },
	Epic      = { order = 4, name = "Epic",      nameThai = "มหากาพย์",   color = Color3.fromRGB(190, 110, 255) },
	Legendary = { order = 5, name = "Legendary", nameThai = "ตำนาน",      color = Color3.fromRGB(255, 190, 60) },
}

-- กำหนดเองเฉพาะบางชิ้น ที่เหลือคำนวณอัตโนมัติ
local overrides = {
	PoringHood = "Uncommon",
	CloverRod = "Rare",
	FourLeafClover = "Rare",
	BeginnerRefinementStone = "Uncommon",
	WolfCard = "Epic",
	SkeletonCard = "Epic",
}

function ItemRarity.GetRarityName(itemId)
	if overrides[itemId] then return overrides[itemId] end
	local item = ItemData[itemId]
	if not item then return "Common" end
	if item.rarity and ItemRarity.Tiers[item.rarity] then return item.rarity end
	if item.type == "Card" then return "Epic" end
	if item.type == "Equipment" then
		local total = 0
		for _, v in pairs(item.bonuses or {}) do total += tonumber(v) or 0 end
		if total >= 6 then return "Rare" elseif total >= 4 then return "Uncommon" end
		return "Common"
	end
	local price = tonumber(item.sellPrice) or 0
	if price >= 20 then return "Rare" elseif price >= 8 then return "Uncommon" end
	return "Common"
end

function ItemRarity.GetTier(itemId)
	return ItemRarity.Tiers[ItemRarity.GetRarityName(itemId)]
end

function ItemRarity.GetColor(itemId)
	return ItemRarity.GetTier(itemId).color
end

return ItemRarity
