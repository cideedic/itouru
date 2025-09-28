// rooms.dart (for buildings)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/components/footer.dart';

class RoomsTab extends StatefulWidget {
  const RoomsTab({super.key});

  @override
  State<RoomsTab> createState() => _RoomsTabState();
}

class _RoomsTabState extends State<RoomsTab> with TickerProviderStateMixin {
  final Map<String, List<Map<String, String>>> floors = {
    'Ground Floor': [
      {
        'room': 'Financial Management Division',
        'type': 'Office',
        'icon': 'business',
      },
      {
        'room': 'Payroll Administration Office',
        'type': 'Office',
        'icon': 'business',
      },
      {
        'room': 'University Cashier\'s Office',
        'type': 'Office',
        'icon': 'business',
      },
      {
        'room': 'General Administration and Support Services',
        'type': 'Office',
        'icon': 'business',
      },
      {
        'room': 'Motorpool Section',
        'type': 'Service Area',
        'icon': 'directions_car',
      },
    ],
    'Second Floor': [
      {'room': 'Room 201', 'type': 'Conference Room', 'icon': 'meeting_room'},
      {'room': 'Room 202', 'type': 'Office Space', 'icon': 'business'},
      {'room': 'Room 203', 'type': 'Storage Room', 'icon': 'inventory'},
    ],
    'Third Floor': [
      {'room': 'Room 301', 'type': 'Executive Office', 'icon': 'business'},
      {'room': 'Room 302', 'type': 'Meeting Room', 'icon': 'meeting_room'},
      {'room': 'Room 303', 'type': 'Archive Room', 'icon': 'folder'},
    ],
  };

  final Map<String, bool> expanded = {};
  final Map<String, AnimationController> controllers = {};

  @override
  void initState() {
    super.initState();
    for (var key in floors.keys) {
      expanded[key] = key == 'Ground Floor'; // Ground Floor starts expanded
      controllers[key] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
        value: key == 'Ground Floor' ? 1.0 : 0.0, // Start Ground Floor expanded
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

  IconData _getRoomIcon(String iconType) {
    switch (iconType) {
      case 'business':
        return Icons.business;
      case 'directions_car':
        return Icons.directions_car;
      case 'meeting_room':
        return Icons.meeting_room;
      case 'inventory':
        return Icons.inventory;
      case 'folder':
        return Icons.folder;
      default:
        return Icons.room;
    }
  }

  String _getFloorIcon(String floor) {
    if (floor.contains('Ground')) return '1';
    if (floor.contains('Second')) return '2';
    if (floor.contains('Third')) return '3';
    return '1';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ...floors.entries.map((entry) {
          final floor = entry.key;
          final rooms = entry.value;
          final isExpanded = expanded[floor] ?? false;
          final controller = controllers[floor]!;

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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _getFloorIcon(floor),
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      floor,
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
                        expanded[floor] = !isExpanded;
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
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(
                                          alpha: 0.05,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
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
                                            padding: EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(
                                                alpha: 0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              _getRoomIcon(room['icon'] ?? ''),
                                              color: Colors.orange,
                                              size: 20,
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  room['room'] ?? '',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                if (room['type']!
                                                    .isNotEmpty) ...[
                                                  SizedBox(height: 4),
                                                  Text(
                                                    room['type'] ?? '',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
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
        AppFooter(),
      ],
    );
  }
}
