import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  // Add bool variables to track the expansion state of each section
  bool isLowPriorityExpanded = false;
  bool isMediumPriorityExpanded = false;
  bool isHighPriorityExpanded = false;

  @override
  void initState() {
    super.initState();
    fetchExpiredTasks();
  }

  Future<void> fetchExpiredTasks() async {
    var headers = {
      'token': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzM2NTg2MywiZXhwIjoxNzM3NDUyMjYzfQ.tB2EW3kKVYhqrBtAZGmh9S5AMODKyHiOwUu_sA5MvCw'
    };

    var request = http.Request(
      'GET',
      Uri.parse('http://192.168.0.108:4001/api/task/get-expired-todos'),
    );

    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        var data = json.decode(responseBody);

        setState(() {
          // Group tasks by priority
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

    // Show dialog with form for editing task
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

                // Send the updated task data to the server
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
      'token': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzM2NTg2MywiZXhwIjoxNzM3NDUyMjYzfQ.tB2EW3kKVYhqrBtAZGmh9S5AMODKyHiOwUu_sA5MvCw'
    };

    var request = http.Request(
      'PUT', // Use PUT method for updating data
      Uri.parse('http://192.168.0.108:4001/api/task/edit-expire-task/${task['id']}'), // Dynamic ID
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
        title: const Text('Expired Tasks'),
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
              child: ListTile(
                title: Text(task['title'] ?? 'No Title'),
                subtitle: Text(task['description'] ?? 'No Description'),
                trailing: Text(task['status'] ?? 'Unknown'),
                onTap: () {
                  // Open the edit form when a task is tapped
                  _editTask(task);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
