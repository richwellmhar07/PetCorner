import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../config/config.dart';



class RateOrderScreen extends StatefulWidget {
  final int orderId;
  final List<Order> orders;

  const RateOrderScreen({
    Key? key,
    required this.orderId,
    required this.orders,
  }) : super(key: key);

  @override
  State<RateOrderScreen> createState() => _RateOrderScreenState();
}

class _RateOrderScreenState extends State<RateOrderScreen> {
  final Map<int, double> _ratings = {};
  final Map<int, TextEditingController> _commentControllers = {};
  
  @override
  void initState() {
    super.initState();
    // Initialize ratings and comment controllers for each product
    for (var order in widget.orders) {
      _ratings[order.productId] = 5.0; 
      _commentControllers[order.productId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    // Dispose all text controllers
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Rate Products',
          style: TextStyle(
            fontSize: 17,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.orders.length,
              itemBuilder: (context, index) {
                final order = widget.orders[index];
                return _buildRatingCard(order);
              },
            ),
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildRatingCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
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
                        'P${order.productPrice.toStringAsFixed(2)} x ${order.productQty}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Rating
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Rating',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _ratings[order.productId]?.toStringAsFixed(1) ?? '5.0',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Slider(
                        value: _ratings[order.productId] ?? 5.0,
                        min: 1.0,
                        max: 5.0,
                        divisions: 8,
                        activeColor: Colors.orange,
                        inactiveColor: Colors.orange.withOpacity(0.2),
                        onChanged: (value) {
                          setState(() {
                            _ratings[order.productId] = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                _buildStarRating(_ratings[order.productId] ?? 5.0),
              ],
            ),
          ),
          
          // Comment
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Review (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentControllers[order.productId],
                  decoration: InputDecoration(
                    hintText: 'Share your experience with this product...',
                    hintStyle: TextStyle(
                      color: const Color.fromARGB(255, 146, 145, 145),
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: const Color.fromARGB(255, 127, 127, 127)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: const Color.fromARGB(255, 136, 135, 135)!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 3,
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

  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return const Icon(Icons.star, color: Colors.orange, size: 24);
        } else if (index == fullStars && hasHalfStar) {
          return const Icon(Icons.star_half, color: Colors.orange, size: 24);
        } else {
          return const Icon(Icons.star_border, color: Colors.orange, size: 24);
        }
      }),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 226, 225, 225),
            spreadRadius: 0,
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: const BorderSide(color: Colors.grey, width: 0.7),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _submitRatings,
          child: const Text(
            'Submit Ratings',
            style: TextStyle(
              color: Color.fromARGB(255, 68, 66, 66),
             
            ),
          ),
        ),
      ),
    );
  }

  void _submitRatings() {
    // Here you would implement the actual submission logic
    
    // For now, just show a success message and go back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ratings submitted successfully'),
        backgroundColor: Color.fromARGB(180, 86, 87, 86),
      ),
    );
    
    Navigator.pop(context);
  }
}