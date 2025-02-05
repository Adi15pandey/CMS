import 'dart:convert';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExpiredTask extends StatefulWidget {
  const ExpiredTask({super.key});

  @override
  State<ExpiredTask> createState() => _ExpiredTaskState();
}

class _ExpiredTaskState extends State<ExpiredTask> {
  List<Map<String, dynamic>> lowPriorityTasks = [];
  List<Map<String, dynamic>> mediumPriorityTasks = [];
  List<Map<String, dynamic>> highPriorityTasks = [];
  bool isLoading = true;

  bool isLowPriorityExpanded = false;
  bool isMediumPriorityExpanded = false;
  bool isHighPriorityExpanded = false;
  String?token;

  @override
  void initState() {
    super.initState();
    _initializeData();
    fetchExpiredTasks();
  }
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      fetchExpiredTasks(); // Fetch cases if the token is valid
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

  Future<void> fetchExpiredTasks() async {
    var headers = {
      'token': '$token',
      // 'token': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzM2NTg2MywiZXhwIjoxNzM3NDUyMjYzfQ.tB2EW3kKVYhqrBtAZGmh9S5AMODKyHiOwUu_sA5MvCw'
    };

    var request = http.Request(
      'GET',
      Uri.parse('${GlobalService.baseUrl}/api/task/get-expired-todos'),
    );

    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        var data = json.decode(responseBody);

        setState(() {

          lowPriorityTasks = List<Map<String, dynamic>>.from(data['lowTasks']);
          mediumPriorityTasks = List<Map<String, dynamic>>.from(data['mediumTasks']);
          highPriorityTasks = List<Map<String, dynamic>>.from(data['highTasks']);
          isLoading = false;
        });
      } else {
        print("Failed to fetch tasks: ${response.reasonPhrase}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching tasks: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _editTask(Map<String, dynamic> task) async {
    TextEditingController titleController =
    TextEditingController(text: task['title']);
    TextEditingController descriptionController =
    TextEditingController(text: task['description']);
    TextEditingController priorityController =
    TextEditingController(text: task['priority']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: priorityController,
                decoration: const InputDecoration(labelText: 'Priority'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Update the task with new values
                task['title'] = titleController.text;
                task['description'] = descriptionController.text;
                task['priority'] = priorityController.text;
                bool success = await _sendUpdatedTaskToServer(task);

                if (success) {
                  setState(() {
                    // Update the task in the list after successful edit
                  });
                }

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Function to send the updated task data to the server
  Future<bool> _sendUpdatedTaskToServer(Map<String, dynamic> task) async {
    var headers = {
      'Content-Type': 'application/json',
      'token': '$token',
    };

    var request = http.Request(
      'PUT', // Use PUT method for updating data
      Uri.parse('${GlobalService.baseUrl}/api/task/edit-expire-task/${task['id']}'), // Dynamic ID
    );

    request.headers.addAll(headers);
    request.body = json.encode({
      'title': task['title'],
      'description': task['description'],
      'priority': task['priority'],
    });

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        var data = json.decode(responseBody);
        print("Task updated successfully: $data");
        return true;
      } else {
        print("Failed to update task: ${response.reasonPhrase}");
        return false;
      }
    } catch (e) {
      print("Error updating task: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expired Task'),
        backgroundColor: Color.fromRGBO(0, 74, 173, 1),foregroundColor:Colors.white,iconTheme: const IconThemeData(
          color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          if (lowPriorityTasks.isNotEmpty)
            _buildExpandableSection(
              'Low Priority',
              lowPriorityTasks,
              isLowPriorityExpanded,
                  (bool value) {
                setState(() {
                  isLowPriorityExpanded = value;
                });
              },
            ),
          if (mediumPriorityTasks.isNotEmpty)
            _buildExpandableSection(
              'Medium Priority',
              mediumPriorityTasks,
              isMediumPriorityExpanded,
                  (bool value) {
                setState(() {
                  isMediumPriorityExpanded = value;
                });
              },
            ),
          if (highPriorityTasks.isNotEmpty)
            _buildExpandableSection(
              'High Priority',
              highPriorityTasks,
              isHighPriorityExpanded,
                  (bool value) {
                setState(() {
                  isHighPriorityExpanded = value;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection(
      String title,
      List<Map<String, dynamic>> tasks,
      bool isExpanded,
      Function(bool) onExpansionChanged,
      ) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      onExpansionChanged: onExpansionChanged,
      initiallyExpanded: isExpanded,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
                side: const BorderSide(
                  color: Color.fromRGBO(189, 217, 255, 1), // Light Blue Border
                  width: 2.0,
                ),
              ),
              child: ListTile(
                title: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0), // Adds space below title
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "CNR Number: ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(0, 74, 173, 1), // Blue color
                            fontSize: 16,
                          ),
                        ),
                        TextSpan(
                          text: "${task['cnrNumber'] ?? 'N/A'}",
                          style: TextStyle(
                            color: Color.fromRGBO(117, 117, 117, 1), // Grey color
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8), // Space before Task Title
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Task Title: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(0, 74, 173, 1),
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text: "${task['title'] ?? 'No Title'}",
                            style: TextStyle(
                              color: Color.fromRGBO(117, 117, 117, 1),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8), // Space before Description
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Description: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(0, 74, 173, 1),
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text: "${task['description'] ?? 'No Description'}",
                            style: TextStyle(
                              color: Color.fromRGBO(117, 117, 117, 1),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8), // Space before Status
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Status: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(0, 74, 173, 1),
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text: "${task['status'] ?? 'Unknown'}",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8), // Space before Due Date
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Due Date: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(0, 74, 173, 1),
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text: "${task['dueDate'] != null ? task['dueDate'].split('T')[0] : 'No Due Date'}",
                            style: TextStyle(
                              color: Color.fromRGBO(117, 117, 117, 1),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                trailing: Icon(Icons.edit, color: Colors.blue),
                onTap: () {
                  _editTask(task); // Open the edit form when a task is tapped
                },
              ),



            );
          },
        ),
      ],
    );
  }
}
