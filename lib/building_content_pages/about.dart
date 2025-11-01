import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/main_pages/maps.dart';

class BuildingAboutTab extends StatelessWidget {
  final int? buildingId;
  final String buildingName;
  final String? buildingType;
  final String? description;
  final int? numberOfFloors;
  final int numberOfRooms;
  final bool hasRooms;

  const BuildingAboutTab({
    super.key,
    this.buildingId,
    required this.buildingName,
    this.buildingType,
    this.description,
    this.numberOfFloors,
    this.numberOfRooms = 0,
    this.hasRooms = true,
  });

  // ✅ UPDATED: Now allows directions for ALL building types including landmarks
  bool get _canGetDirections {
    // As long as we have a buildingId, we can get directions
    return buildingId != null;
  }

  void _handleDirections(BuildContext context) {
    // Check if buildingId is available
    if (buildingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Building location not available'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    print('\n🚀 === GET DIRECTIONS BUTTON PRESSED ===');
    print('📍 Building ID: $buildingId');
    print('📍 Building Name: $buildingName');
    print('📍 Building Type: $buildingType');
    print('📍 Is Landmark: ${buildingType?.toLowerCase() == 'landmark'}');

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

    // Determine item type based on building_type
    String itemType;
    if (buildingType?.toLowerCase() == 'landmark') {
      itemType = 'marker'; // Navigate to landmark marker
      print('🏛️ Landmark - Will navigate to marker');
    } else {
      itemType = 'building'; // Navigate to building polygon
      print('🏢 Building - Will navigate to polygon');
    }

    print('📋 Summary:');
    print('   - Target Building ID: $buildingId');
    print('   - Destination Name: $buildingName');
    print('   - Item Type: $itemType');
    print('🚀 === NAVIGATING TO MAPS PAGE ===\n');

    // Navigate to Maps page with auto-navigation
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Maps(
          buildingId: buildingId,
          destinationName: buildingName,
          itemType:
              itemType, // Uses 'marker' for landmarks, 'building' for regular buildings
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description Section
        if (description != null && description!.isNotEmpty) ...[
          _buildSectionCard(
            'Description',
            Icons.description,
            Text(
              description!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(height: 8),
        ],

        // Show Floors and Rooms only if building has rooms
        if (hasRooms) ...[
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSectionCard(
                  'Floors',
                  Icons.layers,
                  Text(
                    numberOfFloors?.toString() ?? 'N/A',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.6,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSectionCard(
                  'Rooms',
                  Icons.meeting_room,
                  Text(
                    numberOfRooms.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.6,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],

        SizedBox(height: 24),

        // ✅ UPDATED: Directions Button now works for landmarks too
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _canGetDirections
                ? () => _handleDirections(context)
                : null,
            icon: Icon(Icons.directions, size: 20),
            label: Text(
              _canGetDirections ? 'Get Directions' : 'Location Unavailable',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _canGetDirections
                  ? Colors.orange[700]
                  : Colors.grey[400],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: _canGetDirections ? 2 : 0,
              disabledBackgroundColor: Colors.grey[400],
              disabledForegroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Widget content) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title, icon),
          SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFFFF8C00), size: 24),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
