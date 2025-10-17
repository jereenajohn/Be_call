import 'dart:convert';
import 'package:be_call/api.dart';
import 'package:be_call/homepage.dart';
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

  int? _customerId;
  List<dynamic> _customers = [];
  List<dynamic> _states = [];
  String? _selectedState;
  bool _loadingStates = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    _fetchStates();

    dynamic customerData = widget.call['Customer'];
    Map<String, dynamic>? customer;

    if (customerData is Map<String, dynamic>) {
      customer = customerData;
    }

    final fullName = customer != null
        ? '${customer['first_name'] ?? ''} ${customer['last_name'] ?? ''}'.trim()
        : widget.call['customer_name'] ?? '';

    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    firstNameController = TextEditingController(text: firstName);
    lastNameController = TextEditingController(text: lastName);
    durationController = TextEditingController(text: widget.call['duration'] ?? '');
    phoneController = TextEditingController(text: widget.call['phone'] ?? '');
    invoiceController = TextEditingController(text: widget.call['invoice'] ?? '');
    amountController = TextEditingController(text: widget.call['amount']?.toString() ?? '');
    descriptionController = TextEditingController(text: widget.call['description'] ?? '');
    noteController = TextEditingController(text: widget.call['note'] ?? '');

    phoneController.addListener(() {
      if (phoneController.text.trim().length >= 6) {
        _checkExistingCustomerByPhone();
      }
    });
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<int?> getid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('id');
  }

  Future<void> _fetchCustomers() async {
    var token = await getToken();
    var id = await getid();

    setState(() => _loading = true);
    try {
      var response = await https.get(
        Uri.parse("$api/api/contact/info/staff/$id/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          _customers = List<dynamic>.from(jsonDecode(response.body));
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() {
        _customers = [];
        _loading = false;
      });
    }
  }

  void _checkExistingCustomerByPhone() async {
    final inputPhone = phoneController.text.trim();
    if (inputPhone.isEmpty) return;

    String normalizedInput = inputPhone.replaceAll(RegExp(r'\s+'), '');
    normalizedInput = normalizedInput.replaceAll('+91', '');

    for (var customer in _customers) {
      String customerPhone = (customer['phone'] ?? '').replaceAll(RegExp(r'\s+'), '');
      customerPhone = customerPhone.replaceAll('+91', '');

      if (customerPhone.endsWith(normalizedInput) ||
          normalizedInput.endsWith(customerPhone)) {
        setState(() {
          firstNameController.text = customer['first_name'] ?? '';
          lastNameController.text = customer['last_name'] ?? '';
          _selectedState = customer['state']?.toString();
          _customerId = customer['id'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Existing customer found: ${customer['first_name']}")),
        );
        return;
      }
    }
  }

  Future<void> saveContact() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      if (token == null) return;

      final phone = phoneController.text.trim();
      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠️ Phone number is required")));
        return;
      }

      final checkUrl = Uri.parse('$api/api/contact/info/?search=$phone');
       print("🔍 Checking existing contact: $checkUrl");
      final checkResponse = await https.get(
        checkUrl,
        headers: {"Authorization": "Bearer $token"},
      );
 print("📥 Response: ${checkResponse.statusCode} → ${checkResponse.body}");
      if (checkResponse.statusCode == 200) {
        final List<dynamic> existingContacts = json.decode(checkResponse.body);
        if (existingContacts.isNotEmpty) {
          final existing = existingContacts.first;
          final int existingId = existing['id'];
          _customerId = existingId;

          final updateUrl = Uri.parse('$api/api/contact/info/$existingId/');
          final updateBody = {
            "first_name": firstNameController.text.trim(),
            "last_name": lastNameController.text.trim(),
            "phone": phone,
            "state": int.tryParse(_selectedState ?? '0'),
          };
  print("📝 Updating existing contact → $updateUrl");
          print("📤 Body: $updateBody");
          final updateResponse = await https.put(
            updateUrl,
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
            body: jsonEncode(updateBody),
          );
 print("📥 Update Response: ${updateResponse.statusCode} → ${updateResponse.body}");
          if (updateResponse.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Existing contact updated")));
          }
          return;
        }
      }

      final createUrl = Uri.parse('$api/api/contact/info/');
      final createBody = {
        "first_name": firstNameController.text.trim(),
        "last_name": lastNameController.text.trim(),
        "phone": phone,
        "state": int.tryParse(_selectedState ?? '0'),
      };
 print("🆕 Creating new contact → $createUrl");
      print("📤 Body: $createBody");
      final createResponse = await https.post(
        createUrl,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(createBody),
      );
  print("📥 Create Response: ${createResponse.statusCode} → ${createResponse.body}");
      if (createResponse.statusCode == 201 || createResponse.statusCode == 200) {
        final data = json.decode(createResponse.body);
        _customerId = data['id'];
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ New contact created successfully")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving contact: $e")));
    }
  }

  Future<void> _fetchStates() async {
    setState(() => _loadingStates = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await https.get(
        Uri.parse('$api/api/states/'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> stateList = data['data'] ?? [];

        setState(() {
          _states = stateList;
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
      } else {
        setState(() => _loadingStates = false);
      }
    } catch (e) {
      setState(() => _loadingStates = false);
    }
  }

  Future<void> updateCallDetails() async {
     print("🟣 updateCallDetails() started");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final callId = widget.call['id'];

    if (token == null || callId == null) return;

    final now = DateTime.now();
    final formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final Map<String, dynamic> updatedData = {
      'first_name': firstNameController.text,
      'last_name': lastNameController.text,
      'duration': durationController.text,
      'phone': phoneController.text,
      'invoice': invoiceController.text,
      'amount': amountController.text,
      'description': descriptionController.text,
      'note': noteController.text,
      'date': formattedDate,
    };

    if (_customerId != null) {
      updatedData['Customer'] = _customerId;
    }

    if (invoiceController.text.trim().isNotEmpty) {
      updatedData['status'] = 'Productive';
    }

    final url = Uri.parse("$api/api/call/report/$callId/");
 print("🌐 PUT → $url");
    print("📤 Body: $updatedData");
    try {
      final response = await https.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(updatedData),
      );
 print("📥 Response: ${response.statusCode} → ${response.body}");
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(invoiceController.text.trim().isNotEmpty
                ? "✅ Call marked as Productive"
                : "Call updated successfully")));

      Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => const Homepage(initialIndex: 3)),
  (route) => false,
);

      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
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
        title: const Text('Call Details', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(15)),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Edit Call Information",
                  style: TextStyle(
                      color: Color.fromARGB(255, 26, 164, 143),
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _buildEditableRow("First Name", firstNameController)),
                const SizedBox(width: 10),
                Expanded(child: _buildEditableRow("Last Name", lastNameController)),
              ]),
_buildEditableRow("Duration", durationController, readOnly: true),
              _buildEditableRow("Phone Number", phoneController),
              _buildEditableRow("Invoice Number", invoiceController),
              _buildEditableRow("Amount", amountController),
              _buildEditableRow("Description", descriptionController),
              _buildEditableRow("Note", noteController),
              const SizedBox(height: 10),
              const Text("State",
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              _loadingStates
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.teal))
                  : DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF2A2A2A),
                      value: _selectedState,
                      hint: const Text("Select State",
                          style: TextStyle(color: Colors.white70)),
                      items: _states
                          .map<DropdownMenuItem<String>>((s) => DropdownMenuItem(
                              value: s['id'].toString(),
                              child: Text(s['name'],
                                  style: const TextStyle(color: Colors.white))))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedState = v),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Colors.white24)),
                      )),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await saveContact();
                    await updateCallDetails();
                  },
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text("Update Call",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 26, 164, 143),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

Widget _buildEditableRow(
  String label,
  TextEditingController controller, {
  bool readOnly = false,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    ),
  );
}

}
