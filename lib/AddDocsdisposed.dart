import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AddDocsdisposed extends StatefulWidget {
  final String id;
  final String cnrNumber;

  const AddDocsdisposed({required this.id, required this.cnrNumber, Key? key}) : super(key: key);

  @override
  _AddDocsdisposedState createState() => _AddDocsdisposedState();
}

class _AddDocsdisposedState extends State<AddDocsdisposed> {
  TextEditingController _fileNameController = TextEditingController();
  File? _selectedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }
  String?token;
  bool  _isLoading=true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _submitData();

  }
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      _submitData();// Fetch cases if the token is valid
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

  Future<void> _submitData() async {
    // Check for empty fields or missing file
    if (_fileNameController.text.isEmpty || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and select a file!')),
      );
      return;
    }

    // Add headers
    var headers = {
      'token': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzY5NDIyOSwiZXhwIjoxNzM3NzgwNjI5fQ.61uspeeYspKI9Kr6VGE-sThMoOCOmbx89B1C5S4M2wE',
    };

    // Prepare the request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.0.111:4001/api/document/add-sub-document'),
    );

    // Add fields to the request
    request.fields.addAll({
      'cnrNumber': widget.cnrNumber,
      'mainUserId': widget.id,
      'fileNames': _fileNameController.text,
    });

    // Debug log for fields
    print('Request Fields:');
    request.fields.forEach((key, value) => print('$key: $value'));

    // Attach file
    try {
      print('File path: ${_selectedFile?.path}');
      request.files.add(await http.MultipartFile.fromPath(
        'files',
        _selectedFile!.path,
      ));
    } catch (e) {
      print('Error attaching file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error attaching file: $e')),
      );
      return;
    }

    // Add headers to the request
    request.headers.addAll(headers);
    print('Request Headers: $headers');

    // Debug: Send request
    try {
      http.StreamedResponse response = await request.send();

      // Debug status and response body
      if (response.statusCode == 200) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${await response.stream.bytesToString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document uploaded successfully!')),
        );
      } else {
        String responseString = await response.stream.bytesToString();
        print('Response Status: ${response.statusCode}');
        print('Response Reason: ${response.reasonPhrase}');
        print('Response Body: $responseString');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload document: $responseString')),
        );
      }
    } catch (e) {
      print('Error during request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Documents"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CNR Number: ${widget.cnrNumber}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _fileNameController,
              decoration: InputDecoration(
                labelText: "Document Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickFile,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedFile == null
                          ? "Choose File"
                          : _selectedFile!.path.split('/').last,
                    ),
                    Icon(Icons.upload_file),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitData,
              child: Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
