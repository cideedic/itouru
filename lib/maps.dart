import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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

  // Bicol University Main Campus coordinates (approximate)
  static const LatLng bicolUniversityCenter = LatLng(13.144378, 123.724111);

  // Define campus boundary (adjust these coordinates to match actual campus bounds)
  static const double campusRadiusInMeters = 500; // 800 meters radius
  static const LatLng northEast = LatLng(
    13.146509,
    123.76021,
  ); // Top-right corner
  static const LatLng southWest = LatLng(
    13.141452,
    123.720839,
  ); // Bottom-left corner

  // Create bounds for the campus area
  static final LatLngBounds campusBounds = LatLngBounds(southWest, northEast);

  // Sample building locations for Bicol University
  final List<BicolBuildingMarker> campusBuildings = [
    BicolBuildingMarker(
      position: const LatLng(13.14295590, 123.72434098),
      name: "College of Science - Building 1",
      description: "Main administrative offices and registrar",
      type: BuildingType.administrative,
    ),
    BicolBuildingMarker(
      position: const LatLng(13.14278403, 123.72420182),
      name: "College of Science - Building 2",
      description: "Engineering programs and laboratories",
      type: BuildingType.academic,
    ),
    BicolBuildingMarker(
      position: const LatLng(13.14260588, 123.72394515),
      name: "College of Science - Building 3",
      description: "Humanities and liberal arts programs",
      type: BuildingType.academic,
    ),
    BicolBuildingMarker(
      position: const LatLng(13.14213902, 123.72376091),
      name: "College of Science - Building 4",
      description: "University library and study areas",
      type: BuildingType.facility,
    ),
    BicolBuildingMarker(
      position: const LatLng(13.14247308, 123.72446666),
      name: "College of Nursing",
      description: "Student services and activities",
      type: BuildingType.facility,
    ),
  ];

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

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = 'Location services disabled';
          _isLoadingLocation = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'Location permission denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'Location permission permanently denied';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _locationStatus = 'Location found';
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'Error getting location: $e';
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BU Campus Map'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          if (_isLoadingLocation)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _currentLocation != null
                ? _centerOnCurrentLocation
                : _getCurrentLocation,
            tooltip: 'My Location',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: _centerOnCampus,
            tooltip: 'Center on Campus',
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Legend
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Legend: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildLegendItem(Colors.red, 'Academic'),
                    const SizedBox(width: 16),
                    _buildLegendItem(Colors.blue, 'Administrative'),
                    const SizedBox(width: 16),
                    _buildLegendItem(Colors.green, 'Facilities'),
                    const Spacer(),
                    if (_currentLocation != null)
                      _buildLegendItem(Colors.purple, 'Your Location'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _locationStatus,
                  style: TextStyle(
                    fontSize: 12,
                    color: _currentLocation != null
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: bicolUniversityCenter,
                initialZoom: 18.0,
                minZoom: 16.0, // Prevent zooming out too far
                maxZoom: 20.0,
                // Limit map movement to campus bounds
                cameraConstraint: CameraConstraint.contain(
                  bounds: campusBounds,
                ),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.flingAnimation,
                ),

                // Add boundary checking
              ),
              children: [
                // Tile Layer - Using CartoDB Positron for minimalist white/blue style
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // OSM tiles
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.bicoluniversity.etouro',
                  maxNativeZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    // Campus building markers
                    ...campusBuildings.map(
                      (building) => Marker(
                        point: building.position,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showBuildingInfo(building),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _getBuildingColor(building.type),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Current location marker
                    if (_currentLocation != null)
                      Marker(
                        point: _currentLocation!,
                        width: 50,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                  ],
                ),
                // Campus boundary visualization
                CircleLayer(
                  circles: [
                    // Main campus boundary circle
                    CircleMarker(
                      point: bicolUniversityCenter,
                      radius: campusRadiusInMeters,
                      color: Colors.blue.withOpacity(0.08),
                      borderColor: Colors.blue.withOpacity(0.4),
                      borderStrokeWidth: 2,
                    ),
                    // Inner campus core
                    CircleMarker(
                      point: bicolUniversityCenter,
                      radius: 400,
                      color: Colors.green.withOpacity(0.05),
                      borderColor: Colors.green.withOpacity(0.2),
                      borderStrokeWidth: 1,
                    ),
                    // Accuracy circle for current location
                    if (_currentLocation != null)
                      CircleMarker(
                        point: _currentLocation!,
                        radius: 20,
                        color: Colors.purple.withOpacity(0.1),
                        borderColor: Colors.purple.withOpacity(0.3),
                        borderStrokeWidth: 1,
                      ),
                  ],
                ),
                // Boundary polygon overlay (more precise boundary)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _getCampusBoundaryPoints(),
                      color: Colors.blue.withOpacity(0.05),
                      borderColor: Colors.blue.withOpacity(0.3),
                      borderStrokeWidth: 2,
                      isFilled: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "zoom_in",
            mini: true,
            onPressed: _zoomIn,
            child: const Icon(Icons.zoom_in),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "zoom_out",
            mini: true,
            onPressed: _zoomOut,
            child: const Icon(Icons.zoom_out),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _getBuildingColor(BuildingType type) {
    switch (type) {
      case BuildingType.academic:
        return Colors.red;
      case BuildingType.administrative:
        return Colors.blue;
      case BuildingType.facility:
        return Colors.green;
    }
  }

  void _showBuildingInfo(BicolBuildingMarker building) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.business,
                  color: _getBuildingColor(building.type),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    building.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(building.description, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to virtual tour
                    _startVirtualTour(building);
                  },
                  icon: const Icon(Icons.view_in_ar),
                  label: const Text('Virtual Tour'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Show directions
                    _showDirections(building);
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _centerOnCampus() {
    _mapController.move(bicolUniversityCenter, 17.0);
  }

  void _centerOnCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 18.0);
    }
  }

  // Check if current position is within campus bounds
  void _checkBoundary(LatLng position) {
    if (!campusBounds.contains(position)) {
      // If outside bounds, move back to center
      _mapController.move(bicolUniversityCenter, _mapController.camera.zoom);
    }
  }

  // Define precise campus boundary points (polygon)
  List<LatLng> _getCampusBoundaryPoints() {
    // You can customize these points to match the exact campus shape
    // This creates an octagonal boundary around the campus
    return [
      const LatLng(13.146747, 123.722934), // North
      const LatLng(13.145363, 123.724613), // Northeast
      const LatLng(13.143788, 123.726284), // East
      const LatLng(13.142411, 123.725232), // Southeast
      const LatLng(13.141588, 123.723409), // South
      const LatLng(13.141669, 123.720579), // Southwest
      const LatLng(13.144075, 123.721241), // West
      const LatLng(13.146196, 123.722263), // Northwest
    ];
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  void _startVirtualTour(BicolBuildingMarker building) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting virtual tour of ${building.name}'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  void _showDirections(BicolBuildingMarker building) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing directions to ${building.name}'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }
}

// Data models
class BicolBuildingMarker {
  final LatLng position;
  final String name;
  final String description;
  final BuildingType type;

  BicolBuildingMarker({
    required this.position,
    required this.name,
    required this.description,
    required this.type,
  });
}

enum BuildingType { academic, administrative, facility }
