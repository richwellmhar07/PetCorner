import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';


class EditPhoneNumberScreen extends StatefulWidget {
  final String currentPhoneNumber;
  final int userId;

  const EditPhoneNumberScreen({super.key, required this.currentPhoneNumber, required this.userId});

  @override
  State<EditPhoneNumberScreen> createState() => _EditPhoneNumberScreenState();
}

class _EditPhoneNumberScreenState extends State<EditPhoneNumberScreen> {
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.currentPhoneNumber);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updatePhoneNumber() async {
    const String apiUrl = 'http://192.168.1.19:5000/api/update_buyer_info';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'phonenumber': _phoneController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          Navigator.pop(context, _phoneController.text.trim());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number updated successfully!'),
              backgroundColor: Color.fromARGB(180, 86, 87, 86)
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update phone number: ${data['message'] ?? 'Unknown error'}'),
              backgroundColor: Color.fromARGB(180, 86, 87, 86)
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone number already registered!'),
            backgroundColor: Color.fromARGB(180, 86, 87, 86)
          ),
        );
      }
    } catch (e) {
      print('Error updating phone number: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
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
          'Edit Phone Number',
          style: TextStyle(
            fontSize: 17,
            color: Color.fromARGB(255, 88, 88, 88),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _updatePhoneNumber,
          ),
        ],
      ),
      
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: TextField(
          keyboardType: TextInputType.phone,
          controller: _phoneController,
          inputFormatters: [
            LengthLimitingTextInputFormatter(11),
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: '',
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.clear,
                size: 15,
              ),
              onPressed: () {
                _phoneController.clear();
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

