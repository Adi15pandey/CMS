
import 'package:cms/GlobalServiceurl.dart';
import 'package:cms/UserNotification.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class CnrSearchScreen extends StatefulWidget {
  @override
  _CnrSearchScreenState createState() => _CnrSearchScreenState();
}

class _CnrSearchScreenState extends State<CnrSearchScreen> {
  final TextEditingController _cnrController = TextEditingController();
  Map<String, dynamic>? _cnrData;
  bool _isLoading = false;
  String? _error;
  String?token;
  @override
  void initState() {
    super.initState();
    _initializeData();
    fetchCnrData("DEFAULT_CNR_NUMBER");
  }
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      fetchCnrData("DEFAULT_CNR_NUMBER"); // Fetch cases if the token is valid
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

  Future<void> fetchCnrData(String cnrNumber) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final url = '${GlobalService.baseUrl}/api/cnr/get-singlecnr/$cnrNumber';
    // final token = AppConstants.token; // Replace with the actual token or fetch it from local storage.

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'token': '$token',
          // 'token':
          // 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzYwNjg4NiwiZXhwIjoxNzM3NjkzMjg2fQ.Xr4rBiMZBW2zPZKWgEuQIf7FZEUR1FT_51S3lHqSYAI',
          // 'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _cnrData = data['data'];
          });
        } else {
          setState(() {
            _error = "No data found for CNR number $cnrNumber.";
          });
        }
      } else {
        setState(() {
          _error = "Failed to fetch data. Please try again later.";
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

  String? extractFirstHearingDate(List<dynamic> caseStatus) {
    for (var item in caseStatus) {
      if (item is List && item.length == 2 && item[0] == "First Hearing Date") {
        return item[1];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search case by CNR number',
          style: TextStyle(color: Colors.blue),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search CNR Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cnrController,
                      decoration: InputDecoration(
                        labelText: 'Enter CNR Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 16), // Space between TextField and Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, // Set the background color to black
                    ),
                    onPressed: () {
                      if (_cnrController.text.isNotEmpty) {
                        fetchCnrData(_cnrController.text);
                      }
                    },
                    child: Text('Search'),
                  ),
                ],
              ),
              SizedBox(height: 16), // Space between Search Row and Upload Button

              // Upload Document Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Set background color
                ),
                onPressed: () {
                  _pickDocument();
                },
                icon: Icon(Icons.upload_file), // Icon for upload
                label: Text('Upload Doc'),
              ),
              SizedBox(height: 20), // Space before loading indicator or data

              // Loading Indicator
              if (_isLoading)
                CircularProgressIndicator(),

              // Error Message
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),

              // CNR Data Section
              if (_cnrData != null)
                buildInfoSection(),

              SizedBox(height: 20), // Space before Add New CNR button

              // Add New CNR Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Set button color
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    _showAddCnrDialog();
                  },
                  child: Text(
                    'Add New CNR',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Function to display the dialog box
  void _showAddCnrDialog() {
    final TextEditingController _newCnrController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New CNR"),
          content: TextField(
            controller: _newCnrController,
            maxLength: 16, // Limit input to 16 digits
            // keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Enter 16-digit CNR Number",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {

                if (_newCnrController.text.length == 16) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserSelectionScreen(
                        Sendcnr: _newCnrController.text,
                        selectedFile: null,
                        sendScreentype: 'Cnr',
                      ),
                    ),
                  );

                  print("New CNR Number: ${_newCnrController.text}");

                  // Close the dialog
                  Navigator.of(context).pop();

                  // Navigate to UserSelectionScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserSelectionScreen(
                        Sendcnr: _newCnrController.text,
                        selectedFile: null,
                        sendScreentype: 'Cnr',
                      ),
                    ),
                  );
                } else {
                  // Show a snack bar if the CNR number is invalid
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      "Please enter a valid 16-digit CNR number.",
                      style: TextStyle(color: Colors.red),
                    ),
                  ));
                }
              },
              child: Text("Submit"),
            )

          ],
        );
      },
    );
  }


  Widget buildInfoRow(String heading, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              heading,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Text(
              value,
              style: TextStyle(fontSize: 14.0),
            ),
          ),
        ],
      ),
    );
  }
  File? _selectedFile;

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'], // Only allow Excel files
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!); // Get the file
      });
      // Get.to(() => UserSelectionScreen(
      //     Sendcnr :"",
      //     selectedFile: _selectedFile,
      //     sendScreentype: "uploadfile"
      //   // Pass the list of documents!
      // ));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>  UserSelectionScreen(Sendcnr :"",
            selectedFile: _selectedFile,
           sendScreentype: "uploadfile"),
        ),
      );
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file selected.')),
      );
    }
  }

  Widget buildInfoSection() {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildInfoRow("CNR Number:", _cnrData!['cnrNumber'] ?? "N/A"),
            buildInfoRow(
              "First Hearing Date:",
              extractFirstHearingDate(_cnrData!['caseStatus'] ?? []) ??
                  "Not Available",
            ),
            buildInfoRow(
              "Petitioner and Advocate:",
              (_cnrData!['petitionerAndAdvocate'] as List)
                  .expand((subList) => subList as List)
                  .join("\n"),
            ),
            buildInfoRow(
              "Respondent and Advocate:",
              (_cnrData!['respondentAndAdvocate'] as List)
                  .expand((subList) => subList as List)
                  .join("\n"),
            ),
            SizedBox(height: 4), // Spacer to create space between the content and button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>  UserSelectionScreen(Sendcnr :_cnrData!['cnrNumber'].toString(),
                        selectedFile: null,
                          sendScreentype: 'Cnr',),
                    ),
                  );
                  // Get.to(() => UserSelectionScreen(
                  //   Sendcnr :_cnrData!['cnrNumber'].toString(),
                  //   selectedFile: null,
                  //   sendScreentype: 'Cnr',
                  //   // sendExternalId: _cnrData!['cnrNumber'].toString(),
                  //   // Pass the list of documents
                  // ));
                  // Handle button press here
                  print("Button pressed");
                },
                child: Text("Add"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.blue, padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Text color
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}






class UserSelectionScreen extends StatefulWidget {
  final String Sendcnr;
  final File? selectedFile;
  final String sendScreentype;

  UserSelectionScreen({required this.Sendcnr, required this.selectedFile, required this.sendScreentype,  });

  @override
  _UserSelectionScreenState createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _users = [];
  int? _selectedUserIndex;

  Future<void> fetchUsers() async {
    final url = 'http://192.168.0.111:4001/api/external-user/get-external-user';

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'token':
          'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzYwNjg4NiwiZXhwIjoxNzM3NjkzMjg2fQ.Xr4rBiMZBW2zPZKWgEuQIf7FZEUR1FT_51S3lHqSYAI',
          // Ensure AppConstants.token is available
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
  void initState() {
    super.initState();
    fetchUsers();
    //   print(widget.selectedFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Advocate',style: TextStyle(color: Colors.white),),
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
              Card(
                elevation: 4, // Adds a shadow for a card effect
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Advocate:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
            ],
            SizedBox(height: 16),
            ElevatedButton(

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
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
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );

  }
  Future<void> _uploadDocument(String userId, String userName, BuildContext context) async {
    var headers = {
      'token':
      'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzYwNjg4NiwiZXhwIjoxNzM3NjkzMjg2fQ.Xr4rBiMZBW2zPZKWgEuQIf7FZEUR1FT_51S3lHqSYAI',
       // Replace with your actual token
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



