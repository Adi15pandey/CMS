import 'dart:convert';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TrackedConscases extends StatefulWidget {
  const TrackedConscases({super.key});

  @override
  State<TrackedConscases> createState() => _TrackedConscasesState();
}

class _TrackedConscasesState extends State<TrackedConscases> {
  List<dynamic> _cases = [];
  List<dynamic> _filteredCnrs = [];
  bool _isLoading = true;
  String?token;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchCases();
  }
  Future<void> _fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
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

  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      _fetchCases(); // Fetch cases if the token is valid
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("No token found. Please log in."),
      ));
    }
  }
  Future<void> _fetchCases() async {
    final String url =
        "${GlobalService.baseUrl}/api/consumer-court/case/unsaved-cases?searchQuery=&currentPage=1&pageLimit=50&selectedFilter=All";
//     const String token =
// "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTc0MTIzODUwMSwiZXhwIjoxNzQxMzI0OTAxfQ.1Prk0ugKccKq3gw7EwIUMjQTbvkrLL-VD0vqr6517N8";
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'token': '$token',
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data["success"]) {
          setState(() {
            _cases = data["data"];
            _filteredCnrs = _cases;
            _isLoading = false;
          });
        } else {
          throw Exception("Failed to load cases");
        }
      } else {
        throw Exception("Error fetching cases: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching cases: $e");
    }
  }

  void _filterSearchResults(String query) {
    setState(() {
      _filteredCnrs = _cases
          .where((caseItem) => caseItem['caseNumber']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase()))
          .toList();
    });
  }

  void _showFilterDialog() {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Filter Options"),
          content: const Text("Filter functionality goes here."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tracked Cases", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(4, 163, 175, 1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            color: Colors.white,
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSearchResults,
              decoration: InputDecoration(
                labelText: "Search CASE Number",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Table(
                  border: TableBorder.all(
                    color: const Color.fromRGBO(4, 163, 175, 1),
                  ),
                  columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(4, 163, 175, 1),
                      ),
                      children: [
                        _tableHeader("CASE NUMBER"),
                        _tableHeader("STATUS"),
                      ],
                    ),
                    ..._filteredCnrs.map(_buildTableRow),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(dynamic caseItem) {
    return TableRow(
      children: [
        _tableCell(caseItem['caseNumber']), // Case Number
        _statusWithDateCell(caseItem['status'], caseItem['date']), // Status + Due Date
      ],
    );
  }



  Widget _statusWithDateCell(String status, String dueDate) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Wrap Row inside a Flexible or ConstrainedBox to prevent overflow
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100), // Adjust width as needed
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 10, color: Colors.blue),
                  const SizedBox(width: 5),
                  Flexible( // Prevents overflow
                    child: Text(
                      status,
                      overflow: TextOverflow.ellipsis, // Avoid text overflow
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4), // Spacing
          Text(
            "(Due on $dueDate)",
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
  Widget _tableHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _tableCell(String value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        value,
        style: const TextStyle(color: Colors.black),
        textAlign: TextAlign.center,
      ),
    );
  }
}
