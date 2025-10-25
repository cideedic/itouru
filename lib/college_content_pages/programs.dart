// programs.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgramsTab extends StatefulWidget {
  final List<Map<String, dynamic>> programs;

  const ProgramsTab({super.key, required this.programs});

  @override
  State<ProgramsTab> createState() => _ProgramsTabState();
}

class _ProgramsTabState extends State<ProgramsTab> {
  String selectedProgramType = 'All';
  List<String> availableProgramTypes = [];

  @override
  void initState() {
    super.initState();
    _initializeProgramTypes();
  }

  void _initializeProgramTypes() {
    // Get unique program types from the data
    Set<String> types = {};
    for (var program in widget.programs) {
      if (program['program_type'] != null) {
        types.add(program['program_type'] as String);
      }
    }
    availableProgramTypes = types.toList()..sort();
  }

  List<Map<String, dynamic>> _getFilteredPrograms() {
    if (selectedProgramType == 'All') {
      return widget.programs;
    }

    return widget.programs
        .where((program) => program['program_type'] == selectedProgramType)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.programs.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No programs available',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    List<Map<String, dynamic>> filteredPrograms = _getFilteredPrograms();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Program Type Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildProgramTypeChip('All'),
              ...availableProgramTypes.map(
                (type) => _buildProgramTypeChip(type),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),

        // Program Count
        Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            '${filteredPrograms.length} ${filteredPrograms.length == 1 ? 'Program' : 'Programs'}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),

        // Programs List
        ...filteredPrograms.map((program) => _buildProgramCard(program)),
      ],
    );
  }

  Widget _buildProgramTypeChip(String type) {
    final isSelected = selectedProgramType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(type == 'All' ? 'All Programs' : type),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedProgramType = type;
          });
        },
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black87,
        ),
        backgroundColor: Colors.grey[100],
        selectedColor: Colors.orange[700],
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? Colors.orange[700]! : Colors.grey[300]!,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildProgramCard(Map<String, dynamic> program) {
    final programName = program['programs']?.toString() ?? 'N/A';
    final programType = program['program_type']?.toString() ?? 'N/A';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.school, color: Colors.orange[700], size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  programName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (selectedProgramType == 'All') ...[
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      programType,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
