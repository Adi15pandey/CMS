import 'package:cms/CaseDetailsScreen.dart';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For jsonDecode
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:permission_handler/permission_handler.dart';

class DisposedCases extends StatefulWidget {
  const DisposedCases({super.key});

  @override
  State<DisposedCases> createState() => _DisposedCasesState();
}

class _DisposedCasesState extends State<DisposedCases> {
  List<dynamic> _cases = [];
  bool _isLoading = true;
  String? token;
  bool _showCheckboxes = false; // Whether to show checkboxes or not
  List<bool> _selectedCases = []; // To track selected cases
  bool _selectAll = false;

  List<dynamic> _filteredCases = []; // This will be used to store filtered cases
  TextEditingController _searchController = TextEditingController(); // To store the token

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(_filterCases);
  }

  void _filterCases() {
    setState(() {
      String searchQuery = _searchController.text.toLowerCase();
      _filteredCases = _cases.where((caseData) {
        String cnrNumber = caseData['cnrNumber'].toLowerCase();
        return cnrNumber.contains(searchQuery);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCases);
    _searchController.dispose();
    super.dispose();
  }

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

  // List to store selected cases
  List<dynamic> _selectedCaseDetails = [];

  // Function to extract specific date from case status
  String? _extractCaseStatusDate(List<dynamic>? caseStatus, String key) {
    if (caseStatus != null && caseStatus.isNotEmpty) {
      for (var status in caseStatus) {
        if (status.isNotEmpty && status[0] == key) {
          return status[1]; // Return the date corresponding to the key
        }
      }
    }
    return null;
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
            _filteredCases = _cases; // Show all cases initially
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

  Future<void> _exportToExcel() async {
    // Create a new Excel file
    var excel = Excel.createExcel();
    var sheet = excel[excel.getDefaultSheet()!];

    // Add header row
    sheet.appendRow([
      'CNR Number',
      'Petitioner',
      'Respondent',
      'Last Hearing Date',
      'Next Hearing Date',
    ]);

    // Add rows for each selected case
    for (var caseDetail in _selectedCaseDetails) {
      try {
        // Extract details or set default values
        String cnrNumber = caseDetail.cnrNumber ?? "Unknown CNR Number";
        String petitioner = _extractPetitionerOrRespondent(caseDetail.petitionerAndAdvocate) ?? "Unknown Petitioner";
        String respondent = _extractPetitionerOrRespondent(caseDetail.respondentAndAdvocate) ?? "Unknown Respondent";
        String lastHearingDate = _extractCaseHistoryDate(caseDetail.caseHistory) ?? "Unknown Last Hearing";
        String nextHearingDate = _extractCaseStatusDate(caseDetail.caseStatus, "Next Hearing Date") ?? "Unknown Next Hearing";

        // Append the row to the sheet
        sheet.appendRow([
          cnrNumber,
          petitioner,
          respondent,
          lastHearingDate,
          nextHearingDate,
        ]);
        print('Appending row: ${[
          caseDetail.cnrNumber ?? "Unknown CNR Number",
          petitioner,
          respondent,
          nextHearingDate
        ]}');
      } catch (e) {
        print("Error processing case: $e");
      }
    }

    // Finalize the default sheet
    excel.setDefaultSheet(sheet.sheetName);
    print('Rows in sheet: ${sheet.rows}');

    // Check storage permissions
    if (await Permission.storage.request().isGranted || await Permission.manageExternalStorage.request().isGranted) {
      try {
        // Encode the Excel file into bytes
        final excelBytes = await excel.encode();
        if (excelBytes == null) {
          throw Exception("Failed to encode Excel file.");
        }

        // Get the download directory (platform-safe)
        final directory = await getDownloadsDirectory();
        if (directory == null) {
          throw Exception("Failed to get downloads directory.");
        }

        // Save the file
        final file = File('${directory.path}/Cases_Repo.xlsx');
        await file.writeAsBytes(excelBytes);

        // Notify the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel file saved at: ${file.path}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied. Unable to save file.')),
      );
    }
  }

  // Extract the last hearing date from case history
  String? _extractCaseHistoryDate(List<dynamic>? caseHistory) {
    if (caseHistory != null && caseHistory.isNotEmpty) {
      final lastEntry = caseHistory.last;
      if (lastEntry.isNotEmpty && lastEntry[1] != null) {
        return lastEntry[1];
      }
    }
    return null;
  }

  // Extract petitioner or respondent from their respective data
  String? _extractPetitionerOrRespondent(List<dynamic>? partyData) {
    if (partyData != null && partyData.isNotEmpty) {
      return partyData[0][0]; // Assume the first element contains the name
    }
    return null;
  }

  // Get the Downloads directory (platform-safe approach)
  Future<Directory?> getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    } else {
      return await getApplicationDocumentsDirectory(); // Use a default directory for iOS or other platforms
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Disposed Cases"),
        backgroundColor: Color.fromRGBO(0, 74, 173, 1),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search",
                hintText: "Search by CNR, Petitioner, or Respondent",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                _filterCases(); // Filter cases dynamically
              },
            ),
          ),

          // Export Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                // ElevatedButton(
                //   onPressed: () {
                //     setState(() {
                //       _showCheckboxes = !_showCheckboxes; // Toggle checkbox visibility
                //       if (_showCheckboxes) {
                //         _selectedCases = List<bool>.filled(_filteredCases.length, false);
                //         _selectAll = false;
                //       }
                //     });
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.green,
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //   ),
                //   // child: Text(
                //   //   _showCheckboxes ? "Done" : "Export",
                //   //   style: const TextStyle(color: Colors.white, fontSize: 16),
                //   // ),
                // ),
                const SizedBox(width: 10),
                if (_showCheckboxes)
                  Row(
                    children: [
                      Checkbox(
                        value: _selectAll,
                        onChanged: (value) {
                          setState(() {
                            _selectAll = value!;
                            _selectedCases = List<bool>.filled(_filteredCases.length, _selectAll);
                          });
                        },
                      ),
                      const Text("Select All"),
                    ],
                  ),
              ],
            ),
          ),

          // Display Cases
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredCases.isEmpty
              ? const Center(child: Text("No disposed cases found"))
              : Expanded(
            child: ListView.builder(
              itemCount: _filteredCases.length,
              itemBuilder: (context, index) {
                final caseData = _filteredCases[index];
                final caseStatus = caseData['caseStatus'];
                final petitioner = caseData['petitionerAndAdvocate'];
                final respondent = caseData['respondentAndAdvocate'];

                // Extract Last and Final Hearing Dates
                String lastHearing = "Not Available";
                String finalHearing = "Not Available";

                for (var status in caseStatus) {
                  if (status.isNotEmpty) {
                    if (status[0] == "First Hearing Date") {
                      lastHearing = status[1];
                    } else if (status[0] == "Decision Date") {
                      finalHearing = status[1];
                    }
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
                        // Checkbox (if enabled)
                        if (_showCheckboxes)
                          CheckboxListTile(
                            value: _selectedCases[index],
                            onChanged: (value) {
                              setState(() {
                                _selectedCases[index] = value!;
                                _selectAll = !_selectedCases.contains(false);
                              });
                            },
                            title: Text(
                              'CNR: ${caseData['cnrNumber']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16),
                            ),
                          ),

                        if (!_showCheckboxes)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // CNR Number and its corresponding data
                              _buildRow('CNR Number', caseData['cnrNumber']),
                              const SizedBox(height: 8),
                              // Last Hearing
                              _buildRow('Last Hearing', lastHearing),
                              const SizedBox(height: 8),
                              // Final Hearing
                              _buildRow('Final Hearing', finalHearing),
                              const SizedBox(height: 8),
                              // Petitioner
                              _buildRow(
                                'Petitioner',
                                petitioner.isNotEmpty
                                    ? petitioner[0][0]
                                    : 'N/A',
                              ),
                              const SizedBox(height: 8),
                              // Respondent
                              _buildRow(
                                'Respondent',
                                respondent.isNotEmpty
                                    ? respondent[0][0]
                                    : 'N/A',
                              ),
                              const SizedBox(height: 16),

                              // Row with action buttons
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CaseDetailsScreen(
                                                cnrNumber:
                                                caseData['cnrNumber'],
                                              ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color.fromRGBO(0, 111, 253, 1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      "View Detail",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      _deleteCase(index);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color.fromRGBO(253, 101, 0, 1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      "Delete",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
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
                );
              },
            ),
          ),

          // Download Button
          if (_showCheckboxes)
            Padding(
              padding: const EdgeInsets.all(10),
              child: ElevatedButton(
                onPressed: () {
                  _exportToExcel(); // Call download function
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Download Selected",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper Method to Build Rows
  Widget _buildRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:Color.fromRGBO(0, 74, 173, 1),

            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.black54,
            ),
          ),
        ),
      ],
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
