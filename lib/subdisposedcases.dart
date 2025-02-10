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
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Failed to fetch data: ${response.body}')),
        // );
      }
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('An error occurred: $e')),
      // );
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
        title: Text('Disposed Cases', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromRGBO(0, 74, 173, 1),
        centerTitle: true,
        iconTheme: const IconThemeData(
            color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _cases.length,
        itemBuilder: (context, index) {
          final caseItem = _cases[index];
          final caseDetails = caseItem["caseDetails"] ?? {};
          final caseHistory = caseItem["caseHistory"] ?? [];
          final petitionerList = caseItem["petitionerAndAdvocate"] as List<dynamic>? ?? [];
          final petitioner = petitionerList.isNotEmpty ? petitionerList[0].toString() : "N/A";

          final respondentList = caseItem["respondentAndAdvocate"] as List<dynamic>? ?? [];
          final respondent = respondentList.isNotEmpty ? respondentList[0].toString() : "N/A";


          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CNR Number
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'CNR Number: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color.fromRGBO(0, 74, 173, 1), // Blue color for label
                          ),
                        ),
                        TextSpan(
                          text: '${caseItem["cnrNumber"]}',
                          style: TextStyle(
                            // fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color.fromRGBO(117, 117, 117, 1), // Gray color for value
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Last Hearing
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Last Hearing: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color.fromRGBO(0, 74, 173, 1),
                              ),
                            ),
                            TextSpan(
                              text: '${caseHistory.isNotEmpty && caseHistory[0].isNotEmpty ? caseHistory[0][0] : "N/A"}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color.fromRGBO(117, 117, 117, 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Final Hearing: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color.fromRGBO(0, 74, 173, 1),
                              ),
                            ),
                            TextSpan(
                              text: '${caseHistory.isNotEmpty && caseHistory[0].length > 1 ? caseHistory[0][1] : "N/A"}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color.fromRGBO(117, 117, 117, 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
,

                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Petitioner: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color.fromRGBO(0, 74, 173, 1), // Blue color for "Petitioner:"
                            fontWeight: FontWeight.bold, // Optional: make it bold
                          ),
                        ),
                        TextSpan(
                          text: petitioner,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color.fromRGBO(117, 117, 117, 1), // Grey color for petitioner's name
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Respondent: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color.fromRGBO(0, 74, 173, 1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: respondent,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color.fromRGBO(117, 117, 117, 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),


                  // Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          final String id = caseItem['userId'][0]['userId'];
                          final String cnrNumber = caseItem['cnrNumber'];

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddDocsdisposed(
                                id: id,
                                cnrNumber: cnrNumber,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:Color.fromRGBO(0, 74, 173, 1),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add docs'),
                      ),

                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewDetail(
                              cnrNumber: caseItem["cnrNumber"],
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,

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
