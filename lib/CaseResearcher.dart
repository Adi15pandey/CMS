import 'package:cms/Add_cases.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// New screen for Keyword
class KeywordScreen extends StatelessWidget {
  const KeywordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keyword Details'),
        backgroundColor: Colors.blueAccent,
      ),
      body: const Center(child: Text('Keyword details will be shown here')),
    );
  }
}

class Caseresearcher extends StatefulWidget {
  const Caseresearcher({super.key});

  @override
  State<Caseresearcher> createState() => _CaseresearcherState();
}

class _CaseresearcherState extends State<Caseresearcher> {
  List<dynamic> cases = [];
  bool isLoading = true;
  String? token;
      // "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzc4MTA5NCwiZXhwIjoxNzM3ODY3NDk0fQ.bbjGwrw-IuQtb8F3AHCTB-lcwGOvhMUy9hdKBpKaqpA"; // Use your actual token here
  String cnrNumberFilter = '';
 bool _isLoading= true;
  @override
  void initState() {
    super.initState();
    _initializeData();


  }
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      fetchData();
      deleteKeyword("");// Fetch cases if the token is valid
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



  // Function to fetch data from the API
  Future<void> fetchData({
    String filterText = '',
  }) async {
    final url = Uri.parse(
        'http://192.168.0.111:4001/api/keyword/get-new-keyword-cnr-country'
            '?pageLimit=10&currentPage=1&filterText=$filterText'
    );

    final response = await http.get(url, headers: {
      'token': token ?? '',
    });

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
        'http://192.168.0.111:4001/api/keyword/delete-keyword/$keywordId');

    final response = await http.delete(
      url,
      headers: {
        'token': token ?? '',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
        // Refresh data after deletion
        fetchData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete keyword')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error occurred while deleting keyword')),
      );
    }
  }

  // Build Case Card
  Widget _buildCaseCard(Map<String, dynamic> caseData) {
    DateTime createdDate = DateTime.parse(caseData['createdAt']);
    String formattedDate = DateFormat('dd-MM-yyyy').format(createdDate);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CNR Number: ${caseData['cnrNumber']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Registration Date: ${caseData['registrationDate']}'),
            const SizedBox(height: 8),
            Text('Petitioner: ${caseData['petitioner']}'),
            Text('Respondent: ${caseData['respondent']}'),
            const SizedBox(height: 8),
            Text('Added Date: $formattedDate'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>  UserSelectionScreen(Sendcnr :caseData['cnrNumber'].toString(),
                          selectedFile: null,
                          sendScreentype: 'Cnr',),
                      ),
                    );
                    print('Action button clicked for CNR: ${caseData['cnrNumber']}');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Search'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // Search Bar for CNR Number
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by CNR Number',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  cnrNumberFilter = value;
                });
                fetchData(filterText: cnrNumberFilter); // Trigger search by CNR number
              },
            ),
          ),
          const Divider(thickness: 1, height: 1),
          // Case search list view
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : cases.isEmpty
                ? const Center(child: Text("No data available"))
                : ListView.builder(
              itemCount: cases.length,
              itemBuilder: (context, index) {
                final caseData = cases[index];
                return _buildCaseCard(caseData);
              },
            ),
          ),
        ],
      ),
    );
  }
}
