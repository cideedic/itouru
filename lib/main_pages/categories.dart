import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
import 'package:itouru/page_components/header.dart';
import 'package:itouru/page_components/animation.dart';
import 'package:itouru/college_content_pages/content.dart' as CollegeContent;
import 'package:itouru/building_content_pages/content.dart' as BuildingContent;
import 'package:itouru/office_content_pages/content.dart' as OfficeContent;
import 'package:supabase_flutter/supabase_flutter.dart';

class Categories extends StatefulWidget {
  final bool autoFocusSearch;

  const Categories({super.key, this.autoFocusSearch = false});

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
              child: CategoriesBody(autoFocusSearch: widget.autoFocusSearch),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ReusableBottomNavBar(currentIndex: 1),
    );
  }
}

class CategoriesBody extends StatefulWidget {
  final bool autoFocusSearch;

  const CategoriesBody({super.key, this.autoFocusSearch = false});

  @override
  CategoriesBodyState createState() => CategoriesBodyState();
}

class CategoriesBodyState extends State<CategoriesBody>
    with TickerProviderStateMixin, ContentAnimationMixin {
  String selectedCategory = 'All';
  late TextEditingController searchController;
  late FocusNode _searchFocusNode;

  // Dropdown options
  final List<String> categoryOptions = [
    'All',
    'College',
    'Building & Landmarks',
    'Offices',
  ];

  // Data lists from Supabase
  List<CollegeItem> colleges = [];
  List<BuildingItem> buildings = [];
  List<OfficeItem> offices = [];

  List<dynamic> filteredItems = [];
  List<dynamic> allItems = [];

  bool isLoading = true;
  String? errorMessage;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    // Load data from Supabase
    _loadDataFromSupabase();

    // Delay to ensure the widget is fully built before requesting focus
    if (widget.autoFocusSearch) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _loadDataFromSupabase() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Fetch colleges
      final collegesResponse = await supabase
          .from('College')
          .select('college_name, college_about');

      // Fetch buildings
      final buildingsResponse = await supabase
          .from('Building')
          .select('building_name, description');

      // Fetch offices
      final officesResponse = await supabase
          .from('Office')
          .select('office_name, office_services');

      setState(() {
        // Map colleges data
        colleges = (collegesResponse as List).map((item) {
          return CollegeItem(
            name: item['college_name'] ?? '',
            description: item['college_about'] ?? '',
            hasVideo: false, // Set based on your data if available
          );
        }).toList();

        // Map buildings data
        buildings = (buildingsResponse as List).map((item) {
          return BuildingItem(
            name: item['building_name'] ?? '',
            subtitle: '', // Add subtitle field if available in your database
            imagePath: '', // Add image path field if available in your database
            description: item['description'] ?? '',
            hasVideo: false, // Set based on your data if available
          );
        }).toList();

        // Map offices data
        offices = (officesResponse as List).map((item) {
          return OfficeItem(
            name: item['office_name'] ?? '',
            description: item['office_about'] ?? '',
            hasVideo: false, // Set based on your data if available
          );
        }).toList();

        isLoading = false;
        _updateFilteredItems();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading data: $e';
      });
      print('Error loading data from Supabase: $e');
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchFocusNode.dispose();
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
    // Show loading indicator
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading data...',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Show error message
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            SizedBox(height: 16),
            Text(
              errorMessage!,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDataFromSupabase,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

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
              focusNode: _searchFocusNode,
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

          // Show empty state if no items
          if (filteredItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'No items found',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
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
