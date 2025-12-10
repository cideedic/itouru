import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../maps_assets/map_building.dart';
import '../maps_assets/map_boundary.dart';
import '../maps_assets/virtual_tour_manager.dart';
import '../main_pages/maps.dart';
import '../page_components/loading_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import '../maps_assets/routing_service.dart';
import '../maps_assets/location_service.dart';
import '../maps_assets/gate_selection_modal.dart';

class TourLoadingScreen extends StatefulWidget {
  final String tourName;
  final List<VirtualTourStop> tourStops;
  final bool? startFromCurrentLocation;
  final bool audioGuideEnabled;

  const TourLoadingScreen({
    super.key,
    required this.tourName,
    required this.tourStops,
    this.startFromCurrentLocation,
    this.audioGuideEnabled = true,
  });

  @override
  State<TourLoadingScreen> createState() => _TourLoadingScreenState();
}

class _TourLoadingScreenState extends State<TourLoadingScreen> {
  String _currentStatus = 'Initializing tour...';
  int _resolvedStops = 0;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeTour();
  }

  Future<void> _initializeTour() async {
    try {
      await _waitForMapData();
      await _resolveStopLocations();

      if (!mounted) return;

      // Check if user is off-campus and needs gate selection
      final userLocation = await LocationService.getCurrentLocation();
      final bool isOffCampus =
          userLocation.isSuccess &&
          userLocation.location != null &&
          !MapBoundary.isWithinCampusBounds(userLocation.location!);

      // Determine if we should show gate selection
      bool shouldSelectGate =
          isOffCampus &&
          (widget.startFromCurrentLocation == null ||
              widget.startFromCurrentLocation == false);

      if (shouldSelectGate && mounted) {
        // Show gate selection modal
        final selectedGate = await _showGateSelectionModal(
          userLocation: userLocation.location!,
          firstStopLocation: widget.tourStops.first.location!,
        );

        if (selectedGate == null) {
          // User cancelled - go back
          if (mounted) Navigator.pop(context);
          return;
        }

        // Navigate with selected gate
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Maps(
                startVirtualTour: true,
                tourName: widget.tourName,
                tourStops: widget.tourStops,
                useCurrentLocationAsStart: false,
                audioGuideEnabled: widget.audioGuideEnabled,
                selectedStartGate: selectedGate, // Pass selected gate
              ),
            ),
          );
        }
      } else {
        // Normal flow - no gate selection needed
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Maps(
                startVirtualTour: true,
                tourName: widget.tourName,
                tourStops: widget.tourStops,
                useCurrentLocationAsStart:
                    widget.startFromCurrentLocation ?? false,
                audioGuideEnabled: widget.audioGuideEnabled,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  // Add this new method to show gate selection modal
  Future<CampusGate?> _showGateSelectionModal({
    required LatLng userLocation,
    required LatLng firstStopLocation,
  }) async {
    // Show loading while calculating optimal gate
    setState(() {
      _currentStatus = 'Finding optimal gate...';
    });

    final gates = await RoutingService.getAllGates();

    // Calculate optimal gate (based on route duration)
    final optimalGate = await RoutingService.findOptimalGate(
      startPoint: userLocation,
      destinationPoint: firstStopLocation,
      gates: gates,
    );

    if (!mounted) return null;

    setState(() {
      _currentStatus = 'Select starting gate';
    });

    return showDialog<CampusGate>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GateSelectionDialog(
        gates: gates,
        userLocation: userLocation,
        destinationLocation: firstStopLocation,
        recommendedGate: optimalGate,
      ),
    );
  }

  Future<void> _waitForMapData() async {
    setState(() {
      _currentStatus = 'Loading map data...';
    });

    // Initialize map buildings if not already initialized
    if (!MapBuildings.isInitialized) {
      await MapBuildings.initializeWithBoundary(
        campusBoundaryPoints: MapBoundary.getCampusBoundaryPoints(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Map loading timed out');
        },
      );
    }

    // Wait a bit to ensure everything is loaded
    await Future.delayed(const Duration(milliseconds: 500));

    if (!MapBuildings.isInitialized) {
      throw Exception('Failed to initialize map data');
    }
  }

  Future<void> _resolveStopLocations() async {
    setState(() {
      _currentStatus = 'Preparing tour stops...';
    });

    int resolved = 0;
    int failed = 0;
    List<String> failedStopNames = []; // Track which stops failed

    for (var stop in widget.tourStops) {
      try {
        // Try to find as landmark marker first
        final marker = MapBuildings.landmarks.firstWhere(
          (m) => m.buildingId == stop.buildingId,
          orElse: () => MapBuildings.landmarks.first,
        );

        if (marker.buildingId == stop.buildingId) {
          stop.setLocation(marker.position, isMarkerType: true);
          resolved++;
        } else {
          // Try to find as building polygon
          final building = MapBuildings.campusBuildings.firstWhere(
            (b) => b.buildingId == stop.buildingId,
          );
          stop.setLocation(building.getCenterPoint(), isMarkerType: false);
          resolved++;
        }

        setState(() {
          _resolvedStops = resolved;
          _currentStatus =
              'Resolved $resolved of ${widget.tourStops.length} stops...';
        });

        // Small delay for visual feedback
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        failed++;
        failedStopNames.add(stop.buildingName);
        // Continue with other stops
      }
    }
    if (failed > 0 && mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text('Some Stops Not Found'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$failed of ${widget.tourStops.length} stops could not be located on the map:',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 12),
              ...failedStopNames.map(
                (name) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.close, size: 16, color: Colors.red[400]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Would you like to continue with $resolved available stops?',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                throw Exception('Tour cancelled by user');
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context), // Close dialog and continue
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (resolved == 0) {
      throw Exception('Could not find any valid tour stops');
    }

    setState(() {
      _currentStatus = 'Tour ready! Launching...';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Tour Error',
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                const SizedBox(height: 24),
                Text(
                  'Failed to load tour',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'Unknown error occurred',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Go Back',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _errorMessage = null;
                            _resolvedStops = 0;
                            _currentStatus = 'Initializing tour...';
                          });
                          _initializeTour();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8C00),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // Main loading widget
          LoadingScreen.dots(title: widget.tourName, subtitle: _currentStatus),

          // Progress indicator at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Column(
              children: [
                // Progress text
                if (_resolvedStops > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      '$_resolvedStops of ${widget.tourStops.length} stops ready',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // Progress bar
                if (widget.tourStops.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _resolvedStops / widget.tourStops.length,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF8C00),
                        ),
                        minHeight: 6,
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
}
