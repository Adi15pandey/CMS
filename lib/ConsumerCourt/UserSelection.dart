import 'package:cms/GlobalServiceurl.dart';
import 'package:cms/UserNotification.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class UserSelection extends StatefulWidget {
  final String Sendcnr;
  final File? selectedFile;
  final String sendScreentype;

  UserSelection({required this.Sendcnr, required this.selectedFile, required this.sendScreentype,  });

  @override
  _UserSelectionState createState() => _UserSelectionState();
}

class _UserSelectionState extends State<UserSelection> {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _users = [];
  int? _selectedUserIndex;
  String?token;
  @override
  void initState() {
    super.initState();
    _initializeData();

  }
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      fetchUsers(); // Fetch cases if the token is valid
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

  Future<void> fetchUsers() async {
    final url = '${GlobalService.baseUrl}/api/external-user/get-external-user';

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'token': '$token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _users = data['data'];
            _selectedUserIndex = null;  // Reset selection
          });
        } else {
          setState(() {
            _error = "No users found.";
          });
        }
      } else {
        setState(() {
          _error = "Failed to fetch users. Please try again later.";
        });
      }
    } catch (e) {
      setState(() {
        _error = "An error occurred: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('',style: TextStyle(color: Colors.white), ),
        iconTheme: const IconThemeData(
            color: Colors.white),
        backgroundColor: Color.fromRGBO(0, 74, 173, 1) ,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isLoading) const CircularProgressIndicator(),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Colors.red),
              ),
            if (_users.isNotEmpty) ...[
              Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.all(16),
                  color: Colors.white,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Color.fromRGBO(189, 217, 255, 1), // Border color
                        width: 2, // Border width
                      ),
                      borderRadius: BorderRadius.circular(12), // Rounded corners
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Select Advocate:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                // color: Color.fromRGBO(r, g, b, opacity)
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            height: 200,
                            child: ListView.builder(
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                return RadioListTile<int>(
                                  value: index,
                                  groupValue: _selectedUserIndex,
                                  title: Text(_users[index]['name'] ?? 'Unknown'),
                                  onChanged: (int? value) {
                                    setState(() {
                                      _selectedUserIndex = value;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(height: 16),
            ElevatedButton(

              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white
              ),
              onPressed: () {
                if(widget.sendScreentype == "uploadfile"){
                  final selectedUser = _users[_selectedUserIndex!];
                  final userId = selectedUser['userId']; // Pass user ID
                  final userName = selectedUser['name']; // Pass user Name

                  _uploadDocument(userId,userName ,context);
                }
                else if (_selectedUserIndex != null) {
                  final selectedUser = _users[_selectedUserIndex!];
                  final userId = selectedUser['userId']; // Pass user ID
                  final userName = selectedUser['name']; // Pass user Name

                  // Navigate to the new screen and pass user data
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UsersNotification(
                        userId: userId.toString(),
                        userName: userName,
                        sendcnr: widget.Sendcnr.toString(),
                      ),
                    ),
                  );
                } else {
                  // If no user is selected, show a message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a user.')),
                  );
                }
              },
              child: Text('Add',),
            ),
          ],
        ),
      ),
    );

  }


  Future<void> _uploadDocument(String userId, String userName, BuildContext context) async {
    var headers = {
      'token': '$token',
      // 'token':
      // 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzYwNjg4NiwiZXhwIjoxNzM3NjkzMjg2fQ.Xr4rBiMZBW2zPZKWgEuQIf7FZEUR1FT_51S3lHqSYAI',
      //  // Replace with your actual token
    };

    // Ensure the selected file is valid and exists
    if (widget.selectedFile == null || !await widget.selectedFile!.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File does not exist. Please select a valid file.')),
      );
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${GlobalService.baseUrl}/api/cnr/addnew-bulkcnr'),
    );

    // Add form fields
    request.fields.addAll({
      'externalUserId': userId,
      'externalUserName': userName,
    });

    // Add file to the request
    try {
      request.files.add(await http.MultipartFile.fromPath('excelFile', widget.selectedFile!.path));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding file: $e')),
      );
      return;
    }

    // Add headers
    request.headers.addAll(headers);

    // Send the request and capture the response
    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        // Parse the response body
        String responseBody = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File uploaded successfully!')),
        );
        print("Success: $responseBody");
      } else {
        // Show full response if failed
        String responseBody = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file.'

          ),
            backgroundColor: Colors.red, // Set the background color to red

          ),
        );
        print("Failure: $responseBody"); // Log the full error for debugging
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
      print("Error: $e");
    }
  }
}


