import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/building_content_pages/content.dart';

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

class _BuildingsTabState extends State<BuildingsTab> {
  // Group buildings by type
  Map<String, List<Map<String, dynamic>>> _groupBuildingsByType() {
    Map<String, List<Map<String, dynamic>>> grouped = {
      'Academic': [],
      'Non-Academic': [],
      'Facility': [],
    };

    for (var building in widget.buildings) {
      final buildingType = building['building_type']?.toString() ?? 'Facility';

      if (buildingType.toLowerCase().contains('academic') &&
          !buildingType.toLowerCase().contains('non')) {
        grouped['Academic']!.add(building);
      } else if (buildingType.toLowerCase().contains('non-academic')) {
        grouped['Non-Academic']!.add(building);
      } else {
        grouped['Facility']!.add(building);
      }
    }

    return grouped;
  }

  void _showBuildingDialog(
    BuildContext context,
    Map<String, dynamic> building,
  ) {
    final buildingName = building['building_name'] ?? 'Unnamed Building';
    final buildingId = building['building_id'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Building icon
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF8C00).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.apartment,
                    size: 48,
                    color: Color(0xFFFF8C00),
                  ),
                ),
                SizedBox(height: 20),

                // Building name
                Text(
                  buildingName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),

                // Question text
                Text(
                  'View this building?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),

                    // View button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigate to BuildingDetailsPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BuildingDetailsPage(
                                buildingId: buildingId,
                                buildingName: buildingName,
                                title: buildingName,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF8C00),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'View',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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

    final groupedBuildings = _groupBuildingsByType();

    return ListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        // Academic Buildings Section
        if (groupedBuildings['Academic']!.isNotEmpty) ...[
          _buildSectionDivider(
            'Academic Buildings',
            Icons.school,
            Color.fromARGB(255, 237, 86, 4),
          ),
          ...groupedBuildings['Academic']!.map(
            (building) => _buildBuildingCard(building),
          ),
          SizedBox(height: 16),
        ],

        // Non-Academic Buildings Section
        if (groupedBuildings['Non-Academic']!.isNotEmpty) ...[
          _buildSectionDivider(
            'Non-Academic Buildings',
            Icons.business,
            Color.fromARGB(255, 237, 86, 4),
          ),
          ...groupedBuildings['Non-Academic']!.map(
            (building) => _buildBuildingCard(building),
          ),
          SizedBox(height: 16),
        ],

        // Facilities Section
        if (groupedBuildings['Facility']!.isNotEmpty) ...[
          _buildSectionDivider(
            'Facilities',
            Icons.home_repair_service,
            Color.fromARGB(255, 237, 86, 4),
          ),
          ...groupedBuildings['Facility']!.map(
            (building) => _buildBuildingCard(building),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionDivider(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.9),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingCard(Map<String, dynamic> building) {
    final buildingId = building['building_id'];
    final buildingName = building['building_name'] ?? 'Unnamed Building';
    final buildingType = building['building_type']?.toString() ?? 'Facility';
    final rooms = widget.roomsByBuilding[buildingId.toString()] ?? [];

    // Calculate number of floors from rooms data
    int? floorCount;
    if (rooms.isNotEmpty) {
      Set<int> floors = {};
      for (var room in rooms) {
        if (room['floor_level'] != null) {
          floors.add(room['floor_level'] as int);
        }
      }
      if (floors.isNotEmpty) {
        floorCount = floors.length;
      }
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
      child: InkWell(
        onTap: () => _showBuildingDialog(context, building),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Building icon
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFFF8C00).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.apartment,
                  color: Color(0xFFFF8C00),
                  size: 24,
                ),
              ),
              SizedBox(width: 16),

              // Building info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buildingName,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.category, size: 12, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          buildingType,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (floorCount != null) ...[
                          SizedBox(width: 12),
                          Icon(Icons.layers, size: 12, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            '$floorCount ${floorCount == 1 ? 'floor' : 'floors'}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
