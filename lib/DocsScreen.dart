import 'dart:convert';
import 'package:cms/AddDocumentsScreen.dart';
import 'package:cms/EditDocumentPage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class DocsPage extends StatefulWidget {
  @override
  _DocsPageState createState() => _DocsPageState();
}

class _DocsPageState extends State<DocsPage> {
  List _docsData = [];
  List _filteredDocsData = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  Future<void> _fetchDocsData(int page, int limit) async {
    var headers = {
      'token': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzM1MDc4MiwiZXhwIjoxNzM3NDM3MTgyfQ.AtVUVaH1pxPufFMyn2AY24Z1NDaKAYw6j47R0kevI8c',
    };

    var request = http.Request('GET', Uri.parse('http://192.168.1.41:4001/api/document/get-document?currentPage=$page&pageLimit=$limit'));
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
  void initState() {
    super.initState();
    _fetchDocsData(1, 10); // Default page 1, limit 10
    _searchController.addListener(() {
      _filterByCnrNumber(_searchController.text);  // Filter data as the user types
    });
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
                                // Accessing the first document and fetching 'uploadedBy' and 'url' from it
                                String uploadedBy = doc['documents'][0]['uploadedBy'] ?? 'Unknown'; // Provide default value if uploadedBy is null
                                String url = doc['documents'][0]['url'] ?? '';
                                print(url);// Provide default value if url is null

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditDocumentPage(
                                      cnrNumber: doc['cnrNumber'],
                                      uploadedBy: uploadedBy, // Pass uploadedBy to the next screen
                                      url: url, // Pass the URL to the next screen
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
