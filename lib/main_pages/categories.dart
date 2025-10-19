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
  late TextEditingController searchController;
  late FocusNode _searchFocusNode;

  // Data lists from Supabase
  List<CollegeItem> colleges = [];
  List<BuildingItem> buildings = [];
  List<OfficeItem> offices = [];

  // Filtered data
  String searchQuery = '';
  String selectedCategory = 'All';
  List<String> visibleCategories = [];

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
            hasVideo: false,
          );
        }).toList();

        // Map buildings data
        buildings = (buildingsResponse as List).map((item) {
          return BuildingItem(
            name: item['building_name'] ?? '',
            subtitle: '',
            imagePath: '',
            description: item['description'] ?? '',
            hasVideo: false,
          );
        }).toList();

        // Map offices data
        offices = (officesResponse as List).map((item) {
          return OfficeItem(
            name: item['office_name'] ?? '',
            description: item['office_services'] ?? '',
            hasVideo: false,
          );
        }).toList();

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading data: $e';
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      _updateVisibleCategories();
    });
  }

  void _updateVisibleCategories() {
    if (searchQuery.isEmpty && selectedCategory == 'All') {
      visibleCategories = [];
    } else {
      visibleCategories = [];

      // Check which categories have matching items
      bool hasCollegeMatch = colleges.any(
        (item) => item.name.toLowerCase().contains(searchQuery),
      );
      bool hasBuildingMatch = buildings.any(
        (item) => item.name.toLowerCase().contains(searchQuery),
      );
      bool hasOfficeMatch = offices.any(
        (item) => item.name.toLowerCase().contains(searchQuery),
      );

      if (hasCollegeMatch) visibleCategories.add('College');
      if (hasBuildingMatch) visibleCategories.add('Building & Landmarks');
      if (hasOfficeMatch) visibleCategories.add('Offices');
    }
  }

  List<dynamic> _getFilteredItems(List<dynamic> items) {
    if (searchQuery.isEmpty) {
      return items;
    }
    return items
        .where((item) => item.name.toLowerCase().contains(searchQuery))
        .toList();
  }

  bool _shouldShowCategory(String category) {
    // Apply category filter
    if (selectedCategory != 'All') {
      if (category != selectedCategory) return false;
    }

    // Apply search filter
    if (searchQuery.isEmpty) return true;
    return visibleCategories.contains(category);
  }

  bool _hasItemsInCategory(String category) {
    switch (category) {
      case 'College':
        return colleges.isNotEmpty;
      case 'Building & Landmarks':
        return buildings.isNotEmpty;
      case 'Offices':
        return offices.isNotEmpty;
      default:
        return true;
    }
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
          // Search Field
          TextField(
            controller: searchController,
            focusNode: _searchFocusNode,
            onChanged: _filterItems,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search for colleges, buildings, or offices',
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[500]),
                      onPressed: () {
                        searchController.clear();
                        _filterItems('');
                      },
                    )
                  : null,
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
          SizedBox(height: 16),
          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('All'),
                _buildCategoryChip('College'),
                _buildCategoryChip('Building & Landmarks'),
                _buildCategoryChip('Offices'),
              ],
            ),
          ),
          SizedBox(height: 20),
          // Content Area - Show empty state if no results found
          if (searchQuery.isNotEmpty && visibleCategories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'No results found for "$searchQuery"',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (selectedCategory != 'All' &&
              !_hasItemsInCategory(selectedCategory))
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No items in $selectedCategory',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                // College Category Card
                if (_shouldShowCategory('College') && colleges.isNotEmpty)
                  CategoryCard(
                    title: 'College',
                    icon: Icons.school,
                    color: Color(0xFF2457C5),
                    items: _getFilteredItems(colleges),
                  ),

                SizedBox(height: 16),

                // Building & Landmarks Category Card
                if (_shouldShowCategory('Building & Landmarks') &&
                    buildings.isNotEmpty)
                  CategoryCard(
                    title: 'Building & Landmarks',
                    icon: Icons.business,
                    color: Colors.orange,
                    items: _getFilteredItems(buildings),
                  ),

                SizedBox(height: 16),

                // Offices Category Card
                if (_shouldShowCategory('Offices') && offices.isNotEmpty)
                  CategoryCard(
                    title: 'Offices',
                    icon: Icons.work_outline,
                    color: Color(0xFF4CAF50),
                    items: _getFilteredItems(offices),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String title) {
    final isSelected = selectedCategory == title;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(title),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedCategory = title;
            _updateVisibleCategories();
          });
        },
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black87,
        ),
        backgroundColor: Colors.grey[100],
        selectedColor: Colors.orange,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? Colors.orange : Colors.grey[300]!,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

// Category Card Widget
class CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<dynamic> items;

  const CategoryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Items List (No Limit)
          Container(
            height: 280,
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ItemCard(item: items[index], color: color);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Individual Item Card
class ItemCard extends StatelessWidget {
  final dynamic item;
  final Color color;

  const ItemCard({super.key, required this.item, required this.color});

  void _handleDirections(BuildContext context) {
    print('Get directions to ${item.name}');
  }

  void _handleInfo(BuildContext context) {
    if (item is BuildingItem) {
      BuildingItem building = item as BuildingItem;
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
    } else if (item is CollegeItem) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CollegeContent.ContentPage(
            title: item.name,
            subtitle: 'NICE',
            imagePath: 'college_of_science.png',
            logoPath: 'cs_logo.png',
          ),
        ),
      );
    } else if (item is OfficeItem) {
      OfficeItem office = item as OfficeItem;
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Name
              Text(
                item.name,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 10),

              // Description
              Expanded(
                child: Text(
                  item.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(height: 12),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Directions Button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => _handleDirections(context),
                      icon: Icon(
                        Icons.directions,
                        color: Colors.white,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(width: 8),
                  // Info Button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => _handleInfo(context),
                      icon: Icon(Icons.info_outline, color: color, size: 20),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
