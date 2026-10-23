-- Complete Skill Tree definitions for all classes in RoROK.
-- Supports single-target attacks, AoE attacks, heals, buffs, elemental weapon coatings, and status ailments.
local SkillData = {
	-- ── Novice (สกิลผจญภัย / พื้นฐาน) ─────────────────────────
	NoviceStrike = {
		id = "NoviceStrike", name = "Novice Strike", nameThai = "ฟันพื้นฐาน", icon = "⚔", class = "Novice",
		treeRow = 1, treeCol = 1,
		maxLevel = 5, isAttack = true, range = 10, powerMult = 1.25, powerPerLevel = 0.10,
		scalingStat = "STR", spCost = 0, cooldown = 1.2,
		descThai = "โจมตีกายภาพระยะประชิด พลังโจมตีเพิ่มขึ้นตามเลเวลสกิล",
	},
	FirstAid = {
		id = "FirstAid", name = "First Aid", nameThai = "ปฐมพยาบาล", icon = "🩹", class = "Novice",
		treeRow = 1, treeCol = 2, prereq = "NoviceStrike",
		maxLevel = 5, isHeal = true, isMagic = false, flatHeal = 35, flatHealPerLevel = 15,
		spCost = 3, spCostPerLevel = 1, cooldown = 3.5,
		descThai = "ปฐมพยาบาลฟื้นฟู HP ตัวเองทันที 35 (+15 ต่อเลเวล)",
	},

	-- ── Acolyte (นักบวช — ตามผัง Ragnarok M) ───────────────────
	HolyLight = {
		id = "HolyLight", name = "Holy Light Strike", nameThai = "แสงศักดิ์สิทธิ์", icon = "✦", class = "Acolyte",
		treeRow = 1, treeCol = 1,
		maxLevel = 10, isAttack = true, isMagic = true, range = 26, powerMult = 1.55, powerPerLevel = 0.16,
		element = "Holy", spCost = 7, spCostPerLevel = 2, castTime = 0.8, cooldown = 1.8,
		descThai = "ยิงลำแสงธาตุศักดิ์สิทธิ์ รุนแรงเป็นพิเศษต่อมอนสเตอร์ธาตุ Undead และ Shadow",
	},
	Heal = {
		id = "Heal", name = "Heal", nameThai = "ฮีลศักดิ์สิทธิ์", icon = "💚", class = "Acolyte",
		treeRow = 2, treeCol = 1,
		maxLevel = 10, isHeal = true, isMagic = true, powerMult = 1.35, powerPerLevel = 0.22,
		scalingStat = "INT", spCost = 5, spCostPerLevel = 2, castTime = 0.5, cooldown = 2.0,
		descThai = "ฟื้นฟู HP จำนวนมากตามค่า INT และ MATK",
	},
	AquaBenedicta = {
		id = "AquaBenedicta", name = "Aqua Benedicta", nameThai = "เคลือบน้ำมนต์", icon = "💧", class = "Acolyte",
		treeRow = 2, treeCol = 2,
		maxLevel = 5, isBuff = true, coatElement = "Holy", buffDuration = 90,
		spCost = 10, spCostPerLevel = 1, castTime = 1.0, cooldown = 8,
		descThai = "เคลือบอาวุธด้วยธาตุศักดิ์สิทธิ์ (Holy) นาน 90 วินาที",
	},
	Blessing = {
		id = "Blessing", name = "Blessing", nameThai = "พรศักดิ์สิทธิ์", icon = "🙏", class = "Acolyte",
		treeRow = 3, treeCol = 1,
		maxLevel = 10, isBuff = true, buffStats = { STR = 5, INT = 5, DEX = 5 }, buffPerLevel = 2, buffDuration = 60,
		cureStatus = true, spCost = 10, spCostPerLevel = 2, cooldown = 6,
		descThai = "มอบพรเพิ่ม STR/INT/DEX นาน 60 วินาที และล้างสถานะผิดปกติ",
	},
	IncreaseAGI = {
		id = "IncreaseAGI", name = "Increase Agility", nameThai = "เร่งความเร็ว (AGI Up)", icon = "💨", class = "Acolyte",
		treeRow = 3, treeCol = 2, prereq = "Blessing",
		maxLevel = 10, isBuff = true, buffStats = { AGI = 6, FLEE = 10 }, buffPerLevel = 2, buffDuration = 60,
		spCost = 10, spCostPerLevel = 2, cooldown = 6,
		descThai = "เพิ่มค่า AGI และอัตราหลบหลีก FLEE อย่างมากนาน 60 วินาที",
	},
	Ruwach = {
		id = "Ruwach", name = "Ruwach", nameThai = "เนตรศักดิ์สิทธิ์", icon = "👁", class = "Acolyte",
		treeRow = 4, treeCol = 1,
		maxLevel = 5, isAttack = true, isMagic = true, range = 16, aoeRadius = 14, powerMult = 1.45, powerPerLevel = 0.15,
		element = "Holy", spCost = 8, spCostPerLevel = 1, cooldown = 3.0,
		descThai = "ปลดปล่อยคลื่นแสงศักดิ์สิทธิ์รอบตัว โจมตีศัตรูรอบข้างด้วยธาตุ Holy",
	},
	Angelus = {
		id = "Angelus", name = "Light Shield", nameThai = "เกราะเทวทูต (Angelus)", icon = "🛡", class = "Acolyte",
		treeRow = 4, treeCol = 2, prereq = "Ruwach",
		maxLevel = 5, isBuff = true, buffStats = { VIT = 6, DEF = 12, MDEF = 10 }, buffPerLevel = 3, buffDuration = 60,
		spCost = 12, spCostPerLevel = 2, cooldown = 8,
		descThai = "สร้างเกราะแห่งแสงเพิ่ม VIT, DEF และ MDEF นาน 60 วินาที",
	},

	-- ── Knight (อัศวิน) ────────────────────────────────────────
	Bash = {
		id = "Bash", name = "Bash", nameThai = "ฟาดดาบหนัก (Bash)", icon = "⚔", class = "Knight",
		treeRow = 1, treeCol = 1,
		maxLevel = 10, isAttack = true, range = 12, powerMult = 1.65, powerPerLevel = 0.16,
		scalingStat = "STR", statusEffect = "Stun", statusChance = 25, spCost = 4, spCostPerLevel = 1, cooldown = 1.5,
		descThai = "ฟาดดาบอย่างรุนแรง มีโอกาส 25% ทำให้ศัตรูติดสถานะมึนงง (Stun)",
	},
	MagnumBreak = {
		id = "MagnumBreak", name = "Magnum Break", nameThai = "ระเบิดเพลิงดาบ", icon = "🔥", class = "Knight",
		treeRow = 1, treeCol = 2, prereq = "Bash",
		maxLevel = 10, isAttack = true, range = 14, aoeRadius = 16, powerMult = 1.65, powerPerLevel = 0.16,
		scalingStat = "STR", element = "Fire", coatElement = "Fire", buffDuration = 20,
		spCost = 9, spCostPerLevel = 2, cooldown = 3.0,
		descThai = "ระเบิดคลื่นดาบเพลิงรอบตัว (AoE) ธาตุไฟ พร้อมเคลือบอาวุธธาตุไฟ 20 วินาที",
	},
	Provoke = {
		id = "Provoke", name = "Provoke", nameThai = "ยั่วยุ (Provoke)", icon = "💢", class = "Knight",
		treeRow = 2, treeCol = 1,
		maxLevel = 5, isBuff = true, buffStats = { ATK = 10, STR = 4 }, buffPerLevel = 4, buffDuration = 40,
		spCost = 6, spCostPerLevel = 1, cooldown = 5,
		descThai = "ปลุกใจนักรบ เพิ่มพลังโจมตี ATK และ STR อย่างมากนาน 40 วินาที",
	},
	Endure = {
		id = "Endure", name = "Endure", nameThai = "อดทนเหล็กไหล", icon = "🛡", class = "Knight",
		treeRow = 2, treeCol = 2, prereq = "Provoke",
		maxLevel = 5, isBuff = true, buffStats = { DEF = 12, MDEF = 8, VIT = 5 }, buffPerLevel = 4, buffDuration = 45,
		spCost = 8, spCostPerLevel = 1, cooldown = 8,
		descThai = "เสริมเกราะเหล็กไหล เพิ่ม DEF, MDEF และ VIT นาน 45 วินาที",
	},
	BowlingBash = {
		id = "BowlingBash", name = "Bowling Bash", nameThai = "เพลงดาบพายุหมุน", icon = "🌪", class = "Knight",
		treeRow = 3, treeCol = 1,
		maxLevel = 10, isAttack = true, range = 14, aoeRadius = 16, powerMult = 2.1, powerPerLevel = 0.22,
		scalingStat = "STR", spCost = 12, spCostPerLevel = 2, cooldown = 3.5,
		descThai = "ฟาดดาบกวาดศัตรูทั้งกลุ่มด้วยแรงปะทะมหาศาล (AoE กายภาพ)",
	},

	-- ── Mage (นักเวท) ──────────────────────────────────────────
	FireBolt = {
		id = "FireBolt", name = "Fire Bolt", nameThai = "ศรอัคคี (Fire Bolt)", icon = "🔥", class = "Mage",
		treeRow = 1, treeCol = 1,
		maxLevel = 10, isAttack = true, isMagic = true, range = 32, powerMult = 1.5, powerPerLevel = 0.18,
		scalingStat = "INT", element = "Fire", spCost = 5, spCostPerLevel = 2, castTime = 1.2, cooldown = 1.4,
		descThai = "ยิงศรเวทย์ไฟโจมตีเป้าหมาย ชนะทางธาตุ Earth และ Undead",
	},
	MeteorStorm = {
		id = "MeteorStorm", name = "Meteor Storm", nameThai = "ฝนดาวตก (Meteor Storm)", icon = "☄", class = "Mage",
		treeRow = 1, treeCol = 2, prereq = "FireBolt",
		maxLevel = 5, isAttack = true, isMagic = true, range = 32, aoeRadius = 20, powerMult = 2.2, powerPerLevel = 0.3,
		scalingStat = "INT", element = "Fire", statusEffect = "Stun", statusChance = 40,
		spCost = 16, spCostPerLevel = 3, castTime = 2.5, cooldown = 4.5,
		descThai = "เรียกฝนอุกกาบาตถล่มเป็นวงกว้าง (AoE) ธาตุไฟ พร้อมโอกาสทำให้มึนงง 40%",
	},
	ColdBolt = {
		id = "ColdBolt", name = "Cold Bolt", nameThai = "ศรน้ำแข็ง (Cold Bolt)", icon = "❄", class = "Mage",
		treeRow = 2, treeCol = 1,
		maxLevel = 10, isAttack = true, isMagic = true, range = 32, powerMult = 1.48, powerPerLevel = 0.17,
		scalingStat = "INT", element = "Water", statusEffect = "Frozen", statusChance = 35,
		spCost = 5, spCostPerLevel = 2, castTime = 1.2, cooldown = 1.5,
		descThai = "ยิงศรน้ำแข็งธาตุน้ำ มีโอกาส 35% แช่แข็งเป้าหมาย (Frozen)",
	},
	StormGust = {
		id = "StormGust", name = "Storm Gust", nameThai = "พายุหิมะ (Storm Gust)", icon = "🌨", class = "Mage",
		treeRow = 2, treeCol = 2, prereq = "ColdBolt",
		maxLevel = 5, isAttack = true, isMagic = true, range = 32, aoeRadius = 18, powerMult = 2.0, powerPerLevel = 0.25,
		scalingStat = "INT", element = "Water", statusEffect = "Frozen", statusChance = 65,
		spCost = 14, spCostPerLevel = 3, castTime = 2.5, cooldown = 4.0,
		descThai = "มหาเวทย์พายุน้ำแข็งวงกว้าง (AoE) ดาเมจสูงและมีโอกาส 65% แช่แข็งศัตรูเป็นกลุ่ม",
	},
	LightningBolt = {
		id = "LightningBolt", name = "Lightning Bolt", nameThai = "สายฟ้าฟาด", icon = "⚡", class = "Mage",
		treeRow = 3, treeCol = 1,
		maxLevel = 10, isAttack = true, isMagic = true, range = 32, powerMult = 1.55, powerPerLevel = 0.18,
		scalingStat = "INT", element = "Wind", spCost = 6, spCostPerLevel = 2, castTime = 1.4, cooldown = 1.5,
		descThai = "เรียกสายฟ้าธาตุลมฟาดเป้าหมาย ชนะทางมอนสเตอร์ธาตุน้ำ",
	},
	EnergyCoat = {
		id = "EnergyCoat", name = "Energy Coat", nameThai = "เกราะพลังงานเวท", icon = "🔮", class = "Mage",
		treeRow = 3, treeCol = 2, prereq = "LightningBolt",
		maxLevel = 5, isBuff = true, buffStats = { INT = 6, DEF = 12, MDEF = 12 }, buffPerLevel = 3, buffDuration = 60,
		spCost = 10, spCostPerLevel = 2, cooldown = 8,
		descThai = "สร้างม่านพลังเวทคุ้มกาย เพิ่ม INT, DEF และ MDEF นาน 60 วินาที",
	},

	-- ── Archer (นักธนู) ────────────────────────────────────────
	DoubleStrafe = {
		id = "DoubleStrafe", name = "Double Strafe", nameThai = "ยิงธนูคู่ (Double Strafe)", icon = "🏹", class = "Archer",
		treeRow = 1, treeCol = 1,
		maxLevel = 10, isAttack = true, range = 38, powerMult = 1.85, powerPerLevel = 0.18,
		scalingStat = "DEX", spCost = 5, spCostPerLevel = 1, cooldown = 1.4,
		descThai = "ยิงลูกธนู 2 ดอกซ้อนด้วยความเร็วสูง พลังโจมตีขึ้นกับค่า DEX",
	},
	ArrowShower = {
		id = "ArrowShower", name = "Arrow Shower", nameThai = "ฝนธนู (Arrow Shower)", icon = "🌧", class = "Archer",
		treeRow = 1, treeCol = 2, prereq = "DoubleStrafe",
		maxLevel = 10, isAttack = true, range = 34, aoeRadius = 16, powerMult = 1.55, powerPerLevel = 0.15,
		scalingStat = "DEX", spCost = 8, spCostPerLevel = 2, cooldown = 2.6,
		descThai = "ยิงห่าฝนธนูใส่กลุ่มศัตรูในรัศมี 16 เมตร (AoE)",
	},
	ImproveConcentration = {
		id = "ImproveConcentration", name = "Improve Concentration", nameThai = "รวมสมาธิ (Focus)", icon = "🎯", class = "Archer",
		treeRow = 2, treeCol = 1,
		maxLevel = 10, isBuff = true, buffStats = { DEX = 7, AGI = 6 }, buffPerLevel = 2, buffDuration = 60,
		spCost = 10, spCostPerLevel = 2, cooldown = 8,
		descThai = "รวบรวมสมาธิ เพิ่มค่า DEX และ AGI อย่างมากนาน 60 วินาที",
	},
	FocusedArrow = {
		id = "FocusedArrow", name = "Focused Arrow Strike", nameThai = "ศรทะลวงเกราะ", icon = "💥", class = "Archer",
		treeRow = 2, treeCol = 2, prereq = "ImproveConcentration",
		maxLevel = 5, isAttack = true, range = 40, powerMult = 2.4, powerPerLevel = 0.25,
		scalingStat = "DEX", spCost = 12, spCostPerLevel = 2, cooldown = 3.5,
		descThai = "ง้างธนูเต็มกำลังยิงศรทะลวงสร้างดาเมจสูงมากจากระยะไกล",
	},

	-- ── Thief (โจร) ────────────────────────────────────────────
	Envenom = {
		id = "Envenom", name = "Envenom", nameThai = "มีดอาบพิษ (Envenom)", icon = "☠", class = "Thief",
		treeRow = 1, treeCol = 1,
		maxLevel = 10, isAttack = true, range = 12, powerMult = 1.45, powerPerLevel = 0.15,
		scalingStat = "DEX", element = "Shadow", statusEffect = "Poison", statusChance = 55,
		spCost = 4, spCostPerLevel = 1, cooldown = 1.5,
		descThai = "จู่โจมด้วยอาวุธอาบพิษ มีโอกาส 55% ทำให้เป้าหมายติดพิษ (Poison)",
	},
	Detox = {
		id = "Detox", name = "Detox & Hide", nameThai = "ถอนพิษ & เร่งหลบหลีก", icon = "🌿", class = "Thief",
		treeRow = 1, treeCol = 2, prereq = "Envenom",
		maxLevel = 5, isHeal = true, isBuff = true, buffStats = { AGI = 6, FLEE = 12 }, buffPerLevel = 2, buffDuration = 45,
		flatHeal = 40, flatHealPerLevel = 18, cureStatus = true,
		spCost = 6, spCostPerLevel = 1, cooldown = 5,
		descThai = "ถอนพิษและฟื้นฟู HP พร้อมเพิ่ม AGI/FLEE ทันที",
	},
	Backstab = {
		id = "Backstab", name = "Backstab", nameThai = "ลอบสังหาร (Backstab)", icon = "🗡", class = "Thief",
		treeRow = 2, treeCol = 1,
		maxLevel = 10, isAttack = true, range = 14, powerMult = 2.35, powerPerLevel = 0.22,
		scalingStat = "STR", statusEffect = "Stun", statusChance = 35,
		spCost = 8, spCostPerLevel = 2, cooldown = 2.8,
		descThai = "พุ่งแทงจุดตายจากเงามืด สร้างดาเมจมหาศาลและมีโอกาสทำให้ศัตรูติด Stun",
	},
	SonicBlow = {
		id = "SonicBlow", name = "Sonic Blow", nameThai = "ระบำมีดความเร็วเสียง", icon = "⚡", class = "Thief",
		treeRow = 2, treeCol = 2, prereq = "Backstab",
		maxLevel = 10, isAttack = true, range = 14, aoeRadius = 12, powerMult = 2.5, powerPerLevel = 0.24,
		scalingStat = "AGI", statusEffect = "Stun", statusChance = 40,
		spCost = 12, spCostPerLevel = 2, cooldown = 3.5,
		descThai = "ฟันรัวด้วยความเร็วเหนือเสียง สร้างดาเมจสูงและมีโอกาส Stun 40%",
	},

	-- ── Merchant (พ่อค้า) ──────────────────────────────────────
	Mammonite = {
		id = "Mammonite", name = "Mammonite", nameThai = "ฟาดถุงทอง (Mammonite)", icon = "💰", class = "Merchant",
		treeRow = 1, treeCol = 1,
		maxLevel = 10, isAttack = true, range = 12, powerMult = 2.05, powerPerLevel = 0.20,
		scalingStat = "STR", spCost = 0, spCostPerLevel = 0, goldCost = 10, cooldown = 1.8,
		descThai = "ใช้เหรียญ Zeny 10z ฟาดศัตรูอย่างรุนแรงโดยไม่เสีย SP",
	},
	CartRevolution = {
		id = "CartRevolution", name = "Cart Revolution", nameThai = "รถเข็นพุ่งชน (AoE)", icon = "🛒", class = "Merchant",
		treeRow = 1, treeCol = 2, prereq = "Mammonite",
		maxLevel = 10, isAttack = true, range = 14, aoeRadius = 16, powerMult = 1.75, powerPerLevel = 0.18,
		scalingStat = "STR", spCost = 7, spCostPerLevel = 1, cooldown = 2.6,
		descThai = "เหวี่ยงรถเข็นพ่อค้ากระแทกศัตรูเป็นวงกว้าง (AoE)",
	},
	CrazyUproar = {
		id = "CrazyUproar", name = "Crazy Uproar", nameThai = "ตะโกนปลุกพลังพ่อค้า", icon = "📢", class = "Merchant",
		treeRow = 2, treeCol = 1,
		maxLevel = 5, isBuff = true, buffStats = { STR = 7, LUK = 6, ATK = 8 }, buffPerLevel = 3, buffDuration = 60,
		spCost = 8, spCostPerLevel = 1, cooldown = 8,
		descThai = "ตะโกนปลุกใจ เพิ่ม STR, LUK และ ATK นาน 60 วินาที",
	},
	HammerFall = {
		id = "HammerFall", name = "Hammer Fall", nameThai = "ค้อนทุบปฐพี (AoE Stun)", icon = "🔨", class = "Merchant",
		treeRow = 2, treeCol = 2, prereq = "CrazyUproar",
		maxLevel = 5, isAttack = true, range = 14, aoeRadius = 16, powerMult = 1.9, powerPerLevel = 0.2,
		scalingStat = "STR", statusEffect = "Stun", statusChance = 60,
		spCost = 10, spCostPerLevel = 2, cooldown = 4.0,
		descThai = "ทุบพื้นอย่างรุนแรง สร้างดาเมจวงกว้างและมีโอกาส 60% ทำให้ศัตรูติด Stun",
	},
	-- ═══════════════════════════════════════════════════════════
	-- 2ND JOB SKILLS (สกิลคลาสขั้นที่ 2)
	-- ═══════════════════════════════════════════════════════════

	-- ── Lord Knight (สุดยอดอัศวิน) ────────────────────────────
	SpiralPierce = {
		id = "SpiralPierce", name = "Spiral Pierce", nameThai = "แทงทะลวงเกราะ", icon = "🌀", class = "LordKnight",
		treeRow = 4, treeCol = 1, prereq = "Bash",
		maxLevel = 5, isAttack = true, range = 18, powerMult = 2.8, powerPerLevel = 0.35,
		scalingStat = "STR", spCost = 18, spCostPerLevel = 3, cooldown = 2.2,
		descThai = "แทงหอกทะลวงเกราะ 5 จังหวะรวดเร็ว ดาเมจรุนแรงทะลุผ่านค่า DEF ของเป้าหมาย",
	},
	AuraBlade = {
		id = "AuraBlade", name = "Aura Blade", nameThai = "ดาบออร่าศักดิ์สิทธิ์", icon = "✨", class = "LordKnight",
		treeRow = 4, treeCol = 2, prereq = "BowlingBash",
		maxLevel = 5, isBuff = true, buffDuration = 90, buffStats = { ATK = 45 },
		spCost = 25, spCostPerLevel = 4, cooldown = 30,
		descThai = "จุดประกายดาบออร่า เพิ่มพลังโจมตีบริสุทธิ์ไม่คิด DEF ทุกการโจมตีนาน 90 วินาที",
	},
	Concentration = {
		id = "Concentration", name = "Concentration", nameThai = "สมาธิสงคราม", icon = "⚔️", class = "LordKnight",
		treeRow = 5, treeCol = 1, prereq = "SpiralPierce",
		maxLevel = 5, isBuff = true, buffStats = { ATK = 35, HIT = 40 }, buffDuration = 60,
		spCost = 22, spCostPerLevel = 3, cooldown = 45,
		descThai = "รวมสมาธิการรบ เพิ่ม ATK และความแม่นยำ HIT มหาศาล พร้อมต้านทานการกระเด็น",
	},
	ClashingSpiral = {
		id = "ClashingSpiral", name = "Clashing Spiral", nameThai = "พายุหอกเกลียวคลื่น", icon = "🌪️", class = "LordKnight",
		treeRow = 5, treeCol = 2, prereq = "AuraBlade",
		maxLevel = 5, isAttack = true, isAoE = true, aoeRadius = 14, powerMult = 3.8, powerPerLevel = 0.45,
		scalingStat = "STR", spCost = 35, spCostPerLevel = 5, cooldown = 4.0,
		descThai = "หมุนควงหอกปล่อยพายุเกลียวคลื่นทำลายล้างรอบทิศทาง ดาเมจมหาศาลตามน้ำหนักอาวุธ",
	},

	-- ── Priest (นักบุญชั้นสูง) ────────────────────────────────
	MagnusExorcismus = {
		id = "MagnusExorcismus", name = "Magnus Exorcismus", nameThai = "มหาเวทขับไล่ปีศาจ (ME)", icon = "✝️", class = "Priest",
		treeRow = 4, treeCol = 1, prereq = "HolyLight",
		maxLevel = 5, isAttack = true, isAoE = true, aoeRadius = 18, isMagic = true, element = "Holy",
		powerMult = 3.5, powerPerLevel = 0.4, spCost = 40, spCostPerLevel = 6, castTime = 1.8, cooldown = 6.0,
		descThai = "เรียกมหาเวทแสงศักดิ์สิทธิ์ส่องสว่างล้างผลาญศัตรูธาตุ Undead และ Shadow อย่างรุนแรง",
	},
	Sanctuary = {
		id = "Sanctuary", name = "Sanctuary", nameThai = "พื้นที่ศักดิ์สิทธิ์", icon = "🏛️", class = "Priest",
		treeRow = 4, treeCol = 2, prereq = "Heal",
		maxLevel = 5, isHeal = true, isAoE = true, aoeRadius = 16, flatHeal = 150, flatHealPerLevel = 45,
		spCost = 30, spCostPerLevel = 5, castTime = 1.0, cooldown = 8.0,
		descThai = "สร้างเขตแดนศักดิ์สิทธิ์บนพื้น ฟื้นฟู HP ให้กับทุกคนในพื้นที่อย่างต่อเนื่อง",
	},
	LexAeterna = {
		id = "LexAeterna", name = "Lex Aeterna", nameThai = "คำสาปสัจธรรม (ดาเมจ x2)", icon = "👁️", class = "Priest",
		treeRow = 5, treeCol = 1, prereq = "MagnusExorcismus",
		maxLevel = 5, isDebuff = true, range = 24, spCost = 15, cooldown = 4.0,
		descThai = "ร่ายคำสาปแห่งสัจธรรมใส่ศัตรู ทำให้การโจมตีครั้งถัดไปที่ศัตรูได้รับแรงขึ้น 100%",
	},
	Resurrection = {
		id = "Resurrection", name = "Resurrection", nameThai = "ชุบชีวิตสมบูรณ์แบบ", icon = "👼", class = "Priest",
		treeRow = 5, treeCol = 2, prereq = "Sanctuary",
		maxLevel = 5, isBuff = true, spCost = 50, cooldown = 20.0,
		descThai = "อธิษฐานต่อเทพ ฟื้นคืนชีพเพื่อนร่วมปาร์ตี้หรือตนเองให้กลับมาด้วย HP และ SP เต็มเปี่ยม",
	},

	-- ── Wizard (จอมเวทมหาพายุ) ────────────────────────────────
	LordOfVermilion = {
		id = "LordOfVermilion", name = "Lord of Vermilion", nameThai = "มหาพายุสายฟ้า (LoV)", icon = "⚡", class = "Wizard",
		treeRow = 4, treeCol = 1, prereq = "LightningBolt",
		maxLevel = 5, isAttack = true, isAoE = true, aoeRadius = 20, isMagic = true, element = "Wind",
		powerMult = 3.6, powerPerLevel = 0.45, spCost = 45, spCostPerLevel = 7, castTime = 2.0, cooldown = 7.0,
		descThai = "อัญเชิญมหาพายุสายฟ้า 20 ระลอก ฟาดผ่าศัตรูทั้งสนามรบอย่างบ้าคลั่ง พร้อมโอกาสทำให้ตาบอด",
	},
	Quagmire = {
		id = "Quagmire", name = "Quagmire", nameThai = "หล่มโคลนดูด", icon = "🕳️", class = "Wizard",
		treeRow = 4, treeCol = 2, prereq = "MeteorStorm",
		maxLevel = 5, isDebuff = true, isAoE = true, aoeRadius = 15, spCost = 25, cooldown = 6.0,
		descThai = "เปลี่ยนผืนดินเป็นหล่มโคลน ลดความเร็วเดินและค่า AGI/DEX ของศัตรูลง 50%",
	},
	FrostDiver = {
		id = "FrostDiver", name = "Frost Diver", nameThai = "คลื่นน้ำแข็งแช่แข็ง", icon = "❄️", class = "Wizard",
		treeRow = 5, treeCol = 1, prereq = "ColdBolt",
		maxLevel = 5, isAttack = true, isMagic = true, element = "Water", powerMult = 2.4, powerPerLevel = 0.3,
		spCost = 20, spCostPerLevel = 3, cooldown = 3.0, range = 24,
		descThai = "ปล่อยคลื่นไอเย็นเยือกแข็งโจมตีศัตรู พร้อมแช่แข็งเป้าหมายให้ขยับไม่ได้ 5 วินาที",
	},
	JupitelThunder = {
		id = "JupitelThunder", name = "Jupitel Thunder", nameThai = "บอลสายฟ้ากระแทก (JT)", icon = "🌩️", class = "Wizard",
		treeRow = 5, treeCol = 2, prereq = "LordOfVermilion",
		maxLevel = 5, isAttack = true, isMagic = true, element = "Wind", powerMult = 3.2, powerPerLevel = 0.4,
		spCost = 28, spCostPerLevel = 4, castTime = 1.0, cooldown = 3.5, range = 26,
		descThai = "ยิงลูกบอลสายฟ้าอัดกระแทก 7 นัดติด ผลักศัตรูให้กระเด็นถอยหลังไปไกล",
	},

	-- ── Hunter (พรานล่าสัตว์) ──────────────────────────────────
	BlitzBeat = {
		id = "BlitzBeat", name = "Blitz Beat", nameThai = "เหยี่ยวจู่โจม", icon = "🦅", class = "Hunter",
		treeRow = 4, treeCol = 1, prereq = "DoubleStrafe",
		maxLevel = 5, isAttack = true, range = 38, powerMult = 2.6, powerPerLevel = 0.35, element = "Neutral",
		spCost = 16, spCostPerLevel = 3, cooldown = 2.0,
		descThai = "สั่งนกเหยี่ยวคู่ใจโฉบโจมตีทะลุผ่าน DEF และ FLEE ของศัตรูอย่างแม่นยำ",
	},
	FalconAssault = {
		id = "FalconAssault", name = "Falcon Assault", nameThai = "เหยี่ยวสังหารขั้นสูง", icon = "🏹", class = "Hunter",
		treeRow = 4, treeCol = 2, prereq = "FocusedArrow",
		maxLevel = 5, isAttack = true, range = 40, powerMult = 4.2, powerPerLevel = 0.5, element = "Neutral",
		spCost = 35, spCostPerLevel = 5, cooldown = 4.5,
		descThai = "รวมพลังเหยี่ยวพุ่งทะลวงสังหารเป้าหมายเดี่ยวดอกเดียวอย่างรุนแรงสูงสุด",
	},
	LandMine = {
		id = "LandMine", name = "Land Mine", nameThai = "กับดักระเบิดดิน", icon = "💣", class = "Hunter",
		treeRow = 5, treeCol = 1, prereq = "BlitzBeat",
		maxLevel = 5, isAttack = true, isAoE = true, aoeRadius = 12, powerMult = 3.0, powerPerLevel = 0.4,
		element = "Earth", spCost = 20, spCostPerLevel = 3, cooldown = 5.0,
		descThai = "วางกับดักดินใต้ฝ่าเท้า เมื่อศัตรูเหยียบจะระเบิดสร้างดาเมจธาตุดินและทำให้ติด Stun",
	},
	TrueSight = {
		id = "TrueSight", name = "True Sight", nameThai = "เนตรราชันย์แห่งพงไพร", icon = "👁️‍🗨️", class = "Hunter",
		treeRow = 5, treeCol = 2, prereq = "ImproveConcentration",
		maxLevel = 5, isBuff = true, buffStats = { STR = 5, AGI = 5, VIT = 5, INT = 5, DEX = 10, LUK = 10 },
		buffDuration = 90, spCost = 30, spCostPerLevel = 4, cooldown = 60,
		descThai = "เบิกเนตรราชันย์ เพิ่มสเตตัสทุกค่าและเพิ่มพลังโจมตีระยะไกลอย่างมหาศาลนาน 90 วินาที",
	},

	-- ── Assassin (นักฆ่าเงียบ) ─────────────────────────────────
	Grimtooth = {
		id = "Grimtooth", name = "Grimtooth", nameThai = "ฟันแทงจากใต้ดิน", icon = "🗡️", class = "Assassin",
		treeRow = 4, treeCol = 1, prereq = "Detox",
		maxLevel = 5, isAttack = true, isAoE = true, aoeRadius = 14, range = 24, powerMult = 2.8, powerPerLevel = 0.35,
		element = "Neutral", spCost = 18, spCostPerLevel = 3, cooldown = 2.5,
		descThai = "แทงใบมีดทะลุจากใต้ดินโจมตีศัตรูเป็นกลุ่มระยะไกลโดยที่ผู้ใช้ยังคงซ่อนตัวอยู่ในเงามืด",
	},
	EnchantDeadlyPoison = {
		id = "EnchantDeadlyPoison", name = "Enchant Deadly Poison", nameThai = "ยาพิษสังหาร (EDP)", icon = "🧪", class = "Assassin",
		treeRow = 4, treeCol = 2, prereq = "Envenom",
		maxLevel = 5, isBuff = true, buffDuration = 60, buffStats = { ATK = 70 },
		spCost = 35, spCostPerLevel = 5, cooldown = 60,
		descThai = "เคลือบอาวุธด้วยยาพิษสังหารขั้นสูง เพิ่มพลังโจมตีกายภาพขึ้นอย่างมหาศาลชั่วคราว",
	},
	SoulBreaker = {
		id = "SoulBreaker", name = "Soul Breaker", nameThai = "สะบั้นวิญญาณ", icon = "👻", class = "Assassin",
		treeRow = 5, treeCol = 1, prereq = "Backstab",
		maxLevel = 5, isAttack = true, range = 20, powerMult = 3.6, powerPerLevel = 0.45, element = "Neutral",
		spCost = 30, spCostPerLevel = 4, cooldown = 3.5,
		descThai = "ฟาดฟันคลื่นสะบั้นวิญญาณ โจมตีด้วยดาเมจกายภาพผสมดาเมจเวทมนตร์ทะลุเกราะ",
	},
	MeteorAssault = {
		id = "MeteorAssault", name = "Meteor Assault", nameThai = "ระบำมีดหมุนวนสังหาร", icon = "⚔️", class = "Assassin",
		treeRow = 5, treeCol = 2, prereq = "SonicBlow",
		maxLevel = 5, isAttack = true, isAoE = true, aoeRadius = 14, powerMult = 3.4, powerPerLevel = 0.4,
		element = "Neutral", spCost = 32, spCostPerLevel = 4, cooldown = 3.0,
		descThai = "หมุนตัวฟาดฟันใบมีด 360 องศารอบตัว สร้างดาเมจหมู่และมีโอกาสทำให้ศัตรูติด Stun และตาบอด",
	},

	-- ── Blacksmith (ปรมาจารย์ช่างเหล็ก) ────────────────────────
	AdrenalineRush = {
		id = "AdrenalineRush", name = "Adrenaline Rush", nameThai = "เร่งความเร็วอาวุธ", icon = "🔥", class = "Blacksmith",
		treeRow = 4, treeCol = 1, prereq = "CrazyUproar",
		maxLevel = 5, isBuff = true, buffStats = { ASPD = 35 }, buffDuration = 90,
		spCost = 25, spCostPerLevel = 3, cooldown = 45,
		descThai = "กระตุ้นอะดรีนาลีน เพิ่มความเร็วในการโจมตี ASPD +35% ให้กับตนเองและสมาชิกในปาร์ตี้",
	},
	CartTermination = {
		id = "CartTermination", name = "Cart Termination", nameThai = "รถเข็นสังหารมหาประลัย", icon = "🛒", class = "Blacksmith",
		treeRow = 4, treeCol = 2, prereq = "CartRevolution",
		maxLevel = 5, isAttack = true, range = 10, powerMult = 4.5, powerPerLevel = 0.55, element = "Neutral",
		spCost = 30, spCostPerLevel = 4, cooldown = 2.8,
		descThai = "เหวี่ยงรถเข็นอัดกระแทกเป้าหมายอย่างบ้าคลั่ง ดาเมจกายภาพรุนแรงสูงสุดตามน้ำหนักของในรถเข็น",
	},
	WeaponPerfection = {
		id = "WeaponPerfection", name = "Weapon Perfection", nameThai = "อาวุธไร้ที่ติ", icon = "🛡️", class = "Blacksmith",
		treeRow = 5, treeCol = 1, prereq = "HammerFall",
		maxLevel = 5, isBuff = true, buffDuration = 90, buffStats = { ATK = 30 },
		spCost = 20, spCostPerLevel = 3, cooldown = 45,
		descThai = "ขัดเกลาอาวุธให้ไร้จุดบกพร่อง ลบข้อจำกัดขนาดตัวมอนสเตอร์ (โจมตี Small/Medium/Large เต็ม 100%)",
	},
	Overthrust = {
		id = "Overthrust", name = "Overthrust", nameThai = "เพิ่มพลังโจมตีสุดขีด", icon = "💥", class = "Blacksmith",
		treeRow = 5, treeCol = 2, prereq = "Mammonite",
		maxLevel = 5, isBuff = true, buffStats = { ATK = 40 }, buffDuration = 90,
		spCost = 30, spCostPerLevel = 4, cooldown = 60,
		descThai = "เค้นพลังอาวุธขั้นสูงสุด เพิ่มค่า ATK ให้ทั้งทีม 40 หน่วย ชั่วคราว",
	},
}

function SkillData.GetSkill(skillId)
	return type(skillId) == "string" and SkillData[skillId] or nil
end

function SkillData.GetSkillsByClass(className)
	local list = {}
	local ClassData = _G.ClassData or (game:GetService("ReplicatedStorage"):FindFirstChild("GameData") and require(game:GetService("ReplicatedStorage").GameData:FindFirstChild("ClassData")))
	local parentClass = ClassData and ClassData.ParentClass and ClassData.ParentClass[className]
	for k, v in pairs(SkillData) do
		if type(v) == "table" and (v.class == className or (parentClass and v.class == parentClass)) then
			v.id = v.id or k
			table.insert(list, v)
		end
	end
	table.sort(list, function(a, b)
		local ra, rb = a.treeRow or 99, b.treeRow or 99
		if ra ~= rb then return ra < rb end
		return (a.treeCol or 99) < (b.treeCol or 99)
	end)
	return list
end

return SkillData
