import 'package:be_call/dialerpage.dart';
import 'package:be_call/homepage.dart';
import 'package:be_call/profilepage.dart';
import 'package:flutter/material.dart';

class CallReport extends StatefulWidget {
  const CallReport({super.key});

  @override
  State<CallReport> createState() => _CallReportState();
}

class _CallReportState extends State<CallReport> {
  // Sample data
  final List<Map<String, dynamic>> activeCalls = List.generate(
    20,
    (i) => {
      'no': i + 1,
      'invoice': 'Customer 1',
      'amount': 1700.0,
    },
  );

  final List<Map<String, dynamic>> productiveCalls = [
    {'no': 1, 'invoice': 'MC0001', 'amount': 1500.0},
    {'no': 2, 'invoice': 'MC0002', 'amount': 2500.0},
    {'no': 3, 'invoice': 'MC0003', 'amount': 1600.0},
    {'no': 4, 'invoice': 'MC0004', 'amount': 1700.0},
    {'no': 5, 'invoice': 'MC0005', 'amount': 3000.0},
  ];

  double get activeTotal =>
      activeCalls.fold(0.0, (sum, e) => sum + (e['amount'] as double));
  double get productiveTotal =>
      productiveCalls.fold(0.0, (sum, e) => sum + (e['amount'] as double));
 int _selectedIndex = 1; // Contacts is default

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 2) { // Keypad tapped
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DialerPage()),
      );
    }
      else if (index == 0) { // Keypad tapped
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const Homepage()),
      );
    }
      else if (index == 1) { // Keypad tapped
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const Homepage()),
      );
    }

    
    else if (index == 3) { 
        Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CallReport()),
      );
    }
    else if (index == 4) { 
        Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsPage()),
      );// Reports tapped
      // Navigate to Reports page if implemented
    }
    else if (index == 4) { // Settings tapped
      // Navigate to Settings page if implemented
    }
    // you can add more conditions for other tabs if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Call report',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Total calls summary
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 26, 164, 143),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Total calls',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                    Text('20',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Active calls
              _buildExpandableSection(
                title: 'Active calls',
                data: activeCalls,
                total: activeTotal,
              ),
              const SizedBox(height: 16),

              // Productive calls
              _buildExpandableSection(
                title: 'Productive calls',
                data: productiveCalls,
                total: productiveTotal,
              ),
            ],
          ),
        ),
      ),

      // Bottom navigation bar
      // bottomNavigationBar: BottomNavigationBar(
      //   backgroundColor: Colors.black,
      //   type: BottomNavigationBarType.fixed,
      //   selectedItemColor: const Color.fromARGB(255, 26, 164, 143),
      //   unselectedItemColor: Colors.grey,
      //   currentIndex: _selectedIndex, // highlight Reports
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

  /// Helper widget to build an expandable table section
  Widget _buildExpandableSection({
    required String title,
    required List<Map<String, dynamic>> data,
    required double total,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 26, 164, 143),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ExpansionTile(
        collapsedIconColor: Colors.white,
        iconColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        children: [
          // Table
          Container(
            width: double.infinity,
            color: const Color.fromARGB(255, 26, 164, 143),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    MaterialStateProperty.all(const Color.fromARGB(255, 26, 164, 143)),
                columns: const [
                  DataColumn(
                      label: Text('No.', style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label:
                          Text('Invoice', style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label:
                          Text('Amount', style: TextStyle(color: Colors.white))),
                ],
                rows: data
                    .map(
                      (e) => DataRow(cells: [
                        DataCell(Text('${e['no']}',
                            style: const TextStyle(color: Colors.white))),
                        DataCell(Text('${e['invoice']}',
                            style: const TextStyle(color: Colors.white))),
                        DataCell(Text(
                            '₹${(e['amount'] as double).toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white))),
                      ]),
                    )
                    .toList(),
              ),
            ),
          ),
          // Total Row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 26, 164, 143),
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
