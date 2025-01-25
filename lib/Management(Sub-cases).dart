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
  bool isLoading = true;
  String errorMessage = "";
  String? token;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      fetchSubcases(); // Fetch subcases if the token is valid
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

  // Fetch subcases from the API
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Subcases Management"),
      ),
      body: isLoading
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
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display CNR Number
                  Text(
                    "CNR Number: ${subcase["cnrNumber"] ?? "Unknown"}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  // Display Number of Documents
                  Text(
                    "No. of Documents: ${subcase["documentCount"] ?? "N/A"}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  // Display Respondent & Petitioner
                  Text(
                    "Respondent & Petitioner: ${subcase["respondent"] ?? "No respondent"} & ${subcase["petitioner"] ?? "No petitioner"}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  // Action Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        final cnrNumber = subcase["cnrNumber"];
                        final documents = subcase["documents"] ?? [];

                        // Ensure the documents are being extracted correctly as a List<String>
                        final uploadedBy = documents.isNotEmpty
                            ? documents[0]["uploadedBy"] ?? "Unknown"
                            : "Unknown";
                        final id = subcase["_id"];

                        // Extracting document names and URLs as List<String>
                        final documentNames = List<String>.from(documents.map((document) => document["name"] ?? "Unnamed Document"));
                        final documentUrls = List<String>.from(documents.map((document) => document["url"] ?? ""));

                        if (cnrNumber != null && id != null) {
                          // Display a dialog to manage documents for the CNR
                          showDialog(
                            context: context,
                            builder: (_) => SubcaseDetails(
                              cnrNumber: cnrNumber,
                              uploadedBy: uploadedBy,
                              id: id,
                              documentUrls: documentUrls, // Passing URLs
                              documentNames: documentNames, // Passing Names
                            ),
                          );
                        } else {
                          // Handle missing data
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("CNR number or ID is missing!")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
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
