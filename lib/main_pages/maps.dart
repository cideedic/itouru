import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../page_components/bottom_nav_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/office_content_pages/content.dart';
import 'package:shared_preferences/shared_preferences.dart';
// map_assets:
import '../maps_assets/map_boundary.dart';
import '../maps_assets/map_building.dart';
import '../maps_assets/location_service.dart';
import '../maps_assets/map_utils.dart';
import '../maps_assets/map_widgets.dart';
import '../maps_assets/bottom_content.dart';
import '../maps_assets/routing_service.dart';
import '../maps_assets/building_matcher.dart';
import '../maps_assets/virtual_tour_manager.dart';
import '../maps_assets/virtual_tour_card.dart';
import '../maps_assets/tour_stops_number.dart';
import '../maps_assets/nearby_image_manager.dart';
import '../maps_assets/destination_end_marker.dart';
import '../maps_assets/audio_guide_service.dart';

class Maps extends StatefulWidget {
  final LatLng? autoNavigateTo;
  final String? destinationName;
  final int? buildingId;
  final String? itemType;

  final bool startVirtualTour;
  final String? tourName;
  final List<VirtualTourStop>? tourStops;
  final int? skipToStopIndex;
  final bool useCurrentLocationAsStart;
  final bool audioGuideEnabled;
  final CampusGate? selectedStartGate;

  const Maps({
    super.key,
    this.autoNavigateTo,
    this.destinationName,
    this.buildingId,
    this.itemType,
    this.startVirtualTour = false,
    this.tourName,
    this.tourStops,
    this.skipToStopIndex,
    this.useCurrentLocationAsStart = false,
    this.audioGuideEnabled = true,
    this.selectedStartGate,
  });

  @override
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchResults = false;
  late NavigationManager _navigationManager;
  late NearbyImageManager _nearbyImageManager;
  bool _autoFollowLocation = false;
  bool _isDisposed = false;
  double _currentZoom = 17.0;
  List<LatLng> _animatedRoutePoints = [];
  LatLng? _tourStartPoint;
  double _currentRotation = 0.0;
  double _currentHeading = 0.0;
  bool _isLoadingMapData = true;
  bool _mapDataLoadFailed = false;
  String? _mapDataError;
  int _retryAttempts = 0;
  static const int maxRetryAttempts = 3;
  bool _showColleges = true;
  bool _showLandmarks = true;
  bool _showGates = true;
  bool _showDestinationMarker = false;
  bool _animateDestinationMarker = false;
  LatLng? _navigationStartPoint;
  int? _targetedBuildingId;
  int? _selectedMarkerId;
  int? _hiddenMarkerId;
  bool _isMarkerType = false;
  bool _isNavigatingToMarker = false;

  bool _isCollegeMarker = false;

  late VirtualTourManager _virtualTourManager;
  bool _isVirtualTourActive = false;

  MapTileType _currentTileType = MapTileType.standard;
  static const String _tileTypePreferenceKey = 'map_tile_type_preference';

  @override
  void initState() {
    super.initState();

    _navigationManager = NavigationManager();
    _virtualTourManager = VirtualTourManager();
    _nearbyImageManager = NearbyImageManager();
    _virtualTourManager.initializeAudioGuide();

    _setupNavigationCallbacks();
    _setupVirtualTourCallbacks();
    _startContinuousLocationTracking();
    _startLocationTracking();
    _loadMapDataWithRetry();
    _currentZoom = MapBoundary.getInitialZoom();
    LocationService.initializeCompass();
    _checkAndShowFirstTimeGuide();
    _loadTileTypePreference();

    if (widget.startVirtualTour && widget.tourStops != null) {
      _scheduleVirtualTourStart();
    } else if (widget.buildingId != null || widget.destinationName != null) {
      _scheduleAutoNavigation();
    }
  }

  Future<void> _checkAndShowFirstTimeGuide() async {
    final hasSeenGuide = await MapWidgets.hasSeenGuide();
    if (!hasSeenGuide) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted && context.mounted) {
        await MapWidgets.showMapGuideModal(context, isFirstTime: true);
      }
    }
  }

  /// Load saved tile type preference
  Future<void> _loadTileTypePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedType = prefs.getString(_tileTypePreferenceKey);

      if (savedType != null && mounted) {
        setState(() {
          _currentTileType = savedType == 'satellite'
              ? MapTileType.satellite
              : MapTileType.standard;
        });
      }
    } catch (e) {
      debugPrint('Failed to load tile preference: $e');
    }
  }

  /// Save tile type preference
  Future<void> _saveTileTypePreference(MapTileType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _tileTypePreferenceKey,
        type == MapTileType.satellite ? 'satellite' : 'standard',
      );
    } catch (e) {
      debugPrint('Failed to save tile preference: $e');
    }
  }

  /// Handle tile type change
  void _onTileTypeChanged(MapTileType newType) {
    if (_isDisposed) return;

    setState(() {
      _currentTileType = newType;
    });

    _saveTileTypePreference(newType);

    // Show feedback
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                newType == MapTileType.satellite
                    ? Icons.satellite_alt
                    : Icons.map,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                'Switched to ${newType == MapTileType.satellite ? 'Satellite' : 'Standard'} view',
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.blue[700]),
                    SizedBox(width: 12),
                    Text(
                      'Map Filters',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  'Show or hide map elements',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 12),

                // College Markers Toggle
                _buildFilterTile(
                  icon: Icons.school,
                  iconColor: Colors.blue,
                  title: 'College Markers',
                  description: 'Academic colleges and departments',
                  value: _showColleges,
                  onChanged: (value) {
                    setModalState(() => _showColleges = value);
                    setState(() => _showColleges = value);
                  },
                ),
                Divider(height: 32),

                // Landmarks Toggle
                _buildFilterTile(
                  icon: Icons.circle,
                  iconColor: Colors.red,
                  title: 'Landmarks',
                  description: 'Important campus locations',
                  value: _showLandmarks,
                  onChanged: (value) {
                    setModalState(() => _showLandmarks = value);
                    setState(() => _showLandmarks = value);
                  },
                ),
                Divider(height: 32),

                // Gates Toggle
                Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.green.shade700,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.door_sliding,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Campus Gates',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Entry and exit points',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _showGates,
                        onChanged: (value) {
                          setModalState(() => _showGates = value);
                          setState(() => _showGates = value);
                        },
                        activeColor: Colors.orange,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Reset Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setModalState(() {
                        _showColleges = true;
                        _showLandmarks = true;
                        _showGates = true;
                      });
                      setState(() {
                        _showColleges = true;
                        _showLandmarks = true;
                        _showGates = true;
                      });
                    },
                    icon: Icon(Icons.refresh, color: Colors.orange),
                    label: Text(
                      'Reset to Default',
                      style: TextStyle(color: Colors.orange),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 2),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeColor: Colors.orange),
      ],
    );
  }

  bool _enhancedSearchMatch(dynamic item, String query) {
    if (query.trim().isEmpty) return false;

    final lowerQuery = query.toLowerCase().trim();

    // Match by primary name
    if (item.name.toLowerCase().contains(lowerQuery)) {
      return true;
    }

    // Handle BicolBuildingPolygon (buildings)
    if (item is BicolBuildingPolygon) {
      // Match by database name
      if (item.databaseName != null &&
          item.databaseName!.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // Match by nickname (with and without spaces)
      if (item.databaseNickname != null) {
        final lowerNickname = item.databaseNickname!.toLowerCase();

        // Direct match
        if (lowerNickname.contains(lowerQuery)) {
          return true;
        }

        // Space-less match: "CSB1" matches "CS B1"
        final spacelessNickname = lowerNickname.replaceAll(' ', '');
        final spacelessQuery = lowerQuery.replaceAll(' ', '');

        if (spacelessNickname.contains(spacelessQuery) ||
            spacelessQuery.contains(spacelessNickname)) {
          return true;
        }
      }
    }

    // Handle BicolMarker (colleges/landmarks)
    if (item is BicolMarker) {
      // Match by database name
      if (item.databaseName != null &&
          item.databaseName!.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // Match by abbreviation (with and without spaces)
      if (item.abbreviation != null) {
        final lowerAbbreviation = item.abbreviation!.toLowerCase();

        // Direct match
        if (lowerAbbreviation.contains(lowerQuery)) {
          return true;
        }

        // Space-less match: "CEAT" matches "CE AT" or vice versa
        final spacelessAbbreviation = lowerAbbreviation.replaceAll(' ', '');
        final spacelessQuery = lowerQuery.replaceAll(' ', '');

        if (spacelessAbbreviation.contains(spacelessQuery) ||
            spacelessQuery.contains(spacelessAbbreviation)) {
          return true;
        }
      }
    }

    // Handle OfficeData
    if (item is OfficeData) {
      // Match by abbreviation (with and without spaces)
      if (item.abbreviation != null) {
        final lowerAbbreviation = item.abbreviation!.toLowerCase();

        // Direct match
        if (lowerAbbreviation.contains(lowerQuery)) {
          return true;
        }

        // Space-less match
        final spacelessAbbreviation = lowerAbbreviation.replaceAll(' ', '');
        final spacelessQuery = lowerQuery.replaceAll(' ', '');

        if (spacelessAbbreviation.contains(spacelessQuery) ||
            spacelessQuery.contains(spacelessAbbreviation)) {
          return true;
        }
      }
    }

    return false;
  }

  void _onMapMove(MapCamera camera, bool hasGesture) {
    if (!_isDisposed && mounted) {
      setState(() {
        _currentZoom = camera.zoom;
        _currentRotation = camera.rotation;
      });
    }
  }

  void _scheduleAutoNavigation() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!_isDisposed &&
          _currentLocation != null &&
          MapBuildings.isInitialized) {
        _triggerAutoNavigation();
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isDisposed && mounted) {
            _scheduleAutoNavigation();
          }
        });
      }
    });
  }

  Future<void> _triggerAutoNavigation() async {
    if (_isDisposed || !mounted) return;

    if (widget.itemType == 'marker') {
      BicolMarker? targetMarker;

      if (widget.buildingId != null) {
        try {
          targetMarker = MapBuildings.landmarks.firstWhere((m) {
            return m.buildingId == widget.buildingId;
          });
        } catch (e) {
          targetMarker = null;
        }
      }

      if (targetMarker == null && widget.buildingId != null) {
        try {
          targetMarker = MapBuildings.colleges.firstWhere((m) {
            return m.itemId == widget.buildingId;
          });
        } catch (e) {
          targetMarker = null;
        }
      }

      if (targetMarker == null && widget.destinationName != null) {
        try {
          targetMarker = MapBuildings.landmarks.firstWhere((m) {
            final match = m.name.toLowerCase().contains(
              widget.destinationName!.toLowerCase(),
            );
            return match;
          });
        } catch (e) {
          targetMarker = null;
        }

        if (targetMarker == null) {
          try {
            targetMarker = MapBuildings.colleges.firstWhere((m) {
              final match = m.name.toLowerCase().contains(
                widget.destinationName!.toLowerCase(),
              );
              return match;
            });
          } catch (e) {
            targetMarker = null;
          }
        }
      }

      if (targetMarker == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Marker "${widget.destinationName ?? 'Unknown'}" not found on map',
              ),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        _targetedBuildingId = targetMarker!.buildingId;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Getting route to ${targetMarker.displayName}...',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      await MapUtils.animateToBuildingLocation(
        _mapController,
        targetMarker.position,
        zoom: 19.5,
        duration: const Duration(milliseconds: 1000),
      );

      await _getRouteToMarkerAsync(targetMarker);

      // Just set navigation start point and hide marker
      if (_currentLocation != null &&
          MapBoundary.isWithinCampusBounds(_currentLocation!)) {
        setState(() {
          _navigationStartPoint = _currentLocation;
          _showDestinationMarker = false;
        });
      } else {
        setState(() {
          _showDestinationMarker = false;
          _animateDestinationMarker = false;
          _navigationStartPoint = null;
        });
      }

      // Just fit the route to view, no animation
      if (_navigationManager.polylinePoints.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 300));
        RoutingService.fitMapToRoute(
          _mapController,
          _navigationManager.polylinePoints,
        );
      }

      return;
    }

    // Building navigation
    BicolBuildingPolygon? targetBuilding;

    if (widget.buildingId != null) {
      try {
        targetBuilding = MapBuildings.campusBuildings.firstWhere((b) {
          return b.buildingId == widget.buildingId;
        });
      } catch (e) {
        targetBuilding = null;
      }
    }

    if (targetBuilding == null && widget.destinationName != null) {
      try {
        targetBuilding = MapBuildings.campusBuildings.firstWhere((b) {
          final match = b.name.toLowerCase().contains(
            widget.destinationName!.toLowerCase(),
          );
          return match;
        });
      } catch (e) {
        targetBuilding = null;
      }
    }

    if (targetBuilding == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Building "${widget.destinationName ?? 'Unknown'}" not found on map',
            ),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _targetedBuildingId = targetBuilding!.buildingId;
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                // ✅ WRAP IN Expanded
                child: Text(
                  'Getting route to ${targetBuilding.displayName}...',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    await MapUtils.animateToBuildingLocation(
      _mapController,
      targetBuilding.getCenterPoint(),
      zoom: 19.5,
      duration: const Duration(milliseconds: 1000),
    );

    await _showDirectionsForBuilding(targetBuilding);

    // ✅ CHANGED: Don't do Waze animation here anymore
    // Just set navigation start point and hide marker
    if (_currentLocation != null &&
        MapBoundary.isWithinCampusBounds(_currentLocation!)) {
      setState(() {
        _navigationStartPoint = _currentLocation;
        _showDestinationMarker = false; // Keep hidden until "Start Navigation"
      });
    } else {
      setState(() {
        _showDestinationMarker = false;
        _animateDestinationMarker = false;
        _navigationStartPoint = null;
      });
    }

    // ✅ CHANGED: Just fit the route to view, no animation
    if (_navigationManager.polylinePoints.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      RoutingService.fitMapToRoute(
        _mapController,
        _navigationManager.polylinePoints,
      );
    }
  }
  // In _MapsState class, replace _showDirectionsForBuilding method:

  Future<void> _showDirectionsForBuilding(BicolBuildingPolygon building) async {
    if (_isDisposed || _currentLocation == null) return;

    // ✅ NEW: Check if user is already at the building
    final bool isAlreadyHere = RoutingService.isUserAtDestination(
      _currentLocation!,
      building.getCenterPoint(),
      buildingId: building.buildingId,
      thresholdMeters: 30.0,
    );

    if (isAlreadyHere) {
      // User is already at the building
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 8,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green.shade50, Colors.white],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with icon
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Animated check icon
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.check_circle,
                                  size: 45,
                                  color: Colors.green.shade600,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'You\'re Already Here!',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Location badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.green.shade700,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  building.displayName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade900,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Message
                        Text(
                          'You\'re currently at your destination.',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Would you still like to see the route?',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Got It',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _forceShowRoute(building);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  backgroundColor: Colors.orange.shade500,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shadowColor: Colors.orange.withValues(
                                    alpha: 0.4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Show Route',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
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
                ],
              ),
            ),
          ),
        );
      }
      return;
    }

    // Normal flow - user is not at destination
    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: const Text('Getting route...')),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 30),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Try cached entrance first
      LatLng? entrance = RoutingService.getCachedEntrance(building.buildingId);

      // If not cached, fetch it with timeout
      entrance ??=
          await RoutingService.fetchBuildingEntrance(
            building.getCenterPoint(),
            building.name,
            buildingId: building.buildingId,
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Slow internet connection');
            },
          );

      final destination = entrance ?? building.getCenterPoint();
      await _getRoute(_currentLocation!, destination, building);

      // Clear loading snackbar
      if (!_isDisposed && mounted && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    } on TimeoutException {
      if (!_isDisposed && mounted && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Internet connection is slow'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _showDirectionsForBuilding(building),
            ),
          ),
        );
      }
    } on SocketException {
      if (!_isDisposed && mounted && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No internet connection'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _showDirectionsForBuilding(building),
            ),
          ),
        );
      }
    } catch (e) {
      if (!_isDisposed && mounted && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting route: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _showDirectionsForBuilding(building),
            ),
          ),
        );
      }
    }
  }

  void _setupNavigationCallbacks() {
    _navigationManager.onLocationUpdate = (location, bearing) {
      if (!_isDisposed && mounted) {
        setState(() {
          _currentLocation = location;
          _currentHeading = bearing;
        });

        // Auto-follow ONLY when navigating
        if (_navigationManager.isNavigating) {
          _followUserLocationSmooth();
        }
      }
    };
    // Handle dynamic route updates
    _navigationManager.onRouteUpdated = (newRoute) {
      if (!_isDisposed && mounted) {
        setState(() {});
      }
    };
    _navigationManager.onDestinationReached = (destination) {
      if (!_isDisposed && context.mounted) {
        _handleDestinationReached(destination);
      }
    };

    _navigationManager.onError = (error) {
      if (!_isDisposed && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    };
  }

  // Smooth camera follow during navigation
  void _followUserLocationSmooth() {
    if (_currentLocation == null || _isDisposed) return;

    // During navigation, instantly center on user location
    _mapController.move(_currentLocation!, 19.0);
  }

  void _startContinuousLocationTracking() async {
    if (_isDisposed) return;

    // Initial location
    final initialLocation = await LocationService.getCurrentLocation();
    if (initialLocation.isSuccess && mounted && !_isDisposed) {
      setState(() {
        _currentLocation = initialLocation.location;
        _currentHeading = initialLocation.heading ?? 0.0;
      });

      _navigationManager.updateLocation(
        initialLocation.location!,
        initialLocation.heading ?? 0.0,
      );
    }

    // Set up continuous updates
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen((
      Position position,
    ) {
      if (_isDisposed || !mounted) return;

      final newLocation = LatLng(position.latitude, position.longitude);
      final compassHeading = LocationService.getCurrentHeading();

      setState(() {
        _currentLocation = newLocation;
        _currentHeading = compassHeading;
      });

      _navigationManager.updateLocation(newLocation, compassHeading);

      // ✅ UPDATED: Update nearby images during virtual tour OR regular navigation
      if (MapBuildings.isInitialized &&
          (_isVirtualTourActive || _navigationManager.isNavigating)) {
        // Exclude the current destination building from showing nearby images
        Set<int> excludedIds = {};

        if (_isVirtualTourActive && _virtualTourManager.currentStop != null) {
          excludedIds.add(_virtualTourManager.currentStop!.buildingId);
        } else if (_navigationManager.isNavigating &&
            _navigationManager.currentDestination != null) {
          // Exclude regular navigation destination
          final destination = _navigationManager.currentDestination;
          if (destination.buildingId != null) {
            excludedIds.add(destination.buildingId);
          }
        }

        _nearbyImageManager.updateLocation(
          newLocation,
          MapBuildings.campusBuildings,
          [...MapBuildings.colleges, ...MapBuildings.landmarks],
          excludedBuildingIds: excludedIds,
        );
      }

      if (_autoFollowLocation && !_navigationManager.isNavigating) {
        _followUserLocation();
      }
    }, onError: (error) {});
  }

  Future<void> _startLocationTracking() async {
    if (_isDisposed) return;
    setState(() {
      _isLoadingLocation = true;
    });

    final initialLocation = await LocationService.getCurrentLocation();

    if (!initialLocation.isSuccess) {
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(initialLocation.error ?? 'Location error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    if (!_isDisposed && mounted) {
      setState(() {
        _currentLocation = initialLocation.location;
        _currentHeading = initialLocation.heading ?? 0.0;
        _isLoadingLocation = false;
      });
    }
  }

  void _toggleAutoFollow() {
    if (_isDisposed) return;
    setState(() {
      _autoFollowLocation = !_autoFollowLocation;
    });
    if (_autoFollowLocation && _currentLocation != null) {
      MapUtils.animateToLocation(_mapController, _currentLocation!);
    }
  }

  Future<void> _getRoute(
    LatLng start,
    LatLng end,
    BicolBuildingPolygon building,
  ) async {
    if (_isDisposed) return;
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final routeResult = await _navigationManager
          .getRouteAndPrepareNavigation(start, end, building)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException('Route calculation timed out');
            },
          );

      if (!_isDisposed && mounted) {
        setState(() {
          _isLoadingLocation = false;
        });

        if (routeResult.isSuccess && routeResult.points != null) {
          if (widget.buildingId != null || widget.destinationName != null) {
            RoutingService.fitMapToRoute(_mapController, routeResult.points!);
          }
          _showRouteInfo(building);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(routeResult.error ?? 'Failed to get route'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'RETRY',
                  textColor: Colors.white,
                  onPressed: () => _getRoute(start, end, building),
                ),
              ),
            );
          }
        }
      }
    } on TimeoutException {
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Internet connection is slow'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                onPressed: () => _getRoute(start, end, building),
              ),
            ),
          );
        }
      }
    } on SocketException {
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No internet connection'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                onPressed: () => _getRoute(start, end, building),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                onPressed: () => _getRoute(start, end, building),
              ),
            ),
          );
        }
      }
    }
  }

  void _showRouteInfo(BicolBuildingPolygon building) {
    if (_isDisposed || !context.mounted) return;
    if (_navigationManager.routeDistance != null &&
        _navigationManager.routeDuration != null) {
      BottomSheets.showRouteInfo(
        context,
        buildingName: building.displayName,
        distance: _navigationManager.routeDistance!,
        duration: _navigationManager.routeDuration!,
        onClearRoute: _clearRoute,
        onStartNavigation: () => _startNavigation(building),
      );
    }
  }

  Future<void> _forceShowRoute(BicolBuildingPolygon building) async {
    if (_isDisposed || _currentLocation == null) return;

    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Getting route...'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 30),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      LatLng? entrance = RoutingService.getCachedEntrance(building.buildingId);

      entrance ??=
          await RoutingService.fetchBuildingEntrance(
            building.getCenterPoint(),
            building.name,
            buildingId: building.buildingId,
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Slow internet connection');
            },
          );

      final destination = entrance ?? building.getCenterPoint();
      await _getRoute(_currentLocation!, destination, building);

      if (!_isDisposed && mounted && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    } catch (e) {
      if (!_isDisposed && mounted && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _startNavigation(BicolBuildingPolygon building) async {
    if (_isDisposed || !context.mounted) return;
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current location not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user is within campus for Waze animation
    final bool isInsideCampus = MapBoundary.isWithinCampusBounds(
      _currentLocation!,
    );

    // Store starting point if user is within campus
    if (_navigationStartPoint == null && isInsideCampus) {
      setState(() {
        _navigationStartPoint = _currentLocation;
      });
    }

    // Handle marker visibility - hide destination marker during animation
    if (_isMarkerType && building.buildingId != null) {
      setState(() {
        _selectedMarkerId = null;
        _hiddenMarkerId = building.buildingId;
        _isNavigatingToMarker = false;
        _showDestinationMarker = false;
        _animateDestinationMarker = false;
      });
    } else {
      setState(() {
        _showDestinationMarker = false;
        _animateDestinationMarker = false;
      });
    }

    // Initialize nearby images for regular navigation
    if (isInsideCampus && MapBuildings.isInitialized) {
      // Exclude the destination building from showing nearby images
      Set<int> excludedIds = {};
      if (building.buildingId != null) {
        excludedIds.add(building.buildingId!);
      }

      await _nearbyImageManager.updateLocation(
        _currentLocation!,
        MapBuildings.campusBuildings,
        [...MapBuildings.colleges, ...MapBuildings.landmarks],
        excludedBuildingIds: excludedIds,
      );
    }

    // If inside campus, do Waze-style animation BEFORE starting navigation
    if (isInsideCampus && _navigationManager.polylinePoints.isNotEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Preparing navigation...'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Clear any animated route points first
      setState(() {
        _animatedRoutePoints = [];
      });

      // ✅ NEW: Do Waze animation WITH nearby images
      await MapUtils.animateAlongRouteWithCamera(
        _mapController,
        _navigationManager.polylinePoints,
        onRouteUpdate: (visibleRoute) {
          if (mounted && !_isDisposed) {
            setState(() {
              _animatedRoutePoints = visibleRoute;
            });

            // ✅ NEW: Update nearby images as route animates
            _updateNearbyImagesForNavigation(building.buildingId);
          }
        },
      );

      // After animation completes, move camera back to user location
      if (mounted && !_isDisposed && _currentLocation != null) {
        await MapUtils.animateToBuildingLocation(
          _mapController,
          _currentLocation!,
          zoom: 19.0,
          duration: const Duration(milliseconds: 800),
        );

        // Clear animated route points - show full route now
        setState(() {
          _animatedRoutePoints = [];
        });
      }

      if (!_isDisposed && mounted && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    }

    // NOW show the destination marker with animation
    if (mounted && !_isDisposed) {
      setState(() {
        _showDestinationMarker = true;
        _animateDestinationMarker = true;
        _autoFollowLocation = true;
      });
    }

    // Start actual navigation
    await _navigationManager.startNavigation(
      destination: building,
      routePoints: _navigationManager.polylinePoints,
      distance: _navigationManager.routeDistance,
      duration: _navigationManager.routeDuration,
      onRouteUpdated: (newRoute) {
        if (mounted && !_isDisposed) {
          setState(() {});
        }
      },
    );
  }

  void _clearRoute() {
    if (_isDisposed) return;

    _navigationManager.clearRoute();
    _nearbyImageManager.clear();

    setState(() {
      _animatedRoutePoints = [];
      _autoFollowLocation = false;
      _showDestinationMarker = false;
      _animateDestinationMarker = false;
      _navigationStartPoint = null;
      _targetedBuildingId = null;
      _hiddenMarkerId = null;
      _selectedMarkerId = null;
      _isMarkerType = false;
      _isNavigatingToMarker = false;
      _isCollegeMarker = false;
    });

    _centerOnCampus();
  }

  void _stopNavigation() {
    if (_isDisposed) return;

    _navigationManager.stopNavigation();
    _nearbyImageManager.clear();

    setState(() {
      _animatedRoutePoints = [];
      _autoFollowLocation = false;
      _showDestinationMarker = false;
      _animateDestinationMarker = false;
      _navigationStartPoint = null;
      _targetedBuildingId = null;
      _hiddenMarkerId = null;
      _selectedMarkerId = null;
      _isMarkerType = false;
      _isNavigatingToMarker = false;
      _isCollegeMarker = false;
    });

    _centerOnCampus();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigation Stopped'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleDestinationReached(dynamic destination) {
    if (_isDisposed || !context.mounted) return;
    setState(() {
      _autoFollowLocation = false;
    });

    String destinationName = 'your destination';
    if (destination is BicolBuildingPolygon) {
      destinationName = destination.displayName;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.place, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('You have arrived at $destinationName!')),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!_isDisposed) {
        _clearRoute();
      }
    });
  }

  Future<void> _loadMapDataWithRetry() async {
    if (_isDisposed) return;

    setState(() {
      _isLoadingMapData = true;
      _mapDataLoadFailed = false;
      _mapDataError = null;
    });

    int delaySeconds = 0;
    if (_retryAttempts > 0) {
      delaySeconds = (2 * (_retryAttempts)).clamp(2, 10);

      debugPrint(
        '⏳ Waiting ${delaySeconds}s before retry (attempt ${_retryAttempts + 1})...',
      );

      for (int i = delaySeconds; i > 0; i--) {
        if (_isDisposed) return;
        setState(() {
          _mapDataError = 'Retrying in ${i}s...';
        });
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    try {
      await MapBuildings.initializeWithBoundary(
        campusBoundaryPoints: MapBoundary.getCampusBoundaryPoints(),
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw TimeoutException('Map loading timed out after 45 seconds');
        },
      );

      final hasBuildings = MapBuildings.campusBuildings.isNotEmpty;
      final hasMarkers = MapBuildings.campusMarkers.isNotEmpty;
      final isInitialized = MapBuildings.isInitialized;

      if (!isInitialized) {
        throw Exception('Map initialization incomplete');
      }

      if (!hasBuildings && !hasMarkers) {
        throw Exception('No map data received from server');
      }

      // Preload building entrances after map data loads
      if (hasBuildings) {
        debugPrint('🔄 Preloading building entrances...');
        // Don't await - let it run in background
        RoutingService.preloadBuildingEntrances(MapBuildings.campusBuildings);
      }

      if (mounted && !_isDisposed) {
        setState(() {
          _isLoadingMapData = false;
          _mapDataLoadFailed = false;
          _retryAttempts = 0;
          _mapDataError = null;
        });

        ScaffoldMessenger.of(context).clearSnackBars();
      }
    } on TimeoutException catch (e) {
      _handleMapLoadError('Connection timed out', isTimeout: true);
      debugPrint('⏱️ Timeout: $e');
    } on SocketException catch (e) {
      _handleMapLoadError('No internet connection', isNetworkError: true);
      debugPrint('📡 Network error: $e');
    } catch (e) {
      final errorMessage = e.toString();
      final isRateLimited = errorMessage.contains('429');

      if (isRateLimited) {
        _handleMapLoadError(
          'Server busy - too many requests',
          isRateLimited: true,
        );
        debugPrint('🚫 Rate limit hit (429): $e');
      } else {
        _handleMapLoadError(errorMessage);
        debugPrint('❌ Error: $e');
      }
    }
  }

  void _handleMapLoadError(
    String errorMessage, {
    bool isTimeout = false,
    bool isNetworkError = false,
    bool isRateLimited = false,
  }) {
    if (!mounted || _isDisposed) return;

    setState(() {
      _isLoadingMapData = false;
      _mapDataLoadFailed = true;
      _retryAttempts++;

      // User-friendly error messages
      if (isRateLimited) {
        _mapDataError = 'Server is busy. Please wait...';
      } else if (isTimeout) {
        _mapDataError = 'Connection timed out';
      } else if (isNetworkError) {
        _mapDataError = 'No internet connection';
      } else if (errorMessage.contains('initialization')) {
        _mapDataError = 'Map initialization failed';
      } else if (errorMessage.contains('No map data')) {
        _mapDataError = 'No data received';
      } else {
        _mapDataError = 'Could not load map';
      }
    });
  }

  Widget _buildPinMarker(
    BicolMarker marker,
    double currentZoom,
    double currentRotation,
  ) {
    IconData icon;
    Color color;

    if (marker.isCollege) {
      icon = Icons.school;
      color = Colors.blue;
    } else if (marker.isLandmark) {
      icon = Icons.circle;
      color = Colors.red;
    } else {
      icon = Icons.location_on;
      color = Colors.blue;
    }

    final displayText = marker.isCollege && marker.abbreviation != null
        ? marker.abbreviation!
        : marker.name;

    final markerType = marker.isCollege ? 'college' : 'landmark';

    final markerWidget = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 🔄 CHANGED: Make landmark icons circular like DestinationEndMarker
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle, // ✅ Changed to circle for all markers
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: Icon(icon, color: Colors.white, size: 18)),
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              displayText,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );

    return MapUtils.wrapMarkerWithAnimation(
      markerWidget: markerWidget,
      currentZoom: currentZoom,
      markerType: markerType,
    );
  }

  void _showMarkerInfo(BicolMarker marker) {
    if (_isDisposed || !context.mounted) return;

    setState(() {
      _isCollegeMarker = marker.isCollege;
      _isMarkerType = true;
      _selectedMarkerId = marker.isCollege
          ? marker.itemId
          : marker.buildingId; // ⭐ ADD THIS
    });

    final markerAsBuilding = BicolBuildingPolygon(
      points: [marker.position],
      name: marker.name,
      description: marker.isCollege ? 'College' : 'Landmark',
      buildingId: marker.isCollege ? marker.itemId : marker.buildingId,
      databaseName: marker.databaseName,
    );

    BottomSheets.showBuildingInfo(
      context,
      markerAsBuilding,
      onDirections: () => _showDirections(markerAsBuilding),
      isCollege: marker.isCollege,
      isLandmark: marker.isLandmark,
    );
  }

  Future<void> _getRouteToMarkerAsync(BicolMarker marker) async {
    if (_isDisposed || _currentLocation == null) return;

    try {
      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Getting route...'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 30),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final tempBuilding = BicolBuildingPolygon(
        points: [marker.position],
        name: marker.name,
        description: marker.isCollege ? 'College' : 'Landmark',
        buildingId: marker.buildingId,
        databaseName: marker.databaseName,
      );

      // ⭐ ADD THIS - Mark this as a marker type navigation
      setState(() {
        _isMarkerType = true;
      });

      await _getRoute(_currentLocation!, marker.position, tempBuilding);

      // Clear loading
      if (!_isDisposed && mounted && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    } on TimeoutException {
      if (!_isDisposed && mounted && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Internet connection is slow'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _getRouteToMarkerAsync(marker),
            ),
          ),
        );
      }
    } on SocketException {
      if (!_isDisposed && mounted && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No internet connection'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _getRouteToMarkerAsync(marker),
            ),
          ),
        );
      }
    } catch (e) {
      if (!_isDisposed && mounted && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _getRouteToMarkerAsync(marker),
            ),
          ),
        );
      }
    }
  }

  void _setupVirtualTourCallbacks() {
    _virtualTourManager.addListener(() {
      if (mounted && !_isDisposed) {
        setState(() {
          _isVirtualTourActive = _virtualTourManager.isActive;
        });
      }
    });
  }

  void _scheduleVirtualTourStart() {
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!_isDisposed &&
          _currentLocation != null &&
          MapBuildings.isInitialized) {
        _initializeVirtualTour();
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isDisposed && mounted) {
            _scheduleVirtualTourStart();
          }
        });
      }
    });
  }

  Future<void> _initializeVirtualTour() async {
    if (_isDisposed || widget.tourStops == null || widget.tourStops!.isEmpty) {
      return;
    }

    List<VirtualTourStop> resolvedStops = [];

    for (var stop in widget.tourStops!) {
      // Try to find as marker first
      final marker = MapBuildings.landmarks.firstWhere(
        (m) => m.buildingId == stop.buildingId,
        orElse: () => MapBuildings.landmarks.first,
      );

      if (marker.buildingId == stop.buildingId) {
        stop.setLocation(marker.position, isMarkerType: true);
        resolvedStops.add(stop);
        continue;
      }

      // Find as building
      try {
        final building = MapBuildings.campusBuildings.firstWhere(
          (b) => b.buildingId == stop.buildingId,
        );

        stop.setLocation(building.getCenterPoint(), isMarkerType: false);

        // Use preloaded entrance from cache
        final entrance = RoutingService.getCachedEntrance(building.buildingId);

        if (entrance != null) {
          stop.setEntranceLocation(entrance);
        }

        resolvedStops.add(stop);
      } catch (e) {
        debugPrint('❌ Building ${stop.buildingId} not found');
        continue;
      }
    }

    if (resolvedStops.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to start tour - no valid locations found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Determine starting point based on user choice
    LatLng startingPoint;
    int targetStopIndex = widget.skipToStopIndex ?? 0;

    // ✅ FIXED: Check for selected gate FIRST and don't override it
    if (widget.selectedStartGate != null) {
      // ✅ User explicitly chose this gate - use it WITHOUT recalculation
      startingPoint = widget.selectedStartGate!.location;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.door_sliding, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Starting tour from ${widget.selectedStartGate!.name}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (widget.useCurrentLocationAsStart &&
        _currentLocation != null &&
        MapBoundary.isWithinCampusBounds(_currentLocation!)) {
      // ✅ Use current location as starting point
      startingPoint = _currentLocation!;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.my_location, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Starting tour from your current location'),
              ],
            ),
            backgroundColor: Colors.blue[700],
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // ✅ ONLY calculate optimal gate if no gate was selected
      final gates = await RoutingService.getAllGates();

      CampusGate? optimalGate;
      if (gates.isNotEmpty) {
        optimalGate = await RoutingService.findOptimalGate(
          startPoint: _currentLocation ?? MapBoundary.bicolUniversityCenter,
          destinationPoint: resolvedStops[targetStopIndex].navigationTarget,
          gates: gates,
        );
      }

      startingPoint =
          optimalGate?.location ?? MapBoundary.bicolUniversityCenter;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.door_sliding, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    optimalGate != null
                        ? 'Starting tour from ${optimalGate.name} (optimal route)'
                        : 'Starting tour from campus entrance',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    // ✅ Start the tour with the correct starting point
    _virtualTourManager.startTour(
      tourName: widget.tourName ?? 'Campus Tour',
      stops: resolvedStops,
      startingGate:
          startingPoint, // This is now guaranteed to be the selected gate
      startAtIndex: targetStopIndex,
    );

    if (widget.audioGuideEnabled) {
      _virtualTourManager.enableAudioGuide();
    } else {
      _virtualTourManager.disableAudioGuide();
    }

    setState(() {
      _isVirtualTourActive = true;
      _tourStartPoint = startingPoint;
    });

    // Show appropriate message for skipped stops
    if (!mounted) return;

    if (targetStopIndex > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.tour, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Skipping to Stop ${targetStopIndex + 1} - ${resolvedStops[targetStopIndex].displayName}',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.tour, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Starting ${widget.tourName} - ${resolvedStops.length} stops',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Initialize nearby images with exclusion
    Set<int> excludedIds = {};
    if (_virtualTourManager.currentStop != null) {
      excludedIds.add(_virtualTourManager.currentStop!.buildingId);
    }

    if (_currentLocation != null) {
      await _nearbyImageManager.updateLocation(
        _currentLocation!,
        MapBuildings.campusBuildings,
        [...MapBuildings.colleges, ...MapBuildings.landmarks],
        excludedBuildingIds: excludedIds,
      );
    }

    _navigateToCurrentVirtualTourStop();
  }

  Future<void> _navigateToCurrentVirtualTourStop({LatLng? fromLocation}) async {
    if (_isDisposed || !_virtualTourManager.isActive) return;

    final currentStop = _virtualTourManager.currentStop;
    if (currentStop == null || currentStop.location == null) return;

    setState(() {
      _targetedBuildingId = currentStop.buildingId;
    });

    try {
      _virtualTourManager.beginAnimationToStop();
      _nearbyImageManager.clear();

      LatLng startPoint;

      // ✅ FIXED: Determine starting point with proper priority
      if (fromLocation != null) {
        // Explicit fromLocation passed - use it (for next/previous navigation)
        startPoint = fromLocation;
        debugPrint('🔄 Using provided fromLocation: $fromLocation');
      } else if (_tourStartPoint != null) {
        // ✅ CRITICAL FIX: Use the tour start point (selected gate or starting location)
        // This was set in _initializeVirtualTour and should be used for first stop
        startPoint = _tourStartPoint!;
        debugPrint(
          '🎯 Using tour start point (selected gate): $_tourStartPoint',
        );
      } else if (_currentLocation != null &&
          MapBoundary.isWithinCampusBounds(_currentLocation!)) {
        // User is on campus - start from current location
        startPoint = _currentLocation!;
        debugPrint('📍 Using current location: $_currentLocation');
      } else {
        // Fallback: User is off campus and no tour start point - find nearest gate
        final gates = await RoutingService.fetchCampusGates(
          campusCenter: MapBoundary.bicolUniversityCenter,
          radiusMeters: 600,
        );

        CampusGate? nearestGate;
        if (gates.isNotEmpty) {
          final targetBuilding = currentStop.navigationTarget;
          double minDistance = double.infinity;

          for (var gate in gates) {
            final distance = RoutingService.calculateDistance(
              targetBuilding,
              gate.location,
            );
            if (distance < minDistance) {
              minDistance = distance;
              nearestGate = gate;
            }
          }
        }

        startPoint = nearestGate?.location ?? MapBoundary.bicolUniversityCenter;
        debugPrint('🚪 Fallback to nearest gate: ${nearestGate?.name}');
      }

      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Navigating to ${currentStop.buildingName}...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 30),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final routeResult =
          await RoutingService.getRoute(
            startPoint,
            currentStop.navigationTarget,
          ).timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException('Route calculation timed out');
            },
          );

      // Clear loading
      if (!_isDisposed && mounted && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (routeResult.isSuccess && routeResult.points != null) {
        setState(() {
          _navigationManager.clearRoute();
          _animatedRoutePoints = [];
        });

        await MapUtils.animateAlongRouteWithCamera(
          _mapController,
          routeResult.points!,
          onRouteUpdate: (visibleRoute) {
            if (mounted && !_isDisposed) {
              setState(() {
                _animatedRoutePoints = visibleRoute;
              });
              _updateNearbyImagesForRoute();
            }
          },
        );

        setState(() {
          _animatedRoutePoints = routeResult.points!;
          _navigationManager.polylinePoints.clear();
          _navigationManager.polylinePoints.addAll(routeResult.points!);
        });

        _updateNearbyImagesForRoute();
        _virtualTourManager.completeAnimationToStop();
        _showVirtualTourStopCard();
      } else {
        throw Exception(routeResult.error ?? 'Failed to get route');
      }
    } on TimeoutException {
      if (!_isDisposed && mounted && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Internet connection is slow'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () =>
                  _navigateToCurrentVirtualTourStop(fromLocation: fromLocation),
            ),
          ),
        );
      }
    } on SocketException {
      if (!_isDisposed && mounted && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No internet connection'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () =>
                  _navigateToCurrentVirtualTourStop(fromLocation: fromLocation),
            ),
          ),
        );
      }
    } catch (e) {
      if (!_isDisposed && mounted && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () =>
                  _navigateToCurrentVirtualTourStop(fromLocation: fromLocation),
            ),
          ),
        );
      }
    }
  }

  void _showVirtualTourStopCard() {
    if (_isDisposed) return;

    setState(() {});
  }

  void _endVirtualTour() {
    if (_isDisposed || !context.mounted) return;

    final tourName = _virtualTourManager.tourName;
    final stopsVisited = _virtualTourManager.currentStopIndex + 1;
    final completedAll = _virtualTourManager.isLastStop;

    _virtualTourManager.endTour();
    _navigationManager.clearRoute();
    _nearbyImageManager.clear();

    setState(() {
      _isVirtualTourActive = false;
      _animatedRoutePoints = [];
      _tourStartPoint = null;
      _targetedBuildingId = null;
    });
    if (completedAll) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => TourCompletionDialog(
          tourName: tourName,
          stopsVisited: stopsVisited,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Virtual tour ended - visited $stopsVisited stops'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: MapBoundary.bicolUniversityCenter,
              initialZoom: MapBoundary.getInitialZoom(),
              minZoom: MapBoundary.getMinZoom(),
              maxZoom: MapBoundary.getMaxZoom(),
              cameraConstraint: _isVirtualTourActive
                  ? MapBoundary.getFlexibleCameraConstraint()
                  : MapBoundary.getCameraConstraint(),
              onPositionChanged: (camera, hasGesture) {
                _onMapMove(camera, hasGesture);
              },
              onTap: (tapPosition, latLng) {
                _handleMapTapAtLatLng(latLng);
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              MapUtils.getTileLayer(_currentTileType),

              // Boundary polygon
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: MapBoundary.getCampusBoundaryPoints(),
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderColor: Colors.blue.withValues(alpha: 0.8),
                    borderStrokeWidth: 3,
                  ),
                ],
              ),
              // Campus gate markers
              if (_showGates)
                FutureBuilder<List<CampusGate>>(
                  future: RoutingService.fetchCampusGates(
                    campusCenter: MapBoundary.bicolUniversityCenter,
                    radiusMeters: 600,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();

                    return MarkerLayer(
                      markers: snapshot.data!.map((gate) {
                        return Marker(
                          point: gate.location,
                          width: 36,
                          height: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.green[500]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.door_sliding,
                              color: Colors.green[700],
                              size: 18,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

              // Building polygons
              PolygonLayer(
                polygons: MapBuildings.campusBuildings
                    .where(
                      (building) => MapBoundary.isWithinCampusBounds(
                        building.getCenterPoint(),
                      ),
                    )
                    .map((building) {
                      // Make sure BOTH the building has an ID AND it matches the target
                      final bool isTargeted =
                          building.buildingId != null &&
                          building.buildingId == _targetedBuildingId;

                      // DIFFERENT COLORS FOR TARGETED VS NORMAL BUILDINGS
                      final polygonColor = isTargeted
                          ? Colors.deepOrange.withValues(
                              alpha: 0.5,
                            ) // Darker orange-red for targeted
                          : Colors.orange.withValues(
                              alpha: 0.3,
                            ); // Normal orange

                      final borderColor = isTargeted
                          ? Colors
                                .deepOrange
                                .shade700 // Darker border for targeted
                          : Colors.orange; // Normal border

                      final borderWidth = isTargeted
                          ? 3.0
                          : 2.0; // Thicker border for targeted

                      return Polygon(
                        points: building.points,
                        color: polygonColor,
                        borderColor: borderColor,
                        borderStrokeWidth: borderWidth,
                      );
                    })
                    .toList(),
              ),

              // Route polyline (animated or regular)
              if (_isVirtualTourActive && _animatedRoutePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _animatedRoutePoints,
                      color: const Color(0xFFD84315), // Dark red-orange
                      strokeWidth: 5.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                )
              else if (_animatedRoutePoints.isNotEmpty && !_isVirtualTourActive)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _animatedRoutePoints,
                      color: const Color(0xFFD84315),
                      strokeWidth: 5.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                )
              else if (_navigationManager.polylinePoints.isNotEmpty &&
                  !_isVirtualTourActive)
                PolylineLayer(
                  polylines: [
                    RouteHelper.createRoutePolyline(
                      _navigationManager.polylinePoints,
                    ),
                  ],
                ),
              // Start point marker (where navigation began)
              if (_navigationStartPoint != null &&
                  _navigationManager.isNavigating)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _navigationStartPoint!,
                      width: 40,
                      height: 50,
                      alignment: Alignment.bottomCenter,
                      child: const StartPointMarker(),
                    ),
                  ],
                ),

              // Destination marker - handles BOTH buildings and map markers
              if (_showDestinationMarker &&
                  _navigationManager.currentDestination != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _navigationManager.currentDestination
                          .getCenterPoint(),
                      width: 50,
                      height: 60,
                      alignment: Alignment.bottomCenter,
                      child: DestinationEndMarker(
                        animate: _animateDestinationMarker,
                        // ✅ These parameters don't matter anymore since we use unified style
                        isMapMarker: _isMarkerType,
                        isCollege: _isCollegeMarker,
                      ),
                    ),
                  ],
                ),
              // Nearby image popups during virtual tour OR regular navigation
              if (_isVirtualTourActive || _navigationManager.isNavigating)
                MarkerLayer(
                  markers: _nearbyImageManager.nearbyImages.values.map((
                    imageData,
                  ) {
                    return Marker(
                      point: imageData.location,
                      width: 80,
                      height: 110,
                      alignment: Alignment.topCenter,
                      child: NearbyImagePopup(
                        imageData: imageData,
                        onTap: () {
                          ImageFullScreenViewer.show(
                            context,
                            imageData.imageUrl,
                            imageData.name,
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),

              // User location marker
              if (_currentLocation != null &&
                  MapBoundary.isWithinCampusBounds(_currentLocation!))
                MarkerLayer(
                  markers: [
                    _navigationManager.isNavigating
                        ? MapUtils.createNavigationMarker(
                            _currentLocation!,
                            _navigationManager.currentBearing,
                            compassHeading: _currentHeading,
                          )
                        : MapUtils.createUserLocationMarker(
                            _currentLocation!,
                            heading: _currentHeading,
                          ),
                  ],
                ),

              // Tour start marker
              if (_isVirtualTourActive && _tourStartPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _tourStartPoint!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              spreadRadius: 2,
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.flag,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

              if (_isVirtualTourActive &&
                  _virtualTourManager.currentStop != null &&
                  _virtualTourManager.currentStop!.location != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _virtualTourManager.currentStop!.navigationTarget,
                      width: 50,
                      height: 50,
                      child: PulsingDestinationMarker(
                        stopNumber: _virtualTourManager.currentStop!.stopNumber,
                      ),
                    ),
                  ],
                ),
              // College markers
              if (MapUtils.shouldShowColleges(_currentZoom) && _showColleges)
                MarkerLayer(
                  markers: MapBuildings.colleges
                      .where(
                        (marker) =>
                            MapBoundary.isWithinCampusBounds(marker.position) &&
                            marker.itemId != _hiddenMarkerId &&
                            marker.itemId != _selectedMarkerId,
                      )
                      .map((marker) {
                        return Marker(
                          point: marker.position,
                          width: 150,
                          height: 40,
                          alignment: Alignment.center,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              await MapUtils.animateToBuildingLocation(
                                _mapController,
                                marker.position,
                                zoom: 19.5,
                                duration: const Duration(milliseconds: 600),
                              );
                              if (mounted && context.mounted) {
                                _showMarkerInfo(marker);
                              }
                            },
                            child: _buildPinMarker(
                              marker,
                              _currentZoom,
                              _currentRotation,
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              // Landmark markers
              if (MapUtils.shouldShowLandmarks(_currentZoom) && _showLandmarks)
                MarkerLayer(
                  markers: MapBuildings.landmarks
                      .where(
                        (marker) =>
                            MapBoundary.isWithinCampusBounds(marker.position) &&
                            marker.buildingId != _hiddenMarkerId &&
                            marker.buildingId != _selectedMarkerId,
                      )
                      .map((marker) {
                        return Marker(
                          point: marker.position,
                          width: 150,
                          height: 40,
                          alignment: Alignment.center,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              await MapUtils.animateToBuildingLocation(
                                _mapController,
                                marker.position,
                                zoom: 19.5,
                                duration: const Duration(milliseconds: 1000),
                              );
                              if (mounted && context.mounted) {
                                _showMarkerInfo(marker);
                              }
                            },
                            child: _buildPinMarker(
                              marker,
                              _currentZoom,
                              _currentRotation,
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              if (_selectedMarkerId != null && !_isNavigatingToMarker)
                MarkerLayer(
                  markers: [
                    // Find the selected marker
                    ...MapBuildings.colleges
                        .where((m) => m.itemId == _selectedMarkerId)
                        .map(
                          (marker) => Marker(
                            point: marker.position,
                            width: 200,
                            height: 50,
                            alignment: Alignment.center,
                            child: SelectedMarkerWithLabel(
                              // <-- Line 2331
                              isCollege: true,
                              markerName: marker.abbreviation ?? marker.name,
                            ),
                          ),
                        ),
                    ...MapBuildings.landmarks
                        .where((m) => m.buildingId == _selectedMarkerId)
                        .map(
                          (marker) => Marker(
                            point: marker.position,
                            width: 200,
                            height: 50,
                            alignment: Alignment.center,
                            child: SelectedMarkerWithLabel(
                              isCollege: false,
                              markerName: marker.name,
                            ),
                          ),
                        ),
                  ],
                ),
            ],
          ),
          if (_isLoadingMapData)
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 120,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Loading map content...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (_retryAttempts > 0)
                            Text(
                              'Attempt ${_retryAttempts + 1} of $maxRetryAttempts',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error bar with retry button
          if (_mapDataLoadFailed && !_isLoadingMapData)
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 120,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _mapDataError?.contains('timeout') ?? false
                          ? Icons.hourglass_empty
                          : _mapDataError?.contains('internet') ?? false
                          ? Icons.wifi_off
                          : Icons.cloud_off,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Map content not loaded',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _retryAttempts >= maxRetryAttempts
                                ? 'Check your connection'
                                : _mapDataError?.contains('timeout') ?? false
                                ? 'Connection timed out'
                                : 'Could not load buildings',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        _loadMapDataWithRetry();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red[700],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'RETRY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // UI Overlays
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school, color: Colors.blue[700], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Bicol University West Campus',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 51,
            left: 16,
            right: 16,
            child: MapWidgets.buildSearchBar(
              controller: _searchController,
              onChanged: (value) {
                if (!_isDisposed) {
                  setState(() {
                    _showSearchResults = value.isNotEmpty;
                  });
                }
              },
              onClear: () {
                _searchController.clear();
                if (!_isDisposed) {
                  setState(() {
                    _showSearchResults = false;
                  });
                }
              },
            ),
          ),

          // Zoom and location controls
          Positioned(
            right: 16,
            bottom: 100,
            child: IgnorePointer(
              ignoring: false,
              child: Column(
                children: [
                  if (_isVirtualTourActive)
                    AudioGuideButton(
                      isEnabled: _virtualTourManager.isAudioGuideEnabled,
                      isSpeaking: _virtualTourManager.isAudioGuideSpeaking,
                      onToggle: () {
                        setState(() {
                          _virtualTourManager.toggleAudioGuide();
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  _virtualTourManager.isAudioGuideEnabled
                                      ? Icons.volume_up
                                      : Icons.volume_off,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  _virtualTourManager.isAudioGuideEnabled
                                      ? 'Audio Guide Enabled'
                                      : 'Audio Guide Disabled',
                                ),
                              ],
                            ),
                            backgroundColor:
                                _virtualTourManager.isAudioGuideEnabled
                                ? Colors.green
                                : Colors.grey,
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 12),
                  MapWidgets.buildFilterButton(
                    onPressed: () => _showFilterModal(),
                  ),
                  const SizedBox(height: 12),
                  // Map tile switcher button
                  MapWidgets.buildMapTileButton(
                    context: context,
                    currentTileType: _currentTileType,
                    onTileTypeChanged: _onTileTypeChanged,
                  ),
                  const SizedBox(height: 12),
                  MapWidgets.buildInfoButton(
                    onPressed: () {
                      MapWidgets.showMapGuideModal(context, isFirstTime: false);
                    },
                  ),
                  const SizedBox(height: 12),
                  //  Location Permission Toggle
                  MapWidgets.buildLocationToggle(
                    onPermissionChanged: () {
                      // Refresh location when permission changes
                      _startLocationTracking();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Existing auto-follow button
                  MapWidgets.buildFloatingActionButton(
                    icon: _autoFollowLocation
                        ? Icons.my_location
                        : Icons.location_searching,
                    onPressed: _toggleAutoFollow,
                    backgroundColor: Colors.white,
                    iconColor: _autoFollowLocation
                        ? Colors.blue
                        : Colors.grey[600],
                  ),
                  const SizedBox(height: 12),

                  // zoom controls
                  MapWidgets.buildZoomControls(
                    onZoomIn: _zoomIn,
                    onZoomOut: _zoomOut,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: MapWidgets.buildMapLegend(
                showColleges: _showColleges,
                showLandmarks: _showLandmarks,
                showGates: _showGates,
              ),
            ),
          ),
          // Search results
          if (_showSearchResults)
            Positioned(
              top: MediaQuery.of(context).padding.top + 115,
              left: 16,
              right: 16,
              child: MapWidgets.buildSearchResults(
                results: MapBuildings.searchAll(_searchController.text)
                    .where(
                      (item) =>
                          _enhancedSearchMatch(item, _searchController.text),
                    )
                    .toList(),
                onResultTap: (result) async {
                  if (_isDisposed) return;
                  _searchController.clear();
                  setState(() {
                    _showSearchResults = false;
                  });

                  if (result is BicolBuildingPolygon) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Navigating to ${result.displayName}...',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.blue,
                          duration: const Duration(milliseconds: 800),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }

                    await MapUtils.animateToBuildingLocation(
                      _mapController,
                      result.getCenterPoint(),
                      zoom: 19.5,
                      duration: const Duration(milliseconds: 1200),
                    );

                    if (mounted && context.mounted) {
                      BottomSheets.showBuildingInfo(
                        context,
                        result,
                        onVirtualTour: () => _startVirtualTour(result),
                        onDirections: () => _showDirections(result),
                      );
                    }
                  } else if (result is BicolMarker) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Navigating to ${result.displayName}...',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.blue,
                          duration: const Duration(milliseconds: 800),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    await MapUtils.animateToBuildingLocation(
                      _mapController,
                      result.position,
                      zoom: 19.5,
                      duration: const Duration(milliseconds: 1200),
                    );

                    if (mounted && context.mounted) {
                      _showMarkerInfo(result);
                    }
                  } else if (result is OfficeData) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Finding ${result.name}...',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(milliseconds: 800),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }

                    try {
                      final building = MapBuildings.campusBuildings.firstWhere(
                        (b) => b.buildingId == result.buildingId,
                      );

                      await MapUtils.animateToBuildingLocation(
                        _mapController,
                        building.getCenterPoint(),
                        zoom: 19.5,
                        duration: const Duration(milliseconds: 1200),
                      );

                      if (mounted && context.mounted) {
                        // Get building name
                        final buildingName =
                            BuildingMatcher.getBuildingNameById(
                              result.buildingId,
                            ) ??
                            building.displayName;

                        // Show office info bottom sheet
                        BottomSheets.showOfficeInfo(
                          context,
                          result,
                          buildingName: buildingName,
                          onViewDetails: () {
                            Navigator.pop(context); // Close bottom sheet
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OfficeDetailsPage(
                                  officeId: result.id,
                                  officeName: result.name,
                                  title: result.name,
                                ),
                              ),
                            );
                          },
                          onDirections: () {
                            Navigator.pop(context); // Close bottom sheet
                            _showDirections(building);
                          },
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not find building for ${result.name}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ),

          // Navigation status bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_navigationManager.polylinePoints.isNotEmpty &&
                    !_isLoadingLocation &&
                    _navigationManager.currentDestination != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: _navigationManager.isNavigating
                          ? Colors.green
                          : Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // ✅ FIXED: Wrap entire left section in Expanded
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Navigation text
                              if (_navigationManager.isNavigating)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.navigation,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Navigating to ${_navigationManager.currentDestination.displayName}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  'Route to ${_navigationManager.currentDestination.displayName}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (_navigationManager.routeDistance != null &&
                                  _navigationManager.routeDuration != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${_navigationManager.routeDistance} • ${_navigationManager.routeDuration}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ✅ FIXED: Icons side with fixed width
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_navigationManager.isNavigating)
                              GestureDetector(
                                onTap: _stopNavigation,
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.stop,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            GestureDetector(
                              onTap: () {
                                if (!_isDisposed) {
                                  _showRouteInfo(
                                    _navigationManager.currentDestination,
                                  );
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_isVirtualTourActive &&
              _virtualTourManager.isShowingStopCard &&
              _virtualTourManager.currentStop != null)
            VirtualTourStopCard(
              stop: _virtualTourManager.currentStop!,
              totalStops: _virtualTourManager.totalStops,
              isFirstStop: _virtualTourManager.isFirstStop,
              isLastStop: _virtualTourManager.isLastStop,
              onNext: () {
                _nearbyImageManager.clear();

                // Get current stop's location BEFORE moving to next
                final currentStopLocation =
                    _virtualTourManager.currentStop?.navigationTarget;

                _virtualTourManager.nextStop();

                // Pass current stop's location as starting point for next stop
                _navigateToCurrentVirtualTourStop(
                  fromLocation: currentStopLocation,
                );
              },
              onPrevious: () {
                _nearbyImageManager.clear();

                // Get current stop's location BEFORE moving back
                final currentStopLocation =
                    _virtualTourManager.currentStop?.navigationTarget;

                _virtualTourManager.previousStop();

                // Pass current stop's location as starting point for previous stop
                _navigateToCurrentVirtualTourStop(
                  fromLocation: currentStopLocation,
                );
              },
              onEndTour: () {
                _endVirtualTour();
              },
            ),
        ],
      ),
      bottomNavigationBar: ReusableBottomNavBar(currentIndex: 2),
    );
  }

  void _handleMapTapAtLatLng(LatLng latLng) async {
    if (_isDisposed || !context.mounted) return;

    final building = MapBuildings.findBuildingAtPoint(latLng);
    if (building != null) {
      // Clear any selected marker when tapping a building
      if (_selectedMarkerId != null) {
        setState(() {
          _selectedMarkerId = null;
          _isMarkerType = false;
        });
      }

      await MapUtils.animateToBuildingLocation(
        _mapController,
        building.getCenterPoint(),
        zoom: 19.5,
        duration: const Duration(milliseconds: 600),
      );
      if (mounted && context.mounted) {
        BottomSheets.showBuildingInfo(
          context,
          building,
          onVirtualTour: () => _startVirtualTour(building),
          onDirections: () => _showDirections(building),
        );
      }
    } else {
      // Tapped empty space - clear selected marker
      if (_selectedMarkerId != null) {
        setState(() {
          _selectedMarkerId = null;
          _isMarkerType = false;
        });
      }
    }
  }

  void _centerOnCampus() async {
    if (_isDisposed) return;

    await MapUtils.panToLocationFromCurrentView(
      _mapController,
      MapBoundary.bicolUniversityCenter,
      targetZoom: 18.0,
      animationDuration: const Duration(milliseconds: 1000),
    );
  }

  void _zoomIn() {
    if (_isDisposed) return;
    MapUtils.zoomIn(_mapController);
  }

  void _zoomOut() {
    if (_isDisposed) return;
    MapUtils.zoomOut(_mapController);
  }

  // Update nearby images based on current position along the animated route during tour
  void _updateNearbyImagesForRoute() {
    if (!_isVirtualTourActive || !MapBuildings.isInitialized) return;

    // Use the last point of animated route as "current position"
    LatLng? currentPosition;

    if (_animatedRoutePoints.isNotEmpty) {
      currentPosition = _animatedRoutePoints.last;
    } else if (_currentLocation != null) {
      currentPosition = _currentLocation;
    }

    if (currentPosition != null) {
      // Exclude the current destination building from showing nearby images
      Set<int> excludedIds = {};
      if (_virtualTourManager.currentStop != null) {
        excludedIds.add(_virtualTourManager.currentStop!.buildingId);
      }

      _nearbyImageManager.updateLocation(
        currentPosition,
        MapBuildings.campusBuildings,
        [...MapBuildings.colleges, ...MapBuildings.landmarks],
        excludedBuildingIds: excludedIds,
      );
    }
  }

  // Update nearby images during regular navigation Waze animation
  void _updateNearbyImagesForNavigation(int? destinationBuildingId) {
    if (!MapBuildings.isInitialized) return;

    // Use the last point of animated route as "current position"
    LatLng? currentPosition;

    if (_animatedRoutePoints.isNotEmpty) {
      currentPosition = _animatedRoutePoints.last;
    } else if (_currentLocation != null) {
      currentPosition = _currentLocation;
    }

    if (currentPosition != null) {
      // Exclude the destination building from showing nearby images
      Set<int> excludedIds = {};
      if (destinationBuildingId != null) {
        excludedIds.add(destinationBuildingId);
      }

      _nearbyImageManager.updateLocation(
        currentPosition,
        MapBuildings.campusBuildings,
        [...MapBuildings.colleges, ...MapBuildings.landmarks],
        excludedBuildingIds: excludedIds,
      );
    }
  }

  void _startVirtualTour(BicolBuildingPolygon building) {
    if (_isDisposed || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting virtual tour of ${building.displayName}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showDirections(BicolBuildingPolygon building) async {
    if (_isDisposed) return;

    if (_currentLocation == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current location not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // ✅ NEW: Check if user is already at the building
    final bool isAlreadyHere = RoutingService.isUserAtDestination(
      _currentLocation!,
      building.getCenterPoint(),
      buildingId: building.buildingId,
      thresholdMeters: 30.0,
    );

    if (isAlreadyHere) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Already Here',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              'You are already at ${building.displayName}!\n\nWould you still like to see the route?',
              style: TextStyle(fontSize: 15),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _forceShowRoute(building);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Show Route Anyway'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Normal flow
    setState(() {
      _targetedBuildingId = building.buildingId;
      _showDestinationMarker = false;
      _animateDestinationMarker = false;
    });

    final destination = building.getCenterPoint();
    await _getRoute(_currentLocation!, destination, building);

    if (!_isDisposed &&
        mounted &&
        _navigationManager.polylinePoints.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      RoutingService.fitMapToRoute(
        _mapController,
        _navigationManager.polylinePoints,
      );

      setState(() {
        _showDestinationMarker = true;
        _animateDestinationMarker = false;
      });
    }
  }

  void _followUserLocation() async {
    if (_currentLocation == null || _isDisposed) return;

    if (_navigationManager.isNavigating) {
      await MapUtils.animateToBuildingLocation(
        _mapController,
        _currentLocation!,
        zoom: 19.0,
        duration: const Duration(milliseconds: 800),
      );
    } else {
      await MapUtils.panToLocationFromCurrentView(
        _mapController,
        _currentLocation!,
        targetZoom: 18.0,
        animationDuration: const Duration(milliseconds: 800),
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _navigationManager.dispose();
    _virtualTourManager.dispose();
    _nearbyImageManager.dispose();
    _searchController.dispose();
    LocationService.disposeCompass();
    RoutingService.clearEntranceCache();
    super.dispose();
  }
}
