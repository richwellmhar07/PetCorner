// import 'package:flutter/material.dart';

// class EditSexScreen extends StatefulWidget {
//   const EditSexScreen({super.key});

//   @override
//   State<EditSexScreen> createState() => _EditSexScreenState();
// }

// class _EditSexScreenState extends State<EditSexScreen> {
//   String _selectedGender = 'Male'; // Default selection

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 246, 241, 241),
//       appBar: AppBar(
//         backgroundColor: const Color.fromARGB(255, 245, 214, 37),
//         toolbarHeight: 70,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.pop(context); 
//           },
//         ),
//         title: const Text(
//           'Edit Sex',
//           style: TextStyle(
//             fontSize: 17,
//             color: Color.fromARGB(255, 88, 88, 88),
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.check),
//             onPressed: () {
//               // Save gender logic here
//               print('Selected gender: $_selectedGender');
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Select Sex:',
//               style: TextStyle(fontSize: 10, color: Color.fromARGB(255, 88, 88, 88)),
//             ),
//             DropdownButtonFormField<String>(
//               value: _selectedGender,
//               onChanged: (String? newValue) {
//                 setState(() {
//                   _selectedGender = newValue!;
//                 });
//               },
//               decoration: InputDecoration(
//                 contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
//                 enabledBorder: const UnderlineInputBorder(
//                   borderSide: BorderSide(
//                     color: Color.fromARGB(255, 79, 78, 78),
//                     width: 0.3, // Thinner underline
//                   ),
//                 ),
//                 focusedBorder: const UnderlineInputBorder(
//                   borderSide: BorderSide(
//                     color: Color.fromARGB(255, 88, 88, 88),
//                     width: 0.3, 
//                   ),
//                 ),
//               ),
//               items: <String>['Male', 'Female', 'Other']
//                   .map<DropdownMenuItem<String>>((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child: Text(value),
//                 );
//               }).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EditSexScreen extends StatefulWidget {
  final String currentGender;
  final int userId;

  const EditSexScreen({
    super.key, 
    required this.currentGender,
    required this.userId,
  });

  @override
  State<EditSexScreen> createState() => _EditSexScreenState();
}

class _EditSexScreenState extends State<EditSexScreen> {
  late String _selectedGender;
  bool _isLoading = false;
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    // Normalize the gender value to match dropdown options
    String normalizedGender = widget.currentGender.toLowerCase();
    if (normalizedGender == "male") {
      _selectedGender = "Male";
    } else if (normalizedGender == "female") {
      _selectedGender = "Female";
    } else if (normalizedGender == "other") {
      _selectedGender = "Other";
    } else {
      // Default to Male if the current gender doesn't match any option
      _selectedGender = "Male";
    }
  }

  Future<void> _updateGender() async {
    // Convert the selected gender to match database format if needed
    final genderForDb = _selectedGender; // Use as is by default

    if (genderForDb.toLowerCase() == widget.currentGender.toLowerCase()) {
      // No changes, just return
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.19:5000/api/update_buyer_info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'gender': genderForDb,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        // Return the updated gender to the previous screen
        Navigator.pop(context, genderForDb);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Failed to update gender'),
            backgroundColor: Color.fromARGB(180, 86, 87, 86)
          ),
        );
      }
    } catch (e) {
      // Show error message for exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Color.fromARGB(180, 86, 87, 86)
        ),
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
          'Edit Sex',
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
                  onPressed: _updateGender,
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Sex:',
              style: TextStyle(fontSize: 10, color: Color.fromARGB(255, 88, 88, 88)),
            ),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                }
              },
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 10.0),
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
              items: _genderOptions
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}