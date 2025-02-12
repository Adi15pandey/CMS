import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Archieve extends StatefulWidget {
  const Archieve({super.key});

  @override
  State<Archieve> createState() => _ArchieveState();
}

class _ArchieveState extends State<Archieve> {
  List<dynamic> _archivedData = [];
  bool _isLoading = true;
  String?token;

  @override
  void initState() {
    super.initState();
    _initializeData();
    fetchArchivedData();
  }

  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      fetchArchivedData(); // Fetch cases if the token is valid
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

  Future<void> fetchArchivedData() async {
    final url = '${GlobalService.baseUrl}/api/cnr/get-archive-cnr';
    final headers = {
      'token': '$token',
      // 'token':
      // 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzQ0OTc1OCwiZXhwIjoxNzM3NTM2MTU4fQ.B6Xs1cBEttzE87XmTke-rn4RHALZXviDzqhlgctxPP0'
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _archivedData = data['cnrDetails'];
            _isLoading = false;
          });
        } else {
          throw Exception(data['message']);
        }
      } else {}
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void handleRestore(String id) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Restore action triggered for ID: $id'),
    ));
  }

  void handleDelete(String id) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Delete action triggered for ID: $id'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Archive Cases', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromRGBO(0, 74, 173, 1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _archivedData.length,
        itemBuilder: (context, index) {
          final item = _archivedData[index];
          final cnrNumber = item['cnrNumber'] ?? 'N/A';
          final caseStatus = item['caseStatus'] ?? [];
          final petitioner = item['petitionerAndAdvocate']
              ?.map((e) => e[0])
              .join(', ') ?? 'N/A';
          final respondent = item['respondentAndAdvocate']
              ?.map((e) => e[0])
              .join(', ') ?? 'N/A';

          String firstHearingDate = '';
          String nextHearingDate = '';
          String caseStage = '';

          if (caseStatus.isNotEmpty) {
            firstHearingDate = caseStatus[0][1] ?? 'N/A';
            nextHearingDate = caseStatus[1][1] ?? 'N/A';
            caseStage = caseStatus[2][1] ?? 'N/A';
          }

          return Card(
            margin: const EdgeInsets.all(8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Color.fromRGBO(189, 217, 255, 1),
                // Light blue border color
                width: 2, // Border width
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CNR Number: $cnrNumber',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color.fromRGBO(0, 74, 173, 1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('First Hearing Date: $firstHearingDate',
                      style: const TextStyle(fontSize: 16,
                          color: Color.fromRGBO(117, 117, 117, 1))),
                  const SizedBox(height: 8),
                  Text('Next Hearing Date: $nextHearingDate',
                      style: const TextStyle(fontSize: 16,
                          color: Color.fromRGBO(117, 117, 117, 1))),
                  const SizedBox(height: 8),
                  Text('Case Stage: $caseStage',
                      style: const TextStyle(fontSize: 16,
                          color: Color.fromRGBO(117, 117, 117, 1))),
                  const SizedBox(height: 8),
                  Text('Petitioner: $petitioner',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Respondent: $respondent',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () => handleRestore(item['_id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          // Button color
                          foregroundColor: Colors.white,
                          // Text color
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Restore',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => handleDelete(item['_id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          // Button color
                          foregroundColor: Colors.white,
                          // Text color
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}