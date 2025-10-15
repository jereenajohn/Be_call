import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomerDetailsView extends StatefulWidget {
  final String customerName;
  final String phoneNumber;
  final dynamic date;
  final String? stateName;

  const CustomerDetailsView({
    super.key,
    required this.customerName,
    required this.phoneNumber,
    required this.date,
    required this.stateName,
  });

  @override
  State<CustomerDetailsView> createState() => _CustomerDetailsViewState();
}

class _CustomerDetailsViewState extends State<CustomerDetailsView> {
  bool saveNotes = false;
  DateTime? _reminderDate;
  final TextEditingController _noteController = TextEditingController();

  List<CallLogEntry> _displayCalls = [];
  String _headerDate = '';

  @override
  void initState() {
    super.initState();
    _fetchCalls();
  }

Future<void> _fetchCalls() async {
  if (!await Permission.phone.request().isGranted) return;

  final logs = await CallLog.query(number: widget.phoneNumber);
  if (logs.isEmpty) return;

  // Define "today" and "yesterday" ranges
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  final yesterdayStart = todayStart.subtract(const Duration(days: 1));
  final yesterdayEnd = todayStart;

  // 1️⃣ Filter today's calls
  List<CallLogEntry> filtered = logs.where((c) {
    final ts = DateTime.fromMillisecondsSinceEpoch(c.timestamp ?? 0);
    return ts.isAfter(todayStart) && ts.isBefore(todayEnd);
  }).toList();

  // 2️⃣ If no calls today → use yesterday
  bool showingYesterday = false;
  if (filtered.isEmpty) {
    filtered = logs.where((c) {
      final ts = DateTime.fromMillisecondsSinceEpoch(c.timestamp ?? 0);
      return ts.isAfter(yesterdayStart) && ts.isBefore(yesterdayEnd);
    }).toList();
    showingYesterday = true;
  }

  // Sort newest first
  filtered.sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));

  // Set header text
  _headerDate = showingYesterday ? 'Yesterday' : 'Today';

  setState(() {
    _displayCalls = filtered;
  });
}

  Future<void> _callDirect(String n) async =>
      FlutterPhoneDirectCaller.callNumber(n);

  Future<void> _pickReminderDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder:
          (ctx, child) => Theme(
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
              // ✅ Gradient replacing the solid color
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF009688), // top: deep teal
                  Color(0xFF26A69A), // bottom: lighter teal
                ],
              ),
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
                Text(
                  widget.customerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.phoneNumber,
                  style: const TextStyle(color: Colors.white70),
                ),

                // --- Curved container with location and icons ---
                Container(
                  margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(129, 13, 125, 114),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.stateName ?? '', // 👈 dynamic state name
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      Row(
                        children: [
                          _circleAction(
                            icon: Icons.call,
                            onTap: () => _callDirect(widget.phoneNumber),
                          ),
                          const SizedBox(width: 12),
                          _circleAction(icon: Icons.message, onTap: () {}),
                          const SizedBox(width: 12),
                          _circleAction(icon: Icons.chat, onTap: () {}),
                        ],
                      ),
                    ],
                  ),
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

                  // ✅ NEW SECTION — Recent Calls
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Calls',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_displayCalls.isEmpty)
                          const Text(
                            'No recent calls',
                            style: TextStyle(color: Colors.white70),
                          )
                        else
                          Column(
                            children:
                                _displayCalls.take(5).map((c) {
                                  final dt =
                                      DateTime.fromMillisecondsSinceEpoch(
                                        c.timestamp ?? 0,
                                      );
                                  final date =
                                      '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}';
                                  final time =
                                      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                  final dur = c.duration ?? 0;
                                  final type = c.callType?.name ?? 'Call';

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '$date $time',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '$type • ${dur}s',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ Existing Notes section below remains same
                  const Text(
                    'Notes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _noteController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 5,
                            enabled: saveNotes,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Type notes here...',
                              hintStyle: TextStyle(color: Colors.white54),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Transform.scale(
                          scale: 1.2,
                          child: Switch(
                            value: saveNotes,
                            activeColor: const Color.fromARGB(
                              255,
                              26,
                              164,
                              143,
                            ),
                            onChanged: (v) {
                              setState(() => saveNotes = v);
                              if (!v) _noteController.clear();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                      ),
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

  Widget _circleAction({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.black26,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
