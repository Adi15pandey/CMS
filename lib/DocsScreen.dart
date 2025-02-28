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
  String? token;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(() {
      _filterByCnrNumber(_searchController.text);
    });
  }

  Future<void> _initializeData() async {
    await _fetchToken();
    if (token != null && token!.isNotEmpty) {
      _fetchDocsData(1, 10);
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
    if (savedToken != null && savedToken.isNotEmpty) {
      setState(() {
        token = savedToken;
      });
    }
  }

  Future<void> _fetchDocsData(int page, int limit) async {
    var headers = {'token': '$token'};
    var request = http.Request(
      'GET',
      Uri.parse('${GlobalService.baseUrl}/api/document/get-document?currentPage=$page&pageLimit=$limit'),
    );
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      setState(() {
        _docsData = json.decode(responseBody)['data'] ?? [];
        _filteredDocsData = List.from(_docsData);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterByCnrNumber(String searchTerm) {
    setState(() {
      _filteredDocsData = _docsData
          .where((doc) => doc['cnrNumber'].toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
          backgroundColor: Color.fromRGBO(4, 163, 175, 1),foregroundColor:Colors.white,
        centerTitle: true,iconTheme: const IconThemeData(
          color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      prefixIcon: Icon(Icons.search),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(4, 163, 175, 1), // Blue background
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(
                    'Add Docs',
                    style: TextStyle(color: Colors.white), // White text
                  ),
                ),

              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _filteredDocsData.isEmpty
                  ? Center(child: Text('No documents available'))
                  : ListView.builder(
                itemCount: _filteredDocsData.length,
                itemBuilder: (context, index) {
                  var doc = _filteredDocsData[index];
                  String combinedRespondent = "${doc['respondent']} vs ${doc['petitioner']}";

                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Color.fromRGBO(189, 217, 255, 1), // Light blue border color
                        width: 2, // Border width
                      ),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CNR Number: ${doc['cnrNumber']}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color.fromRGBO(4, 163, 175, 1), // Text color
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "No. of Documents: ${doc['noOfDocument']}",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromRGBO(117, 117, 117, 1), // Gray color
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Respondent & Petitioner: $combinedRespondent",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromRGBO(117, 117, 117, 1), // Gray color
                            ),
                          ),
                          SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  if (doc['documents'].isNotEmpty) {
                                    String uploadedBy = doc['documents'][0]['uploadedBy'] ?? 'Unknown';
                                    String url = doc['documents'][0]['url'] ?? '';
                                    String userId = doc['userId'];
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditDocumentPage(
                                          cnrNumber: doc['cnrNumber'],
                                          uploadedBy: uploadedBy,
                                          url: url,
                                          userId: userId,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
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
