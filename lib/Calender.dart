  import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

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

  final String token =
          "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3N2VhNTZiNzU1NGRhNWQ2YWExYWU3MSIsImlhdCI6MTczNzUyMDc3MiwiZXhwIjoxNzM3NjA3MTcyfQ.8YpCygR2uAjCn-yWPEwXG280Cf2Of3KOA_2xBtuIDCw";
  @override
  void initState() {
    super.initState();
    events = {};
    fetchData();
  }

  DateTime _parseDateWithOrdinalSuffix(String dateStr) {
    try {
      dateStr = dateStr.replaceAllMapped(RegExp(r'(\d+)(st|nd|rd|th)'), (match) {
        return match.group(1)!;
      });
      return DateFormat('d MMMM yyyy').parse(dateStr);
    } catch (e) {
      // debugPrint("Error parsing date: $e");
      return DateTime.now();
    }
  }

  Future<void> fetchData() async {
    const apiUrl = 'http://192.168.1.20:4001/api/cnr/get-cnr?pageLimit=1000000';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        // Cast the response to Map<String, dynamic>
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          Map<DateTime, List<dynamic>> tempEvents = {};

          for (var item in jsonResponse['data']) {
            // Cast each item to Map<String, dynamic>
            final Map<String, dynamic> itemMap = item as Map<String, dynamic>;

            final cnrNumber = itemMap['cnrNumber'];
            String? nextHearingDate;

            if (itemMap['caseStatus'] != null) {
              for (var status in itemMap['caseStatus']) {
                // Cast each status to List<dynamic>
                final List<dynamic> statusList = status as List<dynamic>;

                if (statusList[0] == "Next Hearing Date" && statusList[1].isNotEmpty) {
                  nextHearingDate = statusList[1];
                  break;
                }
              }
            }

            if (nextHearingDate != null) {
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
    return events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
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
                  return ListView(
                    shrinkWrap: true,
                    children: events
                        .map((event) {
                      // Cast the event to a Map<String, dynamic>
                      final eventData = event as Map<String, dynamic>;
                      return Text(
                        eventData['cnrNumber'] ?? 'N/A', // Safely access 'cnrNumber'
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      );
                    })
                        .toList(),
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
              itemCount: _getEventsForDay(_selectedDay).length,
              itemBuilder: (context, index) {
                // Explicitly cast event to Map<String, dynamic>
                final event = _getEventsForDay(_selectedDay)[index] as Map<String, dynamic>;

                return ListTile(
                  title: Text("CNR: ${event['cnrNumber']}"),
                  subtitle: Text(
                      "Case Status: ${event['caseStatus']}\nDate: ${event['caseDate']}"),
                );
              },
            )
                : const Center(
              child: Text('No events for this day'),
            ),
          ),

        ],
      ),
    );
  }
}
