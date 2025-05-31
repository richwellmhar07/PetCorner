// lib/models/order_model.dart

import 'dart:developer' as developer;

class Order {
  final int orderId;
  final int userId;
  final int productId;
  final String productName;
  final double productPrice;
  final int productQty;
  final String productImage;
  final double total;
  final String status;
  final String orderedDate;
  final String? receivedDate;

  Order({
    required this.orderId,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productQty,
    required this.productImage,
    required this.total,
    required this.status,
    required this.orderedDate,
    this.receivedDate,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Debug the raw JSON
    developer.log('Processing order JSON: $json', name: 'OrderModel');
    
    // IMPORTANT: Note the field name is 'productimage' in the API response, not 'product_image'
    String imagePathFromJson = json['productimage'] ?? '';
    developer.log('Image path from JSON: $imagePathFromJson', name: 'OrderModel');
    
    // Process the image path
    String processedImagePath = _processImagePath(imagePathFromJson);
    developer.log('Processed image path: $processedImagePath', name: 'OrderModel');

    return Order(
      orderId: json['order_id'] ?? 0,
      userId: json['user_id'] ?? 0, // Note: This might need to be user_id instead
      productId: json['productid'] ?? 0,
      productName: json['productname'] ?? 'Unknown Product',
      productPrice: _parseDouble(json['productprice']),
      productQty: json['productqty'] ?? 0,
      productImage: processedImagePath,
      total: _parseDouble(json['total']),
      status: json['status'] ?? 'Unknown',
      orderedDate: json['ordered_date'] ?? '',
      receivedDate: json['received_date'],
    );
  }
  
  // Helper method to process image path
  static String _processImagePath(dynamic imagePath) {
    if (imagePath == null || imagePath.toString().trim().isEmpty || imagePath == 'null') {
      return '';
    }
    
    String path = imagePath.toString();
    
    // Remove any leading slashes for proper URL construction
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    
    return path;
  }
  
  // Helper method to safely parse doubles
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        developer.log('Error parsing double: $value', name: 'OrderModel', error: e);
        return 0.0;
      }
    }
    
    return 0.0;
  }
}