import 'dart:convert';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddDirectory extends StatefulWidget {
  const AddDirectory({super.key});

  @override
  State<AddDirectory> createState() => _AddDirectoryState();
}

class _AddDirectoryState extends State<AddDirectory> {
  List<dynamic> users = [];
  String?token;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    fetchUsers();
    deleteUser("");
  }

  Future<void> _initializeData() async {
    await _fetchToken();
    if (token != null && token!.isNotEmpty) {
      fetchUsers(); // Fetch cases if the token is valid
    } else {
      setState(() {
        _isLoading = false;
      });
      // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      //   content: Text("No token found. Please log in."),
      // ));
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


  // Function to fetch external users from the API
  Future<void> fetchUsers() async {
    var headers = {
      'token': '$token',
      // 'token': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzQ0OTc1OCwiZXhwIjoxNzM3NTM2MTU4fQ.B6Xs1cBEttzE87XmTke-rn4RHALZXviDzqhlgctxPP0'
    };
    var request = http.Request('GET',
        Uri.parse(
            '${GlobalService.baseUrl}/api/external-user/get-external-user'));
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        final responseData = json.decode(await response.stream.bytesToString());
        setState(() {
          users = responseData['data']; // Store the user data
        });
      } else {
        print('Failed to load users: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  Future<void> deleteUser(String userId) async {
    var headers = {
      'token': '$token',
    };

    var request = http.Request('DELETE', Uri.parse('${GlobalService
        .baseUrl}/api/external-user/delete-external-user/$userId'));
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        print('User deleted successfully');
        fetchUsers();
      } else {
        print('Failed to delete user: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Directory'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: users.isEmpty
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: users.length,
        itemBuilder: (context, index) {
          var user = users[index];
          return Card(
            elevation: 5,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    radius: 30,
                    child: Text(
                      user['name'][0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // User Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No. of Assigned Cases: ${user['noOfAssigncases']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete Button
                  if (user['noOfAssigncases'] == 0)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete User',
                      onPressed: () {
                        deleteUser(user['_id']);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


