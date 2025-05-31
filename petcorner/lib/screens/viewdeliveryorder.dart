import 'package:flutter/material.dart';

class ViewDeliveryOrderScreen extends StatefulWidget {
  const ViewDeliveryOrderScreen({super.key});

  @override
  State<ViewDeliveryOrderScreen> createState() => _ViewDeliveryOrderScreenState();
}

class _ViewDeliveryOrderScreenState extends State<ViewDeliveryOrderScreen> {
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
          'Cancel Order',
          style: TextStyle(
            fontSize: 17,
            color: Color.fromARGB(255, 88, 88, 88),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              
            },
          ),
        ],
      ),
    );
  }
}