import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CaseDetailsScreen extends StatefulWidget {
  final String cnr;

  const CaseDetailsScreen({Key? key, required this.cnr}) : super(key: key);

  @override
  _CaseDetailsScreenState createState() => _CaseDetailsScreenState();
}

class _CaseDetailsScreenState extends State<CaseDetailsScreen> {
  late Future<Map<String, dynamic>> caseData;

  @override
  void initState() {
    super.initState();
    caseData = fetchCaseDetails(widget.cnr);
  }

  Future<Map<String, dynamic>> fetchCaseDetails(String cnr) async {
    final url = '${GlobalService.baseUrl}/api/cnr/get-singlecnr/$cnr';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load case details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Case Details"),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: caseData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No case details available.'));
          } else {
            final caseDetails = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Case Details Section
                  const SectionHeader(title: 'Case Details'),
                  CaseDetailRow(
                    label: 'CNR Number',
                    value: caseDetails['caseDetails']['CNR Number'] ?? 'N/A',
                  ),
                  CaseDetailRow(
                    label: 'Case Type',
                    value: caseDetails['caseDetails']['Case Type'] ?? 'N/A',
                  ),
                  CaseDetailRow(
                    label: 'Filing Date',
                    value: caseDetails['caseDetails']['Filing Date'] ?? 'N/A',
                  ),
                  CaseDetailRow(
                    label: 'Registration Date',
                    value: caseDetails['caseDetails']['Registration Date:'] ?? 'N/A',
                  ),
                  CaseDetailRow(
                    label: 'Registration Number',
                    value: caseDetails['caseDetails']['Registration Number'] ?? 'N/A',
                  ),

                  // Interim Orders Section
                  const SectionHeader(title: 'Interim Orders'),
                  ...List.generate(
                    caseDetails['intrimOrders'].length,
                        (index) {
                      final order = caseDetails['intrimOrders'][index];
                      return OrderCard(order: order);
                    },
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

// Section Header Widget
class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Case Detail Row Widget
class CaseDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const CaseDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

// Order Card Widget
class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Date: ${order['order_date'] ?? 'N/A'}'),
            Text('Summary: ${order['summary']?.join(', ') ?? 'N/A'}'),
            Text('Judge: ${order['judgeName'] ?? "Unknown"}'),
            if (order['s3_url'] != null)
              GestureDetector(
                onTap: () {

                },
                child: const Text(
                  'View Order PDF',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
