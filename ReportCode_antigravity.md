# รายงานสรุปผลการแก้ไขโค้ดและปรับปรุงระบบ (RoROK Refactoring & Bugfix Report)

**ชื่อเอกสาร**: `ReportCode_antigravity.md`  
**วันที่ดำเนินการ**: 2026-10-24  
**ผู้ดำเนินการ**: Antigravity AI Assistant  
**เป้าหมาย**: แก้ไขปัญหาจุดวิกฤต (Critical Crashes), บั๊กสูตรคำนวณสเตตัส/ดาเมจ, บั๊กของหาย, จุดซ้ำซ้อนข้ามสคริปต์ (Redundancies), และปัญหาประสิทธิภาพ (Performance) ครบทั้ง **10 ข้อหลัก** จากตารางสรุปของ `reportcode_gemini.md` 100%

---

## สรุปภาพรวมการแก้ไขทั้ง 10 ข้อ

| ข้อที่ | หัวข้อปัญหา | ไฟล์ที่ได้รับการแก้ไข | ระดับความสำคัญ | สถานะ |
| :---: | :--- | :--- | :---: | :---: |
| **1** | ฟังก์ชันไม่มีอยู่จริง (`DataStore.AddGold`) | `DataStore.server.lua`, `PvPArenaSystem.server.lua`, `DungeonAndMvpSystem.server.lua` | วิกฤต (Crash) | ✅ แก้ไขแล้ว 100% |
| **2** | เรียก `FireServer()` จากฝั่ง Server | `PvPArenaSystem.server.lua` | วิกฤต (Crash) | ✅ แก้ไขแล้ว 100% |
| **3** | ต่อ String กับค่า `nil` (`nameThai`/`descThai`) | `ExpansionUI.client.lua` | วิกฤต (Crash) | ✅ แก้ไขแล้ว 100% |
| **4** | โบนัสเลือด, SP, การ์ด, FLEE, HIT, ตีบวกไม่คิด | `DataStore.server.lua`, `ClassData.lua` | บั๊กคำนวณสเตตัส | ✅ แก้ไขแล้ว 100% |
| **5** | คลาส Hunter คิด ATK จาก STR แทน DEX | `ClassData.lua`, `CombatVFX.client.lua` | บั๊กคลาสขั้นที่ 2 | ✅ แก้ไขแล้ว 100% |
| **6** | ค่าตีบวก (`refineATK`) ไม่ถูกส่งเข้าสูตรดาเมจ | `CombatSystem.server.lua` | บั๊กระบบตีบวก | ✅ แก้ไขแล้ว 100% |
| **7** | เลื่อนขั้น 2nd Job เขียนทับอาวุธเดิมหายถาวร | `JobAdvancementSystem.server.lua` | บั๊กไอเทมสูญหาย | ✅ แก้ไขแล้ว 100% |
| **8** | เสกบอส MVP ซ้ำซ้อน 3 สคริปต์ & บอสไม่มี AI | `MonsterAI.server.lua`, `WorldMapExpansion.server.lua`, `DungeonAndMvpSystem.server.lua`, `CombatSystem.server.lua` | จุดซ้ำซ้อนสูง | ✅ แก้ไขแล้ว 100% |
| **9** | หน้าต่าง UI ทับซ้อน / Dead UI | `WindowSystem.lua`, `ExpansionUI.client.lua`, `RagnarokPanels.client.lua`, `UIManager.client.lua` | จุดซ้ำซ้อนสูง | ✅ แก้ไขแล้ว 100% |
| **10** | ยิงข้อมูลตัวละครทุก 1 วินาทีแม้เลือดเต็ม | `GameManager.server.lua`, `UIManager.client.lua`, `WindowSystem.lua` | Performance | ✅ แก้ไขแล้ว 100% |

---

## รายละเอียดเชิงลึกรายข้อ (ไฟล์, จุดที่แก้, สาเหตุ, และโค้ดก่อน/หลังแก้)

---

### ข้อที่ 1: ปัญหาเรียกฟังก์ชันที่ไม่มีอยู่จริง (`DataStore.AddGold`)
* **ไฟล์ที่เกี่ยวข้อง**:
  * `src/server/DataStore.server.lua`
  * `src/server/PvPArenaSystem.server.lua`
  * `src/server/DungeonAndMvpSystem.server.lua`
* **สาเหตุ**:
  * ในโมดูล `DataStore.server.lua` มีเพียงฟังก์ชัน `ModifyGold(player, amount)` แต่ใน `PvPArenaSystem` และ `DungeonAndMvpSystem` เรียก `DataStore.AddGold(player, amount)` ส่งผลให้เกมเกิด Runtime Error (attempt to call a nil value) ทันทีที่ผู้เล่นเปิดหีบสมบัติ MVP หรือได้รับรางวัลจากสนาม PvP
  * ใน `DungeonAndMvpSystem` ใช้ `table.insert(pData.Inventory, ...)` ยัดไอเทมตรงๆ ทำให้ไอเทมหินตีบวกไม่ยอมรวมกอง (Stack)
* **วิธีแก้ & โค้ดที่เปลี่ยนแปลง**:
  1. ใน `DataStore.server.lua` เพิ่ม Alias `AddGold = ModifyGold` ในตาราง `_G.DataStore`
  2. ใน `PvPArenaSystem.server.lua` และ `DungeonAndMvpSystem.server.lua` ปรับให้เรียกแบบ Safe Call และใช้ `DataStore.AddItem`
```lua
-- [ก่อนแก้]:
DataStore.AddGold(player, goldBonus)
table.insert(pData.Inventory, { itemId = "BeginnerRefinementStone", quantity = 3 })

-- [หลังแก้]:
if DataStore then
    (DataStore.ModifyGold or DataStore.AddGold)(player, goldBonus)
    DataStore.AddItem(player, "BeginnerRefinementStone", 3)
end
```

---

### ข้อที่ 2: ปัญหาเรียก `FireServer()` จากฝั่ง Server ใน `PvPArenaSystem.server.lua`
* **ไฟล์ที่เกี่ยวข้อง**:
  * `src/server/PvPArenaSystem.server.lua`
* **สาเหตุ**:
  * บนเซิร์ฟเวอร์ โค้ดส่วน ProximityPrompt ประตูทางออกลานประลอง (`portalPrompt.Triggered`) มีการเรียก `RE_LeavePvPArena:FireServer()` ซึ่งผิดกฎของ Roblox Engine เพราะฟังก์ชัน `FireServer()` สามารถเรียกได้จาก LocalScript ฝั่ง Client เท่านั้น การเรียกบน Script จะทำให้เกิด Exception ทันที
* **วิธีแก้ & โค้ดที่เปลี่ยนแปลง**:
  * ประกาศตัวแปร `local leaveArena` แบบ Forward Declaration แล้วให้ `portalPrompt.Triggered` เรียกฟังก์ชัน `leaveArena(player)` บนเซิร์ฟเวอร์โดยตรง
```lua
-- [ก่อนแก้]:
portalPrompt.Triggered:Connect(function(player)
    RE_LeavePvPArena:FireServer() -- ❌ Error: FireServer can only be called from a LocalScript
end)

-- [หลังแก้]:
local leaveArena -- Forward declaration
...
portalPrompt.Triggered:Connect(function(player)
    if leaveArena then
        leaveArena(player) -- ✅ ทำงานบน Server ได้ทันทีและวาร์ปผู้เล่นกลับ Prontera
    end
end)
```

---

### ข้อที่ 3: ปัญหาต่อ String กับค่า `nil` (`nameThai`/`descThai`) ใน `ExpansionUI.client.lua`
* **ไฟล์ที่เกี่ยวข้อง**:
  * `src/client/ExpansionUI.client.lua`
* **สาเหตุ**:
  * โค้ดส่วนหน้าต่างเสียบการ์ดอุปกรณ์และสมุดคู่มือนักผจญภัย ดึงค่า `eqDef.nameThai` และ `cardDef.nameThai` มาต่อข้อความตรงๆ แต่ไอเทมใน `ItemData.lua` มีเฉพาะคีย์ภาษาอังกฤษ `name` และ `description` เมื่อมีค่าการ์ดที่ไม่มี `nameThai` จึงเกิด Error `attempt to concatenate a nil value` ทำให้หน้าต่าง UI ค้างและเปิดไม่ขึ้น
  * ในสมุดคู่มืออ่าน `d.ItemID` แต่ drop table บางตัวใช้ `d.itemId`
* **วิธีแก้ & โค้ดที่เปลี่ยนแปลง**:
  * เพิ่ม Fallback ป้องกันค่า nil: `(eqDef.nameThai or eqDef.name)` และ `(cardDef.descThai or cardDef.description or "")`
  * รองรับทั้ง `d.itemId or d.ItemID`
```lua
-- [ก่อนแก้]:
stTitle.Text = sInfo.label .. ": " .. (eqDef and eqDef.nameThai or "ไม่ได้สวมใส่")
cStatus.Text = cardDef and ("🃏 " .. cardDef.nameThai .. "\n(" .. (cardDef.descThai or "") .. ")")

-- [หลังแก้]:
stTitle.Text = sInfo.label .. ": " .. (eqDef and (eqDef.nameThai or eqDef.name) or "ไม่ได้สวมใส่")
cStatus.Text = cardDef and ("🃏 " .. (cardDef.nameThai or cardDef.name or "การ์ด") .. "\n(" .. (cardDef.descThai or cardDef.description or "") .. ")") or "✨ ช่องการ์ดว่าง (พร้อมเสียบการ์ด)"
```

---

### ข้อที่ 4: บั๊กการคำนวณสเตตัสและโบนัสอุปกรณ์/การ์ด/ตีบวก
* **ไฟล์ที่เกี่ยวข้อง**:
  * `src/server/DataStore.server.lua`
  * `src/shared/ClassData.lua`
* **สาเหตุ**:
  * ใน `DataStore.server.lua` ฟังก์ชัน `GetEquipmentBonuses` ตรวจสอบเฉพาะค่า ATK, DEF, MDEF, MATK แต่ไม่ได้นำโบนัส `MaxHP/HP`, `MaxSP/SP`, `CritRate`, `HIT`, `FLEE`, `ASPD` จากอุปกรณ์และการ์ดมารวม
  * โบนัสตีบวกอาวุธให้ ATK เพียง +1 ต่อระดับ แทนที่จะเป็น +6 ATK ต่อระดับตามสูตร RO และเกราะไม่ได้บวก DEF +4 ต่อระดับ
  * ใน `ClassData.lua` ฟังก์ชัน `CalculateDerivedStats` แก้ไขตารางของผู้เรียกโดยตรง (`eq.HP = eq.HP or 0`) และอ่านคีย์ `eq.HP` ซึ่งไม่ตรงกับที่ DataStore ส่ง `MaxHP` มา
* **วิธีแก้ & โค้ดที่เปลี่ยนแปลง**:
  * ใน `DataStore.server.lua`: คำนวณสะสมโบนัสสเตตัสครบทุกค่า พร้อมสูตรตีบวกอาวุธ (+6 ATK) และเกราะ (+4 DEF)
  * ใน `ClassData.lua`: ปรับเป็น Pure Function ไม่อ่านเขียนทับตารางเดิม และดึงค่าแบบยืดหยุ่น:
```lua
-- [หลังแก้ใน ClassData.lua]:
local eqHP = tonumber(eq.MaxHP or eq.HP) or 0
local eqSP = tonumber(eq.MaxSP or eq.SP) or 0
local eqCritRate = tonumber(eq.CritRate or eq.Crit) or 0
local eqHIT = tonumber(eq.HIT or eq.Hit) or 0
local eqFLEE = tonumber(eq.FLEE or eq.Flee) or 0
local eqASPD = tonumber(eq.ASPD or eq.Aspd) or 0

local MaxHP = base.BaseHP + (VIT * 35) + (level * 30) + eqHP
local MaxSP = base.BaseSP + (INT * 15) + (level * 10) + eqSP
local HIT = DEX + level + 20 + eqHIT
local FLEE = AGI + level + 10 + eqFLEE
local ASPD = math.min(base.BaseASPD + math.floor(AGI * 4) + eqASPD, 190)
local CritRate = math.floor(LUK / 3) + 1 + eqCritRate
```

---

### ข้อที่ 5: คลาส Hunter คำนวณ ATK สเกลจาก STR แทน DEX และแอนิเมชันไม่ตรง
* **ไฟล์ที่เกี่ยวข้อง**:
  * `src/shared/ClassData.lua`
  * `src/client/CombatVFX.client.lua`
* **สาเหตุ**:
  * ใน `ClassData.lua` มีโค้ด `classID == "Archer"` เช็คเฉพาะ Archer เมื่อผู้เล่นเลื่อนขั้นเป็น `Hunter` ตัวแปร `isBowClass` กลายเป็น `false` ส่งผลให้พลังโจมตี ATK เปลี่ยนกลับไปสเกลจาก STR แทน DEX
  * ใน `CombatVFX.client.lua` ตรวจสอบเฉพาะคลาส Archer สำหรับแอนิเมชันยิงธนูและลูกศรพุ่ง ทำให้ Hunter ฟันเป็นดาบประชิด และคลาส Wizard / Priest ไม่มีแอนิเมชันร่ายเวท
* **วิธีแก้ & โค้ดที่เปลี่ยนแปลง**:
  * ใน `ClassData.lua`: ปรับเป็น `local isBowClass = (classID == "Archer" or classID == "Hunter")` ทั้งสำหรับค่า Stat หลักและ Stat รอง
  * ใน `CombatVFX.client.lua`: เพิ่มการรองรับ `Hunter` สำหรับการยิงธนูและสกิล BlitzBeat/FalconAssault และเพิ่ม `Wizard/Priest` สำหรับท่ายกมือร่ายมนตร์
```lua
-- [หลังแก้ใน ClassData.lua]:
local isBowClass = (classID == "Archer" or classID == "Hunter")
local mainPhysicalStat = isBowClass and DEX or STR
local secondaryStat = isBowClass and math.floor(STR / 5) or math.floor(DEX / 5)
```

---

### ข้อที่ 6: ค่าตีบวกอาวุธ (`refineATK`) ไม่ถูกส่งเข้าสูตรคำนวณความเสียหาย
* **ไฟล์ที่เกี่ยวข้อง**:
  * `src/server/CombatSystem.server.lua`
* **สาเหตุ**:
  * ใน `CombatSystem.server.lua` ฟังก์ชัน `PlayerAttackMonster` มีการเรียก `CalcPhysicalDamage` และ `CalcMagicDamage` โดยใส่พารามิเตอร์ท้ายเป็น `0, 0` ตายตัว ทำให้การตีบวกอาวุธ (+1 ถึง +15) ที่ผู้เล่นลงทุนตีบวกมา ไม่มีผลต่อการเพิ่มดาเมจจริงในระบบต่อสู้
* **วิธีแก้ & โค้ดที่เปลี่ยนแปลง**:
  * ดึงค่าระดับตีบวก `pData.EquipmentRefine.Weapon` มาคำนวณ `refineATK = weaponRefineLevel * 6` (และ `refineMATK`)
  * ดึงค่า `ignoreDefPercent` จากสกิล และบัฟ `BuffAuraBlade` (+25%) ส่งเข้าฟังก์ชันคำนวณดาเมจ
```lua
-- [หลังแก้ใน CombatSystem.server.lua]:
local weaponRefineLevel = math.clamp(math.floor(tonumber(pData and pData.EquipmentRefine and pData.EquipmentRefine.Weapon) or 0), 0, 15)
local refineATK = weaponRefineLevel * 6
local refineMATK = isMagicSkill and (weaponRefineLevel * 6) or 0
local ignoreDefPercent = (skillDataRef and (skillDataRef.ignoreDefPercent or skillDataRef.ignoreDef)) or 0
if player:GetAttribute("BuffAuraBlade") then
    ignoreDefPercent = math.max(ignoreDefPercent, 0.25)
end

if isMagicSkill then
    finalDamage = CalcMagicDamage(..., ignoreDefPercent, refineMATK)
else
    finalDamage = CalcPhysicalDamage(..., ignoreDefPercent, refineATK)
end
```

---

### ข้อที่ 7: เลื่อนขั้น 2nd Job เขียนทับอาวุธเดิมโดยไม่คืนเข้ากระเป๋า (บั๊กของหาย)
* **ไฟล์ที่เกี่ยวข้อง**:
  * `src/server/JobAdvancementSystem.server.lua`
* **สาเหตุ**:
  * เมื่อคุยกับ Grand Master Elena เพื่อเลื่อนขั้นเป็นคลาส 2 ระบบจะมอบอาวุธเริ่มต้นประจำคลาส 2 (เช่น `HalberdOfValor`, `ArchMageStaff`) โดยกำหนด `data.Equipment.Weapon = starterWeapon` ทับลงไปทันที ทำให้อาวุธชิ้นเดิมของผู้เล่นพร้อมระดับตีบวกหายไปจากตัวละครถาวร
  * มีเงื่อนไข `if changeClassRemote then` ที่ค้างไว้โดยไม่ได้ใช้งาน และไม่ได้เรียกฟังก์ชันเปลี่ยนโมเดลอาวุธในมือ
* **วิธีแก้ & โค้ดที่เปลี่ยนแปลง**:
  * เพิ่มฟังก์ชัน `returnEquipmentToInventory` คืนอาวุธเดิมและค่าตีบวกเดิมเข้ากระเป๋า `data.Inventory` ก่อนติดตั้งอาวุธใหม่
  * ยิง `RE_UpdateInventory` อัปเดตกระเป๋าฝั่ง Client และเรียก `_G.RebuildCharacterWeaponRig(player)` เพื่อเปลี่ยนโมเดลอาวุธ 3D ในมือตัวละครทันที
```lua
-- [หลังแก้ใน JobAdvancementSystem.server.lua]:
local function returnEquipmentToInventory(data, itemId, refineLevel)
    if not itemId then return end
    data.Inventory = data.Inventory or {}
    local refineNum = tonumber(refineLevel) or 0
    for _, owned in ipairs(data.Inventory) do
        if type(owned) == "table" and owned.itemId == itemId and (tonumber(owned.enhancement) or 0) == refineNum then
            owned.quantity = (tonumber(owned.quantity) or 0) + 1
            return
        end
    end
    table.insert(data.Inventory, { itemId = itemId, quantity = 1, enhancement = refineNum })
end

if starterWeapon then
    local oldWeaponId = data.Equipment.Weapon
    local oldRefine = tonumber(data.EquipmentRefine.Weapon) or 0
    if oldWeaponId then
        returnEquipmentToInventory(data, oldWeaponId, oldRefine) -- ✅ คืนของเดิมเข้ากระเป๋า
    end
    data.Equipment.Weapon = starterWeapon
    data.EquipmentRefine.Weapon = 1
end

if _G.RebuildCharacterWeaponRig then
    _G.RebuildCharacterWeaponRig(player) -- ✅ อัปเดตโมเดลอาวุธในมือทันที
end
```

---

### ข้อที่ 8: จุดซ้ำซ้อนการเสกบอส MVP ข้าม 3 สคริปต์ และบอสไม่มี AI
* **ไฟล์ที่เกี่ยวข้อง**:
  * `src/server/MonsterAI.server.lua`
  * `src/server/WorldMapExpansion.server.lua`
  * `src/server/DungeonAndMvpSystem.server.lua`
  * `src/server/CombatSystem.server.lua`
* **สาเหตุ**:
  * `DungeonAndMvpSystem.server.lua` มีลูปเสกบอส `GoldenThiefBug`, `Drake`, `Eddga` ซ้อนขึ้นมาเป็นก้อน Part สี Neon ในโฟลเดอร์ `Workspace.RoROK_MVPBosses` โดยไม่มี AI เคลื่อนที่หรือโจมตี และระบบล็อกเป้าหมายไม่เห็น
  * `MonsterAI.server.lua` ในโซน 6 นอกเมือง Prontera มีการเสก `Drake` ซ้ำซ้อนกับในดันเจี้ยน Culvert
  * ฟังก์ชัน `pushOutOfSafeZone` ใน `MonsterAI.server.lua` ตรวจสอบขอบเขตเฉพาะเมือง Prontera ทำให้มอนสเตอร์ที่เดินเฉียดโซนปลอดภัยใน Morroc/Amatsu ถูกผลักวาร์ปกลับมาที่ Prontera
* **วิธีแก้ & โค้ดที่เปลี่ยนแปลง**:
  1. ลบการเสกบอส Neon ปลอมใน `DungeonAndMvpSystem.server.lua` ออก แล้วส่งออกฟังก์ชัน `_G.SpawnMvpTreasureChest = spawnTreasureChest`
  2. รวมศูนย์การเสกบอสทั้งหมดผ่าน `_G.MonsterAI.SpawnMonster` ใน `Workspace.Monsters` โดยเสก `GoldenThiefBug` และ `Drake` ไว้ท้ายดันเจี้ยน `PronteraCulvert`, `Eddga` ใน `Morroc`, และ `TurtleGeneral` ใน `Amatsu`
  3. ลบ `Drake` ซ้ำซ้อนออกจากทุ่ง Prontera Zone 6
  4. ปรับ `pushOutOfSafeZone` ให้คำนวณตามพิกัดกรอบโซนปลอดภัยของแต่ละแมพแยกอิสระ
  5. ใน `CombatSystem.server.lua` เมื่อบอส MVP ถูกกำจัด จะประกาศ `🏆 [MVP DEFEATED]` ทั้งเซิร์ฟเวอร์ และเรียก `_G.SpawnMvpTreasureChest` ดรอปหีบสมบัติ MVP ทันที
```lua
-- [หลังแก้ใน CombatSystem.server.lua]:
local isMvpBoss = monster:GetAttribute("IsWorldBoss") == true or monster:GetAttribute("IsMVP") == true or (monsterID == "GoldenThiefBug" or monsterID == "Drake" or monsterID == "Eddga" or monsterID == "TurtleGeneral")
if isMvpBoss then
    local mDef = _G.MonsterData and _G.MonsterData[monsterID]
    local bossName = (mDef and mDef.Name) or monsterID
    local killerName = killerPlayer and killerPlayer.Name or "เหล่านักผจญภัย"
    local killerClass = killerPlayer and (killerPlayer:GetAttribute("Class") or "Adventurer") or "Adventurer"
    if RE_SkillFeedback then
        RE_SkillFeedback:FireAllClients(string.format("🏆 [MVP DEFEATED] บอส %s ถูกปราบแล้วโดย %s (%s)!", bossName, killerName, killerClass))
    end
    if _G.SpawnMvpTreasureChest then
        _G.SpawnMvpTreasureChest(monsterPos, monsterID, killerPlayer)
    end
end
```

---

### ข้อที่ 9: จุดซ้ำซ้อนหน้าต่าง UI ทับซ้อน และ Dead UI
* **ไฟล์ที่เกี่ยวข้อง**:
  * `src/client/RagnarokPanels.client.lua`
  * `src/client/ExpansionUI.client.lua`
  * `src/client/UIManager.client.lua`
  * `src/client/UI/WindowSystem.lua`
* **สาเหตุ**:
  * หน้าต่าง `Stats`, `Skills`, `TutorialOverlay` เดิมใน `WindowSystem.lua` ถูกแทนที่ด้วย `RagnarokPanels` และ `HelpWindow` ไปแล้ว แต่ `UIManager` ยังคงเรียก `windowSystem.renderStats(data)` ทุกวินาที
  * ใน `WindowSystem.lua` ฟังก์ชัน `renderInventory` สั่งลบและวาด Grid ช่องกระเป๋าใหม่ทั้งหมด พร้อม Clone โมเดลตัวละคร 3D ใน `ViewportFrame` ทุกครั้งที่ข้อมูลอัปเดต แม้หน้าต่างกระเป๋าจะปิดอยู่
  * ใน `ExpansionUI.client.lua` ปุ่มคีย์บอร์ด `B` (สมุดคู่มือนักผจญภัย) สั่งปิด `Visible = false` แทนที่จะเป็นการสลับเปิด/ปิด และไม่มีฟังก์ชันเปิดหน้าต่างเสียบการ์ด
  * ใน `RagnarokPanels.client.lua` บล็อกไม่ให้ลากสกิลกลุ่ม `isDebuff` (`LexAeterna`, `Quagmire`) วางลง Hotbar และปุ่มแนะนำสเตตัสตกหล่นอาชีพคลาส 2
* **วิธีแก้ & โค้ดที่เปลี่ยนแปลง**:
  1. `RagnarokPanels.client.lua`: เพิ่มอาชีพคลาส 2 ครบทุกสายใน `recommendBtn`, ปลดล็อกให้วางสกิล `isDebuff` บน Hotbar ได้, และลบโค้ดบล็อกที่ซ้ำซ้อน
  2. `ExpansionUI.client.lua`: แก้ไขปุ่ม `B` ให้เปิด/ปิดสมุดคู่มือนักผจญภัย & เรดาร์ MVP พร้อมรีเฟรชข้อมูลมอนสเตอร์ และเพิ่ม `_G.OpenCardSlottingUI` เพื่อเปิดหน้าต่างการ์ดเมื่อคลิกการ์ดในกระเป๋า
  3. `WindowSystem.lua`: ใน `renderInventory` เพิ่มการตรวจเช็ค `if inventoryWin and inventoryWin.Visible then` เพื่อไม่ให้วาดตารางและโคลนโมเดล 3D ขณะปิดกระเป๋า และลบการเรียก `InvokeServer()` ซ้ำซ้อน 2 ครั้งตอนกดเปิดกระเป๋า
  4. `UIManager.client.lua`: ลบการเรียก `windowSystem.renderStats(data)` ออก แล้วส่งผ่าน `_G.UpdateRagnarokData` ไปยัง RagnarokPanels แทน

---

### ข้อที่ 10: ปัญหา Performance — การส่งข้อมูลตัวละครทั้งก้อนทุก 1 วินาทีใน Regen Loop
* **ไฟล์ที่เกี่ยวข้อง**:
  * `src/server/GameManager.server.lua`
* **สาเหตุ**:
  * ใน `GameManager.server.lua` ฟังก์ชัน `StartRegenLoop` วนลูปทุก 1 วินาที และเรียก `DataStore.SyncAttributes(player, data)` พร้อมกับ `PushCharacterData(player)` ตลอดเวลา แม้ว่าค่า HP และ SP ของตัวละครจะเต็ม 100% อยู่แล้ว ส่งผลให้เซิร์ฟเวอร์ส่งข้อมูลขนาดใหญ่ข้ามเครือข่ายตลอดเวลาอย่างไร้ประโยชน์
  * ฟังก์ชัน `BindCharacterRespawn(player)` เรียกตัวเองซ้ำซ้อนในอีเวนต์ `CharacterAdded` และไม่ได้ถูกผูกใน `SetupPlayer`
* **วิธีแก้ & โค้ดที่เปลี่ยนแปลง**:
  * ใน `StartRegenLoop`: เพิ่มตัวแปร `local changed = false` และจะกำหนดเป็น `true` เมื่อมีการฟื้นฟูเลือดหรือ SP จริงเท่านั้น หากไม่มีค่าใดเปลี่ยน จะไม่เรียก `SyncAttributes` และ `PushCharacterData`
  * ใน `BindCharacterRespawn`: ลบการเรียกตัวเองซ้ำใน `CharacterAdded` ออก และนำ `BindCharacterRespawn(player)` ไปผูกใน `SetupPlayer(player)` อย่างเป็นระบบ
```lua
-- [หลังแก้ใน GameManager.server.lua]:
local function StartRegenLoop(player)
    ...
    local thread = task.spawn(function()
        local hpRegenElapsed = 0
        local spRegenAccumulator = 0
        while player.Parent ~= nil do
            task.wait(1)
            hpRegenElapsed += 1
            local data = DataStore.GetPlayerData(player)
            if not data then break end
            local derived = DataStore.CalcDerivedStats(data)
            local changed = false

            if hpRegenElapsed >= 10 and data.HP < derived.MaxHP then
                local newHP = math.min(data.HP + derived.HPRegen, derived.MaxHP)
                DataStore.SetHP(player, newHP)
                changed = true
            end
            if hpRegenElapsed >= 10 then hpRegenElapsed = 0 end

            if data.SP < derived.MaxSP then
                spRegenAccumulator += derived.SPRegen
                local wholeSP = math.floor(spRegenAccumulator)
                if wholeSP > 0 then
                    local newSP = math.min(data.SP + wholeSP, derived.MaxSP)
                    local restoredSP = newSP - data.SP
                    DataStore.SetSP(player, newSP)
                    spRegenAccumulator -= restoredSP
                    if newSP >= derived.MaxSP then spRegenAccumulator = 0 end
                    changed = true
                end
            else
                spRegenAccumulator = 0
            end

            -- ✅ ซิงค์และส่งข้อมูลตัวละครเฉพาะเมื่อมีค่าเปลี่ยนแปลงจริงเท่านั้น
            if changed then
                DataStore.SyncAttributes(player, data)
                PushCharacterData(player)
            end
        end
    end)
end
```

---

### ข้อเพิ่มเติม: การแก้ไข Scope ตัวแปรและ Forward Declaration ใน `CombatTargeting.lua`
* **ไฟล์ที่เกี่ยวข้อง**:
  * `src/client/UI/CombatTargeting.lua`
* **สาเหตุ**:
  * ตัวแปร `local autoAttackEnabled = false` เดิมถูกประกาศไว้ที่บรรทัด 396 ด้านล่างของไฟล์ แต่ในฟังก์ชัน `executeCast` (บรรทัด 145) มีการเช็ค `if not autoAttackEnabled` ทำให้ Lua มองเห็นเป็น Global variable ซึ่งได้ค่า `nil` ตลอดเวลา
  * ในฟังก์ชัน `refreshVisibleTargetFilters` มีการเรียก `if updatePotionInfoDisplay then updatePotionInfoDisplay() end` แต่ฟังก์ชัน `updatePotionInfoDisplay` เพิ่งถูกประกาศไว้ด้านล่างที่บรรทัด 792 ทำให้เงื่อนไขเป็น `nil` และไม่เคยรันจริง
* **วิธีแก้ & โค้ดที่เปลี่ยนแปลง**:
  1. ย้ายการประกาศ `local autoAttackEnabled = false` ขึ้นไปไว้ด้านบนก่อนฟังก์ชัน `cancelCast` และ `executeCast` แล้วที่บรรทัด 396 เปลี่ยนเป็นกำหนดค่า `autoAttackEnabled = false` (เอาคำว่า `local` ออก)
  2. ทำ Forward Declaration `local updatePotionInfoDisplay` ไว้ก่อนฟังก์ชัน `refreshVisibleTargetFilters` และเปลี่ยนบรรทัด 792 เป็น `updatePotionInfoDisplay = function()`

---

### ข้อเพิ่มเติม: การแก้ไขการเดินทับซ้อนบอท Auto-Battle และระบบกล้องใน `CameraController.client.lua`
* **ไฟล์ที่เกี่ยวข้อง**:
  * `src/client/CameraController.client.lua`
* **สาเหตุ**:
  * ฟังก์ชัน `updateMovement()` เดิมเรียก `hum:Move(move, false)` ทุกเฟรม แม้ว่าค่า `move` จะเป็น `Vector3.zero` (ผู้เล่นไม่ได้กดปุ่ม WASD) คำสั่งนี้จะไปลบล้าง (override) คำสั่ง `humanoid:MoveTo()` ของระบบบอท Auto-Battle หรือการคลิกเดิน ทำให้ตัวละครเดินสะดุดหรือยืนนิ่ง
  * ไม่มีการตรวจจับ `UserInputService:GetFocusedTextBox()` ทำให้เมื่อผู้เล่นพิมพ์แชทหรือพิมพ์ข้อความที่มีตัวอักษร W, A, S, D ตัวละครจะเดินไปเอง
  * ฟังก์ชัน `ShakeCam` ประกาศเป็น Global โดยไม่ใส่ `local` และใช้ `tick()`
  * ฟังก์ชัน `getSafeDistance` สร้างอินสแตนซ์ `RaycastParams.new()` ใหม่ทุกเฟรมใน `RenderStepped` ทำให้เกิดภาระ Memory Allocation / Garbage Collection โดยไม่จำเป็น
* **วิธีแก้ & โค้ดที่เปลี่ยนแปลง**:
  1. เพิ่มตัวแปร `local wasMovingManual = false` ตรวจสอบสถานะการกดเดินของผู้เล่น
  2. หากผู้เล่นกำลังโฟกัสกล่องข้อความ (`UserInputService:GetFocusedTextBox()`) ให้สั่งหยุดเดินครั้งเดียว (`hum:Move(Vector3.zero, false)`) หากก่อนหน้านี้กำลังเดินอยู่ แล้ว `return` ออกทันที
  3. สั่ง `hum:Move(move, false)` เฉพาะเมื่อ `move.Magnitude > 0.01` เท่านั้น และเมื่อปล่อยปุ่มเดิน ให้ส่งสัญญาณหยุดเพียงครั้งเดียว (`elseif wasMovingManual then hum:Move(Vector3.zero, false); wasMovingManual = false end`)
  4. ปรับ `ShakeCam` เป็น `local` พร้อม expose ผ่าน `_G.ShakeCam = ShakeCam` และใช้ `os.clock()`
  5. ประกาศ `camRaycastParams` ครั้งเดียวภายนอกฟังก์ชัน `getSafeDistance`

```lua
-- [ก่อนแก้ใน updateMovement]:
local move = Vector3.new(0, 0, 0)
if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + camFwd end
...
if move.Magnitude > 0.01 then
    move = move.Unit
    root.CFrame = CFrame.new(root.Position, root.Position + move)
end
hum:Move(move, false) -- สั่งทุกเฟรมแม้ move เป็น 0

-- [หลังแก้ใน updateMovement]:
local wasMovingManual = false
local function updateMovement()
    local hum  = getHumanoid()
    local root = getRoot()
    if not hum or not root then return end

    if UserInputService:GetFocusedTextBox() then
        if wasMovingManual then
            hum:Move(Vector3.zero, false)
            wasMovingManual = false
        end
        return
    end

    local yawRad    = math.rad(currentYaw)
    local camFwd    = Vector3.new(-math.sin(yawRad), 0, -math.cos(yawRad))
    local camRight  = Vector3.new( math.cos(yawRad), 0, -math.sin(yawRad))

    local move = Vector3.new(0, 0, 0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + camFwd   end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - camFwd   end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - camRight  end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + camRight  end

    if move.Magnitude > 0.01 then
        move = move.Unit
        root.CFrame = CFrame.new(root.Position, root.Position + move)
        hum:Move(move, false)
        wasMovingManual = true
    elseif wasMovingManual then
        hum:Move(Vector3.zero, false)
        wasMovingManual = false
    end
end
```

---

### ข้อเพิ่มเติม: การรองรับสกิลประเภทดีบัฟ (`isDebuff`) ใน `CombatSystem.server.lua`
* **ไฟล์ที่เกี่ยวข้อง**:
  * `src/server/CombatSystem.server.lua`
  * `src/server/MonsterAI.server.lua`
* **สาเหตุ**:
  * ในฟังก์ชัน `HandleSkillUse` เดิมเช็คเฉพาะ `if sData.isAttack then` เพื่อค้นหาและล็อกเป้าหมายมอนสเตอร์ (`targetMonster`) ทำให้สกิลที่เป็นประเภทดีบัฟ (`isDebuff = true`) เช่น `LexAeterna` และ `Quagmire` ไม่สามารถหาเป้าหมายมอนสเตอร์ได้
  * ในบล็อกการทำงานของสกิลมีเพียง `if sData.isAttack and targetMonster then` แต่ไม่มีบล็อกสำหรับประมวลผลดีบัฟ ทำให้การร่ายสกิลดีบัฟไม่ส่งผลลัพธ์ใดๆ ต่อมอนสเตอร์
* **วิธีแก้ & โค้ดที่เปลี่ยนแปลง**:
  1. ใน `HandleSkillUse` บรรทัด 1802 แก้เป็น `if sData.isAttack or sData.isDebuff then` เพื่อให้สกิลดีบัฟสามารถค้นหาและตรวจสอบเป้าหมายมอนสเตอร์ได้เหมือนสกิลโจมตี
  2. ต่อท้ายบล็อก `if sData.isAttack and targetMonster then` ด้วย `elseif sData.isDebuff and targetMonster then`:
     - หากเป็น `LexAeterna` จะติดสถานะ `StatusLexAeterna` บนตัวมอนสเตอร์ (ทำให้การโจมตีครั้งถัดไปสร้างความเสียหาย 2 เท่า และล้างสถานะออก)
     - หากเป็น `Quagmire` จะเรียก `ApplyStatusToMonster(targetMonster, "Slow", sData.debuffDuration or 15)`
  3. เพิ่มสถานะ `Slow` ในตาราง `STATUS_EFFECTS` และผูกการลด `MoveSpeed` 50% ให้กับ AI มอนสเตอร์ใน `MonsterAI.server.lua`
  4. เพิ่ม `ClearPlayerStatuses(player)` ใน `Players.PlayerRemoving` เพื่อล้างเธรดสถานะเมื่อผู้เล่นออกจากเซิร์ฟเวอร์ ป้องกัน Memory Leak

```lua
-- [จุดที่ 1: บรรทัด 1802 ใน HandleSkillUse]:
if sData.isAttack or sData.isDebuff then

-- [จุดที่ 2: ต่อท้ายบล็อก if sData.isAttack and targetMonster then]:
elseif sData.isDebuff and targetMonster then
    local centerRoot = targetMonster:FindFirstChild("HumanoidRootPart") or targetMonster.PrimaryPart
    local centerPos = centerRoot and centerRoot.Position or playerRoot.Position
    vfxTargetPos = centerPos
    if skillId == "LexAeterna" then
        targetMonster:SetAttribute("StatusLexAeterna", true)
    elseif skillId == "Quagmire" then
        ApplyStatusToMonster(targetMonster, "Slow", sData.debuffDuration or 15)
    end
end
```

---

### ข้อเพิ่มเติม: ธาตุ Poison, การตายจากพิษ, และพารามิเตอร์ UpdateInventory ใน `CombatSystem.server.lua`
* **ไฟล์ที่เกี่ยวข้อง**:
  * `src/server/CombatSystem.server.lua`
* **สาเหตุ**:
  * ในตาราง `ElementMultiplier` และ `ELEMENT_INDEX` ไม่มีธาตุ `"Poison"` ทั้งที่มีมอนสเตอร์ธาตุ Poison (เช่น Spider, PoisonSnake) ส่งผลให้การคิดดาเมจธาตุพิษผิดพลาด
  * เมื่อผู้เล่นโดนพิษจน `newHP <= 0` มีเพียงคำสั่ง `break` โดยไม่ได้เรียก `PlayerDied` ทำให้ผู้เล่น HP เป็น 0 แต่ไม่ตายจริงและไม่เกิดใหม่
  * เมื่อผู้เล่นกดเก็บของดรอป มีการเรียก `Remotes.UpdateInventory:FireClient(player, inventory, dropEntry.itemId, qty)` ซึ่งส่งพารามิเตอร์ผิดลำดับ/ผิดประเภท (Client คาดหวัง `inventory, equipment, alertMessage, equipmentRefine`) ทำให้ไม่แสดงข้อความเก็บของและไม่อัปเดตช่องสวมใส่
* **วิธีแก้ & โค้ดที่เปลี่ยนแปลง**:
  1. เพิ่มแถวและคอลัมน์ของธาตุ `Poison` เป็นลำดับที่ 10 ใน `ElementMultiplier` และระบุ `Poison = 10` ใน `ELEMENT_INDEX`
  2. ในลูปพิษของผู้เล่น เมื่อ `newHP <= 0` ให้เรียก `_G.MonsterAI.PlayerDied(player)` ก่อน `break`
  3. ปรับการเรียก `Remotes.UpdateInventory:FireClient` ส่ง `(player, inventory, pData.Equipment or {}, "เก็บ " .. itemInfo.name .. " x" .. qty, pData.EquipmentRefine or {})` ให้ถูกต้องครบถ้วน

```lua
-- [จุดที่ 1: ตารางธาตุ Poison]:
local ElementMultiplier = {
    --        Neutral  Fire  Water  Wind  Earth  Holy  Shadow  Ghost  Undead  Poison
    ...
    Poison  = { 1.0,   1.0,  1.0,   1.0,  1.0,   0.75, 0.5,    0.5,   0.5,    0.0  },
}
local ELEMENT_INDEX = {
    Neutral = 1, Fire = 2, Water = 3, Wind = 4,
    Earth = 5, Holy = 6, Shadow = 7, Ghost = 8, Undead = 9, Poison = 10,
}

-- [จุดที่ 2: การตายจากพิษ]:
if newHP <= 0 then
    if _G.MonsterAI and _G.MonsterAI.PlayerDied then
        _G.MonsterAI.PlayerDied(player)
    end
    break
end

-- [จุดที่ 3: พารามิเตอร์ UpdateInventory]:
if Remotes.UpdateInventory then
    local pData = DataStore.GetPlayerData(player)
    Remotes.UpdateInventory:FireClient(
        player,
        inventory,
        pData and pData.Equipment or {},
        "เก็บ " .. (itemInfo and itemInfo.name or dropEntry.itemId) .. " x" .. tostring(qty),
        pData and pData.EquipmentRefine or {}
    )
end
```

---

### ข้อเพิ่มเติม: การเพิ่มไอเทม GoldRing และแก้ Alias ไม่ให้คัดลอกซ้ำใน `ItemData.lua`
* **ไฟล์ที่เกี่ยวข้อง**:
  * `src/shared/ItemData.lua`
* **สาเหตุ**:
  * บอส MVP `GoldenThiefBug` ใน `MonsterData.lua` มีการกำหนดไอเทมดรอปคือ `GoldRing` แต่ในฐานข้อมูล `ItemData.lua` ไม่มีไอเทมนี้ ส่งผลให้เมื่อบอสตายและสุ่มตกไอเทม เกิด Warning/Nil Error หรือไอเทมไม่มีชื่อ/ข้อมูล
  * ตัวแปร Alias `Iron_Ore` และ `Sticky_Mucus` ใช้วิธีสร้างตารางข้อมูล `{ name = ..., type = ... }` ขึ้นมาใหม่ซ้ำซ้อนกับ `IronOre` และ `StickyMucus`
* **วิธีแก้ & โค้ดที่เปลี่ยนแปลง**:
  1. เพิ่มข้อมูลไอเทม `GoldRing` ในตาราง `ItemData`
  2. เปลี่ยน Alias `Iron_Ore` และ `Sticky_Mucus` เป็นการชี้ไปยังออบเจกต์ต้นฉบับโดยตรง (`ItemData.Iron_Ore = ItemData.IronOre`, `ItemData.Sticky_Mucus = ItemData.StickyMucus`) ไม่สร้างตารางซ้ำซ้อน

```lua
-- [เพิ่ม GoldRing ใน ItemData]:
GoldRing = { name = "Gold Ring", type = "Material", sellPrice = 1500, description = "แหวนทองคำล้ำค่าจากรังแมลงทองคำ" },

-- [ปรับการอ้างอิง Alias]:
ItemData.Iron_Ore = ItemData.IronOre
ItemData.Sticky_Mucus = ItemData.StickyMucus
```

---

### ข้อเพิ่มเติม: การซิงค์ข้อมูลกิลด์ (MyGuild / GuildList / RequestSync) ใน `GuildSystem.server.lua`
* **ไฟล์ที่เกี่ยวข้อง**:
  * `src/server/GuildSystem.server.lua`
* **สาเหตุ**:
  * ฟังก์ชัน `serializeGuildsForClient` คืนค่าตาราง `{ myGuildId = ..., guilds = list }` แต่ฝั่งไคลเอนต์ (`ExpansionUI.client.lua`) อ่านจาก `payload.MyGuild` (ออบเจกต์กิลด์ของผู้เล่น) และ `payload.GuildList` (รายการกิลด์ทั้งหมด) ทำให้เมื่อเปิดหน้าต่างกิลด์ ไม่แสดงข้อมูลกิลด์ที่ตนเองอยู่และไม่แสดงรายชื่อกิลด์
  * ฝั่งไคลเอนต์ส่งคำสั่ง `GuildAction:FireServer("RequestSync")` เมื่อเปิดหน้ากิลด์ แต่ใน `RE_GuildAction.OnServerEvent` ไม่รองรับแอ็กชัน `"RequestSync"` ทำให้ไม่ส่งข้อมูลกลับไป
  * ค่าธรรมเนียมการตั้งกิลด์ใน Server คิด 100 Zeny แต่บนปุ่ม UI แสดง 500z
* **วิธีแก้ & โค้ดที่เปลี่ยนแปลง**:
  1. ใน `serializeGuildsForClient` ค้นหาข้อมูลกิลด์ของผู้เล่นและส่งฟิลด์ `MyGuild = myGuildObj` และ `GuildList = list` กลับไปให้ตรงกับ Client
  2. ใน `RE_GuildAction.OnServerEvent` เพิ่มการเช็ค `if action == "RequestSync" then RE_GuildUpdated:FireClient(player, serializeGuildsForClient(player)); return end`
  3. ปรับค่าสร้างกิลด์ใน Server เป็น 500 Zeny ให้ตรงกับ UI

```lua
-- [จุดที่ 1: การคืนค่าใน serializeGuildsForClient]:
table.sort(list, function(a, b) return a.houseLevel > b.houseLevel end)
local myGuildObj = nil
for _, gInfo in ipairs(list) do
    if gInfo.id == myGuildId then
        myGuildObj = gInfo
        break
    end
end
return {
    myGuildId = myGuildId,
    guilds    = list,
    MyGuild   = myGuildObj,
    GuildList = list,
}

-- [จุดที่ 2: การรองรับ RequestSync]:
if action == "RequestSync" then
    RE_GuildUpdated:FireClient(player, serializeGuildsForClient(player))
    return
end
```

---

### ข้อเพิ่มเติม: การซ่อนผังตึกเมือง Prontera เมื่ออยู่แมพอื่น และแก้ชื่อ TurtleGeneral ใน `MinimapView.lua`
* **ไฟล์ที่เกี่ยวข้อง**:
  * `src/client/UI/MinimapView.lua`
* **สาเหตุ**:
  * บล็อกอาคารเมือง Prontera (`PRONTERA_CITY_BLOCKS`) ถูกวาดและแสดงผลบนมินิแมพตลอดเวลา แม้ผู้เล่นจะเดินทางไปแมพอื่น เช่น Morroc, Amatsu หรือ PronteraCulvert
  * ในการตรวจสอบบอสโลก มีการเช็ค `mId == "Turtle_General"` (มีขีดล่าง `_`) ซึ่งไม่ตรงกับไอดี `"TurtleGeneral"` ใน `MonsterData.lua` ส่งผลให้ไม่แสดงไอคอนบอสสีแดงบนมินิแมพ
* **วิธีแก้ & โค้ดที่เปลี่ยนแปลง**:
  1. เพิ่มตัวแปร `currentMap = player:GetAttribute("Map") or "Prontera"` และ `isProntera = (currentMap == "Prontera")` แล้วกำหนด `f.Visible = isProntera` หากไม่ใช่แมพ Prontera ให้ซ่อนกรอบตึกทันที
  2. แก้ไขเงื่อนไขการตรวจจับ World Boss จาก `Turtle_General` เป็น `TurtleGeneral`

```lua
-- [จุดที่ 1: ซ่อนบล็อกอาคารเมื่อไม่ได้อยู่ Prontera]:
local currentMap = player:GetAttribute("Map") or "Prontera"
local isProntera = (currentMap == "Prontera")
for idx, block in ipairs(PRONTERA_CITY_BLOCKS) do
    local f = cityBlockFrames[idx]
    if f then
        f.Visible = isProntera
        if isProntera then
            local diff = block.pos - playerPos
            local nx = (diff.X / MINIMAP_RANGE) * 0.5 + 0.5
            local nz = (diff.Z / MINIMAP_RANGE) * 0.5 + 0.5
            local sw = (block.size.X / MINIMAP_RANGE) * 0.5 * 160
            local sh = (block.size.Y / MINIMAP_RANGE) * 0.5 * 160
            f.Position = UDim2.new(nx, -sw / 2, nz, -sh / 2)
            f.Size = UDim2.new(0, sw, 0, sh)
        end
    end
end

-- [จุดที่ 2: แก้ชื่อ TurtleGeneral]:
local isWorldBoss = obj:GetAttribute("IsWorldBoss") or mId == "Eddga" or mId == "TurtleGeneral"
```

---

### ข้อเพิ่มเติม: การรองรับสกิลคลาส 1 บน Hotbar เมื่อเลื่อนขั้นเป็นคลาส 2 ใน `HotbarView.lua`
* **ไฟล์ที่เกี่ยวข้อง**:
  * `src/client/UI/HotbarView.lua`
* **สาเหตุ**:
  * ในฟังก์ชัน `renderHotbar` มีการตรวจสอบเงื่อนไขแสดงสกิลบน Hotbar ด้วย `(def.class == class or def.class == "Novice")`
  * เมื่อผู้เล่นเลื่อนขั้นเป็นคลาส 2 (เช่น LordKnight, Wizard, Priest, Hunter, Assassin, Blacksmith) ค่า `class` ของผู้เล่นจะเปลี่ยนเป็นชื่อคลาสใหม่ ทำให้สกิลของคลาสเดิม (เช่น สกิลคลาส Knight หรือ Mage) ไม่เข้าเงื่อนไข และหายไปจากแถบ Hotbar
* **วิธีแก้ & โค้ดที่เปลี่ยนแปลง**:
  1. เพิ่มการ require โมดูล `ClassData` ใน `HotbarView.lua`
  2. แก้ไขเงื่อนไขการอนุญาตใช้งานสกิลใน `renderHotbar` โดยใช้ `classData.CanLearnSkill(class, def.class)` ตรวจสอบสายอาชีพ ทำให้คลาส 2 สามารถนำสกิลของคลาส 1 มาใส่บน Hotbar ใช้งานได้อย่างต่อเนื่อง

```lua
-- [จุดที่แก้ใน renderHotbar]:
for sId, sLv in pairs(owned) do
    local def = skillData[sId]
    local canUse = (def and (def.class == class or def.class == "Novice" or (classData and classData.CanLearnSkill and classData.CanLearnSkill(class, def.class))))
    if (tonumber(sLv) or 0) > 0 and def and not def.isPassive and canUse then
        local alreadyInBar = false
        for idx = 1, 8 do
            if skillByClass[class][idx] == sId then
                alreadyInBar = true
                break
            end
        end
        if not alreadyInBar then
            for idx = 1, 8 do
                if not skillByClass[class][idx] then
                    skillByClass[class][idx] = sId
                    break
                end
            end
        end
    end
end
```

---

## สรุปรายการไฟล์ทั้งหมดที่ได้รับการแก้ไขในโปรเจกต์ (21 ไฟล์)

1. `d:\Robox\project01\src\shared\ClassData.lua`
2. `d:\Robox\project01\src\shared\ItemData.lua`
3. `d:\Robox\project01\src\server\DataStore.server.lua`
4. `d:\Robox\project01\src\server\GameManager.server.lua`
5. `d:\Robox\project01\src\server\CombatSystem.server.lua`
6. `d:\Robox\project01\src\server\MonsterAI.server.lua`
7. `d:\Robox\project01\src\server\GuildSystem.server.lua`
8. `d:\Robox\project01\src\server\JobAdvancementSystem.server.lua`
9. `d:\Robox\project01\src\server\PvPArenaSystem.server.lua`
10. `d:\Robox\project01\src\server\DungeonAndMvpSystem.server.lua`
11. `d:\Robox\project01\src\server\WorldMapExpansion.server.lua`
12. `d:\Robox\project01\src\client\CameraController.client.lua`
13. `d:\Robox\project01\src\client\ExpansionUI.client.lua`
14. `d:\Robox\project01\src\client\CombatVFX.client.lua`
15. `d:\Robox\project01\src\client\RagnarokPanels.client.lua`
16. `d:\Robox\project01\src\client\UIManager.client.lua`
17. `d:\Robox\project01\src\client\UI\WindowSystem.lua`
18. `d:\Robox\project01\src\client\UI\CombatTargeting.lua`
19. `d:\Robox\project01\src\client\UI\MinimapView.lua`
20. `d:\Robox\project01\src\client\UI\HotbarView.lua`
21. `d:\Robox\project01\reportcode_gemini.md` (อัปเดตมาร์กเกอร์ [✅ แก้ไขแล้ว] ครบทุกจุด)

---
*จัดทำและตรวจสอบความถูกต้องโดย Antigravity AI Assistant*
