import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_buyer.dart';
import 'home_courier.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ApiService apiService = ApiService();

  bool _isPasswordVisible = false;

  Future<void> _handleLogin() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    final result = await apiService.login(username, password);

    if (result['success']) {
      print('Login successful!');
      print('User ID: ${result['user_id']}');
      print('Role: ${result['role']}');

      // Navigate based on role
      if (result['role'] == 'buyer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeBuyerScreen(userId: result['user_id']),  // Pass the userId here
          ),
        );
      // } else if (result['role'] == 'courier') {
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (context) => const HomeCourierScreen()),
      //   );
      // } 

      }else if (result['role'] == 'courier') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeCourierScreen(courierId: result['user_id']),
          ),
        );
      }
      
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unknown role!'),
            backgroundColor: Color.fromARGB(180, 86, 87, 86)
          )
        );
      }
    } else {
      print('Error: ${result['error']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']),
          backgroundColor: Color.fromARGB(180, 86, 87, 86)
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Card(
            color: const Color.fromARGB(255, 243, 243, 242),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo inside the card
                  Center(
                    child: Image.asset(
                      'lib/assets/images/petcornerlogo2.png',
                      height: 200,
                      width: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 1),

                  // Username Field
                  _buildInputField(
                    controller: _usernameController,
                    label: 'Username or Email',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 15),

                  // Password Field
                  _buildPasswordField(),
                  const SizedBox(height: 10),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},  // Add forgot password functionality
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.blue, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Login Button
                  ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color.fromARGB(255, 245, 214, 37),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sign-up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SignupScreen()),
                          );
                        },
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            color: Color.fromARGB(255, 245, 214, 37),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                      )
                    ],
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget for Input Field
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Widget for Password Field with Visibility Toggle
  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
