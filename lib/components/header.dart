import 'package:flutter/material.dart';
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

class ReusableHeaderState extends State<ReusableHeader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140.0, // Fixed height, no more expansion
      decoration: BoxDecoration(
        color: Color(0xFF1A31C8),
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
        child: Container(
          height: 80,
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              // Profile section - Only the avatar is clickable
              Row(
                children: [
                  // Clickable avatar
                  GestureDetector(
                    onTap: () {
                      if (widget.showBackButton) {
                        Navigator.pop(context);
                      } else {
                        // Navigate to Profile page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(
                              email: "john.smith@email.com",
                            ),
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      child: Icon(
                        widget.showBackButton ? Icons.arrow_back : Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  SizedBox(width: 14),
                  // Non-clickable text section
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
                        widget.showBackButton ? 'iTOURu' : 'Welcome to iTOURu!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
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
      ),
    );
  }
}
