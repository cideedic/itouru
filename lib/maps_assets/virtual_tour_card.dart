import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../maps_assets/virtual_tour_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class VirtualTourStopCard extends StatefulWidget {
  final VirtualTourStop stop;
  final int totalStops;
  final bool isFirstStop;
  final bool isLastStop;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onEndTour;

  const VirtualTourStopCard({
    super.key,
    required this.stop,
    required this.totalStops,
    required this.isFirstStop,
    required this.isLastStop,
    required this.onNext,
    required this.onPrevious,
    required this.onEndTour,
  });

  @override
  State<VirtualTourStopCard> createState() => _VirtualTourStopCardState();
}

class _VirtualTourStopCardState extends State<VirtualTourStopCard> {
  static final _supabase = Supabase.instance.client;

  List<String> _imageUrls = [];
  bool _isLoadingImages = true;
  int _currentImageIndex = 0;
  Timer? _autoPlayTimer;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _loadBuildingImages();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadBuildingImages() async {
    try {
      // Get building name from the stop
      final buildingName = widget.stop.buildingName;
      final buildingNickname = widget.stop.buildingNickname;

      List<String> possibleFolderNames = [];

      // Add building name as folder name
      final buildingFolderName = buildingName
          .toLowerCase()
          .replaceAll('.', '')
          .replaceAll(' ', '-')
          .trim();
      possibleFolderNames.add(buildingFolderName);

      // Add nickname if available
      if (buildingNickname.isNotEmpty) {
        final nicknameFolderName = buildingNickname
            .toLowerCase()
            .replaceAll('.', '')
            .replaceAll(' ', '-')
            .trim();
        if (!possibleFolderNames.contains(nicknameFolderName)) {
          possibleFolderNames.add(nicknameFolderName);
        }
      }

      List<dynamic> imagesResponse = [];

      // Try each possible folder name
      for (var folderName in possibleFolderNames) {
        final response = await _supabase
            .from('storage_objects_snapshot')
            .select('name, filename')
            .eq('bucket_id', 'images')
            .eq('folder', folderName)
            .order('filename', ascending: true)
            .limit(5);

        if (response.isNotEmpty) {
          imagesResponse = response;
          break;
        }
      }

      if (!mounted) return;

      List<String> imageUrls = [];

      for (var imageData in imagesResponse) {
        final imagePath = imageData['name'] as String;
        final filename = imageData['filename'] as String;

        // Skip placeholder and logo files
        if (filename == '.emptyFolderPlaceholder' ||
            imagePath.endsWith('.emptyFolderPlaceholder') ||
            filename.contains('_logo')) {
          continue;
        }

        final publicUrl = _supabase.storage
            .from('images')
            .getPublicUrl(imagePath);
        imageUrls.add(publicUrl);
      }

      // Limit to 3 images
      if (imageUrls.length > 3) {
        imageUrls = imageUrls.sublist(0, 3);
      }

      if (!mounted) return;

      setState(() {
        _imageUrls = imageUrls;
        _isLoadingImages = false;
      });

      // Start auto-play if multiple images
      if (imageUrls.length > 1) {
        _pageController = PageController();
        _startAutoPlay();
      }
    } catch (e) {
      print('❌ Error loading building images: $e');
      if (!mounted) return;
      setState(() => _isLoadingImages = false);
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || _pageController == null) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _imageUrls.length;
      });

      _pageController?.animateToPage(
        _currentImageIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with progress
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[400]!, Colors.orange[600]!],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stop ${widget.stop.stopNumber}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.stop.stopNumber} of ${widget.totalStops}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: widget.stop.stopNumber / widget.totalStops,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Building name
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_city,
                        color: Colors.orange[400],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.stop.buildingName,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.stop.buildingNickname.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.stop.buildingNickname,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Images section
                if (_isLoadingImages)
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF1A31C8),
                        ),
                      ),
                    ),
                  )
                else if (_imageUrls.isNotEmpty)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 180,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _imageUrls.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return Image.network(
                                _imageUrls[index],
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[300],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(
                                        Icons.error_outline,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      if (_imageUrls.length > 1) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_imageUrls.length, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.orange[400]
                                    : Colors.grey[300],
                              ),
                            );
                          }),
                        ),
                      ],
                    ],
                  ),

                // Notes section
                if (widget.stop.notes != null &&
                    widget.stop.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!, width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.stop.notes!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.blue[900],
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Navigation buttons
                if (widget.isLastStop)
                  // Last stop: Finish above Previous (vertical stack)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onEndTour,
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: Text(
                            'Finish Tour',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[500],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.onPrevious,
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: Text(
                            'Previous',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  // Other stops: Previous and Next side by side
                  Row(
                    children: [
                      // Previous button
                      if (!widget.isFirstStop)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onPrevious,
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: Text(
                              'Previous',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                      if (!widget.isFirstStop) const SizedBox(width: 12),

                      // Next button
                      Expanded(
                        flex: widget.isFirstStop ? 2 : 1,
                        child: ElevatedButton.icon(
                          onPressed: widget.onNext,
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: Text(
                            'Next Stop',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                // End tour button (only show if NOT the last stop)
                if (!widget.isLastStop)
                  Center(
                    child: TextButton.icon(
                      onPressed: widget.onEndTour,
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(
                        'End Virtual Tour',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red[400],
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

/// Congratulations dialog shown when tour completes
class TourCompletionDialog extends StatelessWidget {
  final String tourName;
  final int stopsVisited;

  const TourCompletionDialog({
    super.key,
    required this.tourName,
    required this.stopsVisited,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange[400]!, Colors.orange[600]!],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.emoji_events,
                size: 64,
                color: Colors.orange[600],
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Congratulations!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              'You\'ve completed the',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.95),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            Text(
              tourName,
              style: GoogleFonts.poppins(
                fontSize: 17,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$stopsVisited stops visited',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Done button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
