import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditNameScreen extends StatefulWidget {
  final String currentName;
  final int userId;

  const EditNameScreen({super.key, required this.currentName, required this.userId});

  @override
  State<EditNameScreen> createState() => _EditNameScreenState();
}

class _EditNameScreenState extends State<EditNameScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
  }

  Future<void> _updateName() async {
    const String apiUrl = 'http://192.168.1.19:5000/api/update_buyer_info';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'name': _nameController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          Navigator.pop(context, _nameController.text);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Name updated successfully!'),
              backgroundColor: Color.fromARGB(180, 86, 87, 86)
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update name: ${data['message'] ?? 'Unknown error'}'),
              backgroundColor: Color.fromARGB(180, 86, 87, 86)
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect to the server.'),
            backgroundColor: Color.fromARGB(180, 86, 87, 86)
          ),
        );
      }
    } catch (e) {
      print('Error updating name: $e');
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
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 245, 214, 37),
        toolbarHeight: 70,
        title: const Text('Edit Name', style: TextStyle(fontSize: 17, color: Color.fromARGB(255, 88, 88, 88))),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _updateName,
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: '',
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.clear,
                size: 15,
              ),
              onPressed: () {
                _nameController.clear();
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
