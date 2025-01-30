import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewDetail extends StatefulWidget {
  final String cnrNumber; // Dynamic CNR number
   // Authentication token

  const ViewDetail({
    Key? key,
    required this.cnrNumber,

  }) : super(key: key);

  @override
  State<ViewDetail> createState() => _ViewDetailState();
}

class _ViewDetailState extends State<ViewDetail> {
  bool _isLoading = false;
  Map<String, dynamic>? caseData;

  String?token;
  @override
  void initState() {
    super.initState();
    _initializeData();

  }
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      fetchCaseDetails(); // Fetch cases if the token is valid
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:

        Text("No token found. Please log in."),
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


  Future<void> fetchCaseDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            '${GlobalService.baseUrl}/api/cnr/get-singlesubcnr/${widget.cnrNumber}'),
        headers: {
          'token': '$token',
       // Use Bearer token
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          setState(() {
            caseData = responseData['data'];
          });
        } else {
          _showMessage(responseData['message'] ?? "Failed to fetch data.");
        }
      } else {
        _showMessage("Error: ${response.statusCode}");
      }
    } catch (e) {
      _showMessage("An error occurred: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }


  final bool isLoading = false;
  final String errorMessage = "";


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Case Details",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[800],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
        child: Text(
          errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
          vertical: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CNR Number
            Text(
              'CNR Number: ${caseData?['cnrNumber'] ?? 'N/A'}',
              style: GoogleFonts.poppins(
                fontSize: MediaQuery.of(context).size.width * 0.05,
                fontWeight: FontWeight.w500,
                color: Colors.blue[900],
              ),
            ),
            const Divider(height: 20, thickness: 1),

            // Case Details Section (Table)
            buildSectionTitle('Case Details'),
            buildCaseDetails(),

            const Divider(height: 20, thickness: 1),

            // Case History Section (Table)
            buildSectionTitle('Case History'),
            buildCaseHistory(),

            const Divider(height: 20, thickness: 1),

            // Case Status Section (Table)
            buildSectionTitle('Case Status'),
            buildCaseStatus(),

            const Divider(height: 20, thickness: 1),

            // Interim Orders Section (List)
            buildSectionTitle('Interim Orders'),
            buildInterimOrders(),
          ],
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade800,
      ),
    );
  }

  // Build Case Details Table
  Widget buildCaseDetails() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: Text(
              'Case Type',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Filing Date',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Filing Number',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: [
          DataRow(
            cells: [
              DataCell(Text(caseData?['caseDetails']['Case Type'] ?? 'N/A')),
              DataCell(Text(caseData?['caseDetails']['Filing Date'] ?? 'N/A')),
              DataCell(Text(caseData?['caseDetails']['Filing Number'] ?? 'N/A')),
            ],
          ),
        ],
      ),
    );
  }

  // Build Case History Table
  Widget buildCaseHistory() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: Text(
              'Judge',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Business on Date',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Hearing Date',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Purpose of Hearing',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: caseData?['caseHistory']?.map<DataRow>((history) {
          return DataRow(
            cells: [
              DataCell(Text(history[0] ?? 'N/A')),
              DataCell(Text(history[1] ?? 'N/A')),
              DataCell(Text(history[2] ?? 'N/A')),
              DataCell(Text(history[3] ?? 'N/A')),
            ],
          );
        }).toList() ?? [],
      ),
    );
  }

  // Build Case Status Table
  Widget buildCaseStatus() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: Text(
              'Status',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Details',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: caseData?['caseStatus']?.map<DataRow>((status) {
          return DataRow(
            cells: [
              DataCell(Text(status[0] ?? 'N/A')),
              DataCell(Text(status[1] ?? 'N/A')),
            ],
          );
        }).toList() ?? [],
      ),
    );
  }

  // Build Interim Orders Section
  Widget buildInterimOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (caseData?['intrimOrders'] != null)
          ...caseData?['intrimOrders'].map<Widget>((order) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Order Date: ${order['order_date']}',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                subtitle: Text(
                  'Judge: ${order['judgeName']}',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                ),
                trailing: TextButton(
                  onPressed: () {
                    final Uri _url = Uri.parse(order['s3_url'].toString());
                    launchUrl(_url); // Launch the URL
                  },
                  child: Text(
                    'View Order',
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.blue),
                  ),
                ),
              ),
            );
          }).toList() ?? [],
      ],
    );
  }
}

  // void _launchURL(String url) async {
  //   // Use the URL Launcher package to open the link
  //   if (await canLaunch(url)) {
  //     await launch(url);
  //   } else {
  //     throw 'Could not launch $url';
  //   }
  // }

