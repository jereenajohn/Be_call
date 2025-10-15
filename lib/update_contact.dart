import 'dart:convert';

import 'package:be_call/add_contact.dart';
import 'package:be_call/add_state.dart';
import 'package:be_call/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 👈 needed for BlocBuilder
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;


class UpdateContact extends StatefulWidget {
  final int id;
  const UpdateContact({super.key, required this.id});

  @override
  State<UpdateContact> createState() => _UpdateContactState();
}

class _UpdateContactState extends State<UpdateContact> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  int? _selectedState; // 👈 should be int, not String
  List<dynamic> _customers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    print("Contact ID: ${widget.id}");
    _fetchCustomers();
    _fetchCustomer(); // 👈 fetch specific customer data
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
    var id =
    setState(() => _loading = true);
    var userid=await getid();

    try {
      var response = await https.get(
        Uri.parse("$api/api/contact/info/staff/$userid/"),
        headers: {"Authorization": "Bearer $token"},
      );
      print(response.statusCode);
      print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _customers = List<dynamic>.from(jsonDecode(response.body));
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        print("Failed to load customers: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _loading = false);
      print("Error: $e");
    }
  }

  Future<void> _fetchCustomer() async {
    var token = await getToken();

    try {
      var response = await https.get(
        Uri.parse("$api/api/contact/info/${widget.id}/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("$api/api/contact/info/${widget.id}/");
print(response.statusCode);
print(response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> customer = jsonDecode(response.body);
        print("Fetched customer data: $customer");

        setState(() {
          _firstNameCtrl.text = customer["first_name"] ?? "";
          _lastNameCtrl.text = customer["last_name"] ?? "";
          _phoneCtrl.text = customer["phone"] ?? "";
          _emailCtrl.text = customer["email"] ?? "";
          _selectedState = customer["state"]; // 👈 now int, works with dropdown
        });
      } else {
        print("Failed to load customer: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }


 Future<void> _updateCustomer() async {
  var token = await getToken();

  try {
    final url = Uri.parse("$api/api/contact/info/${widget.id}/");

    final body = jsonEncode({
      "first_name": _firstNameCtrl.text.trim(),
      "last_name": _lastNameCtrl.text.trim(),
      "phone": _phoneCtrl.text.trim(),
      "email": _emailCtrl.text.trim(),
      "state": _selectedState, // send state id
    });

    final response = await https.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: body,
    );

    if (!mounted) return; // ✅ ensure widget still in tree

    if (response.statusCode == 200) {
      print("✅ Customer updated: ${response.body}");
      Navigator.push(context, MaterialPageRoute(builder: ((context) => AddContactFormPage(phoneNumber: '',))));
    } else {
      print("❌ Failed to update: ${response.body}");
      Navigator.pop(context, false); // return failure
    }
  } catch (e) {
    print("⚠️ Error: $e");
    if (mounted) {
      Navigator.pop(context, false);
    }
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("Update Contact", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField("First Name", _firstNameCtrl),
              const SizedBox(height: 12),
              _buildTextField("Last Name", _lastNameCtrl),
              const SizedBox(height: 12),
              _buildTextField("Phone Number", _phoneCtrl, keyboard: TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField("Email (optional)", _emailCtrl,
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildDropdown(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.tealAccent[700],
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  onPressed: _updateCustomer, // 👈 call update
  child: const Text(
    "Update Contact",
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  ),
),

              ),
              const SizedBox(height: 20),
              const Text(
                "Saved Contacts:",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
             const SizedBox(height: 8),

              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _customers.isEmpty
                  ? const Text(
                    "No contacts found",
                    style: TextStyle(color: Colors.white),
                  )
                  : Column(
                    children:
                        _customers.map((c) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => BlocProvider(
                                        create:
                                            (_) => StatesCubit()..fetchStates(),
                                        child: UpdateContact(
                                          id: c['id'],
                                        ),
                                      ),
                                ),
                              );
                            },
                            child: Card(
                              color: Colors.grey[900],
                              child: ListTile(
                                leading: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                                title: Text(
                                  "${c['first_name']} ${c['last_name']}",
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Phone: ${c['phone']}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    if (c['email'] != null &&
                                        c['email'].toString().isNotEmpty)
                                      Text(
                                        "Email: ${c['email']}",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.black,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.tealAccent),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return BlocBuilder<StatesCubit, StatesState>(
      builder: (context, state) {
        if (state is StatesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is StatesLoaded) {
          final states = state.states;

          return DropdownButtonFormField<int>(
            dropdownColor: Colors.black,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.tealAccent),
              ),
            ),
            hint: const Text("Select State", style: TextStyle(color: Colors.grey)),
            value: _selectedState, // 👈 works now (int)
            onChanged: (value) {
              setState(() => _selectedState = value);
            },
            items: states
                .map<DropdownMenuItem<int>>((s) {
              return DropdownMenuItem<int>(
                value: s["id"],
                child: Text(
                  s["name"],
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          );
        } else if (state is StatesError) {
          return Text(state.error, style: const TextStyle(color: Colors.red));
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildSavedContactCard(
      {required String name, required String phone, String? email}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.person, color: Colors.white),
            const SizedBox(width: 8),
            Text(name,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          Text("Phone: $phone", style: const TextStyle(color: Colors.white70)),
          if (email != null)
            Text("Email: $email", style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
