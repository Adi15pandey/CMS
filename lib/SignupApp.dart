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
  List<String> roles = ["Company", "individual", "Advocate", "Bank"];

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
      appBar: AppBar(
        title: Text('Create an Account', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromRGBO(0, 74, 173, 1),
        centerTitle: true,
        iconTheme: const IconThemeData(
            color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Sign Up", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage())),
                child: Text("Already have an account? Log in", style: TextStyle(color: Colors.blue)),
              ),
              SizedBox(height: 20),

              buildInputField("Full Name", _fullNameController),
              buildInputField("Email Address", _emailController),
              buildInputField("Mobile Number", _mobileController),
              buildDropdownField("Select Role"),

              if (showCompanyFields) ...[
                buildInputField("Company Name"),
                buildInputField("Designation"),
                buildInputField("Company Address"),
              ],

              buildInputField("State", _stateController),
              buildInputField("Pincode", _pincodeController),
              buildInputField("District", _districtController),
              buildInputField("Address", _addressController),

              buildPasswordField("Password", _passwordController),
              buildPasswordField("Confirm Password", _confirmPasswordController),

              SizedBox(height: 20),

              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: sendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text("Next", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInputField(String hint, [TextEditingController? controller]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) => value!.isEmpty ? "$hint is required" : null,
      ),
    );
  }

  Widget buildDropdownField(String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        value: selectedRole,
        items: roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
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

  Widget buildPasswordField(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }


}