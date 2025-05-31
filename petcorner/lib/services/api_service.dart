import 'dart:convert';  // For JSON encoding/decoding
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.1.19:5000/api';  // Replace with your server IP

  // Login Function
  Future<Map<String, dynamic>> login(String username, String password) async {
    
    final Uri url = Uri.parse('http://192.168.1.19:5000/api/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "success": true,
          "user_id": data['user_id'],
          "role": data['role']
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          "success": false,
          "error": error['error']
        };
      }
    } catch (e) {
      return {
        "success": false,
        "error": "Failed to connect to the server"
      };
    }
  }
}
