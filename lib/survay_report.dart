import 'dart:convert';

import 'package:be_call/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SurvayReport extends StatefulWidget {
  const SurvayReport({super.key});

  @override
  State<SurvayReport> createState() => _SurvayReportState();
}

class _SurvayReportState extends State<SurvayReport> {

    @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    
    await fetchsurvay();
  }

Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchsurvay() async {
    try {
      final token = await getToken();
      if (token == null) return;

   

      final response = await http.get(
        Uri.parse('$api/api/answers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed['data'] as List;

        
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching questions: $e");
    }
  }

  Widget build(BuildContext context) {
    return const Placeholder();
  }
}