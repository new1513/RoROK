-- ============================================================
-- StoryQuestData.lua
-- ภารกิจเนื้อเรื่องประจำเมืองสไตล์ Ragnarok M (Town Story Quests)
-- ทำได้เพียงครั้งเดียวต่อบัญชี (One-Time per Account)
-- ช่วยเร่งเลเวลผู้เล่นใหม่ มอบอุปกรณ์เริ่มต้น อาวุธประจำอาชีพ และเงินทุน Zeny
-- ============================================================

local StoryQuestData = {}

StoryQuestData.Quests = {
	{
		id = "SQ01_FirstStep",
		title = "ก้าวแรกของนักผจญภัย",
		chapter = 1,
		npcId = "GuildMaster",
		npcName = "กิลด์มาสเตอร์ ซิกฟรีด",
		npcTitle = "ผู้ดูแลสมาคมนักผจญภัย Prontera",
		npcAvatar = "🛡️",
		levelReq = 1,
		prerequisite = nil,
		dialogueStart = "ยินดีต้อนรับสู่เมืองหลวง Prontera! สมาคมนักผจญภัยยินดีต้อนรับผู้มาเยือนเสมอ แต่ก่อนที่เจ้าจะก้าวสู่โลกกว้าง ข้าต้องทดสอบความกล้าหาญของเจ้าก่อน จงออกไปที่ทุ่งหญ้าตะวันออก และปราบ Poring 5 ตัว เพื่อพิสูจน์ฝีมือ!",
		dialogueInProgress = "ทุ่งหญ้าตะวันออกอยู่นอกประตูกำแพงเมือง รีบไปปราบ Poring ให้ครบ 5 ตัวแล้วกลับมารายงานตัวนะ!",
		dialogueReady = "ยอดเยี่ยมมาก! การเคลื่อนไหวของเจ้าคล่องแคล่วสมเป็นนักรบ นี่คือรางวัลและอุปกรณ์เริ่มต้นจากสมาคมนักผจญภัย!",
		dialogueFinished = "เจ้าทำได้ดีมากในก้าวแรก ตอนนี้จงไปหานักสำรวจรุ่นพี่ Leon แถวจัตุรัสน้ำพุกลางเมือง เขาจะแนะนำเส้นทางถัดไปให้เจ้า!",
		objective = "Kill",
		target = "Poring",
		targetName = "Poring",
		amount = 5,
		rewardXP = 12000,
		rewardJobXP = 8500,
		rewardGold = 2500,
		rewardItems = {
			{ itemId = "PoringHood", count = 1, name = "Poring Hood (ฮู้ดโพริ่ง)" },
			{ itemId = "RedPotion", count = 25, name = "Red Potion" },
			{ itemId = "BluePotion", count = 15, name = "Blue Potion" },
		},
		nextNpcHint = "ไปพบ นักสำรวจรุ่นพี่ Leon ที่จัตุรัสน้ำพุกลางเมือง",
	},

	{
		id = "SQ02_FieldSurvival",
		title = "บทเรียนการเอาชีวิตรอด",
		chapter = 2,
		npcId = "TravelerGuideNPC",
		npcName = "นักสำรวจรุ่นพี่ Leon",
		npcTitle = "ผู้เชี่ยวชาญการเอาชีวิตรอดในป่า",
		npcAvatar = "🧭",
		levelReq = 3,
		prerequisite = "SQ01_FirstStep",
		dialogueStart = "ฮ่า! เจ้าคือนักผจญภัยหน้าใหม่ที่ Siegfried พูดถึงสินะ ในทุ่งกว้างมอนสเตอร์ไม่ได้มีแค่ Poring เจ้าต้องระวังกระต่ายป่า Lunatic ที่ว่องไว จงไปปราบ Lunatic 4 ตัว แล้วเก็บ Carrot ติดมือกลับมาให้ข้าสัก 2 ชิ้น!",
		dialogueInProgress = "กระต่าย Lunatic วิ่งเร็วและชอบหลบหลีกในพงหญ้า ปราบพวกมัน 4 ตัวแล้วนำ Carrot มาให้ข้า 2 ชิ้นนะ!",
		dialogueReady = "ทำได้ยอดเยี่ยมมาก! เจ้าเริ่มจับจังหวะการต่อสู้ได้ดีแล้ว นี่คือชุดเกราะนักเดินทางและหินตีบวกสำหรับเจ้า!",
		dialogueFinished = "พลังของเจ้าเติบโตขึ้นมากแล้ว! ถึงเวลาที่เจ้าต้องอัปเกรดอาวุธให้คมกล้า จงไปหาช่างตีเหล็ก Hollgrehenn ที่โรงตีเหล็กมุมตะวันตกเฉียงเหนือ!",
		objective = "Kill",
		target = "Lunatic",
		targetName = "กระต่าย Lunatic",
		amount = 4,
		collectTarget = "Carrot",
		collectAmount = 2,
		rewardXP = 25000,
		rewardJobXP = 18000,
		rewardGold = 4000,
		rewardItems = {
			{ itemId = "NoviceClothes", count = 1, name = "Novice Clothes (ชุดผ้านักผจญภัย)" },
			{ itemId = "BeginnerRefinementStone", count = 15, name = "หินตีบวกเริ่มต้น" },
			{ itemId = "Panacea", count = 5, name = "Panacea (ยาแก้สถานะ)" },
		},
		nextNpcHint = "ไปพบ ช่างตีเหล็ก Hollgrehenn ที่โรงตีเหล็กมุมตะวันตกเฉียงเหนือ",
	},

	{
		id = "SQ03_ForgeMastery",
		title = "ศาสตราแห่งโรงตีเหล็ก",
		chapter = 3,
		npcId = "Blacksmith",
		npcName = "ช่างตีเหล็ก Hollgrehenn",
		npcTitle = "ปรมาจารย์ช่างตีเหล็กหลวง",
		npcAvatar = "⚒️",
		levelReq = 8,
		prerequisite = "SQ02_FieldSurvival",
		dialogueStart = "แคล๊ง! แคล๊ง! อาวุธที่ดีคือชีวิตของนักรบ! เจ้าอยากได้อาวุธที่เหมาะกับสายอาชีพของเจ้าใช่ไหม? ตอนนี้เตาหลอมของข้าขาดแร่เหล็ก Iron Ore 2 ก้อน และน้ำเมือก Sticky Mucus 3 ชิ้นสำหรับชุบแข็งโลหะ จงไปหามาให้ข้า ข้าจะตีอาวุธชั้นยอดให้เจ้าทันที!",
		dialogueInProgress = "Iron Ore และ Sticky Mucus ยังไม่ครบเลยเพื่อน! หาแร่เหล็ก 2 ก้อนและน้ำเมือก 3 ชิ้นมาเร็วเข้า เตาหลอมกำลังร้อนได้ที่!",
		dialogueReady = "ฮ่าฮ่าฮ่า! แร่เหล็กคุณภาพเยี่ยมมาก! นี่คืออาวุธประจำอาชีพของเจ้า ข้าขัดเงาและปรับคมมาอย่างดี พร้อมหินตีบวกไปลองฝีมือ!",
		dialogueFinished = "หากต้องการตีบวกอุปกรณ์เพิ่มเติม แวะมาหาข้าที่เตาหลอมได้ตลอดเวลานะ! ตอนนี้แม่ชี Aria ข้างมหาวิหารกำลังตามหาคนช่วยงานอยู่",
		objective = "Collect",
		target = "IronOre",
		targetName = "Iron Ore (แร่เหล็ก)",
		amount = 2,
		secondaryCollectTarget = "StickyMucus",
		secondaryCollectAmount = 3,
		rewardXP = 45000,
		rewardJobXP = 32000,
		rewardGold = 6500,
		rewardClassWeapon = true, -- Auto-tailor starter weapon to current class
		rewardItems = {
			{ itemId = "BeginnerRefinementStone", count = 25, name = "หินตีบวกเริ่มต้น" },
			{ itemId = "FireScroll", count = 5, name = "Fire Elemental Scroll" },
		},
		nextNpcHint = "ไปพบ หมอดูเครื่องราง Aria ที่ร้านค้าข้างมหาวิหาร Prontera",
	},

	{
		id = "SQ04_WolfMenace",
		title = "ภัยคุกคามแห่งพงไพร",
		chapter = 4,
		npcId = "TalismanSeerNPC",
		npcName = "หมอดูเครื่องราง Aria",
		npcTitle = "ผู้พิทักษ์แห่งแสงศักดิ์สิทธิ์",
		npcAvatar = "🔮",
		levelReq = 12,
		prerequisite = "SQ03_ForgeMastery",
		dialogueStart = "ขอแสงสว่างคุ้มครองเจ้า... คืนนี้ฝูงหมาป่า Wolf บริเวณลำธารรอบนอกดุร้ายผิดปกติ พวกมันเริ่มคุกคามชาวบ้านที่เดินทางไปมา หากปล่อยไว้จะเป็นอันตรายใหญ่หลวง วานเจ้าช่วยปราบหมาป่า Wolf 6 ตัว เพื่อนำความสงบสุขกลับคืนมาเถิด!",
		dialogueInProgress = "ฝูงหมาป่ายังคงเพ่นพ่านอยู่แถวริมธาร ปราบ Wolf ให้ครบ 6 ตัวเพื่อความปลอดภัยของชาวบ้านนะ!",
		dialogueReady = "ขอบพระคุณในความเสียสละของเจ้ามาก! เมืองหลวงสงบสุขได้เพราะความกล้าหาญของเจ้า นี่คือการ์ดมอนสเตอร์ศักดิ์สิทธิ์และยารักษาอาการบาดเจ็บ",
		dialogueFinished = "ความดีงามของเจ้าจะได้รับการจารึก ตอนนี้หัวหน้าอัศวิน Herman กำลังตามหานักรบฝีมือดีไปทดสอบที่ลานประลองหลวง!",
		objective = "Kill",
		target = "Wolf",
		targetName = "หมาป่า Wolf",
		amount = 6,
		rewardXP = 75000,
		rewardJobXP = 55000,
		rewardGold = 9000,
		rewardItems = {
			{ itemId = "PoringCard", count = 1, name = "Poring Card (การ์ดใส่เกราะ MaxHP +250)" },
			{ itemId = "OrangePotion", count = 25, name = "Orange Potion (ฟื้นฟู HP 600)" },
			{ itemId = "Panacea", count = 8, name = "Panacea" },
		},
		nextNpcHint = "ไปพบ หัวหน้าอัศวิน Herman ที่กิลด์อัศวินทิศตะวันตก",
	},

	{
		id = "SQ05_KnightTrial",
		title = "บททดสอบแห่งอัศวิน",
		chapter = 5,
		npcId = "KnightMasterNPC",
		npcName = "หัวหน้าอัศวิน Herman",
		npcTitle = "แม่ทัพแห่งกองอัศวิน Prontera",
		npcAvatar = "⚔️",
		levelReq = 16,
		prerequisite = "SQ04_WolfMenace",
		dialogueStart = "เจ้าคือนักรบที่ปราบฝูงหมาป่าสินะ! ฝีมือของเจ้าเริ่มเป็นที่เลื่องลือ แต่กองอัศวิน Prontera ต้องการผู้ที่แข็งแกร่งและมีวินัยอย่างแท้จริง จงไปที่ลานประลองหลวงข้างมหาวิหาร และทำลายหุ่นฟางซ้อมรบ TrainingDummy 6 ตัวให้สิ้นซาก!",
		dialogueInProgress = "อย่าเพิ่งลดการฝึกฝน! จงฟาดฟันหุ่นซ้อมรบ TrainingDummy ให้ครบ 6 ตัว แล้วข้าจะยอมรับในฝีมือของเจ้า!",
		dialogueReady = "ยอดเยี่ยมมาก! การโจมตีของเจ้าหนักแน่นและแม่นยำดั่งอัศวินหลวง นี่คือเกราะโซ่เหล็กกล้า Chain Mail อันทรงเกียรติของ Prontera!",
		dialogueFinished = "เจ้าคือนักรบที่ข้าภาคภูมิใจ บัดนี้จงไปรับพรศักดิ์สิทธิ์ขั้นสูงสุดจากหลวงพ่อ Bamph ณ มหาวิหารหลวง Grand Cathedral!",
		objective = "Kill",
		target = "TrainingDummy",
		targetName = "หุ่นซ้อมรบ Training Dummy",
		amount = 6,
		rewardXP = 110000,
		rewardJobXP = 80000,
		rewardGold = 12000,
		rewardItems = {
			{ itemId = "ChainMail", count = 1, name = "Prontera Chain Mail (DEF +45, MaxHP +400)" },
			{ itemId = "WhitePotion", count = 20, name = "White Potion (ฟื้นฟู HP 2500)" },
			{ itemId = "HolyScroll", count = 5, name = "Holy Elemental Scroll" },
		},
		nextNpcHint = "ไปพบ หลวงพ่อ Bamph ที่มหาวิหารใหญ่ Grand Cathedral ทางเหนือ",
	},

	{
		id = "SQ06_CathedralBlessing",
		title = "พรแห่งแสงสว่าง",
		chapter = 6,
		npcId = "ArchbishopBamph",
		npcName = "หลวงพ่อ Bamph",
		npcTitle = "สังฆราชแห่งมหาวิหารหลวง Prontera",
		npcAvatar = "✝️",
		levelReq = 20,
		prerequisite = "SQ05_KnightTrial",
		dialogueStart = "ขอความเมตตาแห่งทวยเทพสถิตอยู่กับเจ้า... ข่าวการเสียสละและปกป้องเมืองของเจ้าแผ่ขยายไปทั่วอาณาจักร วันนี้ข้าขอเชิญเจ้าเข้ารับพิธีประสิทธิ์ประสาทพรแห่งมหาวิหารหลวง เพื่อเปิดเส้นทางสู่นักรบในตำนาน เจ้าพร้อมจะรับพรหรือไม่?",
		dialogueInProgress = "ขอให้จิตใจของเจ้าสงบนิ่งและพร้อมรับแสงศักดิ์สิทธิ์แห่งทวยเทพ...",
		dialogueReady = "ขอแสงสว่างจงส่องนำทางทุกการเดินทางของเจ้า! บัดนี้เจ้าคือวีรชนแห่ง Prontera อย่างแท้จริง จงรับการ์ดหมาป่า Wolf Card และพรแห่งความมั่งคั่งนี้ไป!",
		dialogueFinished = "ประตูแห่งอาณาจักรรูนมิดการ์ดเปิดต้อนรับเจ้าแล้ว ไม่ว่าเจ้าจะเดินทางไปยัง Morroc, Geffen หรือเกาะ Amatsu ขอให้ความกล้าหาญจงอยู่กับเจ้าเสมอ!",
		objective = "Visit",
		target = "ArchbishopBamph",
		targetName = "หลวงพ่อ Bamph",
		amount = 1,
		rewardXP = 150000,
		rewardJobXP = 100000,
		rewardGold = 18000,
		rewardItems = {
			{ itemId = "WolfCard", count = 1, name = "Wolf Card (การ์ดใส่อาวุธ)" },
			{ itemId = "BeginnerRefinementStone", count = 30, name = "หินตีบวกเริ่มต้น" },
			{ itemId = "Panacea", count = 12, name = "Panacea" },
		},
		nextNpcHint = "สำเร็จเควสเนื้อเรื่องเมือง Prontera ครบถ้วนสมบูรณ์แล้ว!",
	},
}

StoryQuestData.QuestsById = {}
StoryQuestData.QuestsByNpc = {}

for _, quest in ipairs(StoryQuestData.Quests) do
	StoryQuestData.QuestsById[quest.id] = quest
	StoryQuestData.QuestsByNpc[quest.npcId] = quest
end

-- Helper to get starter weapon tailored to player class
function StoryQuestData.GetClassWeapon(classID)
	local map = {
		Mage     = "ApprenticeRod",
		Knight   = "KnightTrainingSword",
		Archer   = "ArcherTrainingBow",
		Thief    = "ThiefTrainingDagger",
		Acolyte  = "AcolyteTrainingMace",
		Merchant = "MerchantTrainingAxe",
		Novice   = "NoviceTrainingDagger",
	}
	return map[classID] or "NoviceTrainingDagger"
end

function StoryQuestData.GetQuestById(questId)
	return StoryQuestData.QuestsById[questId]
end

function StoryQuestData.GetQuestByNpc(npcId)
	return StoryQuestData.QuestsByNpc[npcId]
end

return StoryQuestData
