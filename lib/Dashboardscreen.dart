
import 'package:cms/GlobalServiceurl.dart';
import 'package:cms/Logout.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pie_chart/pie_chart.dart';
import 'dart:convert';
import 'package:cms/Add_Directory.dart';
import 'package:cms/Add_User.dart';
import 'package:cms/Add_cases.dart';
import 'package:cms/Archieve.dart';
import 'package:cms/Calender.dart';
import 'package:cms/CaseResearcher.dart';
import 'package:cms/Case_repository.dart';
import 'package:cms/Disposed_cases.dart';
import 'package:cms/Management(Sub-cases).dart';
import 'package:cms/Management_screen.dart';
import 'package:cms/Setting.dart';
import 'package:cms/Subcases_CASERepositorty.dart';
import 'package:cms/Tracked_cases.dart';
import 'package:cms/subdisposedcases.dart';
import 'package:flutter/material.dart';


class Dashboardscreen extends StatefulWidget {
  const Dashboardscreen({super.key});

  @override
  State<Dashboardscreen> createState() => _DashboardscreenState();
}

class _DashboardscreenState extends State<Dashboardscreen> {
  int allCases = 0;
  int activeCases = 0;
  int disposedCases = 0;
  bool isLoading = true;

  String? newtoken;
  bool  _isLoading=true;

  @override
  void initState() {
    super.initState();
    //_fetchToken();
    fetchCasesData();



  }

  Future<void> fetchCasesData() async {
    print("833333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
    final prefs = await SharedPreferences.getInstance();
    // Ensure we fetch the latest data

    final savedToken = prefs.getString('auth_token');
    if (savedToken != null && savedToken.isNotEmpty) {
      setState(() {
        newtoken = savedToken;
      });
      print('Token fetched successfully: $newtoken');
    } else {
      print('Token not found');
    }
    try {
      final token = newtoken.toString();
      print('My api token: $newtoken');



      final responses = await Future.wait([
        http.get(
          Uri.parse('${GlobalService.baseUrl}/api/cnr/get-cnr?currentPage=1&pageLimit=100000000'),
          headers: {'token': '$token'},
        ),
        http.get(
          Uri.parse('${GlobalService.baseUrl}/api/cnr/get-disposed-cnr?currentPage=1&pageLimit=100000000'),
          headers: {'token': '$token'},
        ),
      ]);
      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        // Decode the response bodies
        final activeData = json.decode(responses[0].body)['data'] ?? [];
        final disposedData = json.decode(responses[1].body)['data'] ?? [];


        final finalData = [...activeData, ...disposedData];


        setState(() {
          activeCases = activeData.length;
          disposedCases = disposedData.length;
          allCases = finalData.length;
          isLoading = false;
        });
        List<String> activeCnrNumbers = activeData
            .map<String>((caseData) {

          var cnrNumber = caseData['cnrNumber'];
          return (cnrNumber != null && cnrNumber is String) ? cnrNumber : '';
        })
            .where((cnrNumber) {

          return cnrNumber != null && cnrNumber.isNotEmpty;
        }).toList();

        print('Active CNR Numbers: ${activeCnrNumbers.join(', ')}');

      } else {

        throw Exception('Failed to load cases');
      }
    } catch (error) {
      print('Error: $error');
      setState(() {
        isLoading = false;
        activeCases = 0;
        disposedCases = 0;
        allCases = 0;
      });

    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text('Dashboard'),
      ),
      drawer: Drawer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/thumbnail_CMS  RECQARZ.2.jpg',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                onTap: () {

                },
              ),
              ExpansionTile(
                leading: const Icon(Icons.gavel),
                title: const Text('Litigation'),
                children: [
                  ListTile(
                    title: const Text('Case Repository'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => MyCouncil()));



                    },
                  ),
                  ListTile(
                    title: const Text('Disposed Cases'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => DisposedCases()));



                    },
                  ),
                  ListTile(
                    title: const Text('Tracked Cases'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Trackedcases()));


                    },
                  ),
                  ListTile(
                    title: const Text('Add Cases'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => CnrSearchScreen()));



                    },
                  ),
                  ListTile(
                    title: const Text('Case Researcher'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Caseresearcher()));


                    },
                  ),
                  ListTile(
                    title: const Text('Management'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ManagementScreen()));


                    },
                  ),
                ],
              ),
              ExpansionTile(
                leading: const Icon(Icons.cases),
                title: const Text('Sub-Cases'),
                children: [
                  ListTile(
                    title: const Text('Case Repository'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SubcasesCaserepository()));


                    },
                  ),
                  ListTile(
                    title: const Text('Disposed Cases'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SubDisposedCases()));


                    },
                  ),
                  ListTile(
                    title: const Text('Management'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SubcasesManagement()));


                    },
                  ),

                ],
              ),
              ExpansionTile(
                leading: const Icon(Icons.people),
                title: const Text('Users'),
                children: [
                  ListTile(
                    title: const Text('Add User'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AddAdvocateDialog()));


                    },
                  ),
                  ListTile(
                    title: const Text('User Directory'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AddDirectory()));




                    },
                  ),
                ],
              ),
              ListTile(
                leading: const Icon(Icons.archive),
                title: const Text('Archive'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Archieve()));



                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Calendar'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => CalendarPage()));


                },
              ),
              const SizedBox(height: 10),
              // Add a spacer for aesthetics or padding
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Setting'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Setting()));


                  // Handle navigation
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Logout()));


                  // Handle navigation
                },
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Case Analytics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCaseCard(
                    'All Cases', allCases, Icons.folder, Colors.amber),
                _buildCaseCard(
                    'Active Cases', activeCases, Icons.local_fire_department_outlined, Colors.red),
                _buildCaseCard(
                    'Disposed Cases', disposedCases, Icons.ios_share, Colors.green),
              ],
            ),
            const SizedBox(height: 32),
            _buildCasePieChart(context),

          ],
        ),
      ),
    );
  }

  Widget _buildCaseCard(String title, int count, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Color(0xFF63608e),
      elevation: 4,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.28,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCasePieChart(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PieChart(
            dataMap: _buildPieChartData(),
            chartType: ChartType.ring,
            colorList: [
              Colors.green,Colors.red
            ],
            chartRadius: MediaQuery.of(context).size.width / 1.2,
            centerText: '$allCases\nAll Cases',
            legendOptions: const LegendOptions(
              legendPosition: LegendPosition.left,
              showLegends: true,
            ),
            ringStrokeWidth: 32,
            chartValuesOptions: const ChartValuesOptions(
              showChartValues: false,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _buildPieChartData() {
    int total = activeCases + disposedCases;

    if (total == 0) {
      return {};
    }

    return {
      'Active Cases': (activeCases / total) * 100,
      'Disposed Cases': (disposedCases / total) * 100,
    };
  }


  // Build Legend Item
}

