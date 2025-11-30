import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/login_components/guest_restriction_modal.dart';
import 'dart:math';
import 'dart:ui';

class FeedbackSection extends StatefulWidget {
  final Animation<Offset>? slideAnimation;
  final Animation<double>? fadeAnimation;

  const FeedbackSection({super.key, this.slideAnimation, this.fadeAnimation});

  @override
  State<FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends State<FeedbackSection> {
  int _selectedRating = 0;
  final TextEditingController _feedbackTextController = TextEditingController();
  bool _isSubmitting = false;
  final supabase = Supabase.instance.client;

  bool _isGuestUser() {
    final user = supabase.auth.currentUser;
    if (user == null) return true;

    final isAnonymous =
        user.isAnonymous ||
        user.appMetadata['provider'] == 'anonymous' ||
        user.email == null ||
        user.email!.isEmpty;

    return isAnonymous;
  }

  void _showGuestRestriction() {
    showDialog(
      context: context,
      builder: (context) => const GuestRestrictionModal(feature: 'Feedback'),
    );
  }

  void _showModal({
    required String message,
    required Color backgroundColor,
    required Color iconColor,
    required IconData icon,
    String? title,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        Future.delayed(const Duration(seconds: 3), () {
          if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext).pop();
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: iconColor),
                ),
                const SizedBox(height: 20),
                if (title != null) ...[
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitFeedback() async {
    if (_selectedRating == 0 || _feedbackTextController.text.trim().isEmpty) {
      _showModal(
        title: 'Incomplete Feedback',
        message: 'Please provide both a rating and your feedback to continue.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        iconColor: Colors.red,
        icon: Icons.error_outline,
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

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomPart = Random().nextInt(999999);
      final feedbackId = int.parse('$timestamp$randomPart');

      await supabase.from('Feedback').insert({
        'feedback_id': feedbackId,
        'user_id': userId,
        'rating': _selectedRating,
        'description': _feedbackTextController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      _showModal(
        title: 'Thank You!',
        message:
            'Your feedback has been submitted successfully. We appreciate your input!',
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        iconColor: Colors.green,
        icon: Icons.check_circle_outline,
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _selectedRating = 0;
            _feedbackTextController.clear();
            _isSubmitting = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      _showModal(
        title: 'Submission Failed',
        message:
            'Unable to submit your feedback. Please check your connection and try again.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        iconColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  void _onStarTap(int rating) {
    setState(() {
      _selectedRating = rating;
    });
  }

  @override
  void dispose() {
    _feedbackTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          // Title with decorative elements
          Stack(
            alignment: Alignment.center,
            children: [
              // Background Icon
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.orange.withValues(alpha: 0.15),
                      Colors.orange.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.feedback,
                    size: 120,
                    color: Colors.orange.withValues(alpha: 0.12),
                  ),
                ),
              ),

              // Title
              FadeTransition(
                opacity: widget.fadeAnimation ?? AlwaysStoppedAnimation(0.0),
                child: SlideTransition(
                  position:
                      widget.slideAnimation ??
                      AlwaysStoppedAnimation(Offset.zero),
                  child: Column(
                    children: [
                      Text(
                        'Feedback',
                        style: GoogleFonts.montserrat(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Enhanced content card
          FadeTransition(
            opacity: widget.fadeAnimation ?? AlwaysStoppedAnimation(0.0),
            child: GestureDetector(
              onTap: _isGuestUser() ? _showGuestRestriction : null,
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.orange.shade50.withValues(alpha: 0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Section header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade400,
                                    Colors.orange.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.feedback_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'We Value Your Feedback',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Divider with dots
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.orange.withValues(alpha: 0.3),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade400,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange.withValues(alpha: 0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Feedback description text
                        Text(
                          'Share your experience with us',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.7,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // Star rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: (_isSubmitting || _isGuestUser())
                                  ? null
                                  : () => _onStarTap(index + 1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Icon(
                                  index < _selectedRating
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: index < _selectedRating ? 36 : 32,
                                  color: index < _selectedRating
                                      ? Colors.orange[400]
                                      : Colors.grey[300],
                                ),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 20),

                        // Feedback text field
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _feedbackTextController,
                            enabled: !_isSubmitting && !_isGuestUser(),
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: _isGuestUser()
                                  ? 'Sign in to share feedback...'
                                  : 'Share your feedback...',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (_isSubmitting || _isGuestUser())
                                ? null
                                : _submitFeedback,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.zero,
                              disabledBackgroundColor: Colors.grey[300],
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Ink(
                                    decoration: BoxDecoration(
                                      gradient: (_isGuestUser())
                                          ? null
                                          : LinearGradient(
                                              colors: [
                                                Colors.orange.shade400,
                                                Colors.orange.shade600,
                                              ],
                                            ),
                                      color: _isGuestUser()
                                          ? Colors.grey[300]
                                          : null,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _isGuestUser()
                                                ? 'Sign In Required'
                                                : 'Submit Feedback',
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (!_isGuestUser()) ...[
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isGuestUser())
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.1),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      size: 48,
                                      color: Colors.orange[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Sign in to access',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap to learn more',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
