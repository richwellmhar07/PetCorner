// // editbirthdate.dart
// import 'package:flutter/material.dart';

// class EditBirthdateScreen extends StatefulWidget {
//   @override
//   _EditBirthdateScreenState createState() => _EditBirthdateScreenState();
// }

// class _EditBirthdateScreenState extends State<EditBirthdateScreen> {
//   final TextEditingController _dobController = TextEditingController();
//   DateTime _selectedDate = DateTime.now();

//   @override
//   void dispose() {
//     _dobController.dispose();
//     super.dispose();
//   }

//   /// Opens the date picker dialog and updates the text field on selection.
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//         // Format date as MM/DD/YYYY
//         _dobController.text =
//             '${picked.month.toString().padLeft(2, '0')}/'
//             '${picked.day.toString().padLeft(2, '0')}/'
//             '${picked.year}';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Edit Birthdate', style: TextStyle(fontSize: 17, color: Color.fromARGB(255, 88, 88, 88))),
//         backgroundColor: Colors.yellow,
//         iconTheme: IconThemeData(color: const Color.fromARGB(255, 53, 53, 53)),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: GestureDetector(
//           onTap: () => _selectDate(context),
//           child: AbsorbPointer(
//             child: TextField(
//               controller: _dobController,
//               decoration: InputDecoration(
//                 labelText: 'Date of Birth',
//                 suffixIcon: Icon(Icons.calendar_today),
//                 border: UnderlineInputBorder(),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EditBirthdateScreen extends StatefulWidget {
  final String currentBirthdate;
  final int userId;

  const EditBirthdateScreen({
    super.key,
    required this.currentBirthdate,
    required this.userId,
  });

  @override
  _EditBirthdateScreenState createState() => _EditBirthdateScreenState();
}

class _EditBirthdateScreenState extends State<EditBirthdateScreen> {
  final TextEditingController _dobController = TextEditingController();
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Try to parse the current birthdate
    try {
      // Assuming format is MM/DD/YYYY or similar
      List<String> parts = widget.currentBirthdate.split('/');
      if (parts.length == 3) {
        int month = int.parse(parts[0]);
        int day = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        _selectedDate = DateTime(year, month, day);
      } else {
        _selectedDate = DateTime.now();
      }
    } catch (e) {
      // If parsing fails, default to today
      _selectedDate = DateTime.now();
      print('Error parsing birthday: $e');
    }

    // Set the initial text value
    _dobController.text = formatDate(_selectedDate);
  }

  @override
  void dispose() {
    _dobController.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // Format for database (YYYY-MM-DD format)
  String formatDateForDatabase(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Opens the date picker dialog and updates the text field on selection.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = formatDate(picked);
      });
    }
  }

  Future<void> _updateBirthdate() async {
    final String newBirthdate = _dobController.text;

    if (newBirthdate == widget.currentBirthdate) {
      // No changes, just return
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Format date for database: YYYY-MM-DD
    String birthdateForDb;
    try {
      birthdateForDb = formatDateForDatabase(_selectedDate);
    } catch (e) {
      birthdateForDb = newBirthdate; // Fallback to original format
      print('Error formatting date for database: $e');
    }

    // Create the request payload
    final Map<String, dynamic> requestData = {
      'user_id': widget.userId,
      'birthday': birthdateForDb, // Use database-friendly format
    };
    
    print('Sending update request: $requestData');

    try {
      // Make sure to use your actual API URL here
      final response = await http.post(
        Uri.parse('http://192.168.1.19:5000/api/update_buyer_info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        // Return the updated birthdate to the previous screen (in display format)
        Navigator.pop(context, newBirthdate);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to update birthdate')),
        );
      }
    } catch (e) {
      print('Error updating birthdate: $e');
      // Show error message for exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          'Edit Birthdate',
          style: TextStyle(
            fontSize: 17,
            color: Color.fromARGB(255, 88, 88, 88),
          ),
        ),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color.fromARGB(255, 88, 88, 88),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _updateBirthdate,
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Birthdate:',
              style: TextStyle(fontSize: 10, color: Color.fromARGB(255, 88, 88, 88)),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: _dobController,
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.calendar_today),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 79, 78, 78),
                        width: 0.3, // Thinner underline
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 88, 88, 88),
                        width: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}