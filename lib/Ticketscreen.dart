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
      fetchRequestedTasks();
      handleReject(""); // Fetch cases if the token is valid
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

    var request = http.Request('GET',
        Uri.parse('${GlobalService.baseUrl}/api/task/get-requested-task'));

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
      'token': '$token',
    };

    var request = http.Request('PUT', Uri.parse(
        '${GlobalService.baseUrl}/api/task/accept-completed-task/$taskId'));
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
      'token': '$token',
    };

    var request = http.Request('PUT',
        Uri.parse('${GlobalService.baseUrl}/api/task/reject-task/$taskId'));
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
      appBar:AppBar(
        title: const Text('Ticket'),
        backgroundColor: Color.fromRGBO(4, 163, 175, 1),foregroundColor:Colors.white,
        centerTitle: true,iconTheme: const IconThemeData(
          color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Color.fromRGBO(189, 217, 255, 1), // Light blue border color
                width: 2, // Border width
              ),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task Title
                  // Text(
                  //   task['title'] ?? 'No Title',
                  //   style: TextStyle(
                  //     fontSize: 20,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  const SizedBox(height: 8),

                  // CNR Number & Priority (Row layout)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CNR Number:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color.fromRGBO(4, 163, 175, 1), // rgba(0, 74, 173, 1)
                        ),
                      ),
                      const SizedBox(width: 16),  // Added spacing between key and value
                      Expanded(
                        child: Text(
                          task['cnrNumber'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF757575), // rgba(117, 117, 117, 1)
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Priority
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Priority:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color.fromRGBO(4, 163, 175, 1), // rgba(0, 74, 173, 1)
                        ),
                      ),
                      const SizedBox(width: 16),  // Added spacing between key and value
                      Expanded(
                        child: Text(
                          task['priority'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF757575), // rgba(117, 117, 117, 1)
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Description:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color.fromRGBO(4, 163, 175, 1), // rgba(0, 74, 173, 1)
                        ),
                      ),
                      const SizedBox(width: 16),  // Added spacing between key and value
                      Expanded(
                        child: Text(
                          task['description'] ?? 'No Description',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF757575), // rgba(117, 117, 117, 1)
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Responder
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Responder:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color.fromRGBO(4, 163, 175, 1),// rgba(0, 74, 173, 1)
                        ),
                      ),
                      const SizedBox(width: 16),  // Added spacing between key and value
                      Expanded(
                        child: Text(
                          task['responder'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF757575), // rgba(117, 117, 117, 1)
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Remarks
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remarks:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color.fromRGBO(4, 163, 175, 1), // rgba(0, 74, 173, 1)
                        ),
                      ),
                      const SizedBox(width: 16),  // Added spacing between key and value
                      Expanded(
                        child: Text(
                          task['remarks'] ?? 'No Remarks',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF757575), // rgba(117, 117, 117, 1)
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          handleAccept(task['_id']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(4, 163, 175, 1),
                          foregroundColor: Colors.white// rgba(0, 111, 253, 1) for Accept
                        ),
                        child: const Text('Accept'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          handleReject(task['_id']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(253, 101, 0, 1),
                            foregroundColor: Colors.white
                        ),
                        child: const Text('Reject'),
                      ),
                    ],
                  )

                ],
              ),
            ),
          );


        },
      ),
    );
  }
}