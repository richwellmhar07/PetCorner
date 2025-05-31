import 'package:flutter/material.dart';
import 'package:petcorner/screens/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PetCorner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 252, 229, 26)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),  
    );
  }
}
//21.4.7075529 recommended ndk version