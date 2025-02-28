import 'dart:convert';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddAdvocateDialog extends StatefulWidget {
  @override
  State<AddAdvocateDialog> createState() => _AddAdvocateDialogState();
}

class _AddAdvocateDialogState extends State<AddAdvocateDialog> {
  final TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
    addExternalUser("ad");
  }

  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      addExternalUser("ad"); // Fetch cases if the token is valid
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("No token found. Please log in."),
      ));
    }
  }

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


  String?token;
  bool _isLoading = false;

  Future<void> addExternalUser(String name) async {
    var headers = {
      'token': '$token', 'Content-Type': 'application/json'
    };

    var request = http.Request('POST', Uri.parse(
        '${GlobalService.baseUrl}/api/external-user/add-external-user'));
    request.body = json.encode({
      "name": name,
    });

    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        print("User added successfully");
        // Optionally handle the response
        print(await response.stream.bytesToString());
      } else {
        print("Failed to add user: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Add New Advocate',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color.fromRGBO(4, 163, 175, 1),
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Advocate\'s Name',
                hintText: 'Enter the advocate\'s name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color.fromRGBO(4, 163, 175, 1),),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color.fromRGBO(4, 163, 175, 1),),
                ),
                prefixIcon: Icon(
                  Icons.person,
                  color: Color.fromRGBO(4, 163, 175, 1),
                ),
              ),
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog without saving
          },
          child: Text(
            'Cancel',
            style: TextStyle(

              color: Color.fromRGBO(253, 101, 0, 1),

              fontSize: 16,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            String name = nameController.text.trim();
            if (name.isNotEmpty) {
              addExternalUser(name); // Add the user
              Navigator.of(context).pop(); // Close the dialog after saving
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Name is required')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Color.fromRGBO(4, 163, 175, 1), // Text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            'Save',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}

  class Ticketscreen extends StatelessWidget {
  const Ticketscreen({super.key});

  void showAddAdvocateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddAdvocateDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showAddAdvocateDialog(context);
          },
          child: const Text('Add New Advocate'),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: Ticketscreen(),
  ));
}
