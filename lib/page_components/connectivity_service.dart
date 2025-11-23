// lib/page_components/connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Callback when connectivity changes
  Function(bool isConnected)? onConnectivityChanged;

  /// Initialize connectivity monitoring
  void initialize() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final isConnected = !results.contains(ConnectivityResult.none);
      onConnectivityChanged?.call(isConnected);
    });
  }

  /// Check if device has internet connection
  Future<bool> hasConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final isConnected = !results.contains(ConnectivityResult.none);
      return isConnected;
    } catch (e) {
      return false;
    }
  }

  /// Show no internet dialog
  static void showNoInternetDialog(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NoInternetDialog(onRetry: onRetry),
    );
  }

  /// Dispose of connectivity subscription
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

/// No Internet Dialog Widget
class NoInternetDialog extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetDialog({super.key, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wifi_off, size: 40, color: Colors.red.shade400),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Internet Connection',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Please check your internet connection and try again.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            '• Turn off WiFi and Mobile Data to test\n'
            '• Check if Airplane Mode is on\n'
            '• Try restarting your router',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.left,
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            'OK',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();

            // Check connection again
            final hasConnection = await ConnectivityService().hasConnection();

            if (hasConnection) {
              // Connection restored
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Connection restored!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              }

              // Call retry callback if provided
              onRetry?.call();
            } else {
              // Still no connection
              if (context.mounted) {
                ConnectivityService.showNoInternetDialog(
                  context,
                  onRetry: onRetry,
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Try Again', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
