import 'dart:convert';
import 'package:cms/Global/Globalservices.dart';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FirNumberScreen extends StatefulWidget {
  final Function(BuildContext) openFilterDialog;
  final String? selectedState;
  final String? selectedStateName;
  final String? selectedDistrict;
  final String? selectedDistrictName;
  final String? selectedCourt;
  final String? selectedCourtName;
  final String? selectedEstablishment;
  final String? selectedEstablishmentName;
  const FirNumberScreen({Key? key, required this.openFilterDialog,
    this.selectedState,
    this.selectedStateName,
    this.selectedDistrict,
    this.selectedDistrictName,
    this.selectedCourt,
    this.selectedCourtName,
    this.selectedEstablishment,
    this.selectedEstablishmentName,}) : super(key: key);

  @override
  State<FirNumberScreen> createState() => _FirNumberScreenState();
}
String?token;
String? selectedEstablishment; //


class _FirNumberScreenState extends State<FirNumberScreen> {
  final TextEditingController firNumberController = TextEditingController();
  String selectedPoliceStation = "Hauz Qazi 95";
  String selectedYear = "2022";
  String selectedCaseStatus = "Disposed";

  bool isLoading = false;
  List<dynamic> caseResults = [];
  List<Map<String, dynamic>> caseTypes = [];
  String? selectedCaseType;
  String? establishmentId;
  bool _isLoading=false;
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
      } // Fetch cases if the token is valid
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("No token found. Please log in."),
      ));
    }
  }
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
  Future<void> fetchCaseTypes(String establishmentId) async {

    final String selectedId = (GlobalServices.selectedEstablishmentId != null && GlobalServices.selectedEstablishmentId!.isNotEmpty)
        ? GlobalServices.selectedEstablishmentId.toString()
        : (GlobalServices.selectedCourtId != null && GlobalServices.selectedCourtId!.isNotEmpty)
        ? GlobalServices.selectedCourtId.toString()
        : "";


    final String apiUrl = (GlobalServices.selectedEstablishmentId == null || GlobalServices.selectedEstablishmentId!.isEmpty)
        ? "${GlobalService.baseUrl}/api/state/get-court-police-station/$selectedId"
        : "${GlobalService.baseUrl}/api/state/get-establishment-police-station/$selectedId";
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

  Future<void> searchFIR() async {
    setState(() {
      isLoading = true;
      caseResults.clear();
    });

    final String apiUrl = "${GlobalService.baseUrl}/api/caseStatus/fir-number";
    final Map<String, dynamic> payload = {
      "state": widget.selectedStateName?? "Delhi",
      "district": widget.selectedDistrictName ?? "Central",
      "court_complex": widget.selectedCourtName ?? "Tis Hazari Court Complex",
      "court_establishment": widget.selectedEstablishmentName ?? "District and Sessions Judge, Central, THC",
      "police_station": selectedPoliceStation,
      "fir_No": firNumberController.text.trim(),
      "year": selectedYear,
      "isPending": selectedCaseStatus
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'token': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTc0MDExNTY1MiwiZXhwIjoxNzQwMjAyMDUyfQ.z6lcCBzELJyhyKJykCD3-e5VdmnY3l2vW7XnX7xCIUg',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData["success"] == true) {
          setState(() {
            caseResults = responseData["data"];
          });
        } else {
          showError("No results found.");
        }
      } else {
        showError("Failed to fetch case details.");
      }
    } catch (e) {
      showError("Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

        DropdownButtonFormField<String>(
        value: caseTypes.any((element) => element["caseType"] == selectedCaseType)
          ? selectedCaseType
          : null,  // Fixes the issue by ensuring value is valid

      hint: const Text("Select Case Type"),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: caseTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type["caseType"],
          child: SizedBox(
            width: 200,
            child: Text(
              type["caseType"] ?? "",
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedCaseType = value;
        });
      },
    ),
          const SizedBox(height: 10),
            TextFormField(
              controller: firNumberController,
              decoration: const InputDecoration(labelText: "FIR Number"),
            ),
            const SizedBox(height: 10),

            // Year Input
            TextFormField(
              initialValue: selectedYear,
              decoration: const InputDecoration(labelText: "Year"),
              readOnly: true,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedCaseStatus,
              decoration: const InputDecoration(labelText: "Case Status"),
              items: ["Disposed", "Pending"].map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCaseStatus = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: searchFIR,
                    child: isLoading ? const CircularProgressIndicator() : const Text("Search"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      firNumberController.clear();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade100),
                    child: const Text("Reset"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Display Results
            if (caseResults.isNotEmpty) Expanded(child: buildResultsList()),
          ],
        ),
      ),
    );
  }

  Widget buildResultsList() {
    return ListView.builder(
      itemCount: caseResults.length,
      itemBuilder: (context, index) {
        final caseData = caseResults[index];
        return Card(
          child: ListTile(
            title: Text("FIR No: ${caseData['firNo']}"),
            subtitle: Text("Petitioner: ${caseData['petitioner']} \nRespondent: ${caseData['respondent']}"),
            trailing: Text("Case Type: ${caseData['caseType']}"),
          ),
        );
      },
    );
  }
}
