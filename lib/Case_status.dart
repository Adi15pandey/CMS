import 'package:cms/Searchbar.dart';
import 'package:flutter/material.dart';

class CaseStatus extends StatefulWidget {
  const CaseStatus({super.key});

  @override
  State<CaseStatus> createState() => _CaseStatusState();
}

class _CaseStatusState extends State<CaseStatus> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    CaseSearchbar(),
    CaseSearchbar(),
    CaseSearchbar(),
    CaseSearchbar(),
    CaseSearchbar(),




    // Center(child: Text("Case Number Screen")),SearchBar(),
    // Center(child: Text("Filing Number Screen")),
    // Center(child: Text("FIR Number Screen")),
    // Center(child: Text("Case Type Screen")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Case Status"),
        backgroundColor: Color.fromRGBO(0, 74, 173, 1),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body:_screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "Party Name",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.numbers),
            label: "Case No",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: "Filing No",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: "FIR No",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel),
            label: "Case Type",
          ),
        ],
      ),
    );
  }
}
