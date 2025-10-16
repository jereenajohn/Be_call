import 'dart:convert';
import 'package:be_call/api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class statewise extends StatefulWidget {
  final String id; // actually the state name, e.g. "Tamil Nadu"
  const statewise({super.key, required this.id});

  @override
  State<statewise> createState() => _statewiseState();
}

class _statewiseState extends State<statewise> {
  List<dynamic> _customers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    print("📍 State Name Received: ${widget.id}");
    _resolveStateIdAndFetch();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _resolveStateIdAndFetch() async {
    try {
      final token = await getToken();
      final url = Uri.parse("$api/api/states/");
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> states = jsonResponse['data'] ?? [];

        // Find matching state by name (case-insensitive)
        final matched = states.firstWhere(
          (s) => (s['name'] ?? '').toString().trim().toLowerCase() ==
              widget.id.trim().toLowerCase(),
          orElse: () => <String, dynamic>{},
        );

        if (matched.isNotEmpty) {
          final int stateId = matched['id'];
          print("✅ Found stateId: $stateId for ${widget.id}");
          await _fetchCustomers(stateId);
        } else {
          print("⚠️ No matching state found for ${widget.id}");
          setState(() => _loading = false);
        }
      } else {
        print("❌ Failed to fetch states: ${response.statusCode}");
        setState(() => _loading = false);
      }
    } catch (e) {
      print("Error resolving state: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchCustomers(int stateId) async {
    print("📞 Fetching customers for stateId: $stateId ...");
    final token = await getToken();

    try {
      final response = await http.get(
        Uri.parse("$api/api/call/report/state/$stateId/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _customers = data;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print("Error fetching customers: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1AA48F),
        title: Text(
          "Calls in ${widget.id}",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _customers.isEmpty
              ? const Center(
                  child: Text(
                    "No calls found for this state",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child:SingleChildScrollView(
  scrollDirection: Axis.vertical,
  child: Table(
    border: TableBorder.all(color: Colors.white24),
    columnWidths: const {
      0: FlexColumnWidth(2.5), // Customer Name
      1: FlexColumnWidth(2),   // Phone
      2: FlexColumnWidth(1.5), // Duration
      3: FlexColumnWidth(1),   // Status
      4: FlexColumnWidth(1.5), // Amount (only for Productive)
    },
    children: [
      // ✅ Header Row
      const TableRow(
        decoration: BoxDecoration(color: Color(0xFF1AA48F)),
        children: [
          Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              "Customer Name",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              "Phone",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              "Duration",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              "Status",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              "Amount",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),

      // ✅ Data Rows
      ..._customers.asMap().entries.map((entry) {
        final index = entry.key;
        final c = entry.value;
        final isProductive = c['status'] == 'Productive';
        final amount = c['amount'];

        return TableRow(
          decoration: BoxDecoration(
            color: index.isEven
                ? Colors.grey.shade900
                : Colors.grey.shade800,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                c['customer_name'] ?? '-',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                c['phone'] ?? '-',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                c['duration'] ?? '-',
                style:
                    const TextStyle(color: Colors.orangeAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                c['status'] ?? '-',
                style: TextStyle(
                  color: isProductive
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                isProductive && amount != null
                    ? '₹${amount.toString()}'
                    : '-',
                style: TextStyle(
                  color: isProductive ? Colors.yellowAccent : Colors.white24,
                  fontWeight:
                      isProductive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      }),
    ],
  ),
),

                ),
    );
  }
}
