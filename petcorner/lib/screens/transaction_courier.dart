import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'home_courier.dart';
import 'account_courier.dart';

class TransactionCourierScreen extends StatefulWidget {
  final int courierId;
  const TransactionCourierScreen({super.key, required this.courierId});

  @override
  State<TransactionCourierScreen> createState() => _TransactionCourierScreenState();
}

class _TransactionCourierScreenState extends State<TransactionCourierScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 1; // Set Transactions tab (index 1) as selected
  String? courierName;
  TabController? _tabController;
  List<dynamic> pickedUpOrders = [];
  List<dynamic> deliveredOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchCourierName();
    fetchPickedUpOrders();
    fetchDeliveredOrders();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
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
        print("Failed to fetch courier name: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error fetching courier name: $e");
    }
  }

  Future<void> fetchPickedUpOrders() async {
    setState(() {
      isLoading = true;
    });
    
    // Add courier_id parameter to the URL
    final url = 'http://192.168.1.19:5000/api/for_pickup/picked_up?courier_id=${widget.courierId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            pickedUpOrders = data['orders'];
            isLoading = false;
          });
        }
      } else {
        print("Failed to fetch picked up orders: ${response.statusCode}");
        print("Response body: ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching picked up orders: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchDeliveredOrders() async {
    // Add courier_id parameter to the URL
    final url = 'http://192.168.1.19:5000/api/for_pickup/delivered?courier_id=${widget.courierId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            deliveredOrders = data['orders'];
          });
        }
      } else {
        print("Failed to fetch delivered orders: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error fetching delivered orders: $e");
    }
  }

  Future<void> _markOrderAsReceived(int orderId) async {
    final url = 'http://192.168.1.19:5000/api/for_pickup/mark_received';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'order_id': orderId}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Refresh the orders list after successful update
          await refreshOrders();
          
          // Show success message
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order #$orderId marked as received'),
              backgroundColor: Color.fromARGB(180, 86, 87, 86)
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${data['message']}')),
          );
        }
      } else {
        print("Failed to mark order as received: ${response.statusCode}");
        print("Response body: ${response.body}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update order status')),
        );
      }
    } catch (e) {
      print("Error marking order as received: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not connect to server')),
      );
    }
  }
  // Add refresh functionality
  Future<void> refreshOrders() async {
    setState(() {
      isLoading = true;
    });
    await Future.wait([
      fetchPickedUpOrders(),
      fetchDeliveredOrders(),
    ]);
    setState(() {
      isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return; // Do nothing if already selected

    setState(() {
      _selectedIndex = index;
    });

    // Navigate based on selected index
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeCourierScreen(courierId: widget.courierId)),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AccountCourierScreen(courierId: widget.courierId)),
      );
    }
  }

  void _showOrderDetails(dynamic order, bool isPickedUp) {
    // Reference to the current context to be used in the showModalBottomSheet builder
    final BuildContext currentContext = context;
    
    showModalBottomSheet(
      context: currentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(currentContext).size.height * 0.6,
        child: Stack(
          children: [
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 120,
                        child: Text(
                          'Order ID',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          order['order_id'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 120,
                        child: Text(
                          'Buyer',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          order['buyer'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 120,
                        child: Text(
                          'Address',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          order['buyer_address'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 120,
                        child: Text(
                          'Phone Number',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          order['phonenumber'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // Show Drop Order button only for picked up orders
                if (isPickedUp)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Close the bottom sheet
                        Navigator.pop(context);
                        
                        // Call the function to mark the order as received
                        _markOrderAsReceived(order['order_id']);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 245, 214, 37),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Drop Order', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 245, 214, 37),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Close', style: TextStyle(color: Colors.black)),
                    ),
                  ),
              ],
            ),
            
            // Close 'X' button in the top-right corner
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                splashRadius: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order, bool isPickedUp) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrderDetails(order, isPickedUp),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order['order_id']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Buyer: ${order['buyer']}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Phone: ${order['phonenumber']}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order['buyer_address'],
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar color
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.yellow,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 241, 241),
      // Remove extendBodyBehindAppBar to solve overlap issues
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(
              icon: Icon(Icons.local_shipping),
              text: 'For Deliver',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Completed',
            ),
            Tab(
              icon: Icon(Icons.star),
              text: 'Feedback',
            ),
          ],
        ),
      ),

      body: _tabController == null
          ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 245, 214, 37)))
          : SafeArea(
              // Use SafeArea to respect system UI elements
              child: RefreshIndicator(
                onRefresh: refreshOrders,
                color: const Color.fromARGB(255, 245, 214, 37),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // For Deliver Tab
                    isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 245, 214, 37)))
                        : pickedUpOrders.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('No orders to deliver'),
                                    const SizedBox(height: 20),
                                    TextButton(
                                      onPressed: refreshOrders,
                                      child: const Text('Refresh', style: TextStyle(color: Color.fromARGB(255, 245, 214, 37))),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                // Add padding to accommodate the tab bar height
                                padding: const EdgeInsets.only(top: 16.0),
                                itemCount: pickedUpOrders.length,
                                itemBuilder: (context, index) {
                                  return _buildOrderCard(pickedUpOrders[index], true); // true for picked up orders
                                },
                              ),
                              
                    // Completed Tab
                    isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 245, 214, 37)))
                        : deliveredOrders.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('No completed deliveries'),
                                    const SizedBox(height: 20),
                                    TextButton(
                                      onPressed: refreshOrders,
                                      child: const Text('Refresh', style: TextStyle(color: Color.fromARGB(255, 245, 214, 37))),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                // Add padding to accommodate the tab bar height
                                padding: const EdgeInsets.only(top: 16.0),
                                itemCount: deliveredOrders.length,
                                itemBuilder: (context, index) {
                                  return _buildOrderCard(deliveredOrders[index], false); // false for delivered orders
                                },
                              ),
                              
                    // Feedback Tab (Empty for now)
                    const Center(child: Text('Feedback coming soon')),
                  ],
                ),
              ),
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

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

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

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