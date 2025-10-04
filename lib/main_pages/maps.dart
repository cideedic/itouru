import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../page_components/bottom_nav_bar.dart';

// map_assets:
import '../maps_assets/map_boundary.dart';
import '../maps_assets/map_building.dart';
import '../maps_assets/location_service.dart';
import '../maps_assets/map_utils.dart';
import '../maps_assets/map_widgets.dart';
import '../maps_assets/bottom_content.dart';
import '../maps_assets/routing_service.dart';

class Maps extends StatefulWidget {
  const Maps({super.key});

  @override
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchResults = false;

  // Replace individual navigation variables with NavigationManager
  late NavigationManager _navigationManager;
  bool _autoFollowLocation = false;

  // Add this flag to track if widget is disposed
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _navigationManager = NavigationManager();
    _setupNavigationCallbacks();
    _startLocationTracking();
    _loadBuildingData();
  }

  void _setupNavigationCallbacks() {
    // Set up navigation callbacks
    _navigationManager.onLocationUpdate = (location, bearing) {
      if (!_isDisposed && mounted) {
        setState(() {
          _currentLocation = location;
        });

        // Auto-follow user location if enabled OR if navigating
        if (_autoFollowLocation || _navigationManager.isNavigating) {
          _followUserLocation();
        }
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

  Future<void> _startLocationTracking() async {
    if (_isDisposed) return;

    setState(() {
      _isLoadingLocation = true;
    });

    // Use your LocationService for initial location
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
      _isLoadingLocation = true; // Reuse loading state
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
          // Use the routing service to fit the map to the route
          RoutingService.fitMapToRoute(_mapController, routeResult.points!);

          // Show route information
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
        buildingName: building.name,
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
      _autoFollowLocation = true; // Enable auto-follow during navigation
    });

    // Start navigation using NavigationManager
    await _navigationManager.startNavigation(
      destination: building,
      routePoints: _navigationManager.polylinePoints,
      distance: _navigationManager.routeDistance,
      duration: _navigationManager.routeDuration,
    );

    if (mounted && context.mounted) {
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
  }

  void _clearRoute() {
    if (_isDisposed) return;

    _navigationManager.clearRoute();
    setState(() {
      _autoFollowLocation = false;
    });

    // Return to campus center view
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
      destinationName = destination.name;
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

    // Clear the route after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isDisposed) {
        _clearRoute();
      }
    });
  }

  // Simplify _loadBuildingData method:
  Future<void> _loadBuildingData() async {
    try {
      await MapBuildings.initializeWithBoundary(
        campusBoundaryPoints: MapBoundary.getCampusBoundaryPoints(),
      );
      if (mounted) {
        setState(() {
          // Update UI if needed
        });
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load building data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map with exact campus boundary constraints
          FlutterMap(
            mapController: _mapController,
            options: MapUtils.getDefaultMapOptions(
              MapBoundary.bicolUniversityCenter,
              MapBoundary.getCameraConstraint(),
            ),
            children: [
              // Tile Layer
              MapUtils.getDefaultTileLayer(),

              // Exact campus boundary visualization using GeoJSON data
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

              // Building polygons layer
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
                        color: Colors.blue.withValues(
                          alpha: 0.7,
                        ), // Use a single color
                        borderColor: Colors.blue,
                        borderStrokeWidth: 2,
                      );
                    })
                    .toList(),
              ),

              // Route polyline using NavigationManager
              if (_navigationManager.polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    RouteHelper.createRoutePolyline(
                      _navigationManager.polylinePoints
                          .where(
                            (point) => MapBoundary.isWithinCampusBounds(point),
                          )
                          .toList(),
                    ),
                  ],
                ),

              // Current location marker
              if (_currentLocation != null &&
                  MapBoundary.isWithinCampusBounds(_currentLocation!))
                MarkerLayer(
                  markers: [
                    _navigationManager.isNavigating
                        ? MapUtils.createNavigationMarker(
                            _currentLocation!,
                            _navigationManager.currentBearing,
                          )
                        : MapUtils.createUserLocationMarker(_currentLocation!),
                  ],
                ),

              // Map tap handler
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

          // Campus info overlay
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

          // Top floating search bar and controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 51,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Back button
                MapWidgets.buildFloatingActionButton(
                  icon: Icons.arrow_back,
                  onPressed: () {
                    _navigationManager.dispose();
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
              ],
            ),
          ),

          // Search results
          if (_showSearchResults)
            Positioned(
              top: MediaQuery.of(context).padding.top + 115,
              left: 76,
              right: 76,
              child: MapWidgets.buildSearchResults(
                buildings: MapBuildings.getFilteredBuildings(
                  _searchController.text,
                ),
                onBuildingTap: (building) async {
                  if (_isDisposed) return;

                  _searchController.clear();
                  setState(() {
                    _showSearchResults = false;
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

                  await MapUtils.panToLocationFromCurrentView(
                    _mapController,
                    building.getCenterPoint(),
                    targetZoom: 19.0,
                    animationDuration: const Duration(milliseconds: 1200),
                  );
                },
              ),
            ),

          // Right side controls
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 115,
            child: Column(
              children: [
                // Location tracking button
                MapWidgets.buildFloatingActionButton(
                  icon: _currentLocation != null
                      ? Icons.location_on
                      : Icons.location_off,
                  onPressed: _startLocationTracking,
                  iconColor: _currentLocation != null
                      ? Colors.green
                      : Colors.grey[600],
                  isLoading: _isLoadingLocation,
                ),
                const SizedBox(height: 12),

                // Auto-follow toggle
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

                // Clear route button
                if (_navigationManager.polylinePoints.isNotEmpty) ...[
                  MapWidgets.buildFloatingActionButton(
                    icon: Icons.clear,
                    onPressed: _clearRoute,
                    iconColor: Colors.red,
                  ),
                  const SizedBox(height: 12),
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

          // Bottom status/route info
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Route info using NavigationManager data
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
                                          ? 'Navigating to ${_navigationManager.currentDestination.name}'
                                          : 'Route to ${_navigationManager.currentDestination.name}',
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

                // Loading indicator
                if (_isLoadingLocation)
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
                        Text('Loading', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: ReusableBottomNavBar(currentIndex: 2),
    );
  }

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
    _searchController.dispose();
    super.dispose();
  }
}
