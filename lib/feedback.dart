import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/components/header.dart'; // Import the reusable header
import 'package:itouru/components/bottom_nav_bar.dart'; // Import the bottom nav bar

class Feedbacks extends StatefulWidget {
  const Feedbacks({super.key});

  @override
  FeedbacksState createState() => FeedbacksState();
}

class FeedbacksState extends State<Feedbacks> {
  int _selectedRating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _onStarTap(int rating) {
    setState(() {
      _selectedRating = rating;
    });
  }

  void _showModal({
    required String message,
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: textColor, size: 32),
                SizedBox(height: 12),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    // Auto-dismiss after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  void _submitFeedback() {
    // Handle feedback submission
    if (_selectedRating > 0 && _feedbackController.text.isNotEmpty) {
      // Show success modal
      _showModal(
        message: 'Thank you for your feedback!',
        backgroundColor: Colors.green[50]!,
        textColor: const Color.fromARGB(255, 91, 194, 96),
        icon: Icons.check_circle,
      );

      // Clear form after showing modal
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _selectedRating = 0;
            _feedbackController.clear();
          });
        }
      });
    } else {
      // Show error modal
      _showModal(
        message: 'Please provide a rating and feedback',
        backgroundColor: Colors.red[50]!,
        textColor: const Color.fromARGB(255, 207, 80, 80),
        icon: Icons.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          // Use the reusable header without back button
          ReusableHeader(),

          // Main content area
          Expanded(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SizedBox(height: 40),

                    // Logo section
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/itouru_logo.png',
                          width: 220,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),

                    SizedBox(height: 25),

                    // Rate us text
                    Text(
                      'Rate us!',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Star rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => _onStarTap(index + 1),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.star,
                              size: 36,
                              color: index < _selectedRating
                                  ? Colors.orange[400]
                                  : Colors.grey[300],
                            ),
                          ),
                        );
                      }),
                    ),

                    SizedBox(height: 40),

                    // Feedback text field
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: TextField(
                        controller: _feedbackController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type your feedback here',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    SizedBox(height: 30),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Submit',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // Bottom padding
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ReusableBottomNavBar(currentIndex: 3),
    );
  }
}
