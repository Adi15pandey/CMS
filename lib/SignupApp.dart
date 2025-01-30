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
  String? selectedRole;
  List<String> roles = ["Company", "Individual", "Advocate", "Bank"];

  bool showCompanyFields = false;
  int currentStep = 0;
  bool _isLoading =true;


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
                  // Progress Stepper


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
                  Text("Already have an account? Log in",
                      style: TextStyle(color: Colors.blueAccent)),
                  SizedBox(height: 20),

                  buildInputField(Icons.person, "Full Name"),
                  buildInputField(Icons.email, "Email Address"),
                  buildInputField(Icons.phone, "Mobile Number"),
                  buildDropdownField(Icons.work, "Select Role"),

                  if (showCompanyFields) ...[
                    buildInputField(Icons.business, "Company Name"),
                    buildInputField(Icons.badge, "Designation"),
                    buildInputField(Icons.location_city, "Company Address"),
                  ],

                  Row(
                    children: [
                      Expanded(child: buildInputField(Icons.map, "State")),
                      SizedBox(width: 10),
                      Expanded(child: buildInputField(Icons.location_city, "District")),
                    ],
                  ),

                  buildInputField(Icons.home, "Address"),
                  buildInputField(Icons.pin, "Pincode"),

                  SizedBox(height: 20),

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
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> PasswordScreen(email: "")));
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

  Widget buildStep(String label, int step) {
    bool isActive = currentStep >= step;
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? Colors.blueAccent : Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white),
          ),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }


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


class PasswordScreen extends StatefulWidget {
  final String email;
  const PasswordScreen({super.key,required this.email});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;
  bool _isLoading =true;

  void _validateAndProceed() async {
    if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Both fields are required!";
        _isLoading = false;
      });
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Passwords do not match!";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      print("🔄 Sending API request...");

      final response = await http
          .post(
        Uri.parse("http://192.168.0.187:4002/api/auth/temp-register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "password": _passwordController.text.trim(),
        }),
      )
          .timeout(const Duration(seconds: 10));

      print("✅ API responded: ${response.statusCode}");

      final responseData = json.decode(response.body);
      print("📩 Response data: $responseData");

      if (response.statusCode == 200 && responseData['success'] == true) {
        print("🎉 Registration successful! Navigating to OTP screen...");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationSignup(email: widget.email),
          ),
        );
      } else {
        print("❌ Registration failed: ${responseData['message']}");
        setState(() => _errorMessage = responseData['message'] ?? "Registration failed.");
      }
    } catch (e) {
      print("🚨 Error: $e");
      setState(() => _errorMessage = "An error occurred. Please try again.");
    } finally {
      print("🔄 Stopping loading animation.");
      setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Password"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPasswordField("Enter Password", _passwordController, true),
            const SizedBox(height: 20),
            _buildPasswordField("Confirm Password", _confirmPasswordController, false),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text("Back", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed:  _validateAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child
                      : const Text("Next", style: TextStyle(color: Colors.white)),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool isPasswordField) {
    return TextField(
      controller: controller,
      obscureText: isPasswordField ? !_isPasswordVisible : !_isConfirmPasswordVisible,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: IconButton(
          icon: Icon(
            (isPasswordField ? _isPasswordVisible : _isConfirmPasswordVisible)
                ? Icons.visibility
                : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              if (isPasswordField) {
                _isPasswordVisible = !_isPasswordVisible;
              } else {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              }
            });
          },
        ),
      ),
    );
  }
}

