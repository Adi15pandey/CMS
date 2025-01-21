import 'package:cms/DocsScreen.dart';
import 'package:cms/Expired_task.dart';
import 'package:cms/Sub_Task.dart';
import 'package:cms/TaskScreen.dart';
import 'package:cms/Ticketscreen.dart';
import 'package:flutter/material.dart';

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({super.key});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Management'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
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
              leading: const Icon(Icons.document_scanner),
              title: const Text('Docs'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DocsPage())
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_box),
              title: const Text('Tasks'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=> Taskscreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning),
              title: const Text('Expired Tasks'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=> ExpiredTask()));  // Close the drawer
                // Add action to show expired tasks data
              },
            ),
            ListTile(
              leading: const Icon(Icons.subdirectory_arrow_right),
              title: const Text('Sub Tasks'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=> SubTask()));

                // Close the drawer
                // Add action to show sub-tasks data
              },
            ),
            ListTile(
              leading: const Icon(Icons.support),
              title: const Text('Ticket'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=> Ticketscreen()));  // Close the drawer
                // Add action to show ticket data
              },
            ),
          ],
        ),
      ),

        body: Center(
        child: const Text('Management'),
      ),
    );
  }
}
