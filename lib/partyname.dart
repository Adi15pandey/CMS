import 'dart:convert';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cms/case_status.dart'; // Import CaseStatus screen
class Partyname extends StatefulWidget {
  final Function(BuildContext) openFilterDialog; // ✅ Accept filter function
  final String? selectedState;
  final String? selectedStateName;
  final String? selectedDistrict;
  final String? selectedDistrictName;
  final String? selectedCourt;
  final String? selectedCourtName;
  final String? selectedEstablishment;
  final String? selectedEstablishmentName;

  const Partyname({
    Key? key,
    required this.openFilterDialog, // ✅ Required parameter
    this.selectedState,
    this.selectedStateName,
    this.selectedDistrict,
    this.selectedDistrictName,
    this.selectedCourt,
    this.selectedCourtName,
    this.selectedEstablishment,
    this.selectedEstablishmentName,
  }) : super(key: key);
  @override
  State<Partyname> createState() => _PartynameState();
}

class _PartynameState extends State<Partyname> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  String selectedStatus = "Pending";
  List<String> caseStatuses = ["Pending", "Disposed","Both"];
  List<Map<String, dynamic>> searchResults = []; // Store API results

  bool _isLoading = false; // Loading state
  @override
  void initState() {
    super.initState();
    _initializeData();
    searchCases();

  }
  String?token;

  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      searchCases();    } else {
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



  Future<void> searchCases() async {
    if (_isLoading) return; // Prevent multiple requests

    setState(() {
      _isLoading = true; // Start Loading
    });

    final String apiUrl = "${GlobalService.baseUrl}/api/caseStatus/party-name";
    // const String token = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczOTk2MTA1NCwiZXhwIjoxNzQwMDQ3NDU0fQ.yiSSUq8ec9R0zvsyAlhmAvmfzfLsiRINbZjn8IXSDpU";

    Map<String, dynamic> requestBody = {
      "state": widget.selectedStateName ?? "Delhi",
      "district": widget.selectedDistrictName ?? "Central",
      "court_complex": widget.selectedCourtName ?? "Tis Hazari Court Complex",
      "court_establishment": widget.selectedEstablishmentName ?? "District and Sessions Judge, Central, THC",
      "isPending": selectedStatus,
      "searchTerm": nameController.text.trim(),
      "year": yearController.text.trim(),
    };

    print("Request URL: $apiUrl");
    print("Request Headers: { 'token': '$token', 'Content-Type': 'application/json' }");
    print("Request Body: ${jsonEncode(requestBody)}");

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'token': '$token',
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData["success"] && responseData["data"] != null) {
          setState(() {
            searchResults = List<Map<String, dynamic>>.from(responseData["data"]);
          });
          print("Search Results: $searchResults");
        } else {
          // _showError("No results found.");
        }
      } else {
        // _showError("Error: ${response.statusCode}, Response: ${response.body}");
      }
    } catch (e) {
      // _showError("Network Error: $e");
      print("Exception caught: $e");
    } finally {
      setState(() {
        _isLoading = false; // Stop Loading
      });
    }
  }



  // void _showError(String message) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text(message), backgroundColor: Colors.red),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004AAD),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 🔹 Search Inputs
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Search by Petitioner/Respondent",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF004AAD)),
                      ),
                      const SizedBox(height: 20),

                      // Petitioner Name Field
                      const Text("Petitioner/Respondent Name", style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: "Enter full name",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Year Field
                      const Text("Year", style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: yearController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "YYYY",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Case Status Dropdown
                      const Text("Case Status", style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        items: caseStatuses.map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : searchCases, // Disable button when loading
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF004AAD),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 3,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text("Search"),
                            ),

                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                nameController.clear();
                                yearController.clear();
                                setState(() {
                                  selectedStatus = "Pending";
                                  searchResults.clear();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 2,
                              ),
                              child: const Text("Reset"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Display Search Results
              searchResults.isNotEmpty
                  ? Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Search Results",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF004AAD)),
                      ),
                      const Divider(),
                      ...searchResults.map((caseData) {
                        return ListTile(
                          title: Text(
                            caseData["petitioner"] ?? "N/A",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Respondent: ${caseData["respondent"] ?? "N/A"}"),
                              Text("CNR: ${caseData["cnrNumber"] ?? "N/A"}"),
                              Text("Case Type: ${caseData["caseType"] ?? "N/A"}"),
                              Text("Year: ${caseData["year"] ?? "N/A"}"),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          tileColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}