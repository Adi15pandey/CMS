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
        title: const Text('Add Documents'),
        backgroundColor: Color.fromRGBO(0, 74, 173, 1),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCnrField(),
            const SizedBox(height: 16),
            _buildDocumentList(),
            const SizedBox(height: 20),
            _buildAddDocumentButton(),
            const SizedBox(height: 30),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCnrField() {
    return TextField(
      controller: cnrController,
      decoration: InputDecoration(
        labelText: 'CNR Number',
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      ),
    );
  }

  Widget _buildDocumentList() {
    return documents.isEmpty
        ? Center(
      child: Text(
        "No documents added yet.",
        style: TextStyle(fontSize: 16, color: Colors.black54),
      ),
    )
        : ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        return documents[index];
      },
    );
  }

  Widget _buildAddDocumentButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            documents.add(DocumentField());
          });
        },
        icon: Icon(Icons.add, color: Color.fromRGBO(0, 74, 173, 1),),
        label: Text(
          "Add Another Document",
          style: TextStyle(color: Color.fromRGBO(0, 74, 173, 1), fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: TextStyle(fontSize: 16)),
        ),
        ElevatedButton(
          onPressed: submitData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromRGBO(0, 74, 173, 1),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text("Submit", style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ],
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
            icon: Icon(Icons.upload_file, color: Colors.white),
            label: Text(widget.file == null ? 'Choose File' : 'Upload File', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromRGBO(0, 74, 173, 1), // Background color

            ),
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
