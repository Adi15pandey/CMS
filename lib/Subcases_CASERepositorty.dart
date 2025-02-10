import 'package:cms/(subcases)Adddocs.dart';
import 'package:cms/Deletesubcases.dart';
import 'package:cms/subcasesdetail.dart';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SubcasesCaserepository extends StatefulWidget {
  const SubcasesCaserepository({Key? key}) : super(key: key);

  @override
  State<SubcasesCaserepository> createState() => _SubcasesCaserepositoryState();
}

class _SubcasesCaserepositoryState extends State<SubcasesCaserepository> {
  List<dynamic> _cases = [];
  bool _isLoading = false;
  String?token;

  // final String _token =
      // 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzYwNjg4NiwiZXhwIjoxNzM3NjkzMjg2fQ.Xr4rBiMZBW2zPZKWgEuQIf7FZEUR1FT_51S3lHqSYAI';

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

  Future<void> fetchSubcases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '${GlobalService.baseUrl}/api/cnr/get-sub-cnr?pageNo=1&pageLimit=100000000&filterText=&nextHearing=0&petitioner=0&respondent=0',
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

  void _showMessage(String message) {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text(message)),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 74, 173, 1),
        centerTitle: true,// Blue header
        title: const Text(
          'Subcases Repository',

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
          final cnrNumber = caseItem['cnrNumber'] ?? "N/A";
          final lastHearing = caseItem['caseHistory']?.isNotEmpty ?? false
              ? caseItem['caseHistory'].last[1]
              : "N/A";
          final nextHearing = caseItem['caseHistory']?.isNotEmpty ?? false
              ? caseItem['caseHistory'].last[2]
              : "N/A";

          // final addedBy = caseItem['userId']?[0]['externalUserName'] ?? "Unknown";
          final petitioner = caseItem['petitionerAndAdvocate']?[0]?[0] ?? 'N/A';
          final respondent = caseItem['respondentAndAdvocate']?[0]?[0] ?? 'N/A';

          return Card(
            elevation: 4.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Added By and CNR (First Section)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   "Added By: $addedBy",
                      //   style: const TextStyle(
                      //     fontWeight: FontWeight.bold,
                      //   ),
                      // ),
                      const SizedBox(height: 4.0),
                      Text(
                        "CNR: $cnrNumber",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),

                  // Last Hearing and Next Hearing (Second Section)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Last Hearing: $lastHearing"),
                      const SizedBox(height: 4.0),
                      Text("Next Hearing: $nextHearing"),
                    ],
                  ),
                  const SizedBox(height: 8.0),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Petitioner: $petitioner",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        "Respondent: $respondent",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),

                  // Buttons (Fourth Section)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => subcasesDetailsScreen(cnrNumber: cnrNumber)));

                            // Handle Details
                          },
                          child: const Text("Details"),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final String id = caseItem['userId'][0]['userId'];
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddDocuments(
                                  id: id, // Replace this with the actual `id` you want to pass
                                  cnrNumber: cnrNumber, // Pass the actual `cnrNumber` here
                                ),
                              ),
                            );

                          },

                          child: const Text("Add Doc"),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: ()async {
                            final String id = caseItem['userId'][0]['userId'];
          await deleteSubcase(
          context: context,
          id: id,
          cnrNumber: cnrNumber,
          );

                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text("Delete"),
                        ),
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
