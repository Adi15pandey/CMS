import 'dart:io';
import 'dart:convert';
import 'package:cms/ConsumerCourt/UserSelection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:cms/GlobalServiceurl.dart';

class AddConsumer extends StatefulWidget {
  const AddConsumer({super.key});

  @override
  State<AddConsumer> createState() => _AddConsumerState();
}

class _AddConsumerState extends State<AddConsumer> {
  final TextEditingController _caseNumberController = TextEditingController();
  final String token =
      'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTc0MTA2NDkzMiwiZXhwIjoxNzQxMTUxMzMyfQ.ju_2zjFFC0d3b3zPj6uoo1oFcnay8Huf7ZQrZmcJ__E';

  File? _selectedFile;

  Future<void> searchCase(String caseNumber) async {
    final url = Uri.parse(
        '${GlobalService.baseUrl}/api/consumer-court/case/get-singleCase/$caseNumber');

    try {
      final response = await http.get(url, headers: {'token': token});

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Case data: $data');
      } else {
        print('Failed to fetch case: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> addCase(String caseNumber) async {
    final url = Uri.parse(
        '${GlobalService.baseUrl}/api/consumer-court/case/add/single');

    final payload = {
      'caseNumber': caseNumber,
      'externalUserId': '678f7246df4fd049f632ad18',
      'externalUserName': 'aditya',
      'jointUser': [
        {'name': '11', 'email': '11', 'mobile': '1111', 'dayBeforeNotification': 4}
      ]
    };

    try {
      final response = await http.post(url,
          headers: {
            'token': token,
            'Content-Type': 'application/json'
          },
          body: json.encode(payload));

      final data = json.decode(response.body);
      if (data['success'] == true) {
        print(data['message']);
      } else {
        print('Failed to add case: ${data['message']}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void handleAddCase() {
    final caseNumber = _caseNumberController.text;
    final validFormat = RegExp(r'^[A-Z]{2}/[A-Z]{2}/\d{2}/\d{4}$');

    if (!validFormat.hasMatch(caseNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid case number in format XX/XX/XX/XXXX')),
      );
      return;
    }

    searchCase(caseNumber);
    addCase(caseNumber);
  }

  Future<void> pickExcelFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadExcelFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file first.')),
      );
      return;
    }

    final url = Uri.parse('${GlobalService.baseUrl}/api/upload/excel');
    var request = http.MultipartRequest('POST', url);
    request.headers['token'] = token;
    request.files.add(
      await http.MultipartFile.fromPath('file', _selectedFile!.path),
    );

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload file.')),
        );
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Case Finder & File Uploader', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromRGBO(4, 163, 175, 1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
      SingleChildScrollView(
        child: Padding (
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Case Number Input
              TextField(
                controller: _caseNumberController,
                decoration: InputDecoration(
                  labelText: 'Case Number',
                  hintText: 'XX/XX/XX/XXXX',
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Color.fromRGBO(4, 163, 175, 1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintStyle: const TextStyle(color: Colors.white70),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_caseNumberController.text.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserSelection(
                          Sendcnr: _caseNumberController.text, // Pass entered case number
                          selectedFile: null,
                          sendScreentype: 'Cnr',
                        ),
                      ),
                    );
                    print("Navigating to UserSelection with case number: ${_caseNumberController.text}");
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter a case number")),
                    );
                  }
                },
                child: Text("Add"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),

              const SizedBox(height: 32),
        
              // File Upload Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Upload Excel Files',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromRGBO(4, 163, 175, 1)),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: pickExcelFile,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(4, 163, 175, 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color.fromRGBO(4, 163, 175, 1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upload_file, size: 40, color: Color.fromRGBO(4, 163, 175, 1)),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile == null
                            ? 'Drag & drop your Excel files here, or browse'
                            : 'Selected: ${_selectedFile!.path.split('/').last}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: uploadExcelFile,
                icon: const Icon(Icons.upload),
                label: const Text('Upload'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(4, 163, 175, 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
