import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubcaseDetails extends StatefulWidget {
  final String cnrNumber;
  final String uploadedBy;
  final String id;
  final List<String> documentUrls; // List of document URLs
  final List<String> documentNames; // List of document names

  const SubcaseDetails({
    super.key,
    required this.cnrNumber,
    required this.id,
    required this.uploadedBy,
    required this.documentUrls,
    required this.documentNames,
  });

  @override
  State<SubcaseDetails> createState() => _SubcaseDetailsState();
}

class _SubcaseDetailsState extends State<SubcaseDetails> {
  final List<Map<String, dynamic>> _documents = [];
  final TextEditingController _documentNameController = TextEditingController();
  File? _selectedFile;
  String?token;
  bool isLoading =true;

  // Pick file using the file picker
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);

      setState(() {
        _selectedFile = file;  // Store the file in a state variable
      });
    } else {
      print("No file selected");
    }
  }
  @override
  void initState() {
    super.initState();
    _initializeData();
    _submitDocuments();
  }
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      _submitDocuments();
      // Fetch cases if the token is valid
    } else {
      setState(() {
        isLoading = false;
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


  // Submit documents to the server
  Future<void> _submitDocuments() async {
    if (_documents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one document")),
      );
      return;
    }

    final uri = Uri.parse("http://192.168.0.111:4001/api/document/add-more-document");
    final request = http.MultipartRequest('POST', uri)
      ..headers['token']= '$token'
      // ..headers['token'] = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzc4MTA5NCwiZXhwIjoxNzM3ODY3NDk0fQ.bbjGwrw-IuQtb8F3AHCTB-lcwGOvhMUy9hdKBpKaqpA'
      ..fields['cnrNumber'] = widget.cnrNumber
      ..fields['id'] = widget.id;

    for (var document in _documents) {
      request.files.add(await http.MultipartFile.fromPath(
        'files',
        document['file'].path,
      ));
      request.fields['fileNames'] = document['name'];
    }

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = jsonDecode(await response.stream.bytesToString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData['message'])),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload documents")),
      );
    }
  }

  // Add document to the list
  void _addDocument() {
    if (_documentNameController.text.isEmpty || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() {
      _documents.add({
        'name': _documentNameController.text,
        'file': _selectedFile,
      });
      _documentNameController.clear();
      _selectedFile = null;
    });
  }

  // Launch URL for downloading document
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open URL")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("CNR NUMBER: ${widget.cnrNumber}"),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display existing documents in a table
            if (widget.documentNames.isNotEmpty)
              Table(
                border: TableBorder.all(color: Colors.grey),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.purple[50]),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Document Name", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Uploaded By", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Download", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Display documents passed to this screen
                  ...List.generate(widget.documentNames.length, (index) {
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(widget.documentNames[index]),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(widget.uploadedBy),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: IconButton(
                            icon: const Icon(Icons.download, color: Colors.blue),
                            onPressed: () {
                              final Uri _url = Uri.parse(widget.documentUrls[index].toString());
                              launchUrl(_url);

                              // _launchURL(widget.documentUrls[index]);
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            const SizedBox(height: 20),
            // Input fields for adding new document
            TextField(
              controller: _documentNameController,
              decoration: const InputDecoration(
                labelText: "Document Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Choose file"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _addDocument,
              child: const Text(
                "+ Add Another Document",
                style: TextStyle(color: Colors.purple),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
        ElevatedButton(
          onPressed: _submitDocuments,
          child: const Text("Submit"),
        ),
      ],
    );
  }
}
