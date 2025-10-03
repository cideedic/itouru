import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BuildingsTab extends StatefulWidget {
  const BuildingsTab({super.key});

  @override
  State<BuildingsTab> createState() => _BuildingsTabState();
}

class _BuildingsTabState extends State<BuildingsTab>
    with TickerProviderStateMixin {
  final Map<String, List<Map<String, String>>> buildings = {
    'Building 1': [
      {'room': 'Room 101', 'type': 'Lecture Room', 'floor': 'Ground Floor'},
      {'room': 'Room 102', 'type': 'Lecture Room', 'floor': 'Ground Floor'},
      {'room': 'Room 103', 'type': 'Lecture Room', 'floor': '2nd Floor'},
      {'room': 'Room 104', 'type': 'Laboratory', 'floor': '2nd Floor'},
      {'room': 'Room 104', 'type': 'Office, ICTO', 'floor': '3rd Floor'},
    ],
    'Building 2': [
      {'room': 'Room 201', 'type': 'Lecture Room', 'floor': 'Ground Floor'},
      {'room': 'Room 202', 'type': 'Laboratory', 'floor': 'Ground Floor'},
      {'room': 'Room 203', 'type': 'Computer Lab', 'floor': '2nd Floor'},
    ],
    'Building 3': [
      {'room': 'Room 301', 'type': 'Conference Room', 'floor': 'Ground Floor'},
      {'room': 'Room 302', 'type': 'Library', 'floor': 'Ground Floor'},
      {'room': 'Room 303', 'type': 'Study Hall', 'floor': '2nd Floor'},
    ],
    'Building 4': [
      {'room': 'Room 401', 'type': 'Auditorium', 'floor': 'Ground Floor'},
      {'room': 'Room 402', 'type': 'Faculty Office', 'floor': '2nd Floor'},
    ],
  };

  final Map<String, bool> expanded = {};
  final Map<String, AnimationController> controllers = {};

  @override
  void initState() {
    super.initState();
    for (var key in buildings.keys) {
      expanded[key] =
          key == 'Building 1 (4 -story)'; // Building 1 starts expanded
      controllers[key] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
        value: key == 'Building 1 (4 -story)'
            ? 1.0
            : 0.0, // Start Building 1 expanded
      );
    }
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  IconData _getRoomIcon(String roomType) {
    if (roomType.contains('Laboratory')) return Icons.science;
    if (roomType.contains('Office') || roomType.contains('ICTO')) {
      return Icons.business;
    }
    if (roomType.contains('Computer Lab')) return Icons.computer;
    if (roomType.contains('Library')) return Icons.local_library;
    if (roomType.contains('Conference')) return Icons.meeting_room;
    if (roomType.contains('Auditorium')) return Icons.theater_comedy;
    if (roomType.contains('Faculty')) return Icons.person;
    return Icons.school; // Default for lecture rooms
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ...buildings.entries.map((entry) {
          final building = entry.key;
          final rooms = entry.value;
          final isExpanded = expanded[building] ?? false;
          final controller = controllers[building]!;

          // Animate when expanded/collapsed
          if (isExpanded) {
            controller.forward();
          } else {
            controller.reverse();
          }

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            color: Colors.white,
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
                        Icons.business,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      building,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isExpanded)
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ),
                        if (!isExpanded) ...[
                          SizedBox(width: 8),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.expand_more,
                              color: Colors.blue[800],
                              size: 28,
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        expanded[building] = !isExpanded;
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
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              children: rooms
                                  .map(
                                    (room) => Container(
                                      margin: EdgeInsets.only(bottom: 12),
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(
                                          alpha: 0.05,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.orange.withValues(
                                            alpha: 0.2,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(
                                                alpha: 0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              _getRoomIcon(room['type'] ?? ''),
                                              color: Colors.orange,
                                              size: 16,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  room['room'] ?? '',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  '${room['type']} • ${room['floor']}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
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
        }),
        SizedBox(height: 20),
      ],
    );
  }
}
