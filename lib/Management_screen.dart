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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 cards per row
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
          ),
          children: [
            _buildCard(
              context,
              icon: Icons.document_scanner,
              title: 'Docs',
              color: Colors.blueAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DocsPage()),
                );
              },
            ),
            _buildCard(
              context,
              icon: Icons.check_box,
              title: 'Tasks',
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Taskscreen()),
                );
              },
            ),
            _buildCard(
              context,
              icon: Icons.warning,
              title: 'Expired Tasks',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExpiredTask()),
                );
              },
            ),
            _buildCard(
              context,
              icon: Icons.subdirectory_arrow_right,
              title: 'Sub Tasks',
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SubTask()),
                );
              },
            ),
            _buildCard(
              context,
              icon: Icons.support,
              title: 'Ticket',
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Ticketscreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: color.withOpacity(0.1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48.0, color: color),
              const SizedBox(height: 8.0),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
