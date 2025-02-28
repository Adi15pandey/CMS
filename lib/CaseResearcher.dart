import 'package:cms/Add_cases.dart';
import 'package:cms/GlobalServiceurl.dart';
import 'package:cms/KeywordScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

 // Ensure you have a KeywordScreen for navigation

class Caseresearcher extends StatefulWidget {
  const Caseresearcher({super.key});

  @override
  State<Caseresearcher> createState() => _CaseresearcherState();
}

class _CaseresearcherState extends State<Caseresearcher> {
  List<dynamic> cases = [];
  bool isLoading = true;
  String? token;
  String cnrNumberFilter = '';
  bool _isLoading = true;
  String _selectedOption = 'Case Overview';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchToken();
    if (token != null && token!.isNotEmpty) {
      fetchData();
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

  Future<void> fetchData({String filterText = ''}) async {
    final url = Uri.parse(
        '${GlobalService.baseUrl}/api/keyword/get-new-keyword-cnr-country?pageLimit=10&currentPage=1&filterText=$filterText');

    final response = await http.get(url, headers: {'token': token ?? ''});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        cases = data['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch data')),
      );
    }
  }

  Future<void> deleteKeyword(String keywordId) async {
    final url = Uri.parse(
        '${GlobalService.baseUrl}/api/keyword/delete-keyword/$keywordId');

    final response = await http.delete(url, headers: {'token': '$token'});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
        fetchData();
      }
    }
  }

  Widget _buildCaseCard(Map<String, dynamic> caseData) {
    DateTime createdDate = DateTime.parse(caseData['createdAt']);
    String formattedDate = DateFormat('dd-MM-yyyy').format(createdDate);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color.fromRGBO(189, 217, 255, 1), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('CNR Number:', caseData['cnrNumber']),
            _buildInfoRow('Registration Date:', caseData['registrationDate']),
            _buildInfoRow('Petitioner:', caseData['petitioner']),
            _buildInfoRow('Respondent:', caseData['respondent']),
            _buildInfoRow('Added Date:', formattedDate),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserSelectionScreen(
                          Sendcnr: caseData['cnrNumber'].toString(),
                          selectedFile: null,
                          sendScreentype: 'Cnr',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  tooltip: 'Action',
                ),
                IconButton(
                  onPressed: () {
                    deleteKeyword(caseData['cnrNumber']);
                  },
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color.fromRGBO(4, 163, 175, 1),)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 16, color: Color.fromRGBO(117, 117, 117, 1)), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

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
            underline: SizedBox(), // Removes default underline
            style: TextStyle(color: Colors.white), // Ensures text color is white
            items: [
              DropdownMenuItem<String>(
                value: 'Case Overview',
                child: Row(
                  children: [
                    // Icon(Icons.folder, color: Colors.white), // Icon for Case Overview
                    SizedBox(width: 8),
                    Text('Case Overview'),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'Keyword',
                child: Row(
                  children: [
                    // Icon(Icons.vpn_key, color: Colors.white), // Icon for Keyword
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

                if (newValue == 'Keyword') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => KeywordScreen()),
                  );
                }
              }
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cases.isEmpty
          ? const Center(child: Text("No data available"))
          : ListView.builder(
        itemCount: cases.length,
        itemBuilder: (context, index) {
          return _buildCaseCard(cases[index]);
        },
      ),
    );
  }
}

