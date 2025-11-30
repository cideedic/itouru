import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ImageLayout extends StatelessWidget {
  final List<String> imageUrls;
  final PageController? pageController;
  final bool isForMap;
  final bool showGalleryText;
  final Color? buttonColor;

  const ImageLayout({
    super.key,
    required this.imageUrls,
    this.pageController,
    this.showGalleryText = true,
    this.buttonColor,
  }) : isForMap = false;

  const ImageLayout.forMap({
    super.key,
    required this.imageUrls,
    this.pageController,
    this.showGalleryText = true,
    this.buttonColor,
  }) : isForMap = true;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    if (isForMap) {
      return _buildMapImageCarousel(context);
    }

    // Get the effective button color
    final effectiveButtonColor = buttonColor ?? const Color(0xFF1A31C8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Only show header if showGalleryText is true
          if (showGalleryText)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GALLERY',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: effectiveButtonColor,
                    letterSpacing: 1.2,
                  ),
                ),
                if (imageUrls.length > 1)
                  TextButton(
                    onPressed: () => _showAllImagesDialog(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      backgroundColor: effectiveButtonColor.withValues(
                        alpha: 0.1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'View All',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: effectiveButtonColor,
                      ),
                    ),
                  ),
              ],
            ),

          // Add spacing only if header was shown
          if (showGalleryText) const SizedBox(height: 16),

          // Show "View All" button above images if gallery text is hidden
          if (!showGalleryText && imageUrls.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showAllImagesDialog(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    backgroundColor: effectiveButtonColor.withValues(
                      alpha: 0.1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'View All',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: effectiveButtonColor,
                    ),
                  ),
                ),
              ),
            ),

          imageUrls.length == 1
              ? _buildSingleImage(context)
              : _buildImageCarousel(context),
        ],
      ),
    );
  }

  Widget _buildMapImageCarousel(BuildContext context) {
    final controller = pageController ?? PageController();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: controller,
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return _buildMapCarouselItem(context, index);
            },
          ),
        ),
        if (imageUrls.length > 1) ...[
          const SizedBox(height: 12),
          _buildPageIndicator(imageUrls.length, controller),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildMapCarouselItem(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => _showImageDialog(context, index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrls[index],
                fit: BoxFit.cover,
                cacheWidth: 800,
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
                        color: buttonColor ?? const Color(0xFF1A31C8),
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
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.5),
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

  Widget _buildPageIndicator(int count, PageController controller) {
    final effectiveButtonColor = buttonColor ?? const Color(0xFF1A31C8);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            double selectedness = 0.0;
            if (controller.hasClients && controller.position.haveDimensions) {
              final page = controller.page ?? controller.initialPage.toDouble();
              selectedness = 1.0 - (page - index).abs().clamp(0.0, 1.0);
            } else if (index == 0) {
              selectedness = 1.0;
            }
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(
                  Colors.grey[400],
                  effectiveButtonColor,
                  selectedness,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSingleImage(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageDialog(context, 0),
      child: Container(
        height: 325,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrls[0],
                fit: BoxFit.cover,
                cacheWidth: 1200,
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
                        color: buttonColor ?? const Color(0xFF1A31C8),
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
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.5),
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

  Widget _buildImageCarousel(BuildContext context) {
    return SizedBox(
      height: 325,
      child: PageView.builder(
        controller: pageController,
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return _buildCarouselItem(context, index, index);
        },
      ),
    );
  }

  Widget _buildCarouselItem(
    BuildContext context,
    int actualIndex,
    int virtualIndex,
  ) {
    if (pageController == null) {
      return _buildImageItem(context, actualIndex);
    }

    return AnimatedBuilder(
      animation: pageController!,
      builder: (context, child) {
        double scale = 1.0;
        double opacity = 1.0;

        if (pageController!.position.haveDimensions) {
          double page = pageController!.page ?? virtualIndex.toDouble();
          double distance = (page - virtualIndex).abs();

          if (distance < 1.0) {
            scale = 1.0 - (distance * 0.15);
            opacity = 1.0 - (distance * 0.6);
          } else {
            scale = 0.85;
            opacity = 0.4;
          }
        }

        return Center(
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: child,
              ),
            ),
          ),
        );
      },
      child: _buildImageItem(context, actualIndex),
    );
  }

  Widget _buildImageItem(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => _showImageDialog(context, index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrls[index],
                fit: BoxFit.cover,
                cacheWidth: 1200,
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
                        color: buttonColor ?? const Color(0xFF1A31C8),
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
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.5),
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

  void _showImageDialog(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => ImageCarouselDialog(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
        accentColor: buttonColor,
      ),
    );
  }

  void _showAllImagesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          ImageGridDialog(imageUrls: imageUrls, accentColor: buttonColor),
    );
  }
}

// Image Grid Dialog Widget
class ImageGridDialog extends StatelessWidget {
  final List<String> imageUrls;
  final Color? accentColor;

  const ImageGridDialog({super.key, required this.imageUrls, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = accentColor ?? const Color(0xFF1A31C8);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Images (${imageUrls.length})',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => ImageCarouselDialog(
                        imageUrls: imageUrls,
                        initialIndex: index,
                        accentColor: accentColor,
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrls[index],
                        fit: BoxFit.cover,
                        cacheWidth: 400,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
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
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Image Carousel Dialog Widget
class ImageCarouselDialog extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final Color? accentColor;

  const ImageCarouselDialog({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    this.accentColor,
  });

  @override
  State<ImageCarouselDialog> createState() => _ImageCarouselDialogState();
}

class _ImageCarouselDialogState extends State<ImageCarouselDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextImage() {
    if (_currentIndex < widget.imageUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
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
                    ),
                  ),
                ),
              );
            },
          ),
          // Previous button
          if (_currentIndex > 0)
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
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
          // Next button
          if (_currentIndex < widget.imageUrls.length - 1)
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
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
          // Close button
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          // Page indicator
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.imageUrls.length}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
