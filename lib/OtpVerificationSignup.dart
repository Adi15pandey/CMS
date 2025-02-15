import 'dart:convert';
import 'package:cms/GlobalServiceurl.dart';
import 'package:cms/Login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'Dashboardscreen.dart'; // Import your dashboard screen

class OtpVerificationSignup extends StatefulWidget {
  final String email;


  const OtpVerificationSignup({super.key, required this.email,});

  @override
  State<OtpVerificationSignup> createState() => _OtpVerificationSignupState();
}

class _OtpVerificationSignupState extends State<OtpVerificationSignup> {
  final TextEditingController _emailOtpController = TextEditingController();
  final TextEditingController _mobileOtpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _verifyOtp() async {
    if (_emailOtpController.text.isEmpty || _mobileOtpController.text.isEmpty) {
      setState(() => _errorMessage = "Both OTPs are required!");
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      var url = Uri.parse('${GlobalService.baseUrl}/api/auth/register');
      var headers = {'Content-Type': 'application/json'};

      var requestBody = {
        "email": widget.email.trim(),
        "mobileOtp": _mobileOtpController.text.trim(),
        "emailOtp": _emailOtpController.text.trim(),
      };

      print("🔹 Sending request to: $url");
      print("🔹 Request Body: ${jsonEncode(requestBody)}");

      var request = http.Request('POST', url);
      request.headers.addAll(headers);
      request.body = jsonEncode(requestBody);

      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print("🔹 Response Code: ${response.statusCode}");
      print("🔹 Response Body: $responseBody");

      if (response.statusCode == 201) {
        Map<String, dynamic> responseData = json.decode(responseBody);

        if (responseData['success'] == true) {

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Successfully Registered!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Delay before navigation
          await Future.delayed(Duration(seconds: 2));

          // Navigate to login page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        } else {
          setState(() => _errorMessage = responseData['message'] ?? "Invalid OTP.");
        }
      } else {
        setState(() => _errorMessage = "Server error: $responseBody");
      }
    } catch (e) {
      print("🔴 Error: $e");
      setState(() => _errorMessage = "An error occurred. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify OTP"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              "Enter the OTP sent to your email and mobile number.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            _buildOtpField("Email OTP", _emailOtpController),
            const SizedBox(height: 20),
            _buildOtpField("Mobile OTP", _mobileOtpController),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14)),
              ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : const Text("Verify", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black87),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      ),
    );
  }
}