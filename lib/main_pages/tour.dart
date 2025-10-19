import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/header.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class Feedbacks extends StatefulWidget {
  const Feedbacks({super.key});

  @override
  FeedbacksState createState() => FeedbacksState();
}

class FeedbacksState extends State<Feedbacks> {
  int _selectedRating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  final supabase = Supabase.instance.client;

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

  Future<void> _submitFeedback() async {
    // Validate input
    if (_selectedRating == 0 || _feedbackController.text.trim().isEmpty) {
      _showModal(
        message: 'Please provide a rating and feedback',
        backgroundColor: Colors.red[50]!,
        textColor: const Color.fromARGB(255, 207, 80, 80),
        icon: Icons.error,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userResponse = await supabase
          .from('Users')
          .select('user_id')
          .eq('email', user.email!)
          .single();

      final userId = userResponse['user_id'];

      // Generate a random bigint for feedback_id
      final feedbackId = Random().nextInt(9007199254740991);

      await supabase.from('Feedback').insert({
        'feedback_id': feedbackId, // Add this line
        'user_id': userId,
        'rating': _selectedRating,
        'description': _feedbackController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

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
            _isSubmitting = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      _showModal(
        message: 'Failed to submit feedback. Please try again.',
        backgroundColor: Colors.red[50]!,
        textColor: const Color.fromARGB(255, 207, 80, 80),
        icon: Icons.error,
      );

      print('Error submitting feedback: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          ReusableHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SizedBox(height: 30),

                  // Feedback illustration
                  Image.asset(
                    'assets/images/feedback_image.png',
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        child: Icon(
                          Icons.feedback_outlined,
                          size: 100,
                          color: Colors.orange[300],
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 30),

                  // Rate Our App title
                  Text(
                    'Rate Our App',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Like the app? Rate our app then.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 24),

                  // Star rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: _isSubmitting
                            ? null
                            : () => _onStarTap(index + 1),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.star,
                            size: 42,
                            color: index < _selectedRating
                                ? Colors.orange[400]
                                : Colors.grey[300],
                          ),
                        ),
                      );
                    }),
                  ),

                  SizedBox(height: 32),

                  // Your Experience so far label
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Your Experience so far',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Feedback text field
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _feedbackController,
                      enabled: !_isSubmitting,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your feedback here...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[400],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Submit',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ReusableBottomNavBar(currentIndex: 3),
    );
  }
}
