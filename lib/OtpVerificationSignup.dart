import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'Dashboardscreen.dart'; // Import your dashboard screen

class OtpVerificationSignup extends StatefulWidget {
  final String email;

  const OtpVerificationSignup({super.key, required this.email});

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
      final response = await http.post(
        Uri.parse("http://192.168.0.187:4002/api/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "emailOtp": _emailOtpController.text.trim(),
          "mobileOtp": _mobileOtpController.text.trim(),
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // OTP Verified, navigate to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboardscreen()),
        );
      } else {
        setState(() => _errorMessage = responseData['message'] ?? "Invalid OTP.");
      }
    } catch (e) {
      setState(() => _errorMessage = "An error occurred. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP"), backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOtpField("Enter Email OTP", _emailOtpController),
            const SizedBox(height: 20),
            _buildOtpField("Enter Mobile OTP", _mobileOtpController),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14)),
              ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : const Text("Verify", style: TextStyle(color: Colors.white)),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
