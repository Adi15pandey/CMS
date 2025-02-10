import 'package:cms/GlobalServiceurl.dart';
import 'package:cms/Login.dart';
import 'package:cms/OtpVerificationSignup.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}
class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  String?   selectedRole;
  List<String> roles = ["Company", "Individual", "Advocate", "Bank"];

  bool showCompanyFields = false;
  bool _isLoading = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _districtController= TextEditingController();
  final TextEditingController _addressController= TextEditingController();


  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pincodeController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Passwords do not match!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_emailController.text.trim().isEmpty || _mobileController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Email and Mobile number are required!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var headers = {'Content-Type': 'application/json'};

      var requestBody = {
        "name": _fullNameController.text.trim(),
        "email": _emailController.text.trim(),
        "mobile": _mobileController.text.trim(),
        "password": _passwordController.text.trim(),
        "confirmPassword": _confirmPasswordController.text.trim(),
        "role": selectedRole ?? "individual" ,
        "state": _stateController.text.trim(),
        "pinCode": _pincodeController.text.trim(),
        "district": _districtController.text.trim(),
        "address": _addressController.text.trim(),
        "bankAddress": "",
        "bankName": "",
        "companyAddress": "",
        "companyName": "",
        "userDegisnation": ""
      };

      print("Sending request to: ${GlobalService.baseUrl}/api/auth/temp-register");
      print("Request Body: ${jsonEncode(requestBody)}");

      var response = await http.post(
        Uri.parse('${GlobalService.baseUrl}/api/auth/temp-register'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success']) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationSignup(
              email: _emailController.text,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? "Failed to send OTP"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      print("Error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong! Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


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
                  SizedBox(height: 10),
                  Text(
                    "Create an account",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    child: Text(
                      "Already have an account? Log in",
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),

                  SizedBox(height: 20),

                  buildInputField(
                      Icons.person, "Full Name", _fullNameController),
                  buildInputField(
                      Icons.email, "Email Address", _emailController),
                  buildInputField(
                      Icons.phone, "Mobile Number", _mobileController),
                  buildDropdownField(Icons.work, "Select Role"),

                  if (showCompanyFields) ...[
                    buildInputField(Icons.business, "Company Name"),
                    buildInputField(Icons.badge, "Designation"),
                    buildInputField(Icons.location_city, "Company Address"),
                  ],

                  buildInputField(
                      Icons.location_city, "State", _stateController),
                  buildInputField(Icons.pin, "Pincode", _pincodeController),
                  buildInputField(Icons.offline_bolt, "District",_districtController),
                  buildInputField(Icons.ice_skating, "Address",_addressController),

                  buildPasswordField(
                      Icons.lock, "Password", _passwordController),
                  buildPasswordField(Icons.lock_outline, "Confirm Password",
                      _confirmPasswordController),


                  SizedBox(height: 20),

                  _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(
                          horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: sendOTP,
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

  Widget buildInputField(IconData icon, String hint,
      [TextEditingController? controller]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
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
            .map((role) =>
            DropdownMenuItem(
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

  Widget buildPasswordField(IconData icon, String hint,
      TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: true,
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
      ),
    );
  }

}