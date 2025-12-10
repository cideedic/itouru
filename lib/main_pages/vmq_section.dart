import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VMQSection extends StatefulWidget {
  final Animation<Offset>? slideAnimation;
  final Animation<double>? fadeAnimation;

  const VMQSection({super.key, this.slideAnimation, this.fadeAnimation});

  @override
  State<VMQSection> createState() => _VMQSectionState();
}

class _VMQSectionState extends State<VMQSection> with TickerProviderStateMixin {
  String? expandedCard;
  late AnimationController _visionController;
  late AnimationController _missionController;
  late AnimationController _qualityController;

  late Animation<double> _visionAnimation;
  late Animation<double> _missionAnimation;
  late Animation<double> _qualityAnimation;

  @override
  void initState() {
    super.initState();

    _visionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _missionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _qualityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _visionAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _visionController, curve: Curves.easeInOut),
    );
    _missionAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _missionController, curve: Curves.easeInOut),
    );
    _qualityAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _qualityController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _visionController.dispose();
    _missionController.dispose();
    _qualityController.dispose();
    super.dispose();
  }

  void _handleCardTap(String cardName) async {
    if (expandedCard == cardName) {
      // Collapse if already expanded
      setState(() {
        expandedCard = null;
      });
      _resetAllAnimations();
    } else {
      // First, shrink the previously expanded card if any
      if (expandedCard != null) {
        _resetAllAnimations();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Then expand the selected card
      setState(() {
        expandedCard = cardName;
      });
      _updateAnimations(cardName);
    }
  }

  void _resetAllAnimations() {
    _visionController.reverse();
    _missionController.reverse();
    _qualityController.reverse();
  }

  void _updateAnimations(String expandedCardName) {
    if (expandedCardName == 'vision') {
      _visionAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: _visionController, curve: Curves.easeInOut),
      );
      _missionAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
        CurvedAnimation(parent: _missionController, curve: Curves.easeInOut),
      );
      _qualityAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
        CurvedAnimation(parent: _qualityController, curve: Curves.easeInOut),
      );

      _visionController.forward();
      _missionController.forward();
      _qualityController.forward();
    } else if (expandedCardName == 'mission') {
      _visionAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
        CurvedAnimation(parent: _visionController, curve: Curves.easeInOut),
      );
      _missionAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: _missionController, curve: Curves.easeInOut),
      );
      _qualityAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
        CurvedAnimation(parent: _qualityController, curve: Curves.easeInOut),
      );

      _visionController.forward();
      _missionController.forward();
      _qualityController.forward();
    } else if (expandedCardName == 'quality') {
      _visionAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
        CurvedAnimation(parent: _visionController, curve: Curves.easeInOut),
      );
      _missionAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
        CurvedAnimation(parent: _missionController, curve: Curves.easeInOut),
      );
      _qualityAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: _qualityController, curve: Curves.easeInOut),
      );

      _visionController.forward();
      _missionController.forward();
      _qualityController.forward();
    }
  }

  Widget _buildCard({
    required String title,
    required String content,
    required IconData icon,
    required String cardName,
    required Animation<double> scaleAnimation,
  }) {
    final isExpanded = expandedCard == cardName;

    return ScaleTransition(
      scale: scaleAnimation,
      child: GestureDetector(
        onTap: () => _handleCardTap(cardName),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.orange.shade50.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpanded
                  ? Colors.orange.shade400
                  : Colors.orange.withValues(alpha: 0.2),
              width: isExpanded ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isExpanded
                    ? Colors.orange.withValues(alpha: 0.3)
                    : Colors.orange.withValues(alpha: 0.15),
                blurRadius: isExpanded ? 25 : 15,
                offset: Offset(0, isExpanded ? 10 : 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade400,
                          Colors.orange.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[700],
                  height: 1.6,
                ),
                maxLines: isExpanded ? null : 3,
                overflow: isExpanded ? null : TextOverflow.ellipsis,
              ),
              if (!isExpanded) ...[
                const SizedBox(height: 8),
                Text(
                  'Tap to read more',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.orange.shade600,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (expandedCard != null) {
          setState(() {
            expandedCard = null;
          });
          _resetAllAnimations();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        color: Colors.transparent,
        child: Column(
          children: [
            // Title Section with Slide and Fade Animation
            Stack(
              alignment: Alignment.center,
              children: [
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
                      Icons.business_center,
                      size: 90,
                      color: Colors.orange.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: widget.fadeAnimation ?? AlwaysStoppedAnimation(0.0),
                  child: SlideTransition(
                    position:
                        widget.slideAnimation ??
                        AlwaysStoppedAnimation(Offset.zero),
                    child: Column(
                      children: [
                        Text(
                          'Our Foundation',
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
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
            const SizedBox(height: 20),

            // Cards Container with Fade Animation
            FadeTransition(
              opacity: widget.fadeAnimation ?? AlwaysStoppedAnimation(0.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.orange.shade50.withValues(alpha: 0.2),
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
                    // Vision Card
                    _buildCard(
                      title: 'Vision',
                      content:
                          'A University for Humanity characterized by productive scholarship, transformative leadership, collaborative service, and distinctive character for sustainable societies.',
                      icon: Icons.visibility,
                      cardName: 'vision',
                      scaleAnimation: _visionAnimation,
                    ),
                    const SizedBox(height: 12),

                    // Mission Card
                    _buildCard(
                      title: 'Mission',
                      content:
                          'The Bicol University shall give professional and technical training, and provide advanced and specialized instruction in literature, philosophy, the sciences and arts, besides providing for the promotion of scientific and technological researches (RA 5521, Sec. 3.0).',
                      icon: Icons.flag,
                      cardName: 'mission',
                      scaleAnimation: _missionAnimation,
                    ),
                    const SizedBox(height: 12),

                    // Quality Policy Card
                    _buildCard(
                      title: 'Quality Policy',
                      content:
                          'Bicol University commits to continually strive for excellence in instruction, research, and extension by meeting the highest level of clientele satisfaction and adhering to quality standards and applicable statutory and regulatory requirements.',
                      icon: Icons.workspace_premium,
                      cardName: 'quality',
                      scaleAnimation: _qualityAnimation,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
