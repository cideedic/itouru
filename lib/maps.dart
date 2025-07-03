import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

// map_assets:
import 'maps_assets/map_boundary.dart';
import 'maps_assets/map_building.dart';
import 'maps_assets/location_service.dart';
import 'maps_assets/map_utils.dart';
import 'maps_assets/map_widgets.dart';
import 'maps_assets/bottom_content.dart';

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

  // Sample building polygons for Bicol University (actual building outlines)

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatus = 'Getting location...';
    });

    final result = await LocationService.getCurrentLocation();

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

              // Campus boundary visualization (optional, for visual reference)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: MapBoundary.getCampusBoundaryPoints(),
                    color: Colors.blue.withOpacity(0.05),
                    borderColor: Colors.blue.withOpacity(0.3),
                    borderStrokeWidth: 2,
                    isFilled: true,
                  ),
                ],
              ),

              // Building polygons layer (clickable building outlines)
              PolygonLayer(
                polygons: MapBuildings.campusBuildings.map((building) {
                  return Polygon(
                    points: building.points,
                    color: MapBuildings.getBuildingColor(
                      building.type,
                    ).withOpacity(0.7),
                    borderColor: MapBuildings.getBuildingColor(building.type),
                    borderStrokeWidth: 2,
                    isFilled: true,
                  );
                }).toList(),
              ),

              // Current location marker
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    MapUtils.createUserLocationMarker(_currentLocation!),
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
                // Back button
                MapWidgets.buildFloatingActionButton(
                  icon: Icons.tune,
                  onPressed: () => BottomSheets.showFilterOptions(context),
                  iconColor: Colors.black87,
                ),
                const SizedBox(width: 12),

                // Search bar
                Expanded(
                  child: MapWidgets.buildSearchBar(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _showSearchResults = value.isNotEmpty;
                      });
                    },
                    onClear: () {
                      _searchController.clear();
                      setState(() {
                        _showSearchResults = false;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // Filter/Menu button
                MapWidgets.buildFloatingActionButton(
                  icon: Icons.tune,
                  onPressed: () => BottomSheets.showFilterOptions(context),
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
                onBuildingTap: (building) {
                  _searchController.clear();
                  setState(() {
                    _showSearchResults = false;
                  });
                  _mapController.move(building.getCenterPoint(), 19.0);
                  Future.delayed(const Duration(milliseconds: 500), () {
                    BottomSheets.showBuildingInfo(
                      context,
                      building,
                      onVirtualTour: () => _startVirtualTour(building),
                      onDirections: () => _showDirections(building),
                    );
                  });
                },
              ),
            ),

          // Right side floating controls
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 80,
            child: Column(
              children: [
                // My location button
                MapWidgets.buildFloatingActionButton(
                  icon: Icons.my_location,
                  onPressed: _currentLocation != null
                      ? _centerOnCurrentLocation
                      : _getCurrentLocation,
                  iconColor: _currentLocation != null
                      ? Colors.blue
                      : Colors.grey[600],
                  isLoading: _isLoadingLocation,
                ),
                const SizedBox(height: 12),

                // Campus center button
                MapWidgets.buildFloatingActionButton(
                  icon: Icons.home,
                  onPressed: _centerOnCampus,
                ),
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
            child: MapWidgets.buildLegendBar(
              isLocationConnected: _currentLocation != null,
            ),
          ),
        ],
      ),
    );
  }

  // Handle map tap to detect building polygon clicks
  void _handleMapTap(TapUpDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    final mapPosition = _screenToLatLng(localPosition);

    final building = MapBuildings.findBuildingAtPoint(mapPosition);
    if (building != null) {
      BottomSheets.showBuildingInfo(
        context,
        building,
        onVirtualTour: () => _startVirtualTour(building),
        onDirections: () => _showDirections(building),
      );
    }
  }

  // Convert screen coordinates to LatLng
  LatLng _screenToLatLng(Offset screenPoint) {
    final size = MediaQuery.of(context).size;
    return MapUtils.screenToLatLng(screenPoint, _mapController, size);
  }

  void _centerOnCampus() {
    MapUtils.animateToLocation(
      _mapController,
      MapBoundary.bicolUniversityCenter,
      zoom: 17.0,
    );
  }

  void _centerOnCurrentLocation() {
    if (_currentLocation != null) {
      MapUtils.animateToLocation(_mapController, _currentLocation!);
    }
  }

  void _zoomIn() {
    MapUtils.zoomIn(_mapController);
  }

  void _zoomOut() {
    MapUtils.zoomOut(_mapController);
  }

  void _startVirtualTour(BicolBuildingPolygon building) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting virtual tour of ${building.name}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showDirections(BicolBuildingPolygon building) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing directions to ${building.name}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
