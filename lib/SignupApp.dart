import 'package:flutter/material.dart';

class SignUpApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignUpPage(),
    );
  }
}

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  String? selectedRole;
  List<String> roles = ["Company", "Individual", "Advocate", "Bank"];

  // Dynamic Fields for "Company" and "Bank"
  bool showCompanyFields = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.black],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Create an account",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text("Already have an account? Log in",
                      style: TextStyle(color: Colors.blueAccent)),
                  SizedBox(height: 20),

                  // Input Fields
                  buildInputField(Icons.person, "Full Name"),
                  buildInputField(Icons.email, "Email Address"),
                  buildInputField(Icons.phone, "Mobile Number"),

                  // Role Dropdown
                  buildDropdownField(Icons.work, "Select Role"),

                  // Show extra fields if "Company" or "Bank" is selected
                  if (showCompanyFields) ...[
                    buildInputField(Icons.business, "Company Name"),
                    buildInputField(Icons.badge, "Designation"),
                    buildInputField(Icons.location_city, "Company Address"),
                  ],

                  // State & District
                  Row(
                    children: [
                      Expanded(child: buildInputField(Icons.map, "State")),
                      SizedBox(width: 10),
                      Expanded(child: buildInputField(Icons.location_city, "District")),
                    ],
                  ),

                  // Address & Pincode
                  buildInputField(Icons.home, "Address"),
                  buildInputField(Icons.pin, "Pincode"),

                  SizedBox(height: 20),

                  // Next Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Handle form submission
                      }
                    },
                    child: Text(
                      "Next",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Input Field Widget
  Widget buildInputField(IconData icon, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) => value!.isEmpty ? "$hint is required" : null,
      ),
    );
  }

  /// Dropdown Field Widget
  Widget buildDropdownField(IconData icon, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        style: TextStyle(color: Colors.white),
        dropdownColor: Colors.black,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        value: selectedRole,
        items: roles
            .map((role) => DropdownMenuItem(
          value: role,
          child: Text(role, style: TextStyle(color: Colors.white)),
        ))
            .toList(),
        onChanged: (value) {
          setState(() {
            selectedRole = value;
            showCompanyFields = (value == "Bank" || value == "Company");
          });
        },
        validator: (value) => value == null ? "Role is required" : null,
      ),
    );
  }
}
