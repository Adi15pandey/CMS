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
        backgroundColor: const Color.fromRGBO(0, 74, 173, 1),
        centerTitle: true,// Blue header
        title: const Text(
          'Management',

          style: TextStyle(color: Colors.white),

        ),
        iconTheme: const IconThemeData(
            color: Colors.white), // Back button color
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
                    imagePath: 'assets/images/contract_1358533 1.png', // PNG Image for Docs
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
                    imagePath: 'assets/images/list_3208615 1.png', // PNG Image for Docs
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
                    icon: Icons.warning_amber, // Expired Tasks Icon
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
                    icon: Icons.subtitles, // Sub Tasks Icon
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
                    imagePath: 'assets/images/ticket_13416591 1.png', // Tickets Icon
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
    String? imagePath, // Optional image path
    IconData? icon, // Optional icon
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
            color: Color.fromRGBO(189, 217, 255, 1), // Light Blue Border
            width: 2.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
          child: Row(
            children: [
              if (imagePath != null)
                Image.asset(imagePath, width: 40, height: 40) // PNG Image
              else
                if (icon != null)
                  Icon(icon, size: 40, color: Colors.black), // Black Icon
              const SizedBox(width: 30),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.black, // Text in Black
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
