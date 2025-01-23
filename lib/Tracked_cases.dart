import 'dart:convert';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Trackedcases extends StatefulWidget {
  @override
  _TrackedcasesState createState() => _TrackedcasesState();
}

class _TrackedcasesState extends State<Trackedcases> {
  bool _isLoading = false;
  List<dynamic> _unsavedCnrs = [];
  String?token;

  @override
  void initState() {
    super.initState();
    _fetchToken();
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
      fetchUnsavedCnr();


    } else {
      print('Token not found');
      _showMessage("Token not found. Please log in again.");
    }
  }
  Future<void> fetchUnsavedCnr({
    String searchQuery = '',
    int currentPage = 1,
    int pageLimit = 100000000,
    String selectedFilter = 'All',
  }) async {
    setState(() {
      _isLoading = true;
    });



    try {
      final response = await http.get(
        Uri.parse(
            '${GlobalService.baseUrl}/api/cnr/get-unsaved-cnr?searchQuery=$searchQuery&currentPage=$currentPage&pageLimit=$pageLimit&selectedFilter=$selectedFilter'),
        headers: {
          'token': '$token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            _unsavedCnrs = responseData['data'];
          });
        } else {
          _showMessage(responseData['message'] ?? "Failed to fetch data");
        }
      } else {
        _showMessage("Error: ${response.statusCode}");
      }
    } catch (e) {
      _showMessage("An error occurred: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tracked Cases"),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(

        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
            },
            children: [
              // Table Header
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "CNR NUMBER",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "STATUS",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              // Table Rows
              ..._unsavedCnrs.map((cnr) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        cnr['cnr'],
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 10,
                                color: cnr['status'] == "processed" ? Colors.purple : Colors.orange,
                              ),
                              SizedBox(width: 5),
                              Flexible( // Ensure the Text wraps or truncates to avoid overflow
                                child: Text(
                                  cnr['status'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis, // Truncate if text is too long
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 5),
                          Text(
                            "(Due on ${cnr['date']})",
                            style: TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
