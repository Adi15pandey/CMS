import 'dart:io';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';


class Taskscreen extends StatefulWidget {
  const Taskscreen({super.key});

  @override
  State<Taskscreen> createState() => _TaskscreenState();
}

class _TaskscreenState extends State<Taskscreen> {
  final List<Map<String, dynamic>> lowPriorityTasks = [];
  final List<Map<String, dynamic>> mediumPriorityTasks = [];
  final List<Map<String, dynamic>> highPriorityTasks = [];
  String? token;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchTasks();
  }

  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      _fetchTasks(); // Fetch cases if the token is valid
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

  Future<void> _fetchTasks() async {
    try {
      var headers = {
        'token': '$token',
      };

      // Send GET request
      var response = await http.get(
        Uri.parse('${GlobalService.baseUrl}/api/task/get-alltask'),
        headers: headers,
      );

      // Check response status
      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        // Parse and cast data to the correct type
        List<Map<String, dynamic>> lowTasks =
            List<Map<String, dynamic>>.from(data['lowTasks'] ?? []);
        List<Map<String, dynamic>> mediumTasks =
            List<Map<String, dynamic>>.from(data['mediumTasks'] ?? []);
        List<Map<String, dynamic>> highTasks =
            List<Map<String, dynamic>>.from(data['highTasks'] ?? []);

        // Update state
        setState(() {
          lowPriorityTasks.clear();
          mediumPriorityTasks.clear();
          highPriorityTasks.clear();

          lowPriorityTasks.addAll(lowTasks);
          mediumPriorityTasks.addAll(mediumTasks);
          highPriorityTasks.addAll(highTasks);
        });

        print("Tasks fetched successfully");
      } else {
        print("Failed to fetch tasks. Status Code: ${response.statusCode}");
        print("Response Body: ${response.body}");
      }
    } catch (e) {
      print("An error occurred while fetching tasks: $e");
    }
  }

  Future<void> _addTask(
      Map<String, String> task, String priority, File? file) async {
    try {
      var headers = {
        'token': '$token',
        // 'token': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzM2NTg2MywiZXhwIjoxNzM3NDUyMjYzfQ.tB2EW3kKVYhqrBtAZGmh9S5AMODKyHiOwUu_sA5MvCw',
      };

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${GlobalService.baseUrl}/api/task/add-task'),
      );

      request.headers.addAll(headers);
      request.fields.addAll({
        'title': task['title'] ?? '',
        'description': task['description'] ?? '',
        'dueDate': task['dueDate'] ?? '',
        'priority': priority,
        'cnrNumber': task['cnrNumber'] ?? '',
        'email': task['email'] ?? '',
        'fileNames': task['fileNames'] ?? '',
      });

      if (file != null) {
        request.files
            .add(await http.MultipartFile.fromPath('files', file.path));
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      var jsonResponse = jsonDecode(responseBody);
      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        print("Task added successfully: ${jsonResponse['message']}");
        _fetchTasks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added successfully!')),
        );
      } else {
        print("Failed to add task. Status Code: ${response.statusCode}");
        print("Response Body: $responseBody");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add task!')),
        );
      }
    } catch (e) {
      // print("An error occurred: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        backgroundColor: Color.fromRGBO(0, 74, 173, 1),foregroundColor:Colors.white,iconTheme: const IconThemeData(
          color: Colors.white),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildPriorityCard("Low Priority", lowPriorityTasks),
                  _buildPriorityCard("Medium Priority", mediumPriorityTasks),
                  _buildPriorityCard("High Priority", highPriorityTasks),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor:                                              Color.fromRGBO(0, 74, 173, 1),
        foregroundColor: Colors.white,// Blue color

        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskScreen(onTaskAdded: _addTask),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromRGBO(0, 74, 173, 1)),
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
                backgroundColor: Color.fromRGBO(0, 74, 173, 1),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color.fromRGBO(0, 74, 173, 1)),
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

  Widget _buildDropdown({required String value, required Map<String, String> items, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(),
      items: items.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
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

  void _saveTask(
      String taskId,
      Map<String, dynamic> task,
      String cnr,
      String title,
      String desc,
      String dueDate,
      List<String> emails,
      String priority,
      String status) async {
    print("Saving task:");
    print("Task ID: $taskId");
    print("CNR: $cnr, Title: $title, Description: $desc");
    print("Due Date: $dueDate, Emails: $emails");
    print("Priority: $priority, Status: $status");

    String url = "${GlobalService.baseUrl}/api/task/edit-task/$taskId";

    Map<String, dynamic> requestBody = {
      "_id": taskId,
      "cnrNumber": cnr,
      "title": title,
      "description": desc,
      "dueDate": "${DateFormat('yyyy-MM-dd').format(DateTime.parse(dueDate))}T00:00:00.000Z",

      "priority": priority,
      "status": status,
      "emails": emails,
    };

    try {
      var response = await http.put(
        Uri.parse(url),
        headers: {
          'token': '$token',

          "Content-Type": "application/json"
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        print("Response: ${responseData['message']}");
        print("Task ID: ${responseData['data']['_id']}");
      } else {
        print("Failed to update task. Status code: ${response.statusCode}");
        print("Error: ${response.body}");
      }
    } catch (error) {
      print("Error occurred while making the API request: $error");
    }
  }


  Widget _buildTextField(String label, TextEditingController controller,
      {bool isReadOnly = false, bool isDate = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly || isDate,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          suffixIcon: isDate
              ? IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      controller.text =
                          "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                    }
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildPriorityCard(String title, List<Map<String, dynamic>> tasks) {
    return Card(
      elevation: 4,shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
      side: const BorderSide(
        color: Color.fromRGBO(189, 217, 255, 1), // Light Blue Border
        width: 2.0,
      ),
    ),
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (tasks.isEmpty)
              const Text("No tasks added.")
            else
              Column(
                children: tasks
                    .map((task) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: const BorderSide(
                      color: Color.fromRGBO(189, 217, 255, 1), // Light Blue Border
                      width: 2.0,
                    ),
                  ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Adds padding around the ListTile
                            title: Padding(
                              padding: const EdgeInsets.only(bottom: 8), // Space between title and subtitle
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
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
                                          text: "${task['cnrNumber'] ?? ''}",
                                          style: TextStyle(
                                            color: Color.fromRGBO(117, 117, 117, 1), // Grey color
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4), // Spacing between rows
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "Task Title: ",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromRGBO(0, 74, 173, 1),
                                            fontSize: 16,
                                          ),
                                        ),
                                        TextSpan(
                                          text: "${task['title'] ?? ''}",
                                          style: TextStyle(
                                            color: Color.fromRGBO(117, 117, 117, 1),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4), // Space above subtitle
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                          text: "${task['description'] ?? ''}",
                                          style: TextStyle(
                                            color: Color.fromRGBO(117, 117, 117, 1),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
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
                                          text: "${task['status'] ?? ''}",
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
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
                                          text: "${task['dueDate']?.split('T')[0] ?? 'N/A'}",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (task['attachments'] != null && task['attachments'].isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.attach_file,color: Colors.green,),
                                    onPressed: () {
                                      String url = task['attachments'][0]['url'];
                                      final Uri _url = Uri.parse(url);
                                      launchUrl(_url);
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.edit,color: Colors.blue,),
                                  onPressed: () {
                                    _editTask(context, task);
                                  },
                                ),
                              ],
                            ),
                          ),


                ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class AddTaskScreen extends StatefulWidget {
  final Function(Map<String, String>, String, File?) onTaskAdded;

  const AddTaskScreen({required this.onTaskAdded, super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fileNamesController = TextEditingController();
  final TextEditingController _cnrNumberController = TextEditingController();

  File? _selectedFile;
  String? _selectedPriority;
  DateTime? _dueDate;

  Future<void> _pickFile() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(' Add Task'),
        backgroundColor: Color.fromRGBO(0, 74, 173, 1),foregroundColor:Colors.white,iconTheme: const IconThemeData(
          color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Task Title",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter Task Title",
                ),
              ),
              const SizedBox(height: 16),
              const Text("Task Description",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter Task Description",
                ),
              ),
              const SizedBox(height: 16),
              const Text("Email",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter Email",
                ),
              ),
              const SizedBox(height: 16),
              const Text("CNR Number",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _cnrNumberController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter CNR Number",
                ),
              ),
              const SizedBox(height: 16),
              const Text("File Name",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _fileNamesController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter File Name",
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickFile,
                child: const Text("Select File"),
              ),
              const SizedBox(height: 16),
              const Text("Priority",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                items: const [
                  DropdownMenuItem(value: "low", child: Text("low")),
                  DropdownMenuItem(value: "medium", child: Text("medium")),
                  DropdownMenuItem(value: "high", child: Text("high")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Select Priority",
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Due Date",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _dueDate = pickedDate;
                        });
                      }
                    },
                    child: Text(
                      _dueDate != null
                          ? "${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}"
                          : "Select Date",
                      style: const TextStyle(                                            color: Color.fromRGBO(0, 74, 173, 1), // Blue color
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_titleController.text.isEmpty ||
                      _descriptionController.text.isEmpty ||
                      _emailController.text.isEmpty ||
                      _cnrNumberController.text.isEmpty ||
                      _selectedPriority == null ||
                      _dueDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please fill all required fields!"),
                      ),
                    );
                    return;
                  }

                  Map<String, String> task = {
                    'title': _titleController.text,
                    'description': _descriptionController.text,
                    'dueDate': _dueDate!.toIso8601String(),
                    'email': _emailController.text,
                    'fileNames': _fileNamesController.text,
                    'cnrNumber': _cnrNumberController.text,
                  };

                  widget.onTaskAdded(task, _selectedPriority!, _selectedFile);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor:Color.fromRGBO(0, 74, 173, 1,),foregroundColor: Colors.white // Blue color
              ),
                child: const Text("Add Task"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
