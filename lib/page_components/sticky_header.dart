import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StickyHeader extends StatelessWidget {
  final bool isVisible;
  final String title;
  final String? abbreviation; //  Pass the actual abbreviation/nickname
  final String? logoImageUrl;
  final bool showLogo; //  Control whether to show logo
  final VoidCallback? onBackPressed;

  const StickyHeader({
    super.key,
    required this.isVisible,
    required this.title,
    this.abbreviation,
    this.logoImageUrl,
    this.showLogo = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Use abbreviation if provided and title is long, otherwise use full title
    final displayTitle =
        (abbreviation != null && abbreviation!.isNotEmpty && title.length > 25)
        ? abbreviation!
        : title;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      top: isVisible ? 0 : -135,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(
          top: 12,
          bottom: 14,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.42, 0.85],
            colors: [
              const Color(0xFF203BE6).withValues(alpha: 0.95),
              const Color(0xFF1A31C8).withValues(alpha: 0.95),
              const Color(0xFF060870).withValues(alpha: 0.95),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed:
                      onBackPressed ??
                      () {
                        if (Navigator.canPop(context)) {
                          Navigator.of(context).pop();
                        }
                      },
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 12),
              // Only show logo container if showLogo is true
              if (showLogo) ...[
                Container(
                  width: 45,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: logoImageUrl != null
                          ? Image.network(
                              logoImageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.school,
                                  color: Colors.blue,
                                  size: 25,
                                );
                              },
                            )
                          : const Icon(
                              Icons.school,
                              color: Colors.blue,
                              size: 25,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  displayTitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
