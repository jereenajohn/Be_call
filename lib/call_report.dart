import 'package:flutter/material.dart';

class CallReport extends StatefulWidget {
  const CallReport({super.key});

  @override
  State<CallReport> createState() => _CallReportState();
}

class _CallReportState extends State<CallReport> {
  final List<Map<String, dynamic>> activeCalls = List.generate(
    20,
    (i) => {
      'no': i + 1,
      'invoice': 'Customer ${i + 1}',
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
                'Call Report',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Overall calls count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 26, 164, 143),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Calls',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                    Text('${activeCalls.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Active calls section
              _buildExpandableSection(
                title: 'Active Calls',
                total: activeTotal,
                data: activeCalls,
              ),
              const SizedBox(height: 16),

              // Productive calls section
              _buildExpandableSection(
                title: 'Productive Calls',
                total: productiveTotal,
                data: productiveCalls,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required double total,
    required List<Map<String, dynamic>> data,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 26, 164, 143),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ExpansionTile(
        collapsedIconColor: Colors.white,
        iconColor: Colors.white,
        // Title row: heading + total side by side
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 18)),
            Text(
              '₹${total.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        children: [
          // Data Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  MaterialStateProperty.all(const Color.fromARGB(255, 26, 164, 143)),
              columns: const [
                DataColumn(
                    label: Text('No.', style: TextStyle(color: Colors.white))),
                DataColumn(
                    label: Text('Invoice', style: TextStyle(color: Colors.white))),
                DataColumn(
                    label: Text('Amount', style: TextStyle(color: Colors.white))),
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
          // Bottom total row (kept)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
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
