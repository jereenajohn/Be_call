import 'dart:convert';
import 'package:be_call/api.dart';
import 'package:http/http.dart' as https;
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
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController durationController;
  late TextEditingController phoneController;
  late TextEditingController invoiceController;
  late TextEditingController amountController;
  late TextEditingController descriptionController;
  late TextEditingController noteController;
  late TextEditingController emailController;
  int? _customerId; // store created contact id

  List<dynamic> _states = [];
  String? _selectedState;
  bool _loadingStates = false;
  bool _loading = true;
  bool _stateLoading = true;

 @override
void initState() {
  super.initState();

  // ✅ Safely handle both object and integer for "Customer"
  dynamic customerData = widget.call['Customer'];
  Map<String, dynamic>? customer;

  if (customerData is Map<String, dynamic>) {
    // if backend returned full customer object
    customer = customerData;
  } else {
    // if backend only returned an ID (int)
    customer = null;
  }

  // ✅ Try to get name properly
  final fullName = customer != null
      ? '${customer['first_name'] ?? ''} ${customer['last_name'] ?? ''}'.trim()
      : widget.call['customer_name'] ?? '';

  final nameParts = fullName.split(' ');
  final firstName = nameParts.isNotEmpty ? nameParts.first : '';
  final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

  // ✅ Properly handle email (check multiple possible sources)
  String email = '';
  if (widget.call['email'] != null &&
      widget.call['email'].toString().isNotEmpty) {
    email = widget.call['email'];
  } else if (customer != null &&
      customer['email'] != null &&
      customer['email'].toString().isNotEmpty) {
    email = customer['email'];
  }

  // ✅ Initialize controllers
  firstNameController = TextEditingController(text: firstName);
  lastNameController = TextEditingController(text: lastName);
  emailController = TextEditingController(text: email);
  durationController =
      TextEditingController(text: widget.call['duration'] ?? '');
  phoneController = TextEditingController(text: widget.call['phone'] ?? '');
  invoiceController = TextEditingController(text: widget.call['invoice'] ?? '');
  amountController =
      TextEditingController(text: widget.call['amount']?.toString() ?? '');
  descriptionController =
      TextEditingController(text: widget.call['description'] ?? '');
  noteController = TextEditingController(text: widget.call['note'] ?? '');

  _selectedState = null;
  _fetchStates();

  // ✅ Optional: if only Customer ID given, auto-fetch details
  if (widget.call['Customer'] is int) {
    _fetchCustomerEmail(widget.call['Customer']);
  }
}

Future<void> _fetchCustomerEmail(int id) async {
  try {
    final token = await getToken();
    final url = Uri.parse('$api/api/contact/info/$id/');
    final response =
        await https.get(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        emailController.text = data['email'] ?? '';
        firstNameController.text = data['first_name'] ?? '';
        lastNameController.text = data['last_name'] ?? '';
      });
      print("📩 Loaded contact info from ID $id");
    } else {
      print("⚠️ Could not fetch contact info ($id): ${response.statusCode}");
    }
  } catch (e) {
    print("⚠️ Error fetching contact info: $e");
  }
}


  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<int?> getid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('id');
  }

  Future<void> saveContact() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      if (token == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Missing token")));
        return;
      }

      final url = Uri.parse('$api/api/contact/info/');
      final body = {
        "first_name": firstNameController.text.trim(),
        "last_name": lastNameController.text.trim(),
        "phone": phoneController.text.trim(),
        "email": emailController.text.trim(),
        "state": int.tryParse(_selectedState ?? '0'),
      };

      print("📤 Saving contact: $body");

      final response = await https.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      print("📥 Response: ${response.statusCode} → ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        _customerId = data['id']; // ✅ capture ID from response
        print("✅ Contact saved successfully with ID: $_customerId");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Contact saved successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️ Failed to save contact (${response.statusCode})"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving contact: $e")));
    }
  }

  Future<void> _fetchStates() async {
    setState(() => _loadingStates = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final url = Uri.parse('$api/api/states/');
      final response = await https.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ✅ Your state list is inside 'data'
        final List<dynamic> stateList = data['data'] ?? [];

        setState(() {
          _states = stateList;

          // ✅ Match the existing state_name to set pre-selected value
          final existingName = widget.call['state_name'];
          if (existingName != null) {
            final match = _states.firstWhere(
              (s) =>
                  s['name'].toString().toLowerCase() ==
                  existingName.toString().toLowerCase(),
              orElse: () => {},
            );
            if (match.isNotEmpty) {
              _selectedState = match['id'].toString();
            }
          }

          _loadingStates = false;
        });

        print("✅ States fetched: ${_states.length}");
        print("🔹 Preselected State ID: $_selectedState");
      } else {
        print("❌ Failed to fetch states: ${response.statusCode}");
        setState(() => _loadingStates = false);
      }
    } catch (e) {
      print("⚠️ State fetch error: $e");
      setState(() => _loadingStates = false);
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    durationController.dispose();
    phoneController.dispose();
    invoiceController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    noteController.dispose();
    emailController.dispose();
    super.dispose();
  }

  /// 🔹 Update call details API (same logic, just sending first_name / last_name separately)
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

    final now = DateTime.now();
    final formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final Map<String, dynamic> updatedData = {
      'first_name': firstNameController.text,
      'last_name': lastNameController.text,
      'duration': durationController.text,
      'phone': phoneController.text.isEmpty ? null : phoneController.text,
      'invoice': invoiceController.text,
      'amount': amountController.text,
      'description': descriptionController.text,
      'note': noteController.text,
      'date': formattedDate,
    };

    // ✅ Fix: use "Customer" (capital C) to match backend
    if (_customerId != null) {
      updatedData['Customer'] = _customerId;
      print("🔗 Added Customer ID to update body: $_customerId");
    }

    if (invoiceController.text.trim().isNotEmpty) {
      updatedData['status'] = 'Productive';
    }

    final url = Uri.parse("$api/api/call/report/$callId/");

    try {
      print("📤 Sending update body: $updatedData");
      final response = await https.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(updatedData),
      );

      print(
        "📥 Update Call Response: ${response.statusCode} → ${response.body}",
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              invoiceController.text.trim().isNotEmpty
                  ? "✅ Call marked as Productive"
                  : "Call updated successfully",
            ),
          ),
        );
      
        Navigator.push(context, MaterialPageRoute(builder: (context)=>CallReport()));
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

              // 🔹 First / Last Name fields
              Row(
                children: [
                  Expanded(
                    child: _buildEditableRow("First Name", firstNameController),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildEditableRow("Last Name", lastNameController),
                  ),
                ],
              ),
              _buildEditableRow("Email", emailController),
              _buildEditableRow("Duration", durationController),
              _buildEditableRow("Phone Number", phoneController),
              _buildEditableRow("Invoice Number", invoiceController),
              _buildEditableRow("Amount", amountController),
              _buildEditableRow("Description", descriptionController),
              _buildEditableRow("Note", noteController),

              const SizedBox(height: 10),

              const Text(
                "State",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              _loadingStates
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  )
                  : DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF2A2A2A),
                    value: _selectedState,
                    hint: const Text(
                      "Select State",
                      style: TextStyle(color: Colors.white70),
                    ),
                    items:
                        _states.map<DropdownMenuItem<String>>((s) {
                          return DropdownMenuItem<String>(
                            value: s['id'].toString(),
                            child: Text(
                              s['name'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                    onChanged: (v) => setState(() => _selectedState = v),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),

              const SizedBox(height: 20),

              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await saveContact(); // ✅ Save contact first
                    await updateCallDetails(); // ✅ Then update call
                  },
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
