
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../config/config.dart';
import 'dart:developer' as developer;


class OrderService {
  final String baseUrl = AppConfig.apiBaseUrl;
  
  Future<List<Order>> getUserOrders(int userId) async {
    try {
      developer.log('Fetching orders for user ID: $userId', name: 'OrderService');
      developer.log('API URL: $baseUrl/api/orders?user_id=$userId', name: 'OrderService');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders?user_id=$userId'),
      );
      
      if (response.statusCode == 200) {
        // Log the raw response for debugging
        developer.log('Raw API response: ${response.body}', name: 'OrderService');
        
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> ordersJson = data['orders'];
          
          // Debug each order's product image path
          for (var order in ordersJson) {
            developer.log('Product image from API: ${order['productimage']}', name: 'OrderService');
          }
          
          return ordersJson.map((json) => Order.fromJson(json)).toList();
        } else {
          throw Exception('Failed to load orders: ${data['message']}');
        }
      } else {
        developer.log('API error: ${response.statusCode} - ${response.body}', name: 'OrderService');
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Exception in getUserOrders: $e', name: 'OrderService', error: e);
      throw Exception('Error fetching orders: $e');
    }
  }

  
  

}