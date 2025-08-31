// animated_dropdown.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedDropdown extends StatefulWidget {
  final List<String> items;
  final String selectedValue;
  final Function(String) onChanged;
  final String? hint;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final Color? backgroundColor;
  final Color? selectedBackgroundColor;
  final Color? borderColor;
  final Color? selectedBorderColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor; // New property
  final Color? dropdownBackgroundColor;
  final double? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? itemPadding;
  final double? elevation;
  final Duration? animationDuration;

  const AnimatedDropdown({
    Key? key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.hint,
    this.textStyle,
    this.hintStyle,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.borderColor,
    this.selectedBorderColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.dropdownBackgroundColor,
    this.borderRadius,
    this.padding,
    this.itemPadding,
    this.elevation,
    this.animationDuration,
  }) : super(key: key);

  @override
  _AnimatedDropdownState createState() => _AnimatedDropdownState();
}

class _AnimatedDropdownState extends State<AnimatedDropdown> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool isDropdownOpen = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _createOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 40,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, 60),
          child: TweenAnimationBuilder<double>(
            duration: widget.animationDuration ?? Duration(milliseconds: 200),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.95 + (0.05 * value),
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: value,
                  child: Material(
                    elevation: widget.elevation ?? 8,
                    borderRadius: BorderRadius.circular(
                      widget.borderRadius ?? 12,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.dropdownBackgroundColor ?? Colors.white,
                        borderRadius: BorderRadius.circular(
                          widget.borderRadius ?? 12,
                        ),
                        border: Border.all(
                          color: widget.borderColor ?? Colors.grey.shade300,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.items.asMap().entries.map((entry) {
                          int index = entry.key;
                          String item = entry.value;

                          return _buildDropdownItem(
                            item,
                            isSelected: widget.selectedValue == item,
                            isFirst: index == 0,
                            isLast: index == widget.items.length - 1,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildDropdownItem(
    String value, {
    bool isSelected = false,
    bool isLast = false,
    bool isFirst = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 150),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - animValue), 0),
          child: Opacity(
            opacity: animValue,
            child: GestureDetector(
              onTap: () {
                widget.onChanged(value);
                setState(() {
                  isDropdownOpen = false;
                });
                _removeOverlay();
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 150),
                width: double.infinity,
                padding:
                    widget.itemPadding ??
                    EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (widget.selectedBackgroundColor ?? Color(0xFFFFE7CA))
                      : Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topLeft: isFirst
                        ? Radius.circular(widget.borderRadius ?? 12)
                        : Radius.zero,
                    topRight: isFirst
                        ? Radius.circular(widget.borderRadius ?? 12)
                        : Radius.zero,
                    bottomLeft: isLast
                        ? Radius.circular(widget.borderRadius ?? 12)
                        : Radius.zero,
                    bottomRight: isLast
                        ? Radius.circular(widget.borderRadius ?? 12)
                        : Radius.zero,
                  ),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 150),
                  style: (widget.textStyle ?? GoogleFonts.poppins()).copyWith(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? (widget.selectedItemColor ?? Color(0xFF2457C5))
                        : (widget.unselectedItemColor ??
                              Color(0xFF65789F)), // Use unselected color
                  ),
                  child: Text(value),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TweenAnimationBuilder<Color?>(
        duration: widget.animationDuration ?? Duration(milliseconds: 200),
        tween: ColorTween(
          begin: widget.backgroundColor ?? Colors.white,
          end: isDropdownOpen
              ? (widget.selectedBackgroundColor ?? Colors.blue.shade50)
              : (widget.backgroundColor ?? Colors.white),
        ),
        builder: (context, color, child) {
          return GestureDetector(
            onTap: () {
              setState(() {
                isDropdownOpen = !isDropdownOpen;
              });

              if (isDropdownOpen) {
                _createOverlay();
              } else {
                _removeOverlay();
              }
            },
            child: AnimatedContainer(
              duration: widget.animationDuration ?? Duration(milliseconds: 200),
              padding:
                  widget.padding ??
                  EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
                border: Border.all(
                  color: isDropdownOpen
                      ? (widget.selectedBorderColor ?? Colors.blue)
                      : (widget.borderColor ?? Colors.grey.shade300),
                  width: isDropdownOpen ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      isDropdownOpen ? 0.1 : 0.05,
                    ),
                    blurRadius: isDropdownOpen ? 8 : 4,
                    offset: Offset(0, isDropdownOpen ? 4 : 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedDefaultTextStyle(
                    duration:
                        widget.animationDuration ?? Duration(milliseconds: 200),
                    style: (widget.textStyle ?? GoogleFonts.poppins()).copyWith(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold, // Always bold for closed dropdown
                      color: isDropdownOpen
                          ? Colors.blue
                          : (widget.selectedItemColor ?? Color(0xFF2457C5)),
                    ),
                    child: Text(
                      widget.selectedValue.isNotEmpty
                          ? widget.selectedValue
                          : (widget.hint ?? 'Select an option'),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isDropdownOpen ? 0.5 : 0,
                    duration:
                        widget.animationDuration ?? Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: isDropdownOpen ? Colors.blue : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Content Animation Mixin - for animating content when dropdown selection changes
mixin ContentAnimationMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  late AnimationController fadeController;
  late AnimationController slideController;
  late AnimationController scaleController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  late Animation<double> scaleAnimation;

  bool isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Initialize animation controllers
    fadeController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    slideController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    scaleController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize animations with smooth curves (no bounce)
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: fadeController, curve: Curves.easeInOut));

    slideAnimation = Tween<Offset>(begin: Offset(0.0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: slideController, curve: Curves.easeOutCubic),
        );

    scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: scaleController, curve: Curves.easeOut));

    // Show content on first load without animation
    if (isFirstLoad) {
      fadeController.forward();
      slideController.forward();
      scaleController.forward();
      isFirstLoad = false;
    }
  }

  @override
  void dispose() {
    fadeController.dispose();
    slideController.dispose();
    scaleController.dispose();
    super.dispose();
  }

  void animateContentChange() {
    // Reset animations
    fadeController.reset();
    slideController.reset();
    scaleController.reset();

    // Start animations with slight delays for a cascading effect
    fadeController.forward();

    Future.delayed(Duration(milliseconds: 100), () {
      slideController.forward();
    });

    Future.delayed(Duration(milliseconds: 200), () {
      scaleController.forward();
    });
  }

  Widget buildAnimatedContent({required Widget child}) {
    return AnimatedBuilder(
      animation: fadeAnimation,
      builder: (context, _) {
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          ),
        );
      },
    );
  }

  Widget buildStaggeredList({required List<Widget> children}) {
    return Column(
      children: children.asMap().entries.map((entry) {
        int index = entry.key;
        Widget child = entry.value;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, _) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
        );
      }).toList(),
    );
  }
}
