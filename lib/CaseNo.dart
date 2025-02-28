import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'dart:convert'; // For jsonDecode
import 'package:http/http.dart' as http;

import 'Global/Globalservices.dart';
import 'package:shared_preferences/shared_preferences.dart';// For API calls


class Caseno extends StatefulWidget {
  final Function(BuildContext) openFilterDialog;
  final String? selectedState;
  final String? selectedStateName;
  final String? selectedDistrict;
  final String? selectedDistrictName;
  final String? selectedCourt;
  final String? selectedCourtName;
  final String? selectedEstablishment;
  final String? selectedEstablishmentName;

  const Caseno({Key? key, required this.openFilterDialog,
    this.selectedState,
    this.selectedStateName,
    this.selectedDistrict,
    this.selectedDistrictName,
    this.selectedCourt,
    this.selectedCourtName,
    this.selectedEstablishment,
    this.selectedEstablishmentName,}) : super(key: key);

  @override
  State<Caseno> createState() => _CasenoState();
}


class _CasenoState extends State<Caseno> {
  String?token;
  bool  _isLoading=true;
  String? selectedCaseType;


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

  bool isLoading = false;

  Future<void> fetchCaseData() async {
    setState(() {
      isLoading = true;
    });

    final String apiUrl = "${GlobalService.baseUrl}/api/caseStatus/case-number";
    final Map<String, dynamic> payload = {
      "state": widget.selectedStateName?? "Delhi",
      "district": widget.selectedDistrictName ?? "Central",
      "court_complex": widget.selectedCourtName ?? "Tis Hazari Court Complex",
      "court_establishment": widget.selectedEstablishmentName ?? "District and Sessions Judge, Central, THC",
      "case_type": selectedCaseType ?? "",
      "case_No": caseNumberController.text,
      "year": yearController.text
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'token': '$token',          'Content-Type': 'application/json',
        },

        body: jsonEncode(payload),
      );
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      print("Sending API Request to: $apiUrl");
      print("Request Payload: ${jsonEncode(payload)}");

      if (response.statusCode == 200) {

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData["success"] == true && responseData["data"] != null) {
          print("Response Status Code: ${response.statusCode}");
          print("Response Body: ${response.body}");

          List<dynamic> caseResults = responseData["data"];
          showCaseResults(caseResults);


        } else {
          showError("No cases found.");
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

  void showCaseResults(List<dynamic> caseResults) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: caseResults.map((caseData) {
              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text("Petitioner: ${caseData['petitioner']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Respondent: ${caseData['respondent']}"),
                      Text("CNR Number: ${caseData['cnrNumber']}"),
                      Text("Register No: ${caseData['registerNo']}"),
                      Text("Case Type: ${caseData['caseType']}"),
                      Text("Year: ${caseData['year']}"),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text("Case Type"),
            const SizedBox(height: 6),
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
                      type["caseType"] ?? "Unknown",
                      overflow: TextOverflow.ellipsis, // Prevents overflow
                      maxLines: 1, // Ensures single-line text
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


            // DropdownButtonFormField<String>(
            //   value: selectedCaseType,
            //   hint: const Text("Select Case Type"),
            //   decoration: InputDecoration(
            //     border: OutlineInputBorder(),
            //     contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            //   ),
            //   items: caseTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
            //   onChanged: (value) {
            //     setState(() {
            //       selectedCaseType = value;
            //     });
            //   },
            // ),

            const SizedBox(height: 16),

            // Case Number Field
            const Text("Case Number *"),
            const SizedBox(height: 6),
            TextField(
              controller: caseNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter Case Number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Year Field
            const Text("Year *"),
            const SizedBox(height: 6),
            TextField(
              controller: yearController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "YYYY",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : fetchCaseData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(4, 163, 175, 1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : const Text("Search"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Clear Fields
                      setState(() {
                        selectedCaseType = null;
                        caseNumberController.clear();
                        yearController.clear();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Reset"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


}
