import 'package:cms/GlobalServiceurl.dart';
import 'package:cms/SubcaseDetail.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SubcasesManagement extends StatefulWidget {
  const SubcasesManagement({super.key});

  @override
  State<SubcasesManagement> createState() => _SubcasesManagementState();
}

class _SubcasesManagementState extends State<SubcasesManagement> {
  final String baseUrl = "${GlobalService.baseUrl}/api/document/get-sub-document";
  List<dynamic> subcases = [];
  List<dynamic> filteredSubcases = [];
  bool isLoading = true;
  String errorMessage = "";
  String? token;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchToken();
    if (token != null && token!.isNotEmpty) {
      fetchSubcases();
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
      isLoading = true;
    });

    var headers = {'token': '$token'};
    var uri = Uri.parse('$baseUrl?currentPage=1&pageLimit=1000000000000&searchCNR=');

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data["success"] == true) {
          setState(() {
            subcases = data["data"] ?? [];
            filteredSubcases = subcases;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data["message"] ?? "Failed to fetch data.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Error: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "An error occurred: $e";
        isLoading = false;
      });
    }
  }
  void _filterSubcases(String query) {
    setState(() {
      filteredSubcases = subcases.where((subcase) {
        final cnrNumber = subcase["cnrNumber"]?.toString().toLowerCase() ?? "";
        return cnrNumber.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(4, 163, 175, 1), // Blue header
        title: const Text(
           'Subcases Management',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
            color: Colors.white), // Back button color
      ),
      body:
      isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : subcases.isEmpty
          ? const Center(child: Text("No subcases found."))
          : ListView.builder(
        itemCount: subcases.length,
        itemBuilder: (context, index) {
          final subcase = subcases[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Color.fromRGBO(189, 217, 255, 1),
                width: 2, // Border width
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "CNR Number: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(4, 163, 175, 1),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "${subcase["cnrNumber"] ?? "Unknown"}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(117, 117, 117, 1), // Value color
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Display Number of Documents
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "No. of Documents: ",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(4, 163, 175, 1),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "${subcase['noOfDocument'] ?? 'N/A'}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color.fromRGBO(117, 117, 117, 1),
                          ),
                          overflow: TextOverflow.ellipsis,
                        )

                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Display Respondent & Petitioner
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Respondent & Petitioner: ",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color:Color.fromRGBO(4, 163, 175, 1),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "${subcase["respondent"] ?? "No respondent"} vs ${subcase["petitioner"] ?? "No petitioner"}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color.fromRGBO(117, 117, 117, 1),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Action Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        final cnrNumber = subcase["cnrNumber"];
                        final documents = subcase["documents"] ?? [];

                        // Extract uploader's name
                        final uploadedBy = documents.isNotEmpty
                            ? documents[0]["uploadedBy"] ?? "Unknown"
                            : "Unknown";
                        final id = subcase["_id"];

                        // Extract document names and URLs
                        final documentNames = List<String>.from(
                            documents.map((document) => document["name"] ?? "Unnamed Document"));
                        final documentUrls = List<String>.from(
                            documents.map((document) => document["url"] ?? ""));

                        if (cnrNumber != null && id != null) {
                          // Show document details dialog
                          showDialog(
                            context: context,
                            builder: (_) => SubcaseDetails(
                              cnrNumber: cnrNumber,
                              uploadedBy: uploadedBy,
                              id: id,
                              documentUrls: documentUrls,
                              documentNames: documentNames,
                            ),
                          );
                        } else {
                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("CNR number or ID is missing!")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:Color.fromRGBO(4, 163, 175, 1),
                        foregroundColor: Colors.white
                      ),
                      child: const Text("Action"),
                    ),
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
