import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'checkout_page.dart'; //IMPORTED CHECKOUT PAGE

class CartPage extends StatefulWidget {
  final int userId;
  const CartPage({super.key, required this.userId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<dynamic> cartItems = [];
  Set<int> selectedIndexes = {};
  double total = 0;

  Future<void> fetchCartData() async {
    final url = Uri.parse("http://192.168.1.19:5000/api/get_cart");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': widget.userId}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        cartItems = data['cart_items'];
        _calculateTotal();
      });
    } else {
      throw Exception("Failed to load cart");
    }
  }

  // Add this function to group cart items by shop
  List<Map<String, dynamic>> groupCartItemsByShop() {
    Map<String, List<dynamic>> shopGroups = {};
    
    for (var item in cartItems) {
      String shopName = item['shopname'] ?? 'Unknown Shop';
      
      if (!shopGroups.containsKey(shopName)) {
        shopGroups[shopName] = [];
      }
      
      shopGroups[shopName]!.add(item);
    }
    
    // Convert to list of shop groups
    List<Map<String, dynamic>> result = [];
    shopGroups.forEach((shopName, items) {
      result.add({
        'shopName': shopName,
        'sellerId': items.first['seller_id'], // Get seller_id from the first item
        'items': items,
      });
    });
    
    return result;
  }

  void _calculateTotal() {
    total = 0;
    for (var index in selectedIndexes) {
      final item = cartItems[index];
      total += double.tryParse(item['productprice'])! * item['productqty'];
    }
  }

  Future<Map<String, dynamic>> updateCartQuantity(int cartId, int quantity) async {
    var url = Uri.parse('http://192.168.1.19:5000/update_cart_quantity');
    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cartid': cartId, 'quantity': quantity}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
 //  delete product in the cart fucntion
  Future<void> deleteCartItem(int cartId) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.19:5000/delete_cart_item'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cartid': cartId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            cartItems.removeWhere((item) => item['cartid'] == cartId);
          });
        } else {
          // Handle error from backend
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Failed to delete item')),
          );
        }
      } else {
        // Handle HTTP error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server error')),
        );
      }
    } catch (e) {
      // Handle general error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  @override
  void initState() {
    super.initState();
    fetchCartData();
  }

  @override
  Widget build(BuildContext context) {
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
                'lib/assets/images/cart.png',
                width: 23, 
                height: 23,
              ),
              const SizedBox(width: 8),
              Text(
                'Shopping Cart (${cartItems.length})',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 8),
          // "Select All" Checkbox
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11.0),
            child: Row(
              children: [
                Checkbox(
                  value: selectedIndexes.length == cartItems.length && cartItems.isNotEmpty,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        // Select all indexes
                        selectedIndexes = List<int>.generate(cartItems.length, (index) => index).toSet();
                      } else {
                        // Deselect all
                        selectedIndexes.clear();
                      }
                      _calculateTotal();
                    });
                  },
                  activeColor: const Color.fromARGB(255, 245, 214, 37),
                  checkColor: const Color.fromARGB(255, 80, 79, 79),
                  side: const BorderSide(
                    width: 1.0,
                    color: Color.fromARGB(255, 158, 158, 157),
                  ),
                ),
                const SizedBox(width: 3),
                const Text(
                  'All',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: groupCartItemsByShop().length,
              itemBuilder: (context, shopIndex) {
                final shopGroup = groupCartItemsByShop()[shopIndex];
                final shopName = shopGroup['shopName'];
                final sellerId = shopGroup['sellerId'];
                final shopItems = shopGroup['items'] as List;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
                      child: Row(
                        children: [
                          Image.asset(
                            'lib/assets/images/shop.png',
                            width: 17,
                            height: 17,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  shopName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromARGB(255, 57, 57, 57),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(ID: $sellerId)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color.fromARGB(255, 248, 248, 242), // FONTTTTTTTTTTTTTTTTTTTTTT
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Divider(height: 1, thickness: 1, color: Color.fromARGB(255, 240, 240, 240)),
                    ),
                    
                    // Shop Items
                    ...shopItems.asMap().entries.map((entry) {
                      final itemIndex = cartItems.indexWhere((item) => item['cartid'] == entry.value['cartid']);
                      final item = entry.value;
                      final isSelected = selectedIndexes.contains(itemIndex);
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 0), 
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedIndexes.add(itemIndex);
                                    } else {
                                      selectedIndexes.remove(itemIndex);
                                    }
                                    _calculateTotal();
                                  });
                                },
                                side: const BorderSide(
                                  width: 1.0,
                                  color: Color.fromARGB(255, 158, 158, 157),
                                ),
                                activeColor: const Color.fromARGB(255, 245, 214, 37),
                                checkColor: const Color.fromARGB(255, 80, 79, 79),
                              ),
                            ),
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade200,
                                image: DecorationImage(
                                  image: NetworkImage(item['productimage']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [ 
                                  Text(
                                    item['productname'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w300),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '₱${double.tryParse(item['productprice'])?.toStringAsFixed(2) ?? "0.00"}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 88, 88, 88),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // qty section
                                  Transform.translate(
                                    offset: const Offset(90, -5),
                                    child: Container(
                                      height: 18,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // "-" button
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: IconButton(
                                              iconSize: 14,
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(Icons.remove),
                                              onPressed: () async {
                                                int currentQty = item['productqty'] ?? 1;
                                                if (currentQty > 1) {
                                                  setState(() {
                                                    item['productqty'] = currentQty - 1;
                                                  });
                                                  await updateCartQuantity(item['cartid'], item['productqty']);
                                                } else {
                                                  bool? confirmDelete = await showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      title: Text(
                                                        'Remove Product',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      content: Text(
                                                        'Do you want to remove this product from the cart?',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context, false),
                                                          child: Text(
                                                            'No',
                                                            style: TextStyle(fontSize: 13, color: Color.fromARGB(255, 80, 79, 79)), 
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context, true),
                                                          child: Text(
                                                            'Yes',
                                                            style: TextStyle(fontSize: 13, color: Color.fromARGB(255, 80, 79, 79)), 
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );

                                                  if (confirmDelete == true) {
                                                    await deleteCartItem(item['cartid']);
                                                  }
                                                }
                                              },
                                            ),
                                          ),
                                          // Quantity Text
                                          Container(
                                            width: 25,
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${item['productqty']}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          // "+" button
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: IconButton(
                                              iconSize: 14,
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(Icons.add),
                                              onPressed: () async {
                                                int currentQty = item['productqty'] ?? 1;
                                                int stock = item['productstocks'] ?? 0;

                                                print('Current Qty: $currentQty');
                                                print('Stock: $stock');

                                                if (stock == 0) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('No stock available for this product')),
                                                  );
                                                  return;
                                                }

                                                if (currentQty < stock) {
                                                  setState(() {
                                                    item['productqty'] = currentQty + 1;
                                                  });

                                                  var response = await updateCartQuantity(item['cartid'], item['productqty']);

                                                  if (response['success'] == true) {
                                                    print("Cart updated successfully");
                                                  } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text(response['error'] ?? 'Failed to update cart')),
                                                    );
                                                  }
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Reached maximum stock!'),
                                                      backgroundColor: Color.fromARGB(180, 86, 87, 86),
                                                    ),
                                                  );
                                                }
                                              }
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(7, -8),
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey),
                                iconSize: 17,
                                onPressed: () {
                                  deleteCartItem(item['cartid']);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₱${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                //CHECKOUT BUTTON WITH FUNCTION
                ElevatedButton(
                  onPressed: selectedIndexes.isNotEmpty
                    ? () {
                        List<dynamic> selectedItems = selectedIndexes.map((index) => cartItems[index]).toList();

                        // Group selected items by shop
                        Map<String, List<dynamic>> groupedByShop = {};
                        for (var item in selectedItems) {
                          String shopName = item['shopname'] ?? 'Unknown Shop';
                          if (!groupedByShop.containsKey(shopName)) {
                            groupedByShop[shopName] = [];
                          }
                          groupedByShop[shopName]!.add(item);
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutPage(
                              userId: widget.userId,
                              selectedItems: selectedItems,
                              totalAmount: total,
                              groupedItems: groupedByShop, // <- pass this
                            ),
                          ),
                        );
                      }
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 245, 214, 37),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Checkout', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}