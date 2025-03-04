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
        backgroundColor: const Color.fromRGBO(4, 163, 175, 1),
        centerTitle: true,// Blue header
        title: const Text(
          'Management',

          style: TextStyle(color: Colors.white),

        ),
        iconTheme: const IconThemeData(
            color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildCard(
                    context,
                    imagePath: 'assets/images/contract_1358533 1.png',
                    title: 'DOCS',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DocsPage()),
                      );
                    },
                  ),

                  _buildCard(
                    context,
                    imagePath: 'assets/images/list_3208615 1.png',
                    // Tasks Icon
                    title: 'TASKS',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Taskscreen()),
                      );
                    },
                  ),
                  _buildCard(
                    context,
                    icon: Icons.warning_amber,
                    title: 'EXPIRED TASKS',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ExpiredTask()),
                      );
                    },
                  ),
                  _buildCard(
                    context,
                    icon: Icons.subtitles,
                    title: 'SUB TASKS',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SubTask()),
                      );
                    },
                  ),
                  _buildCard(
                    context,
                    imagePath: 'assets/images/ticket_13416591 1.png',
                    title: 'TICKETS',
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
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {
    String? imagePath,
    IconData? icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(
            color: Color.fromRGBO(189, 217, 255, 1),
            width: 2.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
          child: Row(
            children: [
              if (imagePath != null)
                Image.asset(imagePath, width: 40, height: 40)
              else
                if (icon != null)
                  Icon(icon, size: 40, color: Colors.black),
              const SizedBox(width: 30),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
