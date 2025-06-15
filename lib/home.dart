import 'package:flutter/material.dart';
import 'package:itouru/header.dart'; // Import the new header
import 'package:itouru/maps.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  void _onDiscoverBUTap(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Maps()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Use the reusable header
          ReusableHeader(),

          // Main content area (scrollable)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey[200]!, Colors.white],
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Add some top spacing
                    SizedBox(height: 80),
                    Text(
                      'iTOURu',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Your Bicol University Navigation Guide',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () => _onDiscoverBUTap(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[400],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Discover BU',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 60),
                    Text(
                      'Featured Locations',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 20),
                    // Featured locations - empty space for future images
                    SizedBox(
                      height: 120,
                      child: Center(
                        child: Text(
                          'Featured location images will be added here',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                    // Add bottom padding to ensure content doesn't get cut off
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
