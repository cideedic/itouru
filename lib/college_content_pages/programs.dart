import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgramsTab extends StatefulWidget {
  const ProgramsTab({super.key});

  @override
  State<ProgramsTab> createState() => _ProgramsTabState();
}

class _ProgramsTabState extends State<ProgramsTab>
    with TickerProviderStateMixin {
  final Map<String, List<String>> programTypes = {
    'Undergraduate Programs': [
      'BS in Information Technology',
      'BS in Mathematics',
    ],
    'Graduated Programs': ['Master in Information Systems'],
    'Short-Term Programs': [
      'Web Development Bootcamp',
      'Data Science Workshop',
    ],
  };

  final Map<String, bool> expanded = {};
  final Map<String, AnimationController> controllers = {};

  @override
  void initState() {
    super.initState();
    for (var key in programTypes.keys) {
      expanded[key] = false;
      controllers[key] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ...programTypes.entries.map((entry) {
          final type = entry.key;
          final programs = entry.value;
          final isExpanded = expanded[type] ?? false;
          final controller = controllers[type]!;

          // Animate when expanded/collapsed
          if (isExpanded) {
            controller.forward();
          } else {
            controller.reverse();
          }

          return Card(
            margin: const EdgeInsets.symmetric(
              vertical: 8, // Reduced from 16 to make spaces smaller
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 1,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      type,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                    ),
                    trailing: AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.expand_more,
                        color: Colors.blue[800],
                        size: 28,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        expanded[type] = !isExpanded;
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
                          // Semi-visible divider line
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            height: 1,
                            color: Colors.grey[300],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: programs
                                  .map(
                                    (program) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6.0,
                                      ),
                                      child: Text(
                                        program,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
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
      ],
    );
  }
}
