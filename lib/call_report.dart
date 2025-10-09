import 'dart:convert';
import 'package:be_call/api.dart';
import 'package:be_call/call_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CallReport extends StatefulWidget {
  const CallReport({super.key});

  @override
  State<CallReport> createState() => _CallReportState();
}

class _CallReportState extends State<CallReport> {
  List<dynamic> activeCalls = [];
  List<dynamic> productiveCalls = [];
  bool isLoading = true;
  Map<String, dynamic>? userDetails;

  @override
  void initState() {
    super.initState();
    fetchCallReports();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idValue = prefs.get('id');
    if (idValue is int) return idValue;
    if (idValue is String) return int.tryParse(idValue);
    return null;
  }

  Future<Map<String, dynamic>?> getUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      return json.decode(userJson);
    }
    return null;
  }
DateTimeRange? selectedRange;

 Future<void> fetchCallReports({DateTimeRange? range}) async {
  try {
    var token = await getToken();
    var userId = await getUserId();
    var user = await getUserDetails();

    if (userId == null) {
      print("No user id found in SharedPreferences");
      return;
    }

    final activeResponse = await http.get(
      Uri.parse('$api/api/call/report/staff/$userId/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final productiveResponse = await http.get(
      Uri.parse('$api/api/call/report/?type=productive'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print('Active response: ${activeResponse.statusCode}');
    print('Productive response: ${productiveResponse.statusCode}');

    if (activeResponse.statusCode == 200 &&
        productiveResponse.statusCode == 200) {
      final activeData = json.decode(activeResponse.body);
      final productiveData = json.decode(productiveResponse.body);

      // Determine date range
      DateTime today = DateTime.now();
      DateTime start = range?.start ?? DateTime(today.year, today.month, today.day);
      DateTime end = range?.end ?? DateTime(today.year, today.month, today.day);

      bool isWithinRange(String? dateString) {
        if (dateString == null || dateString.isEmpty) return false;
        try {
          // Convert from UTC/ISO + timezone to local date
          DateTime date = DateTime.parse(dateString).toLocal();

          // Compare only Y-M-D (ignore time)
          DateTime callDate = DateTime(date.year, date.month, date.day);
          DateTime startDate = DateTime(start.year, start.month, start.day);
          DateTime endDate = DateTime(end.year, end.month, end.day);

          return !callDate.isBefore(startDate) && !callDate.isAfter(endDate);
        } catch (e) {
          return false;
        }
      }

      // Apply filtering to both lists
      List<dynamic> filteredActive = activeData.where((call) {
        return isWithinRange(call['date'] ?? call['created_at']);
      }).toList();

      List<dynamic> filteredProductive = productiveData.where((call) {
        return isWithinRange(call['date'] ?? call['created_at']);
      }).toList();

      setState(() {
        activeCalls = filteredActive;
        productiveCalls = filteredProductive;
        userDetails = user;
        isLoading = false;
      });

      print('Fetched ${filteredActive.length} active calls and ${filteredProductive.length} productive calls');
    } else {
      setState(() {
        isLoading = false;
        userDetails = user;
      });
      print(
        'Error fetching call report: Active=${activeResponse.statusCode}, Productive=${productiveResponse.statusCode}',
      );
    }
  } catch (e) {
    setState(() => isLoading = false);
    print('Exception: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child:
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Call Report',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // User Info
                      if (userDetails != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Logged in as: ${userDetails!['username'] ?? 'Unknown'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              if (userDetails!['email'] != null)
                                Text(
                                  'Email: ${userDetails!['email']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: Text(
        selectedRange == null
            ? 'Showing: Today'
            : 'From: ${selectedRange!.start.toString().split(" ")[0]}  →  To: ${selectedRange!.end.toString().split(" ")[0]}',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    ),
    ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 26, 164, 143),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () async {
        final DateTime now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 1),
          initialDateRange: selectedRange ??
              DateTimeRange(
                start: DateTime(now.year, now.month, now.day),
                end: DateTime(now.year, now.month, now.day),
              ),
        );

        if (picked != null) {
          setState(() {
            selectedRange = picked;
            isLoading = true;
          });
          await fetchCallReports(range: picked);
        }
      },
      icon: const Icon(Icons.calendar_month, color: Colors.white, size: 18),
      label: const Text(
        'Select Dates',
        style: TextStyle(color: Colors.white, fontSize: 13),
      ),
    ),
  ],
),
const SizedBox(height: 20),

                      // Total Calls Summary
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 26, 164, 143),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Calls',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              '${activeCalls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
// 📅 Date Range Selector


                      _expandableTable(
                        title: 'Active Calls',
                        data:
                            activeCalls.where((call) {
                              final d =
                                  call['duration']
                                      ?.toString()
                                      .trim()
                                      .toLowerCase() ??
                                  '';
                              if (d.isEmpty) return false;
                              if (d == '0' ||
                                  d == '0 sec' ||
                                  d == '0s' ||
                                  d == '00:00' ||
                                  d == '00:00:00')
                                return false;
                              return true;
                            }).toList(),
                      ),
                      const SizedBox(height: 16),
                      _expandableTable(
                        title: 'Productive Calls',
                        data:
                            productiveCalls
                                .where(
                                  (call) =>
                                      call['invoice'] != null &&
                                      call['invoice_number']
                                          .toString()
                                          .isNotEmpty,
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

Widget _expandableTable({
  required String title,
  required List<dynamic> data,
}) {
  final isProductive = title == 'Productive Calls';

  // ✅ FIXED FUNCTION
  String getTotalDuration() {
    int totalSeconds = 0;

    for (var call in data) {
      final dynamic duration = call['duration'];
      if (duration == null) continue;

      String durationStr = duration.toString().trim().toLowerCase();

      // Handle formats like "20 sec", "15s", "1 min 30 sec", etc.
      if (durationStr.contains('min') || durationStr.contains('sec')) {
        int minutes = 0;
        int seconds = 0;

        final minMatch = RegExp(r'(\d+)\s*min').firstMatch(durationStr);
        final secMatch = RegExp(r'(\d+)\s*sec').firstMatch(durationStr);

        if (minMatch != null) minutes = int.parse(minMatch.group(1)!);
        if (secMatch != null) seconds = int.parse(secMatch.group(1)!);

        totalSeconds += minutes * 60 + seconds;
        continue;
      }

      // Handle "HH:MM:SS" or "MM:SS" formats
      final parts = durationStr.split(':').map((e) => int.tryParse(e) ?? 0).toList();
      if (parts.length == 3) {
        totalSeconds += parts[0] * 3600 + parts[1] * 60 + parts[2];
      } else if (parts.length == 2) {
        totalSeconds += parts[0] * 60 + parts[1];
      } else if (parts.length == 1) {
        totalSeconds += parts.first;
      }
    }

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String getTotalAmount() {
    double total = data.fold<double>(0, (double sum, dynamic call) {
      final amount = call['amount'];
      if (amount == null) return sum;
      return sum +
          (amount is num
              ? amount.toDouble()
              : double.tryParse(amount.toString()) ?? 0);
    });
    return total.toStringAsFixed(2);
  }

  return Container(
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 26, 164, 143),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // ✅ removes top/bottom lines
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        collapsedIconColor: Colors.white,
        iconColor: Colors.white,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              '${data.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(const Color(0xFF00695C)),
                border: TableBorder.all(color: Colors.white, width: 1),
                columns: isProductive
                    ? const [
                        DataColumn(
                          label: Text(
                            'No.',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Invoice',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Amount',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ]
                    : const [
                        DataColumn(
                          label: Text(
                            'No.',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Customer',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Duration',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                rows: data.isNotEmpty
                    ? data.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final call = entry.value;
                        return DataRow(
                          cells: isProductive
                              ? [
                                  DataCell(Text('$index',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 10))),
                                  DataCell(Text(call['invoice']?.toString() ?? 'N/A',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 10))),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(call['amount']?.toString() ?? 'N/A',
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 10)),
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward_ios,
                                            color: Colors.white, size: 16),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CallDetailPage(call: call),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  )),
                                ]
                              : [
                                  DataCell(Text('$index',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 10))),
                                  DataCell(Text(call['customer_name'] ?? 'N/A',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 10))),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        child: Text(call['duration'] ?? 'N/A',
                                            style: const TextStyle(
                                                color: Colors.white, fontSize: 10),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward_ios,
                                            color: Colors.white, size: 16),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CallDetailPage(call: call),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  )),
                                ],
                        );
                      }).toList()
                    : [
                        DataRow(
                          cells: isProductive
                              ? const [
                                  DataCell(Text('-', style: TextStyle(color: Colors.white))),
                                  DataCell(Text('No Calls', style: TextStyle(color: Colors.white))),
                                  DataCell(Text('-', style: TextStyle(color: Colors.white))),
                                ]
                              : const [
                                  DataCell(Text('-', style: TextStyle(color: Colors.white))),
                                  DataCell(Text('No Calls', style: TextStyle(color: Colors.white))),
                                  DataCell(Text('-', style: TextStyle(color: Colors.white))),
                                ],
                        ),
                      ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: isProductive
                  ? Text(
                      'Total Amount: ₹${getTotalAmount()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    )
                  : Text(
                      'Total Duration: ${getTotalDuration()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

}
