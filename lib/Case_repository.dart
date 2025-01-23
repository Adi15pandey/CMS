import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'GlobalServiceurl.dart';

class CnrDetailsScreen extends StatefulWidget {
  @override
  _CnrDetailsScreenState createState() => _CnrDetailsScreenState();
}

class _CnrDetailsScreenState extends State<CnrDetailsScreen> {
  bool _isLoading = false;
  List<dynamic> _cnrDetails = [];
  List<dynamic> _filteredCnrDetails = [];
  String? token;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchToken();
    fetchCnrDetails(pageNo: 1, pageLimit: 100);

    _searchController.addListener(_filterCnrDetails);
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
      _showMessage("Token not found. Please log in again.");
    }
  }

  Future<void> fetchCnrDetails({
    required int pageNo,
    required int pageLimit,
  }) async {
    if (token == null || token!.isEmpty) {
      print('Token is null or empty. Fetching again...');
      await _fetchToken();
    }

    if (token == null || token!.isEmpty) {
      _showMessage("Token not found. Please log in again.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '${GlobalService.baseUrl}/api/cnr/get-cnr?pageNo=$pageNo&pageLimit=$pageLimit',
        ),
        headers: {
          'token': '$token',
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          setState(() {
            _cnrDetails = responseData['data'];
            _filteredCnrDetails = _cnrDetails;
          });
        } else {
          _showMessage(responseData['message'] ?? "Error retrieving CNR details");
        }
      } else {
        _showMessage("Failed to load CNR details. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
      _showMessage("An error occurred. Please try again later.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterCnrDetails() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCnrDetails = _cnrDetails.where((cnr) {
        final cnrNumber = cnr['cnrNumber']?.toLowerCase() ?? '';
        return cnrNumber.contains(query);
      }).toList();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Case Repository",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by CNR Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(),
            )
                : ListView.builder(
              padding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              itemCount: _filteredCnrDetails.length,
              itemBuilder: (context, index) {
                final cnr = _filteredCnrDetails[index];
                final caseDetails = cnr['caseDetails'];
                final caseStatus = cnr['caseStatus'];
                final petitionerAndAdvocate = cnr['petitionerAndAdvocate'];
                final respondentAndAdvocate = cnr['respondentAndAdvocate'];

                return Card(
                  margin: EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CNR Number: ${cnr['cnrNumber']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Case Type: ${caseDetails['Case Type']}',
                          style: TextStyle(
                              fontSize: 16, color: Colors.black54),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Last Hearing: ${_getLastHearingDate(caseStatus)}',
                          style: TextStyle(
                              fontSize: 16, color: Colors.black54),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Next Hearing: ${_getNextHearingDate(caseStatus)}',
                          style: TextStyle(
                              fontSize: 16, color: Colors.black54),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Petitioner: ${petitionerAndAdvocate.isNotEmpty ? petitionerAndAdvocate[0][0] : 'N/A'}',
                          style: TextStyle(
                              fontSize: 16, color: Colors.black54),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Respondent: ${respondentAndAdvocate.isNotEmpty ? respondentAndAdvocate[0][0] : 'N/A'}',
                          style: TextStyle(
                              fontSize: 16, color: Colors.black54),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // Navigate to the details screen or handle details logic
                                _showCaseDetails(cnr);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text("Details"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Handle delete logic
                                _deleteCase(index);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text("Delete"),
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
    );
  }
  void _showCaseDetails(Map<String, dynamic> caseData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaseDetailsScreen(caseData: caseData),
      ),
    );
  }
  void _deleteCase(int index) {
    setState(() {
      _filteredCnrDetails.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Case deleted successfully."),
    ));
  }


  String _getLastHearingDate(List<dynamic> caseStatus) {
    final lastHearing = caseStatus.firstWhere(
            (status) => status[0] == "First Hearing Date",
        orElse: () => ["", ""]);
    return lastHearing[1] ?? 'N/A';
  }

  String _getNextHearingDate(List<dynamic> caseStatus) {
    final nextHearing = caseStatus.firstWhere(
            (status) => status[0] == "Next Hearing Date",
        orElse: () => ["", ""]);
    return nextHearing[1] ?? 'N/A';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
class CaseDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> caseData;

  const CaseDetailsScreen({Key? key, required this.caseData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Case Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CNR Number: ${caseData['cnrNumber']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Case Type: ${caseData['caseDetails']['Case Type']}'),
            SizedBox(height: 10),
            // Add other details as needed
          ],
        ),
      ),
    );
  }
}

