import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveToken(String authToken) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', authToken);
  print('Token saved successfully: $authToken');
}

Future<void> deleteSubcase({
  required BuildContext context,
  required String id,
  required String cnrNumber,
}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  // Fetch the token dynamically
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  if (token == null || token.isEmpty) {
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Authentication token not found.')),
    );
    return;
  }

  scaffoldMessenger.showSnackBar(
    const SnackBar(content: Text('Deleting case...')),
  );

  try {
    final response = await http.delete(
      Uri.parse(
          'http://192.168.0.111:4001/api/cnr/delete-sub-case/$cnrNumber/$id'),
      headers: {
        'token': '$token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Case deleted successfully!')),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to delete case: ${response.body}')),
      );
    }
  } catch (e) {
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('An error occurred: $e')),
    );
  }
}

class ExampleWidget extends StatefulWidget {
  @override
  _ExampleWidgetState createState() => _ExampleWidgetState();
}

class _ExampleWidgetState extends State<ExampleWidget> {
  String? token;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchToken();
    if (token != null && token!.isNotEmpty) {
      print('Token fetched successfully in initState: $token');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No token found. Please log in.')),
      );
    }
  }

  Future<void> _fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Ensure the latest data is fetched
    final savedToken = prefs.getString('auth_token');
    setState(() {
      token = savedToken;
    });

    if (savedToken != null && savedToken.isNotEmpty) {
      print('Token fetched successfully: $savedToken');
    } else {
      print('Token not found');
    }
  }

  Future<void> _simulateLogin() async {
    // Simulate a login and save a token
    const mockToken = 'newly_generated_token';
    await saveToken(mockToken);
    await _fetchToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Token Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => deleteSubcase(
                context: context,
                id: 'sampleId', // Replace with actual ID
                cnrNumber: 'sampleCnrNumber', // Replace with actual CNR Number
              ),
              child: const Text('Delete Subcase'),
            ),
            ElevatedButton(
              onPressed: _simulateLogin,
              child: const Text('Simulate Login and Save Token'),
            ),
          ],
        ),
      ),
    );
  }
}
