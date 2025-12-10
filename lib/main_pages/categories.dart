import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
import 'package:itouru/page_components/header.dart';
import 'package:itouru/college_content_pages/content.dart' as college_content;
import 'package:itouru/building_content_pages/content.dart' as building_content;
import 'package:itouru/office_content_pages/content.dart' as office_content;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/main_pages/maps.dart';
import 'package:itouru/page_components/loading_widget.dart';

class Categories extends StatefulWidget {
  final bool autoFocusSearch;
  final String? initialCategory;

  const Categories({
    super.key,
    this.autoFocusSearch = false,
    this.initialCategory,
  });

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
              child: CategoriesBody(
                autoFocusSearch: widget.autoFocusSearch,
                initialCategory: widget.initialCategory,
              ),
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
  final String? initialCategory;

  const CategoriesBody({
    super.key,
    this.autoFocusSearch = false,
    this.initialCategory,
  });

  @override
  CategoriesBodyState createState() => CategoriesBodyState();
}

class CategoriesBodyState extends State<CategoriesBody> {
  late TextEditingController searchController;
  late FocusNode _searchFocusNode;

  List<CollegeItem> colleges = [];
  List<BuildingItem> buildings = [];
  List<BuildingItem> landmarks = [];
  List<OfficeItem> offices = [];
  List<RoomItem> rooms = [];

  String searchQuery = '';
  String selectedCategory = 'All';
  List<String> visibleCategories = [];

  bool isLoading = true;
  String? errorMessage;

  final supabase = Supabase.instance.client;

  final Map<String, GlobalKey> _categoryKeys = {
    'Colleges': GlobalKey(),
    'Buildings': GlobalKey(),
    'Landmarks': GlobalKey(),
    'Offices': GlobalKey(),
  };

  final ScrollController _mainScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    _loadDataFromSupabase();

    if (widget.autoFocusSearch) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }

    if (widget.initialCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            _scrollToCategory(widget.initialCategory!);
          }
        });
      });
    }
  }

  void _scrollToCategory(String category) {
    final key = _categoryKeys[category];

    if (key == null) {
      return;
    }

    final context = key.currentContext;

    if (context == null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;

        final retryContext = key.currentContext;

        if (retryContext != null && retryContext.mounted) {
          _performScroll(retryContext, key);
        }
      });
      return;
    }

    _performScroll(context, key);
  }

  void _performScroll(BuildContext scrollContext, GlobalKey key) {
    if (!scrollContext.mounted) return;

    Scrollable.ensureVisible(
          scrollContext,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          alignment: 0.15,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        )
        .then((_) {
          if (mounted) {
            _triggerBumpAnimation(key);
          }
        })
        .catchError((error) {});
  }

  void _triggerBumpAnimation(GlobalKey key) {
    final context = key.currentContext;

    if (context != null) {
      final renderBox = context.findRenderObject() as RenderBox?;

      if (renderBox != null) {
        final categoryCardState = context
            .findAncestorStateOfType<_CategoryCardState>();

        if (categoryCardState != null) {
          categoryCardState.triggerBumpAnimation();
        }
      }
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
          .select(
            'college_id, college_name, college_about, college_abbreviation',
          )
          .timeout(
            Duration(seconds: 15),
            onTimeout: () => throw Exception('Connection timeout'),
          );

      // Fetch buildings
      final buildingsResponse = await supabase
          .from('Building')
          .select(
            'building_id, building_name, description, building_nickname, building_type',
          )
          .timeout(
            Duration(seconds: 15),
            onTimeout: () => throw Exception('Connection timeout'),
          );

      // Fetch offices
      final officesResponse = await supabase
          .from('Office')
          .select(
            'office_id, office_name, office_services, building_id, office_abbreviation',
          )
          .timeout(
            Duration(seconds: 15),
            onTimeout: () => throw Exception('Connection timeout'),
          );

      // Fetch rooms
      final roomsResponse = await supabase
          .from('Room')
          .select(
            'room_id, room_name, building_id, floor_level, Building(building_name)',
          )
          .timeout(
            Duration(seconds: 15),
            onTimeout: () => throw Exception('Connection timeout'),
          );

      setState(() {
        // Map colleges
        colleges = (collegesResponse as List).map((item) {
          return CollegeItem(
            collegeId: item['college_id'] ?? 0,
            name: item['college_name'] ?? '',
            description: item['college_about'] ?? '',
            abbreviation: item['college_abbreviation'],
            hasVideo: false,
          );
        }).toList();
        colleges.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

        // Map buildings and landmarks
        final allBuildings = (buildingsResponse as List)
            .where((item) {
              return item['building_id'] != null;
            })
            .map((item) {
              return BuildingItem(
                buildingId: item['building_id'] as int,
                name: item['building_name'] ?? '',
                description: item['description'] ?? '',
                nickname: item['building_nickname'],
                hasVideo: false,
                buildingType: item['building_type'],
              );
            })
            .toList();

        buildings = allBuildings
            .where((b) => b.buildingType?.toLowerCase() != 'landmark')
            .toList();
        landmarks = allBuildings
            .where((b) => b.buildingType?.toLowerCase() == 'landmark')
            .toList();

        buildings.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        landmarks.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

        // Map offices
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
        offices.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

        // Map rooms
        rooms = (roomsResponse as List)
            .where(
              (item) => item['room_id'] != null && item['building_id'] != null,
            )
            .map((item) {
              return RoomItem(
                roomId: item['room_id'] as int,
                roomName: item['room_name'] ?? '',
                buildingId: item['building_id'] as int,
                buildingName:
                    item['Building']?['building_name'] ?? 'Unknown Building',
                floorNumber: item['floor_level'] as int?,
              );
            })
            .toList();
        rooms.sort(
          (a, b) =>
              a.roomName.toLowerCase().compareTo(b.roomName.toLowerCase()),
        );

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        if (e.toString().contains('timeout') ||
            e.toString().contains('Connection timeout')) {
          errorMessage =
              'Connection is taking too long. Please check your internet and try again.';
        } else if (e.toString().contains('SocketException') ||
            e.toString().contains('network')) {
          errorMessage =
              'No internet connection. Please check your network and try again.';
        } else {
          errorMessage = 'Unable to load categories. Please try again.';
        }
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchFocusNode.dispose();
    _mainScrollController.dispose();
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

      bool hasCollegeMatch = colleges.any((item) => _matchesSearch(item));
      bool hasBuildingMatch = buildings.any((item) => _matchesSearch(item));
      bool hasLandmarkMatch = landmarks.any((item) => _matchesSearch(item));
      bool hasOfficeMatch = offices.any((item) => _matchesSearch(item));

      if (hasCollegeMatch) visibleCategories.add('Colleges');
      if (hasBuildingMatch) visibleCategories.add('Buildings');
      if (hasLandmarkMatch) visibleCategories.add('Landmarks');
      if (hasOfficeMatch) visibleCategories.add('Offices');
    }
  }

  bool _matchesSearch(dynamic item) {
    final query = searchQuery.toLowerCase().replaceAll(' ', '');

    if (item.name.toLowerCase().replaceAll(' ', '').contains(query)) {
      return true;
    }

    if (item is CollegeItem && item.abbreviation != null) {
      if (item.abbreviation!
          .toLowerCase()
          .replaceAll(' ', '')
          .contains(query)) {
        return true;
      }
    } else if (item is BuildingItem && item.nickname != null) {
      if (item.nickname!.toLowerCase().replaceAll(' ', '').contains(query)) {
        return true;
      }
    } else if (item is OfficeItem && item.abbreviation != null) {
      if (item.abbreviation!
          .toLowerCase()
          .replaceAll(' ', '')
          .contains(query)) {
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

  // New method to get matching rooms for search
  List<RoomItem> _getMatchingRooms() {
    if (searchQuery.isEmpty) return [];

    final query = searchQuery.toLowerCase().replaceAll(' ', '');
    return rooms.where((room) {
      return room.roomName.toLowerCase().replaceAll(' ', '').contains(query);
    }).toList();
  }

  bool _shouldShowCategory(String category) {
    if (selectedCategory != 'All') {
      if (category != selectedCategory) return false;
    }

    if (searchQuery.isEmpty) return true;
    return visibleCategories.contains(category);
  }

  bool _hasItemsInCategory(String category) {
    switch (category) {
      case 'Colleges':
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
    if (isLoading) {
      return LoadingScreen.dots(
        title: 'Loading Categories',
        subtitle: 'Please Wait',
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined, size: 80, color: Colors.grey[400]),
              SizedBox(height: 24),
              Text(
                'Oops!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12),
              Text(
                errorMessage!,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadDataFromSupabase,
                icon: Icon(Icons.refresh, size: 20),
                label: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF8C00),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final matchingRooms = _getMatchingRooms();

    return SingleChildScrollView(
      controller: _mainScrollController,
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
              hintText: 'Search',
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 12,
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
                _buildCategoryChip('Colleges'),
                _buildCategoryChip('Buildings'),
                _buildCategoryChip('Landmarks'),
                _buildCategoryChip('Offices'),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Content Area
          if (searchQuery.isNotEmpty &&
              visibleCategories.isEmpty &&
              matchingRooms.isEmpty)
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
                      'Try searching by name, shortcut, or room',
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
                if (_shouldShowCategory('Colleges') && colleges.isNotEmpty)
                  CategoryCard(
                    key: _categoryKeys['Colleges'],
                    title: 'Colleges',
                    icon: Icons.school,
                    color: Color(0xFFFF8C00),
                    items: _getFilteredItems(colleges),
                  ),
                if (_shouldShowCategory('Colleges') && colleges.isNotEmpty)
                  SizedBox(height: 16),

                // Buildings Category Card
                if (_shouldShowCategory('Buildings') && buildings.isNotEmpty)
                  CategoryCard(
                    key: _categoryKeys['Buildings'],
                    title: 'Buildings',
                    icon: Icons.business,
                    color: Color(0xFFFF8C00),
                    items: _getFilteredItems(buildings),
                  ),
                if (_shouldShowCategory('Buildings') && buildings.isNotEmpty)
                  SizedBox(height: 16),

                // Landmarks Category Card
                if (_shouldShowCategory('Landmarks') && landmarks.isNotEmpty)
                  CategoryCard(
                    key: _categoryKeys['Landmarks'],
                    title: 'Landmarks & Others',
                    icon: Icons.place,
                    color: Color(0xFFFF8C00),
                    items: _getFilteredItems(landmarks),
                  ),
                if (_shouldShowCategory('Landmarks') && landmarks.isNotEmpty)
                  SizedBox(height: 16),

                // Offices Category Card
                if (_shouldShowCategory('Offices') && offices.isNotEmpty)
                  CategoryCard(
                    key: _categoryKeys['Offices'],
                    title: 'Offices',
                    icon: Icons.work_outline,
                    color: Color(0xFFFF8C00),
                    items: _getFilteredItems(offices),
                  ),
                if (_shouldShowCategory('Offices') && offices.isNotEmpty)
                  SizedBox(height: 16),

                // Room Search Results at the bottom
                if (searchQuery.isNotEmpty && matchingRooms.isNotEmpty)
                  RoomSearchResults(rooms: matchingRooms),
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
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black87,
        ),
        backgroundColor: Colors.grey[100],
        selectedColor: Color(0xFFFF8C00),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? Color(0xFFFF8C00) : Colors.grey[300]!,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

// Room Search Results - appears only when searching
class RoomSearchResults extends StatelessWidget {
  final List<RoomItem> rooms;

  const RoomSearchResults({super.key, required this.rooms});

  void _showRoomActionModal(BuildContext context, RoomItem room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.roomName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.business, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        room.buildingName,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (room.floorNumber != null) ...[
                        SizedBox(width: 8),
                        Text(
                          '• ${room.floorNumber}${_getFloorSuffix(room.floorNumber!)} Floor',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 24),
                  Text(
                    'What would you like to do?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 16),
                  // View Building Info Button
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              building_content.BuildingDetailsPage(
                                buildingId: room.buildingId,
                                title: room.buildingName,
                              ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'View Building Info',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'See details about ${room.buildingName}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  // Get Directions Button
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Maps(
                            buildingId: room.buildingId,
                            destinationName: room.buildingName,
                            itemType: 'building',
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF8C00).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFFFF8C00).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF8C00),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.directions,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Get Directions',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFF8C00),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Navigate to this building',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Color(0xFFFF8C00)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFloorSuffix(int floor) {
    if (floor == 1) return 'st';
    if (floor == 2) return 'nd';
    if (floor == 3) return 'rd';
    return 'th';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFFF8C00).withValues(alpha: 0.1),
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
                    color: Color(0xFFFF8C00),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.meeting_room,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Rooms',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF8C00),
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF8C00).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${rooms.length} found',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFF8C00),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Fixed Height Room List with Scrolling
          SizedBox(
            height: 300, // Fixed height - adjust as needed
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: rooms.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey[200],
                indent: 20,
                endIndent: 20,
              ),
              itemBuilder: (context, index) {
                final room = rooms[index];
                return InkWell(
                  onTap: () => _showRoomActionModal(context, room),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF8C00).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.door_front_door,
                            color: Color(0xFFFF8C00),
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.roomName,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.business,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${room.buildingName}${room.floorNumber != null ? ' • ${room.floorNumber}${_getFloorSuffix(room.floorNumber!)} Floor' : ''}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for room display
class RoomDisplayItem {
  final String name;
  final String description;
  final RoomItem roomData;

  RoomDisplayItem({
    required this.name,
    required this.description,
    required this.roomData,
  });
}

class CategoryCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<dynamic> items;
  final bool isRoomCategory;
  final Function(BuildContext, RoomItem)? onRoomTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    this.isRoomCategory = false,
    this.onRoomTap,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _bumpController;
  late Animation<double> _bumpAnimation;

  @override
  void initState() {
    super.initState();
    _bumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bumpAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.08,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_bumpController);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bumpController.dispose();
    super.dispose();
  }

  void triggerBumpAnimation() {
    _bumpController.forward(from: 0.0).then((_) {});
  }

  void _showItemsList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${widget.items.length} items',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    String shortcut = '';

                    if (!widget.isRoomCategory) {
                      if (item is CollegeItem && item.abbreviation != null) {
                        shortcut = item.abbreviation!;
                      } else if (item is BuildingItem &&
                          item.nickname != null) {
                        shortcut = item.nickname!;
                      } else if (item is OfficeItem &&
                          item.abbreviation != null) {
                        shortcut = item.abbreviation!;
                      }
                    }

                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.isRoomCategory && item is RoomDisplayItem) {
                          widget.onRoomTap?.call(context, item.roomData);
                        } else {
                          _scrollToItem(index);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (shortcut.isNotEmpty) ...[
                                    SizedBox(height: 4),
                                    Text(
                                      shortcut,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: widget.color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  if (widget.isRoomCategory &&
                                      item is RoomDisplayItem) ...[
                                    SizedBox(height: 4),
                                    Text(
                                      item.description,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToItem(int index) {
    final double targetPosition = (index * 272.0);
    _scrollController.animateTo(
      targetPosition,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _bumpAnimation,
      child: Card(
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
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
                      color: widget.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.color,
                    ),
                  ),
                  Spacer(),
                  InkWell(
                    onTap: () => _showItemsList(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.list, color: widget.color, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 280, // Fixed height - prevents excessive scrolling
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                scrollDirection: Axis.horizontal,
                physics:
                    ClampingScrollPhysics(), // Add this line to limit bounce
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  return ItemCard(
                    item: widget.items[index],
                    color: widget.color,
                  );
                },
              ),
            ),
          ],
        ),
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

    if (item is BuildingItem) {
      targetBuildingId = item.buildingId;
      if (item.buildingType?.toLowerCase() == 'landmark') {
        itemType = 'marker';
      } else {
        itemType = 'building';
      }
    } else if (item is CollegeItem) {
      targetBuildingId = item.collegeId;
      itemType = 'marker';
    } else if (item is OfficeItem) {
      targetBuildingId = item.buildingId;
      itemType = 'office';

      if (targetBuildingId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} has no building location assigned'),
            backgroundColor: Color(0xFFFF8C00),
          ),
        );
        return;
      }
    }

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
          builder: (context) => building_content.BuildingDetailsPage(
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
          builder: (context) => college_content.CollegeDetailsPage(
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
          builder: (context) => office_content.OfficeDetailsPage(
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
              Expanded(
                child: Text(
                  item.description,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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

// Room Item Card
class RoomItemCard extends StatelessWidget {
  final RoomDisplayItem item;
  final Color color;
  final VoidCallback onTap;

  const RoomItemCard({
    super.key,
    required this.item,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.door_front_door,
                        color: color,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 8),
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
                SizedBox(height: 12),
                Expanded(
                  child: Text(
                    item.description,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'View Options',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
  final String? buildingType;

  BuildingItem({
    required this.buildingId,
    required this.name,
    required this.description,
    this.nickname,
    this.hasVideo = false,
    this.buildingType,
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

class RoomItem {
  final int roomId;
  final String roomName;
  final int buildingId;
  final String buildingName;
  final int? floorNumber;

  RoomItem({
    required this.roomId,
    required this.roomName,
    required this.buildingId,
    required this.buildingName,
    this.floorNumber,
  });
}
