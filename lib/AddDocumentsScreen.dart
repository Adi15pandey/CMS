import 'dart:io';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddDocumentsScreen extends StatefulWidget {
  @override
  _AddDocumentsScreenState createState() => _AddDocumentsScreenState();
}

class _AddDocumentsScreenState extends State<AddDocumentsScreen> {
  final TextEditingController cnrController = TextEditingController();
  List<DocumentField> documents = [DocumentField()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Documents'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: cnrController,
              decoration: InputDecoration(
                labelText: 'CNR Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  return documents[index];
                },
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  documents.add(DocumentField());
                });
              },
              child: Text(
                '+ Add Another Document',
                style: TextStyle(color: Colors.teal),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submitData,
                  child: Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String?token;
  bool  _isLoading=true;
  @override
  void initState() {
    super.initState();
    _initializeData();
    submitData();

  }
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      submitData();// Fetch cases if the token is valid
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

  void submitData() async {
    try {
      final url = Uri.parse('${GlobalService.baseUrl}/api/document/add-document');
      var request = http.MultipartRequest('POST', url);

      // Add headers
      request.headers['token'] ='$token';
      // request.headers['token'] = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzM2NTg2MywiZXhwIjoxNzM3NDUyMjYzfQ.tB2EW3kKVYhqrBtAZGmh9S5AMODKyHiOwUu_sA5MvCw';

      // Add fields
      request.fields['cnrNumber'] = cnrController.text;
      request.fields['fileNames'] = '';

      // Add files
      for (var i = 0; i < documents.length; i++) {
        var document = documents[i];
        if (document.file != null) {
          request.files.add(
            await http.MultipartFile.fromPath('files', document.file!.path),
          );
        }
      }

      // Send request
      var response = await request.send();

      // Debug response
      if (response.statusCode == 200) {
        print("Success: ${await response.stream.bytesToString()}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Documents submitted successfully!')),
        );
      } else {
        print("Failed: ${response.statusCode} - ${response.reasonPhrase}");
        print("Body: ${await response.stream.bytesToString()}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

}

class DocumentField extends StatefulWidget {
  final TextEditingController nameController = TextEditingController();
  File? file;

  @override
  _DocumentFieldState createState() => _DocumentFieldState();
}

class _DocumentFieldState extends State<DocumentField> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.nameController,
              decoration: InputDecoration(
                labelText: 'Document Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: pickFile,
            icon: Icon(Icons.upload_file),
            label: Text(widget.file == null ? 'Choose File' : 'Change File'),
          ),
        ],
      ),
    );
  }

  void pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        widget.file = File(result.files.single.path!);
      });
    }
  }
}
