# RoROK — สรุปสถานะโครงการและคู่มือส่งต่องาน

อัปเดต 20 ต.ค. 2026  
โปรเจกต์: `D:\Robox\project01`  
จุดประสงค์: ให้ Codex, Claude หรือผู้พัฒนาคนถัดไปเปิดแล้วรู้ว่ามีอะไรอยู่ตรงไหน กดใช้ยังไง และต้องทำอะไรต่อ

> สรุปนี้อิงซอร์สและเอกสารในโฟลเดอร์โครงการ รวมถึงผลทดสอบที่ผู้เล่นรายงานในบทสนทนา การที่โค้ดมีอยู่ไม่ได้แปลว่ารันผ่านใน Studio ทุกข้อ

## สถานะรวมและเปอร์เซ็นต์

- Checklist มี 74 รายการ: ทำเครื่องหมายผ่าน 32 รายการ (43%), ยังไม่ยืนยัน/รอทดสอบ 42 รายการ (57%). ตัวเลขนี้คือสัดส่วนรายการทดสอบที่ทำเครื่องหมายไว้ ไม่ใช่เปอร์เซ็นต์ความสมบูรณ์ของเกม
- ระบบแกนหลักของเดโม (ตัวละคร, สถานะ, ต่อสู้, มอน, เควส, กระเป๋า, ร้าน, ปาร์ตี้, UI) มีโค้ดใช้งานแล้ว และหลายส่วนผู้เล่นเคยยืนยันผ่าน
- ระบบเกมสำหรับเดโมโดยรวมประเมินคร่าว ๆ **ประมาณ 70%**: ฟีเจอร์พื้นฐานมีแล้ว แต่ยังมีข้อทดสอบค้าง, persistence/หลายเซิร์ฟเวอร์ และ polish
- งานเมืองตามแบบ 1,200 × 900: **ประมาณ 15–20%**. ตอนนี้เป็น Prontera starter plaza ขนาดเล็กกับบ้าน/แลนด์มาร์ก low-poly บางส่วน ยังไม่ใช่เมืองขนาดเต็ม, ไม่มีผังอำเภอ/กำแพง/ท่าเรือครบตามขนาด
- สถานะล่าสุดที่กำลังทำ: ขยายภาพและผังเมืองให้เป็นเมืองแฟนตาซียุคกลางที่น่าเดิน โดยใช้ชิ้นส่วนซ้ำ/แอสเซ็ตบ้านที่ตรวจแล้ว ไม่ทำให้จุดเกิด, NPC, ถนนฝึก และระบบเดิมพัง
- ไฟล์ที่เปิดอยู่ใน Studio อาจไม่ใช่ซอร์สล่าสุด การเปิด `.rbxl` ค้างไว้ไม่ได้ซิงก์เองถ้า Rojo ไม่เชื่อมต่อ

## วิธีเปิดและซิงก์งาน

1. เปิด Roblox Studio place ที่ต้องการทำงาน
2. เปิด Rojo plugin ใน Studio แล้ว Connect ไปยัง `localhost:34872`
3. ถ้า Rojo server ไม่ทำงาน ให้เปิด `D:\Robox\project01\Start-Rojo-Serve.cmd`
4. ใช้ Play/Stop ใน Studio เพื่อทดสอบ; การแก้ไฟล์ใน `src\` จะ sync เมื่อเชื่อม Rojo
5. หากจะทดสอบ DataStore จริง ต้อง Publish place แบบ private และเปิด **Game Settings → Security → Enable Studio Access to API Services**
6. อย่า Publish เกมจริงจากไฟล์ทดสอบโดยไม่ตรวจ diff/การตั้งค่า

Rojo project mapping อยู่ที่ `default.project.json`: `src/shared` → ReplicatedStorage/GameData, `src/server` → ServerScriptService, `src/client` → StarterPlayerScripts

## การควบคุมที่ผู้เล่นใช้

- `C`: เปิดหน้าต่างสถานะ/ค่าสเตตัสและจัดสรรค่าสเตตัส; ใน Studio มีปุ่มทดสอบ Job EXP สำหรับข้ามไปเลือกอาชีพ
- `E`: เปิด/ปิดกระเป๋า; ปุ่มบนจอใช้ได้ด้วย
- `F`: เก็บของดรอป หรือคุย/โต้ตอบ NPC, กระดาน, ร้านและบริการ
- `J`: เปิดเควสประจำวัน; มีปุ่มเควสบนจอ
- `1` เป็นต้นไป: ใช้สกิลตาม Hotbar
- คลิกมอน: เลือกเป้าหมายและวิ่งเข้าไปโจมตี; วงแดงใต้เท้าคือเป้าหมาย
- `Auto`: เปิด/ปิดการโจมตีอัตโนมัติ; ปุ่มเฟืองตั้งชนิดมอน, All และลำดับ basic attack/skill แยกตามอาชีพ
- ปุ่ม Party ใต้ roster: สร้าง/เชิญ/ตอบรับ/ปฏิเสธ/ออกจากปาร์ตี้
- ในกระเป๋า: ใช้/สวม/ถอดไอเท็มตามชนิด; ตีบวกทำที่ NPC ช่างตีเหล็ก ไม่ใช่จากกระเป๋า
- ร้านยา: กด F ที่แผงร้าน; ซื้อยาและใช้จากกระเป๋า
- ตลาดกลาง: กด F ที่ NPC/แผงตลาด; เปิดแท็บซื้อ/ประมูล/ลงขาย/ของฉัน
- ช่างคราฟต์: กด F แล้วเลือกสูตร; ต้องมีวัตถุดิบและ Zeny

## ฟีเจอร์ที่มีและตำแหน่งซอร์ส

### ตัวละคร, ข้อมูล, ค่าสเตตัส, XP
- `src/server/DataStore.server.lua`: สร้าง/โหลด/บันทึกข้อมูลผู้เล่น, ค่า derived stats, HP/SP/XP/เงิน/ของ, โบนัสอุปกรณ์, API ข้อมูลให้สคริปต์อื่น
- `src/server/GameManager.server.lua`: รวมการสื่อสาร client-server, RemoteEvents, เลือกอาชีพ, จัดสรรค่าสเตตัส, เลือกเป้าหมาย/เริ่มโจมตี/สกิล/กระเป๋า
- `src/shared/ClassData.lua`: อาชีพและค่าสเตตัส/การโจมตีพื้นฐาน
- HUD แสดง XP เป็นเปอร์เซ็นต์และความยาวแถบ, HP/SP, hotbar และ roster ปาร์ตี้
- DataStore local ไม่ยืนยันการเซฟถาวรจนกว่าจะทดสอบบน place ที่ Publish + API Services

### ต่อสู้และมอน
- `src/server/CombatSystem.server.lua`: สูตร physical/magic damage, hit/crit/element/status, ดาเมจผู้เล่น/มอน, ตาย/XP/drop/respawn, สกิล
- `src/server/MonsterAI.server.lua`: spawn/aggro/ไล่/โจมตี/กลับจุดเกิด/ฟื้น HP/เขตเมืองปลอดภัย
- `src/shared/MonsterData.lua`, `SkillData.lua`: ข้อมูลมอนและสกิล
- ผู้เล่นยืนยันก่อนหน้าว่า: อาชีพและสกิลใช้ค่าสเตตัสสายที่เหมาะ, Archer ยิงไกล, วงโจมตี/วงเล็ง, Auto ล็อกเป้าจนตาย, เลือกชนิดมอน/All, ลำดับสกิลแยกอาชีพ, AGI เพิ่ม ASPD, ข้อความดาเมจที่รับ, ป้องกันเกิดใหม่, SP regen
- ระยะเลือกเป้า/Auto ใช้ 50 studs พร้อมตรวจสิ่งบัง; การแสดงโลกปกติแยกจากระยะหาเป้า
- ข้อจำกัดโค้ดที่บันทึกไว้: AI ปัจจุบันเคลื่อนที่บนระนาบ X/Z โดยคงระดับ Y จุดเกิด ยังไม่ใช่ Pathfinding เต็ม อาจติดสิ่งก่อสร้าง/พื้นต่างระดับ; safe-zone ผูกกับขอบเขตแผนที่ปัจจุบัน
- ยังมี R24: วงล็อกใต้เท้ามอนต้องตรวจซ้ำหลัง sync ว่าแนบพื้นและไม่เป็นหยัก/ลอย

### UI, กล้อง, อินเวนทอรี
- `src/client/UIManager.client.lua`: HUD หลัก, party roster, XP, hotbar, inventory, skill input/selection, Auto และหน้าต่างต่าง ๆ
- `src/client/CameraController.client.lua`: กล้องผู้เล่น/feedback
- ผู้เล่นรายงานว่า B เปิดกระเป๋าได้ แต่เปลี่ยนคีย์หลักเป็น E; UI บนจอเปิดได้
- ล่าสุด checklist ยังมี U1 retest HUD หลังเริ่ม Play ใหม่

### เควสประจำวัน
- `src/server/DailyQuestSystem.server.lua`, `src/shared/DailyQuestData.lua`: กระดาน/รับเควส/ติดตาม/รับรางวัล
- มีเควสล่ามอนและเก็บของ; ผู้เล่นเคยยืนยันการเปิด/รับเควสใช้งานได้
- มีการแก้การเปลี่ยนวันเป็นเวลาไทย UTC+7; D1 ยังต้องทดสอบข้ามเที่ยงคืน/เวลา mock

### ร้าน, ไอเท็ม, อุปกรณ์, ตีบวก
- `src/server/TownShop.server.lua`, `src/shared/ItemData.lua`: ร้านยา, ซื้อ/ป้องกันเงินไม่พอ, ใช้ Red/Blue Potion, HP/SP cap; ซื้อ/ใช้เคยผ่าน
- `src/server/DataStore.server.lua`: starter equipment, equip/unequip, class weapon rules, stat bonuses/refinement level
- Refinement UI/handlers อยู่ใน `src/client/UIManager.client.lua` และ `src/server/GameManager.server.lua`/DataStore; เปิดบริการที่ NPC ช่างตีเหล็กด้วย F
- ผู้เล่นเคยยืนยันเปิดบริการ, ตีบวกเริ่มต้นและโบนัส ATK/DEF; E11/E12/E13 และตำแหน่ง prompt ยังต้องตรวจ
- persistence อุปกรณ์/ไอเท็ม/เงินต้องทดสอบ place Publish

### ปาร์ตี้
- `src/server/PartySystem.server.lua`, `src/client/PartyUI.client.lua`, roster ใน `UIManager.client.lua`
- มีสร้างปาร์ตี้, เชิญ/ตอบรับ/ปฏิเสธ, จำกัด 5 คน, ออก/เปลี่ยนหัวหน้า (ดู P1–P5)
- ข้อตกลงล่าสุด: XP แชร์ให้สมาชิกในแผนที่เดียวกันแม้ห่างกัน; คนละแผนที่ไม่ได้ XP. เช็ก map โดยข้อมูล `Player.Map` กับ `Monster.MapName`; แผนที่ใหม่ต้องกำหนดค่าให้ตรง
- P6 ต้องทดสอบซ้ำเรื่อง XP และ level gap 0/10/20; โค้ดใช้ตัวคูณ ไม่ได้แบ่ง XP เป็นก้อนหารต่อสมาชิก

### คราฟต์และตลาดกลาง
- `src/server/CraftingSystem.server.lua`, `src/client/CraftingUI.client.lua`: สูตร Poring Hood และ Four-Leaf Apprentice Rod, เช็ก/หักวัตถุดิบ/เงินฝั่ง server, ให้ของ
- `src/shared/MarketData.lua`, `src/server/MarketSystem.server.lua`, `src/client/MarketUI.client.lua`: ซื้อขายตั้งราคา, ประมูล, ยกเลิก, mailbox/offline delivery, DataStore snapshot
- ตลาดมาจากชุด Claude ที่รวมจาก `newro.zip`; โค้ดอยู่ใน src แต่ checklist M1–M9 ยังไม่ได้ทดสอบใน Studio; M10 ข้ามหลาย Roblox server ยังไม่รองรับอย่างปลอดภัย จึงถือเป็นระบบทดลองเท่านั้น

### ลานประลองเกียรติยศ Prontera PvP Arena (Phase 4)
- `src/server/PvPArenaSystem.server.lua`, `src/client/PvPArenaUI.client.lua`:
  - สังเวียนโคลอสเซียม ณ พิกัด `(0, 48, 1500)` เส้นผ่านศูนย์กลาง 140 studs พร้อมเสาหิน 16 ต้น คบเพลิง และธงศึก
  - แท่นปลอดภัย Hall of Champions (Safe Zone Z > 1546) คุ้มกันด้วย ForceField พร้อมประตูมิติกลับ Prontera
  - NPC ผู้คุมลานประลอง `PvPGatekeeper` ประจำเมือง Prontera พิกัด `(16, 3, 18)` ข้างน้ำพุ
  - สูตร PvP 0.55x Normal DMG, คลิกเลือกเป้าหมายผู้เล่นคนอื่นผ่าน `CombatTargeting.lua` มีวงแหวนสีแดงใต้เท้า
  - ระบบ Kill Streak (Double Kill, Killing Spree, Rampage, Dominating, GODLIKE)
  - รางวัลผู้ชนะ +50 แต้ม PvP (+15/streak) และ +350 Zeny (+50/streak)
  - กฎ Zero EXP Loss: พ่ายแพ้ไม่เสีย EXP เกิดใหม่ใน Safe Zone อัตโนมัติใน 2.2 วินาที
  - แถบสถานะ PvP StatusBar, ป้ายประกาศ Kill Banner สไลด์ลงจากด้านบนพร้อมเสียง และ Leaderboard [P] จัดอันดับ Top 20

### เมือง/ฉาก
- `src/server/StarterMap.server.lua`: สร้างฉากเมืองเริ่มต้นตอน server เริ่มเกม—ลาน, ถนน, น้ำพุ/คริสตัล, ประตู/อาคารแลนด์มาร์ก, โรงแรม, ตลาด, NPC/บริการ, บ้าน low-poly ห้าหลัง, โคม, ป้าย, สวน; รายละเอียดล่าสุดเพิ่มกรอบไม้/หน้าต่าง/บานเกล็ด/กล่องดอกไม้/แนวหลังคา/สินค้าแผง
- `src/shared/MedievalHouse.rbxm`: โมเดลบ้าน Medieval House ฟรีที่บันทึกจาก Creator Store เข้าโปรเจกต์; ตรวจไฟล์ดิบแล้วไม่พบ Script/LocalScript/ModuleScript หรือข้อความ require/loadstring/InsertService (ตรวจระดับไฟล์ ไม่ใช่การรับประกันความปลอดภัยจาก Roblox)
- `RoROK-fantasy-town-test.rbxlx`: snapshot เมืองเล็กชุดเดิม; `RoROK-city-scale-test.rbxl`: place ทดสอบที่ถูกสร้างระหว่างทดลองนำเข้าบ้าน อย่าใช้เป็นตัวอ้างอิงหลักก่อนตรวจใน Studio เพราะรอบนั้นมีบ้านจากการ insert ซ้ำซ้อนใน place
- สเกล 1,200×900, ปราสาท/กำแพง/ท่าเรือ และผังถนนตามภาพยังไม่ได้สร้างครบ; การนำเข้าโมเดลอย่างเดียวไม่เท่ากับประกอบเมืองใหญ่ให้สำเร็จ

## โครงไฟล์แบบเร็ว

- `src/server/`: โค้ด authoritative ฝั่งเกม
- `src/client/`: ปุ่ม, HUD, หน้าต่าง, input
- `src/shared/`: ตารางข้อมูลและ asset ที่แชร์
- `default.project.json`: mapping สำหรับ Rojo
- `Start-Rojo-Serve.cmd`: เปิด live sync ที่พอร์ต 34872
- `README.md`: วิธีรันและภาพรวมเดิม
- `TEST_CHECKLIST_TH.md`: ผลยืนยันจากผู้เล่นกับข้อทดสอบที่ยังเปิด
- `RoROK_HANDOFF_codex.md`: handoff ก่อนหน้านี้
- `MARKET_NOTES_TH.md`: ขอบเขต/ความเสี่ยงตลาด
- ถ้าส่งงานให้ Claude ต่อ ให้แนบ `src/` ทั้งโฟลเดอร์, `default.project.json`, `README.md`, `RoROK_HANDOFF_codex.md`, `TEST_CHECKLIST_TH.md`, เอกสารสรุปฉบับนี้ และไฟล์/ภาพใหม่ที่เกี่ยวข้อง; ไม่ต้องส่ง `.rbxl` เว้นแต่ Claude ต้องดูฉากใน Studio โดยตรง

## งานที่ต้องทำต่อ เรียงตามลำดับ

1. **ยืนยันไฟล์หลักและสร้าง snapshot สะอาด**: เปิด `RoROK-fantasy-town-test.rbxlx` หรือ build จาก Rojo; ตรวจว่าไม่ใช้ `RoROK-city-scale-test.rbxl` ที่อาจมีบ้านซ้อน
2. **ทดสอบเปิดเกมหลัง sync**: Play; ตรวจ Output ว่า HUD, NPC, ร้าน, เควส, มอน และระบบไม่ error; ทำ U1/S1 retest และ R24
3. **ทำเมืองให้เห็นเป็นโครงจริง**: กำหนดศูนย์กลางและเขตเมืองบน grid ตามผัง 1200×900 studs (ค่าที่ผู้ใช้ให้เรียกเมตรควรแปลง/ยืนยัน เพราะ Roblox ใช้ studs); วางถนนหลัก/รอง/ตรอกต่อเนื่อง, plaza, market, residential blocks, church, palace district, wall/gates, river/harbor
4. **ประกอบ asset อย่างปลอดภัยและจัดสเกล**: ใช้บ้าน MedievalHouse เป็น template หลังตรวจชั้น/ขนาด/จุด pivot; เพิ่มบ้าน/ร้านหลายแบบให้มี variation, ใช้ asset-free Creator Store เพิ่มเฉพาะที่จำเป็น; จัด collision/anchor/optimization; ห้ามกองหรือซ้อนโมเดลที่ origin
5. **รักษา gameplay**: วง spawn/NPC เดิม/ทางเข้า training ต้องเข้าถึงได้; ย้ายเขต safe-zone และ spawn/monster bounds ให้สัมพันธ์กับเมืองใหม่; AI ต้องไม่ทะลุกำแพง/อาคารเมื่อเดินไกล
6. **ทดสอบภาพและการเดินใน Studio**: ภาพจุดเกิด, มุมสูง, ถนน, บ้าน, ตลาด, โบสถ์/ปราสาท, harbor; เดินวิ่ง 1–2 นาทีเพื่อหาจุดติด/เฟรมตก; ถ่ายภาพแล้วอัปเดต V1–V8
7. **ปิด checklist ระบบ**: E11–E13/E8a, S7–S12, D1, P1–P6, C tests, M1–M9, persistence. ห้ามนับระบบว่าเสร็จเพียงเพราะโค้ด compile
8. **ก่อนใช้งานจริง**: เพิ่ม cross-server market coordination/locking หรือปิดตลาดข้ามเซิร์ฟเวอร์ไว้; ตั้ง DataStore/place/private tests; ตรวจ exploit/server validation

## แหล่งอ้างอิงหลักที่ส่งต่อ

- เอกสารนี้เป็นสรุปสถานะปัจจุบัน; เช็กลิสต์ละเอียดและผลทดสอบอยู่ใน `TEST_CHECKLIST_TH.md`
- ระบบ/วิธีเปิดดูโค้ดให้ค้นชื่อไฟล์ตามหัวข้อด้านบน; เริ่มหาจุดทำงานด้วยชื่อ event และฟังก์ชันในไฟล์ ไม่ย้าย handler ไป client เพราะต้องตรวจความถูกต้องฝั่ง server
- ก่อนแก้เมืองให้อ่าน `src/server/StarterMap.server.lua` และขอบเขตใน `src/server/MonsterAI.server.lua`
- ก่อนแก้ระบบข้อมูลให้ตรวจ `DataStore.server.lua` กับ API `_G.DataStore` ที่สคริปต์อื่นเรียก
