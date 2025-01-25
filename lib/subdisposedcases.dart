import 'package:cms/(subdisposedcases)viewDetail.dart';
import 'package:cms/AddDocsdisposed.dart';
import 'package:cms/Deletesubcases.dart';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SubDisposedCases extends StatefulWidget {
  const SubDisposedCases({super.key});

  @override
  State<SubDisposedCases> createState() => _SubDisposedCasesState();
}

class _SubDisposedCasesState extends State<SubDisposedCases> {
  final String apiUrl =
      '${GlobalService.baseUrl}/api/cnr/get-disposed-sub-cnr?pageNo=1&pageLimit=10&filterText=&nextHearing=0&petitioner=0&respondent=0';
  // final String token =
  //     'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzY5NDIyOSwiZXhwIjoxNzM3NzgwNjI5fQ.61uspeeYspKI9Kr6VGE-sThMoOCOmbx89B1C5S4M2wE';

  bool _isLoading = true;
  List<dynamic> _cases = [];
  String?token;

  @override
  void initState() {
    super.initState();
    _initializeData();
    fetchDisposedCases();

  }
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      fetchDisposedCases();// Fetch cases if the token is valid
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

  Future<void> fetchDisposedCases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'token': '$token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _cases = data['data'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch data: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void addDocument(String cnrNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add Document for CNR: $cnrNumber')),
    );
  }

  void deleteCase(String cnrNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Delete Case for CNR: $cnrNumber')),
    );
  }

  void viewDetails(String cnrNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View Details for CNR: $cnrNumber')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disposed Cases'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _cases.length,
        itemBuilder: (context, index) {
          final caseItem = _cases[index];
          final caseDetails = caseItem["caseDetails"] ?? {};
          final caseHistory = caseItem["caseHistory"] ?? [];
          final petitioner = caseItem["petitionerAndAdvocate"]?[0] ?? "N/A";
          final respondent = caseItem["respondentAndAdvocate"]?[0] ?? "N/A";

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CNR Number: ${caseItem["cnrNumber"]}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last Hearing: ${caseHistory.isNotEmpty ? caseHistory[0][1] : "N/A"}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Final Hearing: ${caseHistory.isNotEmpty ? caseHistory[0][2] : "N/A"}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Petitioner: $petitioner',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Respondent: $respondent',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Get the first userId from the caseItem
                          final String id = caseItem['userId'][0]['userId'];
                          final String cnrNumber = caseItem['cnrNumber']; // Assuming caseItem contains cnrNumber

                          // Navigate to the AddDocsdisposed screen with id and cnrNumber
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddDocsdisposed(
                                id: id, // Pass the userId
                                cnrNumber: cnrNumber, // Pass the cnrNumber
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                        ),
                        child: const Text('Add docs'),
                      ),

                      // Expanded(
                      //   child: ElevatedButton(
                      //     onPressed: ()async {
                      //       final String id = caseItem['userId'][0]['userId'];
                      //       final String cnrNumber = caseItem['cnrNumber'];
                      //
                      //       await deleteSubcase(
                      //         context: context,
                      //         id: id,
                      //         cnrNumber: cnrNumber,
                      //       );
                      //
                      //     },
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor: Colors.red,
                      //     ),
                      //     child: const Text("Delete"),
                      //   ),
                      // ),

                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewDetail(
                              cnrNumber: caseItem["cnrNumber"], // Pass the CNR Number here
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text('Details'),
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
}
