import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'product.dart';
import 'cart.dart';
import 'orders.dart';
import 'notif.dart';
import 'account.dart';


class HomeBuyerScreen extends StatefulWidget {
  final int userId;

  const HomeBuyerScreen({super.key, required this.userId});

  @override
  State<HomeBuyerScreen> createState() => _HomeBuyerScreenState();
}


class _HomeBuyerScreenState extends State<HomeBuyerScreen> {
  int _currentIndex = 0;
  String _searchQuery = '';
  String _selectedCategory = '';

  final List<Map<String, String>> _categories = [
    {'name': 'Dog Food & Treats', 'image': 'lib/assets/images/dogfood.jpg'},
    {'name': 'Cat Litter & Accessories', 'image': 'lib/assets/images/catlitter.jpg'},
    {'name': 'Aquariums & Food', 'image': 'lib/assets/images/acquarium.jpg'},
    {'name': 'Bird Feeders & Food', 'image': 'lib/assets/images/birdfeed.jpg'},
    {'name': 'Pet Grooming', 'image': 'lib/assets/images/grooming.jpg'},
    {'name': 'Pet Care & Wellness', 'image': 'lib/assets/images/health.jpg'},
  ];

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final url = Uri.parse('http://192.168.1.19:5000/api/products');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _products = data.map((product) {
            double productQuality = double.tryParse(product['product_quality'].toString()) ?? 0.0;
            double feedback = double.tryParse(product['feedback'].toString()) ?? 1.0;

            double rating = feedback != 0 ? productQuality / feedback : 0.0;

            return {
              'productid': product['productid'],
              'name': product['productname'],
              'price': double.tryParse(product['productprice'].toString()) ?? 0.0,
              'image': product['productimage'],
              'rating': rating,
              'category': product['productcategory'],
            };
          }).toList();
          
          _filteredProducts = List.from(_products);
        });

      } else {
        print('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          ImageSlideshow(
            width: double.infinity,
            height: 140,
            initialPage: 0,
            indicatorColor: Colors.blue,
            indicatorBackgroundColor: Colors.grey,
            autoPlayInterval: 3000,
            isLoop: true,
            children: [
              Image.asset('lib/assets/images/C1.png', fit: BoxFit.cover),
              Image.asset('lib/assets/images/C2.png', fit: BoxFit.cover),
              Image.asset('lib/assets/images/C3.png', fit: BoxFit.cover),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Categories',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = '';
                          _filteredProducts = List.from(_products);
                        });
                      },
                      child: const Text(
                          'Show All',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.asMap().entries.map((entry) {
                        int index = entry.key;
                        var category = entry.value;
                        bool isSelected = _selectedCategory == category['name'];

                        return Padding(
                          padding: EdgeInsets.only(left: index == 0 ? 12 : 0, right: 12),
                          child: Material(
                            color: isSelected
                                ? const Color.fromARGB(255, 252, 227, 4)
                                : const Color.fromARGB(255, 248, 248, 248),
                            borderRadius: BorderRadius.circular(12),
                            elevation: 2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category['name']!;
                                  _filteredProducts = _products.where((product) {
                                    final productCategory = product['category']?.toString().toLowerCase() ?? '';
                                    return productCategory.contains(_selectedCategory.toLowerCase());
                                  }).toList();
                                });
                              },
                              splashColor: const Color.fromARGB(255, 246, 241, 79).withOpacity(0.2),
                              child: Container(
                                width: 72,
                                height: 72,
                                padding: const EdgeInsets.all(5),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(category['image']!, height: 28, width: 28, fit: BoxFit.cover),
                                    const SizedBox(height: 4),
                                    Text(
                                      category['name']!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 9),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
          ),
          const SizedBox(height: 20),
          const Text('Recommended Products', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductPage(
                          productId: int.parse(product['productid'].toString()),
                          userId: widget.userId,
                          productName: product['productname'] ?? 'No name available',
                          productPrice: double.tryParse(product['productprice'].toString()) ?? 0.0,
                          shopName: product['shopname'] ?? 'Unknown shop',
                          sellerId: int.tryParse(product['seller_id'].toString()) ?? 0,
                          productImage: product['productimage'] ?? '',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product['image'],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product['name'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₱${product['price'].toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(product['rating'].toString(), style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigateToPage(int index) {
    print('Navigating to tab index: $index'); // Add this debug statement
    
    if (index == 0) {
      // Stay on home page
      setState(() {
        _currentIndex = 0;
      });
      print('Staying on home page');
    } else if (index == 1) {
      // Navigate to Orders screen
      print('Attempting to navigate to Orders screen');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrdersScreen(userId: widget.userId),
        ),
      );
    } else if (index == 2) {
      // Navigate to Notifications screen
      print('Attempting to navigate to Notifications screen');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationBuyerScreen(userId: widget.userId),
        ),
      );
    } else if (index == 3) {
      // Navigate to Account screen
      print('Attempting to navigate to Account screen');
      try {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccountScreen(userId: widget.userId),
          ),
        );
      } catch (e) {
        print('Error navigating to Account screen: $e');
        // Fallback in case the AccountScreen has an issue
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Account: $e')),
        );
      }
    }
  }

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
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
                _filteredProducts =
                    _products.where((product) {
                      final name = product['name'].toString().toLowerCase();
                      return name.contains(_searchQuery);
                    }).toList();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search products...',
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
          IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartPage(userId: widget.userId),
              ),
            );
          }),
          IconButton(icon: const Icon(Icons.message), onPressed: () {}),
        ],
      ),
      body: _buildHomeContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: _navigateToPage,
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