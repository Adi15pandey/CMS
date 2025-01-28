import 'dart:convert';
import 'package:cms/AddDocumentsScreen.dart';
import 'package:cms/EditDocumentPage.dart';
import 'package:cms/GlobalServiceurl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DocsPage extends StatefulWidget {
  @override
  _DocsPageState createState() => _DocsPageState();
}

class _DocsPageState extends State<DocsPage> {
  List _docsData = [];
  List _filteredDocsData = [];
  bool _isLoading = true;
  String?token;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();

    _fetchDocsData(1, 1000); // Default page 1, limit 10
    _searchController.addListener(() {
      _filterByCnrNumber(_searchController.text);  // Filter data as the user types
    });
  }

  // Initialize data by fetching the token and cases
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      _fetchDocsData(1, 10);  // Fetch cases if the token is valid
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("No token found. Please log in."),
      ));
    }
  }

  // Fetch token from SharedPreferences
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


  Future<void> _fetchDocsData(int page, int limit) async {
    var headers = {
      'token': '$token',
    };

    var request = http.Request('GET', Uri.parse('${GlobalService.baseUrl}/api/document/get-document?currentPage=$page&pageLimit=$limit'));
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      print("Response Body: $responseBody"); // Log response to check the data

      setState(() {
        _docsData = json.decode(responseBody)['data'] ?? [];
        _filteredDocsData = List.from(_docsData);  // Copy data to filtered list
        _isLoading = false;
      });
    } else {
      print('Failed to load documents: ${response.reasonPhrase}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filter the documents based on CNR number
  void _filterByCnrNumber(String searchTerm) {
    setState(() {
      _filteredDocsData = _docsData
          .where((doc) => doc['cnrNumber'].toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
    });
  }


  void _addDocument() {
    print("Add Document button clicked");

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search by CNR Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddDocumentsScreen()),
                      );
                    },
                    child: Text('Add Docs'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),

                ],
              ),
              SizedBox(height: 20),

              // If still loading, show loader, else show data or empty state message
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _filteredDocsData.isEmpty
                  ? Center(child: Text('No documents available'))
                  : SingleChildScrollView(  // Horizontal scroll added here
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const <DataColumn>[
                    DataColumn(label: Text('CNR Number')),
                    DataColumn(label: Text('No. of Documents')),
                    DataColumn(label: Text('Respondent & Petitioner')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _filteredDocsData.map<DataRow>((doc) {
                    String combinedRespondent = "${doc['respondent']} vs ${doc['petitioner']}";
                    return DataRow(cells: [
                      DataCell(Text(doc['cnrNumber'])),
                      DataCell(Text(doc['noOfDocument'].toString())),
                      DataCell(Text(combinedRespondent)),
                      DataCell(
                        Row(
                          children: [
                            // Inside your previous screen where you navigate to the EditDocumentPage
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                // Accessing the first document in the list and fetching 'uploadedBy' and 'url' from it
                                String uploadedBy = doc['documents'][0]['uploadedBy'] ?? 'Unknown'; // Provide default value if uploadedBy is null
                                String url = doc['documents'][0]['url'] ?? ''; // Provide default value if url is null
                                String userId = doc['userId']; // Fetching the userId from the document

                                print(url); // Print URL to check

                                // Navigating to the next screen and passing all necessary data
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditDocumentPage(
                                      cnrNumber: doc['cnrNumber'],
                                      uploadedBy: uploadedBy, // Pass uploadedBy to the next screen
                                      url: url, // Pass the URL to the next screen
                                      userId: userId, // Pass userId to the next screen
                                    ),
                                  ),
                                );
                              },

                            )




                          ],
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
