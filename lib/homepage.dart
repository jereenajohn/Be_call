import 'package:be_call/customer_details_view.dart';
import 'package:be_call/recent_calls_page.dart';
import 'package:flutter/material.dart';
import 'package:be_call/call_report.dart';
import 'package:be_call/dialerpage.dart';
import 'package:be_call/profilepage.dart'; // <- your Settings page file

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 1; // Contacts tab is default

  final List<String> customers = [
    'Customer 1',
    'Customer 2',
    'Customer 3',
    'Customer 4',
    'Customer 5',
    'Customer 6',
    'Customer 7',
  ];

  // Build all tab pages once so they're ready immediately
  late final List<Widget> _pages = [
    const RecentCallsPage(),
    _buildContactsPage(), // index 0  -> Contacts
    // index 1  -> Calls
    const DialerPage(), // index 2
    const CallReport(), // index 3
    const SettingsPage(), // index 4
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // swap body based on the selected bottom-nav item
      body: SafeArea(child: _pages[_selectedIndex]),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 26, 164, 143),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Calls'),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contacts',
          ),

          BottomNavigationBarItem(icon: Icon(Icons.dialpad), label: 'Keypad'),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  // ---- Individual page widgets ----

  Widget _buildCallsPage() {
    return const Center(
      child: Text('Calls Page', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildContactsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Contacts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(30),
            ),
            child: const TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                icon: Icon(Icons.search, color: Colors.grey),
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.black),
                ),
                title: Text(
                  customers[index],
                  style: const TextStyle(color: Colors.white),
                ),
                // 👇 Add this
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CustomerDetailsView(
                            customerName: customers[index],phoneNumber: '8157845851',date: null,
                          ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
