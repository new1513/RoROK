-- Shared monster definitions across Prontera, Prontera Culvert Dungeon, Morroc Desert, and Amatsu Island.
-- Calibrated to Ragnarok M: Eternal Love 1:1 Battle Scaling (Option 2).
return {
	-- ═══════════════════════════════════════════════════════════
	-- 1. PRONTERA FIELD (Lv. 1–10)
	-- ═══════════════════════════════════════════════════════════
	Poring = {
		Name = "Poring", Level = 1, MaxHP = 350, ATK = 18, DEF = 5, MDEF = 2,
		HIT = 45, FLEE = 5, PerfectDodge = 0, Element = "Water", Size = "Small",
		XP = 18, JobXP = 8, RespawnTime = 12, AggroRange = 18, AttackRange = 5,
		MoveSpeed = 6, AttackCooldown = 2.5, Color = Color3.fromRGB(255, 105, 170),
		Drops = {
			{ itemId = "Jellopy",     chance = 65,  quantity = 1 },
			{ itemId = "StickyMucus", chance = 25,  quantity = 1 },
			{ itemId = "PoringCard",  chance = 2.5, quantity = 1 },
		},
	},
	Fabre = {
		Name = "Fabre", Level = 2, MaxHP = 480, ATK = 24, DEF = 8, MDEF = 3,
		HIT = 48, FLEE = 8, PerfectDodge = 0, Element = "Earth", Size = "Small",
		XP = 24, JobXP = 11, RespawnTime = 14, AggroRange = 0, AttackRange = 5,
		MoveSpeed = 6, AttackCooldown = 2.4, Color = Color3.fromRGB(115, 195, 85),
		Drops = {
			{ itemId = "Jellopy",     chance = 60,  quantity = 1 },
			{ itemId = "StickyMucus", chance = 20,  quantity = 1 },
			{ itemId = "FourLeafClover", chance = 5, quantity = 1 },
		},
	},
	Lunatic = {
		Name = "Lunatic", Level = 3, MaxHP = 650, ATK = 32, DEF = 10, MDEF = 5,
		HIT = 52, FLEE = 12, PerfectDodge = 0, Element = "Neutral", Size = "Small",
		XP = 35, JobXP = 15, RespawnTime = 18, AggroRange = 0, AttackRange = 5,
		MoveSpeed = 8, AttackCooldown = 2.2, Color = Color3.fromRGB(190, 150, 235),
		Drops = {
			{ itemId = "Carrot",         chance = 45,  quantity = 1 },
			{ itemId = "FourLeafClover", chance = 8,   quantity = 1 },
			{ itemId = "LunaticCard",    chance = 2.0, quantity = 1 },
		},
	},
	Wolf = {
		Name = "Wolf", Level = 5, MaxHP = 1696, ATK = 75, DEF = 25, MDEF = 10,
		HIT = 65, FLEE = 30, PerfectDodge = 0, Element = "Neutral", Size = "Medium",
		XP = 80, JobXP = 35, RespawnTime = 25, AggroRange = 20, AttackRange = 5,
		MoveSpeed = 10, AttackCooldown = 1.8, Color = Color3.fromRGB(120, 110, 90),
		Drops = {
			{ itemId = "RawMeat",  chance = 35,  quantity = 1 },
			{ itemId = "Hide",     chance = 22,  quantity = 1 },
			{ itemId = "Bone",     chance = 18,  quantity = 1 },
			{ itemId = "WolfFang", chance = 12,  quantity = 1 },
			{ itemId = "WolfCard", chance = 2.0, quantity = 1 },
		},
	},
	Zombie = {
		Name = "Zombie", Level = 8, MaxHP = 2800, ATK = 110, DEF = 30, MDEF = 8,
		HIT = 60, FLEE = 15, PerfectDodge = 0, Element = "Undead", Size = "Medium",
		XP = 145, JobXP = 60, RespawnTime = 30, AggroRange = 15, AttackRange = 5,
		MoveSpeed = 5, AttackCooldown = 2.6, Color = Color3.fromRGB(90, 115, 70),
		StatusOnHit = "Poison", StatusChance = 15,
		Drops = {
			{ itemId = "RottenBandage", chance = 30,  quantity = 1 },
			{ itemId = "Jellopy",       chance = 20,  quantity = 1 },
			{ itemId = "Bone",          chance = 12,  quantity = 1 },
			{ itemId = "ZombieCard",    chance = 1.8, quantity = 1 },
		},
	},
	Skeleton = {
		Name = "Skeleton", Level = 10, MaxHP = 3600, ATK = 145, DEF = 45, MDEF = 15,
		HIT = 72, FLEE = 20, PerfectDodge = 0, Element = "Undead", Size = "Medium",
		XP = 200, JobXP = 88, RespawnTime = 35, AggroRange = 15, AttackRange = 5,
		MoveSpeed = 7, AttackCooldown = 2.3, Color = Color3.fromRGB(220, 210, 185),
		StatusOnHit = "Stun", StatusChance = 12,
		Drops = {
			{ itemId = "Bone",         chance = 38,  quantity = 1 },
			{ itemId = "Skull",        chance = 15,  quantity = 1 },
			{ itemId = "SkeletonCard", chance = 1.8, quantity = 1 },
		},
	},
	Goblin = {
		Name = "Goblin", Level = 15, MaxHP = 4500, ATK = 180, DEF = 55, MDEF = 20,
		HIT = 80, FLEE = 28, PerfectDodge = 0, Element = "Earth", Size = "Small",
		XP = 110, JobXP = 52, RespawnTime = 18, AggroRange = 16, AttackRange = 5,
		MoveSpeed = 8, AttackCooldown = 2.0, Color = Color3.fromRGB(110, 145, 80),
		Drops = {
			{ itemId = "Jellopy",     chance = 45,  quantity = 1 },
			{ itemId = "IronOre",    chance = 20,  quantity = 1 },
			{ itemId = "Dagger",      chance = 5,   quantity = 1 },
		},
	},
	GoblinRaider = {
		Name = "Goblin Raider", Level = 28, MaxHP = 12000, ATK = 320, DEF = 110, MDEF = 45,
		HIT = 115, FLEE = 50, PerfectDodge = 0, Element = "Earth", Size = "Small",
		XP = 320, JobXP = 145, RespawnTime = 22, AggroRange = 22, AttackRange = 5,
		MoveSpeed = 9, AttackCooldown = 1.8, Color = Color3.fromRGB(135, 105, 60),
		Drops = {
			{ itemId = "IronOre",    chance = 35,  quantity = 1 },
			{ itemId = "Short_Sword", chance = 8,   quantity = 1 },
			{ itemId = "Yellow_Gemstone", chance = 5, quantity = 1 },
		},
	},
	Spider = {
		Name = "Spider", Level = 24, MaxHP = 8500, ATK = 250, DEF = 75, MDEF = 35,
		HIT = 105, FLEE = 45, PerfectDodge = 0, Element = "Poison", Size = "Medium",
		XP = 260, JobXP = 120, RespawnTime = 20, AggroRange = 18, AttackRange = 5,
		MoveSpeed = 9, AttackCooldown = 2.0, Color = Color3.fromRGB(75, 55, 95),
		StatusOnHit = "Poison", StatusChance = 20,
		Drops = {
			{ itemId = "StickyMucus", chance = 50,  quantity = 1 },
			{ itemId = "Panacea",     chance = 6,   quantity = 1 },
		},
	},
	PoisonSnake = {
		Name = "Poison Snake", Level = 26, MaxHP = 9800, ATK = 280, DEF = 85, MDEF = 40,
		HIT = 110, FLEE = 48, PerfectDodge = 0, Element = "Poison", Size = "Medium",
		XP = 290, JobXP = 135, RespawnTime = 20, AggroRange = 20, AttackRange = 5,
		MoveSpeed = 10, AttackCooldown = 1.9, Color = Color3.fromRGB(45, 120, 110),
		StatusOnHit = "Poison", StatusChance = 25,
		Drops = {
			{ itemId = "Scale",       chance = 40,  quantity = 1 },
			{ itemId = "Green_Herb",  chance = 25,  quantity = 1 },
			{ itemId = "Panacea",     chance = 8,   quantity = 1 },
		},
	},

	-- ═══════════════════════════════════════════════════════════
	-- 2. PRONTERA CULVERT DUNGEON (Lv. 12–20 & Bosses)
	-- ═══════════════════════════════════════════════════════════
	ThiefBug = {
		Name = "Thief Bug", Level = 12, MaxHP = 3800, ATK = 155, DEF = 48, MDEF = 20,
		HIT = 75, FLEE = 35, PerfectDodge = 0, Element = "Shadow", Size = "Small",
		XP = 260, JobXP = 115, RespawnTime = 25, AggroRange = 18, AttackRange = 5,
		MoveSpeed = 9, AttackCooldown = 2.0, Color = Color3.fromRGB(68, 78, 96),
		Drops = {
			{ itemId = "IronOre",     chance = 30, quantity = 1 },
			{ itemId = "RedPotion",   chance = 25, quantity = 1 },
			{ itemId = "BeginnerRefinementStone", chance = 18, quantity = 1 },
		},
	},
	Sohee = {
		Name = "Sohee", Level = 15, MaxHP = 9500, ATK = 260, DEF = 80, MDEF = 90,
		HIT = 95, FLEE = 45, PerfectDodge = 2, Element = "Ghost", Size = "Medium",
		XP = 360, JobXP = 160, RespawnTime = 30, AggroRange = 18, AttackRange = 6,
		MoveSpeed = 9, AttackCooldown = 2.1, Color = Color3.fromRGB(142, 188, 245),
		StatusOnHit = "Curse", StatusChance = 18,
		Drops = {
			{ itemId = "BluePotion",  chance = 30, quantity = 1 },
			{ itemId = "WhitePotion", chance = 15, quantity = 1 },
			{ itemId = "ChainMail",   chance = 4,  quantity = 1 },
		},
	},
	Minorous = {
		Name = "★ Minorous (Mini-Boss)", Level = 18, MaxHP = 45000, ATK = 650, DEF = 160, MDEF = 75,
		HIT = 110, FLEE = 35, PerfectDodge = 2, Element = "Fire", Size = "Large", IsBoss = true, Scale = 1.65,
		XP = 950, JobXP = 420, RespawnTime = 45, AggroRange = 22, AttackRange = 7,
		MoveSpeed = 8, AttackCooldown = 2.2, Color = Color3.fromRGB(188, 68, 44),
		StatusOnHit = "Stun", StatusChance = 25,
		Drops = {
			{ itemId = "IronOre",           chance = 65, quantity = 2 },
			{ itemId = "MinorousBattleAxe", chance = 12, quantity = 1 },
			{ itemId = "MinorousCard",      chance = 6,  quantity = 1 },
			{ itemId = "BeginnerRefinementStone", chance = 45, quantity = 2 },
		},
	},
	Drake = {
		Name = "👑 Captain Drake (Dungeon Boss)", Level = 20, MaxHP = 250000, ATK = 1200, DEF = 240, MDEF = 140,
		HIT = 145, FLEE = 60, PerfectDodge = 5, Element = "Undead", Size = "Large", IsBoss = true, IsWorldBoss = true, Scale = 2.0,
		XP = 2400, JobXP = 1100, RespawnTime = 60, AggroRange = 24, AttackRange = 8,
		MoveSpeed = 9, AttackCooldown = 2.0, Color = Color3.fromRGB(122, 68, 198),
		StatusOnHit = "Curse", StatusChance = 30,
		Drops = {
			{ itemId = "PiratesDagger", chance = 18, quantity = 1 },
			{ itemId = "ChainMail",     chance = 15, quantity = 1 },
			{ itemId = "DrakeCard",     chance = 8,  quantity = 1 },
			{ itemId = "BeginnerRefinementStone", chance = 80, quantity = 3 },
		},
	},
	GoldenThiefBug = {
		Name = "🏆 Golden Thief Bug (Culvert MVP)", Level = 55, MaxHP = 480000, ATK = 1850, DEF = 280, MDEF = 999,
		HIT = 180, FLEE = 85, PerfectDodge = 8, Element = "Fire", Size = "Large", IsBoss = true, IsWorldBoss = true, Scale = 2.2,
		XP = 8500, JobXP = 4500, RespawnTime = 90, AggroRange = 26, AttackRange = 8,
		MoveSpeed = 10, AttackCooldown = 1.8, Color = Color3.fromRGB(245, 195, 45),
		StatusOnHit = "Stun", StatusChance = 35,
		Drops = {
			{ itemId = "GoldenThiefBugCard", chance = 15, quantity = 1 },
			{ itemId = "GoldRing",           chance = 35, quantity = 1 },
			{ itemId = "GrandClaymore",       chance = 12, quantity = 1 },
			{ itemId = "HalberdOfValor",      chance = 12, quantity = 1 },
			{ itemId = "BeginnerRefinementStone", chance = 100, quantity = 5 },
		},
	},

	-- ═══════════════════════════════════════════════════════════
	-- 3. MORROC DESERT REALM (Lv. 20–40 & World Boss Eddga)
	-- ═══════════════════════════════════════════════════════════
	Scorpion = {
		Name = "Desert Scorpion", Level = 20, MaxHP = 6800, ATK = 240, DEF = 70, MDEF = 25,
		HIT = 100, FLEE = 40, PerfectDodge = 0, Element = "Fire", Size = "Small",
		XP = 420, JobXP = 190, RespawnTime = 22, AggroRange = 18, AttackRange = 5,
		MoveSpeed = 9, AttackCooldown = 1.9, Color = Color3.fromRGB(215, 92, 48),
		StatusOnHit = "Poison", StatusChance = 30,
		Drops = {
			{ itemId = "ScorpionTail", chance = 45,  quantity = 1 },
			{ itemId = "FireScroll",   chance = 15,  quantity = 1 },
			{ itemId = "ScorpionCard", chance = 2.5, quantity = 1 },
		},
	},
	Mummy = {
		Name = "Ancient Mummy", Level = 25, MaxHP = 12500, ATK = 310, DEF = 90, MDEF = 30,
		HIT = 115, FLEE = 30, PerfectDodge = 0, Element = "Undead", Size = "Medium",
		XP = 620, JobXP = 280, RespawnTime = 26, AggroRange = 18, AttackRange = 5,
		MoveSpeed = 6, AttackCooldown = 2.3, Color = Color3.fromRGB(212, 192, 142),
		StatusOnHit = "Blind", StatusChance = 22,
		Drops = {
			{ itemId = "EmbalmingCloth", chance = 42,  quantity = 1 },
			{ itemId = "Panacea",        chance = 20,  quantity = 1 },
			{ itemId = "MummyCard",      chance = 2.5, quantity = 1 },
		},
	},
	SandMan = {
		Name = "Sand Golem", Level = 28, MaxHP = 16500, ATK = 380, DEF = 110, MDEF = 40,
		HIT = 125, FLEE = 50, PerfectDodge = 0, Element = "Earth", Size = "Medium",
		XP = 820, JobXP = 360, RespawnTime = 28, AggroRange = 18, AttackRange = 6,
		MoveSpeed = 8, AttackCooldown = 2.1, Color = Color3.fromRGB(196, 156, 88),
		Drops = {
			{ itemId = "EarthScroll", chance = 20, quantity = 1 },
			{ itemId = "IronOre",     chance = 35, quantity = 1 },
			{ itemId = "WhitePotion", chance = 25, quantity = 1 },
		},
	},
	Eddga = {
		Name = "👑 Eddga (Morroc World Boss)", Level = 40, MaxHP = 1800000, ATK = 2400, DEF = 320, MDEF = 180,
		HIT = 180, FLEE = 80, PerfectDodge = 6, Element = "Fire", Size = "Large", IsBoss = true, IsWorldBoss = true, Scale = 2.2,
		XP = 5500, JobXP = 2600, RespawnTime = 75, AggroRange = 26, AttackRange = 9,
		MoveSpeed = 9, AttackCooldown = 1.9, Color = Color3.fromRGB(238, 112, 32),
		StatusOnHit = "Stun", StatusChance = 30,
		Drops = {
			{ itemId = "FireCrystal", chance = 75, quantity = 2 },
			{ itemId = "EddgaCard",   chance = 10, quantity = 1 },
			{ itemId = "BeginnerRefinementStone", chance = 90, quantity = 4 },
		},
	},

	-- ═══════════════════════════════════════════════════════════
	-- 4. AMATSU WATER BLOSSOM ISLAND (Lv. 35–60 & World Boss Turtle General)
	-- ═══════════════════════════════════════════════════════════
	Swordfish = {
		Name = "Amatsu Swordfish", Level = 35, MaxHP = 22000, ATK = 450, DEF = 120, MDEF = 50,
		HIT = 145, FLEE = 55, PerfectDodge = 2, Element = "Water", Size = "Small",
		XP = 1150, JobXP = 520, RespawnTime = 25, AggroRange = 19, AttackRange = 6,
		MoveSpeed = 10, AttackCooldown = 1.8, Color = Color3.fromRGB(68, 162, 232),
		Drops = {
			{ itemId = "MermaidScale",  chance = 45,  quantity = 1 },
			{ itemId = "WaterScroll",   chance = 20,  quantity = 1 },
			{ itemId = "SwordfishCard", chance = 2.5, quantity = 1 },
		},
	},
	Merman = {
		Name = "Merman", Level = 38, MaxHP = 34000, ATK = 620, DEF = 150, MDEF = 70,
		HIT = 165, FLEE = 70, PerfectDodge = 2, Element = "Water", Size = "Medium",
		XP = 1400, JobXP = 620, RespawnTime = 25, AggroRange = 20, AttackRange = 6,
		MoveSpeed = 10, AttackCooldown = 1.8, Color = Color3.fromRGB(50, 120, 180),
		Drops = {
			{ itemId = "MermaidScale", chance = 50, quantity = 1 },
			{ itemId = "WaterScroll",  chance = 25, quantity = 1 },
			{ itemId = "WhitePotion",  chance = 30, quantity = 1 },
		},
	},
	Tengu = {
		Name = "Karasu Tengu", Level = 45, MaxHP = 65000, ATK = 950, DEF = 210, MDEF = 130,
		HIT = 210, FLEE = 115, PerfectDodge = 4, Element = "Wind", Size = "Medium",
		XP = 1800, JobXP = 820, RespawnTime = 28, AggroRange = 20, AttackRange = 6,
		MoveSpeed = 11, AttackCooldown = 1.7, Color = Color3.fromRGB(168, 52, 68),
		StatusOnHit = "Silence", StatusChance = 20,
		Drops = {
			{ itemId = "WindScroll",  chance = 22,  quantity = 1 },
			{ itemId = "WhitePotion", chance = 35,  quantity = 1 },
			{ itemId = "TenguCard",   chance = 2.5, quantity = 1 },
		},
	},
	TurtleGeneral = {
		Name = "👑 Turtle General (Amatsu World Boss)", Level = 60, MaxHP = 3500000, ATK = 3600, DEF = 420, MDEF = 260,
		HIT = 260, FLEE = 110, PerfectDodge = 8, Element = "Earth", Size = "Large", IsBoss = true, IsWorldBoss = true, Scale = 2.35,
		XP = 9500, JobXP = 4500, RespawnTime = 90, AggroRange = 26, AttackRange = 9,
		MoveSpeed = 8, AttackCooldown = 2.0, Color = Color3.fromRGB(58, 148, 92),
		StatusOnHit = "Frozen", StatusChance = 30,
		Drops = {
			{ itemId = "EarthCrystal",      chance = 85, quantity = 2 },
			{ itemId = "TurtleGeneralCard", chance = 12, quantity = 1 },
			{ itemId = "BeginnerRefinementStone", chance = 100, quantity = 5 },
		},
	},
}
