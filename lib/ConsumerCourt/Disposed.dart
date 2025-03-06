import 'dart:convert';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DisposedCons extends StatefulWidget {
  const DisposedCons({super.key});

  @override
  State<DisposedCons> createState() => _DisposedConsState();
}

class _DisposedConsState extends State<DisposedCons> {
  List<dynamic> _cases = [];
  bool _isLoading = true;
  String?token;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchDisposedCases();
  } Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      _fetchDisposedCases(); // Fetch cases if the token is valid
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("No token found. Please log in."),
      ));
    }
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

  Future<void> _fetchDisposedCases() async {
    final String apiUrl =

        '${GlobalService
        .baseUrl}/api/consumer-court/case/get-consumer-court-disposed-cases';

//     const String token =
// 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTc0MTIzODUwMSwiZXhwIjoxNzQxMzI0OTAxfQ.1Prk0ugKccKq3gw7EwIUMjQTbvkrLL-VD0vqr6517N8';        // 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTc0MTE1MzQ4MSwiZXhwIjoxNzQxMjM5ODgxfQ.rCe7L4E6B-';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'token': '$token',
        },
      );
      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(json.encode(data)); // Debug: Print full response

        setState(() {
          _cases = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load cases');
      }
    } catch (e) {
      print("Error fetching cases: $e");
      setState(() {
        _isLoading = false;
        _cases = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(4, 163, 175, 1),
        centerTitle: true,
        title: const Text(
          'Disposed Cases',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cases.isEmpty
          ? const Center(child: Text("No cases available."))
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _cases.length,
        itemBuilder: (context, index) {
          final caseItem = _cases[index];

          final advocate = caseItem['users'].isNotEmpty
              ? caseItem['users'][0]['externalUserName']
              : "N/A";
          final caseNumber = caseItem['caseNumber']?.toString() ?? "N/A";
          final lastHearing = caseItem['caseHearingDetails'].isNotEmpty
              ? caseItem['caseHearingDetails'].last['dateOfHearing']
              : "N/A";
          final finalHearing = caseItem['caseHearingDetails'].isNotEmpty
              ? caseItem['caseHearingDetails'].last['dateOfNextHearing']
              : "N/A";
          final petitioner = caseItem['complainant'] ?? "N/A";
          final respondent = caseItem['respondent'] ?? "N/A";

          return Card(
            elevation: 4.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRow("ADVOCATE:", advocate),
                  _buildRow("CASE NUMBER:", caseNumber),
                  _buildRow("LAST HEARING:", lastHearing),
                  _buildRow("FINAL HEARING:", finalHearing),
                  _buildRow("PETITIONER:", petitioner),
                  _buildRow("RESPONDENT:", respondent),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Action button logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white
                    ),
                    child: const Text("View Details"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(4, 163, 175, 1),
            ),
          ),
          Expanded(  // Prevents overflow by making the text wrap properly
            child: Text(
              value,
              style: const TextStyle(
                color: Color.fromRGBO(117, 117, 117, 1),
              ),
              overflow: TextOverflow.ellipsis, // Truncates long text with "..."
              maxLines: 1, // Keeps it in one line
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
