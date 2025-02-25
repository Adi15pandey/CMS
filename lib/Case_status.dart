import 'package:cms/Advocate.dart';
import 'package:cms/CaseNo.dart';
import 'package:cms/Casetype.dart';
import 'package:cms/Fillingno.dart';
import 'package:cms/Firnumber.dart';
import 'package:cms/Searchbar.dart';
import 'package:cms/partyname.dart';
import 'package:flutter/material.dart';

class CaseStatus extends StatefulWidget {
  const CaseStatus({super.key});

  @override
  State<CaseStatus> createState() => _CaseStatusState();
}

class _CaseStatusState extends State<CaseStatus> {
  int _selectedIndex = 0;
  String? selectedState;
  String? selectedStateName;
  String? selectedDistrict;
  String? selectedDistrictName;
  String? selectedCourt;
  String? selectedCourtName;
  String? selectedEstablishment;
  String? selectedEstablishmentName;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      Partyname(openFilterDialog: _openFilterDialog,selectedState: selectedState,
    selectedStateName: selectedStateName,
    selectedDistrict: selectedDistrict,
    selectedDistrictName: selectedDistrictName,
    selectedCourt: selectedCourt,
    selectedCourtName: selectedCourtName,
    selectedEstablishment: selectedEstablishment,
    selectedEstablishmentName:  selectedEstablishmentName,
    ),
      Caseno(openFilterDialog: _openFilterDialog),
      Fillingno(openFilterDialog: _openFilterDialog),
      AdvocateSearch(openFilterDialog: _openFilterDialog),
      CaseTypeSearch(openFilterDialog: _openFilterDialog),
      FirNumberScreen(openFilterDialog: _openFilterDialog),


      // CaseSearchbar(openFilterDialog: _openFilterDialog),
      // CaseSearchbar(openFilterDialog: _openFilterDialog),
      // CaseSearchbar(openFilterDialog: _openFilterDialog),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Case Status"),
        backgroundColor: Color.fromRGBO(0, 74, 173, 1),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // ✅ Filter Icon Button (Always Visible)
          IconButton(
            icon: Icon(Icons.filter_list), // Filter icon
            onPressed: () {
              _openFilterDialog(context);
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex], // ✅ Dynamic Content

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
            icon: Icon(Icons.pending_actions_sharp),
            label: "Advocate",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel),
            label: "Case Type",
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.local_police),
          //   label: "Fir No:",
          // ),
        ],
      ),
    );
  }
  void _openFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filter Cases",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context), // ✅ Close button
                      ),
                    ],
                  ),
                ),
                Divider(), // ✅ Visual separator
                Expanded(
                  child: CaseSearchbar(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
