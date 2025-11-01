import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BuildingRoomsTab extends StatefulWidget {
  final List<Map<String, dynamic>> rooms;

  const BuildingRoomsTab({super.key, required this.rooms});

  @override
  State<BuildingRoomsTab> createState() => _BuildingRoomsTabState();
}

class _BuildingRoomsTabState extends State<BuildingRoomsTab> {
  String selectedFloor = 'All';
  List<int> availableFloors = [];

  @override
  void initState() {
    super.initState();
    _initializeFloors();
  }

  void _initializeFloors() {
    // Get unique floors from rooms data
    Set<int> floors = {};
    for (var room in widget.rooms) {
      if (room['floor_level'] != null) {
        floors.add(room['floor_level'] as int);
      }
    }
    availableFloors = floors.toList()..sort();
  }

  List<Map<String, dynamic>> _getFilteredRooms() {
    List<Map<String, dynamic>> filtered;

    if (selectedFloor == 'All') {
      filtered = List.from(widget.rooms);
    } else {
      int floorNumber = int.parse(selectedFloor);
      filtered = widget.rooms
          .where((room) => room['floor_level'] == floorNumber)
          .toList();
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
    if (widget.rooms.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.meeting_room_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'No rooms available',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    List<Map<String, dynamic>> filteredRooms = _getFilteredRooms();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Floor Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFloorChip('All'),
              ...availableFloors.map(
                (floor) => _buildFloorChip(floor.toString()),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),

        // Room Count
        Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            '${filteredRooms.length} ${filteredRooms.length == 1 ? 'Room' : 'Rooms'}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),

        // Rooms List
        ...filteredRooms.map((room) => _buildRoomCard(room)),
      ],
    );
  }

  Widget _buildFloorChip(String floor) {
    final isSelected = selectedFloor == floor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(floor == 'All' ? 'All Floors' : 'Floor $floor'),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedFloor = floor;
          });
        },
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
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
                  size: 20,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Floor ${room['floor_level']?.toString() ?? '?'}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[900],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Show room number below the room name only when a name exists AND a number is present
                    if (hasName && roomNumberExists) ...[
                      SizedBox(height: 4),
                      Text(
                        'Room $roomNumberRaw',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (room['room_type'] != null || room['capacity'] != null) ...[
            SizedBox(height: 12),
            Divider(color: Colors.grey[300]),
            SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (room['room_type'] != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        room['room_type'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                if (room['capacity'] != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        '${room['capacity']} capacity',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
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
