import 'dart:convert';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Trackedcases extends StatefulWidget {
  @override
  _TrackedcasesState createState() => _TrackedcasesState();
}

class _TrackedcasesState extends State<Trackedcases> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _unsavedCnrs = [];
  List<Map<String, dynamic>> _filteredCnrs = [];
  String? token;
  String _selectedFilter = 'All';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchToken();
  }

  Future<void> _fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final savedToken = prefs.getString('auth_token');

    if (savedToken != null && savedToken.isNotEmpty) {
      setState(() => token = savedToken);
      fetchUnsavedCnr();
    } else {
      _showMessage("Token not found. Please log in again.");
    }
  }

  Future<void> fetchUnsavedCnr({String searchQuery = '', String selectedFilter = 'All'}) async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${GlobalService.baseUrl}/api/cnr/get-unsaved-cnr?searchQuery=$searchQuery&currentPage=1&pageLimit=1000000000000&selectedFilter=$selectedFilter'),
        headers: {'token': '$token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            _unsavedCnrs = List<Map<String, dynamic>>.from(responseData['data']);
            _filteredCnrs = _unsavedCnrs;
          });
        } else {
          _showMessage(responseData['message'] ?? "Failed to fetch data");
        }
      } else {
        _showMessage("Error: ${response.statusCode}");
      }
    } catch (e) {
      _showMessage("An error occurred: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterSearchResults( String query ) {
    setState(() {
      _filteredCnrs = query.isEmpty
          ? List.from(_unsavedCnrs)
          : _unsavedCnrs.where((cnr) => cnr['cnr'].toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tracked Cases", style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromRGBO(4, 163, 175, 1),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            color: Colors.white,
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSearchResults,
              decoration: InputDecoration(
                labelText: "Search CNR Number",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Table(
                  border: TableBorder.all(color: Color.fromRGBO(4, 163, 175, 1),),
                  columnWidths: {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Color.fromRGBO(4, 163, 175, 1),),
                      children: [
                        _tableHeader("CNR NUMBER"),
                        _tableHeader("STATUS"),
                      ],
                    ),
                    ..._filteredCnrs.map(_buildTableRow),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
    );
  }

  TableRow _buildTableRow(Map<String, dynamic> cnr) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(cnr['cnr'], style: TextStyle(fontSize: 14)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: cnr['status'].toLowerCase() == "processed"
                        ? Colors.purple
                        : Colors.orange,
                  ),
                  SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      cnr['status'],
                      style: TextStyle(fontSize: 14, color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 5),

              // Hide Due Date if status is "processed"
              if (cnr['status'].toLowerCase() != "processed")
                Text(
                  "(Due on ${cnr['date']})",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                12), // Rounded corners for the dialog
          ),
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Select Filter',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent, // Make title standout
              ),
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.all(8.0), // Add padding for dropdown
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              // Add horizontal padding for better spacing
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                // Rounded corners for dropdown
                border: Border.all(color: Colors.grey.shade400), // Border color
              ),
              child: DropdownButton<String>(
                value: _selectedFilter,
                onChanged: (newValue) {
                  setState(() {
                    _selectedFilter = newValue!;
                  });
                  Navigator.pop(context);
                  fetchUnsavedCnr(
                      selectedFilter: _selectedFilter); // Fetch data with the selected filter
                },
                isExpanded: true, // Make the dropdown full width
                items: <String>[
                  'All',
                  'Wrong',
                  'Processed',
                  'Pending',
                  'InvalidCnr',
                  'UnderProgress'
                ]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87, // Text color
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: <Widget>[

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}



// Filter dialog
//   void _showFilterDialog() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(
//                 12), // Rounded corners for the dialog
//           ),
//           title: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8.0),
//             child: Text(
//               'Select Filter',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blueAccent, // Make title standout
//               ),
//             ),
//           ),
//           content: Padding(
//             padding: const EdgeInsets.all(8.0), // Add padding for dropdown
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12.0),
//               // Add horizontal padding for better spacing
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(8),
//                 // Rounded corners for dropdown
//                 border: Border.all(color: Colors.grey.shade400), // Border color
//               ),
//               child: DropdownButton<String>(
//                 value: _selectedFilter,
//                 onChanged: (newValue) {
//                   setState(() {
//                     _selectedFilter = newValue!;
//                   });
//                   Navigator.pop(context);
//                   fetchUnsavedCnr(
//                       selectedFilter: _selectedFilter); // Fetch data with the selected filter
//                 },
//                 isExpanded: true, // Make the dropdown full width
//                 items: <String>[
//                   'All',
//                   'Wrong',
//                   'Processed',
//                   'Pending',
//                   'InvalidCnr',
//                   'UnderProgress'
//                 ]
//                     .map<DropdownMenuItem<String>>((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(
//                       value,
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.black87, // Text color
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//           actions: <Widget>[
//
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text(
//                 'Cancel',
//                 style: TextStyle(
//                   color: Colors.blueAccent,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
