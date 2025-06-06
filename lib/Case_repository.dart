
import 'dart:convert';
import 'dart:io';

import 'package:cms/GlobalServiceurl.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'MyCouncilDetails.dart';
import 'MyCouncilModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyCouncil extends StatefulWidget {
  const MyCouncil({super.key});

  @override
  State<MyCouncil> createState() => _MyCouncilState();
}

class _MyCouncilState extends State<MyCouncil> {
  late Future<List<CaseDetails>> futureCaseDetails;
  List<CaseDetails> _caseDetailsList = []; // Stores the fetched case details
  List<CaseDetails> _filteredCaseDetails = []; // Stores the filtered case details
  List<CaseDetails> _selectedCaseDetails = []; // List to store selected case items
  List<CaseDetails> selectedCases = []; // Holds the selected cases to export
  bool _showCheckboxes = false;
  bool _selectAll = false;
  String?token;
  bool  _isLoading =true;



  TextEditingController _searchController = TextEditingController();


  void _onCaseSelected(bool selected, CaseDetails caseDetails) {
    setState(() {
      if (selected) {
        _selectedCaseDetails.add(caseDetails);
      } else {
        _selectedCaseDetails.remove(caseDetails);
      }
    });
  }

  Future<void> _exportToExcel() async {
    var excel = Excel.createExcel();
    var sheet = excel[excel.getDefaultSheet()!];

    // Add header row in Excel
    sheet.appendRow(['CNR Number', 'Petitioner', 'Respondent', 'Last Hearing Date', 'Next Hearing Date']);

    // Add data for each selected case
    for (var caseDetail in _selectedCaseDetails) {
      String lastDate = "Unknown Last Hearing"; // Default value for "Last Hearing Date"


      if (caseDetail.caseHistory != null && caseDetail.caseHistory.isNotEmpty) {
        final lastCaseHistory = caseDetail.caseHistory.last;
        if (lastCaseHistory.isNotEmpty && lastCaseHistory[1] != null) {
          lastDate = lastCaseHistory[1]; // Get the date from the last caseHistory entry
        }
      }
      String petitioner = _extractPetitionerOrRespondent(caseDetail.petitionerAndAdvocate) ?? "Unknown Petitioner";
      String respondent = _extractPetitionerOrRespondent(caseDetail.respondentAndAdvocate) ?? "Unknown Respondent";
      //  String lastHearingDate = _extractCaseStatusDate(caseDetail.caseStatus, "Last Hearing Date") ?? "Unknown Last Hearing";
      String nextHearingDate = _extractCaseStatusDate(caseDetail.caseStatus, "Next Hearing Date") ?? "Unknown Next Hearing";

      // Debugging: Check if the fields are null
      print('Appending row: ${[
        caseDetail.cnrNumber ?? "Unknown CNR Number",
        petitioner,
        respondent,
        lastDate,
        nextHearingDate
      ]}');

      // Check if caseDetail.cnrNumber is null before appending
      if (caseDetail.cnrNumber != null) {
        sheet.appendRow([
          caseDetail.cnrNumber,
          petitioner,
          respondent,
          lastDate,
          nextHearingDate
        ]);
      } else {
        print("Skipping case due to null CNR number.");
      }
    }

    // Debugging: Check rows in the sheet
    print('Rows in sheet: ${sheet.rows}');

    // Set the active sheet
    excel.setDefaultSheet(sheet.sheetName);

    // Request storage permission
    if (await Permission.storage.request().isGranted || await Permission.manageExternalStorage.request().isGranted) {
      try {
        final excelBytes = await excel.encode();
        if (excelBytes == null) {
          print('Excel encoding failed');
          return;
        }

        // Get the Downloads directory
        final directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          await directory.create();
        }

        final file = File('${directory.path}/Cases_Repo.xlsx');
        await file.writeAsBytes(excelBytes); // Save the file to Downloads folder

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel file saved at: ${file.path}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission denied. Unable to save file.')),
      );
    }
  }


  Future<Directory?> getDownloadsDirectory() async {
    return Directory('/storage/emulated/0/Download');
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
     futureCaseDetails = fetchCaseDetails();
     _searchController.addListener(_onSearchChanged);

    // print(AppConstants.token);
  }
  Future<void> _initializeData() async {
    await _fetchToken();
    if (token != null && token!.isNotEmpty) {
      futureCaseDetails = fetchCaseDetails();
      _searchController.addListener(_onSearchChanged);
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

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Function to handle changes in the search query
  void _onSearchChanged() {
    _filterCaseDetails(_searchController.text);
  }

  void _filterCaseDetails(String query) {
    final lowerQuery = query.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredCaseDetails = _caseDetailsList;
      } else {
        _filteredCaseDetails = _caseDetailsList.where((caseDetails) {
          final cnrLower = caseDetails.cnrNumber.toLowerCase();
          final petitionerLower = _extractPetitionerOrRespondent(caseDetails.petitionerAndAdvocate).toLowerCase();

          return cnrLower.contains(lowerQuery) || petitionerLower.contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Case Repository', style: TextStyle(color: Colors.white)),
          backgroundColor: Color.fromRGBO(4, 163, 175, 1),
          centerTitle: true,
          iconTheme: const IconThemeData(
              color: Colors.white),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 15),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by CNR No',

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color:Color.fromRGBO(4, 163, 175, 1),),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  prefixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                ),
                onChanged: (query) {
                  _filterCaseDetails(query); // Filter case details based on search query
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15, top: 10),
              child: Align(
                alignment: Alignment.topRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showCheckboxes = !_showCheckboxes; // Toggle checkbox visibility
                    });
                  },
                  icon: Icon(Icons.file_download, color: Colors.white), // Add an icon
                  label: Text(
                    'Export',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                     backgroundColor: Color(0xFF004AAD),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),


            if (_showCheckboxes)
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectAll = !_selectAll;
                        if (_selectAll) {
                          _selectedCaseDetails = List.from(_filteredCaseDetails); // Select all
                        } else {
                          _selectedCaseDetails.clear(); // Deselect all
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(4, 163, 175, 1), // Background color
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3), // Optional: Rounded corners
                      ),
                    ),
                    child: Text(
                      _selectAll ? 'Deselect All' : 'Select All',
                      style: TextStyle(color: Colors.white), // Text color
                    ),
                  ),
                ),
              ),

            Expanded(
              child: FutureBuilder<List<CaseDetails>>(
                future: futureCaseDetails,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData) {
                    // Populate the case details list once data is fetched
                    if (_caseDetailsList.isEmpty) {
                      _caseDetailsList = snapshot.data!;
                      _filteredCaseDetails = _caseDetailsList; // Initially show all cases
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _filteredCaseDetails.length,
                      itemBuilder: (context, index) {
                        final caseDetails = _filteredCaseDetails[index];
                        final petitioner = _extractPetitionerOrRespondent(caseDetails.petitionerAndAdvocate);
                        final respondent = _extractPetitionerOrRespondent(caseDetails.respondentAndAdvocate);
                        String firstHearingDate = "Not Available";
                        String lastHearingDate = "Not Available";


                        for (var status in caseDetails.caseStatus) {
                          if (status.isNotEmpty) {
                            if (status[0] == "First Hearing Date") {
                              firstHearingDate = status[1];
                            } else if (status[0] == "Next Hearing Date") {
                              lastHearingDate = status[1];
                            }
                          }
                        }
                         String lastDate = "Not Available";
                        if (caseDetails.caseHistory != null && caseDetails.caseHistory.isNotEmpty) {
                          final lastCaseHistory = caseDetails.caseHistory.last;

                          if (lastCaseHistory.isNotEmpty && lastCaseHistory.length > 1 && lastCaseHistory[1] != null) {
                            lastDate = lastCaseHistory[1];
                          }
                        }


                        return Column(
                          children: [
                            if (_showCheckboxes)
                              CheckboxListTile(
                                value: _selectedCaseDetails.contains(caseDetails),
                                onChanged: (bool? selected) {
                                  _onCaseSelected(selected!, caseDetails);
                                },
                                title: Text("Select this case"),
                              ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 12.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(189, 217, 255, 1),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            "Advocate Name",  // Label for the advocate's name
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color.fromRGBO(4, 163, 175, 1), // Label color
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            caseDetails.userId.isNotEmpty ? caseDetails.userId[0].externalUserName : "N/A",
                                            textAlign: TextAlign.end,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black54,  // Text color
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // CNR Number
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            "Cnr",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                               color:Color.fromRGBO(4, 163, 175, 1),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            caseDetails.cnrNumber,
                                            textAlign: TextAlign.end,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            "Last Hearing",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color:Color.fromRGBO(4, 163, 175, 1),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            lastDate,
                                            textAlign: TextAlign.end,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Final Hearing
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Expanded(
                                          flex: 2,
                                          child: Text(
                                            "Next Hearing",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color:Color.fromRGBO(4, 163, 175, 1),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            lastHearingDate,
                                            textAlign: TextAlign.end,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Petitioner
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Expanded(
                                          flex: 2,
                                          child: Text(
                                            "Petitioner",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color:Color.fromRGBO(4, 163, 175, 1),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            petitioner,
                                            textAlign: TextAlign.end,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Respondent
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            "Respondent",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color:Color.fromRGBO(4, 163, 175, 1),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            respondent,
                                            textAlign: TextAlign.end,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16.0),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color.fromRGBO(4, 163, 175, 1),
                                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8.0),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => MyCouncilDetails(
                                                  SendCnrNo: caseDetails.cnrNumber ?? "N/A",
                                                  SendNextHearingDate: lastHearingDate ?? "N/A",
                                                ),
                                              ),
                                            );
                                          },

                                          child: const Text(
                                            "View Detail",
                                            style: TextStyle(
                                              color: Colors.white,
                                              backgroundColor: Color.fromRGBO(4, 163, 175, 1),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color.fromRGBO(253, 101, 0, 1),

                                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8.0),
                                            ),
                                          ),
                                          onPressed: () {
                                            deleteCNR(caseDetails.cnrNumber);
                                          },
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(
                                              color: Colors.white,
                                              backgroundColor: Color.fromRGBO(253, 101, 0, 1),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }
                  return Center(child: Text('No Data Found'));
                },
              ),
            ),
            if (_showCheckboxes)

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: _exportToExcel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Sets the background color to green
                    ),
                    child: Text(
                      'Download',
                      style: TextStyle(color: Colors.white), // Optional: set text color to white
                    ),
                  ),
                ),
              ),

          ],
        )
    );
  }

  // Extract petitioner or respondent from the respective lists
  String _extractPetitionerOrRespondent(List<List<String>>? data) {
    if (data != null && data.isNotEmpty) {
      return data[0][0];
    }
    return 'Not Available';
  }

  // Extract date from caseStatus based on the label
  String _extractCaseStatusDate(List<List<String>>? caseStatus, String label) {
    if (caseStatus != null) {
      for (var status in caseStatus) {
        if (status[0] == label) {
          return status[1];
        }
      }
    }
    return 'Not Available';
  }



  Future<List<CaseDetails>> fetchCaseDetails() async {
    final response = await http.get(
      Uri.parse('${GlobalService.baseUrl}/api/cnr/get-cnr?pageNo=1&pageLimit=10000000000000000000000000000000000000000000000000000000000000000000&filterText=&nextHearing=0&petitioner=0&respondent=0'),
      headers: {
        'token': '$token',
        'Content-Type': 'application/json',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final jsonData = jsonDecode(response.body);

        if (jsonData is Map<String, dynamic> && jsonData['data'] is List) {
          List<dynamic> caseDetailsList = jsonData['data'];
          return caseDetailsList.map((item) => CaseDetails.fromJson(item)).toList();
        } else {
          throw Exception("Invalid data format: Expected a list in 'data' key");
        }
      } catch (e) {
        throw Exception("Error parsing JSON: $e");
      }
    } else {
      throw Exception('Failed to load case details. Status code: ${response.statusCode}');
    }
  }


  Future<void> deleteCNR(String cnrId,) async {

    final url = Uri.parse('${GlobalService.baseUrl}/api/cnr/delte-cnr/$cnrId');

    try {
      final response = await http.delete(
        url,
        headers: {
          'token': '$token',


          // 'Authorization': AppConstants.token,//'Bearer $token',
          'Content-Type': 'application/json', // Optional, based on API requirements
        },
      );

      if (response.statusCode == 200) {
        // Successfully deleted

        print("Deleted successfully");
       // GlobalFunction().ShowMsg(context, "Deleted Successfully");
        // Refresh the data after deletion
        setState(() {
          futureCaseDetails = fetchCaseDetails();
        });
      } else {
        // Handle error
        print('Failed to delete: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (error) {
      print('Error during DELETE request: $error');
    }
  }


// Filter the case details based on search query
}