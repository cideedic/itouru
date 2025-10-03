import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/components/bottom_nav_bar.dart';
import 'package:itouru/components/header.dart';
import 'package:itouru/maps.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentSlideIndex = 0;

  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;

  // Mock data - torch removed from featured locations
  final List<Map<String, dynamic>> featuredLocations = [
    {
      'id': 2,
      'name': 'College of Science',
      'description':
          'The College of Science building houses various science departments and laboratories for students pursuing scientific disciplines.',
      'image': 'assets/images/college_of_science.png',
      'category': 'College Building',
    },
    {
      'id': 3,
      'name': 'College of Engineering',
      'description':
          'Modern facilities and laboratories for engineering students with state-of-the-art equipment.',
      'image': 'assets/images/college_of_engineering.jpg',
      'category': 'College Building',
    },
    {
      'id': 4,
      'name': 'Library',
      'description':
          'The main university library with extensive collection of books, journals, and digital resources.',
      'image': 'assets/images/library.jpg',
      'category': 'Academic Facility',
    },
    {
      'id': 5,
      'name': 'Administration Building',
      'description':
          'Central administrative offices and student services are located in this building.',
      'image': 'assets/images/admin_building.jpg',
      'category': 'Administrative',
    },
  ];

  @override
  void initState() {
    super.initState();
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _zoomAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onLocationTap(Map<String, dynamic> location) {
    // Navigate to detailed view or map location
    print('Tapped on: ${location['name']}');
    // TODO: Navigate to specific location or detailed view
  }

  void _onLearnMoreTap() {
    // Navigate to about page or more info
    print('Learn More tapped');
    // TODO: Navigate to about/info page
  }

  void _onMapTap() async {
    await _zoomController.forward();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Maps()),
      ).then((_) {
        if (mounted) {
          _zoomController.reverse();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Use the reusable header
          ReusableHeader(),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // App Info Section with Torch on Left
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Torch Image on Left
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/bu_torch.png',
                                fit: BoxFit
                                    .contain, // Changed to contain to show full image
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Text Content on Right
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bicol University (BU) is the premier state university in the Bicol region, founded on June 21, 1969, through the passage of Republic Act 5521. The university is located in Legazpi City, Albay, Philippines, with external campuses scattered throughout the provinces of Albay and Sorsogon. The university was established through the collaboration of three founding fathers: Senator Dominador R. Aytona, Congressman Carlos R. Imperial, and Congressman Jose M. Alberto, who worked together to create the first state university in the Bicol region Bicol University.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                                const SizedBox(height: 15),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: _onLearnMoreTap,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: Text(
                                      'Learn More',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
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
                  ),

                  // Torch Label
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Featured Locations \n around West Campus',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Slideshow Section
                  Container(
                    height: 280,
                    child: Column(
                      children: [
                        // Slideshow
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentSlideIndex = index;
                              });
                            },
                            itemCount: featuredLocations.length,
                            itemBuilder: (context, index) {
                              final location = featuredLocations[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: GestureDetector(
                                  onTap: () => _onLocationTap(location),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Stack(
                                        children: [
                                          // Background Image
                                          Container(
                                            width: double.infinity,
                                            height: double.infinity,
                                            child: Image.asset(
                                              location['image'],
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons.location_city,
                                                        size: 60,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  },
                                            ),
                                          ),
                                          // Gradient Overlay
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.7),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Content
                                          Positioned(
                                            bottom: 15,
                                            right: 15,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.9,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                location['name'],
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Page Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            featuredLocations.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _currentSlideIndex == index ? 20 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentSlideIndex == index
                                    ? Colors.orange
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Navigation arrows for slideshow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_currentSlideIndex > 0) {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: _currentSlideIndex > 0
                              ? Colors.orange
                              : Colors.grey[300],
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: () {
                          if (_currentSlideIndex <
                              featuredLocations.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          color:
                              _currentSlideIndex < featuredLocations.length - 1
                              ? Colors.orange
                              : Colors.grey[300],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30), // Bottom padding

                  GestureDetector(
                    onTap: _onMapTap,
                    child: AnimatedBuilder(
                      animation: _zoomAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _zoomAnimation.value,
                          child: child,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomLeft: Radius.circular(0),
                          bottomRight: Radius.circular(0),
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, -3),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Map Image
                              Image.asset(
                                'assets/images/footer_map.jpg',
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(
                                        Icons.map,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Overlay with text
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.3),
                                      Colors.black.withOpacity(0.6),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.map_outlined,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Explore Campus Map',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Tap to navigate',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
      bottomNavigationBar: ReusableBottomNavBar(currentIndex: 0),
    );
  }
}
