import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class ImageDebugUtility {
  static Widget loadImage({
    required String imagePath,
    required String baseUrl,
    double width = 80,
    double height = 80,
    BoxFit fit = BoxFit.cover,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(5)),
  }) {
    // Log the image loading attempt
    developer.log('Attempting to load image: $imagePath', name: 'ImageDebug');
    
    if (imagePath.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius,
        ),
        child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
      );
    }

    // Normalize the image path
    String normalizedPath = imagePath;
    
    // Construct full URL if needed
    String fullUrl;
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      fullUrl = imagePath;
      developer.log('Using direct URL: $fullUrl', name: 'ImageDebug');
    } else {
      // Remove any leading slashes
      while (normalizedPath.startsWith('/')) {
        normalizedPath = normalizedPath.substring(1);
      }
      
      fullUrl = '$baseUrl/$normalizedPath';
      developer.log('Constructed URL: $fullUrl', name: 'ImageDebug');
    }

    // Return the image widget
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        fullUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          developer.log('Image error: $error', name: 'ImageDebug', error: error, stackTrace: stackTrace);
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: borderRadius,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                const SizedBox(height: 4),
                Text(
                  'Failed to load',
                  style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: borderRadius,
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                strokeWidth: 2,
              ),
            ),
          );
        },
      ),
    );
  }
}