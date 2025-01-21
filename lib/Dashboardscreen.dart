import 'package:cms/Management_screen.dart';
import 'package:flutter/material.dart';

class Dashboardscreen extends StatefulWidget {
  const Dashboardscreen({super.key});

  @override
  State<Dashboardscreen> createState() => _DashboardscreenState();
}

class _DashboardscreenState extends State<Dashboardscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      drawer: Drawer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Drawer header
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.black,
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo-cms-whire.png',
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

                    },
                  ),
                  ListTile(
                    title: const Text('Disposed Cases'),
                    onTap: () {

                    },
                  ),
                  ListTile(
                    title: const Text('Tracked Cases'),
                    onTap: () {

                    },
                  ),
                  ListTile(
                    title: const Text('Add Cases'),
                    onTap: () {

                    },
                  ),
                  ListTile(
                    title: const Text('Case Reminder'),
                    onTap: () {

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
                    title: const Text(''),
                    onTap: () {
                    },
                  ),
                  ListTile(
                    title: const Text(''),
                    onTap: () {
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

                    },
                  ),
                  ListTile(
                    title: const Text('User Directory'),
                    onTap: () {


                    },
                  ),
                ],
              ),
              ListTile(
                leading: const Icon(Icons.archive),
                title: const Text('Archive'),
                onTap: () {

                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Calendar'),
                onTap: () {

                },
              ),
              const SizedBox(height: 10),
              // Add a spacer for aesthetics or padding
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Setting'),
                onTap: () {
                  // Handle navigation
                },
              ),
            ],
          ),
        ),
      ),
      body: const Center(
        child: Text('Dashboard Content Goes Here'),
      ),
    );
  }
}
