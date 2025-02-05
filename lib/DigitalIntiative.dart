import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class Digitalintiative extends StatefulWidget {
  const Digitalintiative({super.key});

  @override
  State<Digitalintiative> createState() => _DigitalintiativeState();
}

class _DigitalintiativeState extends State<Digitalintiative> {
  int currentPage = 1;
  int pageLimit = 1000000000000;
  List<dynamic> fileData = [];
  String?token;
  bool  isLoading=true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    fetchData();
    sendWhatsApp("");
    sendEmail("");
    delete("");

  }
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      fetchData();
      sendWhatsApp("");
      sendEmail("");
      delete("");

    } else {
      setState(() {
        isLoading = false;
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

  Future<void> fetchData() async {
    final String apiUrl = '${GlobalService.baseUrl}/api/file/filedata/';

    try {
      final response = await http.get(
        Uri.parse('$apiUrl?search=&page=$currentPage&limit=$pageLimit'),
        headers: {
          'token': '$token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          fileData = data['data'];
          // filteredData = fileData; // Initialize filtered data with all items
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Failed to load data');
    }
  }



  void showVisibilityDetails(dynamic item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisibilityDetailsScreen(item: item),
      ),
    );
  }

  Future<void> sendEmail(String id) async {
    final url = '${GlobalService.baseUrl}/api/file/interimorder/sendemail/$id';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'token': '$token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email sent successfully!')),
          );
        } else {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('Failed to send WhatsApp message')),
          // );
        }
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Error sending WhatsApp message')),
        // );
      }
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('An error occurred: $e')),
      // );
    }
  }
  // List<dynamic> fileData = []; // Replace with your data fetch logic

  Future<void> sendWhatsApp(String id) async {
    final url = '${GlobalService.baseUrl}/api/file/interimorder/sendwhatsapp/$id';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'token': '$token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('WhatsApp sent successfully!')),
          );
        } else {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('Failed to send WhatsApp message')),
          // );
        }
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Error sending WhatsApp message')),
        // );
      }
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('An error occurred: $e')),
      // );
    }
  }
  Future<void> delete(String id) async {
    // Prepare the headers with the Bearer token
    var headers = {
      'token': token ?? '',
    };

    // Prepare the DELETE request URL with the dynamic 'id'
    final url = '${GlobalService.baseUrl}/api/file/deletedatabyid/$id';

    // Create the DELETE request with the provided headers
    var request = http.Request('DELETE', Uri.parse(url));
    request.headers.addAll(headers);

    try {
      // Send the request
      http.StreamedResponse response = await request.send();

      // Check if the request was successful
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);

        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete')),
          );
        }
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Error: ${response.reasonPhrase}')),
        // );
      }
    } catch (e) {
      // Handle any errors that occur during the request
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('An error occurred: $e')),
      // );
    }
  }

  void _showConfirmationDialog(BuildContext context, String action, Function onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text("Confirm Action", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            "Are you sure you want to ${action.toLowerCase()} this file?\nThis action cannot be undone.",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Confirmation button color
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                onConfirm(); // Execute the action
              },
              child: Text("Yes, Proceed", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Digital Initiative', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromRGBO(0, 74, 173, 1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: fileData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: fileData.length,
        itemBuilder: (context, index) {
          final item = fileData[index];
          return Card(
            margin: const EdgeInsets.all(10),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Color.fromRGBO(189, 217, 255, 1),
                width: 2, // Border width
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FileName
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "FileName: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color.fromRGBO(0, 74, 173, 1), // Label color
                        ),
                      ),
                      Expanded( // To handle long text and avoid overflow
                        child: Text(
                          "${item['fileName']}",
                          style: TextStyle(
                            // fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color.fromRGBO(117, 117, 117, 1), // Value color
                          ),
                          overflow: TextOverflow.ellipsis, // Truncate overflowed text
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),

                  // Client
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Client: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color.fromRGBO(0, 74, 173, 1), // Label color
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "${item['clientName']}",
                          style: TextStyle(
                            // fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color.fromRGBO(117, 117, 117, 1), // Value color
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),

                  // Notice Type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Notice Type: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color.fromRGBO(0, 74, 173, 1), // Label color
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "${item['noticeType']}",
                          style: TextStyle(
                            // fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color.fromRGBO(117, 117, 117, 1), // Value color
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),

                  // Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Date: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color.fromRGBO(0, 74, 173, 1), // Label color
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "${item['date']}",
                          style: TextStyle(
                            // fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color.fromRGBO(117, 117, 117, 1), // Value color
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () => showVisibilityDetails(item),
                      ),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
                        tooltip: 'Send via WhatsApp',
                        onPressed: () {
                          _showConfirmationDialog(context, "send via WhatsApp", () {
                            sendWhatsApp(item['_id']);
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.email, color: Colors.orange),
                        onPressed: () {
                          _showConfirmationDialog(context, "send via Email", () {
                            sendEmail(item['_id']);
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showConfirmationDialog(context, "delete", () {
                            delete(item['_id']);
                          });
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
    );
  }

}


class VisibilityDetailsScreen extends StatelessWidget {
  final dynamic item;

  const VisibilityDetailsScreen({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final caseData = item['data'][0]; // Assuming first item from list

    Color labelColor = const Color.fromRGBO(0, 74, 173, 1); // Dark Blue
    Color valueColor = const Color.fromRGBO(117, 117, 117, 1); // Gray

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Case Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: labelColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow("CNR Number", caseData['cnrNumber'], labelColor, valueColor),
              _buildDetailRow("Petitioner Name", caseData['petitionerAndAdvocate'][0]['name'], labelColor, valueColor),
              _buildDetailRow("Petitioner Advocate", caseData['petitionerAndAdvocate'][0]['advocate'], labelColor, valueColor),
              _buildDetailRow("Respondent Name", caseData['respondentAndAdvocate'][0]['name'], labelColor, valueColor),
              _buildDetailRow("Respondent Advocate", caseData['respondentAndAdvocate'][0]['advocate'], labelColor, valueColor),
              _buildDetailRow("Registration Number", caseData['registrationNumber'], labelColor, valueColor),
              _buildDetailRow("Registration Date", caseData['registrationDate'], labelColor, valueColor),
              _buildDetailRow("Filing Number", caseData['filingNumber'], labelColor, valueColor),
              _buildDetailRow("Filing Date", caseData['filingDate'], labelColor, valueColor),
              _buildDetailRow("First Hearing Date", caseData['firstHearingDate'], labelColor, valueColor),
              _buildDetailRow("Next Hearing Date", caseData['nextHearingDate'], labelColor, valueColor),
              _buildDetailRow("Case Stage", caseData['caseStage'], labelColor, valueColor),
              _buildDetailRow("Court Number & Judge", caseData['courtNumberAndJudge'], labelColor, valueColor),
              _buildDetailRow("Case History", caseData['caseHistory'], labelColor, valueColor),
              // _buildDetailRow("Interim Order", caseData['interimOrder'], labelColor, valueColor),
              _buildDetailRow("Summary", caseData['summary'], labelColor, valueColor),
              _buildDetailRow("Customer Name", caseData['customerDetails'][0]['customerName'], labelColor, valueColor),
              _buildDetailRow("Customer Email", caseData['customerDetails'][0]['customerEmail'], labelColor, valueColor),
              _buildDetailRow("Customer Mobile", caseData['customerDetails'][0]['customerMobile'], labelColor, valueColor),
              _buildDetailRow("Customer Address", caseData['customerDetails'][0]['customerAddress'], labelColor, valueColor),
              _buildDetailRow("Customer Loan ID", caseData['customerDetails'][0]['customerLoanId'], labelColor, valueColor),
              _buildDetailRow("Email Status", caseData['customerDetails'][0]['emailStatus'], labelColor, valueColor),
              _buildDetailRow("WhatsApp Status", caseData['customerDetails'][0]['whatsAppStatus'], labelColor, valueColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0), // Adds spacing between rows
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16), // Default text size
          children: [
            TextSpan(
              text: "$title: ",
              style: TextStyle(fontWeight: FontWeight.bold, color: labelColor),
            ),
            TextSpan(
              text: value,
              style: TextStyle(fontWeight: FontWeight.w500, color: valueColor),
            ),
          ],
        ),
      ),
    );
  }
}
