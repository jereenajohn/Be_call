import 'package:be_call/call_report.dart';
import 'package:be_call/homepage.dart';
import 'package:be_call/profilepage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class DialerPage extends StatefulWidget {
  const DialerPage({super.key});

  @override
  State<DialerPage> createState() => _DialerPageState();
}

class _DialerPageState extends State<DialerPage> {
  String enteredNumber = '';

  void _appendDigit(String digit) {
    setState(() => enteredNumber += digit);
  }

  void _deleteDigit() {
    if (enteredNumber.isNotEmpty) {
      setState(() {
        enteredNumber = enteredNumber.substring(0, enteredNumber.length - 1);
      });
    }
  }

  int _selectedIndex = 1; // Contacts is default

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 2) {
      // Keypad tapped
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DialerPage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CallReport()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const Homepage()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsPage()),
      ); // Reports tapped
      // Navigate to Reports page if implemented
    } else if (index == 4) {
      // Settings tapped
      // Navigate to Settings page if implemented
    }
    // you can add more conditions for other tabs if needed
  }

  Widget _buildKey(String label) {
    return GestureDetector(
      onTap: () => _appendDigit(label),
      child: CircleAvatar(
        radius: 35,
        backgroundColor: Colors.grey[850],
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 28),
        ),
      ),
    );
  }

  Future<bool> _ensureCallPermission() async {
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      status = await Permission.phone.request();
    }
    return status.isGranted;
  }

  Future<void> _makeDirectCall(String number) async {
    if (await _ensureCallPermission()) {
      await FlutterPhoneDirectCaller.callNumber(number);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Call permissions denied')),
      );
    }
  }
     
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // push the number display downward
            const SizedBox(height: 120), // adjust this to taste

            // Dialed number row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      enteredNumber,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  if (enteredNumber.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.backspace, color: Colors.white),
                      onPressed: _deleteDigit,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Keypad stays fixed below the number display
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['*', '0', '#'],
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row.map(_buildKey).toList(),
                      ),
                    ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      if (enteredNumber.isNotEmpty) {
                        _makeDirectCall(enteredNumber);
                      } else { 
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a number')),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: const Color.fromARGB(255, 26, 164, 143),
                      child: const Icon(Icons.call,
                          color: Colors.black, size: 32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom navigation bar
      // bottomNavigationBar: BottomNavigationBar(
      //   backgroundColor: Colors.black,
      //   type: BottomNavigationBarType.fixed,
      //   selectedItemColor: const Color.fromARGB(255, 26, 164, 143),
      //   unselectedItemColor: Colors.grey,
      //   currentIndex: _selectedIndex,
      //          onTap: _onItemTapped,

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
}

// AndroidManifest.xml
// <uses-permission android:name="android.permission.CALL_PHONE"/>
