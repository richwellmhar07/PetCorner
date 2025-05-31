import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../config/config.dart';

class CancelOrderScreen extends StatefulWidget {
  final int orderId;
  final int userId;
  final List<Order> orders;

  const CancelOrderScreen({
    Key? key,
    required this.orderId,
    required this.userId,
    required this.orders,
  }) : super(key: key);

  @override
  State<CancelOrderScreen> createState() => _CancelOrderScreenState();
}


class _CancelOrderScreenState extends State<CancelOrderScreen> {
  String _selectedReason = 'Change of mind';
  final List<String> _reasons = [
    'Change of mind',
    'Found better price',
    'Order placed by mistake',
    'Other'
  ];


  @override
  Widget build(BuildContext context) {
    double subtotal = 0;
    for (var order in widget.orders) {
      subtotal += order.productPrice * order.productQty;
    }
    double shippingFee = 50.00;
    double total = subtotal + shippingFee;

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
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Details
            _buildSectionHeader('Order No. ${widget.orderId}'),
            const SizedBox(height: 8),
            
            // Order Items
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.orders.length,
              itemBuilder: (context, index) {
                final order = widget.orders[index];
                return _buildOrderItemCard(order);
              },
            ),
            
            // Order Summary
            const SizedBox(height: 20),
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
            
            // Cancellation Reason
            const SizedBox(height: 20),
            _buildSectionHeader('Cancellation Reason'),
            _buildReasonSelector(),
            
            // Buttons
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    'Cancel',
                    () => Navigator.pop(context),
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildButton(
                    'Submit',
                    () => _submitCancellation(context),
                    isOutlined: true,
                  ),
                ),
              ],
            ),
            
          ],
        ),
      ),
    );
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

  Widget _buildReasonSelector() {
    return Container(
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
      child: Column(
        children: _reasons.map((reason) {
          return RadioListTile<String>(
            title: Text(
              reason,
              style: const TextStyle(fontSize: 14),
            ),
            value: reason,
            groupValue: _selectedReason,
            onChanged: (value) {
              setState(() {
                _selectedReason = value!;
              });
            },
            activeColor: Colors.orange,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            dense: true,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, {required bool isOutlined}) {
    return isOutlined
        ? OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color.fromARGB(255, 156, 155, 155), width: 0.7),
              backgroundColor: Colors.white,
              elevation: 0, // removes shadow
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onPressed,
            child: Text(
              text,
              style: const TextStyle(
                color: Color.fromARGB(255, 68, 66, 66),
              ),
            ),
          )
        : ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 245, 214, 37),
              elevation: 0, // optional: also remove shadow from elevated button if needed
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onPressed,
            child: Text(
              text,
              style: const TextStyle(color: Colors.black),
            ),
          );
  }

  // void _submitCancellation(BuildContext context) {
  //   // Here you would implement the actual cancellation logic
  //   // For now, just show a success message and navigate back
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text('Order cancelled successfully'),
  //       backgroundColor: Colors.green,
  //     ),
  //   );
  //   // Navigate back to previous screens
  //   Navigator.of(context).popUntil((route) => route.isFirst);
  // }


  void _submitCancellation(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 245, 214, 37)),
          ),
        );
      },
    );

    try {
      // Get current datetime for request_date
      final now = DateTime.now();
      final String formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} "
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      
      // Prepare the cancellation request data
      final Map<String, dynamic> requestData = {
        'order_id': widget.orderId,
        'user_id': widget.userId,
        'ordered_date': formattedDate, 
        'reason': _selectedReason,
      };

      final response = await http.post(
        Uri.parse('http://192.168.1.19:5000/api/cancel-order'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      // Close loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success']) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancellation request submitted successfully!'),
              backgroundColor: Color.fromARGB(180, 86, 87, 86),
              duration: Duration(seconds: 2),
            ),
          );
          
          // Navigate back to previous screens
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          // Show error message with details from response
          final errorMessage = responseData['message'] ?? 'Failed to cancel order';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Color.fromARGB(180, 86, 87, 86),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Show error message with status code
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error: ${response.statusCode}'),
            backgroundColor: Color.fromARGB(180, 86, 87, 86),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling order: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      print('Error cancelling order: $e');
    }
  }
}
