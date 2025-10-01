import 'package:be_call/Contact_list.dart';
import 'package:be_call/add_contact.dart';
import 'package:be_call/add_contry.dart';
import 'package:be_call/add_state.dart';
import 'package:be_call/add_state_cubit.dart' hide AddStateCubit;
import 'package:be_call/call_report.dart';
import 'package:be_call/countries_cubit.dart';
import 'package:be_call/dialerpage.dart';
import 'package:be_call/homepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  
    int _selectedIndex = 1; // Contacts is default

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 2) { // Keypad tapped
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DialerPage()),
      );
    }
     else if (index == 0) { 
        Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const Homepage()),
      );
    }
     else if (index == 1) { 
        Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const Homepage()),
      );
    }
    else if (index == 3) { 
        Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CallReport()),
      );
    }
    else if (index == 4) { 
        Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsPage()),
      );// Reports tapped
      // Navigate to Reports page if implemented
    }
    else if (index == 4) { // Settings tapped
      // Navigate to Settings page if implemented
    }
    // you can add more conditions for other tabs if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                    const Text(
                      'My profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
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
                      label: 'Contacts',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ContactsListPage()),
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
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AddStateCubit()),
    BlocProvider(create: (_) => CountriesCubit()),
    BlocProvider(create: (_) => StatesCubit()),
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
                      label: 'Contries',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddContryFormPage()),
                        );
                       
                      },
                    ),
                                        const Divider(color: Colors.black54, height: 1),

                    _settingsTile(
                      icon: Icons.star,
                      label: 'Stared',
                      onTap: () {
                       
                      },
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
  Widget _settingsTile(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 26, 164, 143)),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
      onTap: onTap,
    );
  }
}
