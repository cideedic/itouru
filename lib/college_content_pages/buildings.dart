import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BuildingsTab extends StatefulWidget {
  final List<Map<String, dynamic>> buildings;
  final Map<String, List<Map<String, dynamic>>> roomsByBuilding;

  const BuildingsTab({
    super.key,
    required this.buildings,
    required this.roomsByBuilding,
  });

  @override
  State<BuildingsTab> createState() => _BuildingsTabState();
}

class _BuildingsTabState extends State<BuildingsTab>
    with TickerProviderStateMixin {
  final Map<String, bool> expanded = {};
  final Map<String, AnimationController> controllers = {};
  final Map<String, String> selectedFloorPerBuilding = {};
  final Map<String, TextEditingController> searchControllers = {};
  final Map<String, String> searchQueries = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(BuildingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinitialize if buildings list changes
    if (oldWidget.buildings != widget.buildings) {
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    // Initialize expanded state, controllers, and floor filters for each building
    for (var building in widget.buildings) {
      final buildingId = building['building_id'].toString();

      // Only initialize if not already present
      if (!expanded.containsKey(buildingId)) {
        expanded[buildingId] = false;
      }
      if (!selectedFloorPerBuilding.containsKey(buildingId)) {
        selectedFloorPerBuilding[buildingId] = 'All';
      }
      if (!searchControllers.containsKey(buildingId)) {
        searchControllers[buildingId] = TextEditingController();
      }
      if (!searchQueries.containsKey(buildingId)) {
        searchQueries[buildingId] = '';
      }
      if (!controllers.containsKey(buildingId)) {
        controllers[buildingId] = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 350),
          value: 0.0,
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    for (var searchController in searchControllers.values) {
      searchController.dispose();
    }
    super.dispose();
  }

  List<int> _getAvailableFloorsForBuilding(String buildingId) {
    final rooms = widget.roomsByBuilding[buildingId] ?? [];
    Set<int> floors = {};
    for (var room in rooms) {
      if (room['floor_level'] != null) {
        floors.add(room['floor_level'] as int);
      }
    }
    return floors.toList()..sort();
  }

  List<Map<String, dynamic>> _getFilteredRoomsForBuilding(String buildingId) {
    final rooms = widget.roomsByBuilding[buildingId] ?? [];
    final selectedFloor = selectedFloorPerBuilding[buildingId] ?? 'All';
    final searchQuery = searchQueries[buildingId] ?? '';

    List<Map<String, dynamic>> filtered;

    // First filter by floor
    if (selectedFloor == 'All') {
      filtered = List.from(rooms);
    } else {
      int floorNumber = int.parse(selectedFloor);
      filtered = rooms
          .where((room) => room['floor_level'] == floorNumber)
          .toList();
    }

    // Then filter by search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((room) {
        final roomName = room['room_name']?.toString().toLowerCase() ?? '';
        final roomNumber = room['room_number']?.toString().toLowerCase() ?? '';
        final query = searchQuery.toLowerCase();

        return roomName.contains(query) || roomNumber.contains(query);
      }).toList();
    }

    // Sort rooms: first by whether they have room_number, then by room_number or room_name
    filtered.sort((a, b) {
      final aNumber = a['room_number']?.toString().trim() ?? '';
      final bNumber = b['room_number']?.toString().trim() ?? '';
      final aHasNumber = aNumber.isNotEmpty;
      final bHasNumber = bNumber.isNotEmpty;

      // Rooms with numbers come before rooms without numbers
      if (aHasNumber && !bHasNumber) return -1;
      if (!aHasNumber && bHasNumber) return 1;

      // Both have room numbers - sort by room number
      if (aHasNumber && bHasNumber) {
        // Try to parse as numbers first for proper numeric sorting
        final aNum = int.tryParse(aNumber);
        final bNum = int.tryParse(bNumber);

        if (aNum != null && bNum != null) {
          return aNum.compareTo(bNum);
        }

        // If not both numbers, do string comparison
        return aNumber.compareTo(bNumber);
      }

      // Both don't have room numbers - sort by room name
      final aName = a['room_name']?.toString().trim() ?? '';
      final bName = b['room_name']?.toString().trim() ?? '';
      return aName.compareTo(bName);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.buildings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.apartment, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No Buildings Available',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Building information will appear here once added.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: widget.buildings.length,
      itemBuilder: (context, index) {
        final building = widget.buildings[index];
        final buildingId = building['building_id'].toString();
        final buildingName = building['building_name'] ?? 'Unnamed Building';
        final isExpanded = expanded[buildingId] ?? false;
        final controller = controllers[buildingId];
        final searchController = searchControllers[buildingId];

        // Safety check - if controller is null, skip this building
        if (controller == null || searchController == null) {
          return SizedBox.shrink();
        }

        final availableFloors = _getAvailableFloorsForBuilding(buildingId);
        final filteredRooms = _getFilteredRoomsForBuilding(buildingId);
        final totalRooms = widget.roomsByBuilding[buildingId]?.length ?? 0;
        final searchQuery = searchQueries[buildingId] ?? '';

        // Animate when expanded/collapsed
        if (isExpanded) {
          controller.forward();
        } else {
          controller.reverse();
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.apartment,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    buildingName,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  trailing: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                  onTap: () {
                    setState(() {
                      expanded[buildingId] = !isExpanded;
                    });
                  },
                ),
                SizeTransition(
                  sizeFactor: CurvedAnimation(
                    parent: controller,
                    curve: Curves.easeOutCubic,
                  ),
                  child: FadeTransition(
                    opacity: controller,
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          height: 1,
                          color: Colors.grey[300],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 8,
                            left: 8,
                            right: 8,
                            bottom: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Search Bar (only show if there are rooms)
                              if (totalRooms > 0) ...[
                                Container(
                                  margin: EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: searchController,
                                    onChanged: (value) {
                                      setState(() {
                                        searchQueries[buildingId] = value;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search by room name or number...',
                                      hintStyle: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey[500],
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: Colors.grey[600],
                                        size: 20,
                                      ),
                                      suffixIcon: searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.clear,
                                                color: Colors.grey[600],
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  searchController.clear();
                                                  searchQueries[buildingId] =
                                                      '';
                                                });
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],

                              // Floor Filter Chips
                              if (availableFloors.isNotEmpty) ...[
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildFloorChip(buildingId, 'All'),
                                      ...availableFloors.map(
                                        (floor) => _buildFloorChip(
                                          buildingId,
                                          floor.toString(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),
                              ],

                              // Room Count
                              if (totalRooms > 0)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    '${filteredRooms.length} ${filteredRooms.length == 1 ? 'Room' : 'Rooms'}${searchQuery.isNotEmpty ? ' found' : ''}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),

                              // Rooms List or No Results
                              if (totalRooms == 0)
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.meeting_room_outlined,
                                        size: 40,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'No rooms available',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (filteredRooms.isEmpty &&
                                  searchQuery.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 40,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'No rooms found',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Try adjusting your search',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ...filteredRooms.map(
                                  (room) => _buildRoomCard(room),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloorChip(String buildingId, String floor) {
    final isSelected = selectedFloorPerBuilding[buildingId] == floor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(floor == 'All' ? 'All Floors' : 'Floor $floor'),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedFloorPerBuilding[buildingId] = floor;
          });
        },
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black87,
        ),
        backgroundColor: Colors.grey[100],
        selectedColor: Colors.orange[700],
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? Colors.orange[700]! : Colors.grey[300]!,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final hasName =
        room['room_name'] != null &&
        room['room_name'].toString().trim().isNotEmpty;
    final roomNumberRaw = room['room_number']?.toString().trim();
    final roomNumberExists = roomNumberRaw != null && roomNumberRaw.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.door_front_door,
                  color: Colors.orange[700],
                  size: 18,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Highlight: room name (or fallback to Room <number> if number exists)
                        Expanded(
                          child: Text(
                            hasName
                                ? room['room_name']
                                : (roomNumberExists
                                      ? 'Room $roomNumberRaw'
                                      : 'Room'),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Floor ${room['floor_level']?.toString() ?? '?'}',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[900],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Show room number below the room name only when a name exists AND a number is present
                    if (hasName && roomNumberExists)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Room $roomNumberRaw',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (room['room_type'] != null || room['capacity'] != null) ...[
            SizedBox(height: 10),
            Divider(color: Colors.grey[300], height: 1),
            SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (room['room_type'] != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        room['room_type'],
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                if (room['capacity'] != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        '${room['capacity']} capacity',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
