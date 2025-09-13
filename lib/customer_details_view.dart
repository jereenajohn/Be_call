import 'package:flutter/material.dart';

class CustomerDetailsView extends StatefulWidget {
  final String customerName;
  const CustomerDetailsView({super.key, required this.customerName});

  @override
  State<CustomerDetailsView> createState() => _CustomerDetailsViewState();
}

class _CustomerDetailsViewState extends State<CustomerDetailsView> {
  bool saveNotes = false;
  int _selectedIndex = 0;

  DateTime? _reminderDate;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _pickReminderDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),               // can't pick past dates
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color.fromARGB(255, 26, 164, 143), // header & selected day
              onPrimary: Colors.white,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _reminderDate) {
      setState(() => _reminderDate = picked);
      // You can also schedule a notification or save to DB here
    }
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
                Text(
                  widget.customerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('+91 8086868900',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Chip(
                      label: Text(
                        'Ernakulam',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Color.fromARGB(255, 26, 164, 143),
                    ),
                    const SizedBox(width: 12),
                    _roundIcon(Icons.call),
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
                  const Text(
                    'Today',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Call details in single container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _CallRow('4:03 PM', 'Outgoing call', '11.04 Minutes'),
                        Divider(color: Colors.white24, height: 16),
                        _CallRow('2:15 PM', 'Outgoing call', '7:12 Minutes'),
                        Divider(color: Colors.white24, height: 16),
                        _CallRow('10:15 AM', 'Outgoing call', '7:12 Minutes'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Notes',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          style: const TextStyle(color: Colors.white),
                          maxLines: 3,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Type notes here...',
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Switch(
                              value: saveNotes,
                              onChanged: (v) =>
                                  setState(() => saveNotes = v),
                              activeColor:
                                  const Color.fromARGB(255, 26, 164, 143),
                            ),
                            const Text('Save',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ Reminder button opens date picker
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today, color: Colors.white),
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

      // ---------- Bottom Navigation Bar ----------
      // bottomNavigationBar: BottomNavigationBar(
      //   backgroundColor: Colors.black,
      //   type: BottomNavigationBarType.fixed,
      //   selectedItemColor: const Color.fromARGB(255, 26, 164, 143),
      //   unselectedItemColor: Colors.grey,
      //   currentIndex: _selectedIndex,
      //   onTap: _onItemTapped,
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Calls'),
      //     BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'Contacts'),
      //     BottomNavigationBarItem(icon: Icon(Icons.dialpad), label: 'Keypad'),
      //     BottomNavigationBarItem(icon: Icon(Icons.insert_chart), label: 'Reports'),
      //     BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      //   ],
      // ),
    );
  }

  Widget _roundIcon(IconData icon) {
    return CircleAvatar(
      backgroundColor: Colors.black26,
      child: Icon(icon, color: Colors.white),
    );
  }
}

/// Helper widget for each call row inside the single container
class _CallRow extends StatelessWidget {
  final String time;
  final String type;
  final String duration;
  const _CallRow(this.time, this.type, this.duration);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$time  $type',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 4),
        Text(duration,
            style: const TextStyle(color: Colors.white54, fontSize: 14)),
      ],
    );
  }
}
