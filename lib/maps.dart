import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

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

  // Bicol University Main Campus coordinates (approximate)
  static const LatLng bicolUniversityCenter = LatLng(13.144378, 123.724111);

  // Define campus boundary (adjust these coordinates to match actual campus bounds)
  static const double campusRadiusInMeters = 500; // 500 meters radius
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
      body: Stack(
        children: [
          // Full-screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: bicolUniversityCenter,
              initialZoom: 18.0,
              minZoom: 16.0,
              maxZoom: 20.0,
              cameraConstraint: CameraConstraint.contain(bounds: campusBounds),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.flingAnimation,
              ),
            ),
            children: [
              // Tile Layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
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
                  // Accuracy circle for current location
                  if (_currentLocation != null)
                    CircleMarker(
                      point: _currentLocation!,
                      radius: 20,
                      color: Colors.blue.withOpacity(0.1),
                      borderColor: Colors.blue.withOpacity(0.3),
                      borderStrokeWidth: 1,
                    ),
                ],
              ),
              // Boundary polygon overlay
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

          // Top floating search bar and back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Back button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),

                // Search bar
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search buildings, locations...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _showSearchResults = false;
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _showSearchResults = value.isNotEmpty;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Filter/Menu button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: Colors.black87),
                    onPressed: _showFilterOptions,
                  ),
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
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  shrinkWrap: true,
                  itemCount: _getFilteredBuildings().length,
                  itemBuilder: (context, index) {
                    final building = _getFilteredBuildings()[index];
                    return ListTile(
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getBuildingColor(building.type),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      title: Text(
                        building.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        building.description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        _searchController.clear();
                        setState(() {
                          _showSearchResults = false;
                        });
                        _mapController.move(building.position, 19.0);
                        Future.delayed(const Duration(milliseconds: 500), () {
                          _showBuildingInfo(building);
                        });
                      },
                    );
                  },
                ),
              ),
            ),

          // Right side floating controls
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 140,
            child: Column(
              children: [
                // My location button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.my_location,
                            color: _currentLocation != null
                                ? Colors.blue
                                : Colors.grey[600],
                          ),
                    onPressed: _currentLocation != null
                        ? _centerOnCurrentLocation
                        : _getCurrentLocation,
                  ),
                ),
                const SizedBox(height: 12),

                // Campus center button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.home, color: Colors.grey[600]),
                    onPressed: _centerOnCampus,
                  ),
                ),
              ],
            ),
          ),

          // Bottom zoom controls
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.add, color: Colors.grey[700]),
                    onPressed: _zoomIn,
                  ),
                ),
                Container(width: 48, height: 1, color: Colors.grey[300]),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.remove, color: Colors.grey[700]),
                    onPressed: _zoomOut,
                  ),
                ),
              ],
            ),
          ),

          // Bottom legend/status bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildLegendItem(Colors.red, 'Academic'),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.blue, 'Admin'),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.green, 'Facilities'),
                  const Spacer(),
                  if (_currentLocation != null)
                    Icon(Icons.circle, color: Colors.green, size: 8),
                  if (_currentLocation != null) const SizedBox(width: 4),
                  Text(
                    _currentLocation != null
                        ? 'Connected'
                        : 'Finding location...',
                    style: TextStyle(
                      fontSize: 12,
                      color: _currentLocation != null
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
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

  List<BicolBuildingMarker> _getFilteredBuildings() {
    if (_searchController.text.isEmpty) return campusBuildings;

    return campusBuildings.where((building) {
      return building.name.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ) ||
          building.description.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );
    }).toList();
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Filter Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 16),
              ),
              title: const Text('Academic Buildings'),
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.business,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              title: const Text('Administrative'),
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_library,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              title: const Text('Facilities'),
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
          ],
        ),
      ),
    );
  }

  void _showBuildingInfo(BicolBuildingMarker building) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getBuildingColor(building.type),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        building.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        building.description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _startVirtualTour(building);
                    },
                    icon: const Icon(Icons.view_in_ar, size: 18),
                    label: const Text('Virtual Tour'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDirections(building);
                    },
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Directions'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
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

  List<LatLng> _getCampusBoundaryPoints() {
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showDirections(BicolBuildingMarker building) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing directions to ${building.name}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
