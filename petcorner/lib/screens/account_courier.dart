import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petcorner/screens/home_courier.dart' as home;
import 'package:petcorner/screens/transaction_courier.dart' as transaction;


class AccountCourierScreen extends StatefulWidget {
  final int courierId;
  const AccountCourierScreen({super.key, required this.courierId});

  @override
  State<AccountCourierScreen> createState() => _AccountCourierScreenState();
}

class _AccountCourierScreenState extends State<AccountCourierScreen> {
  int _selectedIndex = 2; 

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return; // Do nothing if already selected

    setState(() {
      _selectedIndex = index;
    });

    // Navigate based on selected index
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => home.HomeCourierScreen(courierId: widget.courierId)),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => transaction.TransactionCourierScreen(courierId: widget.courierId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar color to match app bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.yellow, // Status bar color
      statusBarIconBrightness: Brightness.dark, // Dark icons on light background
    ));
    
    // Make status bar transparent or remove it completely
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 241, 241),
      extendBodyBehindAppBar: true, // This allows the body to extend behind the AppBar
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 245, 214, 37),
        automaticallyImplyLeading: false,
        leadingWidth: 80,
        toolbarHeight: 100, // You can adjust this value to control the AppBar height
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: _ProfileAvatar(),
        ),
        titleSpacing: 10,
        title: const Text(
          'Courier Name',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          _NotificationButton(),
        ],
      ),

      body: const Center(
        child: Text('Account Courier Content'), 
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 245, 214, 37),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

// Extracted profile avatar to its own widget
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile clicked!')),
        );
      },
      child: const CircleAvatar(
        backgroundColor: Colors.grey,
        radius: 20,
        child: Icon(Icons.person, color: Colors.white),
      ),
    );
  }
}

// Extracted notification button to its own widget
class _NotificationButton extends StatelessWidget {
  const _NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications clicked!')),
        );
      },
    );
  }
}