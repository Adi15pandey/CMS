import 'package:cms/(subcases)Adddocs.dart';
import 'package:cms/Deletesubcases.dart';
import 'package:cms/subcasesdetail.dart';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CaseConsrepository extends StatefulWidget {
  const CaseConsrepository({Key? key}) : super(key: key);

  @override
  State<CaseConsrepository> createState() => _CaseConsrepositoryState();
}

class _CaseConsrepositoryState extends State<CaseConsrepository> {
  List<dynamic> _cases = [];
  bool _isLoading = false;
  String?token;

  @override
  void initState() {
    super.initState();
    _initializeData();
    fetchSubcases();
  }

  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      fetchSubcases(); // Fetch cases if the token is valid
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

  Future<void> fetchSubcases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${GlobalService
            .baseUrl}/api/consumer-court/case/get-consumer-court-cases',
        ),
        headers: {
          'token': '$token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            _cases = responseData['data'];
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
  final DateFormat dateFormat = DateFormat('dd-MM-yyyy'); // Change format as needed

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return "N/A";

    try {
      DateTime parsedDate = DateTime.parse(dateString);
      return dateFormat.format(parsedDate);
    } catch (e) {
      return "Invalid Date"; // Handle incorrect date format
    }
  }

  void _showMessage(String message) {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(4, 163, 175, 1),
        centerTitle: true, // Blue header
        title: const Text(
          'Case Repository',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
            color: Colors.white), // Back button color
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

          // Extracting case details
          final cnrNumber = caseItem['caseNumber'] ?? "N/A";
          final String respondent = caseItem['respondent']?.toString() ?? 'N/A';
          final String complainant = caseItem['complainant']?.toString() ?? 'N/A';


          final caseStage = caseItem['caseStage'] ?? "N/A";


          final lastHearing = (caseItem['caseHearingDetails'] != null &&
              caseItem['caseHearingDetails'].isNotEmpty &&
              caseItem['caseHearingDetails'].last['dateOfHearing'] != null)
              ? formatDate(caseItem['caseHearingDetails'].last['dateOfHearing'].toString())
              : "N/A";

          final nextHearing = (caseItem['caseHearingDetails'] != null &&
              caseItem['caseHearingDetails'].isNotEmpty &&
              caseItem['caseHearingDetails'].last['dateOfNextHearing'] != null)
              ? formatDate(caseItem['caseHearingDetails'].last['dateOfNextHearing'].toString())
              : "N/A";


          return Card(
            elevation: 4.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Case Number
                  _buildRow("CASE NUMBER:", cnrNumber),
                  _buildRow("Complainant:", complainant),
                  _buildRow("Respondent:", respondent),
                  _buildRow("Case Stage:", caseStage),
                  _buildRow("Last Hearing:", lastHearing),
                  _buildRow("Next Hearing:", nextHearing),

                  const SizedBox(height: 12.0),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(
                        label: "Details",
                        color: const Color.fromRGBO(4, 163, 175, 1),
                        onTap: () {
                          // Navigator.push(
                          //   context,
                          //   // MaterialPageRoute(
                          //   //   builder: (context) =>
                          //   //       // SubcasesDetailsScreen(cnrNumber: cnrNumber),
                          //   // ),
                          // );
                        },
                      ),
                      _buildActionButton(
                        label: "Add Doc",
                        color: const Color.fromRGBO(111, 181, 232, 1.0),
                        onTap: () {
                          final String id = caseItem['users'][0]['userId'];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddDocuments(id: id, cnrNumber: cnrNumber),
                            ),
                          );
                        },
                      ),
                      _buildActionButton(
                        label: "Delete",
                        color: const Color.fromRGBO(253, 101, 0, 1),
                        onTap: () async {
                          final String id = caseItem['users'][0]['userId'];
                          await deleteSubcase(
                            context: context,
                            id: id,
                            cnrNumber: cnrNumber,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Widget helper functions
  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(4, 163, 175, 1),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Color.fromRGBO(117, 117, 117, 1)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        child: Text(label),
      ),
    );
  }
}
