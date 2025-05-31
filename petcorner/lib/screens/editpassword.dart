import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EditPasswordScreen extends StatefulWidget {
  final int userId; // Changed to match your pattern in EditNameScreen

  const EditPasswordScreen({super.key, required this.userId});

  @override
  State<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _has8Chars = false;
  bool _hasLowercase = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  
  bool _isLoading = false;
  String _errorMessage = '';
  bool _showError = false;

  void _checkPassword(String password) {
    setState(() {
      _has8Chars = password.length >= 8;
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  bool _isPasswordValid() {
    return _has8Chars && _hasLowercase && _hasUppercase && _hasNumber && _hasSpecialChar;
  }

  Future<void> _updatePassword() async {
    // Clear previous errors
    setState(() {
      _showError = false;
      _errorMessage = '';
      _isLoading = true;
    });

    // Validate inputs
    if (_currentPasswordController.text.isEmpty) {
      _setError('Please enter your current password');
      return;
    }
    
    if (_newPasswordController.text.isEmpty) {
      _setError('Please enter a new password');
      return;
    }
    
    if (!_isPasswordValid()) {
      _setError('New password does not meet all requirements');
      return;
    }
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _setError('New passwords do not match');
      return;
    }

    try {
      // Debug logging
      print("Sending update password request with user_id: ${widget.userId}");
      
      // Make API call to update password - using userId from widget parameter
      final response = await http.post(
        Uri.parse('http://192.168.1.19:5000/api/update_password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId, // Use the userId passed as parameter
          'current_password': _currentPasswordController.text,
          'new_password': _newPasswordController.text,
        }),
      );

      final responseData = json.decode(response.body);
      print("API response: $responseData");

      if (response.statusCode == 200 && responseData['success']) {
        // Password updated successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully'),
            backgroundColor: Color.fromARGB(180, 86, 87, 86)
          ),
        );
        Navigator.pop(context); // Go back to previous screen
      } else {
        // Error updating password
        _setError(responseData['message'] ?? 'Failed to update password');
      }
    } catch (e) {
      print("Error updating password: $e");
      _setError('An error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setError(String message) {
    setState(() {
      _errorMessage = message;
      _showError = true;
      _isLoading = false;
    });
  }

  Widget _buildChecklistItem(String text, bool condition) {
    return Row(
      children: [
        Icon(
          condition ? Icons.check_circle : Icons.cancel,
          color: condition ? Colors.green : Colors.grey,
          size: 15,
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black87),
        ),
        suffixIcon: IconButton(
          iconSize: 18, // smaller size
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[700],
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Password',
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
                      color: Colors.black54,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _updatePassword,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showError)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            _buildPasswordField(
              label: "Current Password",
              controller: _currentPasswordController,
              obscureText: _obscureCurrent,
              onToggleVisibility: () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              label: "New Password",
              controller: _newPasswordController,
              obscureText: _obscureNew,
              onToggleVisibility: () => setState(() => _obscureNew = !_obscureNew),
              onChanged: _checkPassword,
            ),
            const SizedBox(height: 10),
            _buildChecklistItem("At least 8 characters", _has8Chars),
            _buildChecklistItem("Contains lowercase letter", _hasLowercase),
            _buildChecklistItem("Contains uppercase letter", _hasUppercase),
            _buildChecklistItem("Contains number", _hasNumber),
            _buildChecklistItem("Contains special character", _hasSpecialChar),
            const SizedBox(height: 16),
            _buildPasswordField(
              label: "Confirm Password",
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ],
        ),
      ),
    );
  }
}