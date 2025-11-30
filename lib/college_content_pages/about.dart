import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/info_card.dart';

class AboutTab extends StatelessWidget {
  final String description;
  final String learningOutcomes;
  final String objectives;
  final Map<String, dynamic>? headData;

  const AboutTab({
    super.key,
    required this.description,
    required this.learningOutcomes,
    required this.objectives,
    this.headData,
  });

  bool _isNotEmpty(String? text) {
    return text != null && text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        if (_isNotEmpty(description)) ...[
          _buildSectionCard(
            'Description',
            Icons.description,
            _buildTextContent(description),
          ),
          SizedBox(height: 16),
        ],

        // Learning Outcomes
        if (_isNotEmpty(learningOutcomes)) ...[
          _buildSectionCard(
            'Learning Outcomes',
            Icons.psychology,
            _buildTextContent(learningOutcomes),
          ),
          SizedBox(height: 16),
        ],

        // Objectives
        if (_isNotEmpty(objectives)) ...[
          _buildSectionCard(
            'Objectives',
            Icons.checklist,
            _buildTextContent(objectives),
          ),
          SizedBox(height: 16),
        ],

        // Head/Dean Information Card
        if (headData != null) ...[InfoCard(headData: headData)],
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
