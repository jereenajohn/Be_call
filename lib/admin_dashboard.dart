import 'dart:convert';
import 'package:be_call/api.dart';
import 'package:be_call/callreport_date_wise.dart';
import 'package:be_call/callreport_statewise.dart';
import 'package:be_call/login_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<dynamic> _customers = [];
  int totalRecords = 0; 
  int productiveCount = 0;
  int activeCount = 0;
  double totalAmount = 0.0;
   int productiveCountmonthly = 0;
  int activeCountmonthly = 0;
  double totalAmountmonthly = 0.0;
  List<Map<String, dynamic>> groupedData = [];
  bool isLoading = true;
List<dynamic> allCalls = [];
  List<dynamic> filteredCalls = [];

  DateTime? startDate;
  DateTime? endDate;

  String? _username;

  @override
  void initState() {
    super.initState();
    _fetchUser();
    _loadUserName();
    _fetchDashboardSummary();
    fetchCallReports();

    // Fetch today's data
    final today = DateTime.now();
getDateWise();
  }

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idValue = prefs.get('id');
    if (idValue is int) return idValue;
    if (idValue is String) {
      return int.tryParse(idValue);
    }
    return null;
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Admin';
    });
  }

  int parseDuration(String duration) {
    int totalSeconds = 0;
    final minMatch = RegExp(r'(\d+)\s*min').firstMatch(duration);
    final secMatch = RegExp(r'(\d+)\s*sec').firstMatch(duration);
    if (minMatch != null) totalSeconds += int.parse(minMatch.group(1)!) * 60;
    if (secMatch != null) totalSeconds += int.parse(secMatch.group(1)!);
    return totalSeconds;
  }

  Future<void> getDateWise() async {
  setState(() {
    isLoading = true;
  });

  var token = await getToken();

  DateTime today = DateTime.now();
  String todayStr = DateFormat('yyyy-MM-dd').format(today);

  try {
    var res = await http.get(
      Uri.parse("$api/api/call/report/"),
      headers: {"Authorization": "Bearer $token"},
    );

    print("🟡 Status Code: ${res.statusCode}");
    print("🟡 Response: ${res.body}");

    if (res.statusCode == 200) {
      List<dynamic> allData = jsonDecode(res.body);

      // ✅ Filter only today's records
      List<dynamic> data = allData.where((call) {
        if (call['date'] == null && call['created'] == null) return false;
        try {
          // handle both possible keys
          String dateStr = call['date'] ?? call['created'];
          DateTime createdDate = DateTime.parse(dateStr).toLocal();
          String createdStr = DateFormat('yyyy-MM-dd').format(createdDate);
          return createdStr == todayStr;
        } catch (e) {
          print("⚠️ Date parse error: $e");
          return false;
        }
      }).toList();

      print("📅 Filtered today's calls: ${data.length}");

      Map<String, Map<String, dynamic>> grouped = {};

      for (var call in data) {
        String name = call['created_by_name'] ?? 'Unknown';
        String status = call['status'] ?? '';
        String durationStr = call['duration'] ?? '0 sec';
        double amount = (call['amount'] ?? 0).toDouble();

        if (status.toLowerCase() == 'productive') {
          grouped.putIfAbsent(
            name,
            () => {'count': 0, 'duration': 0, 'amount': 0.0},
          );

          grouped[name]!['count'] += 1;
          grouped[name]!['duration'] += parseDuration(durationStr);
          grouped[name]!['amount'] += amount;
        }
      }

      setState(() {
        groupedData = grouped.entries
            .map((e) => {
                  'name': e.key,
                  'count': e.value['count'],
                  'duration': e.value['duration'],
                  'amount': e.value['amount'],
                })
            .toList();
        isLoading = false;
      });

      print("✅ Final grouped today data count: ${groupedData.length}");
    } else {
      print("❌ Failed: ${res.statusCode}");
      setState(() => isLoading = false);
    }
  } catch (e) {
    print("⚠️ Error: $e");
    setState(() => isLoading = false);
  }
}


 Future<void> fetchCallReports() async {
  try {
    var token = await getToken();
    var userId = await getUserId();

    if (userId == null) {
      print("❌ No user id found in SharedPreferences");
      return;
    }

    final response = await http.get(
      Uri.parse('$api/api/call/report/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print('🟡 Status Code: ${response.statusCode}');
    print('🟡 Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      DateTime today = DateTime.now();
      String todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      // Filter only today’s calls
      List<dynamic> todayCalls = data.where((call) {
        if (call["date"] == null) return false;
        try {
          DateTime createdDate = DateTime.parse(call["date"]).toLocal();
          String createdStr = "${createdDate.year}-${createdDate.month.toString().padLeft(2, '0')}-${createdDate.day.toString().padLeft(2, '0')}";
          return createdStr == todayStr;
        } catch (e) {
          print("⚠️ Date parse error for call: $e");
          return false;
        }
      }).toList();

      setState(() {
        allCalls = data;
        filteredCalls = todayCalls;
        isLoading = false;
      });

      print("✅ Loaded ${allCalls.length} total calls");
      print("✅ Filtered ${filteredCalls.length} calls for today ($todayStr)");
    } else {
      setState(() => isLoading = false);
      print('❌ Error fetching reports');
    }
  } catch (e) {
    setState(() => isLoading = false);
    print('⚠️ Exception: $e');
  }
}


  Future<void> _fetchDashboardSummary() async {
    var token = await getToken();

    try {
      final response = await https.get(
        Uri.parse("$api/api/call/report/summary/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          totalRecords = data['today_summary']['total_records'] ?? 0;
          productiveCount = data['today_summary']['productive_count'] ?? 0;
          totalAmount = data['today_summary']['total_amount'] ?? 0.0;
          activeCount = data['today_summary']['active_count'] ?? 0;
          productiveCountmonthly = data['current_month_summary']['productive_count'] ?? 0;
          totalAmountmonthly = data['current_month_summary']['total_amount'] ?? 0.0;
          activeCountmonthly = data['current_month_summary']['active_count'] ?? 0;


        });
      } else {
        print("❌ Failed to load dashboard data: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Error fetching dashboard data: $e");
    }
  }

  Future<void> _fetchUser() async {
    var token = await getToken();
    var userId = await getUserId();
    if (userId == null) {
      print("No user id found in SharedPreferences");
      return;
    }

    try {
      var response = await https.get(
        Uri.parse("$api/api/users/$userId/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          _customers = [jsonDecode(response.body)];
        });
      } else {
        print("Failed to load user: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Colors.black;

    Map<String, Map<String, dynamic>> stateSummary = {};

    for (var call in filteredCalls) {
      // Enhanced state detection
      String state = '';
      if (call['state'] != null && call['state'].toString().trim().isNotEmpty) {
        state = call['state'].toString();
      } else if (call['state_name'] != null &&
          call['state_name'].toString().trim().isNotEmpty) {
        state = call['state_name'].toString();
      } else {
        state = 'Unknown';
      }

      String status = (call['status'] ?? '').toString();
      double amount = double.tryParse(call['amount']?.toString() ?? '0') ?? 0.0;

      if (!stateSummary.containsKey(state)) {
        stateSummary[state] = {
          'Active': 0,
          'Productive': 0,
          'Amount': 0.0,
        };
      }

      if (status == 'Active') {
        stateSummary[state]!['Active']++;
      } 
      else if (status == 'Productive')
      {
        stateSummary[state]!['Productive']++;
        stateSummary[state]!['Amount'] += amount;
      }
    }
print("State Summary: $stateSummary");

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 26, 164, 143),
        elevation: 4,
        shadowColor: const Color.fromARGB(255, 26, 164, 143).withOpacity(0.4),
        automaticallyImplyLeading: false, // hides default back arrow
        titleSpacing: 16, // add padding from left edge
        title: const Text(
          'BE CALL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
            fontSize: 18,
          ),
        ),
        centerTitle: false, // ✅ aligns title to the left
       actions: [
  Padding(
    padding: const EdgeInsets.only(right: 16),
    child: GestureDetector(
      onTap: () async {
        // Confirm logout (optional)
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
        );

        if (shouldLogout ?? false) {
          // Clear stored token and role
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          await prefs.remove('role');

          // Navigate back to LoginPage
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          }
        }
      },
      child: const CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white,
        child: Icon(
          Icons.person,
          color: Color.fromARGB(255, 26, 164, 143),
        ),
      ),
    ),
  ),
],

      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            // Text(
            //   "Welcome back, ${_username ?? 'Admin'} 👋",
            //   style: const TextStyle(
            //     color: Colors.white,
            //     fontSize: 15,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            const SizedBox(height: 20),

            // Summary Cards
            _buildSectionTitle("Today's Summary"),
                        const SizedBox(height: 5),


            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCard(Icons.people, "Active calls", "$activeCount"),
                _buildInfoCard(
                  Icons.receipt_long_rounded,
                  "Invoices",
                  "$productiveCount",
                ),
                _buildInfoCard(Icons.currency_rupee, "Amount", "$totalAmount"),
              ],
            ),
                        const SizedBox(height: 15),

            _buildSectionTitle("Monthly Summary"),
                        const SizedBox(height: 5),


             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCard(Icons.people, "Active calls", "$activeCountmonthly"),
                _buildInfoCard(
                  Icons.receipt_long_rounded,
                  "Invoices",
                  "$productiveCountmonthly",
                ),
                _buildInfoCard(Icons.currency_rupee, "Amount", "$totalAmountmonthly"),
              ],
            ),

            const SizedBox(height: 30),
       // 🟢 STAFF PERFORMANCE OVERVIEW
_buildSectionTitle("Staff Performance Overview"),
const SizedBox(height: 10),
Container(
  width: double.infinity,
  decoration: BoxDecoration(
    color: const Color(0xFF101010),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.white24, width: 1),
  ),
  child: Table(
    border: TableBorder.symmetric(
      inside: const BorderSide(color: Colors.white24, width: 0.5),
      outside: const BorderSide(color: Colors.white24, width: 1),
    ),
    columnWidths: const {
      0: FlexColumnWidth(2),
      1: FlexColumnWidth(2),
      2: FlexColumnWidth(2),
      3: FlexColumnWidth(2),
    },
    children: [
      // Header Row
      const TableRow(
        decoration: BoxDecoration(color: Color.fromARGB(255, 26, 164, 143)),
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Staff",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Duration",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Productive",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Total",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),

      // ✅ Data Rows (Top 3 by Productive Count)
      ...(() {
        final sorted =
            List<Map<String, dynamic>>.from(groupedData)..sort((a, b) => b['count'].compareTo(a['count']));
        final top3 = sorted.take(3).toList();

        return top3.map((item) {
          final hours = (item['duration'] / 3600).floor();
          final minutes = ((item['duration'] % 3600) / 60).floor();
          return TableRow(
            decoration: const BoxDecoration(color: Color(0xFF181818)),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(item['name'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("${hours}h ${minutes}m",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("${item['count']}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("₹${item['amount'].toStringAsFixed(0)}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        }).toList();
      })(),

      // ✅ “See More” Row
      TableRow(
        decoration: const BoxDecoration(color: Color(0xFF151515)),
        children: [
          
          const TableCell(child: SizedBox()), // empty columns
          const TableCell(child: SizedBox()),
          const TableCell(child: SizedBox()),
          TableCell(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CallreportDateWise(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Text(
                    "See More→",
                    style: TextStyle(
                      color: const Color.fromARGB(255, 26, 164, 143),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  ),
),


const SizedBox(height: 25),

// 🟢 STATE WISE SUMMARY
_buildSectionTitle("State Wise Summary"),
const SizedBox(height: 10),
Container(
  width: double.infinity,
  decoration: BoxDecoration(
    color: const Color(0xFF101010),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.white24, width: 1),
  ),
  child: Table(
    border: TableBorder.symmetric(
      inside: const BorderSide(color: Colors.white24, width: 0.5),
      outside: const BorderSide(color: Colors.white24, width: 1),
    ),
    columnWidths: const {
      0: FlexColumnWidth(3),
      1: FlexColumnWidth(2),
      2: FlexColumnWidth(2),
    },
    children: [
      // Header Row
      const TableRow(
        decoration: BoxDecoration(color: Color.fromARGB(255, 26, 164, 143)),
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("State",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Productive",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Amount",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),

      // ✅ Data Rows (Top 3 States by Productive Count)
      ...(() {
        // Convert to a list for sorting
        final entries = stateSummary.entries.toList();

        // Sort by Productive count descending
        entries.sort((a, b) =>
            (b.value['Productive'] as int).compareTo(a.value['Productive'] as int));

        // Take top 3 states
        final top3 = entries.take(3).toList();

        // Map to TableRow widgets
        return top3.map((entry) {
          final state = entry.key;
          final data = entry.value;
          return TableRow(
            decoration: const BoxDecoration(color: Color(0xFF181818)),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(state,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("${data['Productive']}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                    "₹${(data['Amount'] as double).toStringAsFixed(0)}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        }).toList();
      })(),

      // ✅ “See More” Row
      TableRow(
        decoration: const BoxDecoration(color: Color(0xFF151515)),
        children: [
         
          const TableCell(child: SizedBox()),
          const TableCell(child: SizedBox()),
           TableCell(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CallreportStatewise(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Text(
                    "See More →",
                    style: TextStyle(
                      color: const Color.fromARGB(255, 26, 164, 143),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  ),
),


const SizedBox(height: 30),



            // Financial Summary
            _buildSectionTitle("Financial Summary"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(
                      255,
                      26,
                      164,
                      143,
                    ).withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _AccountRow(
                    label: "Total Invoice Amount",
                    amount: "₹${totalAmount.toStringAsFixed(2)}",
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 🔹 Info Card Widget
  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF101010), Color(0xFF1A1A1A)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.65),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color.fromARGB(255, 26, 164, 143),
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Color.fromARGB(255, 26, 164, 143),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Section Title Widget
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color.fromARGB(255, 26, 164, 143),
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
    );
  }
}

// 🔹 Financial Summary Row
class _AccountRow extends StatelessWidget {
  final String label;
  final String amount;

  const _AccountRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        Text(
          amount,
          style: const TextStyle(
            color: Color.fromARGB(255, 26, 164, 143),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _HeaderText extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderText({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FancyRow extends StatelessWidget {
  final String staff;
  final String duration;
  final String calls;
  final String amount;
  final bool isEven;

  const _FancyRow(
    this.staff,
    this.duration,
    this.calls,
    this.amount,
    this.isEven, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: isEven ? const Color(0xFF151515) : const Color(0xFF101010),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!isEven)
            BoxShadow(
              color: const Color.fromARGB(255, 26, 164, 143).withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _DataText(staff),
          _DataText(duration),
          _DataText(calls),
          _DataText(amount),
        ],
      ),
    );
  }
}

class _DataText extends StatelessWidget {
  final String text;
  const _DataText(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
