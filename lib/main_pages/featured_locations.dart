import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'dart:async';
import 'package:itouru/college_content_pages/content.dart';
import 'package:itouru/building_content_pages/content.dart';
import 'package:itouru/page_components/loading_widget.dart';

// Global singleton to cache featured locations across the entire app
class FeaturedLocationsCache {
  static final FeaturedLocationsCache _instance =
      FeaturedLocationsCache._internal();
  factory FeaturedLocationsCache() => _instance;
  FeaturedLocationsCache._internal();

  List<Map<String, dynamic>>? _cachedLocations;
  Future<List<Map<String, dynamic>>>? _loadingFuture;
  bool _isPreloaded = false;

  bool get hasData => _cachedLocations != null && _isPreloaded;
  List<Map<String, dynamic>>? get data => _cachedLocations;

  Future<List<Map<String, dynamic>>> loadLocations(BuildContext context) async {
    // If already loaded, return cached data
    if (_cachedLocations != null && _isPreloaded) {
      print('✅ Using cached featured locations');
      return _cachedLocations!;
    }

    // If currently loading, return the existing future
    if (_loadingFuture != null) {
      print('⏳ Already loading, waiting for completion...');
      return _loadingFuture!;
    }

    // Start loading
    print('🔄 Starting fresh load of featured locations...');
    _loadingFuture = _performLoad(context);

    try {
      final result = await _loadingFuture!;
      _cachedLocations = result;
      return result;
    } finally {
      _loadingFuture = null;
    }
  }

  Future<List<Map<String, dynamic>>> _performLoad(BuildContext context) async {
    final supabase = Supabase.instance.client;
    List<Map<String, dynamic>> allLocations = [];

    try {
      // 1. Fetch random 3 Colleges
      print('📚 Fetching colleges...');
      final allColleges = await supabase
          .from('College')
          .select('college_id, college_name, college_abbreviation');

      final shuffledColleges = List<Map<String, dynamic>>.from(allColleges);
      shuffledColleges.shuffle(Random());
      final collegesResponse = shuffledColleges.take(3).toList();

      for (var college in collegesResponse) {
        final collegeId = college['college_id'];
        final collegeName = college['college_name'] as String;
        final collegeAbbreviation = college['college_abbreviation'] as String?;

        final collegeFolderName = collegeName
            .toLowerCase()
            .replaceAll(' ', '-')
            .replaceAll('college of', 'college-of')
            .trim();

        final abbreviationFolderName = collegeAbbreviation
            ?.toLowerCase()
            .replaceAll(' ', '-')
            .trim();

        List<String> possibleFolderNames = [];
        if (collegeFolderName.isNotEmpty) {
          possibleFolderNames.add(collegeFolderName);
        }
        if (abbreviationFolderName != null &&
            abbreviationFolderName.isNotEmpty &&
            abbreviationFolderName != collegeFolderName) {
          possibleFolderNames.add(abbreviationFolderName);
        }

        String? imageUrl = await _findImageForLocation(
          possibleFolderNames,
          supabase,
        );

        allLocations.add({
          'id': collegeId,
          'name': collegeName,
          'abbreviation': collegeAbbreviation,
          'description':
              'Academic college offering various programs and courses',
          'image': imageUrl,
          'category': 'College',
          'itemType': 'marker',
        });
      }

      // 2. Fetch random 3 Regular Buildings
      print('🏢 Fetching buildings...');
      final allBuildings = await supabase
          .from('Building')
          .select('building_id, building_name, building_nickname')
          .neq('building_type', 'Landmark')
          .neq('building_type', 'Facility');

      final shuffledBuildings = List<Map<String, dynamic>>.from(allBuildings);
      shuffledBuildings.shuffle(Random());

      final buildingsResponse = shuffledBuildings
          .where((building) {
            final name = building['building_name'];
            return name != null && (name as String).length < 20;
          })
          .take(3)
          .toList();

      for (var building in buildingsResponse) {
        final buildingId = building['building_id'];
        final buildingName = building['building_name'] as String;
        final buildingNickname = building['building_nickname'] as String?;

        final buildingFolderName = buildingName
            .toLowerCase()
            .replaceAll('.', '')
            .replaceAll(' ', '-')
            .trim();

        final nicknameFolderName = buildingNickname
            ?.toLowerCase()
            .replaceAll('.', '')
            .replaceAll(' ', '-')
            .trim();

        List<String> possibleFolderNames = [];
        if (buildingFolderName.isNotEmpty) {
          possibleFolderNames.add(buildingFolderName);
        }
        if (nicknameFolderName != null &&
            nicknameFolderName.isNotEmpty &&
            nicknameFolderName != buildingFolderName) {
          possibleFolderNames.add(nicknameFolderName);
        }

        String? imageUrl = await _findImageForLocation(
          possibleFolderNames,
          supabase,
        );

        allLocations.add({
          'id': buildingId,
          'name': buildingName,
          'nickname': buildingNickname,
          'description':
              buildingNickname ?? 'Academic and administrative building',
          'image': imageUrl,
          'category': 'Building',
          'itemType': 'building',
        });
      }

      // 3. Fetch random 3 Landmarks
      print('🏛️ Fetching landmarks...');
      final allLandmarks = await supabase
          .from('Building')
          .select('building_id, building_name, building_nickname')
          .eq('building_type', 'Landmark');

      final shuffledLandmarks = List<Map<String, dynamic>>.from(allLandmarks);
      shuffledLandmarks.shuffle(Random());

      final landmarksResponse = shuffledLandmarks
          .where((landmark) {
            final name = landmark['building_name'];
            return name != null && (name as String).length < 20;
          })
          .take(3)
          .toList();

      for (var landmark in landmarksResponse) {
        final landmarkId = landmark['building_id'];
        final landmarkName = landmark['building_name'] as String;
        final landmarkNickname = landmark['building_nickname'] as String?;

        final landmarkFolderName = landmarkName
            .toLowerCase()
            .replaceAll('.', '')
            .replaceAll(' ', '-')
            .trim();

        final nicknameFolderName = landmarkNickname
            ?.toLowerCase()
            .replaceAll('.', '')
            .replaceAll(' ', '-')
            .trim();

        List<String> possibleFolderNames = [];
        if (landmarkFolderName.isNotEmpty) {
          possibleFolderNames.add(landmarkFolderName);
        }
        if (nicknameFolderName != null &&
            nicknameFolderName.isNotEmpty &&
            nicknameFolderName != landmarkFolderName) {
          possibleFolderNames.add(nicknameFolderName);
        }

        String? imageUrl = await _findImageForLocation(
          possibleFolderNames,
          supabase,
        );

        allLocations.add({
          'id': landmarkId,
          'name': landmarkName,
          'nickname': landmarkNickname,
          'description':
              landmarkNickname ?? 'Campus landmark and point of interest',
          'image': imageUrl,
          'category': 'Landmark',
          'itemType': 'marker',
        });
      }

      print('✅ Loaded ${allLocations.length} featured locations');

      // Preload all images
      if (context.mounted) {
        print('🖼️ Preloading all images...');
        await _preloadAllImages(allLocations, context);
        _isPreloaded = true;
        print('✅ All images preloaded successfully!');
      }

      return allLocations;
    } catch (e) {
      print('❌ Error loading featured locations: $e');
      return [];
    }
  }

  Future<String?> _findImageForLocation(
    List<String> possibleFolderNames,
    SupabaseClient supabase,
  ) async {
    for (var folderName in possibleFolderNames) {
      try {
        final imagesResponse = await supabase
            .from('storage_objects_snapshot')
            .select('name, filename')
            .eq('bucket_id', 'images')
            .eq('folder', folderName)
            .order('filename', ascending: true);

        if (imagesResponse.isNotEmpty) {
          for (var imageData in imagesResponse) {
            final imagePath = imageData['name'] as String;
            final filename = imageData['filename'] as String;

            if (filename != '.emptyFolderPlaceholder' &&
                !filename.contains('_logo')) {
              final imageUrl = supabase.storage
                  .from('images')
                  .getPublicUrl(imagePath);
              print('✅ Found image in "$folderName": $imageUrl');
              return imageUrl;
            }
          }
        }
      } catch (e) {
        print('⚠️ No images in folder "$folderName"');
      }
    }
    return null;
  }

  Future<void> _preloadAllImages(
    List<Map<String, dynamic>> locations,
    BuildContext context,
  ) async {
    if (!context.mounted) return;

    final List<Future<void>> preloadFutures = [];

    for (var location in locations) {
      final imageUrl = location['image'] as String?;
      if (imageUrl != null) {
        preloadFutures.add(
          precacheImage(NetworkImage(imageUrl), context).catchError((error) {
            print('⚠️ Failed to preload image: $imageUrl');
            return null;
          }),
        );
      }
    }

    await Future.wait(preloadFutures);
  }
}

class FeaturedLocationsSection extends StatefulWidget {
  final double height;

  const FeaturedLocationsSection({super.key, required this.height});

  @override
  State<FeaturedLocationsSection> createState() =>
      _FeaturedLocationsSectionState();
}

class _FeaturedLocationsSectionState extends State<FeaturedLocationsSection> {
  late PageController _featuredLocationsController;
  final _cache = FeaturedLocationsCache();

  List<Map<String, dynamic>> featuredLocations = [];
  bool _isLoading = true;
  int _currentLocationIndex = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _featuredLocationsController = PageController(initialPage: 0);
    _loadLocations();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _featuredLocationsController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    if (!mounted) return;

    // Check if already cached
    if (_cache.hasData) {
      setState(() {
        featuredLocations = _cache.data!;
        _isLoading = false;
      });
      _setupCarousel();
      return;
    }

    // Load from cache (which will fetch if needed)
    try {
      final locations = await _cache.loadLocations(context);

      if (!mounted) return;

      setState(() {
        featuredLocations = locations;
        _isLoading = false;
      });

      _setupCarousel();
    } catch (e) {
      print('❌ Error in _loadLocations: $e');
      if (!mounted) return;

      setState(() {
        featuredLocations = [];
        _isLoading = false;
      });
    }
  }

  void _setupCarousel() {
    if (featuredLocations.isNotEmpty && mounted) {
      _featuredLocationsController = PageController(
        initialPage: 5000 * featuredLocations.length,
      );
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (featuredLocations.isEmpty || !mounted) {
        timer.cancel();
        return;
      }

      if (!_featuredLocationsController.hasClients) {
        return;
      }

      final currentPage = _featuredLocationsController.page;
      if (currentPage == null) {
        return;
      }

      final nextPage = currentPage.round() + 1;

      _featuredLocationsController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onLocationExplore() {
    if (featuredLocations.isEmpty ||
        _currentLocationIndex >= featuredLocations.length) {
      return;
    }

    final location = featuredLocations[_currentLocationIndex];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange[400]!, width: 1),
                  ),
                  child: Text(
                    location['category'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  location['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                if (location['abbreviation'] != null ||
                    location['nickname'] != null)
                  Text(
                    location['abbreviation'] ?? location['nickname'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToDetails();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text(
                          'View Details',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
      },
    );
  }

  void _navigateToDetails() {
    if (featuredLocations.isEmpty ||
        _currentLocationIndex >= featuredLocations.length) {
      return;
    }

    final location = featuredLocations[_currentLocationIndex];
    final locationId = location['id'] as int;
    final locationName = location['name'] as String;
    final category = location['category'] as String;

    if (category == 'College') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CollegeDetailsPage(
            collegeId: locationId,
            collegeName: locationName,
            title: location['name'] ?? locationName,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BuildingDetailsPage(
            buildingId: locationId,
            buildingName: locationName,
            title: location['name'] ?? locationName,
          ),
        ),
      );
    }
  }

  void _onLocationInfo() {
    if (featuredLocations.isEmpty ||
        _currentLocationIndex >= featuredLocations.length) {
      return;
    }

    final location = featuredLocations[_currentLocationIndex];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange[400]!, width: 1),
                  ),
                  child: Text(
                    location['category'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  location['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                if (location['abbreviation'] != null ||
                    location['nickname'] != null)
                  Text(
                    location['abbreviation'] ?? location['nickname'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _onLocationExplore();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text(
                          'View on Map',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading widget while initially loading
    if (_isLoading) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: LoadingScreen.circular(
            title: 'Loading Featured Locations',
            subtitle: 'Preparing your experience...',
            primaryColor: Colors.orange[400],
            backgroundColor: const Color.fromARGB(255, 0, 1, 46),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: _featuredLocationsController,
              onPageChanged: (index) {
                if (featuredLocations.isEmpty) return;

                setState(() {
                  _currentLocationIndex = index % featuredLocations.length;
                });

                if (mounted) {
                  _startAutoScroll();
                }
              },
              itemCount: featuredLocations.isEmpty
                  ? 1
                  : featuredLocations.length * 10000,
              itemBuilder: (context, index) {
                if (featuredLocations.isEmpty) {
                  return Container(
                    color: Colors.grey[800],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 80,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No featured locations available',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final actualIndex = index % featuredLocations.length;
                final location = featuredLocations[actualIndex];
                final imageUrl = location['image'] as String?;

                return Stack(
                  children: [
                    if (imageUrl != null)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[400],
                            child: Center(
                              child: Icon(
                                Icons.location_city,
                                size: 80,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: Colors.grey[400],
                        child: Center(
                          child: Icon(
                            Icons.location_city,
                            size: 80,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color.fromARGB(
                              255,
                              0,
                              1,
                              46,
                            ).withValues(alpha: 0.1),
                            const Color.fromARGB(
                              255,
                              0,
                              1,
                              46,
                            ).withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _onLocationExplore,
                        borderRadius: BorderRadius.circular(30),
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _onLocationInfo,
                        borderRadius: BorderRadius.circular(30),
                        child: Icon(
                          Icons.map_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(
                          255,
                          199,
                          152,
                          76,
                        ).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color.fromARGB(255, 199, 152, 76),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        featuredLocations.isNotEmpty
                            ? featuredLocations[_currentLocationIndex]['category']
                            : '',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(255, 199, 152, 76),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      featuredLocations.isNotEmpty
                          ? featuredLocations[_currentLocationIndex]['name']
                          : '',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: List.generate(
                        featuredLocations.length,
                        (index) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: index == _currentLocationIndex ? 24 : 8,
                          height: 4,
                          decoration: BoxDecoration(
                            color: index == _currentLocationIndex
                                ? Colors.cyan
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
