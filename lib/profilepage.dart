import 'dart:convert';

import 'package:be_call/Contact_list.dart';
import 'package:be_call/add_contact.dart';
import 'package:be_call/add_contry.dart';
import 'package:be_call/add_state.dart';
import 'package:be_call/add_state_cubit.dart';
import 'package:be_call/api.dart';
import 'package:be_call/call_report.dart';
import 'package:be_call/callreport_date_wise.dart';
import 'package:be_call/callreport_statewise.dart';
import 'package:be_call/countries_cubit.dart';
import 'package:be_call/dialerpage.dart';
import 'package:be_call/homepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<dynamic> _customers = [];

  int _selectedIndex = 1; // Contacts is default

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 2) {
      // Keypad tapped
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DialerPage()),
      );
    } else if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const Homepage()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const Homepage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CallReport()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsPage()),
      ); // Reports tapped
      // Navigate to Reports page if implemented
    } else if (index == 4) {
      // Settings tapped
      // Navigate to Settings page if implemented
    }
    // you can add more conditions for other tabs if needed
  }

  @override
  initState() {
    super.initState();
    _fetchUser();
  }

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idValue = prefs.get('id');
    if (idValue is int) return idValue;
    if (idValue is String) {
      return int.tryParse(idValue);
    }
    return null;
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _fetchUser() async {
    var token = await getToken();
    var userId = await getUserId();
    print("User ID from prefs: $userId");
    print(token);
    if (userId == null) {
      print("No user id found in SharedPreferences");
      return;
    }

    try {
      var response = await https.get(
        Uri.parse("$api/api/users/$userId/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          _customers = [jsonDecode(response.body)];
        });
      } else {
        print("Failed to load user: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  // ...existing code...
  Future<void> _updateUserName(int userId, String newName) async {
    var token = await getToken();
    try {
      var response = await https.put(
        Uri.parse("$api/api/users/$userId/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"name": newName}),
      );

      print("$api/api/users/$userId/");
      print("Request Body: ${jsonEncode({"name": newName})}");
      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");
      if (response.statusCode == 200) {
        print("Name updated successfully");
      } else {
        print("Failed to update name: ${response.statusCode}");
      }
    } catch (e) {
      print("Error updating name: $e");
    }
  }
  // ...existing code...

  String? _editedName;

  void _showEditNameDialog() {
    TextEditingController controller = TextEditingController(
      text: _customers.isNotEmpty ? _customers[0]['name'] ?? '' : '',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('Edit Name', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter new name',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 26, 164, 143),
              ),
              onPressed: () async {
                if (_customers.isNotEmpty) {
                  setState(() {
                    _customers[0]['name'] = controller.text;
                    _editedName = controller.text;
                  });
                  int? userId = await getUserId();
                  if (userId != null) {
                    await _updateUserName(userId, controller.text);
                  }
                }
                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // Profile icon and text
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color.fromARGB(255, 26, 164, 143),
                        child: const Icon(
                          Icons.person,
                          color: Colors.black,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _customers.isNotEmpty && _customers[0]['name'] != null
                                ? _customers[0]['name']
                                : '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: _showEditNameDialog,
                            tooltip: 'Edit Name',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Settings List
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                        _settingsTile(
                        icon: Icons.person_2,
                        label: 'datewise Call Report',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CallreportDateWise(),
                            ),
                          );
                        },
                      ),
                      const Divider(color: Colors.black54, height: 1),
                       _settingsTile(
                        icon: Icons.person_2,
                        label: 'state wise Call Report',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CallreportStatewise(),
                            ),
                          );
                        },
                      ),
                      const Divider(color: Colors.black54, height: 1),

                      _settingsTile(
                        icon: Icons.person_2,
                        label: 'Contacts',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ContactsListPage(),
                            ),
                          );
                        },
                      ),
                      const Divider(color: Colors.black54, height: 1),
                      _settingsTile(
                        icon: Icons.person_2,
                        label: 'States',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => MultiBlocProvider(
                                    providers: [
                                      BlocProvider(
                                        create: (_) => AddStateCubit(),
                                      ),
                                      BlocProvider(
                                        create: (_) => CountriesCubit(),
                                      ),
                                      BlocProvider(
                                        create: (_) => StatesCubit(),
                                      ),
                                    ],
                                    child: const AddstateFormPage(),
                                  ),
                            ),
                          );
                        },
                      ),

                      const Divider(color: Colors.black54, height: 1),

                      _settingsTile(
                        icon: Icons.star,
                        label: 'Countries',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddContryFormPage(),
                            ),
                          );
                        },
                      ),
                      const Divider(color: Colors.black54, height: 1),

                      _settingsTile(
                        icon: Icons.star,
                        label: 'Stared',
                        onTap: () {},
                      ),
                      const Divider(color: Colors.black54, height: 1),
                      _settingsTile(
                        icon: Icons.favorite,
                        label: 'Favourite',
                        onTap: () {},
                      ),
                      const Divider(color: Colors.black54, height: 1),
                      _settingsTile(
                        icon: Icons.folder,
                        label: 'Labels',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // Bottom navigation bar
      // bottomNavigationBar: BottomNavigationBar(
      //   backgroundColor: Colors.black,
      //   type: BottomNavigationBarType.fixed,
      //   selectedItemColor: const Color.fromARGB(255, 26, 164, 143),
      //   unselectedItemColor: Colors.grey,
      //   currentIndex: _selectedIndex, // highlight Settings
      //          onTap: _onItemTapped,

      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Calls'),
      //     BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'Contacts'),
      //     BottomNavigationBarItem(icon: Icon(Icons.dialpad), label: 'Keypad'),
      //     BottomNavigationBarItem(icon: Icon(Icons.insert_chart), label: 'Reports'),
      //     BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      //   ],
      // ),
    );
  }

  // Reusable list tile with teal icon
  Widget _settingsTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 26, 164, 143)),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}
