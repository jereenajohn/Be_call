import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    const Color bgColor = Colors.black;
    const Color accentColor = Color(0xFF00B8B8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 26, 164, 143),
        elevation: 4,
        shadowColor: const Color.fromARGB(255, 26, 164, 143).withOpacity(0.4),
        title: const Text(
          'ADMIN DASHBOARD',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color.fromARGB(255, 26, 164, 143)),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting / Header
            const Text(
              "Welcome Back, Admin 👋",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),

            // Top Summary Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCard(Icons.people, "Users", "1,250"),
                _buildInfoCard(Icons.shopping_bag, "Orders", "390"),
                _buildInfoCard(Icons.show_chart, "Sales", "1,045"),
              ],
            ),

            const SizedBox(height: 30),

            // Overview Section
            _buildSectionTitle("Overview"),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    Colors.grey[900]!,
                    Colors.grey[850]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 26, 164, 143).withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.show_chart,
                      color: Color.fromARGB(255, 26, 164, 143), size: 60),
                  const SizedBox(height: 8),
                  Text(
                    "Monthly Performance Graph",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 5,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        colors: [Color.fromARGB(255, 26, 164, 143), Color.fromARGB(255, 26, 164, 143)],
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Recent Orders Section
            _buildSectionTitle("Recent Orders"),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 26, 164, 143).withOpacity(0.2),
                    blurRadius: 8,
                  )
                ],
              ),
              child: Column(
                children: [
                  _buildTableHeader(),
                  const Divider(color: Colors.white10, thickness: 1),
                  _buildOrderRow("#1234", "04/05/2024", "John Doe"),
                  _buildOrderRow("#1233", "04/05/2024", "Jane Smith"),
                  _buildOrderRow("#1232", "04/04/2024", "Michael Brown"),
                  _buildOrderRow("#1231", "04/03/2024", "John Doe"),
                  _buildOrderRow("#1230", "04/02/2024", "Jane Smith"),
                  _buildOrderRow("#1243", "04/01/2024", "Emily White"),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Account Summary Section
            _buildSectionTitle("Account Summary"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 26, 164, 143).withOpacity(0.2),
                    blurRadius: 8,
                  )
                ],
              ),
              child: Column(
                children: const [
                  _AccountRow(label: "Total Balance", amount: "\$199.00"),
                  SizedBox(height: 12),
                  _AccountRow(label: "Pending Payout", amount: "\$99.99"),
                  SizedBox(height: 12),
                  _AccountRow(label: "Transactions", amount: "45"),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Reusable Widgets
  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF101010),
              Color(0xFF1A1A1A),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color.fromARGB(255, 26, 164, 143), size: 32),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Color.fromARGB(255, 26, 164, 143),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color.fromARGB(255, 26, 164, 143),
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }

  Widget _buildTableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("ID",
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          Text("Date",
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          Text("Customer",
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildOrderRow(String id, String date, String customer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(id,
              style:
                  const TextStyle(color: Colors.white, fontSize: 14)),
          Text(date,
              style:
                  const TextStyle(color: Colors.white, fontSize: 14)),
          Text(customer,
              style:
                  const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final String label;
  final String amount;

  const _AccountRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        Text(amount,
            style: const TextStyle(
              color: Color.fromARGB(255, 26, 164, 143),
              fontWeight: FontWeight.bold,
            )),
      ],
    );
  }
}
