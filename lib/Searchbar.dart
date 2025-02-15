import 'dart:convert';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CaseSearchbar extends StatefulWidget {
  @override
  _CaseSearchbarState createState() => _CaseSearchbarState();
}

class _CaseSearchbarState extends State<CaseSearchbar> {
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> districts = [];
  List<Map<String, dynamic>> courts = [];
  List<Map<String, dynamic>> establishments = [];
  String?token;
  bool   _isLoading=true;


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
  Future<void> fetchStates() async {
    final url = Uri.parse("${GlobalService.baseUrl}/api/state/get-state");

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
            states = List<Map<String, dynamic>>.from(responseData["data"]);
          });
        }
      } else {
        print("Failed to fetch states: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching states: $e");
    }
  }
  void onStateChanged(String? stateId) {
    setState(() {
      selectedState = stateId;
      selectedDistrict = null;
      selectedCourt = null;
      selectedEstablishment = null;
      districts = states.firstWhere((state) => state["_id"] == stateId)["district"]
          .map<Map<String, dynamic>>((district) => {
        "name": district["districtName"],
        "courts": district["courts"]
      })
          .toList();
      courts = [];
      establishments = [];
    });
  }
  void onDistrictChanged(String? districtName) {
    setState(() {
      selectedDistrict = districtName;
      selectedCourt = null;
      selectedEstablishment = null;
      courts = districts
          .firstWhere((district) => district["name"] == districtName)["courts"]
          .map<Map<String, dynamic>>((court) => {
        "name": court["courtName"],
        "complexes": court["courtComplexes"]
      })
          .toList();
      establishments = [];
    });
  }
  void onCourtChanged(String? courtName) {
    setState(() {
      selectedCourt = courtName;
      selectedEstablishment = null;
      establishments = courts
          .firstWhere((court) => court["name"] == courtName)["complexes"]
          .map<Map<String, dynamic>>((complex) => {"name": complex["complexName"]})
          .toList();
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildDropdown("Select State:", selectedState, states.map((state) {
                  return DropdownMenuItem<String>(
                    value: state["_id"],
                    child: Text(state["state"]),
                  );
                }).toList(), onStateChanged),
                buildDropdown("Select District:", selectedDistrict, districts.map((district) {
                  return DropdownMenuItem<String>(
                    value: district["name"],
                    child: Text(district["name"]),
                  );
                }).toList(), onDistrictChanged),
              ],
            ),

            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                buildDropdown("Select Court:", selectedCourt, courts.map((court) {
                  return DropdownMenuItem<String>(
                    value: court["name"],
                    child: Text(court["name"]),
                  );
                }).toList(), onCourtChanged),
                if (establishments.isNotEmpty)
                  buildDropdown("Select Establishment:", selectedEstablishment, establishments.map((estab) {
                    return DropdownMenuItem<String>(
                      value: estab["name"],
                      child: Text(estab["name"]),
                    );
                  }).toList(), (value) => setState(() => selectedEstablishment = value)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget buildDropdown(String label, String? value, List<DropdownMenuItem<String>> items, Function(String?) onChanged) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Container(
            width: 160, // Adjust the width of the dropdowns for better alignment
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: _inputDecoration(),
              items: items,
              onChanged: onChanged,
              isDense: true,
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
    );
  }
}
