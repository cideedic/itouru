import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/header.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _creatorKeys = List.generate(4, (_) => GlobalKey());
  final List<bool> _hasAnimated = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    for (int i = 0; i < _creatorKeys.length; i++) {
      if (!_hasAnimated[i]) {
        final RenderBox? renderBox =
            _creatorKeys[i].currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          final screenHeight = MediaQuery.of(context).size.height;

          if (position.dy < screenHeight * 0.7) {
            setState(() {
              _hasAnimated[i] = true;
            });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ReusableHeader(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // Back Button and Title
                  Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.arrow_back,
                            color: Colors.black87,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'About iTOURu',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // What is iTOURu Section
                  _buildInfoCard(
                    icon: Icons.explore,
                    iconColor: Colors.blue,
                    title: 'What is iTOURu?',
                    description:
                        'iTOURu is an interactive mobile campus guide developed as a thesis/capstone project for Bicol University - West Campus. This navigation application helps students, faculty, and visitors explore the campus with ease by providing essential information about colleges, academic and non-academic buildings, offices, services, and the rich historical heritage of the university.\n\nMore than just a navigation tool, iTOURu serves as a digital gateway to appreciate and understand the history and heritage of Bicol University, making campus exploration both informative and engaging.',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.lightbulb_outline,
                    iconColor: Color(0xFFFF8C00),
                    title: 'Our Inspiration',
                    description:
                        'The idea for iTOURu was born from observing the daily navigation challenges faced by our campus community. First-year students often struggle to locate their classrooms in unfamiliar buildings, spending precious time wandering through corridors. Faculty members frequently find themselves getting lost when offices are relocated to different locations across campus. Visitors and guests have difficulty navigating the sprawling campus grounds without proper guidance. New employees face the challenge of trying to familiarize themselves with the vast array of campus facilities and services. Recognizing these pain points, we envisioned a solution that would make campus navigation effortless while simultaneously promoting awareness of our university\'s cultural and historical significance.',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFFFF8C00),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Note: iTOURu is designed for navigation purposes only. It serves as a guide to help you explore and discover Bicol University - West Campus.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Color(0xFFFF8C00),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Meet the Creators Section
                  Center(child: _buildSectionTitle('Meet the Creators')),
                  const SizedBox(height: 25),

                  // Creator panels
                  CreatorPanel(
                    key: _creatorKeys[0],
                    name: 'TERRENZE\nJOSH',
                    rolesText: 'Admin Side Developer\nDatabase Manager',
                    imagePath: 'assets/images/ter1.png',
                    motto: 'Sana makapasa sa defense',
                    mottoAuthor: 'Terrenze Josh M. Binamira',
                    shouldAnimate: _hasAnimated[0],
                    delay: 0,
                  ),
                  const SizedBox(height: 40),
                  CreatorPanel(
                    key: _creatorKeys[1],
                    name: 'ERICCAH\nJOYCE',
                    rolesText: 'Database Manager\nProject Lead',
                    imagePath: 'assets/images/erika1.png',
                    motto: 'Sana makapasa sa defense',
                    mottoAuthor: 'Ericcah Joyce B. Braga',
                    shouldAnimate: _hasAnimated[1],
                    delay: 0,
                  ),
                  const SizedBox(height: 40),
                  CreatorPanel(
                    key: _creatorKeys[2],
                    name: 'MA. ALEXA\nNICOLE',
                    rolesText: 'Capstone Papers\nDocumentation',
                    imagePath: 'assets/images/nix1.png',
                    motto: 'Sana makapasa sa defense',
                    mottoAuthor: 'Ma. Alexa Nicole P. Boroc',
                    shouldAnimate: _hasAnimated[2],
                    delay: 0,
                  ),
                  const SizedBox(height: 40),
                  CreatorPanel(
                    key: _creatorKeys[3],
                    name: 'JOHN\nCEDRICK',
                    rolesText: 'Mobile Application Developer',
                    imagePath: 'assets/images/ced1.png',
                    motto: 'Sana makapasa sa defense',
                    mottoAuthor: 'John Cedrick M. Lensoco',
                    shouldAnimate: _hasAnimated[3],
                    delay: 0,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ReusableBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class CreatorPanel extends StatefulWidget {
  final String name;
  final String rolesText;
  final String imagePath;
  final String motto;
  final String mottoAuthor;
  final int delay;
  final bool shouldAnimate;

  const CreatorPanel({
    super.key,
    required this.name,
    required this.rolesText,
    required this.imagePath,
    required this.motto,
    required this.mottoAuthor,
    required this.delay,
    required this.shouldAnimate,
  });

  @override
  State<CreatorPanel> createState() => _CreatorPanelState();
}

class _CreatorPanelState extends State<CreatorPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _nameSlideAnimation;
  late Animation<double> _imageOpacityAnimation;
  late Animation<double> _roleOpacityAnimation;
  late Animation<double> _mottoOpacityAnimation;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4500),
      vsync: this,
    );

    // Name slides from left to right
    _nameSlideAnimation =
        Tween<Offset>(begin: const Offset(-1.5, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
          ),
        );

    // Image fades in
    _imageOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.5, curve: Curves.easeIn),
      ),
    );

    // Role fades in
    _roleOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.7, curve: Curves.easeIn),
      ),
    );

    // Motto fades in
    _mottoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void didUpdateWidget(CreatorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldAnimate && !_hasStarted) {
      _hasStarted = true;
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image, Name, and Role section
            SizedBox(
              height: 280,
              child: Stack(
                children: [
                  // Name section with slide animation
                  Positioned(
                    left: 0,
                    top: 20,
                    right: 0,
                    child: ClipRect(
                      child: SlideTransition(
                        position: _nameSlideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.name,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.getFont(
                                'Montserrat',
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                                height: 0.95,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Large creator image on the left with fade animation
                  Positioned(
                    left: -30,
                    top: 0,
                    bottom: 0,
                    child: FadeTransition(
                      opacity: _imageOpacityAnimation,
                      child: SizedBox(
                        width: 600,
                        child: Image.asset(
                          widget.imagePath,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.person,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Role section on the right side below name with fade animation
                  Positioned(
                    right: 0,
                    top: 130,
                    child: FadeTransition(
                      opacity: _roleOpacityAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Orange container with "Roles" label only
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Color(0xFFFF8C00),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'Assigned Roles',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFF8C00),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Roles text outside the orange container
                          Text(
                            widget.rolesText,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Motto section with fade animation
            FadeTransition(
              opacity: _mottoOpacityAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"${widget.motto}"',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '- ${widget.mottoAuthor}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
