import 'dart:convert';
import 'package:cms/GlobalServiceurl.dart';
import 'package:cms/MyCouncilDetailModel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart'as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyCouncilDetails extends StatefulWidget {
  final String SendCnrNo;
  final String SendNextHearingDate;
  const MyCouncilDetails({Key? key, required this.SendCnrNo, required this.SendNextHearingDate}) : super(key: key);

  @override
  State<MyCouncilDetails> createState() => _MyCouncilDetailsState();
}

class _MyCouncilDetailsState extends State<MyCouncilDetails> {
  late Future<List<CaseDetails>> futureCaseDetails;
  String?token;
  bool _isLoading= true;

  @override
  void initState() {
    super.initState();
    _initializeData();


  }
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      fetchCases(); // Fetch cases if the token is valid
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


  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Case Repository', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromRGBO(4, 163, 175, 1),iconTheme: const IconThemeData(
          color: Colors.white),
        centerTitle: true,
      ),
      body: FutureBuilder<CaseResponse>(
        future: fetchCases(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final caseData = snapshot.data!.data;

            // Extract specific case status information
            String firstHearingDate = '';
            String courtNoAndJudge = '';
            String caseStatus = '';
            for (var item in caseData.caseStatus ?? []) {
              if (item.isNotEmpty) {
                switch (item[0]) {
                  case 'First Hearing Date':
                    firstHearingDate = item[1];
                    break;
                  case 'Court Number and Judge':
                    courtNoAndJudge = item[1];
                    break;
                  case 'Case Status':
                    caseStatus = item[1];
                    break;
                }
              }
            }

            return SingleChildScrollView( // Wrap the whole body with SingleChildScrollView
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Case Details Card
                Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Container(
                          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 19.0),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(4, 163, 175, 1), // Background color
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Center(
                            child: Text(
                              'Case Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // White text for contrast
                              ),
                            ),
                          ),
                        ),
                        Divider(),
                        const SizedBox(height: 16),

                        // Case Type
                        DetailRow(label: 'Case Type', value: caseData.caseDetails.caseType),

                        // Registration Date
                        DetailRow(label: 'Registration Date', value: caseData.caseDetails.registrationDate),

                        // Filing Number
                        DetailRow(label: 'Filing No.', value: caseData.caseDetails.filingNumber),

                        // First Hearing Date
                        DetailRow(label: 'First Hearing Date', value: firstHearingDate),

                        // Filing Date
                        DetailRow(label: 'Filing Date', value:caseStatus),

                          // CNR No
                          DetailRow(label: 'CNR No', value: caseData.caseDetails.cnrNumber),

                          // Next Hearing Date (Example placeholder)
                          DetailRow(label: 'Next Hearing Date', value: widget.SendNextHearingDate),
                        ],
                      ),
                    ),
                ),
                ),

                    Divider(thickness: 3,),
                    SizedBox(height: 3,),
                    // Respondent's Card
                    Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey, width: 1), // Add border
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Respondent's Heading
                            Center(
                              child: Text(
                                'Respondent',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(4, 163, 175, 1),
                                ),
                              ),
                            ),
                            Divider(),
                            const SizedBox(height: 16),

                            // Table for Respondent's and Advocate's data
                            if (caseData.respondentAndAdvocate != null &&
                                caseData.respondentAndAdvocate!.isNotEmpty)
                              Column(
                                children: [
                                  // Heading Row
                                  Row(
                                    children: const [
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          'Party Type',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Name',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Data Rows with Divider
                                  for (var item in caseData.respondentAndAdvocate!.asMap().entries)
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                'Respondent', // Hardcoded as Party Type
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                item.value.isNotEmpty ? item.value[0] : 'Name not available',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (item.key != caseData.respondentAndAdvocate!.length - 1)
                                          Divider(color: Colors.grey), // Add divider between rows
                                      ],
                                    ),
                                ],
                              )
                            else
                              Text(
                                'No data available.',
                                style: TextStyle(fontSize: 16, color: Colors.red),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10,),
                    // Petitioner's Card
                    Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey, width: 1), // Add border
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Petitioner's Heading
                            Center(
                              child: Text(
                                'Petitioner',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(4, 163, 175, 1),
                                ),
                              ),
                            ),
                            Divider(),
                            const SizedBox(height: 16),

                            // Table for Petitioner's and Advocate's data
                            if (caseData.petitionerAndAdvocate != null &&
                                caseData.petitionerAndAdvocate!.isNotEmpty)
                              Column(
                                children: [
                                  // Heading Row
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          'Party Type',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Name',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Data Rows with Divider
                                  for (var item in caseData.petitionerAndAdvocate!.asMap().entries)
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                'Petitioner',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                item.value.isNotEmpty ? item.value[0] : 'Name not available', // Advocate name
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (item.key != caseData.petitionerAndAdvocate!.length - 1)
                                          Divider(color: Colors.grey), // Add divider between rows
                                      ],
                                    ),
                                ],
                              )
                            else
                              Text(
                                'No data available.',
                                style: TextStyle(fontSize: 16, color: Colors.red),
                              ),
                          ],
                        ),
                      ),
                    ),


                    const SizedBox(height: 16),
                    Text(
                      'Case History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(4, 163, 175, 1),
                      ),
                    ),
                    SizedBox(height: 10,),
                    // Case History Table
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,

                      child: Container(
                        //width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey, width: 1), // Add border
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(),
                              //     const SizedBox(height: 16),

                              // DataTable for Case History
                              DataTable(
                                columns: [
                                  DataColumn(label: Text('Judge')),
                                  DataColumn(label: Text('Business on Date')),
                                  DataColumn(label: Text('Hearing Date')),
                                  DataColumn(label: Text('Purpose of Hearing')),
                                ],
                                rows: caseData.caseHistory!.map<DataRow>((history) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(history[0])),
                                      DataCell(Text(history[1])),
                                      DataCell(Text(history[2] ?? 'N/A')), // Handle null value
                                      DataCell(Text(history[3])),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Interim Orders section
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Heading for the entire section
                              Center(
                                child: Text(
                                  'Interim Orders',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromRGBO(4, 163, 175, 1),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Table for displaying all orders
                              Table(
                                border: TableBorder.all(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                                columnWidths: {
                                  0: FlexColumnWidth(2),
                                  1: FlexColumnWidth(3),
                                },
                                children: [
                                  // Table Header
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          'Order Date',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          'Link',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Table Data Rows for all orders
                                  for (var order in caseData.intrimOrders!)
                                    TableRow(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(order.orderDate),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: TextButton(
                                            onPressed: () {
                                              final Uri _url = Uri.parse(order.s3Url.toString());
                                              launchUrl(_url);
                                            },
                                            child: Text(
                                              'View',
                                              style: TextStyle(
                                                color: Color.fromRGBO(4, 163, 175, 1),
                                                fontSize: 16,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: Text('No data available.'));
          }
        },
      ),
    );


  }

  String _extractPetitionerOrRespondent(List<List<String>>? data) {
    if (data != null && data.isNotEmpty) {
      return data[0][0];
    }
    return 'Not Available';
  }
  Future<CaseResponse> fetchCases() async {
    String apiUrl = "${GlobalService.baseUrl}/api/cnr/get-singlecnr/${widget.SendCnrNo}";
    // const String token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3NjU2OTNhZmU0ZTAzNmFkNDdjNWUzZCIsImlhdCI6MTczNDkzMDk0MywiZXhwIjoxNzM1MDE3MzQzfQ.3VkdiTezQb2ks65okPNHJMeT-5gGCbZssi4JxB7Hte4';

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'token': '$token',


        //  'token' :
       // 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzYwNjg4NiwiZXhwIjoxNzM3NjkzMjg2fQ.Xr4rBiMZBW2zPZKWgEuQIf7FZEUR1FT_51S3lHqSYAI',
        // 'Authorization': AppConstants.token,//'Bearer $token', // Add the token here
        'Content-Type': 'application/json',
      },
    );
    // print(AppConstants.token);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return CaseResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to load cases");
    }
  }

  Future<void> openPDFInBrowser(String url) async {
    if (url.isNotEmpty) {
      // Check if the URL can be launched
      if (await canLaunch(url)) {
        await launch(url); // Open the PDF in the default browser
      } else {
        print('Could not open PDF. Invalid URL.');
      }
    } else {
      print('No PDF available to open.');
    }
  }
}
class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label on the left
          Expanded(
            flex: 2, // You can adjust the flex value based on how much space you want the label to occupy
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color.fromRGBO(4, 163, 175, 1),
              ),
            ),
          ),

          // Value on the right
          Expanded(
            flex: 3, // Adjust flex value to control the width of the value column
            child: Text(
              value,
              textAlign: TextAlign.end, // Align text to the right
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

