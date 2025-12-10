import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GridImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final Color? accentColor;
  final bool showGalleryText;

  const GridImageGallery({
    super.key,
    required this.imageUrls,
    this.accentColor,
    this.showGalleryText = true,
  });

  @override
  State<GridImageGallery> createState() => _GridImageGalleryState();
}

class _GridImageGalleryState extends State<GridImageGallery> {
  int _currentBatch = 0;
  static const int _imagesPerBatch = 4; // 2x2 grid

  int get _totalBatches => (widget.imageUrls.length / _imagesPerBatch).ceil();

  List<String> get _currentBatchImages {
    final startIndex = _currentBatch * _imagesPerBatch;
    final endIndex = (startIndex + _imagesPerBatch).clamp(
      0,
      widget.imageUrls.length,
    );
    return widget.imageUrls.sublist(startIndex, endIndex);
  }

  void _nextBatch() {
    if (_currentBatch < _totalBatches - 1) {
      setState(() {
        _currentBatch++;
      });
    }
  }

  void _previousBatch() {
    if (_currentBatch > 0) {
      setState(() {
        _currentBatch--;
      });
    }
  }

  @override
  void didUpdateWidget(GridImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls != widget.imageUrls) {
      setState(() {
        _currentBatch = 0;
      });
    }
  }

  void _showImageViewer(int imageIndex) {
    final globalIndex = (_currentBatch * _imagesPerBatch) + imageIndex;
    showDialog(
      context: context,
      builder: (context) => FullImageViewer(
        imageUrls: widget.imageUrls,
        initialIndex: globalIndex,
        accentColor: widget.accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    final effectiveColor = widget.accentColor ?? const Color(0xFF1A31C8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (widget.showGalleryText)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GALLERY',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: effectiveColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: effectiveColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.imageUrls.length} ${widget.imageUrls.length == 1 ? 'Image' : 'Images'}',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: effectiveColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 2x2 Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _currentBatchImages.length,
            itemBuilder: (context, index) {
              return _buildGridItem(index);
            },
          ),

          // Batch Navigation
          if (_totalBatches > 1) ...[
            const SizedBox(height: 16),

            // Dot Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _totalBatches,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: index == _currentBatch ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == _currentBatch
                        ? effectiveColor
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Arrow Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous Arrow Button
                Container(
                  decoration: BoxDecoration(
                    color: _currentBatch > 0
                        ? effectiveColor
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                    boxShadow: _currentBatch > 0
                        ? [
                            BoxShadow(
                              color: effectiveColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: IconButton(
                    onPressed: _currentBatch > 0 ? _previousBatch : null,
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),

                const SizedBox(width: 24),

                // Next Arrow Button
                Container(
                  decoration: BoxDecoration(
                    color: _currentBatch < _totalBatches - 1
                        ? effectiveColor
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                    boxShadow: _currentBatch < _totalBatches - 1
                        ? [
                            BoxShadow(
                              color: effectiveColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: IconButton(
                    onPressed: _currentBatch < _totalBatches - 1
                        ? _nextBatch
                        : null,
                    icon: const Icon(Icons.arrow_forward_ios, size: 20),
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridItem(int index) {
    final effectiveColor = widget.accentColor ?? const Color(0xFF1A31C8);

    return GestureDetector(
      onTap: () => _showImageViewer(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                _currentBatchImages[index],
                fit: BoxFit.cover,
                cacheWidth: 400,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        color: effectiveColor,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 30,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
              // Hover overlay effect
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Full Image Viewer Dialog
class FullImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final Color? accentColor;

  const FullImageViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    this.accentColor,
  });

  @override
  State<FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<FullImageViewer> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _nextImage() {
    if (_currentIndex < widget.imageUrls.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.accentColor ?? const Color(0xFF1A31C8);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          // Main Image
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.imageUrls[_currentIndex],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 300,
                      height: 300,
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: effectiveColor,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 300,
                      height: 300,
                      color: Colors.black,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Previous Button
          if (_currentIndex > 0)
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _previousImage,
                  ),
                ),
              ),
            ),

          // Next Button
          if (_currentIndex < widget.imageUrls.length - 1)
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _nextImage,
                  ),
                ),
              ),
            ),

          // Close Button
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Image Counter
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_currentIndex + 1}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' / ${widget.imageUrls.length}',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
