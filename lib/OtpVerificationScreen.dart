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

        await saveToken(token);


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

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print("Token saved: $token");
  }

  Future<String> _getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('auth_token') ?? '';
    print("Token fetched: $token");
    return token;
  }


  String _getOtp(List<TextEditingController> controllers) {
    return controllers
        .map((c) => c.text)
        .join()
        .trim()
        .length == 6
        ? controllers.map((c) => c.text).join()
        : '';
  }

  bool _isResendingEmailOtp = false;
  bool _isResendingSmsOtp = false;

  Future<void> _resendEmailOtp() async {
    setState(() => _isResendingEmailOtp = true);

    try {
      final response = await http.post(
        Uri.parse('${GlobalService.baseUrl}/api/auth/resend-login-otp'),
        body: json.encode({"email": widget.email, "type": "email"}),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = json.decode(response.body);
      _showMessage(responseData['message'] ?? "Email OTP sent successfully.");
    } catch (e) {
      _showMessage("Network error: Unable to resend Email OTP.");
    } finally {
      setState(() => _isResendingEmailOtp = false);
    }
  }

  Future<void> _resendSmsOtp() async {
    setState(() => _isResendingSmsOtp = true);

    try {
      final response = await http.post(
        Uri.parse('${GlobalService.baseUrl}/api/auth/resend-login-otp'),
        body: json.encode({"email": widget.email, "type": "mobile"}),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = json.decode(response.body);
      _showMessage(responseData['message'] ?? "SMS OTP sent successfully.");
    } catch (e) {
      _showMessage("Network error: Unable to resend SMS OTP.");
    } finally {
      setState(() => _isResendingSmsOtp = false);
    }
  }


// Function to show messages (Snackbar)
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }


  Widget _buildOtpFields(List<TextEditingController> controllers) {
    List<FocusNode> focusNodes = List.generate(
        controllers.length, (index) => FocusNode());

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
                borderSide: const BorderSide(color: Color.fromRGBO(4, 163, 175, 1),),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < controllers.length - 1) {
                FocusScope.of(focusNodes[index].context!).requestFocus(
                    focusNodes[index + 1]);
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(focusNodes[index].context!).requestFocus(
                    focusNodes[index - 1]);
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
      body: Center( // Center the entire form
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                Text(
                  "Enter Confirmation Code",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(4, 163, 175, 1),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),

                Text(
                  "A 6-digit code was sent to:",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),

                // Display Email
                Text(
                  widget.email,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),

                // Email OTP Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Email OTP",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                _buildOtpFields(_emailOtpControllers),
                SizedBox(height: 12),

                // Resend Email OTP Button
                _isResendingEmailOtp
                    ? Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: CircularProgressIndicator(color:Color.fromRGBO(4, 163, 175, 1),),
                )
                    : Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: TextButton(
                    onPressed: _resendEmailOtp,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                      // shape: RoundedRectangleBorder(
                      //   borderRadius: BorderRadius.circular(8),
                      //   side: BorderSide(color: Colors.blue),
                      // ),
                    ),
                    child: Text(
                      "Resend Email OTP",
                      style: TextStyle(fontSize: 14, color: Color.fromRGBO(4, 163, 175, 1),),
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // SMS OTP Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "SMS OTP",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                _buildOtpFields(_mobileOtpControllers),
                SizedBox(height: 12),

                // Resend SMS OTP Button
                _isResendingSmsOtp
                    ? Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: CircularProgressIndicator(color: Color.fromRGBO(4, 163, 175, 1),),
                )
                    : Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: TextButton(
                    onPressed: _resendSmsOtp,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      // shape: RoundedRectangleBorder(
                      //   borderRadius: BorderRadius.circular(8),
                      //   side: BorderSide(color: Colors.blue),
                      // ),
                    ),
                    child: Text(
                      "Resend SMS OTP",
                      style: TextStyle(fontSize: 14, color: Color.fromRGBO(4, 163, 175, 1),),
                    ),
                  ),
                ),
                SizedBox(height: 40),

                // Verify OTP Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(4, 163, 175, 1),
                    padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Continue",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
