
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
  String?token;
  bool _isLoading=true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchToken();
    if (token != null && token!.isNotEmpty) {
      fetchPremiumData();
      deletePremiumData( "");
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
    final url = Uri.parse("${GlobalService.baseUrl}/api/premium/deletelocation/$id");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(0, 74, 173, 1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          DropdownButton<String>(
            value: _selectedOption,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            dropdownColor: Colors.blue,
            underline: SizedBox(), // Removes default underline
            style: TextStyle(color: Colors.white), // Ensures text color is white
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
      body: Stack(
        children: [
          premiumData.isEmpty
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
            itemCount: premiumData.length,
            itemBuilder: (context, index) {
              var item = premiumData[index];
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Country:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF004AAD),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "State:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF004AAD),
                            ),
                          ),
                          Text(
                            item['state'].isNotEmpty ? item['state'] : 'All State',
                            style: TextStyle(
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "District:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF004AAD),
                            ),
                          ),
                          Text(
                            item['district'].isNotEmpty ? item['district'] : 'All District',
                            style: TextStyle(
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Keyword:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF004AAD),
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
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deletePremiumData(item["_id"]),
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
    );
  }
}
