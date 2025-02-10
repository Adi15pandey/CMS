import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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
  bool isLoading = true;

  List<dynamic> filteredData = [];
  TextEditingController searchController = TextEditingController(); // Search Controller


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
      fetchClients();
      fetchNotices();
      uploadFile();
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
          filteredData = fileData;
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

  void _filterData(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredData = List.from(fileData);
      } else {
        filteredData = fileData.where((item) {
          return (item['fileName']?.toString().toLowerCase().contains(
              query.toLowerCase()) ?? false) ||
              (item['clientName']?.toString().toLowerCase().contains(
                  query.toLowerCase()) ?? false) ||
              (item['noticeType']?.toString().toLowerCase().contains(
                  query.toLowerCase()) ?? false) ||
              (item['date']?.toString().toLowerCase().contains(
                  query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }


  void showVisibilityDetails(dynamic item) {
    String id = item['_id'] ?? '';  // Extract 'id' from item
    if (id.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VisibilityDetailsScreen(id: id),
        ),
      );
    } else {
      print("⚠️ ID is missing or empty!");
    }
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

  Future<void> sendWhatsApp(String id) async {
    final url = '${GlobalService
        .baseUrl}/api/file/interimorder/sendwhatsapp/$id';

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

  void _showConfirmationDialog(BuildContext context, String action,
      Function onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text("Confirm Action",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            "Are you sure you want to ${action
                .toLowerCase()} this file?\nThis action cannot be undone.",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                  "Cancel", style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Confirmation button color
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                onConfirm(); // Execute the action
              },
              child: Text("Yes, Proceed",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
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
        title: Text(
            'Digital Initiative', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromRGBO(0, 74, 173, 1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar and Button
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                // Search TextField
                Expanded(
                  child: TextField(
                    onChanged: (value) => _filterData(value),
                    decoration: InputDecoration(
                      hintText: "Search by File Name...",
                      prefixIcon: Icon(Icons.search, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ),

                // Small Button
                IconButton(
                  icon: Icon(Icons.upload_file, color: Colors.blue),
                  onPressed: () {
                    _showPopup(context);
                  },
                ),
              ],
            ),
          ),

          // File List
          Expanded(
            child: filteredData.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                final item = filteredData[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Color.fromRGBO(189, 217, 255, 1),
                      width: 2,
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
                                color: Color.fromRGBO(0, 74, 173, 1),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "${item['fileName']}",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromRGBO(117, 117, 117, 1),
                                ),
                                overflow: TextOverflow.ellipsis,
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
                                color: Color.fromRGBO(0, 74, 173, 1),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "${item['clientName']}",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromRGBO(117, 117, 117, 1),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height:6),

                        // Notice Type
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Notice Type: ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color.fromRGBO(0, 74, 173, 1),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "${item['noticeType']}",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromRGBO(117, 117, 117, 1),
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
                                color: Color.fromRGBO(0, 74, 173, 1),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "${item['date']}",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromRGBO(117, 117, 117, 1),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(Icons.visibility, color: Colors.blue),
                              onPressed: () => showVisibilityDetails(item),
                            ),
                            IconButton(
                              icon: const FaIcon(FontAwesomeIcons.whatsapp,
                                  color: Colors.green),
                              tooltip: 'Send via WhatsApp',
                              onPressed: () {
                                _showConfirmationDialog(
                                    context, "send via WhatsApp", () {
                                  sendWhatsApp(item['_id']);
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.email, color: Colors.orange),
                              onPressed: () {
                                _showConfirmationDialog(
                                    context, "send via Email", () {
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
          ),
        ],
      ),
    );
  }
  List<Map<String, dynamic>> clients = [];
  String? selectedClient;

  Future<void> fetchClients() async {
    final apiUrl = '${GlobalService.baseUrl}/api/client/getclients';
    // final token = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczODgxNzk5MSwiZXhwIjoxNzM4OTA0MzkxfQ.pTjEYNx26RpXTSTbufRBbLDCgt67i4DPzW3-7H052M0';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'token': '$token',        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          // ✅ Fix: Use 'clients' instead of 'data'
          final List<dynamic> clientList = jsonResponse['clients'] ?? [];

          setState(() {
            clients = clientList.map((client) => {
              '_id': client['_id'].toString(),
              'clientName': client['clientName']?.toString() ?? 'Unknown',
            }).toList();
            isLoading = false;
          });

          print("Clients loaded: $clients"); // Debugging
        }
      } else {
        throw Exception("Failed to load clients");
      }
    } catch (e) {
      debugPrint("Error fetching clients: $e");
    }
  }

  List<Map<String, String>> notices = [];
  String? selectedNotice;
  Future<void> fetchNotices() async {
    final apiUrl = '${GlobalService.baseUrl}/api/notice/getnotice';
    // final token = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczODgxNzk5MSwiZXhwIjoxNzM4OTA0MzkxfQ.pTjEYNx26RpXTSTbufRBbLDCgt67i4DPzW3-7H052M0';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'token': '$token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          setState(() {
            notices = (jsonResponse['data'] as List)
                .map((notice) => {
              'id': notice['_id'].toString(), // ✅ Correct key
              'name': notice['noticeType']?.toString() ?? 'Unnamed',
            })
                .toList();
            isLoading = false;
          });

          print("Notices Loaded: $notices");
        } else {
          throw Exception("Invalid API response format");
        }
      } else {
        throw Exception("Failed to load notices");
      }
    } catch (e) {
      debugPrint("Error fetching notices: $e");
      setState(() {
        isLoading = false;
      });
    }
  }
   // Store selected file



  File? selectedFile;
  String? fileName;
  bool isUploading = false;
  Future<void> uploadFile() async {
    if (selectedFile == null) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Please select a file first.")),
      // );
      return;
    }

    setState(() {
      isUploading = true;
    });

    var headers = {
      'token': '$token',
    };

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${GlobalService.baseUrl}/api/file/fileupload/'),
    );

    request.fields.addAll({
      'clientName': selectedClient ?? '',
      'noticeType': selectedNotice ?? '',
    });

    request.files.add(
      await http.MultipartFile.fromPath('file', selectedFile!.path),
    );

    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print("Upload successful: $responseBody");

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Success"),
              content: Text("File uploaded successfully!"),
            );
          },
        );

        // Close dialog after 2 seconds
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pop();
        });

        // Clear selected file after success
        setState(() {
          selectedFile = null;
        });
      } else {
        print("Upload failed: ${response.reasonPhrase}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: ${response.reasonPhrase}")),
        );
      }
    } catch (e) {
      print("Error uploading file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });

      print("Selected file path: ${selectedFile!.path}"); // Debugging
    } else {
      print("No file selected");
    }
  }


  void _showPopup(BuildContext context) {
    File? selectedFile;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Upload Excel File',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Select Notice Type
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Notice Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  value: selectedNotice,
                  items: isLoading
                      ? []
                      : notices.map((notice) {
                    return DropdownMenuItem(
                      value: notice['name'],
                      child: Text(notice['name']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedNotice = value;
                    });
                  },
                ),

                SizedBox(height: 15),

                // Select Client Name
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Client Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  value: selectedClient != null && selectedClient!.isNotEmpty ? selectedClient : null,
                  items: clients.isNotEmpty
                      ? clients.map((client) {
                    return DropdownMenuItem(
                      value: client['clientName'].toString(),
                      child: Text(client['clientName']?.toString() ?? 'Unknown'),
                    );
                  }).toList()
                      : [],
                  onChanged: (value) {
                    setState(() {
                      selectedClient = value;
                    });
                  },
                ),

                SizedBox(height: 15),

                // File Upload Area
                GestureDetector(
                  onTap: pickFile,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade100,
                    ),
                    child: Center(
                      child: selectedFile == null
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, size: 40, color: Colors.grey.shade600),
                          SizedBox(height: 5),
                          Text(
                            "Click to upload or drag ",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      )
                          : Text(
                        "Selected: ${selectedFile!.path.split('/').last}",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: isUploading ? null : uploadFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isUploading ? "Uploading..." : "Import",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

}


class VisibilityDetailsScreen extends StatefulWidget {
  final String id;

  const VisibilityDetailsScreen({Key? key, required this.id}) : super(key: key);

  @override
  _VisibilityDetailsScreenState createState() => _VisibilityDetailsScreenState();
}

class _VisibilityDetailsScreenState extends State<VisibilityDetailsScreen> {
  Map<String, dynamic>? caseData;
  bool isLoading = true;
  String errorMessage = "";
  String?token;

  @override
  void initState() {
    super.initState();
    fetchCaseDetails();
  }

  Future<void> fetchCaseDetails() async {
    String apiUrl = "http://192.168.68.134:4001/api/file/filedatabyid/${widget.id}/?search=&page=1&limit=50";

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'token': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczODgyNjA1MSwiZXhwIjoxNzM4OTEyNDUxfQ.dlr-jAg1E_AfvgYyus5NLiIUYeRr5kdQx70dN_eExCQ',
          'Content-Type': 'application/json',
        },
      );

      print("API Response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List && jsonResponse['data'].isNotEmpty) {
          setState(() {
            caseData = jsonResponse['data'][0];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = "No data found.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Failed to load data: ${response.reasonPhrase}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    Color labelColor = const Color.fromRGBO(0, 74, 173, 1);
    Color valueColor = const Color.fromRGBO(117, 117, 117, 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Case Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: labelColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red, fontSize: 16)))
          : caseData != null
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow("CNR Number", caseData?['cnrNumber'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("Case Type", caseData?['caseType'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("Filing Number", caseData?['filingNumber'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("Filing Date", caseData?['filingDate'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("Registration Number", caseData?['registrationNumber'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("Registration Date", caseData?['registrationDate'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("First Hearing Date", caseData?['firstHearingDate'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("Next Hearing Date", caseData?['nextHearingDate'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("Case Stage", caseData?['caseStage'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("Court Number & Judge", caseData?['courtNumberAndJudge'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("Case History", caseData?['caseHistory'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("Summary", caseData?['summary'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("Customer Name", caseData?['customerName'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("Customer Email", caseData?['customerEmail'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("Customer Mobile", caseData?['customerMobile'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("Customer Address", caseData?['customerAddress'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("Loan ID", caseData?['customerLoanId'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("Email Status", caseData?['emailStatus'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("WhatsApp Status", caseData?['whatsAppStatus'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("Notice Type", caseData?['noticeType'] ?? "N/A", labelColor, valueColor),
              _buildDetailRow("Client Name", caseData?['clientName'] ?? "N/A", labelColor, valueColor),
            ],
          ),
        ),
      )
          : const Center(child: Text("No details available.")),
    );
  }

  Widget _buildDetailRow(String title, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16),
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