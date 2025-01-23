import 'dart:convert';

import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class UsersNotification extends StatefulWidget {
  final String userId;
  final String userName;
  final String sendcnr;


  UsersNotification({required this.userId, required this.userName, required this.sendcnr});

  @override
  State<UsersNotification> createState() => _UsersNotificationState();
}

class _UsersNotificationState extends State<UsersNotification> {
  List<Map<String, String>> userFields = [
    {"name": "", "email": "", "mobile": "", "dayBeforeNotification": ""}
  ];
  String?token;
  bool   isLoading=true;

  // Function to add new user fields
  void addUserFields() {
    if (userFields.length < 8) {
      setState(() {
        userFields.add({
          "name": "",
          "email": "",
          "mobile": "",
          "dayBeforeNotification": ""
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You cannot add more than 8 users.')),
      );
    }
  }


  // Function to remove a set of fields at a specific index
  void removeUserFields(int index) {
    setState(() {
      userFields.removeAt(index);
    });
  }

  // Function to handle submission of data
  // Future<void> submitData() async {
  //   // Prepare the jointUser list
  //   List<Map<String, dynamic>> jointUser = [];
  //   for (var user in userFields) {
  //     jointUser.add({
  //       "name": user["name"] ?? "",  // Name of the user
  //       "email": user["email"] ?? "",  // Email of the user
  //       "mobile": user["mobile"] ?? "",  // Mobile number of the user
  //       "dayBeforeNotification": int.tryParse(user["dayBeforeNotification"] ?? "0") ?? 0,  // Notification days before (ensure it's an int)
  //     });
  //   }
  //
  //   // Payload data
  //   Map<String, dynamic> payload = {
  //     "cnrNumber": widget.sendcnr,  // CNR number from the widget
  //     "externalUserId": widget.userId,  // External user ID from the widget
  //     "externalUserName": widget.userName,  // External user name from the widget
  //     "jointUser": jointUser,  // Joint users data
  //   };
  //   print(payload);
  //
  //   // API URL
  //   String apiUrl = "http://192.168.0.107:4001/api/cnr/addnew-singlecnr";
  //
  //   // Send POST request
  //   try {
  //     final response = await http.post(
  //       Uri.parse(apiUrl),
  //       headers: {
  //         'token': AppConstants.token,  // Authorization token
  //         'Content-Type': 'application/json',  // Content type is JSON
  //       },
  //       body: json.encode(payload),  // Convert payload to JSON string
  //     );
  //
  //     // Handle the response
  //     if (response.statusCode == 200) {
  //       // Successfully added CNR
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('CNR added successfully!')),
  //       );
  //     } else {
  //       // Try to parse the API's response body to show the message
  //       try {
  //         final responseBody = json.decode(response.body);
  //         String errorMessage = responseBody['message'] ?? 'Failed to add CNR.';
  //
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text(' $errorMessage')),
  //         );
  //       } catch (e) {
  //         // In case the response body is not a valid JSON or doesn't contain the expected fields
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Failed to add CNR: ${response.statusCode}')),
  //         );
  //       }
  //     }
  //   } catch (error) {
  //     // Handle network or other errors
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: $error')),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text(
          'Notification Setting',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...userFields.asMap().entries.map((entry) {
                int index = entry.key;
                var userField = entry.value;

                return Card(
                  elevation: 4, // Adds shadow for a card effect
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display the user number (e.g., User 1, User 2, etc.)
                        Text(
                          'User ${index + 1}', // Display "User 1", "User 2", etc.
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        SizedBox(height: 10),

                        // User Fields with borders
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(), // Adds border to the TextField
                          ),
                          onChanged: (value) {
                            userField["name"] = value;
                          },
                        ),
                        SizedBox(height: 10),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(), // Adds border to the TextField
                          ),
                          onChanged: (value) {
                            userField["email"] = value;
                          },
                        ),
                        SizedBox(height: 10),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Mobile',
                            border: OutlineInputBorder(), // Adds border to the TextField
                          ),
                          onChanged: (value) {
                            userField["mobile"] = value;
                          },
                        ),
                        SizedBox(height: 10),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Day Before Notification',
                            border: OutlineInputBorder(), // Adds border to the TextField
                          ),
                          onChanged: (value) {
                            userField["dayBeforeNotification"] = value;
                          },
                        ),
                        SizedBox(height: 20),

                        // Remove button (only shown if there are more than 1 set of fields)
                        if (userFields.length > 1)
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: Icon(Icons.remove_circle_outline),
                              color: Colors.red,
                              onPressed: () {
                                removeUserFields(index);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              // Add More Fields Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Set the background color to black
                ),
                onPressed: addUserFields,
                child: Text(
                  'Add More Fields',
                  style: TextStyle(color: Colors.white),
                ),
              ),

              // Submit Button
              SizedBox(height: 20), // Add space between buttons
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Set the background color to black
                  ),
                  onPressed: submitData, // Handle submission when clicked
                  child: Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );


  }
  @override
  void initState() {
    super.initState();
    _initializeData();
    submitData();
  }
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      submitData();// Fetch cases if the token is valid
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

  Future<void> submitData() async {
    // Validate user fields before submitting
    for (var user in userFields) {
      if (user["name"]?.isEmpty ?? true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in the Name for all users.')),
        );
        return;
      }
      if (user["email"]?.isEmpty ?? true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in the Email for all users.')),
        );
        return;
      }
      if (user["mobile"]?.isEmpty ?? true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in the Mobile for all users.')),
        );
        return;
      }
      if (user["dayBeforeNotification"]?.isEmpty ?? true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in the Day Before Notification for all users.')),
        );
        return;
      }
    }

    // Prepare the jointUser list
    List<Map<String, dynamic>> jointUser = [];
    for (var user in userFields) {
      jointUser.add({
        "name": user["name"] ?? "",  // Name of the user
        "email": user["email"] ?? "",  // Email of the user
        "mobile": user["mobile"] ?? "",  // Mobile number of the user
        "dayBeforeNotification": int.tryParse(user["dayBeforeNotification"] ?? "0") ?? 0,  // Notification days before (ensure it's an int)
      });
    }

    // Payload data
    Map<String, dynamic> payload = {
      "cnrNumber": widget.sendcnr,  // CNR number from the widget
      "externalUserId": widget.userId,  // External user ID from the widget
      "externalUserName": widget.userName,  // External user name from the widget
      "jointUser": jointUser,  // Joint users data
    };

    // API URL
    String apiUrl = "${GlobalService.baseUrl}/api/cnr/addnew-singlecnr";

    // Send POST request
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'token':
          'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzYwNjg4NiwiZXhwIjoxNzM3NjkzMjg2fQ.Xr4rBiMZBW2zPZKWgEuQIf7FZEUR1FT_51S3lHqSYAI', // Authorization token
          'Content-Type': 'application/json',  // Content type is JSON
        },
        body: json.encode(payload),  // Convert payload to JSON string
      );

      // Handle the response
      if (response.statusCode == 200) {
        // Successfully added CNR
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CNR added successfully!')),
        );
      } else {
        // Try to parse the API's response body to show the message
        try {
          final responseBody = json.decode(response.body);
          String errorMessage = responseBody['message'] ?? 'Failed to add CNR.';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(' $errorMessage')),
          );
        } catch (e) {
          // In case the response body is not a valid JSON or doesn't contain the expected fields
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add CNR: ${response.statusCode}')),
          );
        }
      }
    } catch (error) {
      // Handle network or other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

}
