-- Item definitions for RoROK: Equipment, Consumables, Elemental Scrolls, Materials, and Socketable Cards.
local ItemData = {
	-- ── Equipment: Weapons ──────────────────────────────────
	Dagger               = { name = "Dagger",                 type = "Equipment", slot = "Weapon", weaponType = "Dagger",  bonuses = { ATK = 22 }, description = "มีดสั้นพื้นฐาน เหมาะสำหรับ Novice และ Thief" },
	Short_Sword          = { name = "Short Sword",            type = "Equipment", slot = "Weapon", weaponType = "Sword",   bonuses = { ATK = 32 }, description = "ดาบสั้นเหล็กกล้า คล่องตัวและคมกริบ" },
	NoviceTrainingDagger = { name = "Novice Training Dagger", type = "Equipment", slot = "Weapon", weaponType = "Dagger",  bonuses = { ATK = 18 }, description = "มีดสั้นฝึกหัดสำหรับ Novice" },
	ApprenticeRod        = { name = "Apprentice Rod",         type = "Equipment", slot = "Weapon", weaponType = "Rod",     bonuses = { MATK = 22 }, description = "คทาไม้ฝึกหัดสำหรับผู้เริ่มต้น" },
	AcolyteTrainingMace  = { name = "Acolyte Training Mace",  type = "Equipment", slot = "Weapon", weaponType = "Mace",    bonuses = { ATK = 20, MATK = 15 }, description = "กระบองนักบวชฝึกหัด" },
	KnightTrainingSword  = { name = "Knight Training Sword",  type = "Equipment", slot = "Weapon", weaponType = "Sword",   bonuses = { ATK = 30 }, description = "ดาบอัศวินฝึกหัด" },
	ArcherTrainingBow    = { name = "Archer Training Bow",    type = "Equipment", slot = "Weapon", weaponType = "Bow",     bonuses = { ATK = 28 }, description = "ธนูไม้ฝึกหัดระยะไกล" },
	ThiefTrainingDagger  = { name = "Thief Training Dagger",  type = "Equipment", slot = "Weapon", weaponType = "Dagger",  bonuses = { ATK = 25 }, description = "มีดสั้นโจรความเร็วสูง" },
	MerchantTrainingAxe  = { name = "Merchant Training Axe",  type = "Equipment", slot = "Weapon", weaponType = "Axe",     bonuses = { ATK = 32 }, description = "ขวานพ่อค้าฝึกหัด" },
	CloverRod            = { name = "Four-Leaf Apprentice Rod", type = "Equipment", slot = "Weapon", weaponType = "Rod",   bonuses = { MATK = 45, INT = 4 }, description = "คทาใบโคลเวอร์ 4 แฉก เสริมพลังเวทมนตร์" },
	PiratesDagger        = { name = "Drake's Pirate Sabre",   type = "Equipment", slot = "Weapon", weaponType = "Sword",   bonuses = { ATK = 145, AGI = 8 }, description = "ดาบโจรสลัดต้องคำสาปของกัปตัน Drake" },
	MinorousBattleAxe    = { name = "Axe of Minorous",        type = "Equipment", slot = "Weapon", weaponType = "Axe",     bonuses = { ATK = 185, STR = 12 }, description = "ขวานศึกยักษ์ของมินอทอร์ใต้ดิน" },
	-- 2nd Job Weapons
	HalberdOfValor       = { name = "Halberd of Valor",       type = "Equipment", slot = "Weapon", weaponType = "TwoHandSpear", bonuses = { ATK = 165, STR = 10, MaxHP = 400 }, description = "หอกสองมือแห่งความกล้าหาญ อาวุธประจำกายของ Lord Knight" },
	GrandClaymore        = { name = "Grand Claymore",         type = "Equipment", slot = "Weapon", weaponType = "TwoHandSword", bonuses = { ATK = 180, STR = 12, CritRate = 5 }, description = "ดาบยักษ์สองมืออันทรงพลัง อาวุธทำลายล้างของ Lord Knight" },
	HolyJudgementCross   = { name = "Holy Judgement Cross",   type = "Equipment", slot = "Weapon", weaponType = "Mace",         bonuses = { ATK = 105, MATK = 80, INT = 8 }, description = "กระบองกางเขนศักดิ์สิทธิ์ เสริมพลังเวทและการรักษาของ Priest" },
	ArchMageStaff        = { name = "Arch Mage Staff",        type = "Equipment", slot = "Weapon", weaponType = "Staff",        bonuses = { ATK = 35, MATK = 145, INT = 12 }, description = "คทาจอมเวทมหาพายุ เพิ่มพลังทำลายล้างเวทมนตร์ของ Wizard" },
	HunterGaleBow        = { name = "Hunter Gale Bow",        type = "Equipment", slot = "Weapon", weaponType = "Bow",          bonuses = { ATK = 115, DEX = 10, AGI = 6 }, description = "คันศรสายลมเกลคลื่น เพิ่มระยะยิงและความเร็วของ Hunter" },
	KatarOfShadows       = { name = "Katar of Shadows",       type = "Equipment", slot = "Weapon", weaponType = "Katar",        bonuses = { ATK = 110, AGI = 8, CritRate = 12 }, description = "กรงเล็บแห่งเงามืด เพิ่มพลังสังหารและโอกาสคริติคอลของ Assassin" },
	WarhammerOfTitans    = { name = "Warhammer of Titans",    type = "Equipment", slot = "Weapon", weaponType = "TwoHandAxe",   bonuses = { ATK = 175, STR = 14, MaxHP = 350 }, description = "ค้อนสงครามยักษ์ไททัน อาวุธทุบทำลายล้างของ Blacksmith" },

	-- ── Equipment: Armor ────────────────────────────────────
	NoviceClothes = { name = "Novice Clothes", type = "Equipment", slot = "Armor", bonuses = { DEF = 10, MaxHP = 50 }, description = "ชุดผ้าฝ้ายสำหรับนักผจญภัยหน้าใหม่" },
	PoringHood    = { name = "Poring Hood",    type = "Equipment", slot = "Armor", bonuses = { DEF = 18, MaxHP = 150, LUK = 2 }, description = "เสื้อคลุมฮู้ดสลิมชมพู น่ารักและทนทาน" },
	ChainMail     = { name = "Prontera Chain Mail", type = "Equipment", slot = "Armor", bonuses = { DEF = 45, MaxHP = 400, VIT = 4 }, description = "เกราะโซ่เหล็กกล้าแห่งอัศวิน Prontera" },

	-- ── Consumables (Potions & Status Recovery) ─────────────
	RedPotion    = { name = "Red Potion",    type = "Consumable", buyPrice = 20, sellPrice = 5,  use = { HP = 250 }, description = "ฟื้นฟู HP 250" },
	OrangePotion = { name = "Orange Potion", type = "Consumable", buyPrice = 45, sellPrice = 12, use = { HP = 600 }, description = "ฟื้นฟู HP 600 ขนาดกลาง" },
	YellowPotion = { name = "Yellow Potion", type = "Consumable", buyPrice = 60, sellPrice = 16, use = { HP = 1200 }, description = "ฟื้นฟู HP 1200 ขนาดใหญ่" },
	WhitePotion  = { name = "White Potion",  type = "Consumable", buyPrice = 75, sellPrice = 20, use = { HP = 2500 }, description = "ฟื้นฟู HP 2500 สำหรับดันเจี้ยนและบอส" },
	BluePotion   = { name = "Blue Potion",   type = "Consumable", buyPrice = 15, sellPrice = 4,  use = { SP = 150 }, description = "ฟื้นฟู SP 150" },
	Panacea     = { name = "Panacea",      type = "Consumable", buyPrice = 35, sellPrice = 10, use = { CureAll = true, HP = 20 }, description = "ยาครอบจักรวาล ล้างสถานะผิดปกติทั้งหมด + ฟื้นฟู HP 20" },
	Green_Herb   = { name = "Green Herb",    type = "Consumable", buyPrice = 12, sellPrice = 4,  use = { HP = 60 },  description = "สมุนไพรสีเขียว ฟื้นฟู HP 60" },
	Carrot      = { name = "Carrot",       type = "Consumable",                sellPrice = 3,  use = { HP = 80 },  description = "ฟื้นฟู HP 80" },

	-- ── Elemental Scrolls (ใบธาตุเคลือบอาวุธ) ────────────────
	FireScroll   = { name = "Fire Elemental Scroll",   type = "Consumable", buyPrice = 50, sellPrice = 15, use = { CoatElement = "Fire",   Duration = 300 }, description = "เคลือบอาวุธเป็นธาตุไฟ (Fire) นาน 5 นาที" },
	WaterScroll  = { name = "Water Elemental Scroll",  type = "Consumable", buyPrice = 50, sellPrice = 15, use = { CoatElement = "Water",  Duration = 300 }, description = "เคลือบอาวุธเป็นธาตุน้ำ (Water) นาน 5 นาที" },
	WindScroll   = { name = "Wind Elemental Scroll",   type = "Consumable", buyPrice = 50, sellPrice = 15, use = { CoatElement = "Wind",   Duration = 300 }, description = "เคลือบอาวุธเป็นธาตุลม (Wind) นาน 5 นาที" },
	EarthScroll  = { name = "Earth Elemental Scroll",  type = "Consumable", buyPrice = 50, sellPrice = 15, use = { CoatElement = "Earth",  Duration = 300 }, description = "เคลือบอาวุธเป็นธาตุดิน (Earth) นาน 5 นาที" },
	HolyScroll   = { name = "Holy Elemental Scroll",   type = "Consumable", buyPrice = 65, sellPrice = 20, use = { CoatElement = "Holy",   Duration = 300 }, description = "เคลือบอาวุธเป็นธาตุศักดิ์สิทธิ์ (Holy) นาน 5 นาที" },
	ShadowScroll = { name = "Shadow Elemental Scroll", type = "Consumable", buyPrice = 65, sellPrice = 20, use = { CoatElement = "Shadow", Duration = 300 }, description = "เคลือบอาวุธเป็นธาตุเงามืด (Shadow) นาน 5 นาที" },

	-- ── Materials: Prontera & Culvert ───────────────────────
	Jellopy        = { name = "Jellopy",          type = "Material", sellPrice = 2  },
	StickyMucus    = { name = "Sticky Mucus",      type = "Material", sellPrice = 4  },
	FourLeafClover = { name = "Four Leaf Clover",  type = "Material", sellPrice = 25 },
	RawMeat        = { name = "Raw Meat",          type = "Material", sellPrice = 6  },
	Hide           = { name = "Hide",              type = "Material", sellPrice = 8  },
	Bone           = { name = "Bone",              type = "Material", sellPrice = 5  },
	WolfFang       = { name = "Wolf Fang",         type = "Material", sellPrice = 12 },
	RottenBandage  = { name = "Rotten Bandage",    type = "Material", sellPrice = 3  },
	Skull          = { name = "Skull",             type = "Material", sellPrice = 10 },
	IronOre        = { name = "Iron Ore",          type = "Material", sellPrice = 18 },

	-- ── Materials: Morroc & Amatsu ──────────────────────────
	Scale          = { name = "Reptile Scale",     type = "Material", sellPrice = 8  },
	Yellow_Gemstone = { name = "Yellow Gemstone",   type = "Material", sellPrice = 25 },
	ScorpionTail   = { name = "Scorpion Tail",     type = "Material", sellPrice = 22 },
	EmbalmingCloth = { name = "Embalming Cloth",   type = "Material", sellPrice = 30 },
	MermaidScale   = { name = "Mermaid Scale",     type = "Material", sellPrice = 38 },
	FireCrystal    = { name = "Fire Crystal",      type = "Material", sellPrice = 85 },
	EarthCrystal   = { name = "Earth Crystal",     type = "Material", sellPrice = 95 },

	-- ── Socketable Monster Cards (เสียบลงในช่อง Weapon หรือ Armor) ──
	PoringCard = {
		name = "Poring Card", type = "Card", slot = "Armor", sellPrice = 100,
		bonuses = { MaxHP = 250, LUK = 2 },
		description = "[ใส่เกราะ Armor] MaxHP +250, LUK +2",
	},
	LunaticCard = {
		name = "Lunatic Card", type = "Card", slot = "Weapon", sellPrice = 150,
		bonuses = { ATK = 3, LUK = 3 },
		description = "[ใส่อาวุธ Weapon] ATK +3, LUK +3",
	},
	WolfCard = {
		name = "Wolf Card", type = "Card", slot = "Weapon", sellPrice = 200,
		bonuses = { ATK = 6, STR = 2 },
		description = "[ใส่อาวุธ Weapon] ATK +6, STR +2",
	},
	ZombieCard = {
		name = "Zombie Card", type = "Card", slot = "Armor", sellPrice = 180,
		bonuses = { MaxHP = 45, VIT = 2 },
		description = "[ใส่เกราะ Armor] MaxHP +45, VIT +2",
	},
	SkeletonCard = {
		name = "Skeleton Card", type = "Card", slot = "Weapon", sellPrice = 220,
		bonuses = { ATK = 8, DEX = 2 },
		description = "[ใส่อาวุธ Weapon] ATK +8, DEX +2",
	},
	MinorousCard = {
		name = "Minorous Card", type = "Card", slot = "Weapon", sellPrice = 450,
		bonuses = { ATK = 14, STR = 4 },
		description = "[ใส่อาวุธ Weapon] ATK +14, STR +4",
	},
	DrakeCard = {
		name = "Drake Boss Card", type = "Card", slot = "Weapon", sellPrice = 900,
		bonuses = { ATK = 20, MATK = 16,AGI = 4 },
		description = "[การ์ดบอสใส่อาวุธ] ATK +20, MATK +16, AGI +4",
	},
	ScorpionCard = {
		name = "Scorpion Card", type = "Card", slot = "Weapon", sellPrice = 320,
		bonuses = { ATK = 11, DEX = 3 },
		description = "[ใส่อาวุธ Weapon] ATK +11, DEX +3",
	},
	MummyCard = {
		name = "Mummy Card", type = "Card", slot = "Armor", sellPrice = 360,
		bonuses = { MaxHP = 75, DEF = 5 },
		description = "[ใส่เกราะ Armor] MaxHP +75, DEF +5",
	},
	EddgaCard = {
		name = "Eddga World Boss Card", type = "Card", slot = "Armor", sellPrice = 1800,
		bonuses = { MaxHP = 150, STR = 6, DEF = 8 },
		description = "[การ์ดเวิลด์บอสใส่เกราะ] MaxHP +150, STR +6, DEF +8",
	},
	SwordfishCard = {
		name = "Swordfish Card", type = "Card", slot = "Armor", sellPrice = 420,
		bonuses = { MaxHP = 90, MDEF = 8 },
		description = "[ใส่เกราะ Armor] MaxHP +90, MDEF +8",
	},
	TenguCard = {
		name = "Tengu Card", type = "Card", slot = "Weapon", sellPrice = 520,
		bonuses = { ATK = 16, AGI = 5 },
		description = "[ใส่อาวุธ Weapon] ATK +16, AGI +5",
	},
	TurtleGeneralCard = {
		name = "Turtle General World Boss Card", type = "Card", slot = "Weapon", sellPrice = 2500,
		bonuses = { ATK = 32, STR = 8, DEF = 10 },
		description = "[การ์ดเวิลด์บอสใส่อาวุธ] ATK +32, STR +8, DEF +10",
	},
	GoldenThiefBugCard = {
		name = "Golden Thief Bug MVP Card", type = "Card", slot = "Armor", sellPrice = 5000,
		bonuses = { MDEF = 80, MaxHP = 1200, DEF = 25 },
		description = "[การ์ดบอส MVP ใส่เกราะ] ป้องกันเวทมนตร์ MDEF +80, MaxHP +1,200",
	},

	-- ── Crafting / Enhancement ───────────────────────────────
	BeginnerRefinementStone = { name = "Beginner Refinement Stone", type = "Material", buyPrice = 50, sellPrice = 15, description = "หินตีบวกอุปกรณ์ +1 ถึง +15 ที่โรงตีเหล็ก" },
	GoldRing        = { name = "Gold Ring",          type = "Material", sellPrice = 1500, description = "แหวนทองคำล้ำค่าจากรังแมลงทองคำ" },
}
-- ── ID Aliases (Backward & Drop Compatibility without duplicating tables) ──
ItemData.Iron_Ore = ItemData.IronOre
ItemData.Sticky_Mucus = ItemData.StickyMucus
ItemData.Items = ItemData
ItemData.GetItem = function(id)
	return ItemData[id]
end
return ItemData
