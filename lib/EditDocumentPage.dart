import 'dart:io'; // For File class
import 'package:cms/GlobalServiceurl.dart';
import 'package:file_picker/file_picker.dart'; // For file picking functionality
import 'package:http/http.dart' as http; // For HTTP requests
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';// For launching URLs

class EditDocumentPage extends StatefulWidget {
  final String cnrNumber;
  final String uploadedBy;
  final String url;

  EditDocumentPage({
    required this.cnrNumber,
    required this.uploadedBy,
    required this.url,
  });

  @override
  _EditDocumentPageState createState() => _EditDocumentPageState();
}

class _EditDocumentPageState extends State<EditDocumentPage> {
  List<DocumentCard> _documentCards = [];
  String?token;
  bool  _isLoading=true;

  @override
  void initState() {
    super.initState();
    _initializeData();

    _addNewDocumentCard();
    // _fetchDocumentDetails();
  }
  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch the token first
    if (token != null && token!.isNotEmpty) {
      _addNewDocumentCard();
      _submitDocuments();// Fetch cases if the token is valid
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

  Future<void> _uploadFile(int index) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() {
        _documentCards[index].uploadedFile = file;
      });
      print("File uploaded: ${file.path}");
    }
  }

  void _addNewDocumentCard() {
    setState(() {
      _documentCards.add(
        DocumentCard(
          index: _documentCards.length,
          onUploadFile: (index) => _uploadFile(index),
          onRemoveCard: (index) => _removeDocumentCard(index),
        ),
      );
    });
  }
  void _removeDocumentCard(int index) {
    setState(() {
      _documentCards.removeAt(index);
      for (int i = 0; i < _documentCards.length; i++) {
        _documentCards[i] = DocumentCard(
          index: i,
          onUploadFile: (index) => _uploadFile(index),
          onRemoveCard: (index) => _removeDocumentCard(index),
        );
      }
    });
  }
  Future<void> _submitDocuments() async {
    try {
      for (var card in _documentCards) {
        if (card.uploadedFile == null || card.documentName.isEmpty) {
          print("Skipping incomplete document entry.");
          continue;
        }

        // Create a multipart request
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${GlobalService.baseUrl}/api/document/add-more-document'),
        );

        // Add headers
        request.headers['token'] = '$token';

        // Add fields
        request.fields.addAll({
          'cnrNumber': widget.cnrNumber,
          'id': 'widget.id', // Replace with dynamic ID if needed
          'fileNames': card.documentName,
        });

        // Add the file
        request.files.add(await http.MultipartFile.fromPath(
          'files',
          card.uploadedFile!.path,
        ));

        // Send the request
        var response = await request.send();

        if (response.statusCode == 200) {
          var responseBody = await response.stream.bytesToString();
          print("Document submitted successfully: $responseBody");
        } else {
          print(
            "Failed to submit document: ${response.statusCode} - ${response.reasonPhrase}",
          );
          var errorBody = await response.stream.bytesToString();
          print("Error Response Body: $errorBody");
        }
      }

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Documents submitted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      print("An error occurred: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Document'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CNR Number: ${widget.cnrNumber}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Uploaded By',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      readOnly: true,
                      controller: TextEditingController(text: widget.uploadedBy),
                    ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final Uri _url = Uri.parse(widget.url.toString());
                        launchUrl(_url);
                      },
                      child: Row(
                        children: [
                          Icon(Icons.link, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Open Document',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ..._documentCards,
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addNewDocumentCard,
              icon: Icon(Icons.add),
              label: Text('Add Another Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: Size(double.infinity, 48),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitDocuments,
                    child: Text('Submit'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Close'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentCard extends StatelessWidget {
  final int index;
  final Function(int) onUploadFile;
  final Function(int) onRemoveCard;
  final TextEditingController _documentNameController = TextEditingController();
  File? uploadedFile;

  DocumentCard({
    Key? key,
    required this.index,
    required this.onUploadFile,
    required this.onRemoveCard,
  }) : super(key: key);

  String get documentName => _documentNameController.text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Document ${index + 1}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () => onRemoveCard(index), // Call to remove the card
                ),
              ],
            ),
            SizedBox(height: 8),
            TextField(
              controller: _documentNameController,
              decoration: InputDecoration(
                labelText: 'Document Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => onUploadFile(index),
              icon: Icon(Icons.upload_file),
              label: Text('Upload File'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }
}

