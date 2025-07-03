import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;

// map_assets:
import 'maps_assets/map_boundary.dart';
import 'maps_assets/map_building.dart';
import 'maps_assets/location_service.dart';
import 'maps_assets/map_utils.dart';
import 'maps_assets/map_widgets.dart';
import 'maps_assets/bottom_content.dart';
import 'maps_assets/routing_service.dart';

class Maps extends StatefulWidget {
  const Maps({super.key});

  @override
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;
  String _locationStatus = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchResults = false;

  // Real-time tracking variables
  StreamSubscription<Position>? _positionStream;
  bool _isTrackingLocation = false;
  bool _autoFollowLocation = false;

  // Navigation and route variables
  List<LatLng> _polylinePoints = [];
  bool _isLoadingRoute = false;
  String? _routeDistance;
  String? _routeDuration;
  BicolBuildingPolygon? _currentDestination;
  bool _isNavigating = false;
  double _currentBearing = 0.0;
  LatLng? _previousLocation;

  // Add this flag to track if widget is disposed
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    if (_isDisposed) return; // Check if disposed

    setState(() {
      _isLoadingLocation = true;
      _locationStatus = 'Starting location tracking...';
    });

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!_isDisposed) {
        setState(() {
          _isLoadingLocation = false;
          _locationStatus = 'Location services are disabled';
        });
      }
      return;
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!_isDisposed) {
          setState(() {
            _isLoadingLocation = false;
            _locationStatus = 'Location permissions are denied';
          });
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!_isDisposed) {
        setState(() {
          _isLoadingLocation = false;
          _locationStatus = 'Location permissions are permanently denied';
        });
      }
      return;
    }

    // Start listening to location updates
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            // Check if widget is still mounted before calling setState
            if (!_isDisposed && mounted) {
              final newLocation = LatLng(position.latitude, position.longitude);

              // Calculate bearing if we have a previous location
              if (_previousLocation != null) {
                _currentBearing = MapUtils.calculateBearing(
                  _previousLocation!,
                  newLocation,
                );
              }

              setState(() {
                _currentLocation = newLocation;
                _isTrackingLocation = true;
                _isLoadingLocation = false;
                _locationStatus = 'Location tracking active';
              });

              // Update previous location
              _previousLocation = newLocation;

              // Auto-follow user location if enabled OR if navigating
              if ((_autoFollowLocation || _isNavigating) && !_isDisposed) {
                _followUserLocation();
              }

              // Check if user reached destination during navigation
              if (_isNavigating && _currentDestination != null) {
                _checkDestinationReached();
              }
            }
          },
          onError: (error) {
            // Handle stream errors
            if (!_isDisposed && mounted) {
              setState(() {
                _isLoadingLocation = false;
                _locationStatus = 'Location error: $error';
              });
            }
          },
        );
  }

  void _stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    if (!_isDisposed && mounted) {
      setState(() {
        _isTrackingLocation = false;
        _locationStatus = 'Location tracking stopped';
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

  Future<void> _getCurrentLocation() async {
    if (_isDisposed) return;

    setState(() {
      _isLoadingLocation = true;
      _locationStatus = 'Getting location...';
    });

    final result = await LocationService.getCurrentLocation();

    if (!_isDisposed && mounted) {
      setState(() {
        _isLoadingLocation = false;
        if (result.isSuccess) {
          _currentLocation = result.location;
          _locationStatus = 'Location found';
        } else {
          _locationStatus = result.error ?? 'Unknown error';
        }
      });
    }
  }

  Future<void> _getRoute(
    LatLng start,
    LatLng end,
    BicolBuildingPolygon building,
  ) async {
    if (_isDisposed) return;

    setState(() {
      _isLoadingRoute = true;
      _polylinePoints.clear();
      _currentDestination = building;
    });

    try {
      final routeResult = await RoutingService.getRoute(start, end);

      if (!_isDisposed && mounted) {
        if (routeResult.isSuccess && routeResult.points != null) {
          setState(() {
            _polylinePoints = routeResult.points!;
            _routeDistance = routeResult.distance;
            _routeDuration = routeResult.duration;
            _isLoadingRoute = false;
          });

          // Use the routing service to fit the map to the route
          RoutingService.fitMapToRoute(_mapController, _polylinePoints);

          // Show route information
          _showRouteInfo(building);
        } else {
          setState(() {
            _isLoadingRoute = false;
          });

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
          _isLoadingRoute = false;
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

    if (_routeDistance != null && _routeDuration != null) {
      BottomSheets.showRouteInfo(
        context,
        buildingName: building.name,
        distance: _routeDistance!,
        duration: _routeDuration!,
        onClearRoute: _clearRoute,
        onStartNavigation: () => _startNavigation(building),
      );
    }
  }

  void _startNavigation(BicolBuildingPolygon building) {
    if (_isDisposed || !context.mounted) return;

    setState(() {
      _isNavigating = true;
      _autoFollowLocation = true; // Enable auto-follow during navigation
    });

    // Start location tracking if not already active
    if (!_isTrackingLocation) {
      _startLocationTracking();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.navigation, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Navigation started to ${building.name}')),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'STOP',
          textColor: Colors.white,
          onPressed: _stopNavigation,
        ),
      ),
    );
  }

  void _clearRoute() {
    if (_isDisposed) return;

    setState(() {
      _polylinePoints.clear();
      _routeDistance = null;
      _routeDuration = null;
      _currentDestination = null;
      _isNavigating = false;
      _currentBearing = 0.0;
      _previousLocation = null;
    });

    // Return to campus center view
    _centerOnCampus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map with camera constraint for boundary limits
          FlutterMap(
            mapController: _mapController,
            options: MapUtils.getDefaultMapOptions(
              MapBoundary.bicolUniversityCenter,
              MapBoundary.getCameraConstraint(),
            ),
            children: [
              // Tile Layer
              MapUtils.getDefaultTileLayer(),

              // Campus boundary visualization
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: MapBoundary.getCampusBoundaryPoints(),
                    color: const Color.fromARGB(
                      255,
                      0,
                      0,
                      0,
                    ).withValues(alpha: 0.05),
                    borderColor: Colors.blue.withValues(alpha: 0.3),
                    borderStrokeWidth: 2,
                    isFilled: true,
                  ),
                ],
              ),

              // Building polygons layer
              PolygonLayer(
                polygons: MapBuildings.campusBuildings.map((building) {
                  return Polygon(
                    points: building.points,
                    color: MapBuildings.getBuildingColor(
                      building.type,
                    ).withValues(alpha: 0.7),
                    borderColor: MapBuildings.getBuildingColor(building.type),
                    borderStrokeWidth: 2,
                    isFilled: true,
                  );
                }).toList(),
              ),

              // Polyline layer for directions - using RouteHelper
              if (_polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [RouteHelper.createRoutePolyline(_polylinePoints)],
                ),

              // Current location marker
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    _isNavigating
                        ? MapUtils.createNavigationMarker(
                            _currentLocation!,
                            _currentBearing,
                          )
                        : MapUtils.createUserLocationMarker(_currentLocation!),
                  ],
                ),

              // Invisible tap detection layer for building polygons
              GestureDetector(
                onTapUp: (details) => _handleMapTap(details),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
            ],
          ),

          // Top floating search bar and back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Back button with proper navigation handling
                MapWidgets.buildFloatingActionButton(
                  icon: Icons.arrow_back,
                  onPressed: () {
                    // Ensure cleanup before navigation
                    _stopLocationTracking();
                    Navigator.of(context).pop();
                  },
                  iconColor: Colors.black87,
                ),
                const SizedBox(width: 12),

                // Search bar
                Expanded(
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

                const SizedBox(width: 12),

                // Filter/Menu button
                MapWidgets.buildFloatingActionButton(
                  icon: Icons.tune,
                  onPressed: () {
                    if (!_isDisposed && context.mounted) {
                      BottomSheets.showFilterOptions(context);
                    }
                  },
                  iconColor: Colors.black87,
                ),
              ],
            ),
          ),

          // Search results dropdown
          if (_showSearchResults)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 76,
              right: 76,
              child: MapWidgets.buildSearchResults(
                buildings: MapBuildings.getFilteredBuildings(
                  _searchController.text,
                ),
                onBuildingTap: (building) async {
                  if (_isDisposed) return;

                  // Clear search first
                  _searchController.clear();
                  setState(() {
                    _showSearchResults = false;
                  });

                  // Show loading indicator briefly
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
                            Text('Navigating to ${building.name}...'),
                          ],
                        ),
                        backgroundColor: Colors.blue,
                        duration: const Duration(milliseconds: 800),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  // Use the enhanced panning method
                  await MapUtils.panToLocationFromCurrentView(
                    _mapController,
                    building.getCenterPoint(),
                    targetZoom: 19.0,
                    animationDuration: const Duration(milliseconds: 1200),
                  );
                },
              ),
            ),

          // Right side floating controls
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 80,
            child: Column(
              children: [
                // Location tracking button
                MapWidgets.buildFloatingActionButton(
                  icon: _isTrackingLocation
                      ? Icons.location_on
                      : Icons.location_off,
                  onPressed: _isTrackingLocation
                      ? _stopLocationTracking
                      : _startLocationTracking,
                  iconColor: _isTrackingLocation
                      ? Colors.green
                      : Colors.grey[600],
                  isLoading: _isLoadingLocation,
                ),
                const SizedBox(height: 12),

                // Auto-follow toggle button
                MapWidgets.buildFloatingActionButton(
                  icon: _autoFollowLocation
                      ? Icons.center_focus_strong
                      : Icons.center_focus_weak,
                  onPressed: _toggleAutoFollow,
                  iconColor: _autoFollowLocation
                      ? Colors.orange
                      : Colors.grey[600],
                ),
                const SizedBox(height: 12),

                // Clear route button (only show when route is active)
                if (_polylinePoints.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  MapWidgets.buildFloatingActionButton(
                    icon: Icons.clear,
                    onPressed: _clearRoute,
                    iconColor: Colors.red,
                  ),
                ],
              ],
            ),
          ),

          // Bottom zoom controls
          Positioned(
            right: 16,
            bottom: 100,
            child: MapWidgets.buildZoomControls(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
            ),
          ),

          // Bottom legend/status bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Route info (if route is active)
                if (_polylinePoints.isNotEmpty &&
                    !_isLoadingRoute &&
                    _currentDestination != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: _isNavigating ? Colors.green : Colors.blue,
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
                                  if (_isNavigating) ...[
                                    const Icon(
                                      Icons.navigation,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Expanded(
                                    child: Text(
                                      _isNavigating
                                          ? 'Navigating to ${_currentDestination!.name}'
                                          : 'Route to ${_currentDestination!.name}',
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
                              if (_routeDistance != null &&
                                  _routeDuration != null)
                                Text(
                                  '$_routeDistance • $_routeDuration',
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
                            if (_isNavigating) ...[
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
                                  _showRouteInfo(_currentDestination!);
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

                // Loading indicator for route
                if (_isLoadingRoute)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Loading route...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                // Legend bar
                MapWidgets.buildLegendBar(
                  isLocationConnected: _currentLocation != null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Also update the _handleMapTap method for better building selection:
  void _handleMapTap(TapUpDetails details) async {
    if (_isDisposed || !context.mounted) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    final mapPosition = MapUtils.screenToLatLng(
      localPosition,
      _mapController,
      MediaQuery.of(context).size,
    );

    final building = MapBuildings.findBuildingAtPoint(mapPosition);
    if (building != null) {
      // Add a subtle zoom-in effect when tapping on buildings
      await MapUtils.animateToBuildingLocation(
        _mapController,
        building.getCenterPoint(),
        zoom: 19.5,
        duration: const Duration(milliseconds: 600),
      );

      if (!_isDisposed && context.mounted) {
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
        content: Text('Starting virtual tour of ${building.name}'),
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

  // New navigation methods
  void _stopNavigation() {
    if (_isDisposed) return;

    setState(() {
      _isNavigating = false;
      _autoFollowLocation = false;
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigation stopped'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _followUserLocation() async {
    if (_currentLocation == null || _isDisposed) return;

    if (_isNavigating) {
      // During navigation, use a closer zoom and smooth animation
      await MapUtils.animateToBuildingLocation(
        _mapController,
        _currentLocation!,
        zoom: 19.0,
        duration: const Duration(milliseconds: 800),
      );
    } else {
      // Normal follow mode with smooth transition
      await MapUtils.panToLocationFromCurrentView(
        _mapController,
        _currentLocation!,
        targetZoom: 18.0,
        animationDuration: const Duration(milliseconds: 800),
      );
    }
  }

  void _checkDestinationReached() {
    if (_currentLocation == null || _currentDestination == null) return;

    final destination = _currentDestination!.getCenterPoint();
    final distance = _calculateDistance(_currentLocation!, destination);

    // If within 50 meters of destination, consider it reached
    if (distance < 50) {
      _destinationReached();
    }
  }

  void _destinationReached() {
    if (_isDisposed || !context.mounted) return;

    setState(() {
      _isNavigating = false;
      _autoFollowLocation = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.place, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('You have arrived at ${_currentDestination!.name}!'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );

    // Optionally clear the route after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isDisposed) {
        _clearRoute();
      }
    });
  }

  // Calculate distance between two points in meters
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters

    double lat1Rad = point1.latitude * (math.pi / 180);
    double lat2Rad = point2.latitude * (math.pi / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180);
    double deltaLngRad =
        (point2.longitude - point1.longitude) * (math.pi / 180);

    double a =
        math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  @override
  void dispose() {
    // Set disposal flag first
    _isDisposed = true;

    // Cancel location tracking
    _stopLocationTracking();

    // Dispose controllers
    _searchController.dispose();

    // Call super dispose
    super.dispose();
  }
}
