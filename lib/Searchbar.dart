import 'dart:convert';
import 'package:cms/Case_status.dart';
import 'package:cms/GlobalServiceurl.dart';
import 'package:cms/partyname.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'Global/Globalservices.dart';

class CaseSearchbar extends StatefulWidget {
  @override
  _CaseSearchbarState createState() => _CaseSearchbarState();
}

class _CaseSearchbarState extends State<CaseSearchbar> {
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> districts = [];
  List<Map<String, dynamic>> courts = [];
  List<Map<String, dynamic>> establishments = [];
  String? token;
  bool _isLoading = true;

  String? selectedState;
  String? selectedDistrict;
  String? selectedCourt;
  String? selectedEstablishment;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchToken();
    if (token != null && token!.isNotEmpty) {
      fetchStates();
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No token found. Please log in.")),
      );
    }
  }

  Future<void> _fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final savedToken = prefs.getString('auth_token');
    setState(() {
      token = savedToken;
    });
  }

  Future<void> fetchStates() async {
    final url = Uri.parse("${GlobalService.baseUrl} /api/state/get-state");
    await _fetchData(url, (data) {
      setState(() {
        states = List<Map<String, dynamic>>.from(data);
      });
    });
  }

  void onDistrictChanged(String? districtId) async {
    setState(() {
      selectedDistrict = districtId;
      selectedCourt = null;
      selectedEstablishment = null;
      courts = [];
      establishments = [];
    });

    if (districtId != null && districtId.isNotEmpty) {
      await fetchCourts(districtId);
    }
  }

  Future<void> fetchDistricts(String stateId) async {
    final url =
    Uri.parse("${GlobalService.baseUrl}/api/state/get-district/$stateId");

    try {
      final response = await http.get(
        url,
        headers: {
          'token': '$token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData["success"] == true) {
          setState(() {
            districts = List<Map<String, dynamic>>.from(responseData["data"]);
          });
        }
      } else {
        print("Failed to fetch districts: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching districts: $e");
    }
  }

  Future<void> fetchCourts(String districtId) async {
    if (districtId.isEmpty) return;

    final url = Uri.parse("${GlobalService.baseUrl}/api/state/get-court/$districtId");

    try {
      final response = await http.get(
        url,
        headers: {
          'token': '$token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData["success"] == true) {
          setState(() {
            courts = List<Map<String, dynamic>>.from(responseData["data"])
                .where((court) => court["_id"] != null && court["court"] != null)
                .toList();

            // Only update selectedCourt if it's null (prevents unnecessary triggers)
            if (selectedCourt == null && courts.isNotEmpty) {
              selectedCourt = courts.first["_id"];
              GlobalServices.selectedCourtId = selectedCourt;
            }

            print("Selected Court ID: ${GlobalServices.selectedCourtId}");
          });
        }
      } else {
        print("Failed to fetch courts: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching courts: $e");
    }
  }

  Future<void> fetchEstablishments(String courtId) async {
    if (courtId.isEmpty) return;

    final url = Uri.parse("${GlobalService.baseUrl}/api/state/get-establishment/$courtId");

    await _fetchData(url, (data) {
      setState(() {
        establishments = List<Map<String, dynamic>>.from(data);

        // Only update selectedEstablishment if it's null (prevents unnecessary triggers)
        if (selectedEstablishment == null && establishments.isNotEmpty) {
          selectedEstablishment = establishments.first["_id"];
        }

        GlobalServices.selectedEstablishmentId = selectedEstablishment;

        print("Selected Establishment ID: ${GlobalServices.selectedEstablishmentId}");
      });
    });
  }




  Future<void> _fetchData(Uri url, Function(List<dynamic>) onSuccess) async {
    try {
      final response = await http.get(
        url,
        headers: {
          'token': '$token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData["success"] == true) {
          onSuccess(responseData["data"]);
        }
      } else {
        print("Failed to fetch data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  void applyFilter() {


    String? selectedStateName = states.firstWhere(
          (state) => state["_id"] == selectedState,
      orElse: () => {"state": ""},
    )["state"];

    String? selectedDistrictName = districts.firstWhere(
          (district) => district["_id"] == selectedDistrict,
      orElse: () => {"district": ""},
    )["district"];

    String? selectedCourtName = courts.firstWhere(
          (court) => court["_id"] == selectedCourt,
      orElse: () => {"court": ""},
    )["court"];

    String? selectedEstablishmentName = establishments.firstWhere(
          (estab) => estab["_id"] == selectedEstablishment,
      orElse: () => {"establishment": ""},
    )["establishment"];

    print("State Name: $selectedStateName");
    print("District Name: $selectedDistrictName");
    print("Court Name: $selectedCourtName");
    print("Establishment Name: $selectedEstablishmentName");

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => Partyname(
    //       selectedState: selectedState,
    //       selectedStateName: selectedStateName,
    //       selectedDistrict: selectedDistrict,
    //       selectedDistrictName: selectedDistrictName,
    //       selectedCourt: selectedCourt,
    //       selectedCourtName: selectedCourtName,
    //       selectedEstablishment: selectedEstablishment,
    //       selectedEstablishmentName: selectedEstablishmentName,
    //     ),
    //   ),
    // );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDropdown("Select State:", selectedState, states.map((state) {
                return DropdownMenuItem<String>(
                  value: state["_id"],
                  child: Text(state["state"]),
                );
              }).toList(), (value) {
                setState(() {
                  selectedState = value;
                });
                fetchDistricts(value!);
              }),

              SizedBox(height: 16),
              buildDropdown(
                "Select District:",
                selectedDistrict,
                districts.map((district) {
                  return DropdownMenuItem<String>(
                    value: district["_id"],
                    child: Text(district["district"] ?? ""),
                  );
                }).toList(),
                onDistrictChanged,
              ),

              SizedBox(height: 16),
              buildDropdown(
                "Select Court:",
                selectedCourt,
                courts.map((court) {
                  return DropdownMenuItem<String>(
                    value: court["_id"] ?? "",
                    child: Text(court["court"] ?? ""),
                  );
                }).toList(),
                    (value) {
                  if (value != null && value.isNotEmpty) {
                    setState(() {
                      selectedCourt = value;
                    });
                    fetchEstablishments(value);
                  }
                },
              ),

              SizedBox(height: 16),
              buildDropdown(
                "Select Establishment:",
                selectedEstablishment,
                establishments.map((estab) {
                  return DropdownMenuItem<String>(
                    value: estab["_id"] ?? "",
                    child: Text(estab["establishment"] ?? ""),
                  );
                }).toList(),
                    (value) {
                  if (value != null && value.isNotEmpty) {
                    setState(() {
                      selectedEstablishment = value;
                    });
                  }
                },
              ),

              SizedBox(height: 20),
              Center(
                child:ElevatedButton(
                  onPressed: () {
                    applyFilter(); // Call the filter function
                    Navigator.pop(context); // Close the dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: const Text("Apply Filter"),
                ),


              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDropdown(String label, String? value,
      List<DropdownMenuItem<String>> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: value,
          decoration: _inputDecoration(),
          items: items,
          onChanged: onChanged,
          isDense: true,
          isExpanded: true,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
