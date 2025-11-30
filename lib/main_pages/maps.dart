import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../page_components/bottom_nav_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
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
import '../maps_assets/destination_marker.dart';

class Maps extends StatefulWidget {
  final LatLng? autoNavigateTo;
  final String? destinationName;
  final int? buildingId;
  final String? itemType;

  final bool startVirtualTour;
  final String? tourName;
  final List<VirtualTourStop>? tourStops;

  const Maps({
    super.key,
    this.autoNavigateTo,
    this.destinationName,
    this.buildingId,
    this.itemType,
    this.startVirtualTour = false,
    this.tourName,
    this.tourStops,
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

  late VirtualTourManager _virtualTourManager;
  bool _isVirtualTourActive = false;

  @override
  void initState() {
    super.initState();

    _navigationManager = NavigationManager();
    _virtualTourManager = VirtualTourManager();
    _setupNavigationCallbacks();
    _setupVirtualTourCallbacks();
    _startContinuousLocationTracking();
    _startLocationTracking();
    _loadMapDataWithRetry();
    _currentZoom = MapBoundary.getInitialZoom();
    LocationService.initializeCompass();
    _checkAndShowFirstTimeGuide();

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
                  icon: Icons.place,
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

      if (_navigationManager.polylinePoints.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 300));
        RoutingService.fitMapToRoute(
          _mapController,
          _navigationManager.polylinePoints,
        );
      } else {}

      return;
    }

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
                  'Getting route to ${targetBuilding.displayName}...',
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

    if (_navigationManager.polylinePoints.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      RoutingService.fitMapToRoute(
        _mapController,
        _navigationManager.polylinePoints,
      );
    } else {}
  }

  Future<void> _showDirectionsForBuilding(BicolBuildingPolygon building) async {
    if (_isDisposed || _currentLocation == null) return;
    final destination = building.getCenterPoint();
    await _getRoute(_currentLocation!, destination, building);
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
      final routeResult = await _navigationManager.getRouteAndPrepareNavigation(
        start,
        end,
        building,
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
              ),
            );
          }
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
              content: Text('Error getting route: $e'),
              backgroundColor: Colors.red,
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

    setState(() {
      _autoFollowLocation = true;
    });

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
    setState(() {
      _autoFollowLocation = false;
    });
    _centerOnCampus();
  }

  void _stopNavigation() {
    if (_isDisposed) return;
    _navigationManager.stopNavigation();
    setState(() {
      _autoFollowLocation = false;
    });
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

    // Calculate delay with exponential backoff for rate limiting
    int delaySeconds = 0;
    if (_retryAttempts > 0) {
      delaySeconds = (2 * (_retryAttempts)).clamp(2, 10);

      debugPrint(
        '⏳ Waiting ${delaySeconds}s before retry (attempt ${_retryAttempts + 1})...',
      );

      // Show countdown in UI
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
        const Duration(seconds: 45), //
        onTimeout: () {
          throw TimeoutException('Map loading timed out after 45 seconds');
        },
      );

      // Verify data loaded
      final hasBuildings = MapBuildings.campusBuildings.isNotEmpty;
      final hasMarkers = MapBuildings.campusMarkers.isNotEmpty;
      final isInitialized = MapBuildings.isInitialized;

      if (!isInitialized) {
        throw Exception('Map initialization incomplete');
      }

      if (!hasBuildings && !hasMarkers) {
        throw Exception('No map data received from server');
      }

      // Success!
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
      icon = Icons.place;
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
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
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

    final tempBuilding = BicolBuildingPolygon(
      points: [marker.position],
      name: marker.name,
      description: marker.isCollege ? 'College' : 'Landmark',
      buildingId: marker.buildingId,
      databaseName: marker.databaseName,
    );

    await _getRoute(_currentLocation!, marker.position, tempBuilding);
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

    // Step 1: Resolve building locations (polygons AND markers)
    List<VirtualTourStop> resolvedStops = [];

    for (var stop in widget.tourStops!) {
      // First, try to find as a landmark marker
      final marker = MapBuildings.landmarks.firstWhere(
        (m) => m.buildingId == stop.buildingId,
        orElse: () => MapBuildings.landmarks.first,
      );

      if (marker.buildingId == stop.buildingId) {
        // Found as landmark marker
        stop.setLocation(marker.position, isMarkerType: true);
        resolvedStops.add(stop);
        continue;
      }

      // If not a landmark, try to find as building polygon
      try {
        final building = MapBuildings.campusBuildings.firstWhere(
          (b) => b.buildingId == stop.buildingId,
        );

        stop.setLocation(building.getCenterPoint(), isMarkerType: false);

        // Fetch entrance from OSM
        final entrance = await RoutingService.fetchBuildingEntrance(
          building.getCenterPoint(),
          building.name,
        );

        if (entrance != null) {
          stop.setEntranceLocation(entrance);
        } else {
          debugPrint(' No entrance found for ${building.name}, using center');
        }

        resolvedStops.add(stop);
      } catch (e) {
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

    // Step 2: Determine starting point (user location OR nearest gate)
    LatLng startingPoint;

    if (_currentLocation != null &&
        MapBoundary.isWithinCampusBounds(_currentLocation!)) {
      startingPoint = _currentLocation!;
    } else {
      final gates = await RoutingService.fetchCampusGates(
        campusCenter: MapBoundary.bicolUniversityCenter,
        radiusMeters: 600,
      );

      CampusGate? nearestGate;
      if (gates.isNotEmpty) {
        final firstBuilding = resolvedStops.first.navigationTarget;
        double minDistance = double.infinity;
        for (var gate in gates) {
          final distance = RoutingService.calculateDistance(
            firstBuilding,
            gate.location,
          );
          if (distance < minDistance) {
            minDistance = distance;
            nearestGate = gate;
          }
        }
      }

      startingPoint =
          nearestGate?.location ?? MapBoundary.bicolUniversityCenter;
    }

    // Step 3: Start the tour
    _virtualTourManager.startTour(
      tourName: widget.tourName ?? 'Campus Tour',
      stops: resolvedStops,
      startingGate: startingPoint,
    );

    setState(() {
      _isVirtualTourActive = true;
      _tourStartPoint = startingPoint;
    });

    // Step 4: Show welcome message
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.tour, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Starting ${widget.tourName} - ${resolvedStops.length} stops',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    // Step 5: First show entire campus overview
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    await MapUtils.animateToBuildingLocation(
      _mapController,
      MapBoundary.bicolUniversityCenter,
      zoom: 16.5, // Wide view to see entire campus
      duration: const Duration(milliseconds: 1500),
    );

    // Step 6: Wait a moment, then navigate to first stop
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    _navigateToCurrentVirtualTourStop();
  }

  Future<void> _navigateToCurrentVirtualTourStop({LatLng? fromLocation}) async {
    if (_isDisposed || !_virtualTourManager.isActive) return;

    final currentStop = _virtualTourManager.currentStop;
    if (currentStop == null || currentStop.location == null) return;

    _virtualTourManager.beginAnimationToStop();

    LatLng startPoint;

    if (fromLocation != null) {
      startPoint = fromLocation;
    } else if (_virtualTourManager.currentStopIndex == 0) {
      startPoint = _virtualTourManager.startingGate!;
    } else {
      final previousStop =
          _virtualTourManager.stops[_virtualTourManager.currentStopIndex - 1];
      startPoint = previousStop.navigationTarget;
    }

    // Get route to entrance (or center if no entrance found)
    final routeResult = await RoutingService.getRoute(
      startPoint,
      currentStop.navigationTarget, // Use navigationTarget
    );

    if (routeResult.isSuccess && routeResult.points != null) {
      // Clear previous navigation
      setState(() {
        _navigationManager.clearRoute();
        _animatedRoutePoints = []; // Clear animated route
      });

      // Animate with progressive route drawing + camera rotation
      await MapUtils.animateAlongRouteWithCamera(
        _mapController,
        routeResult.points!,
        onRouteUpdate: (visibleRoute) {
          if (mounted && !_isDisposed) {
            setState(() {
              _animatedRoutePoints = visibleRoute;
            });
          }
        },
      );

      // Store full route after animation
      setState(() {
        _animatedRoutePoints = routeResult.points!;
        _navigationManager.polylinePoints.clear();
        _navigationManager.polylinePoints.addAll(routeResult.points!);
      });

      // Show stop card
      _virtualTourManager.completeAnimationToStop();
      _showVirtualTourStopCard();
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not find route to ${currentStop.buildingName}'),
          backgroundColor: Colors.red,
        ),
      );
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

    setState(() {
      _isVirtualTourActive = false;
      _animatedRoutePoints = [];
      _tourStartPoint = null;
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
              MapUtils.getDefaultTileLayer(),

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
                      return Polygon(
                        points: building.points,
                        color: Colors.orange.withValues(alpha: 0.3),
                        borderColor: Colors.orange,
                        borderStrokeWidth: 2,
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
                      color: const Color(0xFF2196F3),
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
                            MapBoundary.isWithinCampusBounds(marker.position),
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
                            MapBoundary.isWithinCampusBounds(marker.position),
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

          // Search results
          if (_showSearchResults)
            Positioned(
              top: MediaQuery.of(context).padding.top + 115,
              left: 16,
              right: 16,
              child: MapWidgets.buildSearchResults(
                results: MapBuildings.searchAll(_searchController.text),
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
                                child: Text('Finding ${result.name}...'),
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
                        BottomSheets.showBuildingInfo(
                          context,
                          building,
                          onVirtualTour: () => _startVirtualTour(building),
                          onDirections: () => _showDirections(building),
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

          // Zoom and location controls
          Positioned(
            right: 16,
            bottom: 100,
            child: IgnorePointer(
              ignoring: false,
              child: Column(
                children: [
                  MapWidgets.buildFilterButton(
                    onPressed: () => _showFilterModal(),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (_navigationManager.isNavigating) ...[
                                    const Icon(
                                      Icons.navigation,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Expanded(
                                    child: Text(
                                      _navigationManager.isNavigating
                                          ? 'Navigating to ${_navigationManager.currentDestination.displayName}'
                                          : 'Route to ${_navigationManager.currentDestination.displayName}',
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
                              ),
                              if (_navigationManager.routeDistance != null &&
                                  _navigationManager.routeDuration != null)
                                Text(
                                  '${_navigationManager.routeDistance} • ${_navigationManager.routeDuration}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_navigationManager.isNavigating) ...[
                              GestureDetector(
                                onTap: _stopNavigation,
                                child: const Icon(
                                  Icons.stop,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            GestureDetector(
                              onTap: () {
                                if (!_isDisposed) {
                                  _showRouteInfo(
                                    _navigationManager.currentDestination,
                                  );
                                }
                              },
                              child: const Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 20,
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
                _virtualTourManager.nextStop();
                _navigateToCurrentVirtualTourStop();
              },
              onPrevious: () {
                // Store current location before going back
                final currentLocation =
                    _virtualTourManager.currentStop?.location;
                _virtualTourManager.previousStop();
                _navigateToCurrentVirtualTourStop(
                  fromLocation: currentLocation,
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

  void _showDirections(BicolBuildingPolygon building) {
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

    final destination = building.getCenterPoint();
    _getRoute(_currentLocation!, destination, building);
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
    _searchController.dispose();
    LocationService.disposeCompass();
    super.dispose();
  }
}
