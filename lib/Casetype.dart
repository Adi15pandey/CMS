import 'dart:convert';
import 'package:cms/Global/Globalservices.dart';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CaseTypeSearch extends StatefulWidget {
  final Function(BuildContext) openFilterDialog;
  final String? selectedState;
  final String? selectedStateName;
  final String? selectedDistrict;
  final String? selectedDistrictName;
  final String? selectedCourt;
  final String? selectedCourtName;
  final String? selectedEstablishment;
  final String? selectedEstablishmentName;

  const CaseTypeSearch({Key? key,
    required this.openFilterDialog,
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
  State<CaseTypeSearch> createState() => _CaseTypeSearchState();
}

class _CaseTypeSearchState extends State<CaseTypeSearch> {
  String? selectedCaseType;
  String selectedYear = "2024";
  String selectedStatus = "Disposed";
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;
  String?token;
  bool  _isLoading=false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    fetchCaseTypes(establishmentId.toString());



    if (GlobalServices.selectedEstablishmentId != null) {
      fetchCaseTypes(GlobalServices.selectedEstablishmentId!);
    }
  }
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      fetchCaseTypes(establishmentId.toString());



      if (GlobalServices.selectedEstablishmentId != null) {
        fetchCaseTypes(GlobalServices.selectedEstablishmentId!);

      }
      searchByCaseType();// Fetch cases if the token is valid
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

  final TextEditingController caseNumberController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  List<Map<String, dynamic>> caseTypes = [];

  String? selectedEstablishment; //
  String? establishmentId;


  void onEstablishmentChanged(String? establishmentId) async {
    setState(() {

      selectedEstablishment = establishmentId;
      selectedCaseType = null;
      caseTypes = [];
    });

    if (establishmentId != null && establishmentId.isNotEmpty) {
      await fetchCaseTypes(establishmentId);
    }
  }


  Future<void> fetchCaseTypes(String establishmentId) async {

    final String selectedId = (GlobalServices.selectedEstablishmentId != null && GlobalServices.selectedEstablishmentId!.isNotEmpty)
        ? GlobalServices.selectedEstablishmentId.toString()
        : (GlobalServices.selectedCourtId != null && GlobalServices.selectedCourtId!.isNotEmpty)
        ? GlobalServices.selectedCourtId.toString()
        : "";


    final String apiUrl = (GlobalServices.selectedEstablishmentId == null || GlobalServices.selectedEstablishmentId!.isEmpty)
        ? "${GlobalService.baseUrl}/api/state/get-court-case-type/$selectedId"
        : "${GlobalService.baseUrl}/api/state/get-establishment-case-type/$selectedId";
    final url = Uri.parse(apiUrl);
    print("7y7b");
    print(selectedId);
    print("8rghurguigbfiugufgiuf");
    try {
      final response = await http.get(
        url,
        headers: {
          'token': '$token',          'Content-Type': 'application/json',
        },
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData["data"] != null) {
          List<Map<String, dynamic>> fetchedCaseTypes = List<Map<String, dynamic>>.from(responseData["data"]);

          setState(() {
            caseTypes = fetchedCaseTypes;
            selectedCaseType = null;
          });

          // ✅ Print formatted case type data
          print("Fetched Case Types:");
          for (var caseType in caseTypes) {
            print("ID: ${caseType['id']}, Name: ${caseType['name']}");
          }
        } else {
          print("No case types found.");
        }
      } else {
        print("Failed to fetch case types: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching case types: $e");
    }
  }

  Future<void> searchByCaseType() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse("${GlobalService.baseUrl}/api/caseStatus/case-type");
    final payload = {
      "state": widget.selectedStateName ?? "Delhi",
      "district": widget.selectedDistrictName ?? "Central",
      "court_complex": widget.selectedCourtName ?? "Rouse Avenue Court Complex",
      "court_establishment": widget.selectedEstablishmentName ?? "",
      "case_type": selectedCaseType,
      "year": selectedYear,
      "isPending": selectedStatus,
    };

    print("Request URL: $url");
    print("Request Payload: ${jsonEncode(payload)}");

    try {
      final response = await http.post(
        url,
        headers: {
          'token': '$token',          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData["success"] == true) {
          setState(() {
            searchResults = List<Map<String, dynamic>>.from(responseData["data"]);
          });
        } else {
          searchResults = [];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData["message"])),
          );
        }
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text("Failed to fetch data. Please try again.")),
        // );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong. Please try again.")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }


  void resetFields() {
    setState(() {
      selectedCaseType = "CBI";
      selectedYear = "2024";
      selectedStatus = "Disposed";
      searchResults = [];
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Case Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: selectedCaseType,
              hint: const Text("Select Case Type"),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: caseTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type["caseType"],
                  child: SizedBox(
                    width: 200, // Set a fixed width
                    child: Text(
                      type["caseType"] ?? "",
                      overflow: TextOverflow.ellipsis, // Prevents overflow
                      maxLines: 1, // Ensures single-line text
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCaseType = value; // No need for `.toString()`
                });
              },
            ),
            SizedBox(height: 16),
            Text("Year", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              decoration: InputDecoration(
                hintText: "Enter Year",
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: selectedYear),
              keyboardType: TextInputType.number,
              onChanged: (value) => selectedYear = value,
            ),
            SizedBox(height: 16),
            Text("Case Status", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownButtonFormField(
              value: selectedStatus,
              items: ["Disposed", "Pending"].map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedStatus = value.toString();
                });
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: searchByCaseType,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Search", style: TextStyle(color: Colors.white)),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: resetFields,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlueAccent),
                  child: Text("Reset", style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: searchResults.isEmpty
                  ? Center(child: Text("No results found"))
                  : ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final caseData = searchResults[index];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text("Petitioner: ${caseData["petitioner"]}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Respondent: ${caseData["respondent"]}"),
                          Text("CNR Number: ${caseData["cnrNumber"]}"),
                          Text("Register No: ${caseData["registerNo"]}"),
                          Text("Case Type: ${caseData["caseType"]}"),
                          Text("Year: ${caseData["year"]}"),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
