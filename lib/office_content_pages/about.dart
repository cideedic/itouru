import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/info_card.dart';

class OfficeAboutTab extends StatelessWidget {
  final String officeServices;
  final String? buildingName;
  final String? roomName;
  final Map<String, dynamic>? headData;
  final int? buildingId;
  final VoidCallback onDirectionsPressed;

  const OfficeAboutTab({
    super.key,
    required this.officeServices,
    this.buildingName,
    this.roomName,
    this.headData,
    this.buildingId,
    required this.onDirectionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Office Services (Description)
        if (officeServices.isNotEmpty) ...[
          _buildSectionCard(
            'Description',
            Icons.description,
            _buildTextContent(officeServices),
          ),
          SizedBox(height: 16),
        ],

        // Location Card
        _buildSectionCard(
          'Location',
          Icons.location_on,
          _buildLocationContent(),
        ),
        SizedBox(height: 16),

        // Directions Button - Only show if building is assigned
        if (buildingId != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onDirectionsPressed,
              icon: Icon(Icons.directions, size: 20),
              label: Text(
                'Get Directions',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),

        // Head Information Card
        if (headData != null && headData!.isNotEmpty) ...[
          SizedBox(height: 16),
          InfoCard(headData: headData!),
        ],
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
            color: Colors.black.withValues(alpha: 0.08),
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
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationContent() {
    if (buildingName == null && roomName == null) {
      return Text(
        'Location information not available',
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
          height: 1.6,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (buildingName != null) ...[
          Row(
            children: [
              Icon(Icons.apartment, size: 18, color: Colors.grey[600]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  buildingName!,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (buildingName != null && roomName != null) SizedBox(height: 8),
        if (roomName != null) ...[
          Row(
            children: [
              Icon(Icons.meeting_room, size: 18, color: Colors.grey[600]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  roomName!,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTextContent(String content) {
    // Check if content has numbered items
    if (content.contains(RegExp(r'^\d+\.', multiLine: true))) {
      return _buildNumberedList(content);
    }

    // Otherwise, display as regular text
    return Text(
      content,
      style: GoogleFonts.poppins(
        fontSize: 13,
        height: 1.6,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildNumberedList(String content) {
    // Split by newlines and filter out empty lines
    final items = content
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        // Check if item starts with a number
        final match = RegExp(r'^(\d+)\.\s*(.+)').firstMatch(item.trim());
        if (match != null) {
          final number = match.group(1);
          final text = match.group(2);
          return _buildNumberedItem(int.parse(number!), text!);
        }
        // If no number, just display as text
        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            item,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumberedItem(int number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
