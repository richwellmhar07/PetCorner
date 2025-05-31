import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'cart.dart';

// ProductPage class ............................................................................
class ProductPage extends StatefulWidget {
  final int productId;
  final int userId;
  final String productName;
  final double productPrice;
  final String shopName;
  final int sellerId;
  final String productImage; // This is now a URL from your API

  const ProductPage({
    super.key,
    required this.productId,
    required this.userId,
    required this.productName,
    required this.productPrice,
    required this.shopName,
    required this.sellerId,
    required this.productImage,

  });

  @override
  State<ProductPage> createState() => _ProductPageState();
}// ProductPage class ..................................................

class _ProductPageState extends State<ProductPage> {

  Map<String, dynamic>? product;
  bool isLoading = true;
  int get userId => widget.userId;
  int quantity = 1;
  late String base64ProductImage = "";

  @override
  void initState() {
    super.initState();
    fetchProductDetails();
    
  }

 // Add to cart ..........................................................
  Future<void> addToCart() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Prepare the cart item data
      final Map<String, dynamic> cartItem = {
        'user_id': widget.userId,
        'product_id': widget.productId,
        'product_name': product!['productname'],
        'product_price': product!['productprice'].toString(),
        'product_qty': quantity,
        'shop_name': product!['shopname'],
        'seller_id': product!['seller_id'],
        // Get the image as base64 if your API requires it
        // You'd normally need to convert the image to base64, but since your
        // product image is already a URL, we'll handle this differently
        'product_image': product!['productimage'],
      };

      // Send POST request to add item to cart
      final response = await http.post(
        Uri.parse('http://192.168.1.19:5000/api/cart/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(cartItem),
      );

      // Close loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to cart successfully!'),
            backgroundColor: Color.fromARGB(180, 86, 87, 86),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Show error message with details from response
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Failed to add to cart';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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
          content: Text('Error adding to cart: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      print('Error adding to cart: $e');
    }
  }

  // Fetching Products ..........................................................................
  Future<void> fetchProductDetails() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.19:5000/api/products'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        // Find the product with the matching ID
        final result = data.firstWhere((p) => p['productid'] == widget.productId);
        setState(() {
          product = result;
          isLoading = false;
        });
      } else {
        print("Error fetching product: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Exception fetching product: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (product == null) {
      return const Scaffold(body: Center(child: Text("Product not found")));
    }

    final quality = double.tryParse(product!['product_quality'].toString()) ?? 0.0;
    final feedback = double.tryParse(product!['feedback'].toString()) ?? 1.0; // prevent division by zero
    final rating = (feedback != 0) ? (quality / feedback) : 0.0;
    final ratingText = '${rating.toStringAsFixed(1)}⭐ Product Ratings (${feedback.toInt()})';

    return Scaffold(
      appBar: AppBar(
        title: Transform.translate(
          offset: const Offset(-17, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'lib/assets/images/shop.png',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              Text(
                product!['shopname'] ?? 'Shop',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Transform.translate(
            offset: const Offset(-10, 0),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartPage(userId: widget.userId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              product!['productimage'],
              width: double.infinity,
              height: 350,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),

            // Price
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '₱${(double.tryParse(product!['productprice'].toString()) ?? 0.0).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  color: Color.fromARGB(255, 88, 88, 88),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Product Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                product!['productname'],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                product!['productdescription'] ?? '',
                style: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16), // Adding some space before showing the productid

            // Product ID
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'PID: ${product!['productid']}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),

            const SizedBox(height: 50),

            // Ratings and Stocks
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ratingText,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Stocks: ${product!['productstocks'] ?? 0}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Quantity Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SID: ${product!['seller_id']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  // Quantity Control 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end, // Align to the right side
                    children: [
                      // Quantity control with border (Matching the style from cart.dart)
                      Container(
                        height: 18, // Same height as in cart
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4), // Same border radius as in cart
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // To ensure it only takes the necessary space
                          children: [
                            // "-" button
                            SizedBox(
                              width: 20, // Match the button size in cart
                              height: 20, // Match the button size in cart
                              child: IconButton(
                                iconSize: 14, // Smaller icon size for the button
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (quantity > 1) {
                                    setState(() {
                                      quantity--;
                                    });
                                  }
                                },
                              ),
                            ),
                            // Quantity value
                            Container(
                              width: 25, // Ensure width is small, matching cart's quantity text width
                              alignment: Alignment.center,
                              child: Text(
                                '$quantity',
                                style: const TextStyle(fontSize: 12), // Smaller font size
                              ),
                            ),
                            // "+" button
                            SizedBox(
                              width: 20, // Match the button size in cart
                              height: 20, // Match the button size in cart
                              child: IconButton(
                                iconSize: 14, // Smaller icon size for the button
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  if (quantity < (product!['productstocks'] ?? 0)) {
                                    setState(() {
                                      quantity++;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Product Reviews Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Product Reviews',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            // Sample Review Entry (Repeat for each review)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Buyer Name
                      Text(
                        'Juan Dela Cruz',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),

                      // Edit icon (only show for buyer's own review)
                      Icon(Icons.edit, size: 18, color: Colors.grey),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Star Rating
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < 4 ? Icons.star : Icons.star_border, // Example: 4 stars
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),

                  const SizedBox(height: 6),

                  // Review Comment
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Maganda yung item. Fast delivery din!',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Like and Heart Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(Icons.thumb_up_alt_outlined, size: 20),
                        onPressed: () {
                          // Handle like
                        },
                      ),
                      Text('12'),

                      const SizedBox(width: 16),

                      IconButton(
                        icon: Icon(Icons.favorite_border, size: 20, color: Colors.redAccent),
                        onPressed: () {
                          // Handle heart/favorite
                        },
                      ),
                      Text('5'),
                    ],
                  ),

                  Divider(),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Contact Seller (with click effect)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                // Handle contact seller action
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.chat_bubble_outline, color: Color.fromARGB(255, 245, 214, 37)),
                  SizedBox(height: 4),
                  Text('Contact Seller', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),

            // Add to Cart Button
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                // Check if the user is logged in (userId should be valid)
                if (widget.userId <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please log in to add items to your cart'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Check if there's enough stock before adding to cart
                int availableStock = int.tryParse(product!['productstocks'].toString()) ?? 0;
                if (availableStock < 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product is out of stock'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Call the addToCart function
                addToCart();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.add_shopping_cart, 
                    color: Color.fromARGB(255, 245, 214, 37), // Yellow color for the icon
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add to Cart', 
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            // Buy Now button with rounded corners
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 245, 214, 37),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                // Handle buy now action
              },
              child: const Text('Buy Now', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
