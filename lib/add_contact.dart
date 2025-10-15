import 'dart:convert';

import 'package:be_call/add_state.dart';
import 'package:be_call/api.dart';
import 'package:be_call/update_contact.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:http/http.dart' as https;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddContactFormPage extends StatefulWidget {
  const AddContactFormPage({super.key});

  @override
  State<AddContactFormPage> createState() => _AddContactFormPageState();
}

class _AddContactFormPageState extends State<AddContactFormPage> {
  final GlobalKey<FormState> _addFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _updateFormKey = GlobalKey<FormState>();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  final Color accent = const Color.fromARGB(255, 26, 164, 143);
  String? _selectedState; // holds chosen state ID

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
   Future<int?> getid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('id');
  }

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  List<dynamic> _customers = [];
  bool _loading = true;

  Future<void> _fetchCustomers() async {
    print("Fetching customers...");

    var token = await getToken();
    var id = await getid();
        print("$api/api/contact/info/staff/$id/");

    setState(() => _loading = true);
print("$api/api/contact/info/staff/$id/");
    try {
      var response = await https.get(
        Uri.parse("$api/api/contact/info/staff/$id/"),
        headers: {"Authorization": "Bearer $token"},
      );
print(response.statusCode);
print("response.bodyyyyyyyy${response.body}");
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

  Future<void> _saveContact() async {
    if (!_addFormKey.currentState!.validate()) return;

    if (!await FlutterContacts.requestPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission denied')),
        );
      }
      return;
    }

    // ✅ store values before clearing
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    final contact =
        Contact()
          ..name.first = firstName
          ..name.last = lastName
          ..phones = [Phone(phone)]
          ..emails = email.isNotEmpty ? [Email(email)] : [];

    await FlutterContacts.insertContact(contact);
    var token = await getToken();
    print("Contact saved locallyyyyyy$token");

    try {
      var response = await https.post(
        Uri.parse("$api/api/contact/info/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "first_name": firstName,
          "last_name": lastName,
          "phone": phone,
          "email": email,
          "state": _selectedState, 
        }),
      );
print(response.statusCode);
print(response.body);
      if (mounted) {
        if (response.statusCode == 201 || response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Contact saved successfully!'),
              backgroundColor: accent,
            ),
          );

          // ✅ clear only after sending
          _addFormKey.currentState?.reset();
          _firstNameCtrl.clear();
          _lastNameCtrl.clear();
          _phoneCtrl.clear();
          _emailCtrl.clear();
          _fetchCustomers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to save. Code: ${response.statusCode}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Error saving contact to server: $e");
    }
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    ),
    filled: true,
    fillColor: Colors.grey[900],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Add New Contact'),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _addFormKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _firstNameCtrl,
                decoration: _inputDecoration('First Name'),
                validator: (v) => v!.isEmpty ? 'Enter first name' : null,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameCtrl,
                decoration: _inputDecoration('Last Name'),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                decoration: _inputDecoration('Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Enter phone number' : null,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: _inputDecoration('Email (optional)'),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 28),

              BlocBuilder<StatesCubit, StatesState>(
                builder: (context, state) {
                  if (state is StatesLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  } else if (state is StatesLoaded) {
                    final states = state.states;

                    return DropdownButtonFormField<String>(
                      value: _selectedState,
                      decoration: _inputDecoration("Select State"),
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      items:
                          states.map<DropdownMenuItem<String>>((s) {
                            return DropdownMenuItem<String>(
                              value: s['id'].toString(),
                              child: Text(
                                s['name'],
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedState = value;
                        });
                      },
                      validator: (v) => v == null ? "Select a state" : null,
                    );
                  } else if (state is StatesError) {
                    return Text(
                      state.error,
                      style: const TextStyle(color: Colors.red),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 28),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                ),
                onPressed: _saveContact,
                child: const Text(
                  'Save Contact',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Saved Contacts:",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
}
