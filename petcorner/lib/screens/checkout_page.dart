import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:collection/collection.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:petcorner/screens/orders.dart';

class CheckoutPage extends StatefulWidget {  // Changed to StatefulWidget
  final int userId;
  final List<dynamic> selectedItems;
  final double totalAmount;
  final Map<String, List<dynamic>> groupedItems;

  const CheckoutPage({
    super.key, 
    required this.userId, 
    required this.selectedItems, 
    required this.totalAmount, 
    required this.groupedItems,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isLoading = true;
  String _buyerName = "";
  String _buyerMobile = "";
  String _buyerAddress = "";
  
  @override
  void initState() {
    super.initState();
    _fetchBuyerDetails();
  }
  
  Future<void> _placeOrder() async {
    try {
      setState(() => _isLoading = true);
      
      // Prepare the data
      final List<Map<String, dynamic>> orderedItems = widget.selectedItems.cast<Map<String, dynamic>>().map((item) {
        final double price = double.tryParse(item['productprice'] ?? '0') ?? 0.0;
        final int qty = item['productqty'] ?? 1;
        
        return {
          'productid': item['productid'],
          'productname': item['productname'],
          'productprice': item['productprice'],
          'productqty': item['productqty'],
          'subtotal': (price * qty).toString(),
          'sellerid': item['seller_id'],
          'cartid': item['cartid'],
        };
      }).toList();
      
      final double finalAmount = widget.totalAmount + 50.0; 

      final url = Uri.parse('http://192.168.1.19:5000/api/place_order');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': widget.userId,  // Send the user_id explicitly
          'total_amount': finalAmount,
          'ordered_items': orderedItems,
        }),
      );
      
      setState(() => _isLoading = false);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success']) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message']),
              backgroundColor: Color.fromARGB(180, 86, 87, 86),
              duration: Duration(seconds: 2), // Short duration so user isn't waiting too long
            ),
          );
          
          // Navigate to orders page after showing the message
          // Add a slight delay to ensure the snackbar is visible before navigating
          Future.delayed(Duration(milliseconds: 2000), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => OrdersScreen(userId: widget.userId)),
            );
          });
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${responseData['message']}')),
          );
        }
        
      } else {
        // Handle HTTP error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('HTTP Error ${response.statusCode}: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: $e')),
      );
    }
  }
  
  Future<void> _fetchBuyerDetails() async {
    try {
      // Replace with your actual API base URL
      final url = Uri.parse('http://192.168.1.19:5000/api/get_buyer_account');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': widget.userId}),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'success') {
          final userData = responseData['data'];
          setState(() {
            _buyerName = userData['name'] ?? "No name provided";
            _buyerMobile = userData['phonenumber'] ?? "No phone provided";
            _buyerAddress = userData['address'] ?? "No address provided";
            _isLoading = false;
          });
        } else {
          // Handle error response
          print('Failed to load buyer details: ${responseData['message']}');
          setState(() => _isLoading = false);
        }
      } else {
        // Handle HTTP error
        print('HTTP error ${response.statusCode}: ${response.reasonPhrase}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // Handle exceptions
      print('Error fetching buyer details: $e');
      setState(() => _isLoading = false);
    }
  }

  // Helper method to get seller_id for a store
  int? getSellerIdForStore(String storeName) {
    final storeItems = widget.selectedItems
        .cast<Map<String, dynamic>>()
        .where((item) => item['shopname'] == storeName)
        .toList();
    
    if (storeItems.isNotEmpty && storeItems.first.containsKey('seller_id')) {
      return storeItems.first['seller_id'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const double shippingFee = 50.0; // Fixed shipping fee

    double finalAmount = widget.totalAmount + shippingFee;  // Use widget.totalAmount

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 245, 214, 37),
        foregroundColor: Colors.black,
        elevation: 1,
        centerTitle: false,
        title: Transform.translate(
          offset: const Offset(-20, 0), 
          child: Row(
            children: [
              Image.asset(
                'lib/assets/images/checkout1.png',
                width: 30, 
                height: 30,
              ),
              const SizedBox(width: 8),
              Text(
                'Checkout',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // --- BUYER INFO SECTION ---
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color.fromARGB(255, 255, 255, 255),
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.red, size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _buyerName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _buyerMobile,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _buyerAddress,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          ),
          const SizedBox(height: 8),
          // --- PRODUCT LIST SECTION ---

          Expanded(
            child: ListView(
              children: [
                ...groupBy<Map<String, dynamic>, String>(
                  widget.selectedItems.cast<Map<String, dynamic>>(),  // Use widget.selectedItems
                  (item) => item['shopname'] ?? 'Unknown Store',
                ).entries.map((entry) {

                  final String storeName = entry.key;
                  final List<Map<String, dynamic>> storeItems = entry.value;
                  final int? sellerId = storeItems.isNotEmpty ? storeItems.first['seller_id'] : null;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store name header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: const Color.fromARGB(255, 242, 240, 240),
                        child: Row(
                          children: [
                            Image.asset(
                              'lib/assets/images/shop.png',
                              width: 16,
                              height: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    storeName,
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 57, 57, 57), 
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (sellerId != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '(ID: $sellerId)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Color.fromARGB(255, 242, 240, 240),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Items under this store
                      ...storeItems.map((item) {
                        final double price = double.tryParse(item['productprice']) ?? 0.0;
                        final int qty = item['productqty'] ?? 1;
                        final double total = price * qty;

                        return Column(
                          children: [
                            ListTile(
                              leading: Image.network(
                                item['productimage'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                              title: Text(
                                item['productname'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('x$qty'),
                              trailing: Text('₱${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 15)),
                            ),
                            const Divider(height: 1),
                          ],
                        );
                      }).toList(),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
          // --- PAYMENT SUMMARY SECTION ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal'),
                    Text('₱${widget.totalAmount.toStringAsFixed(2)}'),  // Use widget.totalAmount
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Shipping Fee'),
                    const Text('₱50.00'),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('₱${finalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 245, 214, 37),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text('Place Order', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}