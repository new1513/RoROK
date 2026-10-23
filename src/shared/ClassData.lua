-- ===========================================================================
-- ClassData.lua
-- ModuleScript: ReplicatedStorage/GameData/ClassData
-- ข้อมูลคลาสตัวละครทั้งหมดในเกม RoROK
-- Contains all character class definitions, base stats, and derived stat calculations
-- ===========================================================================

local ClassData = {}

-- ---------------------------------------------------------------------------
-- Class ID Constants (ค่า ID ของแต่ละคลาส)
-- ---------------------------------------------------------------------------
ClassData.ClassID = {
	Novice      = "Novice",       -- มือใหม่
	Acolyte     = "Acolyte",      -- นักบวช
	Knight      = "Knight",       -- อัศวิน
	Mage        = "Mage",         -- นักเวทย์
	Archer      = "Archer",       -- นักธนู
	Thief       = "Thief",        -- โจร
	Merchant    = "Merchant",     -- พ่อค้า
	-- 2nd Job Classes (คลาสขั้นที่ 2)
	LordKnight  = "LordKnight",   -- ลอร์ดไนท์ (สุดยอดอัศวิน)
	Priest      = "Priest",       -- พรีสต์ (นักบุญชั้นสูง)
	Wizard      = "Wizard",       -- วิซาร์ด (จอมเวทมหาพายุ)
	Hunter      = "Hunter",       -- ฮันเตอร์ (พรานล่าสัตว์)
	Assassin    = "Assassin",     -- แอสซาซิน (นักฆ่าเงียบ)
	Blacksmith  = "Blacksmith",   -- แบล็กสมิธ (ปรมาจารย์ช่างเหล็ก)
}

ClassData.ParentClass = {
	LordKnight = "Knight",
	Priest     = "Acolyte",
	Wizard     = "Mage",
	Hunter     = "Archer",
	Assassin   = "Thief",
	Blacksmith = "Merchant",
}

-- ---------------------------------------------------------------------------
-- Weapon type constants (ประเภทอาวุธ)
-- ---------------------------------------------------------------------------
ClassData.WeaponType = {
	Dagger       = "Dagger",
	Rod          = "Rod",
	Mace         = "Mace",
	Staff        = "Staff",
	Sword        = "Sword",
	Spear        = "Spear",
	TwoHandSword = "TwoHandSword",
	TwoHandSpear = "TwoHandSpear",
	Axe          = "Axe",
	TwoHandAxe   = "TwoHandAxe",
	Bow          = "Bow",
	Katar        = "Katar",
}

-- ---------------------------------------------------------------------------
-- Class Definitions Table (ตารางข้อมูลคลาสทั้งหมด)
-- Each class contains:
--   BaseStats      : ค่าสถิติพื้นฐาน
--   StartStats     : ค่าสถิติเริ่มต้น
--   StartStatPoints: จุดสถิติเริ่มต้นที่ยังไม่ได้ใช้
--   UsableWeapons  : อาวุธที่ใช้ได้
--   JobChangeReq   : ระดับงาน (JobLevel) ที่ต้องการเพื่อเปลี่ยนคลาส
--   Description    : คำอธิบาย (ภาษาไทย)
--   DescriptionEN  : คำอธิบาย (ภาษาอังกฤษ)
-- ---------------------------------------------------------------------------
-- Basic attacks are melee for every class except Archer's bow.
ClassData.BasicAttackRanges = {
	Novice = 10, Acolyte = 10, Knight = 10, Mage = 10, Archer = 38, Thief = 10, Merchant = 10,
	LordKnight = 12, Priest = 10, Wizard = 12, Hunter = 42, Assassin = 10, Blacksmith = 10,
}

function ClassData.GetBasicAttackRange(classID)
	return ClassData.BasicAttackRanges[classID] or ClassData.BasicAttackRanges.Novice
end

function ClassData.GetBaseASPD(classID)
	local classInfo = ClassData.Classes[classID] or ClassData.Classes.Novice
	return classInfo.BaseStats.BaseASPD
end

ClassData.Classes = {

	-- ======================================================================
	-- NOVICE (มือใหม่)
	-- ======================================================================
	Novice = {
		ID            = "Novice",
		Name          = "Novice",
		NameThai      = "มือใหม่",
		Description   = "คลาสเริ่มต้น เหมาะสำหรับนักผจญภัยหน้าใหม่ที่เพิ่งเดินทางมาถึงโปรนเทรา",
		DescriptionEN = "The starting class for all adventurers. Versatile but weak, destined for greatness.",

		-- สถิติพื้นฐานของคลาส (Base Stats) — Ragnarok M 1:1 Scale
		BaseStats = {
			BaseHP   = 350,  -- HP พื้นฐาน
			BaseSP   = 80,   -- SP พื้นฐาน
			BaseATK  = 25,   -- ATK พื้นฐาน
			BaseMATK = 15,   -- MATK พื้นฐาน
			BaseDEF  = 10,   -- DEF พื้นฐาน
			BaseMDEF = 5,    -- MDEF พื้นฐาน
			BaseASPD = 100,  -- ความเร็วโจมตีพื้นฐาน (ครั้ง/นาที)
			BaseMove = 10,   -- ความเร็วเดิน (WalkSpeed)
		},

		-- ค่าสถิติเริ่มต้น (Starting stat values)
		StartStats = {
			STR = 1,
			AGI = 1,
			VIT = 1,
			INT = 1,
			DEX = 1,
			LUK = 1,
		},

		-- จุดสถิติเริ่มต้นที่ยังไม่ได้ใช้ (Free stat points to distribute)
		StartStatPoints = 48,

		-- อาวุธที่สามารถใช้ได้ (Usable weapon types)
		UsableWeapons = { "Dagger", "Rod" },

		-- ต้องการ JobLevel เท่าไหร่เพื่อเปลี่ยนคลาส (JobLevel required to change class)
		JobChangeReq = 10,

		-- คลาสที่สามารถเปลี่ยนได้ (Available advancement options)
		AdvanceOptions = { "Acolyte", "Knight", "Mage", "Archer", "Thief", "Merchant" },
	},

	-- ======================================================================
	-- ACOLYTE (นักบวช)
	-- ======================================================================
	Acolyte = {
		ID            = "Acolyte",
		Name          = "Acolyte",
		NameThai      = "นักบวช",
		Description   = "ผู้ปกป้องและรักษาเพื่อนร่วมทีม เชี่ยวชาญด้านการฮีลและบัฟ มีความสำคัญสูงในปาร์ตี้",
		DescriptionEN = "Support class specializing in healing and buffs. Essential for any party.",

		BaseStats = {
			BaseHP   = 550,
			BaseSP   = 250,
			BaseATK  = 35,
			BaseMATK = 65,
			BaseDEF  = 25,
			BaseMDEF = 35,
			BaseASPD = 100,
			BaseMove = 10,
		},

		StartStats = {
			STR = 1,
			AGI = 1,
			VIT = 1,
			INT = 6,
			DEX = 3,
			LUK = 3,
		},

		StartStatPoints = 0,

		UsableWeapons = { "Mace", "Rod", "Staff" },

		JobChangeReq   = 40,
		AdvanceOptions = { "Priest" },
	},

	-- ======================================================================
	-- KNIGHT (อัศวิน)
	-- ======================================================================
	Knight = {
		ID            = "Knight",
		Name          = "Knight",
		NameThai      = "อัศวิน",
		Description   = "นักรบสายหน้า มีพลังโจมตีสูงและทนทาน เป็นผู้นำในการต่อสู้ระยะประชิด",
		DescriptionEN = "Frontline warrior with high attack and defense. Tank and damage dealer.",

		BaseStats = {
			BaseHP   = 1200,
			BaseSP   = 120,
			BaseATK  = 75,
			BaseMATK = 15,
			BaseDEF  = 50,
			BaseMDEF = 20,
			BaseASPD = 115,
			BaseMove = 11,
		},

		StartStats = {
			STR = 8,
			AGI = 4,
			VIT = 6,
			INT = 1,
			DEX = 4,
			LUK = 2,
		},

		StartStatPoints = 0,

		UsableWeapons = { "Sword", "Spear", "Mace", "Axe", "TwoHandSword", "TwoHandSpear" },

		JobChangeReq   = 40,
		AdvanceOptions = { "LordKnight" },
	},

	-- ======================================================================
	-- MAGE (นักเวทย์)
	-- ======================================================================
	Mage = {
		ID            = "Mage",
		Name          = "Mage",
		NameThai      = "นักเวทย์",
		Description   = "ผู้เชี่ยวชาญเวทมนตร์ ดาเมจสูงมากแต่บอบบาง ต้องได้รับการปกป้องจากเพื่อนร่วมทีม",
		DescriptionEN = "Magic damage dealer with high MATK but low defense. Handle with care.",

		BaseStats = {
			BaseHP   = 450,
			BaseSP   = 320,
			BaseATK  = 20,
			BaseMATK = 95,
			BaseDEF  = 15,
			BaseMDEF = 45,
			BaseASPD = 90,
			BaseMove = 10,
		},

		StartStats = {
			STR = 1,
			AGI = 2,
			VIT = 1,
			INT = 9,
			DEX = 6,
			LUK = 1,
		},

		StartStatPoints = 0,

		UsableWeapons = { "Staff", "Rod", "Dagger" },

		JobChangeReq   = 40,
		AdvanceOptions = { "Wizard" },
	},

	-- ======================================================================
	-- ARCHER (นักธนู)
	-- ======================================================================
	Archer = {
		ID            = "Archer",
		Name          = "Archer",
		NameThai      = "นักธนู",
		Description   = "นักสู้ระยะไกล โจมตีได้จากระยะปลอดภัย มีความแม่นยำสูงและโจมตีได้เร็ว",
		DescriptionEN = "Ranged attacker with high DEX and long attack range. Safe and swift.",

		BaseStats = {
			BaseHP   = 650,
			BaseSP   = 150,
			BaseATK  = 65,
			BaseMATK = 20,
			BaseDEF  = 25,
			BaseMDEF = 20,
			BaseASPD = 110,
			BaseMove = 11,
		},

		StartStats = {
			STR = 2,
			AGI = 6,
			VIT = 2,
			INT = 2,
			DEX = 9,
			LUK = 4,
		},

		StartStatPoints = 0,

		UsableWeapons = { "Bow", "Dagger" },

		JobChangeReq   = 40,
		AdvanceOptions = { "Hunter" },
	},

	-- ======================================================================
	-- THIEF (โจร)
	-- ======================================================================
	Thief = {
		ID            = "Thief",
		Name          = "Thief",
		NameThai      = "โจร",
		Description   = "นักลอบเร้นผู้คล่องแคล่ว โจมตีจากเงามืดและหลบหลีกได้ดีเยี่ยม เหมาะสำหรับการเล่นเดี่ยว",
		DescriptionEN = "Agile assassin with stealth abilities and high flee rate. Solo king.",

		BaseStats = {
			BaseHP   = 750,
			BaseSP   = 140,
			BaseATK  = 70,
			BaseMATK = 20,
			BaseDEF  = 25,
			BaseMDEF = 15,
			BaseASPD = 120,
			BaseMove = 12,
		},

		StartStats = {
			STR = 5,
			AGI = 9,
			VIT = 2,
			INT = 1,
			DEX = 5,
			LUK = 3,
		},

		StartStatPoints = 0,

		UsableWeapons = { "Dagger", "Sword", "Katar" },

		JobChangeReq   = 40,
		AdvanceOptions = { "Assassin" },
	},

	-- ======================================================================
	-- MERCHANT (พ่อค้า)
	-- ======================================================================
	Merchant = {
		ID            = "Merchant",
		Name          = "Merchant",
		NameThai      = "พ่อค้า",
		Description   = "นักธุรกิจผู้ทรงพลัง สามารถขายสินค้าให้ผู้เล่นอื่นได้ มีพลังโจมตีสูงและแบกของได้มาก",
		DescriptionEN = "Business-savvy brawler who can open player shops and carry enormous weight.",

		BaseStats = {
			BaseHP   = 950,
			BaseSP   = 160,
			BaseATK  = 68,
			BaseMATK = 20,
			BaseDEF  = 35,
			BaseMDEF = 20,
			BaseASPD = 105,
			BaseMove = 10,
		},

		StartStats = {
			STR = 8,
			AGI = 3,
			VIT = 4,
			INT = 2,
			DEX = 5,
			LUK = 3,
		},

		StartStatPoints = 0,

		UsableWeapons = { "Axe", "Mace", "Dagger", "TwoHandAxe" },

		JobChangeReq   = 40,
		AdvanceOptions = { "Blacksmith" },
	},

	-- ======================================================================
	-- 2ND JOBS (คลาสขั้นที่ 2)
	-- ======================================================================

	LordKnight = {
		ID            = "LordKnight",
		Name          = "LordKnight",
		NameThai      = "ลอร์ดไนท์ (Lord Knight)",
		Description   = "อัศวินขั้นสูงสุด เชี่ยวชาญการต่อสู้ด้วยดาบสองมือและหอก มีพลังป้องกันและพลังโจมตีรุนแรงทะลุเกราะ",
		DescriptionEN = "Supreme knight master of both spear and two-handed sword with defense-piercing strikes.",
		BaseStats = {
			BaseHP   = 2200,
			BaseSP   = 350,
			BaseATK  = 110,
			BaseMATK = 25,
			BaseDEF  = 48,
			BaseMDEF = 20,
			BaseASPD = 135,
			BaseMove = 16,
		},
		StartStats = { STR = 9, AGI = 5, VIT = 9, INT = 2, DEX = 6, LUK = 2 },
		StartStatPoints = 0,
		UsableWeapons = { "Sword", "TwoHandSword", "Spear", "TwoHandSpear", "Axe", "Mace" },
		JobChangeReq = 50,
		AdvanceOptions = {},
	},

	Priest = {
		ID            = "Priest",
		Name          = "Priest",
		NameThai      = "พรีสต์ (Priest)",
		Description   = "นักบวชชั้นสูง ผู้สืบทอดแสงแห่งสวรรค์ ชำนาญมหาเวทศักดิ์สิทธิ์ขับไล่ปีศาจ ชุบชีวิต และรักษาขั้นสูงสุด",
		DescriptionEN = "High holy servant who casts sacred exorcism, immense group healing, and resurrection.",
		BaseStats = {
			BaseHP   = 1450,
			BaseSP   = 780,
			BaseATK  = 55,
			BaseMATK = 135,
			BaseDEF  = 32,
			BaseMDEF = 55,
			BaseASPD = 120,
			BaseMove = 16,
		},
		StartStats = { STR = 2, AGI = 3, VIT = 5, INT = 9, DEX = 6, LUK = 5 },
		StartStatPoints = 0,
		UsableWeapons = { "Mace", "Rod", "Staff" },
		JobChangeReq = 50,
		AdvanceOptions = {},
	},

	Wizard = {
		ID            = "Wizard",
		Name          = "Wizard",
		NameThai      = "วิซาร์ด (Wizard)",
		Description   = "จอมเวทผู้ควบคุมธาตุทั้งสี่ มีมหาเวททำลายล้างวงกว้างรุนแรงสูงสุด ทั้งพายุสายฟ้า พายุหิมะ และหล่มโคลน",
		DescriptionEN = "Master of elemental sorcery commanding devastating AoE thunderstorms, blizzards, and meteors.",
		BaseStats = {
			BaseHP   = 1250,
			BaseSP   = 920,
			BaseATK  = 45,
			BaseMATK = 175,
			BaseDEF  = 24,
			BaseMDEF = 50,
			BaseASPD = 115,
			BaseMove = 16,
		},
		StartStats = { STR = 1, AGI = 2, VIT = 4, INT = 10, DEX = 8, LUK = 2 },
		StartStatPoints = 0,
		UsableWeapons = { "Staff", "Rod", "Dagger" },
		JobChangeReq = 50,
		AdvanceOptions = {},
	},

	Hunter = {
		ID            = "Hunter",
		Name          = "Hunter",
		NameThai      = "ฮันเตอร์ (Hunter)",
		Description   = "นายพรานจอมแม่นยำ โจมตีระยะไกลด้วยความเร็วสูง มีนกเหยี่ยวคู่ใจช่วยโจมตีทะลุเกราะและวางกับดักสังหาร",
		DescriptionEN = "Deadly marksman commanding a falcon companion and placing explosive tactical ground traps.",
		BaseStats = {
			BaseHP   = 1400,
			BaseSP   = 420,
			BaseATK  = 105,
			BaseMATK = 45,
			BaseDEF  = 28,
			BaseMDEF = 22,
			BaseASPD = 150,
			BaseMove = 16,
		},
		StartStats = { STR = 3, AGI = 9, VIT = 4, INT = 2, DEX = 10, LUK = 5 },
		StartStatPoints = 0,
		UsableWeapons = { "Bow", "Dagger" },
		JobChangeReq = 50,
		AdvanceOptions = {},
	},

	Assassin = {
		ID            = "Assassin",
		Name          = "Assassin",
		NameThai      = "แอสซาซิน (Assassin)",
		Description   = "นักฆ่าในเงามืด ผู้เชี่ยวชาญอาวุธกาตาร์และมีดสั้น เคลือบพิษสังหารขั้นรุนแรง มีอัตราคริติคอลและความเร็วสูงสุด",
		DescriptionEN = "Silent stalker wielding katars and twin blades with deadly poison coatings and lethal criticals.",
		BaseStats = {
			BaseHP   = 1550,
			BaseSP   = 360,
			BaseATK  = 112,
			BaseMATK = 35,
			BaseDEF  = 28,
			BaseMDEF = 22,
			BaseASPD = 160,
			BaseMove = 16,
		},
		StartStats = { STR = 8, AGI = 10, VIT = 4, INT = 2, DEX = 6, LUK = 5 },
		StartStatPoints = 0,
		UsableWeapons = { "Katar", "Dagger", "Sword" },
		JobChangeReq = 50,
		AdvanceOptions = {},
	},

	Blacksmith = {
		ID            = "Blacksmith",
		Name          = "Blacksmith",
		NameThai      = "แบล็กสมิธ (Blacksmith)",
		Description   = "ปรมาจารย์แห่งการตีเหล็กและเสริมพลังอาวุธ โจมตีด้วยขวานยักษ์และรถเข็นทำลายล้าง มอบบัพเพิ่มพลังโจมตีให้ทั้งทีม",
		DescriptionEN = "Master craftsman who wields heavy axes, rams carts with lethal force, and buffs party weapon damage.",
		BaseStats = {
			BaseHP   = 1850,
			BaseSP   = 380,
			BaseATK  = 115,
			BaseMATK = 30,
			BaseDEF  = 40,
			BaseMDEF = 22,
			BaseASPD = 140,
			BaseMove = 16,
		},
		StartStats = { STR = 9, AGI = 7, VIT = 7, INT = 2, DEX = 6, LUK = 4 },
		StartStatPoints = 0,
		UsableWeapons = { "Axe", "TwoHandAxe", "Mace", "Dagger" },
		JobChangeReq = 50,
		AdvanceOptions = {},
	},
}

-- ---------------------------------------------------------------------------
-- GetStatCost(currentStatValue)
-- สูตรต้นทุน Stat Point: cost = floor(currentStatValue / 10) + 2
-- ยิ่งค่าสถิติสูง ยิ่งใช้แต้มมาก (Higher stat = more points per upgrade)
-- ---------------------------------------------------------------------------
function ClassData.GetStatCost(currentStatValue)
	return math.floor(currentStatValue / 10) + 2
end

-- ---------------------------------------------------------------------------
-- CalculateDerivedStats(classID, level, STR, AGI, VIT, INT, DEX, LUK, equipStats)
-- คำนวณสถิติทั้งหมดจากสูตร RO-style
-- Calculates all derived stats from class base + character stats + equipment
--
-- Parameters:
--   classID    : string  - ID คลาส เช่น "Knight"
--   level      : number  - ระดับตัวละคร (1-99)
--   STR        : number  - ค่า Strength
--   AGI        : number  - ค่า Agility
--   VIT        : number  - ค่า Vitality
--   INT        : number  - ค่า Intelligence
--   DEX        : number  - ค่า Dexterity
--   LUK        : number  - ค่า Luck
--   equipStats : table   - สถิติจากอุปกรณ์ { HP, SP, ATK, MATK, DEF, MDEF }
--
-- Returns: table with MaxHP, MaxSP, ATK, MATK_min, MATK_max, DEF, MDEF,
--          HIT, FLEE, ASPD, CritRate, PerfectDodge, MaxWeight, HPRegen, SPRegen
-- ---------------------------------------------------------------------------
function ClassData.CalculateDerivedStats(classID, level, STR, AGI, VIT, INT, DEX, LUK, equipStats)
	-- ตรวจสอบว่าคลาสมีอยู่จริง (Validate class exists)
	local classInfo = ClassData.Classes[classID]
	if not classInfo then
		warn("[ClassData] CalculateDerivedStats: Unknown classID = " .. tostring(classID))
		return nil
	end

	local base = classInfo.BaseStats

	-- ตั้งค่า equipStats ป้องกัน nil (Default equip stats to 0 without mutating input table)
	local eqHP       = (equipStats and (equipStats.MaxHP or equipStats.HP)) or 0
	local eqSP       = (equipStats and (equipStats.MaxSP or equipStats.SP)) or 0
	local eqATK      = (equipStats and equipStats.ATK) or 0
	local eqMATK     = (equipStats and equipStats.MATK) or 0
	local eqDEF      = (equipStats and equipStats.DEF) or 0
	local eqMDEF     = (equipStats and equipStats.MDEF) or 0
	local eqHIT      = (equipStats and equipStats.HIT) or 0
	local eqFLEE     = (equipStats and equipStats.FLEE) or 0
	local eqCritRate = (equipStats and (equipStats.CritRate or equipStats.Crit)) or 0
	local eqASPD     = (equipStats and equipStats.ASPD) or 0

	-- ตรวจสอบค่าสถิติขั้นต่ำ (Clamp stats to minimum 1)
	STR   = math.max(1, STR   or 1)
	AGI   = math.max(1, AGI   or 1)
	VIT   = math.max(1, VIT   or 1)
	INT   = math.max(1, INT   or 1)
	DEX   = math.max(1, DEX   or 1)
	LUK   = math.max(1, LUK   or 1)
	level = math.max(1, level  or 1)

	-- ------------------------------------------------------------------
	-- MaxHP & MaxSP: Ragnarok M 1:1 Scale
	-- ------------------------------------------------------------------
	local MaxHP = base.BaseHP + (VIT * 35) + (level * 30) + eqHP
	local MaxSP = base.BaseSP + (INT * 15) + (level * 10) + eqSP

	-- ------------------------------------------------------------------
	-- ATK: Status ATK + Equip ATK (Archer & Hunter scale with DEX, others STR)
	-- ------------------------------------------------------------------
	local isBowClass = (classID == "Archer" or classID == "Hunter")
	local mainPhysicalStat = isBowClass and DEX or STR
	local secondaryStat = isBowClass and math.floor(STR / 5) or math.floor(DEX / 5)
	local statusATK = base.BaseATK + (mainPhysicalStat * 2) + math.floor((mainPhysicalStat ^ 2) / 100)
		+ secondaryStat + (level * 2)
	local ATK = statusATK + eqATK

	-- ------------------------------------------------------------------
	-- MATK: Status MATK + Equip MATK
	-- ------------------------------------------------------------------
	local statusMATK = base.BaseMATK + (INT * 2) + math.floor((INT ^ 2) / 100)
		+ math.floor(DEX / 5) + (level * 2)
	local matkVar  = math.floor(INT / 4)
	local MATK_min = statusMATK - matkVar + eqMATK
	local MATK_max = statusMATK + matkVar + eqMATK

	-- ------------------------------------------------------------------
	-- DEF & MDEF: Ragnarok M 1:1 Hard DEF scaling
	-- ------------------------------------------------------------------
	local DEF = base.BaseDEF + math.floor(VIT * 1.5) + math.floor(level * 0.5) + eqDEF
	local MDEF = base.BaseMDEF + math.floor(INT * 1.2) + math.floor(level * 0.4) + eqMDEF

	-- ------------------------------------------------------------------
	-- HIT & FLEE: Ragnarok M 1:1 Base + Stat + Level + Equip
	-- ------------------------------------------------------------------
	local HIT = DEX + level + 20 + eqHIT
	local FLEE = AGI + level + 10 + eqFLEE

	-- ------------------------------------------------------------------
	-- ASPD = min(BaseASPD + floor(AGI*4) + eqASPD, 190)
	-- สูงสุด 190 (capped at 190 attacks/min)
	-- ------------------------------------------------------------------
	local ASPD = math.min(base.BaseASPD + math.floor(AGI * 4) + eqASPD, 190)

	-- ------------------------------------------------------------------
	-- CritRate = floor(LUK/3) + 1 + eqCritRate
	-- ------------------------------------------------------------------
	local CritRate = math.floor(LUK / 3) + 1 + eqCritRate

	-- ------------------------------------------------------------------
	-- PerfectDodge = floor(LUK/10)
	-- ------------------------------------------------------------------
	local PerfectDodge = math.floor(LUK / 10)

	-- ------------------------------------------------------------------
	-- MaxWeight = 200 + STR*30
	-- ------------------------------------------------------------------
	local MaxWeight = 200 + (STR * 30)

	-- ------------------------------------------------------------------
	-- HPRegen = floor(VIT/5) + 1  (per 10 second tick)
	-- ------------------------------------------------------------------
	local HPRegen = math.floor(VIT / 5) + 1

	-- ------------------------------------------------------------------
	-- Fractional SP per second; skills remain resource-limited at high INT.
	-- ------------------------------------------------------------------
	local SPRegen = math.min(2.5, 1 + INT / 20)

	-- คืนค่าสถิติทั้งหมด (Return all derived stats as a table)
	return {
		MaxHP        = MaxHP,
		MaxSP        = MaxSP,
		ATK          = ATK,
		MATK_min     = MATK_min,
		MATK_max     = MATK_max,
		DEF          = DEF,
		MDEF         = MDEF,
		HIT          = HIT,
		FLEE         = FLEE,
		ASPD         = ASPD,
		CritRate     = CritRate,
		PerfectDodge = PerfectDodge,
		MaxWeight    = MaxWeight,
		HPRegen      = HPRegen,
		SPRegen      = SPRegen,
		MoveSpeed    = base.BaseMove,
	}
end

-- ---------------------------------------------------------------------------
-- GetClass(classID)
-- คืนข้อมูลคลาสที่ระบุ / Returns class data table for the given classID
-- ---------------------------------------------------------------------------
function ClassData.GetClass(classID)
	local classInfo = ClassData.Classes[classID]
	if not classInfo then
		warn("[ClassData] GetClass: Unknown classID = " .. tostring(classID))
		return nil
	end
	return classInfo
end

-- ---------------------------------------------------------------------------
-- GetAllClasses()
-- คืนรายการคลาสทั้งหมด / Returns all class data tables
-- ---------------------------------------------------------------------------
function ClassData.GetAllClasses()
	return ClassData.Classes
end

-- ---------------------------------------------------------------------------
-- CanUseWeapon(classID, weaponType)
-- ตรวจสอบว่าคลาสใช้อาวุธนี้ได้ไหม
-- Returns true if the given class can equip the given weapon type
-- ---------------------------------------------------------------------------
function ClassData.CanUseWeapon(classID, weaponType)
	local classInfo = ClassData.Classes[classID]
	if not classInfo then return false end
	for _, wep in ipairs(classInfo.UsableWeapons) do
		if wep == weaponType then
			return true
		end
	end
	return false
end

-- ---------------------------------------------------------------------------
-- GetStartingStats(classID)
-- คืนค่าสถิติเริ่มต้นของคลาส (คัดลอกข้อมูลเพื่อป้องกันการแก้ไขต้นฉบับ)
-- Returns a copy of the starting stats for the given class
-- ---------------------------------------------------------------------------
function ClassData.GetStartingStats(classID)
	local classInfo = ClassData.Classes[classID]
	if not classInfo then return nil end
	local copy = {}
	for k, v in pairs(classInfo.StartStats) do
		copy[k] = v
	end
	copy.StatPoints = classInfo.StartStatPoints or 0
	return copy
end

-- ---------------------------------------------------------------------------
-- CanChangeClass(currentClassID, targetClassID, jobLevel)
-- ตรวจสอบว่าสามารถเปลี่ยนคลาสได้หรือไม่
-- Returns (bool, message) whether the player meets requirements to advance
-- ---------------------------------------------------------------------------
function ClassData.CanLearnSkill(playerClass, skillClass)
	if skillClass == "Novice" then return true end
	if skillClass == playerClass then return true end
	local parent = ClassData.ParentClass and ClassData.ParentClass[playerClass]
	if parent and parent == skillClass then return true end
	return false
end

function ClassData.CanChangeClass(currentClassID, targetClassID, jobLevel)
	local currentClass = ClassData.Classes[currentClassID]
	if not currentClass then
		return false, "Invalid current class"
	end

	-- ตรวจสอบ JobLevel ขั้นต่ำ (Check minimum JobLevel requirement)
	if jobLevel < (currentClass.JobChangeReq or 10) then
		return false, string.format(
			"ต้องการ Job Level %d (ปัจจุบัน %d)",
			currentClass.JobChangeReq,
			jobLevel
		)
	end

	-- ตรวจสอบว่า targetClass อยู่ในตัวเลือก (Check if target is a valid option)
	local options = currentClass.AdvanceOptions or {}
	for _, opt in ipairs(options) do
		if opt == targetClassID then
			return true, "OK"
		end
	end

	return false, "คลาส " .. tostring(targetClassID) .. " ไม่สามารถเปลี่ยนได้จาก " .. tostring(currentClassID)
end

-- ---------------------------------------------------------------------------
-- Module return (คืน module)
-- ---------------------------------------------------------------------------
return ClassData
