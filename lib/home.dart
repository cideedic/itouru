import 'package:flutter/material.dart';
import 'package:itouru/feedback.dart';
import 'package:itouru/settings.dart';
import 'package:itouru/maps.dart';
import 'package:itouru/profile.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;
  double _dragStart = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    _dragStart = details.globalPosition.dy;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    double dragDistance = details.globalPosition.dy - _dragStart;
    if (dragDistance > 60 && !_isExpanded) {
      _toggleExpansion();
    } else if (dragDistance < -50 && _isExpanded) {
      _toggleExpansion();
    }
  }

  void _onMenuItemTap(String item) {
    // Close the expanded menu first
    if (_isExpanded) {
      _toggleExpansion();
    }

    // Handle navigation based on selected item
    switch (item) {
      case 'Home':
        break;
      case 'Map':
        // Navigate to Map page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Maps(),
          ), // Replace with your actual Map page
        );
        break;
      case 'Settings':
        // Navigate to Settings page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Settings(),
          ), // Replace with your actual Settings page
        );
        break;
      case 'Feedback':
        // Navigate to Feedback page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Feedbacks(),
          ), // This should match your feedback.dart class name
        );
        break;
      case 'Logout':
        // Handle logout functionality
        _showLogoutDialog();
        break;
      case 'Discover BU':
        // Handle Discover BU button
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Maps()),
        );
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$item selected')));
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Add your logout logic here
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Draggable Header with flexible height
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                // Calculate max height based on screen size
                final screenHeight = MediaQuery.of(context).size.height;
                final maxExpandedHeight =
                    screenHeight * 0.28; // 40% of screen height
                final baseHeight = 120.0;
                final expandedHeight = _animation.value * maxExpandedHeight;

                return Container(
                  height: baseHeight + expandedHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Top row with profile and QR code
                        Container(
                          height: 60,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              // Profile section - Tappable
                              GestureDetector(
                                onTap: () {
                                  // Navigate to Profile page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Profiles(),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hi Student Last! (Placeholder for DB)',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'BSIT 3rd Year (Placeholder for DB)',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Spacer(),
                              // QR Code icon
                              Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.qr_code_scanner,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Expanded menu options (scrollable)
                        if (_animation.value > 0)
                          Expanded(
                            child: Opacity(
                              opacity: _animation.value,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      SizedBox(height: 10),
                                      _buildMenuItem(Icons.home, 'Home'),
                                      _buildMenuItem(Icons.map, 'Map'),
                                      _buildMenuItem(
                                        Icons.feedback,
                                        'Feedback',
                                      ),
                                      _buildMenuItem(
                                        Icons.settings,
                                        'Settings',
                                      ),
                                      _buildMenuItem(Icons.logout, 'Logout'),
                                      SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

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
                      onPressed: () {
                        _onMenuItemTap('Discover BU');
                      },
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

  Widget _buildMenuItem(IconData icon, String title) {
    return GestureDetector(
      onTap: () => _onMenuItemTap(title),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        margin: EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: Row(
          children: [
            SizedBox(width: 40),
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
