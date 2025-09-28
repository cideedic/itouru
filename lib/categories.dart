import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/components/bottom_nav_bar.dart';
import 'package:itouru/components/header.dart';
import 'package:itouru/components/animation.dart';
import 'package:itouru/components/footer.dart';
import 'package:itouru/college_content_pages/content.dart'
    as CollegeContent; // Import the college content component
import 'package:itouru/building_content_pages/content.dart'
    as BuildingContent; // Import the building content component
import 'package:itouru/office_content_pages/content.dart'
    as OfficeContent; // Import the office content component

class Categories extends StatefulWidget {
  const Categories({super.key});

  @override
  CategoriesState createState() => CategoriesState();
}

class CategoriesState extends State<Categories> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ReusableHeader(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey[200]!, Colors.white],
                ),
              ),
              child: CategoriesBody(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ReusableBottomNavBar(currentIndex: 1),
    );
  }
}

class CategoriesBody extends StatefulWidget {
  const CategoriesBody({super.key});

  @override
  CategoriesBodyState createState() => CategoriesBodyState();
}

class CategoriesBodyState extends State<CategoriesBody>
    with TickerProviderStateMixin, ContentAnimationMixin {
  String selectedCategory = 'All';
  TextEditingController searchController = TextEditingController();

  // Dropdown options
  final List<String> categoryOptions = [
    'All',
    'College',
    'Building & Landmarks',
    'Offices',
  ];

  // Sample data - TODO: Replace with MySQL database queries
  List<CollegeItem> colleges = [
    CollegeItem(
      name: 'College of Science',
      description:
          'Bicol University College of Science is a leading academic institution dedicated to pursuing future materials and technology professionals. It offers a wide range of undergraduate programs including Information Technology, Computer Science, Biology, Chemistry, and Mathematics designed to equip students with both theoretical knowledge and practical experience.',
      hasVideo: true,
    ),
    CollegeItem(
      name: 'College of Nursing',
      description:
          'Dedicated to producing competent and caring healthcare professionals with strong ethical foundations and clinical expertise.',
      hasVideo: false,
    ),
    CollegeItem(
      name: 'College of Arts and Letters',
      description:
          'Fostering creativity, critical thinking, and cultural understanding through diverse academic programs in humanities and social sciences.',
      hasVideo: false,
    ),
    CollegeItem(
      name: 'College of Engineering',
      description:
          'Building future engineers with strong technical skills and innovative problem-solving capabilities.',
      hasVideo: true,
    ),
    CollegeItem(
      name: 'College of Education',
      description:
          'Preparing dedicated educators who will shape the minds of future generations.',
      hasVideo: false,
    ),
  ];

  List<BuildingItem> buildings = [
    BuildingItem(
      name: 'Ricardo Arcilla Bldg.',
      subtitle: 'The White House',
      imagePath: 'assets/images/ricardo_arcilla_building.jpg',
      description:
          'The historic main building of Bicol University houses the administrative offices, including the Office of the President, Vice President for Academic Affairs, and the Registrar. Built in 1969, it stands as a symbol of the university\'s rich heritage and academic excellence.',
      hasVideo: true,
    ),
    BuildingItem(
      name: 'Science Laboratory Building',
      subtitle: 'Research & Innovation Hub',
      imagePath: 'assets/images/science_lab_building.jpg',
      description:
          'A state-of-the-art facility equipped with modern laboratories for Physics, Chemistry, Biology, and Computer Science. Features advanced research equipment and collaborative spaces for students and faculty.',
      hasVideo: false,
    ),
    BuildingItem(
      name: 'Library Building',
      subtitle: 'Knowledge Center',
      imagePath: 'assets/images/library_building.jpg',
      description:
          'The central repository of knowledge featuring over 50,000 books, digital resources, study areas, and research facilities. Open 24/7 during exam periods to support student learning.',
      hasVideo: true,
    ),
    BuildingItem(
      name: 'Student Center',
      subtitle: 'Hub of Activities',
      imagePath: 'assets/images/student_center.jpg',
      description:
          'Hub for student activities, organizations, and events. Contains meeting rooms, cafeteria, student services offices, and recreational facilities.',
      hasVideo: false,
    ),
    BuildingItem(
      name: 'Engineering Complex',
      subtitle: 'Technical Excellence',
      imagePath: 'assets/images/engineering_complex.jpg',
      description:
          'Multi-story complex housing engineering laboratories, workshops, computer labs, and faculty offices. Features specialized equipment for mechanical, electrical, and civil engineering programs.',
      hasVideo: true,
    ),
  ];

  List<OfficeItem> offices = [
    OfficeItem(
      name: 'Registrar\'s Office',
      description:
          'Handles student enrollment, academic records, transcript requests, and graduation requirements. Open Monday to Friday, 8:00 AM - 5:00 PM.',
      hasVideo: false,
    ),
    OfficeItem(
      name: 'Accounting Office',
      description:
          'Manages tuition payments, financial aid, scholarships, and student accounts. Accepts various payment methods including online transactions.',
      hasVideo: false,
    ),
    OfficeItem(
      name: 'Student Affairs Office',
      description:
          'Provides student services including guidance counseling, disciplinary matters, student organizations coordination, and welfare programs.',
      hasVideo: true,
    ),
    OfficeItem(
      name: 'Admission Office',
      description:
          'Processes new student applications, entrance examinations, and provides information about academic programs and requirements.',
      hasVideo: false,
    ),
    OfficeItem(
      name: 'Medical Clinic',
      description:
          'Provides basic healthcare services, first aid, medical consultations, and health certificates for students and staff. Staffed by licensed medical professionals.',
      hasVideo: false,
    ),
  ];

  List<dynamic> filteredItems = [];
  List<dynamic> allItems = [];

  @override
  void initState() {
    super.initState();
    _updateFilteredItems();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _updateFilteredItems() {
    setState(() {
      allItems.clear();

      if (selectedCategory == 'All') {
        allItems.addAll(colleges);
        allItems.addAll(buildings);
        allItems.addAll(offices);
      } else if (selectedCategory == 'College') {
        allItems.addAll(colleges);
      } else if (selectedCategory == 'Building & Landmarks') {
        allItems.addAll(buildings);
      } else if (selectedCategory == 'Offices') {
        allItems.addAll(offices);
      }

      filteredItems = allItems;
    });

    // Trigger content animation when category changes
    if (!isFirstLoad) {
      animateContentChange();
    }
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredItems = allItems;
      } else {
        filteredItems = allItems
            .where(
              (item) => item.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  String _getSearchHint() {
    switch (selectedCategory) {
      case 'College':
        return 'Search College';
      case 'Building & Landmarks':
        return 'Search Building';
      case 'Offices':
        return 'Search Office';
      default:
        return 'Search';
    }
  }

  void _onCategoryChanged(String newCategory) {
    setState(() {
      selectedCategory = newCategory;
    });
    _updateFilteredItems();
    searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 15),

          // Reusable Animated Dropdown
          AnimatedDropdown(
            items: categoryOptions,
            selectedValue: selectedCategory,
            onChanged: _onCategoryChanged,
            hint: 'Select Category',
            backgroundColor: Colors.white,
            selectedBackgroundColor: Color(0xFFFFE7CA),
            borderColor: Colors.grey.shade300,
            selectedBorderColor: Colors.blue,
            selectedItemColor: Color(0xFF2457C5),
            unselectedItemColor: Color(0xFF65789F),
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            borderRadius: 12,
            elevation: 4,
            animationDuration: Duration(milliseconds: 200),
          ),

          SizedBox(height: 16),

          // Animated Search Field
          buildAnimatedContent(
            child: TextField(
              controller: searchController,
              onChanged: _filterItems,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: _getSearchHint(),
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          SizedBox(height: 20),

          // Animated Items List with Staggered Animation
          buildAnimatedContent(
            child: buildStaggeredList(
              children: filteredItems.asMap().entries.map((entry) {
                int index = entry.key;
                dynamic item = entry.value;

                return UniversalCard(item: item, isExpanded: index == 0);
              }).toList(),
            ),
          ),
          AppFooter(),
        ],
      ),
    );
  }
}

// Universal Card Widget that handles all types
class UniversalCard extends StatefulWidget {
  final dynamic item;
  final bool isExpanded;

  const UniversalCard({super.key, required this.item, this.isExpanded = false});

  @override
  UniversalCardState createState() => UniversalCardState();
}

class UniversalCardState extends State<UniversalCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDirections() {
    print('Get directions to ${widget.item.name}');
  }

  void _handleInfo() {
    // Check the item type and navigate to appropriate content page
    if (widget.item is BuildingItem) {
      BuildingItem building = widget.item as BuildingItem;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BuildingContent.ContentPage(
            title: building.name,
            subtitle: building.subtitle,
            imagePath: building.imagePath,
            // Removed logoPath parameter
          ),
        ),
      );
    } else if (widget.item is CollegeItem) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CollegeContent.ContentPage(
            title: widget.item.name,
            subtitle: 'NICE',
            imagePath: 'college_of_science.png',
            logoPath: 'cs_logo.png',
          ),
        ),
      );
    } else if (widget.item is OfficeItem) {
      OfficeItem office = widget.item as OfficeItem;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OfficeContent.OfficeContentPage(
            title: office.name,
            subtitle: 'University Office',
            description: office.description,
          ),
        ),
      );
    } else {
      // Handle other types if needed
      print('Info for ${widget.item.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                  if (_isExpanded) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: _isExpanded
                          ? Colors.grey.shade200
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.item.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expandable Content
            SizeTransition(
              sizeFactor: _animation,
              child: Container(
                color: Colors.grey.shade50,
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Placeholder (if has video)
                    if (widget.item.hasVideo) ...[
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Description
                    Text(
                      widget.item.description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    SizedBox(height: 20),

                    // Action Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Directions Button
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Color(0xFF1A31C8),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _handleDirections,
                                icon: Icon(
                                  Icons.directions,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Directions',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 20),
                        // Info Button
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Color(0xFFFCF0CA),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _handleInfo,
                                icon: Icon(
                                  Icons.info_outline,
                                  color: const Color.fromARGB(
                                    255,
                                    103,
                                    102,
                                    102,
                                  ),
                                  size: 24,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Info',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 10),
                      ],
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

// Data Models
class CollegeItem {
  final String name;
  final String description;
  final bool hasVideo;

  CollegeItem({
    required this.name,
    required this.description,
    this.hasVideo = false,
  });
}

class BuildingItem {
  final String name;
  final String subtitle;
  final String imagePath;
  final String description;
  final bool hasVideo;

  BuildingItem({
    required this.name,
    required this.subtitle,
    required this.imagePath,
    required this.description,
    this.hasVideo = false,
  });
}

class OfficeItem {
  final String name;
  final String description;
  final bool hasVideo;

  OfficeItem({
    required this.name,
    required this.description,
    this.hasVideo = false,
  });
}
