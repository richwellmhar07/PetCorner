import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'transaction_courier.dart';
import 'account_courier.dart';
import 'orderdetails.dart';

// Model for Pickup Order
class PickupOrder {
  
  final int orderId;
  final String shopName;
  final String sellerAddress;
  final String buyerAddress;

  final String date;
  final int sellerId;
  final String buyer;
  final String contact;

  PickupOrder({
    
    required this.orderId,
    required this.shopName,
    required this.sellerAddress,
    required this.buyerAddress,

    required this.date,
    required this.sellerId,
    required this.buyer,
    required this.contact,

  });

  factory PickupOrder.fromJson(Map<String, dynamic> json) {
    return PickupOrder(
    
      orderId: json['order_id'],
      shopName: json['shopname'] ?? '',
      sellerAddress: json['seller_address'] ?? '',
      buyerAddress: json['buyer_address'] ?? '',

      date: json['date'],
      sellerId: json['seller_id'],
      buyer: json['buyer'] ?? '',
      contact: json['phonenumber'] ?? '',
    );
  }
}

class HomeCourierScreen extends StatefulWidget {
  final int courierId;
  
  const HomeCourierScreen({super.key, required this.courierId});

  @override
  State<HomeCourierScreen> createState() => _HomeCourierScreenState();

}


class _HomeCourierScreenState extends State<HomeCourierScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<PickupOrder> _pickupOrders = [];
  String? courierName;

  @override
  void initState() {
    super.initState();
    fetchCourierName();
    fetchPickupOrders();
  }

  Future<void> fetchCourierName() async {
    final url = 'http://192.168.1.19:5000/api/courier_info?courier_id=${widget.courierId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            courierName = data['name'];
          });
        }
      } else {
        print("Failed to fetch courier name");
      }
    } catch (e) {
      print("Error fetching courier name: $e");
    }
  }

  Future<void> fetchPickupOrders() async {
    final url = 'http://192.168.1.19:5000/api/for_pickup?courier_id=${widget.courierId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _pickupOrders = (data['orders'] as List)
                .map((item) => PickupOrder.fromJson(item))
                .toList();
          });
        }
      } else {
        throw Exception("Failed to load orders");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionCourierScreen(courierId: widget.courierId,)));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AccountCourierScreen(courierId: widget.courierId)));
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.yellow,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 241, 241),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 245, 214, 37),
        automaticallyImplyLeading: false,
        toolbarHeight: 100,
        leadingWidth: 80,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: _ProfileAvatar(),
        ),
        titleSpacing: 10,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              courierName ?? 'Courier Name',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'ID: ${widget.courierId}',
              style: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 76, 76, 76)),
            ),
          ],
        ),
        actions: const [
          _NotificationButton(),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 150, 16, 5), // Reduced top padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'For Pick-Up Orders',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _pickupOrders.isEmpty
                      ? const Center(child: Text("No Pending Orders"))
                      : MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          child: ListView.builder(
                            itemCount: _pickupOrders.length,
                            itemBuilder: (context, index) {
                              final order = _pickupOrders[index];
                              return PickupOrderCard(order: order, courierId: widget.courierId,);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),


      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 245, 214, 37),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Transactions'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
      ),
    );
  }
}

// Widget for a single pickup order card
class PickupOrderCard extends StatelessWidget {
  final PickupOrder order;
   final int courierId;

  const PickupOrderCard({super.key, required this.order, required this.courierId,});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 251, 251, 250),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(1, 1)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Order ID: #${order.orderId}",
                    style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Shop: ${order.shopName}", style: const TextStyle(fontSize: 9)),
                Text("Pick-up: ${order.sellerAddress}", style: const TextStyle(fontSize: 9)),
                Text("Delivery: ${order.buyerAddress}", style: const TextStyle(fontSize: 9)),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsPage(order: order, courierId: courierId,),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.grey.shade300,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.chevron_right, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// Profile Avatar Widget
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile clicked!'))),
      child: const CircleAvatar(
        backgroundColor: Colors.grey,
        radius: 20,
        child: Icon(Icons.person, color: Colors.white),
      ),
    );
  }
}

// Notification Button Widget
class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications),
      onPressed: () => ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Notifications clicked!'))),
    );
  }
}
