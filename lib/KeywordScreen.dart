import 'package:cms/CaseResearcher.dart';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class KeywordScreen extends StatefulWidget {
  @override
  _KeywordScreenState createState() => _KeywordScreenState();
}

class _KeywordScreenState extends State<KeywordScreen> {
  List<dynamic> premiumData = [];
  String _selectedOption = 'Keyword';
  String? token;
  String? _selectedLocation = 'Add new location';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchToken();
    if (token != null && token!.isNotEmpty) {
      fetchPremiumData();
      deletePremiumData("");
      fetchKeywords();
      saveLocation();
      fetchStates();
      saveState();

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
    }
  }

  Future<void> fetchPremiumData() async {
    final url = Uri.parse("${GlobalService.baseUrl}/api/premium/getall");
    final response = await http.get(
      url,
      headers: {
        'token': '$token',
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        premiumData = data["data"];
      });
    } else {
      print("Failed to load data");
    }
  }

  Future<void> deletePremiumData(String id) async {
    final url =
        Uri.parse("${GlobalService.baseUrl}/api/premium/deletelocation/$id");
    final response = await http.delete(
      url,
      headers: {
        'token': '$token',

        // "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczODczNzQ2OSwiZXhwIjoxNzM4ODIzODY5fQ.c2d2CJDq-ZAurp72GWf0gDreIjNI6O-l9w5O0bkECv8",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        premiumData.removeWhere((item) => item["_id"] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Deleted successfully")),
      );
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Failed to delete")),
      // );
    }
  }

  List<String> _keywords = [];
  String?districtCourt;
  String? _selectedState;


  Future<void> fetchKeywords() async {
    final String apiUrl = "${GlobalService.baseUrl}/api/keyword/get-keyword";

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'token': '$token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);

        setState(() {
          // Assuming the response has a "data" key containing a list of items with a "keyword" key
          _keywords =
              List<String>.from(data["data"].map((item) => item["keyword"]));
        });
      } else {
        print("Failed to load keywords: ${response.body}");
      }
    } catch (e) {
      print("Error fetching keywords: $e");
    }
  }
  List<String> states = [];

  Future<void> fetchStates() async {
    final url = '${GlobalService.baseUrl}/api/state/get-state';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
      'token': '$token',
       // Add your token here if required
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('Response Data: $data');

        if (data['data'] != null) {
          setState(() {
            _states = List<String>.from(data['data'].map((state) => state['state'])); // Assuming 'state' is the key for state names
          });
        } else {
          print('No data found in the response');
        }
      } else {
        print('Failed to load states. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred while fetching states: $e');
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _selectedKeyword;
  List<String> _states = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(4, 163, 175, 1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          DropdownButton<String>(
            value: _selectedOption,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            dropdownColor: Colors.blue,
            underline: SizedBox(),
            // Removes default underline
            style: TextStyle(color: Colors.white),
            // Ensures text color is white
            items: [
              DropdownMenuItem<String>(
                value: 'Case Overview',
                child: Row(
                  children: [
                    SizedBox(width: 8),
                    Text('Case Overview'),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'Keyword',
                child: Row(
                  children: [
                    SizedBox(width: 8),
                    Text('Keyword'),
                  ],
                ),
              ),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedOption = newValue;
                });

                if (newValue == 'Case Overview') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Caseresearcher()),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // New dropdown box for Add New Location
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white, // Background color
                    borderRadius: BorderRadius.circular(20), // Rounded shape
                    border: Border.all(
                      color:Color.fromRGBO(4, 163, 175, 1), // Border color
                      width: 2, // Border width
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: ['Add New Location','Pan India', 'District', 'State', 'Reset']
                              .contains(_selectedLocation)
                          ? _selectedLocation
                          : 'Add New Location',
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color.fromRGBO(4, 163, 175, 1),),
                      style: const TextStyle(
                          color: Color.fromRGBO(4, 163, 175, 1),
                          fontWeight: FontWeight.bold),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedLocation = newValue;
                          });
                        }
                      },
                      items: [
                        'Add New Location',
                        'Pan India',
                        'District',
                        'State',
                        'Reset'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_selectedLocation == 'Pan India') ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButtonFormField<String>(
                value: districtCourt,
                hint: Text('Type of Court'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: 'district',
                    child: Text('District Court'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    districtCourt = value;
                  });
                },
              ),
            ),

            SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: DropdownButtonFormField<String>(
                      value: _selectedKeyword,
                      hint: Text('Select a Keyword'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _keywords.map((keyword) {
                        return DropdownMenuItem<String>(
                          value: keyword,
                          child: Text(keyword),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedKeyword = value;
                        });
                      },
                    ),
                  ),

                  // Save Button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(4, 163, 175, 1),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        saveLocation();
                      },
                      child: Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_selectedLocation == 'State') ...[

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButtonFormField<String>(
                value: _selectedState,
                hint: Text('Select State'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _states.map((state) {
                  return DropdownMenuItem<String>(
                    value: state,
                    child: Text(state),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedState = value;
                    print('Selected State11111111111111111111: $_selectedState');
                  });
                },

              ),
            ),

            SizedBox(height: 10),

            // District Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButtonFormField<String>(
                value: districtCourt,
                hint: Text('Type of Court'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: 'districtCourt',
                    child: Text('District Court'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    districtCourt = value;
                    // print(district);
                  });
                },
              ),
            ),

            SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: DropdownButtonFormField<String>(
                      value: _selectedKeyword,
                      hint: Text('Select a Keyword'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _keywords.map((keyword) {
                        return DropdownMenuItem<String>(
                          value: keyword,
                          child: Text(keyword),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedKeyword = value;
                        });
                      },
                    ),
                  ),

                  // Save Button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(4, 163, 175, 1),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        saveState();
                      },
                      child: Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 10),
          //   child: TextField(
          //     controller: _keywordSearchController,
          //     decoration: InputDecoration(
          //       hintText: 'Search by Keyword',
          //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          //     ),
          //   ),
          // ),

          SizedBox(height: 10),

          Expanded(
            child: Stack(
              children: [
                premiumData.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: premiumData.length,
                        itemBuilder: (context, index) {
                          var item = premiumData[index];
                          print(item);
                          return Card(
                            margin: EdgeInsets.all(10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Color.fromRGBO(189, 217, 255, 1),
                                width: 2, // Border width
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Country:",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromRGBO(4, 163, 175, 1),
                                        ),
                                      ),
                                      Text(
                                        "${item['country']}",
                                        style: TextStyle(
                                          color: Color(0xFF757575),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "State:",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromRGBO(4, 163, 175, 1),
                                        ),
                                      ),
                                      Text(
                                        _selectedState?.isNotEmpty ?? false ? _selectedState! : 'All State',
                                        style: TextStyle(
                                          color: Color(0xFF757575),
                                        ),
                                      ),




                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "District:",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromRGBO(4, 163, 175, 1),
                                        ),
                                      ),
                                      Text(
                                        districtCourt?.isNotEmpty ?? false ? districtCourt! : 'district',
                                        style: TextStyle(
                                          color: Color(0xFF757575),
                                        ),
                                      ),

                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Keyword:",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromRGBO(4, 163, 175, 1),
                                        ),
                                      ),
                                      Text(
                                        "${item['keyword']}",
                                        style: TextStyle(
                                          color: Color(0xFF757575),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            deletePremiumData(item["_id"]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void saveLocation() async {
    final String apiUrl = '${GlobalService.baseUrl}/api/premium/createlocation';

    // Print token for debugging
    print('Token being used: $token');

    Map<String, dynamic> payload = {
      'courtType': 'districtCourt',
      'keyword': _selectedKeyword ?? '',
      'isCountryPremium': true,
    };

    print('Payload being sent: $payload'); // Debugging

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'token': '$token',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 201) {
        final responseBody = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Keyword Added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        print('Success: ${responseBody['newLocation']}');
      } else {
        print('❌ Failed to save location. Status: ${response.statusCode}, Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error occurred: $e');
    }
  }


  void saveState() async {
    final String apiUrl = '${GlobalService.baseUrl}/api/premium/createlocation';

    print('Token being used: $token');

    // Ensure state and keyword are not null
    if (_selectedState == null || _selectedKeyword == null || _selectedKeyword!.isEmpty) {
      print('❌ Error: State or keyword is missing!');
      return;
    }

    Map<String, dynamic> payload = {
      'state': _selectedState, // Adding state
      'courtType': 'districtCourt',
      'keyword': _selectedKeyword, // Adding keyword
      'isStatePremium': true, // Fixing incorrect isCountryPremium
    };

    print('🚀 Payload being sent: $payload');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'token': '$token',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      final responseBody = json.decode(response.body);
      print('🔄 Server Response: $responseBody');

      if (response.statusCode == 201 && responseBody['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Keyword Added Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        print('✅ Success: ${responseBody['newLocation']}');
      } else {
        print('❌ Failed to save location. Status: ${response.statusCode}, Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error occurred: $e');
    }
  }




}
