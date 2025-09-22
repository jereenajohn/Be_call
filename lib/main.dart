import 'package:be_call/homepage.dart';
import 'package:flutter/material.dart';

void main() async {
  // Important: ensures that plugin channels (like shared_preferences) are ready
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const Homepage(),
        '/dialer': (context) => const Homepage(),
      },
    );
  }
}
