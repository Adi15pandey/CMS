import 'dart:convert';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SubTask extends StatefulWidget {
  const SubTask({super.key});

  @override
  State<SubTask> createState() => _SubTaskState();
}

class _SubTaskState extends State<SubTask> {
  List<Map<String, dynamic>> lowTasks = [];
  List<Map<String, dynamic>> mediumTasks = [];
  List<Map<String, dynamic>> highTasks = [];
  bool isLoading = true;
  String?token;

  @override
  void initState() {
    super.initState();
    _initializeData();
    fetchTasks();
    updateRemarks("12234","");

  }
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      fetchTasks();// Fetch cases if the token is valid
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


  Future<void> fetchTasks() async {
    var headers = {
      'token': '$token',

      // 'token': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzM2NTg2MywiZXhwIjoxNzM3NDUyMjYzfQ.tB2EW3kKVYhqrBtAZGmh9S5AMODKyHiOwUu_sA5MvCw'
    };

    var request = http.Request(
      'GET',
      Uri.parse('${GlobalService.baseUrl}/api/task/get-sub-alltask'),
    );

    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        var data = json.decode(responseBody);

        setState(() {
          lowTasks = List<Map<String, dynamic>>.from(data['lowTasks']);
          mediumTasks = List<Map<String, dynamic>>.from(data['mediumTasks']);
          highTasks = List<Map<String, dynamic>>.from(data['highTasks']);
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

  Future<void> updateRemarks(String taskId, String remarks) async {
    var headers = {
      'token': '$token',
      'Content-Type': 'application/json',
    };

    var body = json.encode({
      'taskId': taskId,
      'remarks': remarks,
    });

    var request = http.Request(
      'PUT',
      Uri.parse('http://192.168.0.108:4001/api/task/update-remarks'),
    );

    request.headers.addAll(headers);
    request.body = body;

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        print('Remarks updated successfully');
      } else {
        print("Failed to update remarks: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Error updating remarks: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sub Task'),
        backgroundColor: Color.fromRGBO(0, 74, 173, 1),foregroundColor:Colors.white,iconTheme: const IconThemeData(
          color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTaskSection('Low Priority Tasks', lowTasks),
              const SizedBox(height: 16),
              buildTaskSection('Medium Priority Tasks', mediumTasks),
              const SizedBox(height: 16),
              buildTaskSection('High Priority Tasks', highTasks),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTaskSection(String title, List<Map<String, dynamic>> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        tasks.isEmpty
            ? const Text('No tasks available.')
            : ListView.builder(
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
                title: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "CNR Number: ",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color.fromRGBO(0, 74, 173, 1), // CNR Number color
                        ),
                      ),
                      TextSpan(
                        text: "${task['cnrNumber'] ?? 'N/A'}",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color.fromRGBO(117, 117, 117, 1), // CNR value color
                        ),
                      ),
                    ],
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with bold text
                    SizedBox(height: 8), // Add space above
                    Text(
                      task['title'] ?? 'No Title',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4), // Add space below title

                    // Description Text
                    Text(
                      task['description'] ?? 'No Description',
                      style: TextStyle(color: Colors.black87),
                    ),
                    SizedBox(height: 8), // Add space between description and status/duedate

                    // Status Text with color
                    Text(
                      "Status: ${task['status'] ?? 'Unknown'}",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4), // Add space below status

                    // Due Date with conditional format
                    Text(
                      "Due Date: ${task['dueDate'] != null ? task['dueDate'].split('T')[0] : 'No Due Date'}",
                      style: TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
                trailing: Icon(Icons.edit, color: Colors.blue),
                onTap: () {
                  showTaskDetails(task); // Open the edit form when a task is tapped
                },
              )

            );
          },
        ),
      ],
    );
  }

  void showTaskDetails(Map<String, dynamic> task) {
    TextEditingController remarksController = TextEditingController();

    // Set remarks field if available
    remarksController.text = task['remarks'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(task['title'] ?? 'Task Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description: ${task['description'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('Status: ${task['status'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('Due Date: ${task['dueDate'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('Priority: ${task['priority'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('Action: ${task['action'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                if (task['attachments'] != null)
                  ...task['attachments'].map<Widget>((attachment) {
                    return GestureDetector(
                      onTap: () {
                        // Open attachment URL
                      },
                      child: Text(
                        'Attachment: ${attachment['name']}',
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    );
                  }).toList(),
                const SizedBox(height: 8),
                // Remarks input
                TextField(
                  controller: remarksController,
                  decoration: const InputDecoration(labelText: 'Add Remarks'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            // Conditionally show "Complete" button if action is "requested"
            if (task['action'] == 'requested')
              TextButton(
                onPressed: () {
                  // Handle complete action
                  // Update task status or perform other actions here
                  Navigator.pop(context);
                },
                child: const Text('Complete'),
              ),
            TextButton(
              onPressed: () {
                // Update remarks when the user submits
                updateRemarks(task['_id'], remarksController.text);
                Navigator.pop(context);
              },
              child: const Text('Save Remarks'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
