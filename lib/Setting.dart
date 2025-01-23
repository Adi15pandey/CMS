import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Setting extends StatefulWidget {
  const Setting({Key? key}) : super(key: key);

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  bool isLoading = true;
  Map<String, bool> notificationSettings = {
    "Email notifications": false,
    "SMS notifications": false,
    "WhatsApp notifications": false,
    "Day Before notifications": false,
    "2 Day Before notifications": false,
    "3 Day Before notifications": false,
    "4 Day Before notifications": false,
  };


  final String apiUrl = '${GlobalService.baseUrl}/api/auth/get-user-data';
  String?token;
  // final String token =
  //     "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzUyMDc3MiwiZXhwIjoxNzM3NjA3MTcyfQ.8YpCygR2uAjCn-yWPEwXG280Cf2Of3KOA_2xBtuIDCw";

  @override
  void initState() {
    super.initState();
    _initializeData();
    fetchSettings();
  }

  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      fetchSettings(); // Fetch cases if the token is valid
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("No token found. Please log in."),
      ));
    }
  }

  // Fetch token from SharedPreferences
  Future<void> _fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Ensure we fetch the latest data
    await prefs.reload();
    final savedToken = prefs.getString('auth_token');
    if (savedToken != null && savedToken.isNotEmpty) {
      setState(() {
        token = savedToken;
      });
      print('Token fetched successfully: $token');
    } else {
      print('Token not found');
    }
  }

  Future<void> fetchSettings() async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'token': '$token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            notificationSettings["Email notifications"] = data['data']['emailSms'];
            notificationSettings["SMS notifications"] = data['data']['mobileSms'];
            notificationSettings["WhatsApp notifications"] = data['data']['whatsAppSms'];
            notificationSettings["Day Before notifications"] =
            data['data']['oneDayBeforenotification'];
            notificationSettings["2 Day Before notifications"] =
            data['data']['twoDayBeforenotification'];
            notificationSettings["3 Day Before notifications"] =
            data['data']['threeDayBeforenotification'];
            notificationSettings["4 Day Before notifications"] =
            data['data']['fourDayBeforenotification'];
            isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to fetch settings");
      }
    } catch (e) {
      debugPrint("Error fetching settings: $e");
    }
  }

  void toggleNotification(String key, bool value) {
    setState(() {
      notificationSettings[key] = value;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: notificationSettings.keys.map((key) {
                  return SwitchListTile(
                    title: Text(key),
                    value: notificationSettings[key]!,
                    onChanged: (value) {
                      toggleNotification(key, value);
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('Default same day at 6 AM'),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Add save functionality if needed
                  debugPrint('Settings saved');
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
