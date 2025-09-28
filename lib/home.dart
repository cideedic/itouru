import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/components/bottom_nav_bar.dart';
import 'package:itouru/components/header.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final PageController _pageController = PageController();
  int _currentSlideIndex = 0;

  // Mock data - replace with database calls later
  final List<Map<String, dynamic>> featuredLocations = [
    {
      'id': 1,
      'name': 'Bicol University Torch',
      'description':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
      'image': 'assets/images/bu_torch.png', // Replace with actual image path
      'category': 'Monument',
    },
    {
      'id': 2,
      'name': 'College of Science',
      'description':
          'The College of Science building houses various science departments and laboratories for students pursuing scientific disciplines.',
      'image': 'assets/images/college_of_science.jpg',
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
  void dispose() {
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
                  // App Info Section with Image
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Text Content
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 15),
                              Text(
                                '"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.justify,
                              ),
                              const SizedBox(height: 15),
                              ElevatedButton(
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Image
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () => _onLocationTap(featuredLocations[0]),
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
                                  featuredLocations[0]['image'],
                                  fit: BoxFit.cover,
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
                        ),
                      ],
                    ),
                  ),

                  // Category Label
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      featuredLocations[0]['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

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
                            itemCount:
                                featuredLocations.length -
                                1, // Exclude first item used above
                            itemBuilder: (context, index) {
                              final location =
                                  featuredLocations[index +
                                      1]; // Skip first item
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
                            featuredLocations.length - 1,
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

                  // Navigation arrows for slideshow (optional)
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
                              featuredLocations.length - 2) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          color:
                              _currentSlideIndex < featuredLocations.length - 2
                              ? Colors.orange
                              : Colors.grey[300],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 100), // Bottom padding
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
