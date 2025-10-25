import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BuildingAboutTab extends StatelessWidget {
  final String? description;
  final String? location;
  final int? numberOfFloors;
  final int numberOfRooms;
  final bool hasRooms;

  const BuildingAboutTab({
    super.key,
    this.description,
    this.location,
    this.numberOfFloors,
    this.numberOfRooms = 0,
    this.hasRooms = true,
  });

  void _handleDirections(BuildContext context) {
    // TODO: Implement directions functionality
    print('Get directions to building at: $location');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Opening directions...')));
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
          SizedBox(height: 16),
        ],

        // Location Card
        _buildSectionCard(
          'Location',
          Icons.location_on,
          Text(
            location ?? 'N/A',
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ),

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

        // Directions Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleDirections(context),
            icon: Icon(Icons.directions, size: 20),
            label: Text(
              'Get Directions',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
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
