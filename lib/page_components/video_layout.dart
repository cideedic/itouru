import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

class VideoLayout extends StatelessWidget {
  final List<String> videoUrls;
  final PageController? pageController;

  const VideoLayout({super.key, required this.videoUrls, this.pageController});

  @override
  Widget build(BuildContext context) {
    if (videoUrls.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            videoUrls.length == 1 ? 'VIDEO' : 'VIDEOS',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A31C8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          videoUrls.length == 1
              ? _buildSingleVideo(context)
              : _buildVideoCarousel(context),
        ],
      ),
    );
  }

  Widget _buildSingleVideo(BuildContext context) {
    return GestureDetector(
      onTap: () => _showVideoDialog(context, videoUrls[0], 0),
      child: Container(
        height: 200,
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
          child: VideoThumbnail(videoUrl: videoUrls[0]),
        ),
      ),
    );
  }

  Widget _buildVideoCarousel(BuildContext context) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: pageController,
        scrollDirection: Axis.horizontal,
        itemCount: null,
        itemBuilder: (context, index) {
          final actualIndex = index % videoUrls.length;
          return _buildVideoCarouselItem(context, actualIndex, index);
        },
      ),
    );
  }

  Widget _buildVideoCarouselItem(
    BuildContext context,
    int actualIndex,
    int virtualIndex,
  ) {
    if (pageController == null) {
      return _buildVideoItem(context, actualIndex);
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
      child: _buildVideoItem(context, actualIndex),
    );
  }

  Widget _buildVideoItem(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => _showVideoDialog(context, videoUrls[index], index),
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
          child: VideoThumbnail(videoUrl: videoUrls[index]),
        ),
      ),
    );
  }

  void _showVideoDialog(
    BuildContext context,
    String videoUrl,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      builder: (context) => VideoPlayerCarouselDialog(
        videoUrls: videoUrls,
        initialIndex: initialIndex,
      ),
    );
  }
}

// Video Thumbnail Widget
class VideoThumbnail extends StatefulWidget {
  final String videoUrl;

  const VideoThumbnail({super.key, required this.videoUrl});

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeThumbnail();
  }

  Future<void> _initializeThumbnail() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _controller.initialize();
      await _controller.seekTo(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_hasError)
          Container(
            color: Colors.black,
            child: Center(
              child: Icon(
                Icons.video_library,
                size: 80,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          )
        else if (!_isInitialized)
          Container(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(color: const Color(0xFF1A31C8)),
            ),
          )
        else
          VideoPlayer(_controller),
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
        Center(
          child: Icon(
            Icons.play_circle_outline,
            size: 80,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

// Video Player Carousel Dialog Widget
class VideoPlayerCarouselDialog extends StatefulWidget {
  final List<String> videoUrls;
  final int initialIndex;

  const VideoPlayerCarouselDialog({
    super.key,
    required this.videoUrls,
    required this.initialIndex,
  });

  @override
  State<VideoPlayerCarouselDialog> createState() =>
      _VideoPlayerCarouselDialogState();
}

class _VideoPlayerCarouselDialogState extends State<VideoPlayerCarouselDialog> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, bool> _initialized = {};
  final Map<int, bool> _errors = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeVideo(_currentIndex);
  }

  Future<void> _initializeVideo(int index) async {
    if (_controllers.containsKey(index)) return;

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrls[index]),
      );
      _controllers[index] = controller;
      await controller.initialize();

      if (mounted) {
        setState(() {
          _initialized[index] = true;
          _errors[index] = false;
        });

        if (index == _currentIndex) {
          controller.play();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errors[index] = true;
        });
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _nextVideo() {
    if (_currentIndex < widget.videoUrls.length - 1) {
      _controllers[_currentIndex]?.pause();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousVideo() {
    if (_currentIndex > 0) {
      _controllers[_currentIndex]?.pause();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _controllers[_currentIndex]?.pause();
                _currentIndex = index;
                _initializeVideo(index);
                _controllers[index]?.play();
              });
            },
            itemCount: widget.videoUrls.length,
            itemBuilder: (context, index) {
              return Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildVideoPlayer(index),
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
                    onPressed: _previousVideo,
                  ),
                ),
              ),
            ),
          // Next button
          if (_currentIndex < widget.videoUrls.length - 1)
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
                    onPressed: _nextVideo,
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
          if (widget.videoUrls.length > 1)
            Positioned(
              bottom: 60,
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
                    '${_currentIndex + 1} / ${widget.videoUrls.length}',
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

  Widget _buildVideoPlayer(int index) {
    final controller = _controllers[index];
    final isInitialized = _initialized[index] ?? false;
    final hasError = _errors[index] ?? false;

    if (hasError) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              'Error loading video',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (!isInitialized || controller == null) {
      return Container(
        padding: const EdgeInsets.all(60),
        child: CircularProgressIndicator(color: const Color(0xFF1A31C8)),
      );
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(controller),
          GestureDetector(
            onTap: () {
              setState(() {
                if (controller.value.isPlaying) {
                  controller.pause();
                } else {
                  controller.play();
                }
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: AnimatedOpacity(
                  opacity: controller.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: const Color(0xFF1A31C8),
                bufferedColor: Colors.grey,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
