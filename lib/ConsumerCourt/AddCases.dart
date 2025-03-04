import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddConsumer extends StatefulWidget {
  const AddConsumer({super.key});

  @override
  State<AddConsumer> createState() => _AddConsumerState();
}

class _AddConsumerState extends State<AddConsumer> {
  final TextEditingController _caseNumberController = TextEditingController();
  final String token =
      'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTc0MTA2NDkzMiwiZXhwIjoxNzQxMTUxMzMyfQ.ju_2zjFFC0d3b3zPj6uoo1oFcnay8Huf7ZQrZmcJ__E';

  Future<void> searchCase(String caseNumber) async {
    final url = Uri.parse(
        '${GlobalService.baseUrl}/api/consumer-court/case/get-singleCase/$caseNumber');

    try {
      final response = await http.get(url, headers: {
        'token': token,
      });

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
    final validFormat = RegExp(r'^[A-Z]{2}/[A-Z]{2}/\d{2}/\d{4}\$');

    if (!validFormat.hasMatch(caseNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid case number in format XX/XX/XX/XXXX')),
      );
      return;
    }

    searchCase(caseNumber);
    addCase(caseNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Case Finder Using Case Number')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _caseNumberController,
              decoration: const InputDecoration(
                labelText: 'Case Number',
                hintText: 'XX/XX/XX/XXXX',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: handleAddCase,
              child: const Text('Add Case Number'),
            ),
          ],
        ),
      ),
    );
  }
}
