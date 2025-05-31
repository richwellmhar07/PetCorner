import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditUsernameScreen extends StatefulWidget {
  final String currentUsername;
  final int userId;

  const EditUsernameScreen({super.key, required this.currentUsername, required this.userId});

  @override
  State<EditUsernameScreen> createState() => _EditUsernameScreenState();
}

class _EditUsernameScreenState extends State<EditUsernameScreen> {
  late TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _updateUsername() async {
    const String apiUrl = 'http://192.168.1.19:5000/api/update_buyer_info';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'username': _usernameController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          Navigator.pop(context, _usernameController.text.trim());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Username updated successfully!'),
              backgroundColor: Color.fromARGB(180, 86, 87, 86)
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update username: ${data['message'] ?? 'Unknown error'}'),
              backgroundColor: Color.fromARGB(180, 86, 87, 86)
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username already exist!'),
            backgroundColor: Color.fromARGB(180, 86, 87, 86)
          ),
        );
      }
    } catch (e) {
      print('Error updating username: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred.'),
          backgroundColor: Color.fromARGB(180, 86, 87, 86)
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 241, 241),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 245, 214, 37),
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Edit Username',
          style: TextStyle(
            fontSize: 17,
            color: Color.fromARGB(255, 88, 88, 88),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _updateUsername,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            hintText: '',
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.clear,
                size: 15,
              ),
              onPressed: () {
                _usernameController.clear();
              },
              splashRadius: 7,
            ),
            border: const UnderlineInputBorder(),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: Color.fromARGB(255, 79, 78, 78),
                width: 0.5,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: Color.fromARGB(255, 88, 88, 88),
                width: 0.8,
              ),
            ),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
