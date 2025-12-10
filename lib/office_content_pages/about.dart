import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/info_card.dart';

class OfficeAboutTab extends StatelessWidget {
  final String officeServices;
  final String? buildingName;
  final String? roomName;
  final int? floorLevel; // NEW
  final Map<String, dynamic>? headData;
  final String? headImageUrl;
  final int? buildingId;
  final VoidCallback onDirectionsPressed;

  const OfficeAboutTab({
    super.key,
    required this.officeServices,
    this.buildingName,
    this.roomName,
    this.floorLevel, // NEW
    this.headData,
    this.headImageUrl,
    this.buildingId,
    required this.onDirectionsPressed,
  });

  // Helper function to parse and format text with bold VMGO keywords
  List<InlineSpan> _parseTextWithBoldKeywords(String text) {
    final keywords = [
      'VISION',
      'MISSION',
      'GOALS',
      'GOAL',
      'OBJECTIVES',
      'OBJECTIVE',
    ];

    List<InlineSpan> spans = [];
    String remainingText = text;

    for (var keyword in keywords) {
      List<InlineSpan> newSpans = [];

      for (var span
          in (spans.isEmpty ? [TextSpan(text: remainingText)] : spans)) {
        if (span is TextSpan && span.text != null) {
          String spanText = span.text!;
          List<String> parts = spanText.split(keyword);

          for (int i = 0; i < parts.length; i++) {
            if (parts[i].isNotEmpty) {
              newSpans.add(
                TextSpan(
                  text: parts[i],
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
              );
            }

            if (i < parts.length - 1) {
              newSpans.add(
                TextSpan(
                  text: keyword,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
              );
            }
          }
        } else {
          newSpans.add(span);
        }
      }

      spans = newSpans;
    }

    return spans.isEmpty
        ? [
            TextSpan(
              text: text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ]
        : spans;
  }

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

        // Head Information Card with Image
        if (headData != null && headData!.isNotEmpty) ...[
          SizedBox(height: 16),
          _buildHeadSection(),
        ],
      ],
    );
  }

  //  Build head section with image and info card
  Widget _buildHeadSection() {
    return InfoCard(headData: headData!, headImageUrl: headImageUrl);
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
    // Case 1: No building and no room - no location available
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

    // Case 2: Has building but no room - show only building
    if (buildingName != null && roomName == null) {
      return Row(
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
      );
    }

    // Case 3: Has both building and room - show building, floor, and room
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
        // Floor Level - only show if room exists
        if (floorLevel != null && roomName != null) ...[
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.layers, size: 18, color: Colors.grey[600]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Floor $floorLevel',
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
        if (roomName != null) ...[
          SizedBox(height: 8),
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

    // Check if content contains VMGO keywords
    final keywords = [
      'VISION',
      'MISSION',
      'GOALS',
      'GOAL',
      'OBJECTIVES',
      'OBJECTIVE',
    ];
    final hasKeywords = keywords.any((keyword) => content.contains(keyword));

    if (hasKeywords) {
      return RichText(
        text: TextSpan(children: _parseTextWithBoldKeywords(content)),
      );
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

        // Check if this is a standalone keyword (VISION, MISSION, etc.)
        final keywords = [
          'VISION',
          'MISSION',
          'GOALS',
          'GOAL',
          'OBJECTIVES',
          'OBJECTIVE',
        ];
        final trimmedItem = item.trim();
        if (keywords.contains(trimmedItem)) {
          return Padding(
            padding: EdgeInsets.only(bottom: 8, top: 8),
            child: Text(
              trimmedItem,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          );
        }

        // Check if line contains keywords
        final hasKeywords = keywords.any(
          (keyword) => trimmedItem.contains(keyword),
        );

        // If no number, display as text (with bold keywords if present)
        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: hasKeywords
              ? RichText(
                  text: TextSpan(
                    children: _parseTextWithBoldKeywords(trimmedItem),
                  ),
                )
              : Text(
                  trimmedItem,
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
    // Check if text contains VMGO keywords
    final keywords = [
      'VISION',
      'MISSION',
      'GOALS',
      'GOAL',
      'OBJECTIVES',
      'OBJECTIVE',
    ];
    final hasKeywords = keywords.any((keyword) => text.contains(keyword));

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
            child: hasKeywords
                ? RichText(
                    text: TextSpan(children: _parseTextWithBoldKeywords(text)),
                  )
                : Text(
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
