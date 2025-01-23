import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For jsonDecode
import 'package:http/http.dart' as http;

class DisposedCases extends StatefulWidget {
  const DisposedCases({super.key});

  @override
  State<DisposedCases> createState() => _DisposedCasesState();
}

class _DisposedCasesState extends State<DisposedCases> {
  List<dynamic> _cases = [];
  bool _isLoading = true;
  String? token; // To store the token

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Initialize data by fetching the token and cases
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      fetchDisposedCases(); // Fetch cases if the token is valid
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

  // Fetch disposed cases from the API
  Future<void> fetchDisposedCases() async {
    try {
      final response = await http.get(
        Uri.parse(
            "${GlobalService.baseUrl}/api/cnr/get-disposed-cnr?pageNo=1&pageLimit=10&filterText=&nextHearing=0&petitioner=0&respondent=0"),
        headers: {
          'token': '$token',
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _cases = data['data'];
            _isLoading = false;
          });
        } else {
          throw Exception("Failed to load cases");
        }
      } else {
        throw Exception("Failed to connect to the server");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: ${e.toString()}"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Disposed Cases"),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cases.isEmpty
          ? const Center(child: Text("No disposed cases found"))
          : ListView.builder(
        itemCount: _cases.length,
        itemBuilder: (context, index) {
          final caseData = _cases[index];
          final caseDetails = caseData['caseDetails'];
          final caseStatus = caseData['caseStatus'];
          final petitioner = caseData['petitionerAndAdvocate'];
          final respondent = caseData['respondentAndAdvocate'];

          // Extract Last and Final Hearing Dates
          String lastHearing = "";
          String finalHearing = "";

          for (var status in caseStatus) {
            if (status[0] == "First Hearing Date") {
              lastHearing = status[1];
            }
            if (status[0] == "Decision Date") {
              finalHearing = status[1];
            }
          }

          return Card(
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CNR Number: ${caseData['cnrNumber']}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last Hearing: $lastHearing',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Final Hearing: $finalHearing',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Petitioner: ${petitioner.isNotEmpty
                        ? petitioner[0][0]
                        : 'N/A'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Respondent: ${respondent.isNotEmpty
                        ? respondent[0][0]
                        : 'N/A'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => CaseDetailsScreen(caseData: caseData)));

                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Details"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _deleteCase(index);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Delete"),
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
      _cases.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Case deleted successfully.")),
    );
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Details: ${caseData['caseDetails']}'),
            const SizedBox(height: 10),
            // Add more fields as needed
          ],
        ),
      ),
    );
  }
}
