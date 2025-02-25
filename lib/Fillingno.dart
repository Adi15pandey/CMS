import 'dart:convert';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Fillingno extends StatefulWidget {
  final Function(BuildContext) openFilterDialog;
  final String? selectedState;
  final String? selectedStateName;
  final String? selectedDistrict;
  final String? selectedDistrictName;
  final String? selectedCourt;
  final String? selectedCourtName;
  final String? selectedEstablishment;
  final String? selectedEstablishmentName;
  const Fillingno({Key? key, required this.openFilterDialog,
    this.selectedState,
    this.selectedStateName,
    this.selectedDistrict,
    this.selectedDistrictName,
    this.selectedCourt,
    this.selectedCourtName,
    this.selectedEstablishment,
    this.selectedEstablishmentName,}) : super(key: key);

  @override
  State<Fillingno> createState() => _FillingnoState();
}

class _FillingnoState extends State<Fillingno> {
  final TextEditingController filingNoController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;
  bool  _isLoading =false;
  String?token;
  @override
  void initState() {
    super.initState();
    _initializeData();
    searchByFilingNumber();
  }

  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      searchByFilingNumber(); // Fetch cases if the token is valid
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

  Future<void> searchByFilingNumber() async {
    String filingNo = filingNoController.text.trim();
    String year = yearController.text.trim();

    if (filingNo.isEmpty || year.isEmpty) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Please enter both Filing Number and Year")),
      // );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse("${GlobalService.baseUrl}/api/caseStatus/filing-number");

    final payload = {
      "state": widget.selectedStateName?? "Delhi",
      "district": widget.selectedDistrictName ?? "Central",
      "court_complex": widget.selectedCourtName ?? "Tis Hazari Court Complex",
      "court_establishment": widget.selectedEstablishmentName ?? "District and Sessions Judge, Central, THC",
      "filing_No": filingNo,
      "year": year
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'token': '$token',
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData["success"]) {
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
    filingNoController.clear();
    yearController.clear();
    setState(() {
      searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text("Case Status: Search by Filing Number")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Filing Number", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              controller: filingNoController,
              decoration: InputDecoration(
                hintText: "Enter Filing Number",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Text("Year", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              controller: yearController,
              decoration: InputDecoration(
                hintText: "YYYY",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: searchByFilingNumber,
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
                          Text("Filing No: ${caseData["fillingNo"]}"),
                          Text("CNR Number: ${caseData["cnrNumber"]}"),
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
