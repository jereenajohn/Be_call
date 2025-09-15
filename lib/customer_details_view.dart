import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomerDetailsView extends StatefulWidget {
  final String customerName;
  final String phoneNumber;
  var date;
   CustomerDetailsView({
    super.key,
    required this.customerName,
    required this.phoneNumber,
    required this.date,
  });

  @override
  State<CustomerDetailsView> createState() => _CustomerDetailsViewState();
}

class _CustomerDetailsViewState extends State<CustomerDetailsView> {
  bool saveNotes = false;
  DateTime? _reminderDate;

  List<CallLogEntry> _displayCalls = [];
  String _headerDate = '';   // ✅ shows the date above call list

  @override
  void initState() {
    super.initState();
    _fetchCalls();
  }

Future<void> _fetchCalls() async {
  if (!await Permission.phone.request().isGranted) return;

  // All call logs for this number
  final logs = await CallLog.query(number: widget.phoneNumber);
  if (logs.isEmpty) return;

  // --- Use the date coming from widget.date instead of today ---
  final selectedDate = widget.date is DateTime
      ? widget.date as DateTime
      : DateTime.parse(widget.date.toString());

  // Start and end boundaries for that day
  final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  final end = start.add(const Duration(days: 1));

  // Filter logs whose timestamp lies within the selected date
  final matching = logs.where((c) {
    final ts = DateTime.fromMillisecondsSinceEpoch(c.timestamp ?? 0);
    return ts.isAfter(start) && ts.isBefore(end);
  }).toList()
    ..sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));

  // ✅ If the selected date is today, show “Today”, else formatted date
  final now = DateTime.now();
  final isToday = start.year == now.year &&
      start.month == now.month &&
      start.day == now.day;

  _headerDate = isToday
      ? 'Today'
      : '${start.day}-${start.month}-${start.year}';

  _displayCalls = matching;

  setState(() {});
}


  Future<void> _callDirect(String n) async =>
      FlutterPhoneDirectCaller.callNumber(n);

  Future<void> _pickReminderDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color.fromARGB(255, 26, 164, 143),
            onPrimary: Colors.white,
            surface: Colors.black,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _reminderDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // ---------- Header ----------
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 24),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 26, 164, 143),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 50, color: Colors.black),
                ),
                const SizedBox(height: 8),
                Text(widget.customerName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text(widget.phoneNumber,
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Chip(
                      label: Text('Ernakulam',
                          style: TextStyle(color: Colors.white)),
                      backgroundColor: Color.fromARGB(255, 26, 164, 143),
                    ),
                    const SizedBox(width: 12),
                    _roundIcon(Icons.call,
                        onTap: () => _callDirect(widget.phoneNumber)),
                    const SizedBox(width: 12),
                    _roundIcon(Icons.message),
                    const SizedBox(width: 12),
                    _roundIcon(Icons.chat),
                  ],
                ),
              ],
            ),
          ),

          // ---------- Body ----------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.date != null)
                 Text(
  _headerDate.isEmpty ? 'Loading…' : _headerDate,
  style: const TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

                  const SizedBox(height: 8),

                  // call log list (design unchanged)
                  if(widget.date != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _displayCalls.isEmpty
                        ? const Text('No call history',
                            style: TextStyle(color: Colors.white70))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _displayCalls.map((c) {
                              final dt = DateTime.fromMillisecondsSinceEpoch(
                                  c.timestamp ?? 0);
                              final time =
                                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                              final dur = c.duration ?? 0;
                              final type = c.callType?.name ?? 'Call';
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$time  $type',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text('$dur sec',
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 14)),
                                  const Divider(
                                      color: Colors.white24, height: 16),
                                ],
                              );
                            }).toList(),
                          ),
                  ),

                  // ---- Rest of your widgets unchanged ----
                  const SizedBox(height: 20),
                  const Text('Notes',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Type notes here...',
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today,
                          color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[850],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _pickReminderDate,
                      label: Text(
                        _reminderDate == null
                            ? 'Set Reminder'
                            : 'Reminder: ${_reminderDate!.day}-${_reminderDate!.month}-${_reminderDate!.year}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: CircleAvatar(
          backgroundColor: Colors.black26,
          child: Icon(icon, color: Colors.white),
        ),
      );
}
