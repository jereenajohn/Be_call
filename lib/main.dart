import 'package:be_call/add_questions.dart';
import 'package:be_call/homepage.dart';
import 'package:be_call/login_page.dart';
import 'package:be_call/admin_dashboard.dart'; // 👈 Import your admin dashboard page
import 'package:be_call/survay_report.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<String?> _getStartPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? role = prefs.getString('role');

    if (token != null && token.isNotEmpty) {
      // Check role and decide which dashboard to show
      if (role != null &&
          (role.toLowerCase() == 'admin' ||
              role.toLowerCase() == 'ceo' ||
              role.toLowerCase() == 'coo')) {
        return 'admin';
      } else {
        return 'home';
      }
    } else {
      return 'login';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getStartPage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Splash/loading screen
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final startPage = snapshot.data;

        Widget initialScreen;
        if (startPage == 'admin') {
          initialScreen = const AdminDashboard();
        } else if (startPage == 'home') {
          initialScreen = const Homepage();
        } else {
          initialScreen = const LoginPage();
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: initialScreen,
          routes: {
            '/login': (context) => const LoginPage(),
            '/dialer': (context) => const Homepage(),
            '/admin': (context) => const AdminDashboard(),
            '/add_questions': (context) => const AddQuestions(),
            '/survay_report': (context) => const SurveyReportPage(),
          },
        );
      },
    );
  }
}
