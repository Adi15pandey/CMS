import 'package:flutter/material.dart';
import 'dart:convert'; // For JSON parsing
import 'package:http/http.dart' as http;

class CaseRepository extends StatefulWidget {
  const CaseRepository({Key? key}) : super(key: key);

  @override
  State<CaseRepository> createState() => _CaseRepositoryState();
}

class _CaseRepositoryState extends State<CaseRepository> {
  List<dynamic> caseList = [];
  bool isLoading = false;

  String baseUrl = 'http://192.168.1.41:4001/api/cnr/get-cnr';

  // Function to fetch cases dynamically
  Future<void> fetchCases({
    required int pageNo,
    required int pageLimit,
    String filterText = '',
    int nextHearing = 0,
    int petitioner = 0,
    int respondent = 0,
  }) async {
    setState(() {
      isLoading = true;
    });

    final String url =
        '$baseUrl?pageNo=$pageNo&pageLimit=$pageLimit&filterText=$filterText&nextHearing=$nextHearing&petitioner=$petitioner&respondent=$respondent';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            caseList = data['data'];
          });
        } else {
          throw Exception('API response indicates failure');
        }
      } else {
        throw Exception('Failed to load cases');
      }
    } catch (e) {
      print('Error fetching cases: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCases(pageNo: 1, pageLimit: 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Repository'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : caseList.isEmpty
          ? const Center(child: Text('No cases found.'))
          : ListView.builder(
        itemCount: caseList.length,
        itemBuilder: (context, index) {
          final caseItem = caseList[index];
          return ListTile(
            title: Text(caseItem['cnrNumber'] ?? 'No CNR Number'),
            subtitle: Text(caseItem['status'] ?? 'No Status'),
            onTap: () {
              // Handle case item tap
              print('Case tapped: ${caseItem['_id']}');
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          fetchCases(
            pageNo: 1,
            pageLimit: 10,
            filterText: '',
            nextHearing: 1,
            petitioner: 0,
            respondent: 0,
          );
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
