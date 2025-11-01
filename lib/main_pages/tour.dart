import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/header.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/main_pages/maps.dart'; // ✨ Import Maps page
import 'package:itouru/maps_assets/virtual_tour_manager.dart'; // ✨ Import VirtualTourManager

class Tours extends StatefulWidget {
  const Tours({super.key});

  @override
  ToursState createState() => ToursState();
}

class ToursState extends State<Tours> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _tours = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTours();
  }

  Future<void> _fetchTours() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('🔍 DEBUG: Fetching tours from database...');

      final response = await supabase
          .from('Tours')
          .select('id, name, description, is_active')
          .eq('is_active', true)
          .order('name');

      print('✅ DEBUG: Tours response received');
      print('📊 DEBUG: Number of tours: ${response.length}');
      print('🗂️ DEBUG: Tours data: $response');

      setState(() {
        _tours = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      print('✓ DEBUG: Tours state updated successfully');
    } catch (e) {
      print('❌ ERROR fetching tours: $e');
      print('📍 ERROR stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onTourTap(Map<String, dynamic> tour) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TourBuildingsPage(tour: tour)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ReusableHeader(),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Colors.orange[400]),
                  )
                : _tours.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.tour_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No tours available',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchTours,
                    color: Colors.orange[400],
                    child: ListView.builder(
                      padding: EdgeInsets.all(20),
                      itemCount: _tours.length,
                      itemBuilder: (context, index) {
                        final tour = _tours[index];
                        return _buildTourCard(tour);
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: ReusableBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildTourCard(Map<String, dynamic> tour) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTourTap(tour),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: Colors.orange[400],
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  // Tour details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tour['name'] ?? 'Unnamed Tour',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (tour['description'] != null &&
                            tour['description'].toString().isNotEmpty) ...[
                          SizedBox(height: 4),
                          Text(
                            tour['description'],
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey[400],
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Tour Buildings Page
class TourBuildingsPage extends StatefulWidget {
  final Map<String, dynamic> tour;

  const TourBuildingsPage({super.key, required this.tour});

  @override
  TourBuildingsPageState createState() => TourBuildingsPageState();
}

class TourBuildingsPageState extends State<TourBuildingsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _buildings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBuildings();
  }

  Future<void> _fetchBuildings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('');
      print('═══════════════════════════════════════════════');
      print('🏢 FETCHING BUILDINGS FOR TOUR');
      print('═══════════════════════════════════════════════');
      print('🆔 Tour ID: ${widget.tour['id']}');
      print('📝 Tour Name: ${widget.tour['name']}');
      print('🗂️  Full Tour Object: ${widget.tour}');
      print('───────────────────────────────────────────────');

      final response = await supabase
          .from('Tour Stops')
          .select('''
            tour_stops_id,
            building_id,
            stop_order,
            notes,
            Building!inner(
              building_name,
              building_nickname
            )
          ''')
          .eq('tour_id', widget.tour['id'])
          .order('stop_order', ascending: true);

      print('');
      print('✅ RESPONSE RECEIVED FROM DATABASE');
      print('📊 Total Buildings Returned: ${response.length}');
      print('───────────────────────────────────────────────');

      if (response.isEmpty) {
        print('⚠️  WARNING: No buildings found for this tour!');
      } else {
        print('📋 BUILDINGS IN ORDER RETURNED:');
        for (var i = 0; i < response.length; i++) {
          final building = response[i];
          final buildingData = building['Building'];
          print('');
          print('  Stop #${i + 1} (Array Index: $i)');
          print('  ├─ tour_stops_id: ${building['tour_stops_id']}');
          print('  ├─ building_id: ${building['building_id']}');
          print('  ├─ stop_order: ${building['stop_order']}');
          print('  ├─ building_name: ${buildingData['building_name']}');
          print('  ├─ building_nickname: ${buildingData['building_nickname']}');
          print('  └─ notes: ${building['notes']}');
        }
      }

      print('───────────────────────────────────────────────');
      print('🗂️  Raw Response Data: $response');
      print('═══════════════════════════════════════════════');
      print('');

      setState(() {
        _buildings = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      print('✓ Buildings state updated successfully');
      print('✓ UI will now render ${_buildings.length} building cards');
      print('');
    } catch (e) {
      print('');
      print('═══════════════════════════════════════════════');
      print('❌ ERROR FETCHING BUILDINGS');
      print('═══════════════════════════════════════════════');
      print('Error: $e');
      print('Stack Trace: ${StackTrace.current}');
      print('═══════════════════════════════════════════════');
      print('');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Building UI with ${_buildings.length} buildings');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.tour['name'] ?? 'Tour Details',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.orange[400]))
          : _buildings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.apartment_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No buildings in this tour',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // List of buildings
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(20),
                    itemCount: _buildings.length,
                    itemBuilder: (context, index) {
                      final building = _buildings[index];
                      final displayNumber = index + 1;

                      print(
                        '🎯 Rendering card at index $index as stop #$displayNumber',
                      );
                      print(
                        '   Building: ${building['Building']['building_name']}',
                      );
                      print('   stop_order from DB: ${building['stop_order']}');

                      return _buildBuildingCard(building, displayNumber);
                    },
                  ),
                ),
                // Buttons section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Start Virtual Tour button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _startVirtualTour,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[400],
                            padding: EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_circle_filled,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Start Virtual Tour',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ✨ NEW: Start virtual tour method
  void _startVirtualTour() {
    print('\n🎬 === PREPARING VIRTUAL TOUR ===');
    print('Tour: ${widget.tour['name']}');
    print('Buildings: ${_buildings.length}');

    // Prepare tour stops
    List<VirtualTourStop> stops = [];

    for (var building in _buildings) {
      final buildingData = building['Building'];
      final stopOrder = building['stop_order'] as int;
      final buildingId = building['building_id'] as int;

      stops.add(
        VirtualTourStop(
          stopNumber: stopOrder,
          buildingId: buildingId,
          buildingName: buildingData['building_name'] ?? 'Unknown Building',
          buildingNickname: buildingData['building_nickname'] ?? '',
          notes: building['notes'] as String?,
          location: null, // Will be resolved in Maps page
        ),
      );
    }

    print('✅ Prepared ${stops.length} stops');
    print('🎬 === END PREPARATION ===\n');

    // Navigate to Maps with virtual tour data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Maps(
          startVirtualTour: true,
          tourName: widget.tour['name'],
          tourStops: stops,
        ),
      ),
    );
  }

  Widget _buildBuildingCard(Map<String, dynamic> building, int number) {
    final buildingData = building['Building'];
    final buildingName = buildingData?['building_name'] ?? 'Unknown Building';
    final buildingNickname = buildingData?['building_nickname'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stop number
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange[400],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            // Building details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    buildingName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (buildingNickname.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      buildingNickname,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  if (building['notes'] != null &&
                      building['notes'].toString().isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      building['notes'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
