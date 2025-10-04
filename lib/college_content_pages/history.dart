import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/footer.dart';

class HistoryTab extends StatefulWidget {
  final List<Map<String, String>> historyEntries;

  const HistoryTab({super.key, required this.historyEntries});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(widget.historyEntries.length, (index) {
          final entry = widget.historyEntries[index];
          final isLast = index == widget.historyEntries.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline indicator and line
              Column(
                children: [
                  // Circle
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange, width: 4),
                      color: Colors.white,
                    ),
                  ),
                  // Line (only if not last)
                  if (!isLast)
                    Container(width: 4, height: 60, color: Colors.orange),
                ],
              ),
              SizedBox(width: 16),
              // Entry content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry['title'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 18, // Reduced from 20 to 18
                          fontWeight: FontWeight
                              .w600, // Changed from bold to w600 for consistency
                          color: Colors
                              .blue[800], // Changed from Colors.blue[800] to Colors.blue
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        entry['date'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 12, // Reduced from 14 to 12
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        entry['description'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 12, // Reduced from 14 to 12
                          color: Colors
                              .grey[700], // Changed from Colors.black87 to Colors.grey[700] for consistency
                          height:
                              1.6, // Added line height for better readability
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
        AppFooter(),
      ],
    );
  }
}
