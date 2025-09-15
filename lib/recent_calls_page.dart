import 'package:flutter/material.dart';
import 'package:be_call/customer_details_view.dart';

class RecentCallsPage extends StatefulWidget {
  const RecentCallsPage({super.key});

  @override
  State<RecentCallsPage> createState() => _RecentCallsPageState();
}

class _RecentCallsPageState extends State<RecentCallsPage> {
  final List<Map<String, String>> recentCalls = [
    {'name': 'Customer 1', 'time': 'Today 4:03 PM'},
    {'name': 'Customer 2', 'time': 'Today 4:03 PM'},
    {'name': 'Customer 3', 'time': 'Today 4:03 PM'},
    {'name': 'Customer 4', 'time': 'Today 4:03 PM'},
    {'name': 'Customer 5', 'time': 'Today 4:03 PM'},
    {'name': 'Customer 6', 'time': 'Yesterday 4:03 PM'},
    {'name': 'Customer 7', 'time': 'Yesterday 4:03 PM'},
    {'name': 'Customer 8', 'time': '02 Jan, 2025 4:03 PM'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
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
          // ---------- Search bar ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[850],
                hintText: 'Search',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ---------- List of recent calls ----------
          Expanded(
            child: ListView.separated(
              itemCount: recentCalls.length,
              separatorBuilder: (_, __) =>
                  Divider(color: Colors.grey[800], height: 1),
              itemBuilder: (context, index) {
                final call = recentCalls[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    call['name']!,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Phone',
                    style: TextStyle(color: Colors.white54),
                  ),

                  // ✅ Compact trailing widget to prevent overflow
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            call['time']!,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CustomerDetailsView(
                                    customerName: call['name']!,
                                  ),
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.info_outline,
                              color: Color.fromARGB(255, 26, 164, 143),
                              size: 20, // smaller to fit tile height
                            ),
                          ),
                        ],
                      ),
                    ],
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
