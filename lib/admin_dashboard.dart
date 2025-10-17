import 'dart:convert';
import 'package:be_call/api.dart';
import 'package:be_call/callreport_date_wise.dart';
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
  double totalAmount = 0.0;
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
    getDateWise(today, today);
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

  Future<void> getDateWise(DateTime from, DateTime to) async {
    setState(() {
      isLoading = true;
    });

    var token = await getToken();
    String fromStr = DateFormat('yyyy-MM-dd').format(from);
    String toStr = DateFormat('yyyy-MM-dd').format(to);

    try {
      var res = await http.get(
        Uri.parse("$api/api/call/report/?from=$fromStr&to=$toStr"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode != 200) {
        // fallback to single-day endpoint
        res = await http.get(
          Uri.parse("$api/api/call/report/date/$fromStr/"),
          headers: {"Authorization": "Bearer $token"},
        );
      }

      if (res.statusCode == 200) {
        List<dynamic> data = jsonDecode(res.body);
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
          groupedData =
              grouped.entries
                  .map(
                    (e) => {
                      'name': e.key,
                      'count': e.value['count'],
                      'duration': e.value['duration'],
                      'amount': e.value['amount'],
                    },
                  )
                  .toList();
          isLoading = false;
        });
      } else {
        print("Failed: ${res.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error: $e");
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
        setState(() {
          allCalls = data;
          filteredCalls = allCalls; // Initially show all calls
print("All Calls: $allCalls");
         
          isLoading = false;
        });
        print("✅ Loaded ${allCalls.length} call records");
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
          totalRecords = data['total_records'] ?? 0;
          productiveCount = data['productive_count'] ?? 0;
          totalAmount = data['total_amount'] ?? 0.0;
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
            Text(
              "Welcome back, ${_username ?? 'Admin'} 👋",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),

            // Summary Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCard(Icons.people, "Staffs", "65"),
                _buildInfoCard(
                  Icons.receipt_long_rounded,
                  "Invoices",
                  "$productiveCount",
                ),
                _buildInfoCard(Icons.call, "Calls", "$totalRecords"),
              ],
            ),

            const SizedBox(height: 30),
            // Staff Performance Overview Section
            _buildSectionTitle("Staff Performance Overview"),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0E0E0E), Color(0xFF1A1A1A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(
                      255,
                      26,
                      164,
                      143,
                    ).withOpacity(0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header Row
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 26, 164, 143),
                          Color.fromARGB(255, 18, 110, 96),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(
                            255,
                            26,
                            164,
                            143,
                          ).withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        _HeaderText(icon: Icons.person_outline, label: "Staff"),
                        _HeaderText(
                          icon: Icons.access_time,
                          label: "Total Duration",
                        ),
                        _HeaderText(
                          icon: Icons.call,
                          label: "Productive Calls",
                        ),
                        _HeaderText(
                          icon: Icons.currency_rupee,
                          label: "Total Amount",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Data Rows
                  // Data Rows (dynamic)
                  isLoading
                      ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          color: Color.fromARGB(255, 26, 164, 143),
                        ),
                      )
                      : Column(
                        children:
                            groupedData.isEmpty
                                ? const [
                                  Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      "No data available for today",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ]
                                : groupedData.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final item = entry.value;
                                  final hours =
                                      (item['duration'] / 3600).floor();
                                  final minutes =
                                      ((item['duration'] % 3600) / 60).floor();

                                  return _FancyRow(
                                    item['name'],
                                    "${hours}h ${minutes}m",
                                    item['count'].toString(),
                                    "₹${item['amount'].toStringAsFixed(2)}",
                                    i.isEven,
                                  );
                                }).toList(),
                      ),

                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CallreportDateWise(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color.fromARGB(255, 26, 164, 143),
                        size: 15,
                      ),
                      label: const Text(
                        "See More",
                        style: TextStyle(
                          color: Color.fromARGB(255, 26, 164, 143),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
          
// 📊 State Summary Section
_buildSectionTitle("State Summary"),
const SizedBox(height: 10),
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.grey[900],
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: const Color.fromARGB(255, 26, 164, 143).withOpacity(0.45),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  ),
  child: stateSummary.isEmpty
      ? const Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "No state data available",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        )
      : Column(
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    "State",
                    style: TextStyle(
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
               
                Expanded(
                  child: Text(
                    "Productive",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Amount",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            // Data Rows
            ...stateSummary.entries.map((entry) {
              final state = entry.key;
              final data = entry.value;
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF101010),
                ),
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        state,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    
                    Expanded(
                      child: Text(
                        "${data['Productive']}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "₹${(data['Amount'] as double).toStringAsFixed(2)}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 26, 164, 143),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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
              color: Colors.teal.withOpacity(0.45),
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
