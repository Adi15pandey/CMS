import 'dart:convert';
import 'package:cms/GlobalServiceurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cms/Dashboardscreen.dart';

class OtpVerification extends StatefulWidget {
  final String email;

  OtpVerification({required this.email});

  @override
  _OtpVerificationState createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  final List<TextEditingController> _emailOtpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<TextEditingController> _mobileOtpControllers =
  List.generate(6, (_) => TextEditingController());

  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    String emailOtp = _getOtp(_emailOtpControllers);
    String mobileOtp = _getOtp(_mobileOtpControllers);

    if (emailOtp.isEmpty || mobileOtp.isEmpty) {
      _showMessage("Please enter the full OTP.");
      return;
    }

    print("Email OTP: $emailOtp, Mobile OTP: $mobileOtp");

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${GlobalService.baseUrl}/api/auth/login'),
        body: {
          'email': widget.email.toString(),
          'mobileOtp': mobileOtp.toString(),
          'emailOtp': emailOtp.toString(),
        },
      );

      final responseData = json.decode(response.body);
      print("Response: $responseData");

      if (response.statusCode == 200 && responseData['success'] == true) {
        String token = responseData['token'];

        // Save the token
        await saveToken(token);

        // Retrieve the token to check if it's saved correctly
        String savedToken = await _getSavedToken();
        print("Saved Token: $savedToken");

        if (savedToken.isNotEmpty) {
          print("Token is successfully saved.");
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Dashboardscreen()),
          );
        } else {
          _showMessage("Failed to save token.");
        }
      } else {
        _showMessage(responseData['message'] ?? "Invalid OTP");
      }
    } catch (e) {
      print("Error: $e");
      _showMessage("An error occurred. Please try again later.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

// Method to retrieve the saved token from SharedPreferences
  Future<String> _getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? ''; // Returns an empty string if token is not found
  }


  String _getOtp(List<TextEditingController> controllers) {
    return controllers.map((c) => c.text).join().trim().length == 6
        ? controllers.map((c) => c.text).join()
        : '';
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token); // Save with the exact key.
    print('Token saved: $token');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // import 'package:flutter/material.dart';

  Widget _buildOtpFields(List<TextEditingController> controllers) {
    List<FocusNode> focusNodes = List.generate(controllers.length, (index) => FocusNode());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(controllers.length, (index) {
        return SizedBox(
          width: 50,
          child: TextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            maxLength: 1,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: "",
              hintText: "-",
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < controllers.length - 1) {
                FocusScope.of(focusNodes[index].context!).requestFocus(focusNodes[index + 1]);
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(focusNodes[index].context!).requestFocus(focusNodes[index - 1]);
              }
            },
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("OTP Verification"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: SingleChildScrollView(  // Wrap the entire body inside a scroll view
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter the OTP sent to your email:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildOtpFields(_emailOtpControllers),
              SizedBox(height: 20),
              Text(
                "Enter the OTP sent to your mobile:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildOtpFields(_mobileOtpControllers),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Verify OTP",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    // Handle resend OTP action
                  },
                  child: Text(
                    "Resend OTP",
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
