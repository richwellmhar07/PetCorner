import 'dart:convert';
import 'package:http/http.dart' as http;

const String BASE_URL = 'http://192.168.1.19:5000';

class EmailService {
  // Make the methods static

  // Check if the email already exists
  static Future<bool> checkEmailExistence(String email) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/check_email_existence'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['exists'] ?? false;
    } else {
      print('Error: ${response.body}');
      return false;
    }
  }

  // Send the verification code
  static Future<bool> sendVerificationCode(String email) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/send_verification_code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      print('Verification code sent successfully!');
      return true;
    } else {
      print('Failed to send code: ${response.body}');
      return false;
    }
  }

  // Verify the code
  static Future<bool> verifyCode(String email, String code) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/verify_code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode == 200) {
      print('Code verified successfully!');
      return true;
    } else {
      print('Invalid verification code: ${response.body}');
      return false;
    }
  }
}
