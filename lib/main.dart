import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// ─── password admin ───────────────────────────────
const String kAdminPassword = 'zoo1234';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

// ─── Firestore helper ─────────────────────────────
final _db = FirebaseFirestore.instance;

// อัปโหลดข้อมูลเริ่มต้นขึ้น Firestore (ทำครั้งเดียว)
Future<void> seedFirestore() async {
  final col = _db.collection('feedingSchedule');
  final snap = await col.limit(1).get();
  if (snap.docs.isNotEmpty) return; // มีข้อมูลแล้วข้ามไป
  for (final item in feedingScheduleDefault) {
    await col.add({
      'name': item['name'],
      'emoji': item['emoji'],
      'type': item['type'],
      'weekday': item['weekday'],
      'weekend': item['weekend'],
      'active': true,
    });
  }
}

const List<Map<String, dynamic>> locations = [
  {'id': 1,  'name': 'Welcome Center',      'emoji': '👋', 'hasToilet': false, 'hasParking': false, 'waypoint': 1,  'lat': 16.845921, 'lng': 102.895570},
  {'id': 2,  'name': 'โชว์แมวน้ำ',          'emoji': '🦭', 'hasToilet': false, 'hasParking': false, 'waypoint': 4,  'lat': 16.845856, 'lng': 102.894745},
  {'id': 3,  'name': 'สถานีหมี',            'emoji': '🐻', 'hasToilet': false, 'hasParking': true,  'waypoint': 8,  'lat': 16.845275, 'lng': 102.893380},
  {'id': 4,  'name': 'กรงนกใหญ่',           'emoji': '🦜', 'hasToilet': false, 'hasParking': true,  'waypoint': 12, 'lat': 16.844580, 'lng': 102.892960},
  {'id': 5,  'name': 'สถานีลิง',            'emoji': '🐒', 'hasToilet': true,  'hasParking': true,  'waypoint': 18, 'lat': 16.842620, 'lng': 102.892117},
  {'id': 6,  'name': 'สถานีคาปิบาร่า',      'emoji': '🐹', 'hasToilet': true,  'hasParking': true,  'waypoint': 30, 'lat': 16.843490, 'lng': 102.891584},
  {'id': 7,  'name': 'สถานีฮิปโปเล็ก',     'emoji': '🦛', 'hasToilet': true,  'hasParking': true,  'waypoint': 35, 'lat': 16.842769, 'lng': 102.894388},
  {'id': 8,  'name': 'สถานีเสือ',           'emoji': '🐯', 'hasToilet': true,  'hasParking': true,  'waypoint': 38, 'lat': 16.843329, 'lng': 102.893196},
  {'id': 9,  'name': 'สถานีเพนกวิน/ฮิปโป', 'emoji': '🐧', 'hasToilet': true,  'hasParking': true,  'waypoint': 48, 'lat': 16.840716, 'lng': 102.894128},
  {'id': 10, 'name': 'สถานีแร้ง',           'emoji': '🦅', 'hasToilet': false, 'hasParking': false, 'waypoint': 54, 'lat': 16.840324, 'lng': 102.896682},
  {'id': 11, 'name': 'สถานีเลียงผา',        'emoji': '🐐', 'hasToilet': false, 'hasParking': true,  'waypoint': 56, 'lat': 16.840675, 'lng': 102.897894},
  {'id': 12, 'name': 'สถานีจิงโจ้แดง',      'emoji': '🦘', 'hasToilet': true,  'hasParking': true,  'waypoint': 58, 'lat': 16.841918, 'lng': 102.895329},
  {'id': 13, 'name': 'สถานีกวาง',           'emoji': '🦌', 'hasToilet': true,  'hasParking': true,  'waypoint': 59, 'lat': 16.842205, 'lng': 102.896681},
];

// ข้อมูลเริ่มต้น (ใช้ seed ครั้งแรก)
const List<Map<String, dynamic>> feedingScheduleDefault = [
  {'name': 'หมีหมา / หมีควาย', 'emoji': '🐻', 'type': 'feeding', 'weekday': ['10:00', '15:00'], 'weekend': ['10:00', '15:00']},
  {'name': 'นากเล็กเล็บสั้น',   'emoji': '🦦', 'type': 'feeding', 'weekday': [], 'weekend': ['13:00', '14:00']},
  {'name': 'พาแก้วซันคอนัวร์',  'emoji': '🦜', 'type': 'feeding', 'weekday': ['10:00', '14:30'], 'weekend': ['10:30', '15:30']},
  {'name': 'แรดขาว',            'emoji': '🦏', 'type': 'feeding', 'weekday': ['10:00', '15:30'], 'weekend': ['10:00', '15:30']},
  {'name': 'หนูยักษ์ คาปิบาร่า','emoji': '🐹', 'type': 'feeding', 'weekday': ['10:00', '15:30'], 'weekend': ['10:00', '15:30']},
  {'name': 'สิงโตขาว',          'emoji': '🦁', 'type': 'feeding', 'weekday': ['11:00', '12:00'], 'weekend': ['11:00', '12:00']},
  {'name': 'สิงโต',             'emoji': '🦁', 'type': 'feeding', 'weekday': ['13:00', '14:00'], 'weekend': ['13:00', '14:00']},
  {'name': 'เสือโคร่ง',         'emoji': '🐯', 'type': 'feeding', 'weekday': ['15:00', '16:00'], 'weekend': ['15:00', '16:00']},
  {'name': 'ฮิปโปโปเตมัส',      'emoji': '🦛', 'type': 'feeding', 'weekday': [], 'weekend': ['10:00', '15:30']},
  {'name': 'ทุ่งแสนกวาง',       'emoji': '🦌', 'type': 'feeding', 'weekday': ['10:00', '15:00'], 'weekend': ['10:00', '15:00']},
  {'name': 'ช้าง',              'emoji': '🐘', 'type': 'feeding', 'weekday': ['10:00', '15:00'], 'weekend': ['10:00', '15:00']},
  {'name': 'ยีราฟ',             'emoji': '🦒', 'type': 'feeding', 'weekday': ['10:30', '14:00'], 'weekend': ['10:30', '14:00']},
  {'name': 'เพนกวิน',           'emoji': '🐧', 'type': 'show',    'weekday': ['11:00', '14:30'], 'weekend': ['11:00', '14:30']},
  {'name': 'แมวน้ำ',            'emoji': '🦭', 'type': 'show',    'weekday': ['11:00', '13:30'], 'weekend': ['11:00', '13:30', '15:00']},
  {'name': 'พาเหรดคาปิบาร่า',   'emoji': '🐾', 'type': 'show',    'weekday': ['10:00', '13:30'], 'weekend': ['10:00', '13:30']},
  {'name': 'ฮิปโปโปเตมัสแคระ',  'emoji': '🦛', 'type': 'show',    'weekday': ['10:00', '12:00', '13:00', '15:00'], 'weekend': ['10:00', '12:00', '13:00', '15:00']},
];

const List<Map<String, String>> funFacts = [
  {'emoji': '🐒', 'title': 'กลุ่มลิง', 'fact': 'ลิงมีนิ้วมือที่จับสิ่งของได้เหมือนมนุษย์ บางสายพันธุ์มีอายุยืนถึง 40 ปี'},
  {'emoji': '🦁', 'title': 'กลุ่มแมวใหญ่', 'fact': 'สิงโตเป็นสัตว์เพียงชนิดเดียวในตระกูลแมวที่อยู่รวมกันเป็นฝูงได้ถึง 30 ตัว'},
  {'emoji': '🐯', 'title': 'เสือโคร่ง', 'fact': 'ลายทางของเสือแต่ละตัวไม่ซ้ำกันเลย เหมือนลายนิ้วมือมนุษย์'},
  {'emoji': '🦛', 'title': 'ฮิปโปโปเตมัส', 'fact': 'ฮิปโปผลิตสารคล้ายครีมกันแดดจากผิวหนังตามธรรมชาติ'},
  {'emoji': '🐧', 'title': 'เพนกวิน', 'fact': 'เพนกวินแต่งงานกันตลอดชีวิต ตัวผู้จะใช้ก้อนกรวดเป็นของขวัญจีบตัวเมีย'},
  {'emoji': '🦒', 'title': 'ยีราฟ', 'fact': 'ยีราฟมีหัวใจหนักถึง 11 กิโลกรัม และนอนหลับเพียงวันละ 30 นาที'},
  {'emoji': '🦘', 'title': 'จิงโจ้', 'fact': 'จิงโจ้กระโดดได้ไกลถึง 9 เมตรในก้าวเดียว'},
  {'emoji': '🦜', 'title': 'กลุ่มนก', 'fact': 'นกแก้วบางสายพันธุ์มีอายุยืนกว่า 80 ปี ฉลาดเทียบได้กับเด็ก 5 ขวบ'},
  {'emoji': '🐻', 'title': 'กลุ่มหมี', 'fact': 'หมีวิ่งได้เร็วถึง 55 กม./ชม. และมีความจำดีเยี่ยม'},
  {'emoji': '🦭', 'title': 'แมวน้ำ', 'fact': 'แมวน้ำดำน้ำลึกได้ถึง 300 เมตร กลั้นหายใจได้นาน 30 นาที'},
  {'emoji': '🦏', 'title': 'แรด', 'fact': 'นอแรดทำจากเคราตินชนิดเดียวกับเล็บมนุษย์'},
  {'emoji': '🦦', 'title': 'นาก', 'fact': 'นากจับมือกันขณะนอนหลับในน้ำเพื่อไม่ให้พัดห่างกัน'},
  {'emoji': '🐹', 'title': 'คาปิบาร่า', 'fact': 'คาปิบาร่าเป็นสัตว์ฟันแทะที่ใหญ่ที่สุดในโลก หนักได้ถึง 65 กก.'},
  {'emoji': '🦌', 'title': 'กลุ่มกวาง', 'fact': 'เขากวางเติบโตเร็วที่สุดในอาณาจักรสัตว์ เติบโตได้วันละ 2.5 ซม.'},
  {'emoji': '🐐', 'title': 'เลียงผา', 'fact': 'เลียงผาปีนหน้าผาชันได้อย่างน่าอัศจรรย์ กีบมีพื้นนุ่มยืดหยุ่นช่วยยึดเกาะ'},
  {'emoji': '🦅', 'title': 'กลุ่มแร้ง', 'fact': 'แร้งบินสูงได้ถึง 11,000 เมตร มองเห็นซากสัตว์จากระยะ 4 กม.'},
];

const List<String> visitingTips = [
  '👣 เดินตามเส้นทางที่กำหนดเพื่อความปลอดภัย',
  '📸 ถ่ายรูปจากระยะปลอดภัย ไม่ยื่นมือเข้ากรง',
  '🚫 ไม่ให้อาหารสัตว์นอกจากรอบที่กำหนด',
  '🌿 ช่วยกันรักษาความสะอาดในสวนสัตว์',
];

const List<Offset> waypoints = [
  Offset(3631, 812),  // 1
  Offset(3519, 1057), // 2
  Offset(3097, 836),  // 3
  Offset(2975, 451),  // 4
  Offset(2767, 735),  // 5
  Offset(2573, 788),  // 6
  Offset(2371, 889),  // 7
  Offset(2275, 631),  // 8
  Offset(2119, 908),  // 9
  Offset(1925, 849),  // 10
  Offset(1760, 754),  // 11
  Offset(1398, 538),  // 12
  Offset(1053, 709),  // 13
  Offset(829,  831),  // 14
  Offset(587,  911),  // 15
  Offset(409,  1028), // 16
  Offset(439,  1248), // 17
  Offset(266,  1339), // 18
  Offset(534,  1471), // 19
  Offset(409,  1671), // 20
  Offset(245,  1886), // 21
  Offset(250,  2080), // 22
  Offset(391,  2139), // 23
  Offset(553,  2091), // 24
  Offset(649,  1814), // 25
  Offset(731,  1565), // 26
  Offset(912,  1357), // 27
  Offset(1034, 1357), // 28
  Offset(1194, 1421), // 29
  Offset(1140, 1700), // 30
  Offset(1284, 1495), // 31
  Offset(1441, 1562), // 32
  Offset(1669, 1628), // 33
  Offset(2193, 1713), // 34
  Offset(2770, 1647), // 35
  Offset(2424, 1921), // 36
  Offset(2305, 2064), // 37
  Offset(1853, 2048), // 38
  Offset(1975, 2242), // 39
  Offset(1869, 2327), // 40
  Offset(1802, 2479), // 41
  Offset(1677, 2620), // 42
  Offset(1544, 2692), // 43
  Offset(1348, 2771), // 44
  Offset(2990, 2755), // 45
  Offset(2895, 2662), // 46
  Offset(2772, 2418), // 47
  Offset(2485, 2245), // 48
  Offset(2892, 2181), // 49
  Offset(3147, 2229), // 50
  Offset(3357, 2274), // 51
  Offset(3628, 2288), // 52
  Offset(3825, 2240), // 53
  Offset(4147, 2099), // 54
  Offset(4410, 1992), // 55
  Offset(4686, 1995), // 56
  Offset(4437, 1666), // 57
  Offset(4118, 1642), // 58
  Offset(4596, 1333), // 59
];

const List<List<int>> edges = [
  [1, 2], [2, 3], [3, 4], [3, 5], [5, 6], [6, 7],
  [7, 8], [7, 9], [9, 10], [10, 11], [11, 12], [12, 13], [13, 14],
  [14, 15], [15, 16], [16, 17], [17, 18], [17, 19],
  [19, 20], [20, 21], [21, 22], [22, 23], [23, 24],
  [24, 25], [25, 26], [26, 27], [27, 28], [28, 29],
  [29, 30], [29, 31], [31, 32], [32, 33], [33, 34], [34, 35],[34, 36],
  [35, 36], [36, 37], [37, 38], [37, 39],
  [39, 40], [40, 41], [41, 42], [42, 43], [43, 44],
  [44, 45], [45, 46], [46, 47], [47, 48],[47,49],
  [49, 50], [50, 51], [51, 52], [52, 53], [53, 54],
  [54, 55], [55, 57],
  [55, 56],
  [57, 58], [57, 59],
];

List<int> findPath(int from, int to) {
  final graph = <int, List<int>>{};
  for (final e in edges) {
    graph.putIfAbsent(e[0], () => []).add(e[1]);
    graph.putIfAbsent(e[1], () => []).add(e[0]);
  }
  final queue = <List<int>>[[from]];
  final visited = <int>{from};
  while (queue.isNotEmpty) {
    final path = queue.removeAt(0);
    final node = path.last;
    if (node == to) return path;
    for (final neighbor in (graph[node] ?? [])) {
      if (!visited.contains(neighbor)) {
        visited.add(neighbor);
        queue.add([...path, neighbor]);
      }
    }
  }
  return [from, to];
}

int timeToMinutes(String t) {
  final parts = t.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

int nowMinutes() {
  final n = DateTime.now();
  return n.hour * 60 + n.minute;
}

bool isWeekend() {
  final d = DateTime.now().weekday;
  return d == DateTime.saturday || d == DateTime.sunday;
}

String formatCountdown(int diff) {
  if (diff < 60) return 'อีก $diff นาที';
  final h = diff ~/ 60;
  final m = diff % 60;
  return m > 0 ? 'อีก $h ชม. $m นาที' : 'อีก $h ชม.';
}

List<Map<String, dynamic>> getSortedScheduleFromDocs(
    List<QueryDocumentSnapshot> docs, String query, bool weekend) {
  final now = nowMinutes();
  final todayIsWeekend = isWeekend();
  final shouldCountdown = weekend == todayIsWeekend;
  List<Map<String, dynamic>> result = [];
  for (final doc in docs) {
    final data = doc.data() as Map<String, dynamic>;
    if (data['active'] == false) continue;
    final slots = List<String>.from(weekend ? data['weekend'] : data['weekday']);
    if (slots.isEmpty) continue;
    if (query.isNotEmpty &&
        !data['name'].toString().toLowerCase().contains(query.toLowerCase())) continue;
    int? nextDiff;
    String? nextTime;
    if (shouldCountdown) {
      for (final s in slots) {
        final m = timeToMinutes(s);
        if (m > now) { nextDiff = m - now; nextTime = s; break; }
      }
    }
    result.add({
      ...data,
      'id': doc.id,
      'slots': slots,
      'nextDiff': nextDiff,
      'nextTime': nextTime,
      'shouldCountdown': shouldCountdown,
    });
  }
  result.sort((a, b) {
    if (!shouldCountdown) return 0;
    if (a['nextDiff'] == null && b['nextDiff'] == null) return 0;
    if (a['nextDiff'] == null) return 1;
    if (b['nextDiff'] == null) return -1;
    return (a['nextDiff'] as int).compareTo(b['nextDiff'] as int);
  });
  return result;
}

// ════════════════════════════════════════════
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZooPath',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(textTheme: GoogleFonts.sarabunTextTheme(), useMaterial3: true),
      home: const WelcomePage(),
    );
  }
}

// ════════════════════════════════════════════
// หน้าแรก
// ════════════════════════════════════════════
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  Map<String, dynamic>? fromLocation;
  Map<String, dynamic>? toLocation;

  // กด 3 ขีด → ถาม password
  void _onMenuTap() async {
    final pw = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        bool obscure = true;
        return StatefulBuilder(builder: (ctx, setSt) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              const Text('🔐 ', style: TextStyle(fontSize: 20)),
              Text('Admin Login', style: GoogleFonts.sarabun(fontWeight: FontWeight.bold)),
            ]),
            content: TextField(
              controller: ctrl,
              obscureText: obscure,
              style: GoogleFonts.sarabun(),
              decoration: InputDecoration(
                hintText: 'กรอก password',
                hintStyle: GoogleFonts.sarabun(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFf5f5f5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: () => setSt(() => obscure = !obscure),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ยกเลิก', style: GoogleFonts.sarabun(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2d6a4f), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => Navigator.pop(ctx, ctrl.text),
                child: Text('เข้าสู่ระบบ', style: GoogleFonts.sarabun(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        });
      },
    );
    if (pw == null) return;
    if (pw == kAdminPassword) {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPage()));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Password ไม่ถูกต้อง', style: GoogleFonts.sarabun()), backgroundColor: Colors.red[400]),
      );
    }
  }

  Future<void> _selectLocation(bool isFrom) async {
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isFrom ? 'ตอนนี้อยู่ที่ไหน?' : 'อยากไปที่ไหน?',
                  style: GoogleFonts.sarabun(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 400,
                child: ListView.builder(
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final loc = locations[index];
                    return ListTile(
                      leading: Text(loc['emoji'], style: const TextStyle(fontSize: 24)),
                      title: Text(loc['name'], style: GoogleFonts.sarabun(fontSize: 15)),
                      subtitle: Row(children: [
                        if (loc['hasToilet']) const Text('🚻 ', style: TextStyle(fontSize: 12)),
                        if (loc['hasParking']) const Text('🅿️', style: TextStyle(fontSize: 12)),
                      ]),
                      onTap: () => Navigator.pop(context, loc),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) {
      setState(() {
        if (isFrom) fromLocation = selected;
        else toLocation = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _onMenuTap,
                        child: const Icon(Icons.menu, color: Color(0xFF1a2e1a), size: 26),
                      ),
                      const Spacer(),
                      Container(
                        width: 42, height: 42,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipOval(child: Image.asset('assets/logo.jpg', width: 42, height: 42, fit: BoxFit.cover)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('สวนสัตว์', style: GoogleFonts.sarabun(fontSize: 36, fontWeight: FontWeight.w300, color: const Color(0xFF1a2e1a), height: 1.1)),
                      Text('ขอนแก่น', style: GoogleFonts.sarabun(fontSize: 36, fontWeight: FontWeight.bold, color: const Color(0xFF1a2e1a), height: 1.1)),
                      const SizedBox(height: 10),
                      Text('สำรวจสัตว์กว่า ${locations.length} สถานีในสวนสัตว์\nพร้อมนำทางและตารางให้อาหาร',
                          style: GoogleFonts.sarabun(fontSize: 13, color: Colors.grey[500], height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                    child: SizedBox(
                      height: 210,
                      child: Stack(
                      children: [
                    Image.asset(
                          'assets/ZooPath.png',
                            width: double.infinity,
                                height: 210,
                            fit: BoxFit.cover,
              ),
          Positioned(
            top: 16, right: 20,
            child: Column(children: [
              _StatBadge(emoji: '🦁', label: 'สัตว์หายาก', value: '50+'),
              const SizedBox(height: 8),
              _StatBadge(emoji: '🌿', label: 'พื้นที่สีเขียว', value: '2,986 ไร่'),
              ]),
            ),
          ],
        ),
      ),
    ),
  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF2d6a4f).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text('นำทาง', style: GoogleFonts.sarabun(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2d6a4f))),
                          ),
                          const Spacer(),
                          Text('${locations.length} สถานที่', style: GoogleFonts.sarabun(fontSize: 11, color: Colors.grey[400])),
                        ]),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => _selectLocation(true),
                          child: _LocationSelector(
                            label: 'ตอนนี้อยู่ที่', icon: fromLocation?['emoji'] ?? '📍',
                            hint: fromLocation?['name'] ?? 'เลือกจุดเริ่มต้น',
                            color: const Color(0xFF2d6a4f), selected: fromLocation != null),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Column(children: List.generate(3, (i) =>
                            Container(width: 2, height: 6, margin: const EdgeInsets.symmetric(vertical: 2), color: Colors.grey[300]))),
                        ),
                        GestureDetector(
                          onTap: () => _selectLocation(false),
                          child: _LocationSelector(
                            label: 'อยากไปที่', icon: toLocation?['emoji'] ?? '🎯',
                            hint: toLocation?['name'] ?? 'เลือกปลายทาง',
                            color: const Color(0xFFf4845f), selected: toLocation != null),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: fromLocation != null && toLocation != null
                            ? () async {
                                Navigator.push(
                                context,
                                  MaterialPageRoute(
                                    builder: (context) => MapPage(
                                    from: fromLocation!,
                                      to: toLocation!,
                                    ),
                                 ),
                              );
                             }
                          : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2d6a4f), foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[200], disabledForegroundColor: Colors.grey[400],
                              elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('เริ่มนำทาง', style: GoogleFonts.sarabun(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('สถานที่ยอดนิยม', style: GoogleFonts.sarabun(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1a2e1a))),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: locations.take(6).map((loc) =>
                            GestureDetector(
                              onTap: () => setState(() {
                                fromLocation ??= locations[0];
                                toLocation = loc;
                              }),
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: toLocation?['id'] == loc['id'] ? const Color(0xFF2d6a4f) : const Color(0xFFf5f5f5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(children: [
                                  Text(loc['emoji'], style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(loc['name'], style: GoogleFonts.sarabun(
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                      color: toLocation?['id'] == loc['id'] ? Colors.white : const Color(0xFF1a2e1a))),
                                ]),
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════
// หน้า Admin
// ════════════════════════════════════════════
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _doSeed();
  }

  Future<void> _doSeed() async {
    await seedFirestore();
    setState(() => _seeded = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2d6a4f),
        foregroundColor: Colors.white,
        title: Text('🔐 Admin Panel', style: GoogleFonts.sarabun(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: !_seeded
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _db.collection('feedingSchedule').orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final active = data['active'] ?? true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: active ? const Color(0xFFe0e0e0) : Colors.grey[300]!),
                        boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)] : [],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Text(data['emoji'] ?? '🐾', style: const TextStyle(fontSize: 28)),
                        title: Text(data['name'] ?? '',
                            style: GoogleFonts.sarabun(fontWeight: FontWeight.bold, fontSize: 14,
                                color: active ? const Color(0xFF1a2e1a) : Colors.grey)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            _TimeChips(label: 'วันธรรมดา', slots: List<String>.from(data['weekday'] ?? [])),
                            const SizedBox(height: 4),
                            _TimeChips(label: 'เสาร์-อาทิตย์', slots: List<String>.from(data['weekend'] ?? [])),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // toggle เปิด/ปิด
                            Switch(
                              value: active,
                              activeColor: const Color(0xFF2d6a4f),
                              onChanged: (val) => doc.reference.update({'active': val}),
                            ),
                            // ปุ่มแก้ไข
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Color(0xFF2d6a4f)),
                              onPressed: () => _showEditDialog(doc),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void _showEditDialog(QueryDocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final weekdayCtrl = TextEditingController(text: (data['weekday'] as List).join(', '));
  final weekendCtrl = TextEditingController(text: (data['weekend'] as List).join(', '));
  final noticeCtrl = TextEditingController(text: data['notice'] ?? '');
  bool showNotice = data['showNotice'] ?? false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Text(data['emoji'] ?? '🐾', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(child: Text(data['name'] ?? '',
              style: GoogleFonts.sarabun(fontWeight: FontWeight.bold, fontSize: 16))),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('วันธรรมดา (คั่นด้วย , เช่น 10:00, 15:00)',
                  style: GoogleFonts.sarabun(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 6),
              TextField(
                controller: weekdayCtrl,
                style: GoogleFonts.sarabun(),
                decoration: InputDecoration(
                  hintText: '10:00, 15:00',
                  filled: true, fillColor: const Color(0xFFf5f5f5),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              Text('เสาร์-อาทิตย์',
                  style: GoogleFonts.sarabun(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 6),
              TextField(
                controller: weekendCtrl,
                style: GoogleFonts.sarabun(),
                decoration: InputDecoration(
                  hintText: '10:00, 15:00',
                  filled: true, fillColor: const Color(0xFFf5f5f5),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              // ── ส่วนประกาศ ──────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.campaign_rounded,
                          size: 16, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text('ข้อความประกาศ',
                          style: GoogleFonts.sarabun(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[800])),
                      const Spacer(),
                      // toggle เปิด/ปิดการแสดงข้อความ
                      Row(children: [
                        Text(showNotice ? 'แสดงข้อความ' : 'แสดงเวลา',
                            style: GoogleFonts.sarabun(
                                fontSize: 10,
                                color: showNotice
                                    ? Colors.amber[800]
                                    : Colors.grey)),
                        const SizedBox(width: 4),
                        Switch(
                          value: showNotice,
                          activeColor: Colors.amber[700],
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) =>
                              setSt(() => showNotice = val),
                        ),
                      ]),
                    ]),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noticeCtrl,
                      style: GoogleFonts.sarabun(fontSize: 13),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'เช่น วันนี้งดให้อาหาร / เลื่อนโชว์เป็น 16:00',
                        hintStyle:
                            GoogleFonts.sarabun(fontSize: 12, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      showNotice
                          ? '✅ ผู้ใช้จะเห็นข้อความแทนเวลา'
                          : 'ℹ️ ผู้ใช้จะเห็นเวลาปกติ',
                      style: GoogleFonts.sarabun(
                          fontSize: 10,
                          color:
                              showNotice ? Colors.green[700] : Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('⚠️ ถ้าไม่มีรอบให้เว้นว่างไว้เลย',
                  style: GoogleFonts.sarabun(
                      fontSize: 11, color: Colors.orange[700])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ยกเลิก',
                style: GoogleFonts.sarabun(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2d6a4f),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              List<String> parseSlots(String s) {
                if (s.trim().isEmpty) return [];
                return s
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
              }
              await doc.reference.update({
                'weekday': parseSlots(weekdayCtrl.text),
                'weekend': parseSlots(weekendCtrl.text),
                'notice': noticeCtrl.text.trim(),
                'showNotice': showNotice,
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('✅ บันทึกแล้ว',
                          style: GoogleFonts.sarabun()),
                      backgroundColor: Colors.green),
                );
              }
            },
            child: Text('บันทึก',
                style: GoogleFonts.sarabun(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
}
}

class _TimeChips extends StatelessWidget {
  final String label;
  final List<String> slots;
  const _TimeChips({required this.label, required this.slots});

  @override
  Widget build(BuildContext context) {
    return Wrap(                          // ← เปลี่ยนจาก Row เป็น Wrap
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 2,
      children: [
        Text('$label: ',
            style: GoogleFonts.sarabun(fontSize: 10, color: Colors.grey[500])),
        if (slots.isEmpty)
          Text('ไม่มีรอบ',
              style: GoogleFonts.sarabun(fontSize: 10, color: Colors.grey[400]))
        else
          ...slots.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2d6a4f).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(s,
                    style: GoogleFonts.sarabun(
                        fontSize: 10,
                        color: const Color(0xFF2d6a4f),
                        fontWeight: FontWeight.w600)),
              )),
      ],
    );
  }
}

// ════════════════════════════════════════════
// หน้าแผนที่
// ════════════════════════════════════════════
class MapPage extends StatefulWidget {
  final Map<String, dynamic> from, to;
  const MapPage({super.key, required this.from, required this.to});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  int _tipIndex = 0;
  late List<int> _path;
  late AnimationController _animController;
  late Animation<double> _animation;
  late AnimationController _factController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _factIndex = 0;
  final DateTime _now = DateTime.now();
  late Stream<DateTime> _clockStream;
  late double _distanceMeters;
  late int _estimatedMinutes;
  late int _waypointCount;
  bool _showWeekend = isWeekend();
  String temp = '--', humidity = '--', windSpeed = '--', weatherLabel = 'กำลังโหลด...';

  Future<void> getMyWeather() async {
    try {
      final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=16.84&longitude=102.89&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code&timezone=Asia%2FBangkok');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          temp = data['current']['temperature_2m'].toString();
          humidity = data['current']['relative_humidity_2m'].toString();
          windSpeed = data['current']['wind_speed_10m'].toString();
          final int code = data['current']['weather_code'];
          if (code == 0) weatherLabel = 'ฟ้าใส';
          else if (code <= 3) weatherLabel = 'เมฆเยอะ';
          else weatherLabel = 'ฝนตก/หมอกลง';
        });
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _path = findPath(widget.from['waypoint'] as int, widget.to['waypoint'] as int);
    _waypointCount = _path.length;
    const mapWidthMeters = 800.0;
    const mapHeightMeters = 480.0;
    double totalDistance = 0;
    for (int i = 0; i < _path.length - 1; i++) {
      final wp1 = waypoints[_path[i] - 1];
      final wp2 = waypoints[_path[i + 1] - 1];
      final dx = (wp2.dx - wp1.dx) / 5000 * mapWidthMeters;
      final dy = (wp2.dy - wp1.dy) / 3000 * mapHeightMeters;
      totalDistance += sqrt(dx * dx + dy * dy);
    }
    _distanceMeters = totalDistance;
    _estimatedMinutes = (_distanceMeters / 67).round();
    _animController = AnimationController(vsync: this, duration: Duration(seconds: _path.length));
    _animation = Tween<double>(begin: 0, end: (_path.length - 1).toDouble())
        .animate(CurvedAnimation(parent: _animController, curve: Curves.linear));
    _animController.forward();
    _factController = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _factIndex = (_factIndex + 1) % funFacts.length;
            _tipIndex = (_tipIndex + 1) % visitingTips.length;
          });
          _factController.reset();
          _factController.forward();
        }
      });
    _factController.forward();
    _clockStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
    getMyWeather();
  }

  @override
  void dispose() {
    _animController.dispose();
    _factController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Offset _getAnimatedPosition(double t, List<Offset> p) {
    if (t <= 0) return p[0];
    if (t >= p.length - 1) return p.last;
    final i = t.floor();
    final frac = t - i;
    return Offset(p[i].dx + (p[i + 1].dx - p[i].dx) * frac, p[i].dy + (p[i + 1].dy - p[i].dy) * frac);
  }

  String _formatDistance(double m) => m < 1000 ? '${m.round()} เมตร' : '${(m / 1000).toStringAsFixed(1)} กม.';
  String _formatTime(int minutes) {
    if (minutes < 60) return '$minutes นาที';
    final h = minutes ~/ 60; final m = minutes % 60;
    return m > 0 ? '$h ชม. $m นาที' : '$h ชม.';
  }

  @override
  Widget build(BuildContext context) {
    final todayIsWeekend = isWeekend();
    final isViewingToday = _showWeekend == todayIsWeekend;
    final fact = funFacts[_factIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.sarabun(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'ค้นหารอบให้อาหาร / โชว์...',
            hintStyle: GoogleFonts.sarabun(color: Colors.grey[400], fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2d6a4f)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                : null,
            filled: true, fillColor: const Color(0xFFf5f5f5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1a2e1a), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF2d6a4f).withOpacity(0.3), width: 2)),
                    child: ClipOval(child: Image.asset('assets/logo.jpg', fit: BoxFit.cover)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${widget.from['name']} → ${widget.to['name']}',
                          style: GoogleFonts.sarabun(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1a2e1a)),
                          overflow: TextOverflow.ellipsis),
                      Text('นำทางภายในสวนสัตว์', style: GoogleFonts.sarabun(fontSize: 10, color: Colors.grey[400])),
                    ]),
                  ),
                  StreamBuilder<DateTime>(
                    stream: _clockStream, initialData: _now,
                    builder: (context, snapshot) {
                      final t = snapshot.data ?? _now;
                      final h = t.hour.toString().padLeft(2, '0');
                      final m = t.minute.toString().padLeft(2, '0');
                      final s = t.second.toString().padLeft(2, '0');
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF2d6a4f), borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.access_time_rounded, color: Colors.white70, size: 13),
                          const SizedBox(width: 4),
                          Text('$h:$m:$s', style: GoogleFonts.sarabun(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ]),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(height: 1, color: const Color(0xFFf0f0f0)),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // แผนที่
                    SizedBox(
                      height: 320,
                      child: LayoutBuilder(builder: (context, constraints) {
                        final boxW = constraints.maxWidth;
                        final boxH = constraints.maxHeight;
                        final scaleX = boxW / 5000.0;
                        final scaleY = boxH / 3000.0;
                        final scale = scaleX < scaleY ? scaleX : scaleY;
                        final renderedW = 5000.0 * scale;
                        final renderedH = 3000.0 * scale;
                        final offsetX = (boxW - renderedW) / 2;
                        final offsetY = (boxH - renderedH) / 2;
                        final scaledPath = _path.map((i) {
                          final wp = waypoints[i - 1];
                          return Offset(wp.dx * scale + offsetX, wp.dy * scale + offsetY);
                        }).toList();
                        return AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            final currentCoord = _getAnimatedPosition(_animation.value, scaledPath);
                            return Stack(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: SizedBox(width: boxW, height: boxH,
                                  child: Image.asset('assets/map.png', width: boxW, height: boxH, fit: BoxFit.contain)),
                              ),
                              CustomPaint(size: Size(boxW, boxH), painter: _RoutePainter(path: scaledPath, animValue: _animation.value)),
                              Positioned(
                                left: currentCoord.dx - 16, top: currentCoord.dy - 16,
                                child: Container(
                                  width: 32, height: 32,
                                  decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                                  child: const Icon(Icons.directions_walk, color: Colors.white, size: 20),
                                ),
                              ),
                            ]);
                          },
                        );
                      }),
                    ),

                    // Info cards
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: IntrinsicHeight(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Expanded(child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFe0e0e0))),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [const Icon(Icons.route, size: 14, color: Color(0xFF2d6a4f)), const SizedBox(width: 4),
                                Text('เส้นทาง', style: GoogleFonts.sarabun(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2d6a4f)))]),
                              const SizedBox(height: 8),
                              _InfoRow(icon: Icons.straighten, label: 'ระยะ', value: _formatDistance(_distanceMeters)),
                              const SizedBox(height: 4),
                              _InfoRow(icon: Icons.timer, label: 'เวลา', value: _formatTime(_estimatedMinutes)),
                              const SizedBox(height: 4),
                              _InfoRow(icon: Icons.place, label: 'จุดผ่าน', value: '$_waypointCount จุด'),
                            ]),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFe0e0e0))),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [const Icon(Icons.cloud, size: 14, color: Color(0xFF2d6a4f)), const SizedBox(width: 4),
                                Text('อากาศ', style: GoogleFonts.sarabun(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2d6a4f)))]),
                              const Spacer(),
                              Center(child: Column(children: [
                                const Text('⛅', style: TextStyle(fontSize: 28)),
                                Text('$temp°C', style: GoogleFonts.sarabun(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1a2e1a))),
                                Text(weatherLabel, style: GoogleFonts.sarabun(fontSize: 10, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text('💧$humidity%  💨$windSpeed กม./ชม.', style: GoogleFonts.sarabun(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center),
                              ])),
                              const Spacer(),
                            ]),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFe0e0e0))),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [const Icon(Icons.lightbulb, size: 14, color: Color(0xFF2d6a4f)), const SizedBox(width: 4),
                                Text('เคล็ดลับ', style: GoogleFonts.sarabun(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2d6a4f)))]),
                              const Spacer(),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                child: Text(visitingTips[_tipIndex], key: ValueKey(_tipIndex),
                                    style: GoogleFonts.sarabun(fontSize: 11, color: Colors.grey[700]), textAlign: TextAlign.center),
                              ),
                              const Spacer(),
                            ]),
                          )),
                        ]),
                      ),
                    ),

                    // Fun fact
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        key: ValueKey(_factIndex),
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2d6a4f).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF2d6a4f).withOpacity(0.2)),
                        ),
                        child: Row(children: [
                          Text(fact['emoji']!, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('🔍 ${fact['title']}', style: GoogleFonts.sarabun(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2d6a4f))),
                            Text(fact['fact']!, style: GoogleFonts.sarabun(fontSize: 11, color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ])),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ตารางให้อาหาร — ดึงจาก Firestore real-time
                    StreamBuilder<QuerySnapshot>(
                      stream: _db.collection('feedingSchedule').orderBy('name').snapshots(),
                      builder: (context, snapshot) {
                        final docs = snapshot.hasData ? snapshot.data!.docs : <QueryDocumentSnapshot>[];
                        final schedule = getSortedScheduleFromDocs(docs, _searchQuery, _showWeekend);
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                              child: Row(children: [
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('⏰ รอบให้อาหาร / โชว์', style: GoogleFonts.sarabun(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1a2e1a))),
                                  Text('วันนี้: ${todayIsWeekend ? "เสาร์-อาทิตย์" : "วันธรรมดา"}${isViewingToday ? " (กำลังดูอยู่)" : ""}',
                                      style: GoogleFonts.sarabun(fontSize: 10, color: Colors.grey[500])),
                                ]),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => setState(() => _showWeekend = !_showWeekend),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _showWeekend ? const Color(0xFFf4845f).withOpacity(0.1) : const Color(0xFF2d6a4f).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _showWeekend ? const Color(0xFFf4845f) : const Color(0xFF2d6a4f)),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(_showWeekend ? Icons.weekend_rounded : Icons.work_rounded, size: 12,
                                          color: _showWeekend ? const Color(0xFFf4845f) : const Color(0xFF2d6a4f)),
                                      const SizedBox(width: 4),
                                      Text(_showWeekend ? 'เสาร์-อาทิตย์' : 'วันธรรมดา',
                                          style: GoogleFonts.sarabun(fontSize: 11, fontWeight: FontWeight.w600,
                                              color: _showWeekend ? const Color(0xFFf4845f) : const Color(0xFF2d6a4f))),
                                      const SizedBox(width: 4),
                                      Icon(Icons.swap_horiz_rounded, size: 12, color: _showWeekend ? const Color(0xFFf4845f) : const Color(0xFF2d6a4f)),
                                    ]),
                                  ),
                                ),
                              ]),
                            ),
                            if (!isViewingToday)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.info_outline_rounded, size: 14, color: Colors.amber),
                                  const SizedBox(width: 6),
                                  Text('ดูตารางวัน${_showWeekend ? "เสาร์-อาทิตย์" : "ธรรมดา"} (ไม่แสดงเวลานับถอยหลัง)',
                                      style: GoogleFonts.sarabun(fontSize: 11, color: Colors.amber[800])),
                                ]),
                              ),
                            SizedBox(
                              height: 130,
                              child: schedule.isEmpty
                                  ? Center(child: Text('ไม่พบรอบที่ค้นหา', style: GoogleFonts.sarabun(color: Colors.grey, fontSize: 13)))
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                                      itemCount: schedule.length,
                                      itemBuilder: (context, index) {
                                        final item = schedule[index];
                                        final hasNext = item['nextDiff'] != null;
                                        final isSoon = hasNext && (item['nextDiff'] as int) <= 30;
                                        final slots = item['slots'] as List<String>;
                                        return Container(
                                          width: 150,
                                          margin: const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isSoon ? const Color(0xFFf4845f).withOpacity(0.1) : const Color(0xFFf8faf7),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: isSoon ? const Color(0xFFf4845f) : const Color(0xFFe0e0e0)),
                                          ),
                                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Row(children: [
                                              Text(item['emoji'] ?? '🐾', style: const TextStyle(fontSize: 18)),
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: item['type'] == 'show' ? Colors.purple.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(item['type'] == 'show' ? 'โชว์' : 'อาหาร',
                                                    style: GoogleFonts.sarabun(fontSize: 10,
                                                        color: item['type'] == 'show' ? Colors.purple : Colors.green[700])),
                                              ),
                                            ]),
                                            const SizedBox(height: 4),
                                            Text(item['name'] ?? '', style: GoogleFonts.sarabun(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF1a2e1a)),
                                                maxLines: 1, overflow: TextOverflow.ellipsis),
                                            const Spacer(),
                                            // ถ้า showNotice = true → แสดงข้อความประกาศ
                                                if (item['showNotice'] == true &&
                                                      (item['notice'] ?? '').toString().isNotEmpty) ...[
                                                Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 4),
                                                        decoration: BoxDecoration(
                                                        color: Colors.amber.withOpacity(0.15),
                                                              borderRadius: BorderRadius.circular(8),
                                                                border: Border.all(
                                                                  color: Colors.amber.withOpacity(0.5)),
                                                              ),
                                                      child: Row(children: [
                                                        const Icon(Icons.campaign_rounded,
                                                size: 11, color: Colors.amber),
                                                    const SizedBox(width: 4),
                                                  Expanded(
                                                child: Text(
                                                item['notice'].toString(),
                                                  style: GoogleFonts.sarabun(
                                                    fontSize: 10,
                                                      color: Colors.amber[800],
                                                        fontWeight: FontWeight.w600),
                                                          maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ]),
                                                  ),
                                              ] else if (item['shouldCountdown'] == true) ...[
                                        Text(
                                          hasNext
                                              ? formatCountdown(item['nextDiff'] as int)
                                              : 'หมดรอบแล้ว',
                                          style: GoogleFonts.sarabun(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isSoon
                                                  ? const Color(0xFFf4845f)
                                                  : hasNext
                                                      ? const Color(0xFF2d6a4f)
                                                      : Colors.grey),
                                        ),
                                        if (item['nextTime'] != null)
                                          Text('${item['nextTime']} น.',
                                              style: GoogleFonts.sarabun(
                                                  fontSize: 10, color: Colors.grey[600])),
                                      ] else ...[
                                        Text('รอบ:',
                                            style: GoogleFonts.sarabun(
                                                fontSize: 9, color: Colors.grey[500])),
                                        Text(slots.join(' / '),
                                            style: GoogleFonts.sarabun(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF2d6a4f)),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                          ]),
                                        );
                                      },
                                    ),
                            ),
                          ]),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════
// Shared Widgets
// ════════════════════════════════════════════
class _StatBadge extends StatelessWidget {
  final String emoji, label, value;
  const _StatBadge({required this.emoji, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.sarabun(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1a2e1a))),
          Text(label, style: GoogleFonts.sarabun(fontSize: 9, color: Colors.grey[500])),
        ]),
      ]),
    );
  }
}

class _LocationSelector extends StatelessWidget {
  final String label, icon, hint;
  final Color color;
  final bool selected;
  const _LocationSelector({required this.label, required this.icon, required this.hint, required this.color, required this.selected});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFf8faf7), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? color : const Color(0xFFe0e0e0)),
      ),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.sarabun(fontSize: 11, color: const Color(0xFF6b8f71), fontWeight: FontWeight.w600)),
          Text(hint, style: GoogleFonts.sarabun(fontSize: 14, color: selected ? const Color(0xFF1a2e1a) : Colors.grey)),
        ]),
        const Spacer(),
        Icon(Icons.chevron_right, color: color),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 12, color: Colors.grey[600]),
      const SizedBox(width: 4),
      Expanded(child: Text(label, style: GoogleFonts.sarabun(fontSize: 10, color: Colors.grey[600]))),
      Text(value, style: GoogleFonts.sarabun(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1a2e1a))),
    ]);
  }
}

class _RoutePainter extends CustomPainter {
  final List<Offset> path;
  final double animValue;
  _RoutePainter({required this.path, required this.animValue});
  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;
    final dimPaint = Paint()..color = const Color(0xFF2d6a4f).withOpacity(0.3)..strokeWidth = 5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final brightPaint = Paint()..color = const Color(0xFF2d6a4f)..strokeWidth = 5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final dashPaint = Paint()..color = Colors.white..strokeWidth = 2..style = PaintingStyle.stroke;
    final fullPath = Path()..moveTo(path[0].dx, path[0].dy);
    for (int i = 1; i < path.length; i++) fullPath.lineTo(path[i].dx, path[i].dy);
    canvas.drawPath(fullPath, dimPaint);
    if (animValue > 0) {
      final i = animValue.floor(); final frac = animValue - i;
      final donePath = Path()..moveTo(path[0].dx, path[0].dy);
      for (int j = 1; j <= i && j < path.length; j++) donePath.lineTo(path[j].dx, path[j].dy);
      if (i < path.length - 1) {
        final a = path[i]; final b = path[i + 1];
        donePath.lineTo(a.dx + (b.dx - a.dx) * frac, a.dy + (b.dy - a.dy) * frac);
      }
      canvas.drawPath(donePath, brightPaint);
      for (int j = 0; j <= i && j < path.length - 1; j++) {
        final ep = j == i ? Offset(path[j].dx + (path[j+1].dx - path[j].dx) * frac, path[j].dy + (path[j+1].dy - path[j].dy) * frac) : path[j + 1];
        final f = path[j]; final dx = ep.dx - f.dx; final dy = ep.dy - f.dy;
        final dist = (ep - f).distance; double drawn = 0;
        while (drawn < dist) {
          final s = drawn / dist; final e = ((drawn + 10.0) / dist).clamp(0.0, 1.0);
          canvas.drawLine(Offset(f.dx + dx * s, f.dy + dy * s), Offset(f.dx + dx * e, f.dy + dy * e), dashPaint);
          drawn += 18.0;
        }
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
