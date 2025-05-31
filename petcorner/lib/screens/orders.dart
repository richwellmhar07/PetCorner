import 'package:flutter/material.dart';
import 'cart.dart';
import 'notif.dart';
import 'account.dart';
import 'home_buyer.dart';
import 'vieworder.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../config/config.dart';

class OrdersScreen extends StatefulWidget {
  final int userId;
  final int initialTabIndex;
  //final int orderId;
  const OrdersScreen({
    super.key, 
    required this.userId,
    this.initialTabIndex = 0,
    
    
  });

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  Map<int, List<Order>> _groupedOrders = {}; // Group orders by orderId
  bool _isLoading = true;
  String? _error;

  final List<Map<String, dynamic>> orderShortcuts = [
    {'icon': Icons.local_shipping, 'label': 'To Ship'},
    {'icon': Icons.inventory_2, 'label': 'To Receive'},
    {'icon': Icons.check_circle, 'label': 'Completed'},
    {'icon': Icons.cancel, 'label': 'Cancelled'},
  ];

  late PageController pageController;
  int selectedShortcutIndex = 0;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
   // pageController = PageController(initialPage: 0);

    pageController = PageController(initialPage: widget.initialTabIndex);
    selectedShortcutIndex = widget.initialTabIndex;
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final orders = await _orderService.getUserOrders(widget.userId);
      
      // Group orders by orderId
      final Map<int, List<Order>> grouped = {};
      for (var order in orders) {
        if (!grouped.containsKey(order.orderId)) {
          grouped[order.orderId] = [];
        }
        grouped[order.orderId]!.add(order);
      }
      
      setState(() {
        _orders = orders;
        _groupedOrders = grouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Filter grouped orders based on status
  // Map<int, List<Order>> _getGroupedOrdersByStatus(String status) {
  //   Map<int, List<Order>> filteredGroups = {};
    
  //   _groupedOrders.forEach((orderId, ordersList) {
  //     // Use the status of the first order in the group for filtering
  //     if (ordersList.isNotEmpty) {
  //       final status1 = ordersList[0].status;
  //       switch (status) {
  //         case 'To Ship':
  //           if (status1 == 'Pending' || status1 == 'Ready for pick up') {
  //             filteredGroups[orderId] = ordersList;
  //           }
  //           break;
  //         case 'To Receive':
  //           if (status1 == 'Shipped' || status1 == 'Picked up') {
  //             filteredGroups[orderId] = ordersList;
  //           }
  //           break;
  //         case 'Completed':
  //           if (status1 == 'Received') {
  //             filteredGroups[orderId] = ordersList;
  //           }
  //           break;
  //         case 'Cancelled':
  //           if (status1 == 'Cancelled') {
  //             filteredGroups[orderId] = ordersList;
  //           }
  //           break;
  //       }
  //     }
  //   });
    
  //   return filteredGroups;
  // }

  Map<int, List<Order>> _getGroupedOrdersByStatus(String status) {
    Map<int, List<Order>> filteredGroups = {};

    _groupedOrders.forEach((orderId, ordersList) {
      if (ordersList.isNotEmpty) {
        final order = ordersList[0];
        final status1 = order.status;

        switch (status) {
          case 'To Ship':
            if (status1 == 'Pending' || status1 == 'Ready for pick up') {
              filteredGroups[orderId] = ordersList;
            }
            break;
          case 'To Receive':
            if (status1 == 'Shipped' || status1 == 'Picked up') {
              filteredGroups[orderId] = ordersList;
            }
            break;
          case 'Completed':
            if (status1 == 'Received') {
              filteredGroups[orderId] = ordersList;
            }
            break;
          case 'Cancelled':
            if (status1 == 'Cancelled') {
              filteredGroups[orderId] = ordersList;
            }
            break;
        }
      }
    });

    // Convert map entries to a list for sorting
    final sortedEntries = filteredGroups.entries.toList();

    // Sort based on relevant date
    sortedEntries.sort((a, b) {
      final Order aOrder = a.value[0];
      final Order bOrder = b.value[0];

      if (status == 'Completed') {
        // Sort by receivedDate (descending)
        final aDate = DateTime.tryParse(aOrder.receivedDate ?? '') ?? DateTime(2000);
        final bDate = DateTime.tryParse(bOrder.receivedDate ?? '') ?? DateTime(2000);
        return bDate.compareTo(aDate);
      } else {
        // Sort by orderedDate (descending)
        final aDate = DateTime.tryParse(aOrder.orderedDate) ?? DateTime(2000);
        final bDate = DateTime.tryParse(bOrder.orderedDate) ?? DateTime(2000);
        return bDate.compareTo(aDate);
      }
    });

    // Convert back to map
    return Map.fromEntries(sortedEntries);
  }


  Widget _buildOrdersContent() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(orderShortcuts.length, (index) {
            final isSelected = selectedShortcutIndex == index;
            final shortcut = orderShortcuts[index];

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedShortcutIndex = index;
                  pageController.animateToPage( /////////////error here
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                });
              },
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 1.0,
                  end: isSelected ? 1.05 : 1.0,
                ),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFF3E0) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: isSelected ? Colors.orange : const Color(0xFFFFF3E0),
                            radius: 24,
                            child: Icon(
                              shortcut['icon'],
                              color: isSelected ? Colors.white : Colors.orange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            shortcut['label'],
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.orange : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : _error != null
              ? Center(child: Text('Error: $_error'))
              : PageView.builder(
                  controller: pageController,
                  itemCount: orderShortcuts.length,
                  onPageChanged: (index) {
                    setState(() {
                      selectedShortcutIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildTabContent(index);
                  },
                ),
        ),
      ],
    );
  }


  Widget _buildGroupedOrderCard(int orderId, List<Order> orders) {
    // Use the first order for shared information
    final Order firstOrder = orders.first;
    
    // Format the dates
    String formattedOrderedDate = firstOrder.orderedDate.substring(0, 19);
    String? formattedReceivedDate = firstOrder.receivedDate != null && firstOrder.receivedDate != 'null' 
        ? firstOrder.receivedDate!.substring(0, 19)
        : null;

    double orderTotal = firstOrder.total;
    double shippingFee = 50.00;
    
    return GestureDetector(
      onTap: () {
        // Navigate to ViewOrder when card is clicked
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewOrderScreen(
              orderId: orderId,
              userId: widget.userId,
              orders: orders,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Order No. $orderId",
                        style: const TextStyle(fontSize: 8, color: Color.fromARGB(255, 95, 95, 95))),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Ordered Date: $formattedOrderedDate",
                            style: const TextStyle(fontSize: 8, color: Color.fromARGB(255, 95, 95, 95))),
                        if (formattedReceivedDate != null)
                          Text("Received Date: $formattedReceivedDate",
                              style: const TextStyle(fontSize: 8, color: Color.fromARGB(255, 95, 95, 95))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // List of products in this order
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: orders.length > 3 ? 3 : orders.length, // Show up to 3 products
              itemBuilder: (context, index) {
                final order = orders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: _buildProductImage(order.productImage),
                      ),
                      const SizedBox(width: 12),

                      // Product Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text("Price: P${order.productPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12)),
                            Text("x${order.productQty}", style: const TextStyle(fontSize: 12)),
                            Text("Status: ${order.status}", style: const TextStyle(fontSize: 12, color: Colors.orange)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // Show "more items" indicator if there are more than 3 products
            if (orders.length > 3)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    "+ ${orders.length - 3} more items",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
            const SizedBox(height: 12),

            // Bottom Row with corrected totals
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Order Total: P${orderTotal.toStringAsFixed(2)}", 
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                  ),
                  Text("Shipping fee: P${shippingFee.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, color: Colors.orange)),
                  const SizedBox(height: 4),
                 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildProductImage(String imagePath) {
    // For debugging
    print("Building image with path: $imagePath");
    
    // Check if the image path is empty
    if (imagePath.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
      );
    }

    // Construct the full URL - no fancy logic, just direct concatenation
    final String fullUrl = '${AppConfig.imageBaseUrl}/$imagePath';
    print("Full image URL: $fullUrl");
    
    // Simple network image with error handling
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.network(
        fullUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Error loading image ($fullUrl): $error");
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent(int index) {
    String statusLabel = orderShortcuts[index]['label'];
    Map<int, List<Order>> filteredGroups = _getGroupedOrdersByStatus(statusLabel);
    
    if (filteredGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_basket, 
              size: 70, 
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "No $statusLabel orders",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredGroups.length,
        itemBuilder: (context, idx) {
          final orderId = filteredGroups.keys.elementAt(idx);
          final ordersList = filteredGroups[orderId]!;
          return _buildGroupedOrderCard(orderId, ordersList);
        },
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
        title: Transform.translate(
          offset: const Offset(-20, 0), 
          child: Row(
            children: [
              Image.asset(
                'lib/assets/images/order1.png',
                width: 25, 
                height: 25,
              ),
              const SizedBox(width: 8),
              Text(
                'Orders',
                style: const TextStyle(fontSize: 18),
              ),
            ],
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
            icon: const Icon(Icons.message), /////// NAVIAGATE TO CHAT 
            onPressed: () {}
          ),
        ],
      ),
      body: _buildOrdersContent(),
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
              // Already on Orders
              break;
            case 2: 
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationBuyerScreen(userId: widget.userId),
                ),
              );
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
}