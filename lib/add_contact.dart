import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class AddContactFormPage extends StatefulWidget {
  const AddContactFormPage({super.key});

  @override
  State<AddContactFormPage> createState() => _AddContactFormPageState();
}

class _AddContactFormPageState extends State<AddContactFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl  = TextEditingController();
  final TextEditingController _phoneCtrl     = TextEditingController();
  final TextEditingController _emailCtrl     = TextEditingController();

  final Color accent = const Color.fromARGB(255, 26, 164, 143);

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
            ],
          ),
        ),
      ),
    );
  }
}
