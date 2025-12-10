import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:math' as math;

/// Manages nearby location images during virtual tour navigation
class NearbyImageManager extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  // Active nearby images within radius
  final Map<int, NearbyLocationImage> _nearbyImages = {};

  // Cache for fetched images to avoid re-fetching
  final Map<int, String?> _imageCache = {};

  // Track which locations we're currently processing
  Set<int> processingIds = {};

  // Constants
  static const double triggerRadius = 40.0; // meters

  Map<int, NearbyLocationImage> get nearbyImages => _nearbyImages;

  /// Update user location and check for nearby buildings/markers
  Future<void> updateLocation(
    LatLng userLocation,
    List<dynamic> allBuildings, // List of BicolBuildingPolygon
    List<dynamic> allMarkers, { // List of BicolMarker
    bool clearOnUpdate = false,
    Set<int>? excludedBuildingIds, //  IDs to exclude from showing
  }) async {
    debugPrint(
      '🔍 NearbyImageManager: Updating with ${excludedBuildingIds?.length ?? 0} excluded buildings',
    );
    if (clearOnUpdate) {
      _nearbyImages.clear();
    }

    Set<int> currentNearby = {};

    // Check buildings
    for (var building in allBuildings) {
      final buildingId = building.buildingId as int?;
      if (buildingId == null) continue;

      // Skip if this building is excluded
      if (excludedBuildingIds != null &&
          excludedBuildingIds.contains(buildingId)) {
        continue;
      }

      final distance = _calculateDistance(
        userLocation,
        building.getCenterPoint(),
      );

      if (distance <= triggerRadius) {
        currentNearby.add(buildingId);

        // Add new image if not already showing
        if (!_nearbyImages.containsKey(buildingId)) {
          await _addNearbyImage(buildingId, building);
        }
      }
    }

    // Check markers
    for (var marker in allMarkers) {
      final markerId = marker.buildingId as int?;
      if (markerId == null) continue;

      // Skip if this marker is excluded (e.g., current destination)
      if (excludedBuildingIds != null &&
          excludedBuildingIds.contains(markerId)) {
        continue;
      }

      final distance = _calculateDistance(userLocation, marker.position);

      if (distance <= triggerRadius) {
        currentNearby.add(markerId);

        if (!_nearbyImages.containsKey(markerId)) {
          await _addNearbyImage(markerId, marker, isMarker: true);
        }
      }
    }

    notifyListeners();
  }

  /// Add a new nearby image
  Future<void> _addNearbyImage(
    int id,
    dynamic location, {
    bool isMarker = false,
  }) async {
    // Prevent duplicate fetching
    if (processingIds.contains(id)) return;
    processingIds.add(id);

    try {
      // Check cache first
      if (_imageCache.containsKey(id)) {
        final cachedUrl = _imageCache[id];
        if (cachedUrl != null) {
          _nearbyImages[id] = NearbyLocationImage(
            id: id,
            location: isMarker ? location.position : location.getCenterPoint(),
            imageUrl: cachedUrl,
            name: _getLocationName(location),
            isMarker: isMarker,
          );
          notifyListeners();
          return;
        }
      }

      // Fetch building data from database to get the nickname
      String? databaseNickname;
      if (!isMarker) {
        final buildingId = location.buildingId as int?;
        if (buildingId != null) {
          try {
            final response = await supabase
                .from('Building')
                .select('building_nickname')
                .eq('building_id', buildingId)
                .maybeSingle();

            if (response != null) {
              databaseNickname = response['building_nickname'] as String?;
              debugPrint(
                '🔍 Fetched nickname from DB: $databaseNickname for building ID: $buildingId',
              );
            }
          } catch (e) {
            debugPrint('⚠️ Error fetching nickname from database: $e');
          }
        }
      }

      // Fetch first image
      final imageUrl = await _fetchFirstImage(
        location,
        isMarker: isMarker,
        databaseNickname: databaseNickname,
      );

      if (imageUrl != null) {
        _imageCache[id] = imageUrl;
        _nearbyImages[id] = NearbyLocationImage(
          id: id,
          location: isMarker ? location.position : location.getCenterPoint(),
          imageUrl: imageUrl,
          name: _getLocationName(location),
          isMarker: isMarker,
        );
        debugPrint('✅ Added nearby image for: ${_getLocationName(location)}');
        notifyListeners();
      } else {
        _imageCache[id] = null; // Cache null to avoid re-fetching
        debugPrint('⚠️ No image found for: ${_getLocationName(location)}');
      }
    } finally {
      processingIds.remove(id);
    }
  }

  /// Get location name safely
  String _getLocationName(dynamic location) {
    try {
      if (location.displayName != null) return location.displayName;
      if (location.name != null) return location.name;
      return 'Location';
    } catch (e) {
      return 'Location';
    }
  }

  /// Fetch first image from storage (exact same logic as BuildingDetailsPage)
  Future<String?> _fetchFirstImage(
    dynamic location, {
    bool isMarker = false,
    String? databaseNickname,
  }) async {
    try {
      String? buildingName;
      String? nickname;

      // Extract name based on type
      if (isMarker) {
        buildingName = location.name;
        try {
          nickname = location.databaseName;
        } catch (e) {
          nickname = null;
        }
      } else {
        try {
          buildingName = location.name;
        } catch (e) {
          buildingName = null;
        }
        nickname = databaseNickname;
      }

      debugPrint('📝 Building: $buildingName, Nickname: $nickname');

      if (buildingName == null) return null;

      String normalizeFolderName(String name) {
        return name
            .toLowerCase()
            .replaceAll('.', '')
            .replaceAll("'", '')
            .replaceAll(' ', '-')
            .trim();
      }

      List<String> possibleFolderNames = [];

      final fullName = normalizeFolderName(buildingName);
      possibleFolderNames.add(fullName);

      if (fullName.startsWith('bicol-university-')) {
        final withoutPrefix = fullName.replaceFirst('bicol-university-', '');
        if (withoutPrefix.isNotEmpty &&
            !possibleFolderNames.contains(withoutPrefix)) {
          possibleFolderNames.add(withoutPrefix);
        }
      }

      if (nickname != null &&
          nickname.toString().trim().isNotEmpty &&
          nickname != buildingName) {
        final normalizedNickname = normalizeFolderName(nickname);
        if (!possibleFolderNames.contains(normalizedNickname)) {
          possibleFolderNames.add(normalizedNickname);
        }

        if (normalizedNickname.startsWith('bicol-university-')) {
          final withoutPrefix = normalizedNickname.replaceFirst(
            'bicol-university-',
            '',
          );
          if (withoutPrefix.isNotEmpty &&
              !possibleFolderNames.contains(withoutPrefix)) {
            possibleFolderNames.add(withoutPrefix);
          }
        }
      }

      debugPrint(
        '🔍 Searching for images in folders: $possibleFolderNames for: $buildingName',
      );

      for (var folderName in possibleFolderNames) {
        try {
          final response = await supabase
              .from('storage_objects_snapshot')
              .select('name, filename')
              .eq('bucket_id', 'images')
              .eq('folder', folderName)
              .order('filename', ascending: true)
              .limit(10);

          if (response.isNotEmpty) {
            debugPrint(
              '✅ Found ${response.length} files in folder: $folderName',
            );

            for (var imageData in response) {
              final filename = imageData['filename'] as String;

              if (filename == '.emptyFolderPlaceholder' ||
                  filename.endsWith('.emptyFolderPlaceholder') ||
                  filename.contains('_logo')) {
                continue;
              }

              final imagePath = imageData['name'] as String;
              final imageUrl = supabase.storage
                  .from('images')
                  .getPublicUrl(imagePath);
              debugPrint('🎉 Found image: $filename for $buildingName');
              return imageUrl;
            }
          }
        } catch (e) {
          continue;
        }
      }

      debugPrint('❌ No images found in any folder for: $buildingName');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching image for location: $e');
      return null;
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000;

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

  /// Remove a specific nearby image by building ID
  void removeImage(int buildingId) {
    if (_nearbyImages.containsKey(buildingId)) {
      _nearbyImages.remove(buildingId);
      debugPrint('🗑️ Removed nearby image for building ID: $buildingId');
      notifyListeners();
    }
  }

  /// Clear all nearby images and cache
  void clear() {
    _nearbyImages.clear();
    notifyListeners();
  }

  /// Clear only cache (keep active images)
  void clearCache() {
    _imageCache.clear();
  }
}

/// Represents a nearby location with its image
class NearbyLocationImage {
  final int id;
  final LatLng location;
  final String imageUrl;
  final String name;
  final bool isMarker;

  NearbyLocationImage({
    required this.id,
    required this.location,
    required this.imageUrl,
    required this.name,
    required this.isMarker,
  });
}

/// Animated popup widget for nearby location images
class NearbyImagePopup extends StatefulWidget {
  final NearbyLocationImage imageData;
  final VoidCallback onTap;

  const NearbyImagePopup({
    super.key,
    required this.imageData,
    required this.onTap,
  });

  @override
  State<NearbyImagePopup> createState() => _NearbyImagePopupState();
}

class _NearbyImagePopupState extends State<NearbyImagePopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _slideAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_slideAnimation.value),
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.orange, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      widget.imageData.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.orange,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 30,
                          ),
                        );
                      },
                    ),
                    // Tap indicator
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.zoom_in,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Add spacing below the image
          SizedBox(height: 20), // Adjust this value for more/less space
        ],
      ),
    );
  }
}

/// Full screen image viewer as modal overlay
class ImageFullScreenViewer extends StatelessWidget {
  final String imageUrl;
  final String locationName;

  const ImageFullScreenViewer({
    super.key,
    required this.imageUrl,
    required this.locationName,
  });

  static void show(BuildContext context, String imageUrl, String locationName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) =>
          ImageFullScreenViewer(imageUrl: imageUrl, locationName: locationName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20),
      child: Stack(
        children: [
          // Main image container
          Center(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              locationName,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close, color: Colors.grey[700]),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              padding: EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Image with zoom
                    Flexible(
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              padding: EdgeInsets.all(60),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.orange,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              padding: EdgeInsets.all(60),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.grey[400],
                                    size: 48,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Footer hint
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(
                          top: BorderSide(color: Colors.grey[200]!, width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.zoom_in,
                            color: Colors.grey[600],
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Pinch to zoom • Drag to pan',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
