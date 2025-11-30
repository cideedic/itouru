import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryTimeline {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchTimelineData() async {
    try {
      final response = await supabase
          .from('History')
          .select('history_id, title, date, description');

      if (response.isEmpty) {
        return [];
      }

      final data = (response as List).map((item) {
        return {
          'history_id': item['history_id'],
          'title': item['title'] ?? '',
          'date': item['date'] ?? '',
          'description': item['description'] ?? '',
        };
      }).toList();

      data.sort((a, b) {
        try {
          final yearA = _extractFirstYear(a['date']);
          final yearB = _extractFirstYear(b['date']);
          return yearA.compareTo(yearB);
        } catch (e) {
          return 0;
        }
      });

      return data;
    } catch (e) {
      return [];
    }
  }

  int _extractFirstYear(String date) {
    try {
      date = date.trim();

      if (date.contains('-') || date.contains('–')) {
        final parts = date.split(RegExp(r'[-–]'));
        final firstPart = parts[0].trim();

        final yearMatch = RegExp(r'\d{4}').firstMatch(firstPart);
        if (yearMatch != null) {
          return int.parse(yearMatch.group(0)!);
        }
      }

      final parsedDate = DateTime.tryParse(date);
      if (parsedDate != null) {
        return parsedDate.year;
      }

      final yearMatch = RegExp(r'\d{4}').firstMatch(date);
      if (yearMatch != null) {
        return int.parse(yearMatch.group(0)!);
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }

  void showTimelineModal(
    BuildContext context,
    List<Map<String, dynamic>> timelineData,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AnimatedTimelineSheet(timelineData: timelineData),
    );
  }

  String _extractYear(String date) {
    try {
      if (date.contains('-') || date.contains('–')) {
        final parts = date.split(RegExp(r'[-–]'));
        final firstPart = parts[0].trim();

        final yearMatch = RegExp(r'\d{4}').firstMatch(firstPart);
        if (yearMatch != null) {
          return yearMatch.group(0)!;
        }
      }

      if (date.contains('-')) {
        return date.split('-')[0];
      } else if (date.contains('/')) {
        final parts = date.split('/');
        return parts.length == 3 ? parts[2] : date;
      } else if (date.length == 4) {
        return date;
      }

      final yearMatch = RegExp(r'\d{4}').firstMatch(date);
      if (yearMatch != null) {
        return yearMatch.group(0)!;
      }

      return date;
    } catch (e) {
      return date;
    }
  }

  // Enhanced preview timeline with better visuals
  Widget buildPreviewTimeline(
    List<Map<String, dynamic>> timelineData,
    int maxItems,
  ) {
    final previewItems = timelineData.take(maxItems).toList();

    if (previewItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.history_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No timeline data available',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          // Connecting line
          Positioned(
            top: 35,
            left: 40,
            right: 40,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade300, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Timeline items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(previewItems.length, (index) {
              final year = _extractYear(previewItems[index]['date']);
              return Expanded(
                child: Column(
                  children: [
                    // Year badge
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade700,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          year.length > 2
                              ? year.substring(year.length - 2)
                              : year,
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        previewItems[index]['title'],
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// Timeline Sheet
class _AnimatedTimelineSheet extends StatefulWidget {
  final List<Map<String, dynamic>> timelineData;

  const _AnimatedTimelineSheet({required this.timelineData});

  @override
  State<_AnimatedTimelineSheet> createState() => _AnimatedTimelineSheetState();
}

class _AnimatedTimelineSheetState extends State<_AnimatedTimelineSheet>
    with TickerProviderStateMixin {
  late List<AnimationController> _dotControllers;
  late List<AnimationController> _lineControllers;
  late List<AnimationController> _cardControllers;
  late ScrollController _scrollController;

  final List<GlobalKey> _itemKeys = [];
  final Map<int, double> _cardHeights = {};
  final Set<int> _animatedItems = {};
  bool _initialAnimationComplete = false;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _itemKeys.addAll(
      List.generate(widget.timelineData.length, (_) => GlobalKey()),
    );

    _dotControllers = List.generate(
      widget.timelineData.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _lineControllers = List.generate(
      widget.timelineData.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      ),
    );

    _cardControllers = List.generate(
      widget.timelineData.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInitialAnimation();
    });
  }

  void _startInitialAnimation() async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    final visibleIndices = <int>[];

    for (int i = 0; i < _itemKeys.length; i++) {
      final key = _itemKeys[i];
      final itemContext = key.currentContext;

      if (itemContext != null && itemContext.mounted) {
        final box = itemContext.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final position = box.localToGlobal(Offset.zero);
          final screenHeight = MediaQuery.of(itemContext).size.height;

          if (position.dy < screenHeight && position.dy > -box.size.height) {
            visibleIndices.add(i);
          }
        }
      }
    }

    for (int i in visibleIndices) {
      if (!mounted) return;

      _animatedItems.add(i);

      final delay = i * 150;

      Future.delayed(Duration(milliseconds: delay), () {
        if (!mounted) return;
        _dotControllers[i].forward();
      });

      Future.delayed(Duration(milliseconds: delay + 100), () {
        if (!mounted) return;
        _cardControllers[i].forward();
      });

      if (i < widget.timelineData.length - 1) {
        Future.delayed(Duration(milliseconds: delay + 200), () {
          if (!mounted) return;
          _lineControllers[i].forward();
        });
      }
    }

    Future.delayed(
      Duration(milliseconds: visibleIndices.length * 150 + 500),
      () {
        if (!mounted) return;
        _initialAnimationComplete = true;
      },
    );
  }

  void _onScroll() {
    if (!_initialAnimationComplete) return;
    _checkVisibleItems();
  }

  void _checkVisibleItems() {
    for (int i = 0; i < _itemKeys.length; i++) {
      if (_animatedItems.contains(i)) continue;

      final key = _itemKeys[i];
      final context = key.currentContext;

      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final position = box.localToGlobal(Offset.zero);
          final screenHeight = MediaQuery.of(context).size.height;

          if (position.dy < screenHeight * 0.85 &&
              position.dy > -box.size.height) {
            _animateItem(i);
          }
        }
      }
    }
  }

  void _animateItem(int index) async {
    if (_animatedItems.contains(index)) return;

    _animatedItems.add(index);

    _dotControllers[index].forward();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _cardControllers[index].forward();
    });

    if (index < widget.timelineData.length - 1) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        _lineControllers[index].forward();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var controller in _dotControllers) {
      controller.dispose();
    }
    for (var controller in _lineControllers) {
      controller.dispose();
    }
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Enhanced Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade50, Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.history_edu,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BU Timeline',
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${widget.timelineData.length} milestones',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Timeline list
              Expanded(
                child: widget.timelineData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No timeline data available',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: widget.timelineData.length,
                        itemBuilder: (context, index) {
                          final item = widget.timelineData[index];
                          final date = item['date'];
                          final year = _extractYear(date);
                          final isLast =
                              index == widget.timelineData.length - 1;

                          return Container(
                            key: _itemKeys[index],
                            child: _buildAnimatedTimelineItem(
                              item,
                              year,
                              date,
                              index,
                              isLast,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTimelineItem(
    Map<String, dynamic> item,
    String year,
    String date,
    int index,
    bool isLast,
  ) {
    final dotAnimation = CurvedAnimation(
      parent: _dotControllers[index],
      curve: Curves.easeOutBack,
    );

    final lineAnimation = CurvedAnimation(
      parent: _lineControllers[index],
      curve: Curves.easeInOut,
    );

    final cardAnimation = CurvedAnimation(
      parent: _cardControllers[index],
      curve: Curves.easeOut,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced timeline indicator
          SizedBox(
            width: 70,
            child: Column(
              children: [
                // Animated Dot with gradient
                ScaleTransition(
                  scale: dotAnimation,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.orange.shade400,
                          Colors.orange.shade700,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: FadeTransition(
                        opacity: dotAnimation,
                        child: Text(
                          year.length > 2
                              ? year.substring(year.length - 2)
                              : year,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Animated Line
                if (!isLast)
                  AnimatedBuilder(
                    animation: lineAnimation,
                    builder: (context, child) {
                      double lineHeight = _cardHeights[index] ?? 100;

                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 4,
                        height: lineHeight * lineAnimation.value,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade200,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Enhanced Content Card
          Expanded(
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.3, 0),
                end: Offset.zero,
              ).animate(cardAnimation),
              child: FadeTransition(
                opacity: cardAnimation,
                child: _MeasuredCard(
                  index: index,
                  onSizeMeasured: (height) {
                    setState(() {
                      _cardHeights[index] = height + 32;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.orange.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _formatDate(date),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          item['title'],
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        Text(
                          item['description'],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _extractYear(String date) {
    try {
      if (date.contains('-') || date.contains('–')) {
        final parts = date.split(RegExp(r'[-–]'));
        final firstPart = parts[0].trim();

        final yearMatch = RegExp(r'\d{4}').firstMatch(firstPart);
        if (yearMatch != null) {
          return yearMatch.group(0)!;
        }
      }

      if (date.contains('-')) {
        return date.split('-')[0];
      } else if (date.contains('/')) {
        final parts = date.split('/');
        return parts.length == 3 ? parts[2] : date;
      } else if (date.length == 4) {
        return date;
      }

      final yearMatch = RegExp(r'\d{4}').firstMatch(date);
      if (yearMatch != null) {
        return yearMatch.group(0)!;
      }

      return date;
    } catch (e) {
      return date;
    }
  }

  String _formatDate(String date) {
    try {
      if (date.contains('-')) {
        final parsedDate = DateTime.tryParse(date);
        if (parsedDate != null) {
          final months = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
          return '${months[parsedDate.month - 1]} ${parsedDate.day}, ${parsedDate.year}';
        }
      }
      return date;
    } catch (e) {
      return date;
    }
  }
}

class _MeasuredCard extends StatefulWidget {
  final int index;
  final Widget child;
  final Function(double height) onSizeMeasured;

  const _MeasuredCard({
    required this.index,
    required this.child,
    required this.onSizeMeasured,
  });

  @override
  State<_MeasuredCard> createState() => _MeasuredCardState();
}

class _MeasuredCardState extends State<_MeasuredCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureSize();
    });
  }

  void _measureSize() {
    final context = this.context;
    if (!mounted) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      widget.onSizeMeasured(box.size.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
