import 'dart:convert';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Ticketscreen extends StatefulWidget {
  const Ticketscreen({super.key});

  @override
  State<Ticketscreen> createState() => _TicketscreenState();
}

class _TicketscreenState extends State<Ticketscreen> {
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;
  String?token;

  @override
  void initState() {
    super.initState();
    _initializeData();
    fetchRequestedTasks();
  }
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      fetchRequestedTasks();// Fetch cases if the token is valid
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


  Future<void> fetchRequestedTasks() async {
    var headers = {
      'token': '$token',
    };

    var request = http.Request('GET', Uri.parse('${GlobalService.baseUrl}/api/task/get-requested-task'));

    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        var data = json.decode(responseBody);

        setState(() {
          tasks = List<Map<String, dynamic>>.from(data['data']);
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

  Future<void> handleAccept(String taskId) async {
    var headers = {
      'token': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzM2NTg2MywiZXhwIjoxNzM3NDUyMjYzfQ.tB2EW3kKVYhqrBtAZGmh9S5AMODKyHiOwUu_sA5MvCw',
    };

    var request = http.Request('PUT', Uri.parse('http://192.168.1.20:4001/api/task/accept-completed-task/$taskId'));
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        var data = json.decode(responseBody);

        if (data['success']) {
          print("Task accepted successfully!");
          fetchRequestedTasks();
        } else {
          print("Failed to accept task: ${data['message']}");
        }
      } else {
        print("Failed to accept task: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Error accepting task: $e");
    }
  }

  Future<void> handleReject(String taskId) async {
    var headers = {
      'token': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzM2NTg2MywiZXhwIjoxNzM3NDUyMjYzfQ.tB2EW3kKVYhqrBtAZGmh9S5AMODKyHiOwUu_sA5MvCw',
    };

    var request = http.Request('PUT', Uri.parse('http://192.168.1.20:4001/api/task/reject-task/$taskId'));
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        var data = json.decode(responseBody);

        if (data['success']) {
          print("Task rejected successfully!");
          fetchRequestedTasks();
        } else {
          print("Failed to reject task: ${data['message']}");
        }
      } else {
        print("Failed to reject task: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Error rejecting task: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requested Tasks'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(task['title'] ?? 'No Title'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description: ${task['description'] ?? 'No Description'}'),
                  Text('Due Date: ${task['dueDate'] ?? 'Unknown'}'),
                  Text('Priority: ${task['priority'] ?? 'Unknown'}'),
                  Text('Status: ${task['status'] ?? 'Unknown'}'),
                  Text('CNR Number: ${task['cnrNumber'] ?? 'Unknown'}'),
                ],
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      handleAccept(task['_id']);
                    },
                    child: const Text('Accept'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      handleReject(task['_id']);
                    },
                    child: const Text('Reject'),
                  ),
                ],
              ),
              onTap: () {
                // Handle task tap if needed, e.g., edit task or show details
              },
            ),
          );
        },
      ),
    );
  }
}
