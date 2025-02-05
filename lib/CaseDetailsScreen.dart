import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class CaseDetailsScreen extends StatefulWidget {
  final String cnrNumber;

  const CaseDetailsScreen({Key? key, required this.cnrNumber}) : super(key: key);

  @override
  State<CaseDetailsScreen> createState() => _CaseDetailsScreenState();
}

class _CaseDetailsScreenState extends State<CaseDetailsScreen> {
  bool isLoading = true;
  String errorMessage = '';
  bool _isLoading =true;
  Map<String, dynamic>? caseData;
  String?token;

  final String apiUrl = "${GlobalService.baseUrl}/api/cnr/get-singlecnr/";

  // final String token = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzY5NDIyOSwiZXhwIjoxNzM3NzgwNjI5fQ.61uspeeYspKI9Kr6VGE-sThMoOCOmbx89B1C5S4M2wE";

  @override
  void initState() {
    super.initState();
    _initializeData();


  }
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      fetchCaseDetails(widget.cnrNumber); // Fetch cases if the token is valid
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


  Future<void> fetchCaseDetails(String cnrNumber) async {
    try {
      final url = '$apiUrl$cnrNumber';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'token': '$token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          caseData = jsonResponse['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load data: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  String formatDate(String date) {
    final parsedDate = DateTime.parse(date);
    return DateFormat('MMM dd, yyyy').format(parsedDate);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Case Details",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(
            color: Colors.white),
        backgroundColor: Colors.blue[800],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
        child: Text(
          errorMessage,
          style: TextStyle(color: Colors.red, fontSize: 16),
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
                fontSize: MediaQuery.of(context).size.width * 0.05, // Dynamic font size
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
      scrollDirection: Axis.horizontal, // Enable horizontal scrolling
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
      scrollDirection: Axis.horizontal, // Enable horizontal scrolling
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
        }).toList() ??
            [],
      ),
    );
  }

  // Build Case Status Table
  Widget buildCaseStatus() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Enable horizontal scrolling
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
        }).toList() ??
            [],
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
          }).toList() ??
              [],
      ],
    );
  }
}