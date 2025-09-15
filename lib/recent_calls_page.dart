import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:call_log/call_log.dart';
import 'customer_details_view.dart';
import 'package:intl/intl.dart';


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

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredCalls = q.isEmpty
          ? _allCalls
          : _allCalls
              .where((c) =>
                  (c.name ?? '').toLowerCase().contains(q) ||
                  c.number.toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _loadCalls() async {
    if (await Permission.phone.request().isGranted &&
        await Permission.contacts.request().isGranted) {
      final entries = await CallLog.get();
      final Map<String, _GroupedCall> bucket = {};

      for (final e in entries) {
        if (e.timestamp == null || e.number == null) continue;
        final dt = DateTime.fromMillisecondsSinceEpoch(e.timestamp!);
        final dayKey = DateTime(dt.year, dt.month, dt.day);
        final numKey = _normalize(e.number!);
        final key = '$numKey|$dayKey';

        bucket.putIfAbsent(
          key,
          () => _GroupedCall(
            number: numKey,
            name: e.name ?? e.number ?? 'Unknown',
            date: dayKey,
            lastTime: dt,
          ),
        );

        final g = bucket[key]!;
        if (dt.isAfter(g.lastTime)) g.lastTime = dt;
        if ((g.name == 'Unknown' || g.name == null) && e.name != null) {
          g.name = e.name!;
        }
      }

      final list = bucket.values.toList()
        ..sort((a, b) => b.lastTime.compareTo(a.lastTime));
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
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search bar
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
          Expanded(
            child: _filteredCalls.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : ListView.separated(
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
                        title: Text(
  (c.name != null && c.name!.trim().isNotEmpty) ? c.name! : c.number,
  style: const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w500,
    fontSize: 16,
  ),
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
                                  color: Colors.white, fontSize: 14),
                            ),
                            Text(
                              _timeLabel(c.lastTime),
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 13),
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
  _GroupedCall({
    required this.number,
    required this.name,
    required this.date,
    required this.lastTime,
  });
}
