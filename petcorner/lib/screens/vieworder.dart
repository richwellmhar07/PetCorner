import 'package:flutter/material.dart';
import 'dart:convert'; 
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../config/config.dart';
import 'cancelorder.dart';
import 'RateOrder.dart';
import 'orders.dart';

class ViewOrderScreen extends StatefulWidget {
  final int orderId;
  final int userId;
  final List<Order> orders;

  const ViewOrderScreen({
    Key? key,
    required this.orderId,
    required this.userId,
    required this.orders,
  }) : super(key: key);

  @override
  _ViewOrderScreenState createState() => _ViewOrderScreenState();
}

class _ViewOrderScreenState extends State<ViewOrderScreen> {
  String orderStatus = 'Unknown';
  bool _mounted = false;
  
  @override
  void initState() {
    super.initState();
    _mounted = true;
    if (widget.orders.isNotEmpty) {
      orderStatus = widget.orders.first.status;
    }
  }

  @override
  void dispose() {
    _mounted = false; // Set the mounted flag to false when widget is disposed
    super.dispose();
  }

  // Function to mark an order as received
  Future<bool> markOrderReceived(int orderId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/mark_order_received'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'order_id': orderId,
        }),
      );

      final responseData = json.decode(response.body);
      return responseData['success'] ?? false;
    } catch (e) {
      print('Error marking order as received: $e');
      return false;
    }
  }

  // Safe method to update state
  void _safeSetState(VoidCallback fn) {
    if (_mounted) {
      setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Store a reference to the scaffold messenger
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Calculate order summary
    double subtotal = 0;
    for (var order in widget.orders) {
      subtotal += order.productPrice * order.productQty;
    }
    double shippingFee = 50.00; // Fixed shipping fee
    double total = subtotal + shippingFee;

    // Format ordered date
    String orderedDate = widget.orders.isNotEmpty 
        ? widget.orders.first.orderedDate.substring(0, 19)
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order No. ${widget.orderId}', style: TextStyle(fontSize: 18),),
        backgroundColor: const Color.fromARGB(255, 245, 214, 37),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Status Section
              _buildStatusCard(orderStatus),
              const SizedBox(height: 20),
              
              // Order Details Section
              _buildSectionHeader('Order Details'),
              _buildInfoCard(
                child: Column(
                  children: [
                    _buildInfoRow('Order Number', '${widget.orderId}'),
                    _buildInfoRow('Order Date', orderedDate),
                    _buildInfoRow('Status', orderStatus),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Order Items Section
              _buildSectionHeader('Order Items (${widget.orders.length})'),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.orders.length,
                itemBuilder: (context, index) {
                  final order = widget.orders[index];
                  return _buildOrderItemCard(order);
                },
              ),
              const SizedBox(height: 20),
              
              // Order Summary Section
              _buildSectionHeader('Order Summary'),
              _buildInfoCard(
                child: Column(
                  children: [
                    _buildInfoRow('Subtotal', 'P${subtotal.toStringAsFixed(2)}'),
                    _buildInfoRow('Shipping Fee', 'P${shippingFee.toStringAsFixed(2)}'),
                    const Divider(),
                    _buildInfoRow('Total', 'P${total.toStringAsFixed(2)}', isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Buttons Section
              if (orderStatus == 'Pending' || orderStatus == 'Ready for pick up')
                _buildActionButton(
                  'Cancel Order',
                  () => _showCancelConfirmation(context)
                ),
              if (orderStatus == 'Shipped' || orderStatus == 'Picked up')
                _buildActionButton(
                  'Confirm Receipt',
                  () => _showConfirmReceiptDialog(context, scaffoldMessenger)
                ),
             if (orderStatus == 'Received')
              _buildActionButton(
                'Rate',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RateOrderScreen(
                        orderId: widget.orderId, 
                        orders: widget.orders,
                      ), 
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    IconData statusIcon;
    Color statusColor;
    
    switch (status) {
      case 'Pending':
        statusIcon = Icons.pending_actions;
        statusColor = Colors.orange;
        break;
      case 'Ready for pick up':
        statusIcon = Icons.store;
        statusColor = Colors.orange;
        break;
      case 'Shipped':
      case 'Picked up':
        statusIcon = Icons.local_shipping;
        statusColor = Colors.orange;
        break;
      case 'Received':
        statusIcon = Icons.check_circle;
        statusColor = Colors.orange;
        break;
      case 'Cancelled':
        statusIcon = Icons.cancel;
        statusColor = Colors.orange;
        break;
      default:
        statusIcon = Icons.help_outline;
        statusColor = Colors.orange;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(status),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'Pending':
        return 'Your order is being processed.';
      case 'Ready for pick up':
        return 'Your order is ready for pick up at the store.';
      case 'Shipped':
        return 'Your order is on its way to you.';
      case 'Picked up':
        return 'You have picked up your order from the store.';
      case 'Received':
        return 'You have received your order.';
      case 'Cancelled':
        return 'This order has been cancelled.';
      default:
        return 'Status information unavailable.';
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 234, 233, 233),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 238, 235, 235),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildProductImage(order.productImage),
          ),
          const SizedBox(width: 12),
          
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'P${order.productPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'x${order.productQty}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subtotal: P${(order.productPrice * order.productQty).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    final String fullUrl = '${AppConfig.imageBaseUrl}/$imagePath';
    
    return Image.network(
      fullUrl,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 80,
          height: 80,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 80,
          height: 80,
          color: Colors.grey[100],
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
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color.fromARGB(255, 156, 155, 155), width: 0.7),
          backgroundColor: Colors.transparent,
          minimumSize: const Size.fromHeight(40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text, 
          style: const TextStyle(color: Color.fromARGB(255, 68, 66, 66))
        ),
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: const Text(
          'Cancel Order',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to cancel this order?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'No',
              style: TextStyle(color: Color.fromARGB(255, 80, 79, 79)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CancelOrderScreen(
                    orderId: widget.orderId, 
                    userId: widget.userId, 
                    orders: widget.orders,
                  ),
                ),
              );
            },
            child: const Text(
              'Yes',
              style: TextStyle(color: Color.fromARGB(255, 80, 79, 79)),
            ),
          ),
        ],
      ),
    );
  }

  // void _showConfirmReceiptDialog(BuildContext context, ScaffoldMessengerState scaffoldMessenger) {
  //   // Store the parent context BEFORE the dialog is shown
  //   //final parentContext = context;

  //   final navigator = Navigator.of(context);
  //   final messenger = ScaffoldMessenger.of(context);

  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Confirm Receipt'),
  //       content: const Text('Have you received your order?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('No', style: TextStyle(color: Color.fromARGB(255, 80, 79, 79))),
  //         ),
  //         TextButton(
  //           onPressed: () async {
  //             navigator.pop(); // Close the dialog

  //             final success = await markOrderReceived(widget.orderId);

  //             if (_mounted) {
  //               if (success) {
  //                 _safeSetState(() {
  //                   orderStatus = 'Received';
  //                 });

  //                 messenger.showSnackBar(
  //                   const SnackBar(
  //                     content: Text('Order marked as received'),
  //                     backgroundColor: Color.fromARGB(180, 86, 87, 86),
  //                     duration: Duration(seconds: 1),
  //                   ),
  //                 );

  //                 // Wait for snackbar to show and finish
  //                 await Future.delayed(const Duration(seconds: 1));

  //                 // Now do the navigation safely
  //                 if (mounted) {
  //                   Navigator.pushReplacement(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (context) => OrdersScreen(
  //                         userId: widget.userId,
  //                         initialTabIndex: 2, 
  //                       ),
  //                     ),
  //                   );
  //                 }
  //               } else {
  //                 scaffoldMessenger.showSnackBar(
  //                   const SnackBar(
  //                     content: Text('Failed to mark order as received. Please try again.'),
  //                     backgroundColor: Color.fromARGB(180, 86, 87, 86),
  //                     duration: Duration(seconds: 1),
  //                   ),
  //                 );
  //               }
  //             }
  //           },
  //           child: const Text('Yes', style: TextStyle(color: Color.fromARGB(255, 80, 79, 79))),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showConfirmReceiptDialog(BuildContext context, ScaffoldMessengerState scaffoldMessenger) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Receipt'),
        content: const Text('Have you received your order?'),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('No', style: TextStyle(color: Color.fromARGB(255, 80, 79, 79))),
          ),
          TextButton(
            onPressed: () async {
              navigator.pop(); // Close the dialog

              final success = await markOrderReceived(widget.orderId);

              if (!mounted) return;

              if (success) {
                _safeSetState(() {
                  orderStatus = 'Received';
                });

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Order marked as received'),
                    backgroundColor: Color.fromARGB(180, 86, 87, 86),
                    duration: Duration(seconds: 1),
                  ),
                );

                await Future.delayed(const Duration(seconds: 1));

                if (!mounted) return;

                navigator.pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => OrdersScreen(
                      userId: widget.userId,
                      initialTabIndex: 2,
                    ),
                  ),
                );
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Failed to mark order as received. Please try again.'),
                    backgroundColor: Color.fromARGB(180, 86, 87, 86),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Text('Yes', style: TextStyle(color: Color.fromARGB(255, 80, 79, 79))),
          ),
        ],
      ),
    );
  }


}

