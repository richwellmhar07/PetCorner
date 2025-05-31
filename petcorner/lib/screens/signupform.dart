import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login.dart';
import 'courierform.dart'; 
import 'signup.dart';

class SignupFormScreen extends StatefulWidget {
  final String email;

  const SignupFormScreen({super.key, required this.email});

  @override
  _SignupFormScreenState createState() => _SignupFormScreenState();
}

class _SignupFormScreenState extends State<SignupFormScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedRole = 'buyer';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Password checklist booleans
  bool _has8Chars = false;
  bool _hasLowercase = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      _checkPasswordCriteria(_passwordController.text);
    });
  }

  void _checkPasswordCriteria(String password) {
    setState(() {
      _has8Chars = password.length >= 8;
      _hasLowercase = RegExp(r'[a-z]').hasMatch(password);
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasNumber = RegExp(r'[0-9]').hasMatch(password);
      _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    });
  }

  Future<void> _submitSignup() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validate all fields are filled
    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty || _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Color.fromARGB(180, 86, 87, 86)
        ),
      );
      return;
    }

    // Validate passwords match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Color.fromARGB(180, 86, 87, 86)
        ),
      );
      return;
    }

    // Validate password meets all criteria
    if (!(_has8Chars && _hasLowercase && _hasUppercase && _hasNumber && _hasSpecialChar)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password does not meet all criteria'),
          backgroundColor: Color.fromARGB(180, 86, 87, 86)
        ),
      );
      return;
    }

    // If role is courier, directly navigate to courier form without API call
    if (_selectedRole == 'courier') {
      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proceeding to courier registration form...'),
          backgroundColor: Color.fromARGB(180, 86, 87, 86),
        ),
      );
      
      // Navigate to courier form with user data
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CourierForm(
            username: username,
            password: password,
            email: widget.email,
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.19:5000/register_user'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': widget.email,
          'username': username,
          'password': password,
          'role': _selectedRole,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      // Try to parse the response as JSON
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        // If we can't parse as JSON, check for specific HTTP error codes
        if (response.statusCode == 409) {
          // Email already exists case
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email already registered. Please use a different email.'),
              backgroundColor: Color.fromARGB(180, 86, 87, 86),
            ),
          );
          
          // Redirect to signup page after a brief delay to show the message
          Future.delayed(Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SignupScreen()), // Replace with your actual signup screen class
            );
          });
          return;
        } else {
          // Generic server error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Server error. Please try again later.'),
              backgroundColor: Color.fromARGB(180, 86, 87, 86),
            ),
          );
          return;
        }
      }

      if (response.statusCode == 201) {
        // Success handling
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful!'),
            backgroundColor: Color.fromARGB(180, 86, 87, 86),
          ),
        );
        
        // Navigate to login for buyers
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        });
      } else if (response.statusCode == 409 || 
                (responseData.containsKey('error') && 
                responseData['error'].toString().contains('already registered'))) {
        // Email already exists case - check both status code and error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email already registered. Please use a different email.'),
            backgroundColor: Color.fromARGB(180, 86, 87, 86),
          ),
        );
        
        // Redirect to signup page after a brief delay
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SignupScreen()), // Replace with your actual signup screen class
          );
        });
      } else {
        // Other error handling
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['error'] ?? 'Registration failed'),
            backgroundColor: Color.fromARGB(180, 86, 87, 86),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Check if the error message contains signs of duplicate email
      if (e.toString().contains('duplicate') || e.toString().contains('already exists')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email already registered. Please use a different email.'),
            backgroundColor: Color.fromARGB(180, 86, 87, 86),
          ),
        );
        
        // Redirect to signup page
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SignupScreen()), // Replace with your actual signup screen class
          );
        });
      } else {
        // Handle network or other errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: ${e.toString()}'),
            backgroundColor: Color.fromARGB(180, 86, 87, 86),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Card(
            color: Colors.white,
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Text(
                      'Create Your Account',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, color: Colors.black),
                        children: [
                          TextSpan(text: 'Using email: '),
                          TextSpan(
                            text: widget.email,
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 15),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPasswordField(
                        controller: _passwordController,
                        label: 'Password',
                        visible: _isPasswordVisible,
                        toggleVisibility: () {
                          setState(() => _isPasswordVisible = !_isPasswordVisible);
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildPasswordChecklist(),
                    ],
                  ),

                  const SizedBox(height: 15),

                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    visible: _isConfirmPasswordVisible,
                    toggleVisibility: () {
                      setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                    },
                  ),
                  const SizedBox(height: 25),

                  const Text(
                    'Select',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInlineRadio('buyer', 'Buyer'),
                      const SizedBox(width: 60),
                      _buildInlineRadio('courier', 'Courier'),
                    ],
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 245, 214, 37),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            'Submit',
                            style: TextStyle(color: Colors.black, fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback toggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility : Icons.visibility_off),
          onPressed: toggleVisibility,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildPasswordChecklist() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChecklistItem("At least 8 characters", _has8Chars),
        _buildChecklistItem("Contains lowercase letter", _hasLowercase),
        _buildChecklistItem("Contains uppercase letter", _hasUppercase),
        _buildChecklistItem("Contains number", _hasNumber),
        _buildChecklistItem("Contains special character", _hasSpecialChar),
      ],
    );
  }

  Widget _buildChecklistItem(String text, bool valid) {
    return Row(
      children: [
        Icon(
          valid ? Icons.check_circle : Icons.cancel,
          color: valid ? Colors.green : Colors.red,
          size: 11,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: valid ? Colors.green : Colors.red, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildInlineRadio(String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _selectedRole,
          onChanged: (newValue) {
            setState(() => _selectedRole = newValue);
          },
          activeColor: const Color.fromARGB(255, 245, 214, 37),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}