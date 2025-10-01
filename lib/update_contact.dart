import 'dart:convert';

import 'package:be_call/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:http/http.dart' as https;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'StatesCubit.dart'; // adjust path if needed


class updateContactFormPage extends StatefulWidget {
  var id;
   updateContactFormPage({super.key,required this.id});

  @override
  State<updateContactFormPage> createState() => _updateContactFormPageState();
}

class _updateContactFormPageState extends State<updateContactFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl  = TextEditingController();
  final TextEditingController _phoneCtrl     = TextEditingController();
  final TextEditingController _emailCtrl     = TextEditingController();

  final Color accent = const Color.fromARGB(255, 26, 164, 143);

Future <String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
@override
void initState() {
  super.initState();
  _fetchCustomers();
  _fetchidCustomers() ;
}
String? _selectedState; // to store chosen state

  List<dynamic> _customers = [];
bool _loading = true;

Future<void> _fetchCustomers() async {
  var token = await getToken();
  setState(() => _loading = true);

  try {
    var response = await https.get(
      Uri.parse("$api/api/customers/"),
      headers: {"Authorization": "Bearer $token"},
    );

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
Future<void> _fetchidCustomers() async {
  var token = await getToken();
  setState(() => _loading = true);

  try {
    var response = await https.get(
      Uri.parse("$api/api/customers/${widget.id}/"),
      headers: {"Authorization": "Bearer $token"},
    );

    print(response.statusCode);
    print("response.body${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _customers = [data]; // wrap single object in a list
        _loading = false;
      });

      // prefill form controllers
      _firstNameCtrl.text = data['first_name'] ?? "";
      _lastNameCtrl.text  = data['last_name'] ?? "";
      _phoneCtrl.text     = data['phone'] ?? "";
      _emailCtrl.text     = data['email'] ?? "";
      _selectedState = data['state']?.toString();

    } else {
      setState(() => _loading = false);
      print("Failed to load customer: ${response.statusCode}");
    }
  } catch (e) {
    setState(() => _loading = false);
    print("Error: $e");
  }
}

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    if (!await FlutterContacts.requestPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacts permission denied')),
      );
      return;
    }

    final contact = Contact()
      ..name.first = _firstNameCtrl.text.trim()
      ..name.last  = _lastNameCtrl.text.trim()
      ..phones     = [Phone(_phoneCtrl.text.trim())]
      ..emails     = _emailCtrl.text.trim().isNotEmpty
          ? [Email(_emailCtrl.text.trim())]
          : [];

    await FlutterContacts.insertContact(contact);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Contact saved successfully!'),
        backgroundColor: accent,
      ),
    );

    _formKey.currentState!.reset();
    _firstNameCtrl.clear();
    _lastNameCtrl.clear();
    _phoneCtrl.clear();
    _emailCtrl.clear();
     _fetchCustomers(); // refresh list

var token = await getToken();
    try{
      var response= await https.post(Uri.parse("$api/api/customers/"),
      headers: {
        "Authorization":'Bearer $token',
      },
      body:{
        "first_name":_firstNameCtrl.text,
        "last_name":_lastNameCtrl.text,
        "phone":_phoneCtrl.text,
        "email":_emailCtrl.text,
        'state':"1"
      }
      );
      print(response.statusCode);
      print(response.body);
      if(response.statusCode==201 || response.statusCode==200){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Contact saved successfully!'), backgroundColor: accent),
        );
        _formKey.currentState?.reset();
        _firstNameCtrl.clear();
        _lastNameCtrl.clear();
        _phoneCtrl.clear();
        _emailCtrl.clear();
      }
      else{
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save. Code: ${response.statusCode}"), backgroundColor: Colors.red),
        );
      }

    }
    catch(e){
      print(e);
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
          key: _formKey,
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
        items: states.map<DropdownMenuItem<String>>((s) {
          return DropdownMenuItem<String>(
            value: s['id'].toString(),
            child: Text(
              s['name'],
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _selectedState = value);
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
const SizedBox(height: 16),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
),
const SizedBox(height: 8),

_loading
    ? const Center(child: CircularProgressIndicator())
    : _customers.isEmpty
        ? const Text("No contacts found", style: TextStyle(color: Colors.white))
        : Column(
            children: _customers.map((c) {
              return GestureDetector(
                onTap: () {
                  

                },
                child: Card(
                  color: Colors.grey[900],
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.white),
                    title: Text("${c['first_name']} ${c['last_name']}",
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Phone: ${c['phone']}", style: const TextStyle(color: Colors.white70)),
                        if (c['email'] != null && c['email'].toString().isNotEmpty)
                          Text("Email: ${c['email']}", style: const TextStyle(color: Colors.white70)),
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
