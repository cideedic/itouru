import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
import 'package:itouru/page_components/header.dart';
import 'package:itouru/page_components/animation.dart';
import 'package:itouru/college_content_pages/content.dart' as CollegeContent;
import 'package:itouru/building_content_pages/content.dart' as BuildingContent;
import 'package:itouru/office_content_pages/content.dart' as OfficeContent;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/main_pages/maps.dart';

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
  List<BuildingItem> landmarks = []; // ✨ Separate list for landmarks
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

      print('🔄 Starting data fetch from Supabase...');

      // Fetch colleges with abbreviation
      print('📚 Fetching colleges...');
      final collegesResponse = await supabase
          .from('College')
          .select(
            'college_id, college_name, college_about, college_abbreviation',
          );
      print('✅ Colleges fetched: ${collegesResponse.length} items');

      // Fetch buildings with nickname and building_type
      print('🏢 Fetching buildings...');
      final buildingsResponse = await supabase
          .from('Building')
          .select(
            'building_id, building_name, description, building_nickname, building_type',
          );
      print('✅ Buildings fetched: ${buildingsResponse.length} items');

      // Fetch offices with abbreviation
      print('🏛️ Fetching offices...');
      final officesResponse = await supabase
          .from('Office')
          .select(
            'office_id, office_name, office_services, building_id, office_abbreviation',
          );
      print('✅ Offices fetched: ${officesResponse.length} items');

      setState(() {
        // Map colleges data
        colleges = (collegesResponse as List).map((item) {
          return CollegeItem(
            collegeId: item['college_id'] ?? 0,
            name: item['college_name'] ?? '',
            description: item['college_about'] ?? '',
            abbreviation: item['college_abbreviation'],
            hasVideo: false,
          );
        }).toList();
        // Sort colleges alphabetically
        colleges.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

        // Map buildings data - separate buildings and landmarks
        final allBuildings = (buildingsResponse as List)
            .where((item) {
              // Filter out buildings without a valid building_id
              return item['building_id'] != null;
            })
            .map((item) {
              return BuildingItem(
                buildingId: item['building_id'] as int,
                name: item['building_name'] ?? '',
                description: item['description'] ?? '',
                nickname: item['building_nickname'],
                hasVideo: false,
                buildingType: item['building_type'], // ✨ Store building_type
              );
            })
            .toList();

        // ✨ Separate buildings and landmarks into different lists
        buildings = allBuildings
            .where((b) => b.buildingType?.toLowerCase() != 'landmark')
            .toList();
        landmarks = allBuildings
            .where((b) => b.buildingType?.toLowerCase() == 'landmark')
            .toList();

        // Sort both lists alphabetically
        buildings.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        landmarks.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

        // Map offices data
        offices = (officesResponse as List)
            .where((item) {
              return item['office_id'] != null;
            })
            .map((item) {
              return OfficeItem(
                officeId: item['office_id'] as int,
                name: item['office_name'] ?? '',
                description: item['office_services'] ?? '',
                abbreviation: item['office_abbreviation'],
                hasVideo: false,
                buildingId: item['building_id'] as int?,
              );
            })
            .toList();
        // Sort offices alphabetically
        offices.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

        // Important: clear loading flag after successful load
        isLoading = false;
        print('✅ All data loaded successfully!');
        print('   Colleges: ${colleges.length}');
        print('   Buildings: ${buildings.length}');
        print(
          '   Landmarks: ${buildings.where((b) => b.buildingType?.toLowerCase() == 'landmark').length}',
        );
        print('   Offices: ${offices.length}');
      });
    } catch (e) {
      print('❌ Error loading data: $e');
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
      bool hasCollegeMatch = colleges.any((item) => _matchesSearch(item));
      bool hasBuildingMatch = buildings.any((item) => _matchesSearch(item));
      bool hasLandmarkMatch = landmarks.any((item) => _matchesSearch(item));
      bool hasOfficeMatch = offices.any((item) => _matchesSearch(item));

      if (hasCollegeMatch) visibleCategories.add('College');
      if (hasBuildingMatch) visibleCategories.add('Buildings');
      if (hasLandmarkMatch) visibleCategories.add('Landmarks');
      if (hasOfficeMatch) visibleCategories.add('Offices');
    }
  }

  // Helper method to check if item matches search query
  bool _matchesSearch(dynamic item) {
    final query = searchQuery.toLowerCase();

    // Check name
    if (item.name.toLowerCase().contains(query)) {
      return true;
    }

    // Check shortcuts based on item type
    if (item is CollegeItem && item.abbreviation != null) {
      if (item.abbreviation!.toLowerCase().contains(query)) {
        return true;
      }
    } else if (item is BuildingItem && item.nickname != null) {
      if (item.nickname!.toLowerCase().contains(query)) {
        return true;
      }
    } else if (item is OfficeItem && item.abbreviation != null) {
      if (item.abbreviation!.toLowerCase().contains(query)) {
        return true;
      }
    }

    return false;
  }

  List<dynamic> _getFilteredItems(List<dynamic> items) {
    if (searchQuery.isEmpty) {
      return items;
    }
    return items.where((item) => _matchesSearch(item)).toList();
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
      case 'Buildings':
        return buildings.isNotEmpty;
      case 'Landmarks':
        return landmarks.isNotEmpty;
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
              hintText: 'Search by name or abbreviation',
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
                _buildCategoryChip('Buildings'),
                _buildCategoryChip('Landmarks'),
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
                    SizedBox(height: 8),
                    Text(
                      'Try searching by name or shortcut',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[500],
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
                    title: 'Colleges',
                    icon: Icons.school,
                    color: Colors.orange,
                    items: _getFilteredItems(colleges),
                  ),

                SizedBox(height: 16),

                // Buildings Category Card
                if (_shouldShowCategory('Buildings') && buildings.isNotEmpty)
                  CategoryCard(
                    title: 'Buildings',
                    icon: Icons.business,
                    color: Colors.orange,
                    items: _getFilteredItems(buildings),
                  ),

                SizedBox(height: 16),

                // Landmarks Category Card
                if (_shouldShowCategory('Landmarks') && landmarks.isNotEmpty)
                  CategoryCard(
                    title: 'Landmarks',
                    icon: Icons.place,
                    color: Colors.orange,
                    items: _getFilteredItems(landmarks),
                  ),

                SizedBox(height: 16),

                // Offices Category Card
                if (_shouldShowCategory('Offices') && offices.isNotEmpty)
                  CategoryCard(
                    title: 'Offices',
                    icon: Icons.work_outline,
                    color: Colors.orange,
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

  void _handleDirections(BuildContext context) async {
    print('\n🚀 === DIRECTIONS BUTTON PRESSED ===');
    print('📍 Item Type: ${item.runtimeType}');
    print('📍 Item Name: ${item.name}');

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Opening map...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
      ),
    );

    int? targetBuildingId;
    String destinationName = item.name;
    String itemType = 'unknown';

    // Get the appropriate building ID based on item type
    if (item is BuildingItem) {
      targetBuildingId = item.buildingId;
      // ✨ Check building_type to determine if it's a landmark
      if (item.buildingType?.toLowerCase() == 'landmark') {
        itemType = 'marker'; // Navigate to landmark marker
        print('🏛️ Landmark ID: $targetBuildingId');
        print('   Building Type: ${item.buildingType}');
        print('   Will navigate to landmark marker');
      } else {
        itemType = 'building'; // Navigate to building polygon
        print('🏢 Building ID: $targetBuildingId');
        print('   Building Type: ${item.buildingType}');
      }
    } else if (item is CollegeItem) {
      targetBuildingId = item.collegeId;
      itemType = 'marker'; // Navigate to college marker
      print('🎓 College ID: $targetBuildingId');
      print('   Will navigate to college marker');
    } else if (item is OfficeItem) {
      // Use the office's building_id instead of office_id
      targetBuildingId = item.buildingId;
      itemType = 'office';
      print('🏛️ Office: ${item.name}');
      print('   Office ID: ${item.officeId}');
      print('   Building ID: $targetBuildingId');

      // Add warning if no building assigned
      if (targetBuildingId == null) {
        print('⚠️ Warning: Office has no building assigned!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} has no building location assigned'),
            backgroundColor: Colors.orange,
          ),
        );
        return; // Don't navigate if no building
      }
    }

    print('📋 Summary:');
    print('   - Target Building ID: $targetBuildingId');
    print('   - Destination Name: $destinationName');
    print('   - Item Type: $itemType');
    print('🚀 === NAVIGATING TO MAPS PAGE ===\n');

    // Navigate to Maps page with auto-navigation
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Maps(
          buildingId: targetBuildingId,
          destinationName: destinationName,
          itemType: itemType,
        ),
      ),
    );
  }

  void _handleInfo(BuildContext context) {
    if (item is BuildingItem) {
      BuildingItem building = item as BuildingItem;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BuildingContent.BuildingDetailsPage(
            buildingId: building.buildingId,
            title: building.name,
          ),
        ),
      );
    } else if (item is CollegeItem) {
      CollegeItem college = item as CollegeItem;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CollegeContent.CollegeDetailsPage(
            collegeId: college.collegeId,
            collegeName: college.name,
            title: college.name,
          ),
        ),
      );
    } else if (item is OfficeItem) {
      OfficeItem office = item as OfficeItem;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OfficeContent.OfficeDetailsPage(
            officeId: office.officeId,
            officeName: office.name,
            title: office.name,
          ),
        ),
      );
    }
  }

  String _getShortcutBadge() {
    if (item is CollegeItem && item.abbreviation != null) {
      return item.abbreviation!;
    } else if (item is BuildingItem && item.nickname != null) {
      return item.nickname!;
    } else if (item is OfficeItem && item.abbreviation != null) {
      return item.abbreviation!;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final shortcut = _getShortcutBadge();

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
              // Item Name with landmark icon
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Abbreviation/Shortcut underneath name
              if (shortcut.isNotEmpty) ...[
                SizedBox(height: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    shortcut,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
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
  final int collegeId;
  final String name;
  final String description;
  final String? abbreviation;
  final bool hasVideo;

  CollegeItem({
    required this.collegeId,
    required this.name,
    required this.description,
    this.abbreviation,
    this.hasVideo = false,
  });
}

class BuildingItem {
  final int buildingId;
  final String name;
  final String description;
  final String? nickname;
  final bool hasVideo;
  final String? buildingType; // ✨ Store building_type from database

  BuildingItem({
    required this.buildingId,
    required this.name,
    required this.description,
    this.nickname,
    this.hasVideo = false,
    this.buildingType, // ✨ No boolean flag, just the type string
  });
}

class OfficeItem {
  final int officeId;
  final String name;
  final String description;
  final String? abbreviation;
  final bool hasVideo;
  final int? buildingId;

  OfficeItem({
    required this.officeId,
    required this.name,
    required this.description,
    this.abbreviation,
    this.hasVideo = false,
    this.buildingId,
  });
}
