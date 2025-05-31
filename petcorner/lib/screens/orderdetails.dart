import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_courier.dart';
import 'dart:convert';

class OrderDetailsPage extends StatelessWidget {
  
  final PickupOrder order;
  final int courierId;

  const OrderDetailsPage({
    super.key,
    required this.order,
    required this.courierId,
    
  });


  Future<void> updatePickupStatus(BuildContext context, String orderId, String courierId) async {
    final url = Uri.parse('http://192.168.1.19:5000/update_pickup_status');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'status': 'Picked up',
          'courier_id': courierId, // Pass courier_id to backend
        }),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order status updated to Picked up!'),
              backgroundColor: Color.fromARGB(180, 86, 87, 86),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${resData['error']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request failed: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 245, 214, 37),
        title: const Text('Order Details', style: TextStyle(fontSize: 17)),
        actions: [
          // Display courier ID on the right side of the AppBar
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'CID: $courierId',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 251, 214, 4),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
       
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildOrderCard(
              icon: Icons.assignment,
              title: 'Order Information',
              children: [
                buildDetailRow('Date', order.date),
                buildDetailRow('SID', '${order.sellerId}'),
                buildDetailRow('OID', '${order.orderId}'),
              ],
            ),
            const SizedBox(height: 16),
            _buildOrderCard(
              icon: Icons.store,
              title: 'Shop Information',
              children: [
                buildDetailRow('Shop', order.shopName),
                buildDetailRow('Pick-up Address', order.sellerAddress),
              ],
            ),
            const SizedBox(height: 16),
            _buildOrderCard(
              icon: Icons.person,
              title: 'Buyer Information',
              children: [
                buildDetailRow('Buyer', order.buyer),
                buildDetailRow('Address', order.buyerAddress),
                buildDetailRow('Contact', order.contact),
              ],
            ),
            const SizedBox(height: 30),
           SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
               
                //updatePickupStatus(context, order.orderId);
                updatePickupStatus(context, order.orderId.toString(), courierId.toString());

              },
              icon: const Icon(Icons.local_shipping, color: Colors.black),
              label: const Text(
                'Pick Up Order',
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 245, 214, 37), // Yellow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color.fromARGB(255, 97, 97, 97)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
