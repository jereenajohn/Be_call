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
    _fetchCustomers();
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

  Future<int?> getid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('id');
  }

  List<dynamic> _customers = [];
  bool _loading = true;
  Future<void> _fetchCustomers() async {
    final token = await getToken();
    final id = await getid();

    setState(() => _loading = true);

    try {
      final response = await http.get(
        Uri.parse("$api/api/contact/info/staff/$id/"),
        headers: {"Authorization": "Bearer $token"},
      );
     

      if (response.statusCode == 200) {
        final List<dynamic> items = List<dynamic>.from(
          jsonDecode(response.body),
        );

        // build lookup map
        _phoneToCustomerId.clear();
        for (final c in items) {
          // tolerate different id key names (id or customer_id)
          final dynamic rawId = c['id'] ?? c['customer_id'];
          if (rawId == null) continue;
          final int? cid = rawId is int ? rawId : int.tryParse('$rawId');
          if (cid == null) continue;

          for (final p in _extractPhones(c)) {
            final norm = _normalize(p);
            if (norm.isNotEmpty) {
              // only set if not present to keep first match
              _phoneToCustomerId.putIfAbsent(norm, () => cid);
            }
          }
        }

        setState(() {
          _customers = items;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> sendCallReport({
  required String customerName,
  required String duration,
  required String phone,
  required DateTime callDateTime, // 👈 Added
  int? customerId,
}) async {
  final url = Uri.parse("$api/api/call/report/");
  final token = await getToken();
  if (token == null) return;

  // Format the date-time for backend (e.g. ISO8601)
  final formattedDateTime = callDateTime.toIso8601String();

  final body = <String, dynamic>{
    "customer_name": customerName,
    "duration": duration,
    "status": "Active",
    "phone": phone,
    "call_datetime": formattedDateTime, // 👈 New field
    if (customerId != null) "Customer": customerId,
  };

  try {
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );
print(response.body);
print(response.statusCode);
    if (response.statusCode == 201 || response.statusCode == 200) {
      print("✅ Call report sent successfully");
    } else {
      print("❌ Failed to send call report: ${response.statusCode}");
    }
  } catch (e) {
    print("⚠️ Error sending call report: $e");
  }
}


  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredCalls =
          q.isEmpty
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
  phone: lastCall.number ?? '',
  customerId: _phoneToCustomerId[_normalize(lastCall.number ?? '')],
  callDateTime: DateTime.fromMillisecondsSinceEpoch(lastCall.timestamp ?? 0), // 👈 Added
);


          await prefs.setString('last_reported_call', callKey);
        } else if (lastCall.callType == CallType.missed) {
          // Missed call
         await sendCallReport(
  customerName: lastCall.name ?? lastCall.number ?? 'Unknown',
  duration: "${lastCall.duration} sec",
  phone: lastCall.number ?? '',
  customerId: _phoneToCustomerId[_normalize(lastCall.number ?? '')],
  callDateTime: DateTime.fromMillisecondsSinceEpoch(lastCall.timestamp ?? 0), // 👈 Added
);

          await prefs.setString('last_reported_call', callKey);
        }
      }

      // ✅ Build list for UI
    final list = entries.map(
  (e) => _GroupedCall(
    number: e.number ?? '',
    name: e.name ?? e.number ?? 'Unknown',
    date: DateTime.fromMillisecondsSinceEpoch(e.timestamp ?? 0),
    lastTime: DateTime.fromMillisecondsSinceEpoch(e.timestamp ?? 0),
    callType: e.callType ?? CallType.incoming,
    duration: e.duration ?? 0, // 👈 store duration
  ),
).toList();

      setState(() {
        _allCalls = list;
        _filteredCalls = list;
      });
    }
  }

  // Store a fast lookup: normalizedPhone -> customerId
  final Map<String, int> _phoneToCustomerId = {};

  // Safely normalize to last 10 digits (works for +91 and most formats)
  String _normalize(String n) {
    final digits = n.replaceAll(RegExp(r'\D'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  // Try to read possible phone fields from a customer object
  List<String> _extractPhones(dynamic c) {
    final phones = <String>[];

    // common single fields
    for (final k in ['phone', 'phone_number', 'mobile', 'mobile1', 'mobile2']) {
      final v = c[k];
      if (v is String && v.trim().isNotEmpty) phones.add(v.trim());
    }

    // arrays like ["+91...","..."]
    final arr = c['phones'];
    if (arr is List) {
      for (final p in arr) {
        if (p is String && p.trim().isNotEmpty) phones.add(p.trim());
      }
    }

    // de-dup
    return phones.toSet().toList();
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
              child:
                  _filteredCalls.isEmpty
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                      : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _filteredCalls.length,
                        separatorBuilder:
                            (_, __) =>
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
                           trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _dateLabel(c.date),
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        Text(
          _timeLabel(c.lastTime),
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ],
    ),
    const SizedBox(width: 10),
    IconButton(
      icon: const Icon(Icons.add_circle_outline,
          color: Colors.tealAccent, size: 24),
      tooltip: "Add Call Report",
      onPressed: () async {
        final normPhone = _normalize(c.number);
        final customerId = _phoneToCustomerId[normPhone];
        final customerName = c.name ?? c.number;

        await sendCallReport(
          customerName: customerName,
         duration: "${c.duration} sec",

          phone: c.number,
          callDateTime: c.lastTime,
          customerId: customerId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Call report added successfully"),
            duration: Duration(seconds: 2),
          ),
        );
      },
    ),
  ],
),

                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => CustomerDetailsView(
                                          id: 0,
                                          customerName: c.name ?? c.number,
                                          phoneNumber: c.number,
                                          date: c.lastTime,
                                          stateName: null,
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
  int duration; // 👈 add this

  _GroupedCall({
    required this.number,
    required this.name,
    required this.date,
    required this.lastTime,
    required this.callType,
    required this.duration, // 👈 add this
  });
}

Icon _callTypeIcon(CallType type) {
  const double iconSize = 13;
  switch (type) {
    case CallType.outgoing:
      return const Icon(Icons.call_made, color: Colors.green, size: iconSize);
    case CallType.incoming:
      return const Icon(
        Icons.call_received,
        color: Colors.blue,
        size: iconSize,
      );
    case CallType.missed:
      return const Icon(Icons.call_missed, color: Colors.red, size: iconSize);
    default:
      return const Icon(Icons.call, color: Colors.grey, size: iconSize);
  }
}
