import 'package:flutter/material.dart';
//import '../models/order_model.dart';
import 'cart.dart';
import 'home_buyer.dart';
import 'orders.dart';
import 'account.dart';

class NotificationBuyerScreen extends StatefulWidget {
  final int userId;

  const NotificationBuyerScreen({super.key, required this.userId});

  @override
  State<NotificationBuyerScreen> createState() => _NotificationBuyerScreenState();
}

class _NotificationBuyerScreenState extends State<NotificationBuyerScreen> {
  int _currentIndex = 2; // Set to 2 for Notifications tab

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 241, 241),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 245, 214, 37),
        toolbarHeight: 70,
        title: SizedBox(
          height: 40,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Notification...',
              hintStyle: const TextStyle(fontSize: 14),
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart), 
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartPage(userId: widget.userId),
                ),
              );
            }
          ),
          IconButton(
            icon: const Icon(Icons.message), 
            onPressed: () {}
          ),
        ],
      ),
      body: _buildNotificationsContent(), // Changed from empty SizedBox to use the notification content
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0: 
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeBuyerScreen(userId: widget.userId),
                ),
              );
              break;
            case 1: 
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OrdersScreen(userId: widget.userId),
                ),
              );
              break;
            case 2: 
              // Already on Notifications
              break;
            case 3: 
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountScreen(userId: widget.userId),
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
      ),
    );
  }

  Widget _buildNotificationsContent() {
    final List<Map<String, String>> notifications = [
      {
        'title': 'Your order is on the way!',
        'subtitle': 'Order #123456 has been shipped and is on its way to you.',
        'time': '2h ago',
      },
      {
        'title': 'Your item has been delivered!',
        'subtitle': 'Thank you for shopping with us. Please confirm receipt.',
        'time': '1d ago',
      },
      
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFFFF3E0),
            child: Icon(Icons.notifications, color: Colors.orange),
          ),
          title: Text(notification['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(notification['subtitle']!, style: const TextStyle(fontSize: 12)),
          trailing: Text(notification['time']!, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        );
      },
    );
  }
}