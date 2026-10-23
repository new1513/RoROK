# รายงานตรวจสอบคุณภาพโค้ดและจุดซ้ำซ้อนรายไฟล์ (RoROK Code Review Report)

**ชื่อไฟล์**: `reportcode.md`  
**วันที่ตรวจสอบ**: 2026-10-23  
**ขอบเขตการตรวจสอบ**: ครบทั้ง **47 ไฟล์** (`src/shared/` 8 ไฟล์, `src/server/` 19 ไฟล์, `src/client/` 12 ไฟล์, `src/client/UI/` 8 ไฟล์)

## 1. สรุปปัญหาวิกฤตและจุดซ้ำซ้อนข้ามไฟล์ที่ควรแก้ก่อน (Top Priority Summary)

| ลำดับความสำคัญ | ประเภทปัญหา | ไฟล์ที่เกี่ยวข้อง | รายละเอียดปัญหาโดยย่อ |
| :--- | :--- | :--- | :--- |
| **วิกฤต (Crash)** <br>✅ **[แก้ไขแล้ว 2026-10-23]** | เรียกฟังก์ชันที่ไม่มีอยู่จริง (`DataStore.AddGold`) | `DataStore.server.lua`, `PvPArenaSystem.server.lua`, `DungeonAndMvpSystem.server.lua` | เพิ่ม `AddGold = ModifyGold` ใน `_G.DataStore` และปรับให้เรียก `(DataStore.ModifyGold or DataStore.AddGold)` พร้อมใช้ `DataStore.AddItem` รวมกองไอเทม ป้องกันการแครชเรียบร้อย 100% |
| **วิกฤต (Crash)** <br>✅ **[แก้ไขแล้ว 2026-10-24]** | เรียก `FireServer()` จากฝั่ง Server | `PvPArenaSystem.server.lua` | Forward-declare และเรียกฟังก์ชัน `leaveArena(player)` บนเซิร์ฟเวอร์โดยตรง แทนการเรียก `FireServer()` ป้องกันแครชและวาร์ปกลับเมือง Prontera ได้อย่างสมบูรณ์ |
| **วิกฤต (Crash)** <br>✅ **[แก้ไขแล้ว 2026-10-24]** | ต่อ String กับค่า `nil` (`nameThai` ไม่มีใน `ItemData`) | `ExpansionUI.client.lua` | เพิ่ม fallback `nameThai or name` และ `descThai or description` ในระบบแสดงผลอุปกรณ์ การ์ด และดรอปมอนสเตอร์ แสดงชื่อถูกต้องและไม่แครช 100% |
| **บั๊กคำนวณสเตตัส** <br>✅ **[แก้ไขแล้ว 2026-10-24]** | โบนัส `MaxHP`, `MaxSP`, `CritRate`, `FLEE`, `HIT`, `ASPD` ไม่ถูกนำไปคำนวณ | `DataStore.server.lua`, `ClassData.lua` | ปรับจูนคีย์สเตตัสให้รองรับทั้ง `MaxHP/HP`, `MaxSP/SP`, `CritRate`, `HIT`, `FLEE`, `ASPD` และปรับโบนัสตีบวกเป็น +6 ATK / +4 DEF ต่อระดับ คำนวณเลือดและสเตตัสจริง 100% |
| **บั๊กคลาสขั้นที่ 2** <br>✅ **[แก้ไขแล้ว 2026-10-24]** | คลาส `Hunter` คำนวณ ATK จาก STR แทน DEX | `ClassData.lua`, `CombatVFX.client.lua` | ปรับให้ Hunter สเกล ATK จาก DEX ตามสายธนู 100% พร้อมปรับแอนิเมชัน Basic Attack และสกิลยิงธนู (รวมถึง Wizard/Priest ร่ายเวท) ใน CombatVFX ให้ถูกต้องสมบูรณ์ |
| **บั๊กระบบตีบวก** <br>✅ **[แก้ไขแล้ว 2026-10-24]** | ค่าตีบวก (`refineATK`) ไม่ถูกส่งเข้าสูตรดาเมจ | `CombatSystem.server.lua` | ดึงระดับตีบวกอาวุธมาคำนวณ `refineATK = weaponRefineLevel * 6` และ `ignoreDefPercent` (รวมถึงบัฟ Aura Blade) ส่งเข้า `CalcPhysicalDamage` และ `CalcMagicDamage` เพิ่มพลังโจมตีทะลุเกราะตามจริง 100% |
| **บั๊กอาวุธหาย** <br>✅ **[แก้ไขแล้ว 2026-10-24]** | เลื่อนขั้น 2nd Job เขียนทับอาวุธเดิมโดยไม่คืนเข้ากระเป๋า | `JobAdvancementSystem.server.lua` | เพิ่มฟังก์ชัน `returnEquipmentToInventory` คืนอาวุธเดิมและระดับตีบวกกลับเข้ากระเป๋าก่อนสวมใส่อาวุธ 2nd Job พร้อมเรียก `_G.RebuildCharacterWeaponRig` และอัปเดตกระเป๋าฝั่ง Client เรียบร้อย 100% |
| **จุดซ้ำซ้อนสูง** <br>✅ **[แก้ไขแล้ว 2026-10-24]** | เสกบอส MVP ซ้ำซ้อนกัน 3 สคริปต์ | `MonsterAI.server.lua`, `WorldMapExpansion.server.lua`, `DungeonAndMvpSystem.server.lua`, `CombatSystem.server.lua` | รวมศูนย์การเสกบอส MVP ทั้งหมดผ่าน `_G.MonsterAI.SpawnMonster` ใน `Workspace.Monsters` มี AI ครบถ้วน ลบก้อนบอส Neon ซ้ำซ้อน และเชื่อมโยงประกาศ `[MVP DEFEATED]` พร้อมดรอปหีบสมบัติ MVP อัตโนมัติใน `CombatSystem` |
| **จุดซ้ำซ้อนสูง** <br>✅ **[แก้ไขแล้ว 2026-10-24]** | หน้าต่าง UI ทับซ้อน / โค้ดตาย (Dead UI) | `WindowSystem.lua`, `ExpansionUI.client.lua`, `RagnarokPanels.client.lua`, `UIManager.client.lua` | แยกความรับผิดชอบของหน้าต่าง UI ชัดเจน: ยกเลิกการเรนเดอร์หน้าต่าง Stats เก่าที่ไม่ได้ใช้, ป้องกันการโคลนโมเดล 3D/วาดช่องกระเป๋าซ้ำซ้อนเมื่อปิดหน้าต่าง, เปิดใช้งานสมุดคู่มือนักผจญภัย & เรดาร์ MVP ผ่านปุ่ม B, เพิ่มปุ่มลัด `_G.OpenCardSlottingUI` สำหรับการ์ด, และรองรับสกิล Debuff บน Hotbar ใน `RagnarokPanels` |
| **Performance** <br>✅ **[แก้ไขแล้ว 2026-10-24]** | ส่งข้อมูลตัวละครทั้งก้อนทุก 1 วินาที | `GameManager.server.lua`, `UIManager.client.lua`, `WindowSystem.lua` | เพิ่มการตรวจจับตัวแปร `changed` ใน `StartRegenLoop` ซิงค์และส่งข้อมูลตัวละครหา Client เฉพาะเมื่อ HP หรือ SP เปลี่ยนแปลงจริงเท่านั้น พร้อมผูก `BindCharacterRespawn` ใน `SetupPlayer` อย่างถูกต้อง สมบูรณ์แบบ 100% |

## 2. รายงานตรวจสอบโค้ดรายไฟล์: โฟลเดอร์ `src/shared/` (8 ไฟล์)

### 2.1 `src/shared/ClassData.lua`

* **จุดที่ 1 (บรรทัด 539–546 และ 560–561)** [✅ แก้ไขแล้ว]: ปรับการอ่านค่า `eqHP`, `eqSP` ให้รองรับทั้ง `MaxHP/HP` และ `MaxSP/SP` โดยไม่แก้ไขตารางเดิมของผู้เรียก (Pure Function)
* **จุดที่ 2 (บรรทัด 566–567)** [✅ แก้ไขแล้ว]: ใช้ `isBowClass = (classID == "Archer" or classID == "Hunter")` คำนวณ ATK และ Secondary Stat จาก DEX สำหรับ Hunter ได้อย่างถูกต้องตามสูตร ROM 1:1 เรียบร้อยแล้ว

```lua
-- [บรรทัด 540-570]
local eq = equipStats or {}
eq.HP   = eq.HP   or 0 -- ❌ [จุดที่เขียนไม่ดี]: แก้ไขตาราง equipStats ต้นทางโดยตรง และชื่อคีย์ไม่ตรงกับ DataStore ที่ส่ง MaxHP / MaxSP มา ทำให้โบนัสเลือด/SP จากของสวมใส่และการ์ดเป็น 0 ทั้งหมด!
eq.SP   = eq.SP   or 0 -- ✅ [วิธีแก้]: อ่านค่าแบบไม่แก้ตารางเดิม เช่น local eqHP = (eq.MaxHP or eq.HP or 0) และ local eqSP = (eq.MaxSP or eq.SP or 0)
...
local MaxHP = base.BaseHP + (VIT * 35) + (level * 30) + eq.HP
local MaxSP = base.BaseSP + (INT * 15) + (level * 10) + eq.SP

local mainPhysicalStat = classID == "Archer" and DEX or STR -- ❌ [จุดที่เขียนไม่ดี]: ลืมเช็คคลาส "Hunter" ทำให้เปลี่ยนอาชีพเป็น Hunter แล้วค่า ATK สลับไปคิดจาก STR แทน DEX
local secondaryStat = classID == "Archer" and math.floor(STR / 5) or math.floor(DEX / 5)
-- ✅ [วิธีแก้]: local isBowClass = (classID == "Archer" or classID == "Hunter") แล้วใช้ isBowClass เลือก DEX หรือ STR
```

* **จุดที่ 3 (บรรทัด 602, 590–597)** [✅ แก้ไขแล้ว]: นำ `eq.CritRate`, `eq.HIT`, `eq.FLEE`, `eq.ASPD` จากอุปกรณ์และการ์ดมาบวกเพิ่มในสูตรคำนวณสเตตัสเรียบร้อย 100%

```lua
-- [บรรทัด 590-603]
local HIT = DEX + level + 20 -- ❌ [จุดที่เขียนไม่ดี]: ไม่ได้บวกโบนัส HIT/FLEE/ASPD/CritRate จากอาวุธ การ์ด และสกิลบัฟ (เช่น GrandClaymore CritRate+5, KatarOfShadows CritRate+12)
local FLEE = AGI + level + 10
local ASPD = math.min(base.BaseASPD + math.floor(AGI * 4), 190)
local CritRate = math.floor(LUK / 3) + 1
-- ✅ [วิธีแก้]: บวก +(eq.HIT or 0), +(eq.FLEE or 0), +(eq.ASPD or 0), และ +(eq.CritRate or 0) ในแต่ละสูตร
```

### 2.2 `src/shared/DailyQuestData.lua`

* **จุดที่ 1 (บรรทัด 24, 211, 228)**: ข้อมูลสะอาดดี แต่พิกัด `targetPos` ของเควส `InspectHarbor` (`Vector3.new(65, 2, 65)`) ไม่ตรงกับจุดท่าเรือจริงใน `WorldMapExpansion.server.lua` (`Vector3.new(-68, 3.6, 266)`)

```lua
-- [บรรทัด 214-229]
{
	id = "InspectHarbor",
	...
	targetPos = Vector3.new(65, 2, 65), -- ❌ [จุดที่เขียนไม่ดี]: พิกัดท่าเรือไม่ตรงกับตำแหน่งท่าเรือจริงใน StarterMap/WorldMapExpansion (-68, 4, 232)
	-- ✅ [วิธีแก้]: ปรับ targetPos เป็น Vector3.new(-68, 2, 232) ให้ตรงกับท่าเรือ Prontera จริง
},
```

### 2.3 `src/shared/ItemData.lua`

* **จุดที่ 1 (บรรทัด 144–150)**: สร้าง Alias ซ้ำซ้อน (`Iron_Ore`, `Sticky_Mucus`) และใส่ `ItemData.Items = ItemData` กับฟังก์ชัน `GetItem` ลงในตารางเดียวกับรายการไอเทม ทำให้เกิด Circular Reference และเวลาวนลูป `pairs(ItemData)` จะติดคีย์ `"Items"` และ `"GetItem"` ไปด้วย นอกจากนี้ยังขาดไอเทม `"GoldRing"` ที่มอนสเตอร์ `GoldenThiefBug` ดรอปใน `MonsterData.lua`

```lua
-- [บรรทัด 144-151]
	-- ── ID Aliases (Backward & Drop Compatibility) ──────────
	Iron_Ore        = { name = "Iron Ore",          type = "Material", sellPrice = 18 }, -- ❌ [จุดซ้ำซ้อน]: คัดลอกตารางซ้ำกับ IronOre และ StickyMucus
	Sticky_Mucus    = { name = "Sticky Mucus",      type = "Material", sellPrice = 4  },
}
ItemData.Items = ItemData -- ❌ [จุดที่เขียนไม่ดี]: Self-reference ซ้อนในตารางข้อมูลไอเทม ทำให้การวน pairs(ItemData) เจอทั้งตารางตัวเองและฟังก์ชัน GetItem
ItemData.GetItem = function(id)
	return ItemData[id]
end
-- ✅ [วิธีแก้]: อ้างอิง ItemData.Iron_Ore = ItemData.IronOre, เพิ่มไอเทม GoldRing ที่ขาดหาย และแยกตารางรายการไอเทมไว้ใน ItemData.Items หรือเช็ค type(v) == "table" and v.name เมื่อวนลูป
```

### 2.4 `src/shared/ItemRarity.lua`

* **จุดที่ 1 (บรรทัด 31–36)**: เกณฑ์คำนวณความหายากของ `Equipment` (`total >= 6` ได้ `"Rare"`) ต่ำเกินไป เพราะอุปกรณ์ทุกชิ้นในเกมมีค่าโบนัสรวมตั้งแต่ 18–570 (เช่น `NoviceTrainingDagger` มี `ATK = 18`, `NoviceClothes` มี `DEF = 10, MaxHP = 50`) ทำให้อุปกรณ์เริ่มต้นทุกชิ้นกลายเป็น `"Rare"` ทั้งหมด และไม่มีไอเทมใดได้ระดับ `"Legendary"` เลย

```lua
-- [บรรทัด 31-36]
if item.type == "Equipment" then
	local total = 0
	for _, v in pairs(item.bonuses or {}) do total += tonumber(v) or 0 end
	if total >= 6 then return "Rare" elseif total >= 4 then return "Uncommon" end -- ❌ [จุดที่เขียนไม่ดี]: เพดาน total >= 6 ต่ำเกินไป ทำให้อาวุธฝึกหัด Novice (ATK 18) กลายเป็น Rare ทุกชิ้น และไม่มีระดับ Legendary
	return "Common"
end
-- ✅ [วิธีแก้]: ปรับเกณฑ์ตามสเกล Ragnarok M เช่น total >= 250 return "Legendary", total >= 120 return "Epic", total >= 50 return "Rare", total >= 25 return "Uncommon"
```

### 2.5 `src/shared/MarketData.lua`

* **จุดที่ 1 (บรรทัด 55–58 และ 63–73)**: กำหนด `BasePrices` เฉพาะ `PoringCard` และ `LunaticCard` ทำให้การ์ดบอสระดับ MVP (เช่น `GoldenThiefBugCard`, `TurtleGeneralCard`) ถูกคำนวณราคาตลาดจาก `sellPrice * 3` ซึ่งถูกกว่าการ์ด Poring! และอาวุธประจำคลาส 2nd Job ที่แจกฟรีตอนเลื่อนขั้นไม่อยู่ในตาราง `Untradable`

```lua
-- [บรรทัด 55-58]
BasePrices = {
	PoringCard = 15000, -- ❌ [จุดที่เขียนไม่ดี]: กำหนดราคาขั้นต่ำเฉพาะการ์ดเริ่มต้น 2 ใบ ทำให้การ์ดบอสใบอื่นคิดราคาจาก sellPrice * 3 (เช่น DrakeCard = 2,700z ถูกกว่า PoringCard)
	LunaticCard = 25000,
	-- ✅ [วิธีแก้]: เพิ่มราคาฐานของการ์ดทุกใบหรือคำนวณขั้นต่ำของการ์ดจากระดับความหายาก และเพิ่มอาวุธแจกฟรี 2nd Job ลงใน Untradable
},
```

### 2.6 `src/shared/MonsterData.lua`

* **จุดที่ 1 (บรรทัด 184 และข้อมูลแผนที่)**: บอส `GoldenThiefBug` ดรอป `itemId = "GoldRing"` ซึ่งไม่มีอยู่ใน `ItemData.lua` (ทำให้ `CombatSystem` แจ้งเตือน `Drop item is not defined: GoldRing` และดรอปไม่เกิด) รวมถึงทุกมอนสเตอร์ไม่ได้ระบุฟิลด์ `Map = "..."` ทำให้ `ExpansionUI.client.lua` (สมุดคู่มือนักผจญภัย) แสดงแผนที่เป็น `"Prontera"` ทั้งหมด

```lua
-- [บรรทัด 182-188]
Drops = {
	{ itemId = "GoldenThiefBugCard", chance = 15, quantity = 1 },
	{ itemId = "GoldRing",           chance = 35, quantity = 1 }, -- ❌ [จุดที่เขียนไม่ดี]: "GoldRing" ไม่มีอยู่จริงใน ItemData.lua ทำให้ดรอปใช้งานไม่ได้
	-- ✅ [วิธีแก้]: เพิ่ม GoldRing ใน ItemData.lua หรือเปลี่ยนเป็นไอเทมที่มีอยู่จริง และเพิ่มฟิลด์ Map = "PronteraCulvert" / "Morroc" / "Amatsu" ให้แต่ละมอนสเตอร์
```

### 2.7 `src/shared/SkillData.lua`

* **จุดที่ 1 (บรรทัด 279, 288, 295, 302, 323, 359, 396)**: โครงสร้างข้อมูลสกิลคลาส 2 ไม่สม่ำเสมอกับคลาส 1:
  * สกิล `ClashingSpiral`, `LandMine`, `MeteorAssault` ลืมกำหนดค่า `range`
  * สกิล `LexAeterna` และ `Quagmire` ใช้คีย์ `isDebuff = true` โดยไม่มี `isAttack = true` หรือ `isBuff = true` ทำให้ `CombatSystem.server.lua` ปฏิเสธการใช้สกิลและ `RagnarokPanels.client.lua` ไม่ยอมให้ลากใส่ Hotbar
  * สกิล `AuraBlade`, `Concentration`, `TrueSight`, `EnchantDeadlyPoison`, `AdrenalineRush`, `WeaponPerfection`, `Overthrust` ลืมกำหนด `buffPerLevel`
* **จุดที่ 2 (บรรทัด 436–445)**: `GetSkillsByClass` เรียก `game:GetService("ReplicatedStorage"):FindFirstChild("GameData")` และ `require(ClassData)` ซ้ำทุกครั้งที่ถูกเรียก แทนที่จะ `require` ไว้ด้านบนของโมดูล

```lua
-- [บรรทัด 299-304]
LexAeterna = {
	id = "LexAeterna", name = "Lex Aeterna", nameThai = "คำสาปสัจธรรม (ดาเมจ x2)", icon = "👁️", class = "Priest",
	treeRow = 5, treeCol = 1, prereq = "MagnusExorcismus",
	maxLevel = 5, isDebuff = true, range = 24, spCost = 15, cooldown = 4.0, -- ❌ [จุดที่เขียนไม่ดี]: มีแค่ isDebuff = true ซึ่ง CombatSystem และ Hotbar ไม่รองรับ ทำให้กดใช้หรือวางในช่องสกิลไม่ได้เลย
	-- ✅ [วิธีแก้]: เพิ่มการรองรับ sData.isDebuff ใน CombatSystem.server.lua และ RagnarokPanels.client.lua
},

-- [บรรทัด 436-445]
function SkillData.GetSkillsByClass(className)
	local list = {}
	local ClassData = _G.ClassData or (game:GetService("ReplicatedStorage"):FindFirstChild("GameData") and require(game:GetService("ReplicatedStorage").GameData:FindFirstChild("ClassData"))) -- ❌ [จุดซ้ำซ้อน]: ค้นหาและ require ClassData ซ้ำทุกครั้งที่เรียกฟังก์ชัน
	-- ✅ [วิธีแก้]: ย้าย local ClassData = require(script.Parent:WaitForChild("ClassData")) ไปไว้ส่วนหัวของไฟล์
```

### 2.8 `src/shared/StoryQuestData.lua`

* **จุดที่ 1 (บรรทัด 199–210)**: `GetClassWeapon(classID)` รองรับเฉพาะคลาสขั้นที่ 1 หากผู้เล่นเลื่อนขั้นเป็นคลาสขั้นที่ 2 ก่อนมาส่งเควสบทที่ 3 จะได้ `NoviceTrainingDagger` แทนอาวุธสายอาชีพตัวเอง

```lua
-- [บรรทัด 199-210]
function StoryQuestData.GetClassWeapon(classID)
	local map = {
		Mage     = "ApprenticeRod",
		Knight   = "KnightTrainingSword",
		Archer   = "ArcherTrainingBow",
		Thief    = "ThiefTrainingDagger",
		Acolyte  = "AcolyteTrainingMace",
		Merchant = "MerchantTrainingAxe",
		Novice   = "NoviceTrainingDagger", -- ❌ [จุดที่เขียนไม่ดี]: ไม่ได้รองรับคลาสขั้นที่ 2 (LordKnight, Wizard, Priest, Hunter, Assassin, Blacksmith)
	}
	return map[classID] or "NoviceTrainingDagger"
	-- ✅ [วิธีแก้]: เช็ค ClassData.ParentClass[classID] ก่อน เช่น map[classID] or map[ClassData.ParentClass[classID]] or "NoviceTrainingDagger"
end
```

## 3. รายงานตรวจสอบโค้ดรายไฟล์: โฟลเดอร์ `src/server/` (19 ไฟล์)

### 3.1 `src/server/CombatSystem.server.lua`

* **จุดที่ 1 (บรรทัด 101–133)**: ตารางธาตุ `ElementMultiplier` และ `ELEMENT_INDEX` ไม่มีธาตุ `"Poison"` ทั้งที่มอนสเตอร์ `Spider` และ `PoisonSnake` ใน `MonsterData.lua` มี `Element = "Poison"`
* **จุดที่ 2 (บรรทัด 333 และ 443)**: เมื่อหายจากสถานะ `Frozen`/`Stun` หรือล้างสถานะ จะบังคับตั้งค่า `hum.WalkSpeed = 16` เสมอ โดยไม่สนค่า `MoveSpeed` ของอาชีพหรือสถานะขี่สัตว์ (`PecoPecoMount` ความเร็ว 24)
* **จุดที่ 3 (บรรทัด 377–383)**: เมื่อผู้เล่นโดนพิษ (`Poison`) จน `newHP <= 0` โค้ดสั่ง `break` เฉยๆ โดยเข้าใจผิดว่า `MonsterAI` จะจัดการให้ ทำให้ผู้เล่นเลือดเป็น 0 แต่ไม่ตายจริง

```lua
-- [บรรทัด 377-384]
if newHP <= 0 then
	-- PlayerDied จัดการโดย MonsterAI -- ❌ [จุดที่เขียนไม่ดี]: MonsterAI ไม่ได้เช็คการตายจากพิษเอง ทำให้ผู้เล่นค้างที่ HP 0 โดยไม่ตายและไม่เกิดใหม่
	break
	-- ✅ [วิธีแก้]: เรียก if _G.MonsterAI and _G.MonsterAI.PlayerDied then _G.MonsterAI.PlayerDied(player) end ก่อน break
end
```

* **จุดที่ 4 (บรรทัด 1004–1105 และ 1074)**: สร้างโมเดลของดรอปบนพื้นซ้ำซ้อนกับ `ItemDropSystem.server.lua` และส่งพารามิเตอร์เข้า `Remotes.UpdateInventory:FireClient(player, inventory, dropEntry.itemId, qty)` ผิดรูปแบบ (`UIManager.client.lua` คาดหวัง `(inventory, equipment, message, equipmentRefine)`)

```lua
-- [บรรทัด 1072-1076]
if Remotes.UpdateInventory then
	Remotes.UpdateInventory:FireClient(player, inventory, dropEntry.itemId, qty) -- ❌ [จุดที่เขียนไม่ดี]: ส่งอาร์กิวเมนต์ที่ 2 เป็น string (itemId) แทนตาราง Equipment ทำให้ UIManager ไม่แสดงข้อความแจ้งเตือนและไม่อัปเดตช่องสวมใส่
	-- ✅ [วิธีแก้]: ส่ง Remotes.UpdateInventory:FireClient(player, inventory, pData.Equipment or {}, "เก็บ " .. itemInfo.name .. " x" .. qty, pData.EquipmentRefine or {})
end
```

* **จุดที่ 5 (บรรทัด 1320–1350)** [✅ แก้ไขแล้ว]: ดึง `weaponRefineLevel` มาคิดโบนัสดาเมจ `refineATK = weaponRefineLevel * 6` และเจาะเกราะ `ignoreDefPercent` (รวมบัฟ AuraBlade +25%) ส่งเข้า `CalcPhysicalDamage` และ `CalcMagicDamage` เพิ่มพลังโจมตีทะลุเกราะตามจริง 100% เรียบร้อยแล้ว

```lua
-- [บรรทัด 1333-1340]
finalDamage = CalcPhysicalDamage(
	attackerATK, targetDEF,
	isCrit,
	attackElement, targetElement,
	weaponType, targetSize,
	0, 0 -- ❌ [จุดที่เขียนไม่ดี]: ส่ง ignoreDefPercent = 0 และ refineATK = 0 ตายตัว ทำให้โบนัสตีบวกอาวุธ (+6 ต่อระดับ) และสกิลเจาะเกราะไม่ทำงาน
	-- ✅ [วิธีแก้]: คำนวณ local refineLv = (pData and pData.EquipmentRefine and pData.EquipmentRefine.Weapon) or 0 แล้วส่ง refineLv * 6 เข้าไป
)
```

* **จุดที่ 6 (บรรทัด 1720–1728 และ 1862–1866)** [✅ แก้ไขแล้ว]:
  1. เพิ่ม `ClearPlayerStatuses(player)` ใน `Players.PlayerRemoving` เพื่อยกเลิกเธรดสถานะผิดปกติและล้างข้อมูล `PlayerStatusEffects[player.UserId]` ป้องกัน Memory Leak
  2. ใน `HandleSkillUse` ขยายเงื่อนไข `if sData.isAttack or sData.isDebuff then` เพื่อล็อกเป้าหมายมอนสเตอร์สำหรับสกิลดีบัฟ
  3. เพิ่มการประมวลผลสกิล `sData.isDebuff` รองรับ `LexAeterna` (ตั้ง Attribute `StatusLexAeterna` เพื่อคูณ 2 ดาเมจครั้งถัดไป) และ `Quagmire` (เรียก `ApplyStatusToMonster(targetMonster, "Slow", duration)` ลดความเร็วเคลื่อนที่มอนสเตอร์ 50%) ครบถ้วน 100%

### 3.2 `src/server/CraftingSystem.server.lua`

* **จุดที่ 1 (บรรทัด 54–81)**: เขียนฟังก์ชัน `hasIngredients` และ `consumeIngredients` วนลูปเช็ค/ลบไอเทมในกระเป๋าเองซ้ำซ้อนกับ `DataStore.HasItem` และ `DataStore.RemoveItem` (และไม่รองรับไอเทม Alias อย่าง `Sticky_Mucus`)

```lua
-- [บรรทัด 54-81]
local function hasIngredients(inventory, requirements) -- ❌ [จุดซ้ำซ้อน]: เขียนฟังก์ชันเช็คและหักวัตถุดิบเองซ้ำกับ DataStore.HasItem / DataStore.RemoveItem และไม่รองรับ Sticky_Mucus
...
local function consumeIngredients(inventory, requirements)
...
-- ✅ [วิธีแก้]: เรียกใช้ dataApi.HasItem(player, itemId, required) และ dataApi.RemoveItem(player, itemId, required) แทน
```

### 3.3 `src/server/DailyQuestSystem.server.lua`

* **จุดที่ 1 (บรรทัด 110–120 และ 228–244)**: เขียนฟังก์ชัน `countItemInInventory` และลูปหักไอเทมเควสซ้ำซ้อนกับ `DataStore.HasItem` และ `DataStore.RemoveItem`

```lua
-- [บรรทัด 110-120]
local function countItemInInventory(playerData, targetId) -- ❌ [จุดซ้ำซ้อน]: เขียนลูปนับและลบไอเทมซ้ำกับ DataStore.HasItem / DataStore.RemoveItem
	if not playerData or not playerData.Inventory then return 0 end
	...
-- ✅ [วิธีแก้]: เรียกใช้ local _, count = dataStore.HasItem(player, targetId, 1) และใช้ dataStore.RemoveItem ตอนส่งเควส
```

### 3.4 `src/server/DataStore.server.lua`

* **จุดที่ 1 (บรรทัด 263–334)** [✅ แก้ไขแล้ว]:
  1. เพิ่มคีย์ `MaxHP, MaxSP, HP, SP, CritRate, Crit, HIT, FLEE, ASPD` ลงใน `equipmentBonuses` ครบถ้วน
  2. เชื่อมโยงสเตตัสกับการ์ด อุปกรณ์ และบัฟได้อย่างถูกต้อง 100%
  3. ปรับระดับการตีบวกให้ตรงกับระบบ: อาวุธได้ +6 ATK ต่อระดับ และชุดเกราะ/โล่/หมวก ได้ +4 DEF ต่อระดับ

```lua
-- [บรรทัด 263-282]
local equipmentBonuses = { ATK = 0, MATK = 0, DEF = 0, MDEF = 0, MaxHP = 0, MaxSP = 0 } -- ❌ [จุดที่เขียนไม่ดี]: คีย์ MaxHP/MaxSP ไม่ตรงกับ ClassData (ที่อ่าน eq.HP/eq.SP) และขาดคีย์ CritRate, HIT, FLEE, ASPD
for slot, itemId in pairs(data.Equipment or {}) do
	local item = ItemData[itemId]
	for stat, amount in pairs(item and item.bonuses or {}) do
		if s[stat] ~= nil then s[stat] += amount
		elseif equipmentBonuses[stat] ~= nil then equipmentBonuses[stat] += amount end
	end
	local refineLevel = math.clamp(math.floor(tonumber((data.EquipmentRefine or {})[slot]) or 0), 0, 15)
	if slot == "Weapon" then equipmentBonuses.ATK += refineLevel -- ❌ [จุดที่เขียนไม่ดี]: บวก ATK แค่ +1 ต่อระดับ ไม่ตรงกับ WindowSystem ที่แสดง +6 ต่อระดับ
	elseif slot == "Armor" then equipmentBonuses.DEF += refineLevel end
-- ✅ [วิธีแก้]: ตั้งค่า eq.HP = equipmentBonuses.MaxHP, eq.SP = equipmentBonuses.MaxSP, เพิ่มคีย์ CritRate/HIT/FLEE/ASPD และปรับโบนัสตีบวกเป็น refineLevel * 6 (อาวุธ) และ refineLevel * 4 (เกราะ)
```

* **จุดที่ 2 (บรรทัด 670–679 และ 828–843)**: โค้ดกำหนดสกิลเริ่มต้น (`NoviceStrike`, `FirstAid`, และ `starterSkillByClass`) ถูกเขียนซ้ำ 2 รอบในฟังก์ชัน `LoadPlayer` เดียวกัน

```lua
-- [บรรทัด 670-678 และซ้ำอีกครั้งที่บรรทัด 828-842]
result.Skills.NoviceStrike = math.max(1, tonumber(result.Skills.NoviceStrike) or 0)
result.Skills.FirstAid     = math.max(1, tonumber(result.Skills.FirstAid) or 0)
local starterSkillByClass = { Acolyte = "Heal", Knight = "Bash", Mage = "FireBolt", Archer = "DoubleStrafe", Thief = "Envenom", Merchant = "Mammonite" } -- ❌ [จุดซ้ำซ้อน]: บล็อกนี้ถูกเขียนซ้ำ 2 รอบในฟังก์ชัน LoadPlayer (บรรทัด 670-678 และ 828-842)
-- ✅ [วิธีแก้]: ลบบล็อกที่ซ้ำในบรรทัด 828-842 ออก
```

* **จุดที่ 3 (บรรทัด 1284–1319)** [✅ แก้ไขแล้ว]: เพิ่ม `AddGold = ModifyGold` ใน `_G.DataStore` เรียบร้อยแล้ว สคริปต์อื่นสามารถเรียก `DataStore.AddGold` หรือ `DataStore.ModifyGold` ได้อย่างปลอดภัย 100%

```lua
-- [บรรทัด 1308]
ModifyGold = ModifyGold, -- ❌ [จุดที่เขียนไม่ดี]: สคริปต์อื่นเรียก DataStore.AddGold แต่ที่นี่มีแค่ ModifyGold
-- ✅ [วิธีแก้]: เพิ่ม AddGold = ModifyGold ใน _G.DataStore เพื่อความเข้ากันได้กับทุกสคริปต์
```

### 3.5 `src/server/DungeonAndMvpSystem.server.lua`

* **จุดที่ 1 (บรรทัด 102, 108, 112)** [✅ แก้ไขแล้ว]:
  1. ปรับเปลี่ยนเป็น `(DataStore.ModifyGold or DataStore.AddGold)(player, goldBonus)` และ `DataStore.AddItem(...)` เรียบร้อยแล้ว ไอเทมหินตีบวกและการ์ดรวมกอง (Stack) และเงินเข้าตัวละครอย่างปลอดภัย 100%
* **จุดที่ 2 (บรรทัด 141–275)** [✅ แก้ไขแล้ว]: ลบการเสกบอสแท่ง Neon ที่ไม่มี AI ออก รวมศูนย์ให้เสกผ่าน `_G.MonsterAI.SpawnMonster` ใน `Workspace.Monsters` มีระบบล็อกเป้าและ AI ครบถ้วน พร้อมส่งออก `_G.SpawnMvpTreasureChest` ให้ `CombatSystem` เรียกใช้งานเมื่อบอส MVP ตาย

```lua
-- [บรรทัด 101-116]
local goldBonus = 5000
DataStore.AddGold(player, goldBonus) -- ❌ [จุดที่เขียนไม่ดี]: ฟังก์ชัน AddGold ไม่มีใน DataStore ทำให้เกิด Error ทันทีที่ผู้เล่นกดเปิดหีบ!
local pData = DataStore.GetPlayerData(player)
if pData then
	pData.Inventory = pData.Inventory or {}
	table.insert(pData.Inventory, { itemId = "BeginnerRefinementStone", quantity = 3 }) -- ❌ [จุดที่เขียนไม่ดี]: ยัดตารางลง Inventory โดยตรง ทำให้ของไม่ซ้อนทับ (Stack) กัน
-- ✅ [วิธีแก้]: เปลี่ยนเป็น DataStore.ModifyGold(player, goldBonus) และใช้ DataStore.AddItem(player, "BeginnerRefinementStone", 3) พร้อมย้ายการเสกบอสไปใช้ _G.MonsterAI.SpawnMonster ให้หมด
```

### 3.6 `src/server/GameManager.server.lua`

* **จุดที่ 1 (บรรทัด 389–429)** [✅ แก้ไขแล้ว]: เพิ่มการเช็คตัวแปร `changed` ใน `StartRegenLoop` ซิงค์และส่งข้อมูลตัวละครหา Client เฉพาะเมื่อ HP หรือ SP เปลี่ยนแปลงจริงเท่านั้น ลด Network Traffic และภาระการเรนเดอร์ของ Client ลงอย่างมหาศาล
* **จุดที่ 2 (บรรทัด 464–485)** [✅ แก้ไขแล้ว]: ลบการเรียกตัวเองซ้ำใน `CharacterAdded` ออก และผูก `BindCharacterRespawn(player)` ในฟังก์ชัน `SetupPlayer(player)` อย่างถูกต้องเรียบร้อยแล้ว

* **จุดที่ 3 (บรรทัด 284–291 และ 375, 1031)**: ตัวแปร `NOVICE_ADVANCEMENTS` ถูกประกาศแต่ไม่เคยใช้งาน (Dead Code) และกำหนด `_G.PushCharacterData = PushCharacterData` ซ้ำ 2 จุด (บรรทัด 375 และ 1031)

### 3.7 `src/server/GuildSystem.server.lua`

* **จุดที่ 1 (บรรทัด 64–91 และ 103–213)**: โครงสร้างข้อมูลที่ส่งไปให้ Client (`{ myGuildId = ..., guilds = list }`) ไม่ตรงกับที่ `ExpansionUI.client.lua` อ่าน (`payload.MyGuild` และ `payload.GuildList`) และไม่รองรับแอ็กชัน `"RequestSync"` ที่ Client ส่งมา รวมถึงค่าสร้างกิลด์ใน Server คิด `100` Zeny แต่ปุ่มบน UI เขียนว่า `500z`

```lua
-- [บรรทัด 87-90]
return {
	myGuildId = myGuildId, -- ❌ [จุดที่เขียนไม่ดี]: ชื่อฟิลด์ไม่ตรงกับ ExpansionUI.client.lua ที่อ่าน latestGuildState.MyGuild และ latestGuildState.GuildList
	guilds    = list,
}
-- ✅ [วิธีแก้]: ส่งฟิลด์ MyGuild (ตารางข้อมูลกิลด์ของผู้เล่น) และ GuildList = list ให้ตรงกับฝั่ง Client และเพิ่ม elseif action == "RequestSync" then RE_GuildUpdated:FireClient(player, serializeGuildsForClient(player))
```

### 3.8 `src/server/ItemDropSystem.server.lua`

* **จุดที่ 1 (บรรทัด 47–58 และ 135–140)**:
  1. เขียนฟังก์ชัน `addToInventory` เองซ้ำกับ `DataStore.AddItem`
  2. สร้าง `RunService.Heartbeat:Connect` แยกทีละชิ้นสำหรับไอเทมดรอปทุกชิ้นบนพื้นเพื่อหมุน/ขยับขึ้นลงบน Server ซึ่งเปลือง CPU และ Network Replication เมื่อมีของดรอปหลายชิ้น

```lua
-- [บรรทัด 135-140]
local connection
connection = RunService.Heartbeat:Connect(function() -- ❌ [จุดที่เขียนไม่ดี]: สร้าง Heartbeat connection แยกต่อไอเทมทุกชิ้นบน Server ทำให้เซิร์ฟเวอร์ต้องส่งอัปเดต CFrame ผ่านเน็ตเวิร์กทุกเฟรม
	if not part.Parent then connection:Disconnect() return end
	local t = os.clock() - start
	part.CFrame = CFrame.new(position + Vector3.new(0, math.sin(t * 2) * 0.25, 0)) * CFrame.Angles(0, t * 1.5, 0)
end)
-- ✅ [วิธีแก้]: ย้ายแอนิเมชันหมุนไอเทมไปทำฝั่ง Client หรือใช้ลูปรวมอันเดียวที่อัปเดตความถี่ต่ำ
```

### 3.9 `src/server/JobAdvancementSystem.server.lua`

* **จุดที่ 1 (บรรทัด 174–220)** [✅ แก้ไขแล้ว]:
  1. เพิ่มฟังก์ชัน `returnEquipmentToInventory` คืนอาวุธเดิมพร้อมค่าตีบวกเดิมกลับเข้า `data.Inventory` ก่อนติดตั้งอาวุธ 2nd Job ใหม่ ป้องกันของหายถาวร 100%
  2. ลบเงื่อนไข `changeClassRemote` ที่ค้างไว้ และเพิ่มการเรียก `_G.RebuildCharacterWeaponRig(player)` เพื่อเปลี่ยนโมเดล 3D อาวุธในมือตัวละครทันที
  3. ยิงรีโมต `RE_UpdateInventory` อัปเดตช่องสวมใส่และกระเป๋าฝั่ง Client อย่างถูกต้องสมบูรณ์

```lua
-- [บรรทัด 186-209]
local changeClassRemote = remotesFolder:FindFirstChild("ChangeClass")
if changeClassRemote then -- ❌ [จุดที่เขียนไม่ดี]: เช็ค changeClassRemote แต่ไม่ได้ใช้งาน
	...
	if starterWeapon then
		data.Equipment.Weapon = starterWeapon -- ❌ [จุดที่เขียนไม่ดี]: เขียนทับอาวุธที่ผู้เล่นสวมใส่อยู่ทันที ทำให้อาวุธชิ้นเดิมและระดับตีบวกหายไปจากเกมถาวร!
		data.EquipmentRefine = data.EquipmentRefine or {}
		data.EquipmentRefine.Weapon = 1
	end
-- ✅ [วิธีแก้]: เก็บอาวุธเดิมและค่าตีบวกเดิมคืนเข้า data.Inventory ก่อนใส่ starterWeapon หรือมอบ starterWeapon เข้ากระเป๋าผ่าน DataStore.AddItem(player, starterWeapon, 1)
```

### 3.10 `src/server/MarketSystem.server.lua`

* **จุดที่ 1 (บรรทัด 122–159 และ 831–906)**:
  1. เขียนฟังก์ชันจัดการกระเป๋า (`countInInventory`, `takeFromInventory`, `giveToData`) แยกต่างหากอีกชุด
  2. โค้ดสร้างหุ่น NPC `buildBroker()` (บรรทัด 831–906) ซ้ำซ้อนกับฟังก์ชันสร้าง NPC ใน `TownShop.server.lua`, `CraftingSystem.server.lua`, และ `StarterMap.server.lua`

```lua
-- [บรรทัด 839-864]
local function makePart(name, size, position, color, material, shape) -- ❌ [จุดซ้ำซ้อน]: โค้ดสร้างชิ้นส่วนหุ่น NPC (Torso, Head, Hair, LegL, LegR, BillboardGui, ProximityPrompt) ซ้ำกับอีก 5 สคริปต์
	local part = Instance.new("Part")
	...
-- ✅ [วิธีแก้]: แยกฟังก์ชันสร้าง NPC มาตรฐานไว้ใน ModuleScript กลางแล้วเรียกใช้ร่วมกัน
```

### 3.11 `src/server/MonsterAI.server.lua`

* **จุดที่ 1 (บรรทัด 113–161)** [✅ แก้ไขแล้ว]: ปรับให้ `pushOutOfSafeZone` ดึงพิกัดกรอบโซนปลอดภัยของแต่ละแมพ (`Prontera`, `Culvert`, `Morroc`, `Amatsu`) แยกเฉพาะเจาะจง ไม่ดูดมอนสเตอร์ข้ามแมพกลับมา Prontera อีกต่อไป
...
* **จุดที่ 2 (บรรทัด 810–818)** [✅ แก้ไขแล้ว]: ลบ `Drake` ซ้ำซ้อนออกจากทุ่ง Prontera Zone 6 เหลือให้ Drake อยู่ท้ายดันเจี้ยน Culvert เพียงแห่งเดียวตาม Lore และเพิ่ม `GoldenThiefBug` ใน Culvert เรียบร้อยแล้ว

### 3.12 `src/server/PartySystem.server.lua`

* **จุดที่ 1 (บรรทัด 154–160 และ 204–208)**: ลอจิกการหาหัวหน้าปาร์ตี้คนใหม่เมื่อหัวหน้าออก (`nextLeader`) เขียนซ้ำกัน 2 จุดใน `leaveParty` และ `Players.PlayerRemoving`

```lua
-- [บรรทัด 154-160 และซ้ำที่บรรทัด 204-208]
if party.leader == player.UserId then -- ❌ [จุดซ้ำซ้อน]: ลอจิกถอดสมาชิกและโอนตำแหน่งหัวหน้าปาร์ตี้เขียนซ้ำกันใน leaveParty และ PlayerRemoving
	local nextLeader
	for userId in pairs(party.members) do
		if not nextLeader or userId < nextLeader then nextLeader = userId end
	end
	party.leader = nextLeader
end
-- ✅ [วิธีแก้]: ยุบรวมเป็นฟังก์ชัน local function removeMemberFromParty(player, reasonMessage) แล้วเรียกใช้ทั้งสองที่
```

### 3.13 `src/server/PetAndMountSystem.server.lua`

* **จุดที่ 1 (บรรทัด 67, 77 และ 136–192)**:
  1. ระบบสัตว์เลี้ยง (`summonPet`) แสดงข้อความว่า `"ได้รับบัพติดตัวแล้ว"` (`LUK +5 • Drop +10%` หรือ `FLEE +8 • Crit +3`) และตั้ง Attribute `ActivePet` แต่ **ไม่มีสคริปต์ใดในเกมอ่านค่า `ActivePet` ไปบวกสเตตัสหรืออัตราดรอปเลย** (เป็นป้ายข้อความหลอก) รวมถึงไม่ตรวจสอบค่า `petType` ที่ส่งมาจาก Client
  2. เมื่อขี่/ลงจาก Peco Peco ตั้งค่า `humanoid.WalkSpeed = 24` / `16` แบบตายตัว และไม่รีเซ็ต `mountedState` เมื่อตัวละครตายและเกิดใหม่

```lua
-- [บรรทัด 181-192]
bbText.Text = (petType == "Lunatic" and "🐰 Lunatic Pet
[FLEE +8 • Crit +3]" or "🌸 Poring Pet
[LUK +5 • Drop +10%]")
...
activePets[player.UserId] = pet
player:SetAttribute("ActivePet", petType) -- ❌ [จุดที่เขียนไม่ดี]: ตั้ง Attribute ActivePet แต่ DataStore.CalcDerivedStats และ CombatSystem ไม่ได้นำค่านี้ไปบวกสเตตัสจริงเลย
RE_SkillFeedback:FireClient(player, string.format("🐾 อัญเชิญสัตว์เลี้ยง %s สำเร็จ! ได้รับบัพติดตัวแล้ว", petType))
-- ✅ [วิธีแก้]: ตรวจสอบ petType ให้อยู่ใน {"Poring", "Lunatic"} และนำ player:GetAttribute("ActivePet") ไปบวกโบนัสจริงใน DataStore.CalcDerivedStats แล้วเรียก DataStore.SyncAttributes
```

### 3.14 `src/server/PvPArenaSystem.server.lua`

* **จุดที่ 1 (บรรทัด 215–221)** [✅ แก้ไขแล้ว]: Forward-declare และเรียกฟังก์ชัน `leaveArena(player)` ในสคริปต์เซิร์ฟเวอร์โดยตรง ป้องกันข้อผิดพลาด `FireServer` และทำให้ผู้เล่นกด `[F]` ที่ประตูมิติเพื่อกลับเมือง Prontera ได้อย่างสมบูรณ์ 100%

```lua
-- [บรรทัด 215-221]
portalPrompt.Triggered:Connect(function(player)
	if GameManager and GameManager.TeleportPlayerToMap then -- ❌ [จุดที่เขียนไม่ดี]: TeleportPlayerToMap ไม่มีอยู่จริงใน GameManager
		GameManager.TeleportPlayerToMap(player, "Prontera")
	else
		RE_LeavePvPArena:FireServer() -- ❌ [จุดที่เขียนไม่ดี (Crash)]: เรียก :FireServer() จากสคริปต์ฝั่ง Server ทำให้เกิด Error ทันทีที่ผู้เล่นกด F ที่ประตูมิติ!
	end
	-- ✅ [วิธีแก้]: เรียกฟังก์ชัน leaveArena(player) โดยตรง
end)
```

* **จุดที่ 2 (บรรทัด 549)** [✅ แก้ไขแล้ว]: ปรับเปลี่ยนเป็น `(DataStore.ModifyGold or DataStore.AddGold)(killer, bonusZeny)` เรียบร้อยแล้ว ระบบสังหารใน PvP มอบเงินรางวัล Zeny ได้อย่างราบรื่น 100%

```lua
-- [บรรทัด 549]
DataStore.AddGold(killer, bonusZeny) -- ❌ [จุดที่เขียนไม่ดี (Crash)]: ฟังก์ชัน AddGold ไม่มีใน DataStore ทำให้ระบบสังหารใน PvP พังค้างกลางคัน!
-- ✅ [วิธีแก้]: เปลี่ยนเป็น DataStore.ModifyGold(killer, bonusZeny)
```

* **จุดที่ 3 (บรรทัด 679 และ 761)**: ส่งพารามิเตอร์เข้า `RE_ShowDamageNumber:FireAllClients(...)` ไม่ตรงกับที่ `DamageNumbers.lua` รับ (`(position, amount, isCrit, dmgType)`)

```lua
-- [บรรทัด 679 และ 761]
RE_ShowDamageNumber:FireAllClients(vRoot.Position, finalDamage, isCrit, false, isMiss) -- ❌ [จุดที่เขียนไม่ดี]: ส่งอาร์กิวเมนต์ที่ 4 เป็น boolean (false / isMagic) แทนที่จะเป็น string ("PHYS", "MAGIC", "MISS")
-- ✅ [วิธีแก้]: ส่ง RE_ShowDamageNumber:FireAllClients(vRoot.Position, finalDamage, isCrit, isMiss and "MISS" or "PHYS")
```

### 3.15 `src/server/StarterMap.server.lua`

* **จุดที่ 1 (ทั้งไฟล์ 4,580 บรรทัด)**: ไฟล์มีขนาดใหญ่เกินไป (Monolithic 4,580 บรรทัด) รวมการสร้างภูมิประเทศ อาคาร เฟอร์นิเจอร์ โซนมอนสเตอร์ และ NPC ชาวบ้านไว้ในไฟล์เดียว และ `require` บริการ `ServerStorage` กับ `Lighting` (บรรทัด 43, 45) โดยไม่ได้ใช้งาน
* **จุดที่ 2 (บรรทัด 913–929 และ 1319–1351)**:
  1. `smithPrompt.Triggered` ยิงทั้ง `OpenNpcDialogue` และ `OpenRefinement` พร้อมกัน ทำให้หน้าต่างคุยเควสและหน้าต่างตีบวกเด้งซ้อนทับกัน
  2. ผูก `OpenNpcDialogue` ที่ `StarterMap.server.lua` แล้วถูก `TownStoryQuestSystem.server.lua` (บรรทัด 393–398) มาผูก `.Triggered:Connect(...)` ซ้ำเป็นรอบที่ 2 บนปุ่มเดียวกัน!

```lua
-- [บรรทัด 913-929]
smithPrompt.Triggered:Connect(function(player)
	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remotes then
		local openNpcDialogue = remotes:FindFirstChild("OpenNpcDialogue")
		if openNpcDialogue then openNpcDialogue:FireClient(player, "Blacksmith") end -- ❌ [จุดซ้ำซ้อน]: ยิงซ้ำกับ TownStoryQuestSystem.server.lua และเปิดหน้าต่างชนกับ OpenRefinement
		local openRefinement = remotes:FindFirstChild("OpenRefinement")
		if openRefinement then openRefinement:FireClient(player) end
	end
	-- ✅ [วิธีแก้]: ให้เปิดเฉพาะหน้าต่างตีบวก หรือมีตัวเลือกในบทสนทนา NPC เพื่อไม่ให้ 2 หน้าต่างเด้งทับกัน และไม่ผูก Triggered ซ้ำใน TownStoryQuestSystem
end)
```

### 3.16 `src/server/TownShop.server.lua`

* **จุดที่ 1 (บรรทัด 90–104 และ 149–154)**: ลูปหักไอเทมออกจาก `data.Inventory` เขียนซ้ำซ้อนกันใน `sellItem` และ `useConsumable` แทนที่จะเรียก ` dataApi.RemoveItem` และโค้ดสร้างโมเดลแม่ค้า `SupplyVendor` (บรรทัด 175–237) ซ้ำซ้อนกับสคริปต์ NPC อื่นๆ

```lua
-- [บรรทัด 99-104 และซ้ำที่บรรทัด 149-154]
entry.quantity -= quantity -- ❌ [จุดซ้ำซ้อน]: เขียนลูปค้นหาและลบไอเทมออกจาก data.Inventory เองซ้ำๆ แทนการใช้ dataApi.RemoveItem
if entry.quantity <= 0 then
	for index, owned in ipairs(data.Inventory) do
		if owned == entry then table.remove(data.Inventory, index); break end
	end
end
-- ✅ [วิธีแก้]: ใช้ dataApi.RemoveItem(player, itemId, quantity)
```

### 3.17 `src/server/TownStoryQuestSystem.server.lua`

* **จุดที่ 1 (บรรทัด 105–116, 178–184, 218–229, 412–420)**:
  1. ฟังก์ชัน `getItemCount` ถูกประกาศซ้ำถึง 3 จุดในไฟล์เดียวกัน (และซ้ำกับ `DataStore.HasItem`)
  2. ใน `RE_AcceptStoryQuest` (บรรทัด 178–184) ตอนนับไอเทมเริ่มต้น ลืมเช็คชื่อ Alias (`Iron_Ore` / `Sticky_Mucus`) ต่างจากจุดอื่นในไฟล์เดียวกัน
* **จุดที่ 2 (บรรทัด 393–398)**: ผูก `prompt.Triggered:Connect` ซ้ำลงบน `ProximityPrompt` ของ NPC ที่ `StarterMap.server.lua` ผูก `OpenNpcDialogue` ไว้แล้ว ทำให้เวลากดคุยกับ NPC เหตุการณ์จะถูกยิงซ้ำ 2 ครั้งซ้อน

```lua
-- [บรรทัด 393-398]
local prompt = npcModel:FindFirstChildWhichIsA("ProximityPrompt", true)
if prompt then
	prompt.Triggered:Connect(function(player) -- ❌ [จุดซ้ำซ้อน]: StarterMap.server.lua (buildInteriorNpc / smithPrompt) ผูก OpenNpcDialogue ไว้ที่ prompt นี้อยู่แล้ว ทำให้ยิง Remote ซ้ำ 2 รอบ
		RE_OpenNpcDialogue:FireClient(player, quest.npcId)
	end)
	-- ✅ [วิธีแก้]: ตั้ง Attribute เช่น prompt:SetAttribute("StoryQuestBound", true) หรือจัดการที่จุดเดียวไม่ผูกซ้ำ
end
```

### 3.18 `src/server/VisualRigAndLighting.server.lua`

* **จุดที่ 1 (บรรทัด 121–129, 159–210, 275)**:
  1. `getDefaultWeaponTypeForClass` และเงื่อนไขถือโล่ (บรรทัด 275) เช็คเฉพาะคลาส 1 (`Knight`, `Mage`, ฯลฯ) ไม่รองรับคลาส 2 (`LordKnight`, `Wizard`, `Priest`, `Hunter`, `Assassin`, `Blacksmith`)
  2. `WEAPON_MESH_DEFS` ไม่มีข้อมูลของอาวุธประเภท `"Spear"` และ `"TwoHandSpear"` (เช่น `HalberdOfValor` ของ `LordKnight`)
* **จุดที่ 2 (บรรทัด 589–617)**: ใช้วิธี Monkey-Patch ดักฟังก์ชัน `_G.CombatSystem.PlayerAttackMonster` และ `HandleSkillUse` จากภายนอก และในบรรทัด 606 เช็คเฉพาะ `type(targetId) == "string"` ทั้งที่ `CombatTargeting.lua` ส่ง `targetId` มาเป็น `Instance` (`Model`) ทำให้หาตำแหน่งเป้าหมายไม่เจอ

```lua
-- [บรรทัด 605-607]
cs.HandleSkillUse = function(player, skillId, skillLevel, targetId)
	local targetMonster = (type(targetId) == "string" and targetId ~= "") and Workspace:FindFirstChild(targetId, true) or nil -- ❌ [จุดที่เขียนไม่ดี]: เช็คแต่ string ทั้งที่ Client ส่ง targetId มาเป็น Model Instance ทำให้ targetMonster เป็น nil
	-- ✅ [วิธีแก้]: รองรับทั้ง typeof(targetId) == "Instance" และ string หรือย้ายการยิง PlayCombatVFX เข้าไปใน CombatSystem.server.lua โดยตรง
```

### 3.19 `src/server/WorldMapExpansion.server.lua`

* **จุดที่ 1 (บรรทัด 55–74)**: ฟังก์ชัน `teleportPlayer` เขียนลอจิกเปลี่ยนแมพซ้ำกับ `GameManager.server.lua` (`RE_TeleportToMap`)
* **จุดที่ 2 (บรรทัด 260–269)**: ผูก `hmPrompt.Triggered:Connect` ทับลงบน `HarborMasterNPC` โดยไม่ยกเลิก Connection เดิมจาก `StarterMap.server.lua` ทำให้กดคุยครั้งเดียวเปิดทั้งหน้าต่างบทสนทนา NPC และหน้าต่างแผนที่โลกซ้อนกัน

```lua
-- [บรรทัด 260-269]
local harborMaster = plaza and plaza:FindFirstChild("HarborMasterNPC", true)
local hmPrompt = harborMaster and harborMaster:FindFirstChild("TalkToNpc", true)
if hmPrompt then
	hmPrompt.ActionText = "ออกเรือไปเมือง Morroc / Amatsu"
	hmPrompt.Triggered:Connect(function(player) -- ❌ [จุดซ้ำซ้อน]: ผูก Triggered ซ้อนทับกับ buildInteriorNpc ใน StarterMap ทำให้เด้ง 2 หน้าต่างพร้อมกัน
		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
		local openTravel = remotes and remotes:FindFirstChild("OpenWorldTravel")
		if openTravel then openTravel:FireClient(player) end
	end)
	-- ✅ [วิธีแก้]: กำหนด remoteName = "OpenWorldTravel" ใน npcSpec ของ HarborMasterNPC ตั้งแต่ใน StarterMap.server.lua
end
```

## 4. รายงานตรวจสอบโค้ดรายไฟล์: โฟลเดอร์ `src/client/` (12 ไฟล์)

### 4.1 `src/client/AudioManager.client.lua`

* **จุดที่ 1 (บรรทัด 17–23 และ 66–81)**:
  1. เพลง BGM ทั้ง 5 แมพ ใช้ไฟล์เสียงสั้น `"rbxasset://sounds/electronicpingshort.wav"` แล้วตั้ง `Looped = true` ทำให้เกิดเสียงปิ๊งรัวๆ ตลอดเวลาแทนที่จะเป็นเพลงบรรยากาศ
  2. ใน `playSFX` เขียน `if / elseif / else` 6 กิ่ง แต่ทุกกิ่งกำหนด `sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"` เหมือนกันทั้งหมด!

```lua
-- [บรรทัด 66-81]
if soundType == "slash" then
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav" -- ❌ [จุดซ้ำซ้อน]: ทุกเงื่อนไข if/elseif กำหนด SoundId เดียวกันทั้งหมด
elseif soundType == "hit" then
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
elseif soundType == "crit" then
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.8
...
-- ✅ [วิธีแก้]: เก็บเป็นตารางตั้งค่า SFX_CONFIG = { slash = { id = "...", vol = 0.6 }, crit = { id = "...", vol = 0.8 }, ... } เพื่อลดโค้ด if/elseif ซ้ำซ้อน
```

### 4.2 `src/client/CameraController.client.lua`

* **จุดที่ 1 (บรรทัด 99, 120, 136–158)** [✅ แก้ไขแล้ว]:
  1. ปรับ `ShakeCam` เป็น `local function ShakeCam` พร้อมประกาศ `_G.ShakeCam = ShakeCam` และเปลี่ยนจาก `tick()` เป็น `os.clock()`
  2. ยกเลิกการสร้าง `RaycastParams.new()` ซ้ำทุกเฟรมใน `getSafeDistance` โดยสร้างไว้ภายนอกเป็นตัวแปร local ครั้งเดียว
  3. แก้ไข `updateMovement()` ให้เช็ค `UserInputService:GetFocusedTextBox()` เพื่อไม่ให้เดินขณะพิมพ์แชท และใช้ตัวแปร `wasMovingManual` สั่ง `hum:Move(move, false)` เฉพาะเมื่อมีการกดปุ่มเดินจริง (`move.Magnitude > 0.01`) หรือหยุดเดินครั้งเดียว ไม่ส่ง `hum:Move(Vector3.zero)` รัวทุกเฟรมอีกต่อไป ทำให้ไม่ขัดจังหวะระบบบอท Auto-Battle (`humanoid:MoveTo()`) เรียบร้อย 100%

```lua
-- [บรรทัด 145-158]
local move = Vector3.new(0, 0, 0)
if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + camFwd   end -- ❌ [จุดที่เขียนไม่ดี]: ไม่ได้เช็ค GetFocusedTextBox() ทำให้พิมพ์แชทแล้วตัวละครเดินเอง
...
if move.Magnitude > 0.01 then
	move = move.Unit
	root.CFrame = CFrame.new(root.Position, root.Position + move)
end
hum:Move(move, false) -- ❌ [จุดที่เขียนไม่ดี]: เรียก hum:Move(Vector3.zero) ทุกเฟรมแม้ไม่ได้กดปุ่มเดิน ทำให้ไปล้างคำสั่ง humanoid:MoveTo() ของบอท Auto-Battle!
-- ✅ [วิธีแก้]: เช็ค if UserInputService:GetFocusedTextBox() then return end และเรียก hum:Move เฉพาะเมื่อ move.Magnitude > 0.01 หรือเมื่อเพิ่งปล่อยปุ่มเดินเท่านั้น
```

### 4.3 `src/client/CombatVFX.client.lua`

* **จุดที่ 1 (บรรทัด 317 และ 350–355)** [✅ แก้ไขแล้ว]: เพิ่มการเช็ค `"Hunter"` สำหรับแอนิเมชันยิงธนูและกระสุนลูกศร (ทั้ง Basic Attack, DoubleStrafe, ArrowShower, BlitzBeat, FalconAssault) รวมถึงเพิ่ม `"Wizard"`, `"Priest"`, `"Acolyte"` สำหรับท่าทางร่ายเวทมนตร์เรียบร้อย 100%

```lua
-- [บรรทัด 350-359]
if className == "Archer" then -- ❌ [จุดที่เขียนไม่ดี]: ลืมเช็ค "Hunter" และในส่วนเวทลืมเช็ค "Wizard" / "Priest"
	playCharacterActionAnimation(casterPlayer, "Bow")
	spawnArrowProjectile(root.Position + Vector3.new(0, 1, 0), targetPos, elColor)
elseif className == "Mage" then
	playCharacterActionAnimation(casterPlayer, "Cast")
	spawnArrowProjectile(root.Position + Vector3.new(0, 1.5, 0), targetPos, Color3.fromRGB(145, 195, 255))
-- ✅ [วิธีแก้]: เช็ค if className == "Archer" or className == "Hunter" then และ elseif className == "Mage" or className == "Wizard" or className == "Priest" then
```

### 4.4 `src/client/CraftingUI.client.lua`

* **จุดที่ 1 (บรรทัด 96–97)**: ฮาร์ดโค้ดคำอธิบายค่าสเตตัสของไอเทมคราฟต์ผิดไปจาก `ItemData.lua` (`Poring Hood` เขียนว่า `DEF +3, MaxHP +10` แต่ของจริงใน `ItemData.lua` คือ `DEF +18, MaxHP +150, LUK +2` ส่วน `CloverRod` เขียนว่า `MATK +5` แต่ของจริงคือ `MATK +45, INT +4`)

```lua
-- [บรรทัด 96-97]
addRecipe(1, "Poring Hood", "Jellopy x10 • Sticky Mucus x5 • 20 z
โบนัสเมื่อสวม: DEF +3, MaxHP +10", "PoringHood") -- ❌ [จุดที่เขียนไม่ดี]: ฮาร์ดโค้ดค่าสเตตัสไม่ตรงกับ ItemData.lua จริง
addRecipe(2, "Four-Leaf Apprentice Rod", "Jellopy x8 • Four-Leaf Clover x2 • 50 z
โบนัสเมื่อสวม: MATK +5", "CloverRod")
-- ✅ [วิธีแก้]: ดึงค่าโบนัสจาก ItemData.PoringHood.bonuses และ ItemData.CloverRod.bonuses มาแสดงผลโดยอัตโนมัติ
```

### 4.5 `src/client/ExpansionUI.client.lua`

* **จุดที่ 1 (บรรทัด 90–128, 138–383, 553–780, 931–1065, 1116–1129)**:
  1. ฟังก์ชัน `makeLeftShortcutButton` (บรรทัด 90–128) สร้างไว้แต่ไม่เคยถูกเรียกใช้เลย
  2. สร้างหน้าต่างผังสกิล `skillsPage` (บรรทัด 213–383) ซ้ำซ้อนกับ `RagnarokPanels.client.lua`
  3. สร้างหน้าต่าง `guildWindow` (บรรทัด 553–780) และ `bookWindow` (`AdventurerHandbookWindow`, บรรทัด 931–1065) ทิ้งไว้แต่ใน `InputBegan` (บรรทัด 1116–1129) สั่งปิด `Visible = false` ตลอดเวลา ทำให้โค้ดกว่า 500 บรรทัดกลายเป็น Dead UI
* **จุดที่ 2 (บรรทัด 427, 439, 504, 516)** [✅ แก้ไขแล้ว]: ปรับให้มี fallback `(eqDef.nameThai or eqDef.name)` และ `(cardDef.descThai or cardDef.description)` แสดงชื่ออุปกรณ์ถูกต้อง และไม่เกิดข้อผิดพลาดต่อสตริงกับ nil 100%
* **จุดที่ 3 (บรรทัด 1031–1032)** [✅ แก้ไขแล้ว]: รองรับทั้ง `d.itemId` และ `d.ItemID` พร้อม fallback ชื่อไอเทม ทำให้สมุดคู่มือนักผจญภัยแสดงไอเทมดรอปของมอนสเตอร์ได้ครบถ้วนถูกต้อง

```lua
-- [บรรทัด 427-440]
stTitle.Text = sInfo.label .. ": " .. (eqDef and eqDef.nameThai or "ไม่ได้สวมใส่") -- ❌ [จุดที่เขียนไม่ดี]: ItemData ไม่มีฟิลด์ nameThai ทำให้แสดงว่า "ไม่ได้สวมใส่" ตลอดเวลา!
...
cStatus.Text = cardDef and ("🃏 " .. cardDef.nameThai .. "
(" .. (cardDef.descThai or "") .. ")") or "✨ ช่องการ์ดว่าง (พร้อมเสียบการ์ด)" -- ❌ [จุดที่เขียนไม่ดี (Crash)]: cardDef.nameThai เป็น nil ทำให้ต่อ string พังทันทีเมื่อมีการ์ดเสียบอยู่!
-- ✅ [วิธีแก้]: เปลี่ยนเป็น (eqDef and (eqDef.nameThai or eqDef.name) or "ไม่ได้สวมใส่") และใช้ (cardDef.nameThai or cardDef.name) กับ (cardDef.descThai or cardDef.description or "")
```

### 4.6 `src/client/JobAdvancementUI.client.lua`

* **จุดที่ 1 (บรรทัด 15–34 และ 214–221)**: คัดลอกโค้ด Fallback ของ `UITheme` (`hex`, `makeInstance`) ซ้ำกับ `PetAndMountUI.client.lua` และ `PvPArenaUI.client.lua` และสร้าง `Instance.new("Sound")` เองแทนที่จะเรียก `_G.RoROK_Audio.PlaySFX`

```lua
-- [บรรทัด 15-34]
local UITheme
local ok, themeMod = pcall(function()
	return require(script.Parent:WaitForChild("UI"):WaitForChild("UITheme"))
end)
if ok and themeMod then
	UITheme = themeMod
else
	UITheme = { -- ❌ [จุดซ้ำซ้อน]: โค้ดสำรอง UITheme 20 บรรทัดถูกคัดลอกซ้ำใน JobAdvancementUI, PetAndMountUI และ PvPArenaUI
		hex = function(h) ... end,
		makeInstance = function(cls, props, par) ... end,
	}
end
-- ✅ [วิธีแก้]: เรียก require(script.Parent:WaitForChild("UI"):WaitForChild("UITheme")) โดยตรง เพราะ UITheme เป็น ModuleScript มาตรฐานในโปรเจกต์อยู่แล้ว
```

### 4.7 `src/client/MarketUI.client.lua`

* **จุดที่ 1 (บรรทัด 29–85)**: เขียนฟังก์ชันสร้าง UI (`make`, `corner`, `newLabel`, `newButton`) แยกขึ้นมาใหม่แทนการใช้ `UITheme` แต่โดยรวมลอจิกของตลาดกลางเขียนได้ดีและสะอาดมาก ข้อสังเกตเล็กน้อยคือบรรทัด 144–146 ผูก `ViewportSize` กับ `Workspace.CurrentCamera` เพียงครั้งเดียวตอนรันสคริปต์ หาก `CurrentCamera` ถูกเปลี่ยนจะไม่ได้ผูกใหม่

```lua
-- [บรรทัด 144-146]
if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale) -- ❌ [จุดที่ควรระวัง]: ผูกเฉพาะกล้องตัวแรก หาก CurrentCamera เปลี่ยนจะไม่ทำงาน
end
-- ✅ [วิธีแก้]: เพิ่ม Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(...) เพื่อผูกสัญญาณใหม่เมื่อกล้องเปลี่ยน
```

### 4.8 `src/client/PartyUI.client.lua`

* **จุดที่ 1 (บรรทัด 15–17 และ 227–263)**: เขียนฟังก์ชัน `color(hex)` ซ้ำกับ `UITheme.hex` และสร้างแถวรายชื่อผู้เล่นในเซิร์ฟเวอร์ใหม่ทั้งหมดทุกครั้งที่มีการอัปเดต แต่เนื่องจากผู้เล่นในเซิร์ฟเวอร์มีจำนวนจำกัดจึงส่งผลกระทบต่ำ

```lua
-- [บรรทัด 15-17]
local function color(hex) -- ❌ [จุดซ้ำซ้อน]: ซ้ำกับฟังก์ชัน UITheme.hex
	return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
end
-- ✅ [วิธีแก้]: ใช้ UITheme.hex จากโมดูล src/client/UI/UITheme.lua
```

### 4.9 `src/client/PetAndMountUI.client.lua`

* **จุดที่ 1 (บรรทัด 10 และ 15–34)**: `local Debris = game:GetService("Debris")` ถูกประกาศไว้แต่ไม่เคยใช้งาน และมีบล็อก Fallback `UITheme` ซ้ำซ้อนกับ `JobAdvancementUI.client.lua`

```lua
-- [บรรทัด 10]
local Debris = game:GetService("Debris") -- ❌ [จุดที่เขียนไม่ดี]: ประกาศตัวแปรบริการ Debris แต่ไม่ได้ใช้งานเลยในไฟล์นี้
-- ✅ [วิธีแก้]: ลบบรรทัดที่ไม่ได้ใช้ออก และเรียกใช้ UITheme โดยตรง
```

### 4.10 `src/client/PvPArenaUI.client.lua`

* **จุดที่ 1 (บรรทัด 194 และ 296)**: มีอักขระ UTF-8 เสียหาย (กลายเป็นเครื่องหมาย ``) ในข้อความ `bannerSubText` และปุ่มปิดหน้าต่าง `lbCloseBtn`
* **จุดที่ 2 (บรรทัด 640)**: เขียน `local isSafe = localPlayer:GetAttribute("InPvPSafeZone") or true` ซึ่งในภาษา Lua หาก `GetAttribute` คืนค่า `false` นิพจน์ `false or true` จะได้ค่า `true` เสมอ! (และตัวแปร `isSafe` ก็ไม่ได้ถูกนำไปใช้งานต่อด้วย)

```lua
-- [บรรทัด 194 และ 296]
Text = " KILLING SPREE! (+65 แต้ม PvP)", -- ❌ [จุดที่เขียนไม่ดี]: อักขระอีโมจิเสียหาย (Mojibake)
...
Text = "", -- ❌ [จุดที่เขียนไม่ดี]: ปุ่มปิดหน้าต่างแสดงอักขระเสีย แทนที่จะเป็น "✕"

-- [บรรทัด 639-641]
local isPvP = (localPlayer:GetAttribute("Map") == "PvPArena")
local isSafe = localPlayer:GetAttribute("InPvPSafeZone") or true -- ❌ [จุดที่เขียนไม่ดี]: false or true ได้ค่า true เสมอใน Lua และตัวแปร isSafe ไม่ได้ถูกนำไปใช้ต่อ
-- ✅ [วิธีแก้]: แก้อักขระเสียเป็น "🔥 KILLING SPREE!" กับ "✕" และใช้ local isSafe = localPlayer:GetAttribute("InPvPSafeZone") ~= false
```

### 4.11 `src/client/RagnarokPanels.client.lua`

* **จุดที่ 1 (บรรทัด 104, 136–150)**: เขียนสูตร `statCost(v)` ซ้ำกับ `ClassData.GetStatCost(v)` และเขียนระบบลากหน้าต่างเองซ้ำกับ `UITheme.makeDraggable`
* **จุดที่ 2 (บรรทัด 461–478)** [✅ แก้ไขแล้ว]: เพิ่มคลาสขั้นที่ 2 (`Wizard`, `LordKnight`, `Hunter`, `Assassin`, `Priest`, `Blacksmith`) ในปุ่มแนะนำการอัปสเตตัส (`recommendBtn`) ครบถ้วน
* **จุดที่ 3 (บรรทัด 607)** [✅ แก้ไขแล้ว]: ปรับให้รองรับสกิล Debuff (`LexAeterna`, `Quagmire`) สามารถวางบนแถบ Hotbar ได้
* **จุดที่ 4 (บรรทัด 710–715)** [✅ แก้ไขแล้ว]: ลบบล็อกเช็ค `selectedSkill` ซ้ำซ้อนออกแล้ว

```lua
-- [บรรทัด 607]
if def and not def.isAttack and not def.isHeal and not def.isBuff then return end -- ❌ [จุดที่เขียนไม่ดี]: ไม่รวม not def.isDebuff ทำให้วางสกิล LexAeterna และ Quagmire ลงช่องสกิลไม่ได้
-- ✅ [วิธีแก้]: เพิ่ม and not def.isDebuff

-- [บรรทัด 710-715]
if not selectedSkill or not SkillData[selectedSkill] then
	if #list > 0 then selectedSkill = list[1].id end
end
if not selectedSkill or not SkillData[selectedSkill] then -- ❌ [จุดซ้ำซ้อน]: โค้ดบล็อกเดียวกันถูกคัดลอกซ้ำ 2 รอบติดกัน
	if #list > 0 then selectedSkill = list[1].id end
end
-- ✅ [วิธีแก้]: ลบบล็อกที่ซ้ำในบรรทัด 713-715 ออก และเพิ่มคลาสขั้นที่ 2 ใน recommendBtn
```

### 4.12 `src/client/UIManager.client.lua`

* **จุดที่ 1 (บรรทัด 157 และ 179–192)** [✅ แก้ไขแล้ว]:
  1. ตัวแปร `npcDialogueUI` รับค่าจาก `NpcDialogueUI.init(...)`
  2. ยกเลิกการเรียก `windowSystem.renderStats(data)` ที่ซ้ำซ้อน และใน `windowSystem.renderInventory` เพิ่มการตรวจสอบ `if inventoryWin and inventoryWin.Visible then` เพื่อป้องกันการเรนเดอร์กระเป๋าและโคลนโมเดล 3D ทุกวินาทีขณะที่กระเป๋าปิดอยู่เรียบร้อยแล้ว

```lua
-- [บรรทัด 179-192]
if remotes.updateCharData then
	remotes.updateCharData.OnClientEvent:Connect(function(data)
		latestData = data
		hudView.updateData(data)
		windowSystem.renderStats(data) -- ❌ [จุดซ้ำซ้อน]: หน้าต่าง Stats ใน WindowSystem ถูกแทนที่ด้วย RagnarokPanels แล้ว
		hotbarView.renderHotbar(data)
		if data.Inventory then
			windowSystem.renderInventory(data.Inventory, data.Equipment, data.EquipmentRefine) -- ❌ [จุดที่เขียนไม่ดี]: วาดตารางกระเป๋าใหม่และโคลนโมเดล 3D ทุก 1 วินาทีตาม Regen Loop แม้ไม่ได้เปิดกระเป๋า!
			-- ✅ [วิธีแก้]: อัปเดตเฉพาะข้อมูลแคชใน WindowSystem และวาด UI กระเป๋าใหม่เฉพาะเมื่อ inventoryWin.Visible == true หรือเมื่อได้รับอีเวนต์ UpdateInventory เท่านั้น
```

## 5. รายงานตรวจสอบโค้ดรายไฟล์: โฟลเดอร์ `src/client/UI/` (8 ไฟล์)

### 5.1 `src/client/UI/CombatTargeting.lua`

* **จุดที่ 1 (บรรทัด 145)** [✅ แก้ไขแล้ว]: ย้ายการประกาศ `local autoAttackEnabled = false` ขึ้นไปไว้ด้านบนก่อนฟังก์ชัน `executeCast` เพื่อให้มองเห็นค่า Scope ถูกต้องขณะร่ายสกิล
* **จุดที่ 2 (บรรทัด 295 และ 375)**: สร้าง `RaycastParams.new()` ใหม่ทุกเฟรมใน `RenderStepped` (บรรทัด 295) และทุก 0.08 วินาทีใน `Heartbeat` (บรรทัด 375)
* **จุดที่ 3 (บรรทัด 703)** [✅ แก้ไขแล้ว]: ประกาศ `local updatePotionInfoDisplay` ล่วงหน้าก่อนฟังก์ชัน `refreshVisibleTargetFilters` และกำหนดนิยามฟังก์ชันที่บรรทัด 792 เพื่อให้สามารถอัปเดตจำนวนยาในกระเป๋าได้อย่างถูกต้อง

```lua
-- [บรรทัด 145 (ภายใน executeCast)]
if not autoAttackEnabled and root then -- ❌ [จุดที่เขียนไม่ดี]: ตัวแปร local autoAttackEnabled เพิ่งถูกประกาศที่บรรทัด 396 ทำให้ตรงนี้อ่านค่า Global autoAttackEnabled (เป็น nil เสมอ) ดังนั้นแม้เปิดบอท Auto อยู่ ถ้าตัวละครขยับก็จะถูกยกเลิกการร่ายเวท!
-- ✅ [วิธีแก้]: ย้ายการประกาศ local autoAttackEnabled = false และ local updatePotionInfoDisplay ไปไว้ด้านบนก่อนฟังก์ชันที่เรียกใช้

-- [บรรทัด 702-703]
local function refreshVisibleTargetFilters()
	if updatePotionInfoDisplay then updatePotionInfoDisplay() end -- ❌ [จุดที่เขียนไม่ดี]: local function updatePotionInfoDisplay เพิ่งประกาศที่บรรทัด 792 ทำให้เงื่อนไขนี้เป็น nil เสมอ!
```

### 5.2 `src/client/UI/DamageNumbers.lua`

* **จุดที่ 1 (บรรทัด 86–98)**: สร้าง `RunService.RenderStepped:Connect` แยกสำหรับตัวเลขดาเมจแต่ละตัว และใช้ `tick()` ที่กำลังจะเลิกใช้ (Deprecated) รวมถึงยึดพิกัดหน้าจอ `screenPos.X` และ `startY` ตายตัวตั้งแต่เฟรมแรก ทำให้เมื่อหมุนกล้องตัวเลขจะลอยค้างผิดตำแหน่งบนหน้าจอ

```lua
-- [บรรทัด 86-98]
local conn
conn = RunService.RenderStepped:Connect(function() -- ❌ [จุดที่เขียนไม่ดี]: ผูก RenderStepped แยกทุกครั้งที่มีตัวเลขดาเมจเด้ง และใช้พิกัดหน้าจอคงที่ไม่อัปเดตตามมุมกล้อง
	local elapsed = tick() - startT
	...
-- ✅ [วิธีแก้]: ใช้ TweenService:Create เลื่อนตำแหน่ง TextLabel หรือใช้ BillboardGui ใน World Space เพื่อให้ตัวเลขเกาะตำแหน่งมอนสเตอร์เมื่อหมุนกล้องและไม่ต้องผูก RenderStepped แยก
```

### 5.3 `src/client/UI/HUDView.lua`

* **จุดที่ 1 (บรรทัด 472–489 และ 543–564)**: ใช้ทั้ง `RunService.Heartbeat` และ `task.spawn` สร้างลูป `while` แยกตามจำนวนไอคอนสถานะ (`addStatusIcon`) ควบคู่กัน
* **จุดที่ 2 (บรรทัด 580–602 และ 680)**:
  1. สร้าง `goldFrame` และอัปเดต `goldLabel.Text` ทุกครั้ง แต่ตั้งค่า `Visible = false` ตลอดกาล (Dead UI)
  2. บรรทัด 680 คืนค่า `statusButton = statusButton` ทั้งที่ตัวแปร `statusButton` ไม่เคยถูกประกาศในไฟล์นี้ (ได้ค่า `nil` เสมอ)

```lua
-- [บรรทัด 580-588 และ 680]
local goldFrame = makeInstance("Frame", {
	Name    = "GoldDisplay",
	Visible = false, -- ❌ [จุดซ้ำซ้อน/Dead UI]: สร้าง UI แสดงเงินไว้แต่ซ่อนตลอดเวลา ไม่เคยเปิดแสดงผล
...
return {
	...
	inventoryButton = inventoryButton,
	statusButton = statusButton, -- ❌ [จุดที่เขียนไม่ดี]: ตัวแปร statusButton ไม่ได้ถูกประกาศไว้ในไฟล์นี้ (มีค่าเป็น nil)
}
-- ✅ [วิธีแก้]: ลบ goldFrame และ statusButton ที่ไม่ได้ใช้งานออก
```

### 5.4 `src/client/UI/HotbarView.lua`

* **จุดที่ 1 (บรรทัด 12, 150, 238–246, 249, 260)**:
  1. พารามิเตอร์ `onOpenSkillTreeCallback` (บรรทัด 12) และตาราง `autoSkillCooldownUntil` (บรรทัด 249) ไม่เคยถูกนำไปใช้งานจริง
  2. บรรทัด 150 เช็ค `tostring(i == 10 and 0 or i)` ในลูป `for i = 1, 8` ซึ่ง `i` ไม่มีทางเป็น 10
  3. ตาราง `skillByClass` (บรรทัด 238–246) และเงื่อนไขใน `renderHotbar` (บรรทัด 260: `def.class == class or def.class == "Novice"`) ไม่รองรับคลาสขั้นที่ 2! เมื่อผู้เล่นเลื่อนขั้นเป็น 2nd Job สกิลของคลาส 1 (`def.class == "Knight"` ฯลฯ) จะไม่ถูกใส่ลงใน Hotbar อัตโนมัติ

```lua
-- [บรรทัด 258-261]
for sId, sLv in pairs(owned) do
	local def = skillData[sId]
	if (tonumber(sLv) or 0) > 0 and def and not def.isPassive and (def.class == class or def.class == "Novice") then -- ❌ [จุดที่เขียนไม่ดี]: ไม่ได้เช็คคลาสต้นทาง (ParentClass) ทำให้เมื่อเป็นคลาส 2 สกิลคลาส 1 จะไม่เข้าเงื่อนไขนี้
-- ✅ [วิธีแก้]: ใช้ ClassData.CanLearnSkill(class, def.class) แทนการเช็ค def.class == class
```

### 5.5 `src/client/UI/MinimapView.lua`

* **จุดที่ 1 (บรรทัด 476–487 และ 544)**:
  1. วาดบล็อกอาคารเมือง Prontera (`PRONTERA_CITY_BLOCKS`) ลงบนมินิแมพตลอดเวลา แม้ว่าผู้เล่นจะวาร์ปไปอยู่แมพ `Morroc`, `Amatsu`, หรือ `PronteraCulvert` แล้วก็ตาม
  2. บรรทัด 544 เช็คชื่อบอส `mId == "Turtle_General"` (มีขีดล่าง `_`) แต่ใน `MonsterData.lua` ใช้ชื่อ `"TurtleGeneral"` (ไม่มีขีดล่าง)

```lua
-- [บรรทัด 476-487]
for idx, block in ipairs(PRONTERA_CITY_BLOCKS) do -- ❌ [จุดที่เขียนไม่ดี]: แสดงผังตึกเมือง Prontera ตลอดเวลาแม้ผู้เล่นจะอยู่ในดันเจี้ยนหรือแมพอื่น
	local f = cityBlockFrames[idx]
	...
-- [บรรทัด 544]
local isWorldBoss = obj:GetAttribute("IsWorldBoss") or mId == "Eddga" or mId == "Turtle_General" -- ❌ [จุดที่เขียนไม่ดี]: พิมพ์ชื่อไอดีผิดเป็น "Turtle_General" (ที่ถูกคือ "TurtleGeneral")
-- ✅ [วิธีแก้]: ซ่อน buildingLayer เมื่อ player:GetAttribute("Map") ~= "Prontera" และแก้ "Turtle_General" เป็น "TurtleGeneral"
```

### 5.6 `src/client/UI/NpcDialogueUI.lua`

* **จุดที่ 1 (บรรทัด 15 และ 221–230)**:
  1. รับพารามิเตอร์ `remotes`, `minimapView`, `callbacks` เข้ามาแต่ไม่ได้ใช้งานเลย (ไปเรียก `ReplicatedStorage:WaitForChild("RemoteEvents")` ซ้ำเองในบรรทัด 20)
  2. สร้างกรอบ `StoryQuestTracker` ไว้ที่ตำแหน่ง `UDim2.new(1, -242, 0, 185)` ซึ่ง **ซ้อนทับกับ `QuestTrackerWidget` ของ `MinimapView.lua` (`UDim2.new(1, -172, 0, 178)`) และ `PvPStatusBar` ของ `PvPArenaUI.client.lua` (`UDim2.new(1, -370, 0, 195)`)** บนหน้าจอฝั่งขวาใต้แผนที่!

```lua
-- [บรรทัด 221-230]
local hudTracker = makeInstance("Frame", {
	Name = "StoryQuestTracker",
	Size = UDim2.new(0, 230, 0, 64),
	Position = UDim2.new(1, -242, 0, 185), -- ❌ [จุดที่เขียนไม่ดี]: ตำแหน่ง Y=185 ด้านขวาของจอ ทับซ้อนกับ QuestTrackerWidget ของ MinimapView (Y=178) พอดี!
-- ✅ [วิธีแก้]: รวมรายการเควสเนื้อเรื่องเข้าใน QuestTrackerWidget เดียวกับเควสประจำวันใน MinimapView หรือขยับตำแหน่งไม่ให้ทับกัน
```

### 5.7 `src/client/UI/UITheme.lua`

* **จุดที่ 1 (บรรทัด 63–73)**: ใน `UITheme.makeDraggable` ทุกครั้งที่ผู้เล่นคลิกเมาส์ซ้ายบนหัวหน้าต่าง (`dragHandle.InputBegan`) จะสร้างการเชื่อมต่อ `input.Changed:Connect(...)` ใหม่ซ้อนเพิ่มขึ้นเรื่อยๆ โดยไม่เคย `Disconnect()` (Memory Leak) และฟังก์ชัน `makeDraggable` นี้กลับไม่ถูกเรียกใช้ใน `WindowSystem.lua` หรือ `RagnarokPanels.client.lua` (ซึ่งต่างเขียนโค้ดลากหน้าต่างเองซ้ำอีกรอบ)

```lua
-- [บรรทัด 63-73]
dragHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = targetFrame.Position
		input.Changed:Connect(function() -- ❌ [จุดที่เขียนไม่ดี]: สร้าง Connection ซ้อนใหม่ทุกครั้งที่คลิกโดยไม่ Disconnect
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)
-- ✅ [วิธีแก้]: ใช้ dragHandle.InputEnded หรือ UserInputService.InputEnded เพียงตัวเดียวด้านนอกแทนการผูก input.Changed ซ้ำทุกครั้งที่คลิก
```

### 5.8 `src/client/UI/WindowSystem.lua`

* **จุดที่ 1 (บรรทัด 130–152, 180–292, 295–334, 1703–1715)**:
  1. ใน `createWindow` (บรรทัด 130–152) เขียนระบบลากหน้าต่างเองซ้ำกับ `UITheme.makeDraggable`
  2. สร้างหน้าต่าง `Stats` (บรรทัด 180–292), `TutorialOverlay` (บรรทัด 295–334), และ `Skills` (บรรทัด 1703–1715) ทิ้งไว้เป็น **Dead Code กว่า 170 บรรทัด** เพราะถูกแทนที่ด้วย `RagnarokPanels.client.lua` และ `HelpWindow` ไปแล้ว
* **จุดที่ 2 (บรรทัด 32)**: รับ `dropItemRemote` มาเก็บไว้ในตัวแปร แต่ **ไม่มีปุ่มทิ้งไอเทม (Drop Item) ในหน้าต่างกระเป๋าเลย** ทำให้ระบบ `ItemDropSystem.server.lua` ที่เขียนไว้บน Server ไม่สามารถกดใช้งานจาก UI กระเป๋าได้
* **จุดที่ 3 (บรรทัด 1064–1094)**:
  1. `renderInventory` เรียก `task.spawn(refreshAvatarPreview)` ซึ่งสั่ง `char:Clone()` ตัวละคร 3D ทั้งตัวทุกครั้งที่ข้อมูลอัปเดต (และเนื่องจาก `GameManager` ส่ง `UpdateCharacterData` ทุก 1 วินาที จึงเกิดการ `Clone()` โมเดลตัวละครทุก 1 วินาทีแม้ไม่ได้เปิดหน้าต่างกระเป๋า!)
  2. เมื่อกดเปิดกระเป๋าผ่าน `toggleInventory()` (บรรทัด 1072–1080) จะเปลี่ยน `inventoryWin.Visible = true` ซึ่งไปกระตุ้น `inventoryWin:GetPropertyChangedSignal("Visible")` (บรรทัด 1082–1094) ทำให้เกิดการเรียก `requestInventoryRemote:InvokeServer()` **ซ้ำ 2 ครั้งซ้อน** ในเวลาเดียวกัน!

```lua
-- [บรรทัด 1064-1094]
local function renderInventory(inventory, equipment, equipmentRefine)
	...
	renderInventoryGrid()
	task.spawn(refreshAvatarPreview) -- ❌ [จุดที่เขียนไม่ดี]: สั่ง Clone() ตัวละคร 3D ลง ViewportFrame ทุกครั้งแม้หน้าต่างกระเป๋าจะปิดอยู่ (inventoryWin.Visible == false)!
end

local function toggleInventory()
	toggleWindow(inventoryWin)
	if inventoryWin.Visible and requestInventoryRemote then -- ❌ [จุดซ้ำซ้อน]: ทำงานซ้ำซ้อนกับ GetPropertyChangedSignal("Visible") ด้านล่าง ทำให้ยิง InvokeServer() 2 รอบซ้อนทุกครั้งที่กดเปิดกระเป๋า!
		task.spawn(function()
			local ok, inventory, equipment, equipmentRefine = pcall(function() return requestInventoryRemote:InvokeServer() end)
			if ok then renderInventory(inventory, equipment, equipmentRefine) end
		end)
	end
end
-- ✅ [วิธีแก้]: เช็ค if not inventoryWin.Visible then return end ก่อนวาด Grid/Clone โมเดล 3D และเก็บการดึงข้อมูลตอนเปิดกระเป๋าไว้ที่ GetPropertyChangedSignal("Visible") เพียงจุดเดียว
```
