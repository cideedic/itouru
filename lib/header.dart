import 'package:flutter/material.dart';
import 'package:itouru/feedback.dart';
import 'package:itouru/settings.dart';
import 'package:itouru/maps.dart';
import 'package:itouru/profile.dart';

class ReusableHeader extends StatefulWidget {
  final String? pageTitle; // Optional title to show current page
  final bool showBackButton; // Whether to show back button instead of profile

  const ReusableHeader({
    super.key,
    this.pageTitle,
    this.showBackButton = false,
  });

  @override
  ReusableHeaderState createState() => ReusableHeaderState();
}

class ReusableHeaderState extends State<ReusableHeader>
    with TickerProviderStateMixin {
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
        // Navigate to Home - replace all routes to prevent stack buildup
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        break;
      case 'Map':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Maps()),
        );
        break;
      case 'Settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Settings()),
        );
        break;
      case 'Feedback':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Feedbacks()),
        );
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$item selected')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Calculate max height based on screen size
          final screenHeight = MediaQuery.of(context).size.height;
          final maxExpandedHeight = screenHeight * 0.30;
          final baseHeight = 140.0;
          final expandedHeight = _animation.value * maxExpandedHeight;

          return Container(
            height: baseHeight + expandedHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
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
                  // Top row with profile/back button and QR code
                  Container(
                    height: 80,
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        // Profile section or Back button - Tappable
                        GestureDetector(
                          onTap: () {
                            if (widget.showBackButton) {
                              Navigator.pop(context);
                            } else {
                              // Navigate to Profile page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Profiles(),
                                ),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.3,
                                ),
                                child: Icon(
                                  widget.showBackButton
                                      ? Icons.arrow_back
                                      : Icons.person,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              SizedBox(width: 14),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.pageTitle ?? 'Hi Student Last!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    widget.showBackButton
                                        ? 'iTOURu'
                                        : 'BSIT 3rd Year',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 14,
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
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 28,
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
                                _buildMenuItem(Icons.feedback, 'Feedback'),
                                _buildMenuItem(Icons.settings, 'Settings'),
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
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return GestureDetector(
      onTap: () => _onMenuItemTap(title),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        margin: EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: Row(
          children: [
            SizedBox(width: 40),
            Icon(icon, color: Colors.white, size: 22),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
