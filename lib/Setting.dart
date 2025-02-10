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
  final String saveUrl = '${GlobalService.baseUrl}/api/auth/update-user-data';
  String? token;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchToken();
    if (token != null && token!.isNotEmpty) {
      fetchSettings();
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("No token found. Please log in."),
      ));
    }
  }

  Future<void> _fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final savedToken = prefs.getString('auth_token');
    if (savedToken != null && savedToken.isNotEmpty) {
      setState(() {
        token = savedToken;
      });
    }
  }

  Future<void> fetchSettings() async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'token': '$token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            notificationSettings["Email notifications"] =
            data['data']['emailSms'];
            notificationSettings["SMS notifications"] =
            data['data']['mobileSms'];
            notificationSettings["WhatsApp notifications"] =
            data['data']['whatsAppSms'];
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
      }
    } catch (e) {
      debugPrint("Error fetching settings: $e");
    }
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    setState(() {
      isLoading = true;
    });

    var headers = {
      'token': '$token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.put(
        Uri.parse(saveUrl),
        headers: headers,
        body: json.encode(settings), // Dynamic settings payload
      );

      final responseBody = jsonDecode(response.body);
      debugPrint("Response Code: ${response.statusCode}");
      debugPrint("Response Body: $responseBody");

      if (response.statusCode == 200 && responseBody['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Settings updated successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              "Failed to update settings: ${responseBody['message'] ??
                  'Unknown error'}")),
        );
      }
    } catch (e) {
      debugPrint("Error saving settings: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error. Please try again.")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromRGBO(0, 74, 173, 1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                children: notificationSettings.keys.map((key) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                            color: Color.fromRGBO(189, 217, 255, 1)),
                      ),
                      child: SwitchListTile(
                        title: ListTile(
                          leading: Icon(
                            Icons.notifications, // Icon for notifications
                            color: Color.fromRGBO(0, 74, 173, 1),
                          ),
                          title: Text(
                            key,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color.fromRGBO(0, 74, 173, 1),
                            ),
                          ),
                        ),
                        value: notificationSettings[key]!,
                        onChanged: (value) {
                          setState(() {
                            notificationSettings[key] = value;
                          });
                        },
                        activeColor: Color.fromRGBO(59, 199, 89, 1),
                        inactiveTrackColor: Colors.grey,
                        inactiveThumbColor: Colors.white,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Map<String, dynamic> userSettings = {
                    "fourDayBeforenotification": "true",
                    "threeDayBeforenotification": "true",
                    "twoDayBeforenotification": "true",
                    "oneDayBeforenotification": "true",
                    "whatsAppSms": "true",
                    "emailSms": "true",
                    "mobileSms": "true"
                  };

                  saveSettings(userSettings);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  elevation: 5,
                ),
                icon: Icon(Icons.save),
                label: const Text(
                  'Save',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),    );
  }
}