
import 'package:cms/Case_status.dart';
import 'package:cms/DigitalIntiative.dart';
import 'package:cms/GlobalServiceurl.dart';
import 'package:cms/Logout.dart';
import 'package:cms/View_report.dart';
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
        title: Text(
            '', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromRGBO(0, 74, 173, 1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer:Drawer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.white),
                child: Center(
                  child: Image.asset(
                    'assets/images/CMS  RECQARZ (5).png',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Dashboard
              ListTile(
                leading: const Icon(Icons.dashboard, color: Colors.black54),
                title: const Text('Dashboard', style: TextStyle(fontSize: 16)),
                onTap: () {

                },
              ),
              ExpansionTile(
                leading: const Icon(Icons.gavel, color: Colors.black54),
                title: const Text('Litigation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                children: [
                  _buildDrawerSubItem(context, 'Case Repository', MyCouncil()),
                  _buildDrawerSubItem(context, 'Disposed Cases', DisposedCases()),
                  _buildDrawerSubItem(context, 'Tracked Cases', Trackedcases()),
                  _buildDrawerSubItem(context, 'Add Cases', CnrSearchScreen()),
                  _buildDrawerSubItem(context, 'Case Researcher', Caseresearcher()),
                  _buildDrawerSubItem(context, 'Management', ManagementScreen()),
                ],
              ),

              // Sub-Cases Section
              ExpansionTile(
                leading: const Icon(Icons.cases, color: Colors.black54),
                title: const Text('Sub-Cases', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                children: [
                  _buildDrawerSubItem(context, 'Case Repository', SubcasesCaserepository()),
                  _buildDrawerSubItem(context, 'Disposed Cases', SubDisposedCases()),
                  _buildDrawerSubItem(context, 'Management', SubcasesManagement()),
                ],
              ),

              // Users Section
              ExpansionTile(
                leading: const Icon(Icons.people, color: Colors.black54),
                title: const Text('Users', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                children: [
                  _buildDrawerSubItem(context, 'Add User', AddAdvocateDialog()),
                  _buildDrawerSubItem(context, 'User Directory', AddDirectory()),
                ],
              ),

              const Divider(),

              _buildDrawerItem(context, Icons.archive, 'Archive', Archieve()),
              _buildDrawerItem(context, Icons.people_alt_outlined, 'Digital Initiative', Digitalintiative()),
              _buildDrawerItem(context, Icons.people_alt_outlined, 'Case Status', CaseStatus()),

              // _buildDrawerItem(context, Icons.bar_chart, 'View Report', ViewReport()),
              _buildDrawerItem(context, Icons.calendar_today, 'Calendar', CalendarPage()),

              const Divider(),

              _buildDrawerItem(context, Icons.settings, 'Settings', Setting()),
              _buildDrawerItem(context, Icons.logout, 'Logout', LogoutScreen()),
            ],
          ),
        ),
      ),
      body:
      isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Case Analytics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Make the horizontal scrollable row inside the same SingleChildScrollView
              SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Horizontal scrolling
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCaseCard(
                        'All Cases', allCases, Icons.folder, Colors.blue),
                    _buildCaseCard(
                        'Active Cases', activeCases, Icons.local_fire_department_outlined, Colors.green),
                    _buildCaseCard(
                        'Disposed Cases', disposedCases, Icons.ios_share, Color.fromRGBO(
                        234, 72, 72, 1.0)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildCasePieChart(context),
              const SizedBox(height: 30),
              _buildCaseStatistics(),
            ],
          ),
        ),

      ),

    );
  }
  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }

  Widget _buildDrawerSubItem(BuildContext context, String title, Widget page) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }

  Widget _buildCaseCard(String title, int count, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color,  // Use the passed color
      elevation: 4,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.28,
        height: 155,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCasePieChart(BuildContext context) {
    return SizedBox(
      height: 130,
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
  Widget _buildCaseStatistics() {
    int totalCases = activeCases + disposedCases;
    double activePercentage = (activeCases / totalCases) * 100;
    double disposedPercentage = (disposedCases / totalCases) * 100;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(
          color: Color.fromRGBO(189, 217, 255, 1), // Light Blue Border
          width: 2.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Case Statistics",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16),

            // Active Cases Progress Bar
            Text(
              "Active Cases",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: Duration(seconds: 1),
                    width: activePercentage * 2, // Adjusted for proper scaling
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green, Colors.greenAccent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          "${activePercentage.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            // color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              "Disposed Cases",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: Duration(seconds: 1),
                    width: disposedPercentage * 2, // Adjusted for proper scaling
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red, Colors.redAccent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          "${disposedPercentage.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            // color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Additional case statistics text (optional)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                // decoration: BoxDecoration(
                //   color: Colors.white,
                //   borderRadius: BorderRadius.circular(12),
                //   boxShadow: [
                //     BoxShadow(
                //       color: Colors.blue.withOpacity(0.2),
                //       blurRadius: 6,
                //       offset: Offset(0, 2),
                //     ),
                //   ],
                // ),
                child: Column(
                  children: [
                    Text(
                      "Total Cases: ${(activeCases + disposedCases)}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Total Active Cases: $activeCases",
                      style: TextStyle(fontSize: 14, color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Total Disposed Cases: $disposedCases",
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

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

