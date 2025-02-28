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
      'token': '$token',};

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

  void _editTask(BuildContext context, Map<String, dynamic> task) {
    TextEditingController cnrController = TextEditingController(text: task['cnrNumber'] ?? '');
    TextEditingController titleController = TextEditingController(text: task['title'] ?? '');
    TextEditingController descriptionController = TextEditingController(text: task['description'] ?? '');
    TextEditingController dueDateController = TextEditingController(text: task['dueDate']?.split('T')[0] ?? '');
    TextEditingController emailController = TextEditingController(
      text: task['emails'] != null ? task['emails'].join(', ') : '',
    );

    String selectedPriority = task['priority'] ?? 'medium';
    String selectedStatus = task['status'] ?? 'inProgress';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Edit Task",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(4, 163, 175, 1),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLabel("CNR Number"),
                _buildInputField(cnrController),
                _buildLabel("Task Title"),
                _buildInputField(titleController),
                _buildLabel("Task Description"),
                _buildInputField(descriptionController, maxLines: 3),
                _buildLabel("Due Date"),
                _buildInputField(dueDateController),
                _buildLabel("Email (comma-separated)"),
                _buildInputField(emailController),
                _buildLabel("Priority"),
                _buildDropdown(
                  value: selectedPriority,
                  items: {
                    "high": "High Priority",
                    "medium": "Medium Priority",
                    "low": "Low Priority"
                  },
                  onChanged: (value) => selectedPriority = value!,
                ),
                _buildLabel("Status"),
                _buildDropdown(
                  value: selectedStatus,
                  items: {
                    "inProgress": "In Process",
                    "completed": "Completed",
                    "pending": "Pending"
                  },
                  onChanged: (value) => selectedStatus = value!,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                List<String> emails = emailController.text.isNotEmpty
                    ? emailController.text.split(',').map((e) => e.trim()).toList()
                    : [];

                _saveTask(
                  task['_id'], // Task ID
                  task,
                  cnrController.text,
                  titleController.text,
                  descriptionController.text,
                  dueDateController.text,
                  emails,
                  selectedPriority,
                  selectedStatus,
                );

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(4, 163, 175, 1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
  Future<void> _saveTask(
      String taskId,
      Map<String, dynamic> originalTask,
      String cnrNumber,
      String title,
      String description,
      String dueDate,
      List<String> emails,
      String priority,
      String status,
      ) async {
    // Prepare the updated task data
    Map<String, dynamic> updatedTask = {
      '_id': taskId, // Ensure the task ID remains unchanged
      'cnrNumber': cnrNumber,
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'emails': emails,
      'priority': priority,
      'status': status,
    };

    try {
      // Assuming you're sending this updated task to an API endpoint
      var url = Uri.parse('${GlobalService.baseUrl}/api/task/edit-expire-task/$taskId'); // Replace with your actual endpoint
      var response = await http.put(
        url,
        headers: {
          'token': '$token',
          'Content-Type': 'application/json'},
        body: jsonEncode(updatedTask),
      );

      // Check for successful response
      if (response.statusCode == 200) {
        print("Task updated successfully!");
        // Update the UI with the new task data, if needed
        setState(() {
          // Example: You can replace the original task with the updated task here
          originalTask['title'] = title;
          originalTask['description'] = description;
          originalTask['priority'] = priority;
          originalTask['status'] = status;
        });
      } else {
        print("Failed to update task: ${response.body}");
        // Show an error message to the user
        _showErrorDialog("Failed to update task. Please try again.");
      }
    } catch (error) {
      print("Error: $error");
      _showErrorDialog("An error occurred while updating the task.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color.fromRGBO(4, 163, 175, 1),),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: _inputDecoration(),
    );
  }

  Widget _buildDropdown({
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.containsKey(value) ? value : items.keys.first,
      decoration: _inputDecoration(),
      items: items.entries
          .map((entry) => DropdownMenuItem<String>(
        value: entry.key,
        child: Text(entry.value),
      ))
          .toList(),
      onChanged: onChanged,
    );

  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromRGBO(0, 74, 173, 1))),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[400]!)),
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
        backgroundColor: Color.fromRGBO(4, 163, 175, 1),foregroundColor:Colors.white,
        centerTitle: true,iconTheme: const IconThemeData(
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
                            color:Color.fromRGBO(4, 163, 175, 1), // Blue color
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
                              color: Color.fromRGBO(4, 163, 175, 1),
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
                              color: Color.fromRGBO(4, 163, 175, 1),
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
                              color: Color.fromRGBO(4, 163, 175, 1),
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
                              color: Color.fromRGBO(4, 163, 175, 1),
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
                  _editTask(context,task); // Open the edit form when a task is tapped
                },
              ),



            );
          },
        ),
      ],
    );
  }
}
