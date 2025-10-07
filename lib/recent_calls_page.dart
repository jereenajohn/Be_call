import 'dart:convert';
import 'package:be_call/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:call_log/call_log.dart';
import 'customer_details_view.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class RecentCallsPage extends StatefulWidget {
  const RecentCallsPage({super.key});

  @override
  State<RecentCallsPage> createState() => _RecentCallsPageState();
}

class _RecentCallsPageState extends State<RecentCallsPage> {
  List<_GroupedCall> _allCalls = [];
  List<_GroupedCall> _filteredCalls = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCalls();
    _searchCtrl.addListener(_onSearch);
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
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

  Future<String?> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('name');
  }

  Future<void> sendCallReport({
    required String customerName,
    required String duration,
  }) async {
    print("Preparing to send call report for $customerName, duration: $duration");
    final url = Uri.parse("$api/api/call/report/");

    final token = await getToken();
    final userId = await getUserId();
    final userName = await getUserName();

    if (token == null) {
      print("❌ No token found, cannot send call report");
      return;
    }

    final body = {
      "customer_name": customerName,
      "duration": duration,
      "status": "Active",
      // "created_by": userName ?? userId?.toString() ?? "Unknown",
    };

    try {
      print("Sending call report: $body");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      print("Response status: ${response.statusCode}");
      print("Response body;;;;;;;;;;;;;;;: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("✅ Call report sent successfully: ${response.body}");
      } else {
        print("⚠️ Failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Error sending call report: $e");
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredCalls = q.isEmpty
          ? _allCalls
          : _allCalls
              .where(
                (c) =>
                    (c.name ?? '').toLowerCase().contains(q) ||
                    c.number.toLowerCase().contains(q),
              )
              .toList();
    });
  }

  Future<void> _loadCalls() async {
    if (await Permission.phone.request().isGranted &&
        await Permission.contacts.request().isGranted) {
      final entries = await CallLog.get();

      if (entries.isEmpty) return;

      // ✅ Take the most recent call (first entry)
      final lastCall = entries.first;

      if (lastCall.timestamp == null || lastCall.number == null) return;

      final prefs = await SharedPreferences.getInstance();
      final callKey = "${lastCall.number}_${lastCall.timestamp}";
      final lastReportedKey = prefs.getString('last_reported_call');

      // --- 📞 Only send if this call is new ---
      if (callKey != lastReportedKey) {
        if ((lastCall.callType == CallType.outgoing ||
                lastCall.callType == CallType.incoming) &&
            (lastCall.duration != null && lastCall.duration! > 0)) {
          // Completed call
          await sendCallReport(
            customerName: lastCall.name ?? lastCall.number ?? 'Unknown',
            duration: "${lastCall.duration} sec",
          );
          await prefs.setString('last_reported_call', callKey);
        } else if (lastCall.callType == CallType.missed) {
          // Missed call
          await sendCallReport(
            customerName: lastCall.name ?? lastCall.number ?? 'Unknown',
            duration: "0 sec",
          );
          await prefs.setString('last_reported_call', callKey);
        }
      }

      // ✅ Build list for UI
      final list = entries
          .map(
            (e) => _GroupedCall(
              number: e.number ?? '',
              name: e.name ?? e.number ?? 'Unknown',
              date: DateTime.fromMillisecondsSinceEpoch(e.timestamp ?? 0),
              lastTime: DateTime.fromMillisecondsSinceEpoch(e.timestamp ?? 0),
              callType: e.callType ?? CallType.incoming,
            ),
          )
          .toList();

      setState(() {
        _allCalls = list;
        _filteredCalls = list;
      });
    }
  }

  String _normalize(String n) {
    final digits = n.replaceAll(RegExp(r'\D'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  String _dateLabel(DateTime d) {
    final today = DateTime.now();
    final yest = today.subtract(const Duration(days: 1));
    if (d.year == today.year && d.month == today.month && d.day == today.day) {
      return 'Today';
    } else if (d.year == yest.year &&
        d.month == yest.month &&
        d.day == yest.day) {
      return 'Yesterday';
    }
    return DateFormat('dd MMM yyyy').format(d);
  }

  String _timeLabel(DateTime dt) =>
      DateFormat('h:mm a').format(dt); // e.g. 4:03 PM

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Recents',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white10,
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                hintText: 'Search',
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ✅ Pull-to-refresh for list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadCalls,
              color: Colors.orange,
              backgroundColor: Colors.black,
              child: _filteredCalls.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _filteredCalls.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: Colors.grey[800], height: 1),
                      itemBuilder: (context, i) {
                        final c = _filteredCalls[i];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.white10,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (c.name != null &&
                                          c.name!.trim().isNotEmpty)
                                      ? c.name!
                                      : c.number,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _callTypeIcon(c.callType),
                            ],
                          ),
                          subtitle: const Text(
                            'Phone',
                            style: TextStyle(color: Colors.white54),
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _dateLabel(c.date),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _timeLabel(c.lastTime),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailsView(
                                customerName: c.name ?? c.number,
                                phoneNumber: c.number,
                                date: c.lastTime,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedCall {
  final String number;
  String? name;
  final DateTime date;
  DateTime lastTime;
  CallType callType;

  _GroupedCall({
    required this.number,
    required this.name,
    required this.date,
    required this.lastTime,
    required this.callType,
  });
}

Icon _callTypeIcon(CallType type) {
  const double iconSize = 13;
  switch (type) {
    case CallType.outgoing:
      return const Icon(Icons.call_made, color: Colors.green, size: iconSize);
    case CallType.incoming:
      return const Icon(Icons.call_received, color: Colors.blue, size: iconSize);
    case CallType.missed:
      return const Icon(Icons.call_missed, color: Colors.red, size: iconSize);
    default:
      return const Icon(Icons.call, color: Colors.grey, size: iconSize);
  }
}
