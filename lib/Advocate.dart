import 'dart:convert';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdvocateSearch extends StatefulWidget {
  final Function(BuildContext) openFilterDialog;
  final String? selectedState;
  final String? selectedStateName;
  final String? selectedDistrict;
  final String? selectedDistrictName;
  final String? selectedCourt;
  final String? selectedCourtName;
  final String? selectedEstablishment;
  final String? selectedEstablishmentName;
  const AdvocateSearch({Key? key, required this.openFilterDialog,
    this.selectedState,
    this.selectedStateName,
    this.selectedDistrict,
    this.selectedDistrictName,
    this.selectedCourt,
    this.selectedCourtName,
    this.selectedEstablishment,
    this.selectedEstablishmentName,}) : super(key: key);

  @override
  _AdvocateSearchState createState() => _AdvocateSearchState();
}

class _AdvocateSearchState extends State<AdvocateSearch> {
  final TextEditingController advocateController = TextEditingController();
  String caseStatus = "Pending"; // Default value
  bool isLoading = false;
  List<Map<String, dynamic>> searchResults = [];
  String? token;
  bool   _isLoading=false;
  @override
  void initState() {
    super.initState();
    _initializeData();
    searchAdvocate();

  }

  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      searchAdvocate(); // Fetch cases if the token is valid
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


  Future<void> searchAdvocate() async {
    String advocateName = advocateController.text.trim();
    if (advocateName.isEmpty) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Please enter advocate name")),
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse("${GlobalService.baseUrl}/api/caseStatus/advocate-name");

    final payload = {
      "state": widget.selectedStateName?? "Delhi",
      "district": widget.selectedDistrictName ?? "Central",
      "court_complex": widget.selectedCourtName ?? "Tis Hazari Court Complex",
      "court_establishment": widget.selectedEstablishmentName ?? "District and Sessions Judge, Central, THC",
      "adv_name": advocateName,
      "isPending": caseStatus,
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
        if (responseData["status"]) {
          setState(() => searchResults = List<Map<String, dynamic>>.from(responseData["result"]));
        } else {
          searchResults = [];
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No cases found")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to fetch data")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Something went wrong")));
    }

    setState(() => isLoading = false);
  }

  void resetFields() {
    advocateController.clear();
    setState(() {
      caseStatus = "Pending";
      searchResults = [];
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text("Advocate Search")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Advocate", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromRGBO(4, 163, 175, 1),)),
                SizedBox(height: 5),
                TextField(
                  controller: advocateController,
                  decoration: InputDecoration(
                    hintText: "Enter Advocate name",
                    border: OutlineInputBorder(),
                  ),
                ),

                SizedBox(height: 15),
                Text("Case Status", style: TextStyle(fontWeight: FontWeight.bold, color:Color.fromRGBO(4, 163, 175, 1),)),
                SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: caseStatus,
                  decoration: InputDecoration(border: OutlineInputBorder()),
                  items: ["Pending", "Disposed"].map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (value) => setState(() => caseStatus = value!),
                ),

                SizedBox(height: 20),

                // Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: searchAdvocate,
                        style: ElevatedButton.styleFrom(backgroundColor: Color.fromRGBO(4, 163, 175, 1),foregroundColor: Colors.white),
                        child: isLoading ? CircularProgressIndicator(color: Colors.white,) : Text("Search"),
                      ),
                    ),
                    SizedBox(width: 10), // Space between buttons
                    Expanded(
                      child: ElevatedButton(
                        onPressed: resetFields,
                        style: ElevatedButton.styleFrom(backgroundColor: Color.fromRGBO(4, 163, 175, 1), foregroundColor: Colors.white),
                        child: Text("Reset"),
                      ),
                    ),
                  ],
                ),
              ],
            )
,
            SizedBox(height: 20),
            Expanded(
              child: searchResults.isEmpty
                  ? Center(child: Text("No results found"))
                  : ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final caseData = searchResults[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📌 Petitioner: ${caseData["petitioner"]}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("👨‍⚖️ Respondent: ${caseData["respondent"]}", style: TextStyle(fontSize: 14)),
                          SizedBox(height: 4),
                          Text("⚖️ Advocate: ${caseData["advocate"]}", style: TextStyle(fontSize: 14)),
                          SizedBox(height: 4),
                          Text("📄 CNR Number: ${caseData["cnrNumber"]}", style: TextStyle(fontSize: 14)),
                          SizedBox(height: 4),
                          Text("📝 Register No: ${caseData["registerNo"]}", style: TextStyle(fontSize: 14)),
                          SizedBox(height: 4),
                          Text("📅 Year: ${caseData["year"]}", style: TextStyle(fontSize: 14)),
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