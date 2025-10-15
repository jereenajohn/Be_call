import 'dart:convert';
import 'package:be_call/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:be_call/call_report.dart';

class CallDetailPage extends StatefulWidget {
  final Map<String, dynamic> call;

  const CallDetailPage({super.key, required this.call});

  @override
  State<CallDetailPage> createState() => _CallDetailPageState();
}

class _CallDetailPageState extends State<CallDetailPage> {
  late TextEditingController customerNameController;
  late TextEditingController durationController;
  late TextEditingController phoneController;
  late TextEditingController invoiceController;
  late TextEditingController amountController;
  late TextEditingController descriptionController;
  late TextEditingController noteController;

  @override
  void initState() {
    super.initState();
    customerNameController = TextEditingController(
      text: widget.call['customer_name'] ?? '',
    );
    durationController = TextEditingController(
      text: widget.call['duration'] ?? '',
    );
    phoneController = TextEditingController(text: widget.call['phone'] ?? '');
    invoiceController = TextEditingController(
      text: widget.call['invoice'] ?? '',
    );
    amountController = TextEditingController(
      text: widget.call['amount']?.toString() ?? '',
    );
    descriptionController = TextEditingController(
      text: widget.call['description'] ?? '',
    );
    noteController = TextEditingController(text: widget.call['note'] ?? '');
  }

  @override
  void dispose() {
    customerNameController.dispose();
    durationController.dispose();
    phoneController.dispose();
    invoiceController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    noteController.dispose();
    super.dispose();
  }

  /// 🔹 Update call details API
  Future<void> updateCallDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final callId = widget.call['id'];

    if (token == null || callId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Missing token or call ID")));
      return;
    }

    // 🔹 Add current date
    final now = DateTime.now();
    final formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // 🔹 Build updated data payload
    final Map<String, dynamic> updatedData = {
      'customer_name': customerNameController.text,
      'duration': durationController.text,
      'phone': phoneController.text.isEmpty ? null : phoneController.text,
      'invoice': invoiceController.text,
      'amount': amountController.text,
      'description': descriptionController.text,
      'note': noteController.text,
      'date': formattedDate,
    };

    // ✅ Automatically set status to "Productive" if invoice added
    if (invoiceController.text.trim().isNotEmpty) {
      updatedData['status'] = 'Productive';
    }

    final url = Uri.parse("$api/api/call/report/$callId/");

    try {
      print("Updating call at $url with data: $updatedData");

      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(updatedData),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(invoiceController.text.trim().isNotEmpty
                ? "✅ Call marked as Productive"
                : "Call updated successfully"),
          ),
        );
          Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallReport(),
        ),
      );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update (${response.statusCode})")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Call Details',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Edit Call Information",
                style: TextStyle(
                  color: Color.fromARGB(255, 26, 164, 143),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              _buildEditableRow("Customer Name", customerNameController),
              _buildEditableRow("Duration", durationController),
              _buildEditableRow("Phone Number", phoneController),
              _buildEditableRow("Invoice Number", invoiceController),
              _buildEditableRow("Amount", amountController),
              _buildEditableRow("Description", descriptionController),
              _buildEditableRow("Note", noteController),

              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: updateCallDetails, // ✅ simplified
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    "Update Call",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 26, 164, 143),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
