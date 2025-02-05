import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late Map<DateTime, List<dynamic>> events;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  String?token;
  bool  _isLoading=true;

  // final String token = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczODQxMTkzNSwiZXhwIjoxNzM4NDk4MzM1fQ.SL3Vc-rFJIInPDEPbCrrz7OI8yStctjiGBMLA4lLv2M";

  @override
  void initState() {
    super.initState();
    _initializeData();
    events = {};
    fetchData();
  }

  Future<void> _initializeData() async {
    await _fetchToken();
    if (token != null && token!.isNotEmpty) {
      fetchData();

    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No token found. Please log in.")),
      );
    }
  }
  Future<void> _fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final savedToken = prefs.getString('auth_token');
    if (savedToken != null && savedToken.isNotEmpty) {
      setState(() {
        token = savedToken;
      });
    }
  }



  /// ✅ Fix: Parse date without time component
  DateTime _parseDateWithOrdinalSuffix(String dateStr) {
    try {
      // Remove "st", "nd", "rd", "th" from date string
      dateStr = dateStr.replaceAllMapped(RegExp(r'(\d+)(st|nd|rd|th)'), (match) {
        return match.group(1)!;
      });

      DateTime parsedDate = DateFormat('d MMMM yyyy').parse(dateStr);

      return DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    } catch (e) {
      debugPrint("Error parsing date: $e");
      return DateTime.now();
    }
  }

  Future<void> fetchData() async {
    final apiUrl = '${GlobalService.baseUrl}/api/cnr/get-cnr?pageLimit=1000000';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'token': '$token'        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          print(jsonResponse);
          Map<DateTime, List<dynamic>> tempEvents = {};

          for (var item in jsonResponse['data']) {
            final Map<String, dynamic> itemMap = item as Map<String, dynamic>;

            final cnrNumber = itemMap['cnrNumber'];
            String? nextHearingDate;

            if (itemMap['caseStatus'] != null) {
              for (var status in itemMap['caseStatus']) {
                final List<dynamic> statusList = status as List<dynamic>;

                if (statusList[0] == "Next Hearing Date" && statusList[1].isNotEmpty) {
                  nextHearingDate = statusList[1];
                  break;
                }
              }
            }

            if (nextHearingDate != null) {
              print("Next Hearing Date for CNR $cnrNumber: $nextHearingDate");

              DateTime date = _parseDateWithOrdinalSuffix(nextHearingDate);

              if (tempEvents[date] == null) {
                tempEvents[date] = [];
              }

              tempEvents[date]?.add({
                'cnrNumber': cnrNumber,
                'caseStatus': "Next Hearing Date",
                'caseDate': nextHearingDate,
              });
            }
          }

          setState(() {
            events = tempEvents;
          });
        }
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    DateTime normalizedDate = DateTime(day.year, day.month, day.day);
    return events[normalizedDate] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calender', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromRGBO(0, 74, 173, 1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: _getEventsForDay,
            availableGestures: AvailableGestures.all,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          for (var i = 0; i < events.length && i < 2; i++)
                            Text(
                              (events[i] as Map<String, dynamic>)['cnrNumber'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),

                          if (events.length > 2)
                            const Text(
                              'View More',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.yellow,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  );
                }
                return null;
              },
            ),

          ),
          const SizedBox(height: 10),
          Expanded(
            child: _getEventsForDay(_selectedDay).isNotEmpty
                ? ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              itemCount: _getEventsForDay(_selectedDay).length,
              itemBuilder: (context, index) {
                final event = _getEventsForDay(_selectedDay)[index] as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Color.fromRGBO(189, 217, 255, 1), // Light blue border color
                      width: 2, // Border width
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    title: Text(
                      "CNR: ${event['cnrNumber']}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(0, 74, 173, 1),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "Case Status: ${event['caseStatus']}\nDate: ${event['caseDate']}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color.fromRGBO(117, 117, 117, 1),
                          height: 1.5, // Improve line spacing
                        ),
                      ),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.event, color: Colors.blue),
                    ),
                  ),
                );
              },
            )
                : Center(
              child: Text(
                'No events for this day',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,  color: Color.fromRGBO(117, 117, 117, 1),),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
