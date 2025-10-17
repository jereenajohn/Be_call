import 'dart:convert';

import 'package:be_call/admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'otp_page.dart';
import 'api.dart';
import 'package:be_call/homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }
  
Future login(String email, String password, BuildContext context) async {
  try {
    print("Attempting login with email: $email");
    var response = await http.post(
      Uri.parse('$api/api/login/'),
      body: {"username": email, "password": password},
    );
print(response.statusCode);
    print("ressssssssssssss${response.body}");
    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      var status = responseData['status'];

      if (status == 'success') {
        var token = responseData['token'];
        var active = responseData['active'];
        var name = responseData['name'];
        var warehouse = responseData['warehouse_id'] ?? 0;

        // Decode JWT token to get user id
        List<String> parts = token.split('.');
        if (parts.length == 3) {
          String payload = parts[1];
          String normalized = base64.normalize(payload);
          Map<String, dynamic> payloadMap =
              jsonDecode(utf8.decode(base64.decode(normalized)));
          print("payloadMap: $payloadMap");
          var userId = payloadMap['id'];
          var userRole = payloadMap['active']; // e.g. ADMIN, STAFF, etc.

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setString('username', name);
          await prefs.setInt('warehouse_id', warehouse);
          await prefs.setInt('id', userId);
          await prefs.setString('role', userRole);

          // ✅ Navigate based on role
          if (userRole == 'ADMIN') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
            );
          }
           else if (userRole == 'CEO') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
            );
          }
            else if (userRole == 'COO') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
            );
          }
           else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Homepage()),
            );
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Successfully logged in.'),
          ),
        );
      } else {
        String errorMessage = responseData['message'] ?? 'Login failed....';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(errorMessage)),
        );
      }
    } else {
      String errorMessage = 'An error occurred. Please try again.';
      try {
        var responseData = jsonDecode(response.body);
        if (responseData['message'] != null) {
          errorMessage = responseData['message'];
        }
      } catch (_) {

      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(errorMessage)),
      );
    }
  } catch (e) {
    print("Login error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text('An error occurred. Please try again.'),
      ),
    );
  }
}

  Future<void> _postPhoneNumber() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your mobile number' ,style: TextStyle(color: Colors.white),), backgroundColor: Color.fromARGB(255, 26, 164, 143),
      ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$api/api/otp/request/'),
        body: {"phone": phone},
      );

      if (response.statusCode == 500) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpPage(phoneNumber: phone)),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color.fromARGB(255, 26, 164, 143),
            content: Text('OTP sent successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('OTP send failed'),
          ),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color.fromARGB(255, 26, 164, 143),
          content: Text('An error occurred. Please try again later.'),
        ),
      );
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Main content scrollable to avoid overflow
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 130),
                    Image.asset('lib/assets/logo.png', height: 120),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.only(left: 9),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'login here',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: phoneController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter your username',
                        hintStyle: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                     TextField(
                      controller: passwordController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Call login function
                          login(phoneController.text, passwordController.text, context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 26, 164, 143),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom row fixed at bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.white70),
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: navigate to sign-in page
                    },
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        color: Color.fromARGB(255, 26, 164, 143),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

}
