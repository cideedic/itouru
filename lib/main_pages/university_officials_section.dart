import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/page_components/loading_widget.dart';
import 'package:itouru/office_content_pages/content.dart' as office_content;
import 'dart:async';

class UniversityOfficialsSection extends StatefulWidget {
  final Animation<Offset>? slideAnimation;
  final Animation<double>? fadeAnimation;

  const UniversityOfficialsSection({
    super.key,
    this.slideAnimation,
    this.fadeAnimation,
  });

  @override
  State<UniversityOfficialsSection> createState() =>
      _UniversityOfficialsSectionState();
}

class _UniversityOfficialsSectionState
    extends State<UniversityOfficialsSection> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? president;
  List<Map<String, dynamic>> allOfficials = [];
  List<Map<String, dynamic>> filteredOfficials = [];
  bool isLoading = true;

  late PageController _pageController;
  Timer? _autoScrollTimer;
  bool _isCarouselPaused = false;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final List<int> priorityOrder = [28, 60, 49, 59, 58];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.35);
    _searchController.addListener(_onSearchChanged);
    _loadOfficials();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    final previousFilteredCount = filteredOfficials.length;

    setState(() {
      if (query.isEmpty) {
        filteredOfficials = allOfficials;
        _isSearching = false;
      } else {
        _isSearching = true;
        filteredOfficials = allOfficials.where((official) {
          final name = _buildFullName(official).toLowerCase();
          final position = (official['position']?.toString() ?? '')
              .toLowerCase();
          return name.contains(query) || position.contains(query);
        }).toList();
      }
    });

    // Only jump to page 0 if the filtered results actually changed (user typed/deleted)
    if (filteredOfficials.isNotEmpty &&
        _pageController.hasClients &&
        filteredOfficials.length != previousFilteredCount) {
      _pageController.jumpToPage(0);
    }

    if (!_isSearching) {
      _startAutoScroll();
    } else {
      _autoScrollTimer?.cancel();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_isSearching) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isCarouselPaused &&
          _pageController.hasClients &&
          filteredOfficials.isNotEmpty) {
        int nextPage = (_pageController.page?.round() ?? 0) + 1;
        if (nextPage >= filteredOfficials.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _pauseCarousel() {
    setState(() {
      _isCarouselPaused = true;
    });
  }

  void _resumeCarousel() {
    setState(() {
      _isCarouselPaused = false;
    });
  }

  Future<void> _loadOfficials() async {
    try {
      final results = await Future.wait([
        supabase.from('Head').select().eq('head_id', 27).maybeSingle(),
        supabase
            .from('Head')
            .select()
            .neq('head_id', 27)
            .order('position', ascending: true),
      ]);

      if (!mounted) return;

      final presidentResponse = results[0] as Map<String, dynamic>?;
      final officialsResponse = results[1] as List<dynamic>;

      Map<String, dynamic>? processedPresident;
      if (presidentResponse != null) {
        final imageUrl = await _fetchHeadImage(
          presidentResponse['head_id'],
          presidentResponse['first_name']?.toString().toLowerCase(),
          presidentResponse['last_name']?.toString().toLowerCase(),
        );
        processedPresident = {...presidentResponse, 'image_url': imageUrl};
      }

      final imagesFutures = officialsResponse.map((official) async {
        final imageUrl = await _fetchHeadImage(
          official['head_id'],
          official['first_name']?.toString().toLowerCase(),
          official['last_name']?.toString().toLowerCase(),
        );
        return {...official as Map<String, dynamic>, 'image_url': imageUrl};
      }).toList();

      final processedOfficials = await Future.wait(imagesFutures);

      processedOfficials.sort((a, b) {
        int indexA = priorityOrder.indexOf(a['head_id']);
        int indexB = priorityOrder.indexOf(b['head_id']);

        if (indexA != -1 && indexB != -1) {
          return indexA.compareTo(indexB);
        }
        if (indexA != -1) return -1;
        if (indexB != -1) return 1;
        return 0;
      });

      if (mounted) {
        setState(() {
          president = processedPresident;
          allOfficials = processedOfficials;
          filteredOfficials = processedOfficials;
          isLoading = false;
        });

        if (filteredOfficials.isNotEmpty) {
          _startAutoScroll();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<String?> _fetchHeadImage(
    int? headId,
    String? firstName,
    String? lastName,
  ) async {
    if (headId == null && (firstName == null || lastName == null)) {
      return null;
    }

    try {
      final possiblePatterns = <String>[];

      if (headId != null) {
        possiblePatterns.addAll([
          'heads/head_$headId',
          'heads/head_${headId}_profile',
          'heads/$headId',
        ]);
      }

      if (firstName != null && lastName != null) {
        // Normalize names: replace ñ with n, remove dots, replace spaces with hyphens
        final firstNormalized = firstName
            .replaceAll('ñ', 'n')
            .replaceAll('.', '')
            .replaceAll(' ', '-')
            .trim();
        final firstNoSpaces = firstName
            .replaceAll('ñ', 'n')
            .replaceAll('.', '')
            .replaceAll(' ', '')
            .trim();
        final lastNormalized = lastName
            .replaceAll('ñ', 'n')
            .replaceAll('.', '')
            .replaceAll(' ', '-')
            .trim();
        final lastNoSpaces = lastName
            .replaceAll('ñ', 'n')
            .replaceAll('.', '')
            .replaceAll(' ', '')
            .trim();

        possiblePatterns.addAll([
          // With hyphens between words
          'heads/$firstNormalized-$lastNormalized',
          'heads/$lastNormalized-$firstNormalized',
          // Without spaces (johncedrick-doe)
          'heads/$firstNoSpaces-$lastNormalized',
          'heads/$lastNormalized-$firstNoSpaces',
          // With underscores
          'heads/${firstNormalized}_$lastNormalized',
          'heads/${lastNormalized}_$firstNormalized',
          'heads/${firstNoSpaces}_$lastNormalized',
          'heads/${lastNormalized}_$firstNoSpaces',
          // All no spaces
          'heads/$firstNoSpaces-$lastNoSpaces',
          'heads/$lastNoSpaces-$firstNoSpaces',
        ]);
      }

      for (var pattern in possiblePatterns) {
        try {
          final response = await supabase
              .from('storage_objects_snapshot')
              .select('name')
              .eq('bucket_id', 'images')
              .like('name', '$pattern%')
              .maybeSingle()
              .timeout(const Duration(seconds: 3));

          if (response != null) {
            return supabase.storage
                .from('images')
                .getPublicUrl(response['name'] as String);
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      // Return null if any error occurs
    }
    return null;
  }

  String _buildFullName(Map<String, dynamic> data) {
    final prefix = data['prefix_name']?.toString() ?? '';
    final firstName = data['first_name']?.toString() ?? '';
    final lastName = data['last_name']?.toString() ?? '';
    final middleName = data['middle_name']?.toString() ?? '';
    final suffix = data['suffix_name']?.toString() ?? '';

    String fullName = '';

    if (prefix.isNotEmpty) fullName += '$prefix ';
    if (firstName.isNotEmpty) fullName += '$firstName ';
    if (lastName.isNotEmpty) fullName += '$lastName ';
    if (middleName.isNotEmpty) {
      fullName += '${middleName[0]}. ';
    }
    if (suffix.isNotEmpty) fullName += suffix;

    return fullName.trim();
  }

  void _showOfficialModal(Map<String, dynamic> official) async {
    _pauseCarousel();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.orange.shade50.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: official['image_url'] != null
                      ? Image.network(
                          official['image_url']!,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _buildFullName(official),
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  official['position']?.toString() ?? 'No Position',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final officeResponse = await supabase
                          .from('Office')
                          .select('office_id, office_name, office_abbreviation')
                          .eq('head_id', official['head_id'])
                          .maybeSingle();

                      // Close dialog first, THEN navigate
                      if (!mounted) return;
                      Navigator.pop(context);

                      if (officeResponse != null) {
                        // Wait a tiny bit for dialog to fully close
                        await Future.delayed(Duration(milliseconds: 100));

                        if (!mounted) return;

                        // Navigate to office details page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                office_content.OfficeDetailsPage(
                                  officeId: officeResponse['office_id'] as int,
                                  officeName:
                                      officeResponse['office_name'] as String,
                                  title:
                                      officeResponse['office_name'] as String,
                                ),
                          ),
                        );
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No office found for this official'),
                            backgroundColor: Colors.orange[700],
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      // Close dialog on error too
                      if (mounted) {
                        Navigator.pop(context);
                      }

                      await Future.delayed(Duration(milliseconds: 100));

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red[700],
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.business, size: 18),
                  label: Text(
                    'View Office',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade400,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    _resumeCarousel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.orange.withValues(alpha: 0.15),
                      Colors.orange.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.account_balance,
                    size: 90,
                    color: Colors.orange.withValues(alpha: 0.12),
                  ),
                ),
              ),
              FadeTransition(
                opacity: widget.fadeAnimation ?? AlwaysStoppedAnimation(0.0),
                child: SlideTransition(
                  position:
                      widget.slideAnimation ??
                      AlwaysStoppedAnimation(Offset.zero),
                  child: Column(
                    children: [
                      Text(
                        'University Leadership',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: widget.fadeAnimation ?? AlwaysStoppedAnimation(0.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.orange.shade50.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: isLoading
                  ? SizedBox(
                      height: 300,
                      child: LoadingWidget(
                        title: 'Loading Officials',
                        subtitle: 'Please wait...',
                        primaryColor: Colors.orange.shade400,
                        backgroundColor: Colors.transparent,
                        style: LoadingStyle.dots,
                      ),
                    )
                  : president == null
                  ? _buildNoDataDisplay()
                  : Column(
                      children: [
                        _buildPresidentCard(president!),
                        if (allOfficials.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'Other Officials',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey[400],
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey.shade400,
                                  size: 20,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.grey[400],
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _searchController.clear(),
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_isSearching && filteredOfficials.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No officials found',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (filteredOfficials.isNotEmpty) ...[
                            SizedBox(
                              height: 180,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: filteredOfficials.length,
                                itemBuilder: (context, index) {
                                  return _buildOfficialCarouselCard(
                                    filteredOfficials[index],
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresidentCard(Map<String, dynamic> official) {
    return GestureDetector(
      onTap: () => _showOfficialModal(official),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: official['image_url'] != null
                  ? Image.network(
                      official['image_url']!,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFA9D2B),
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _buildFullName(official),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                official['position']?.toString() ?? 'No Position',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialCarouselCard(Map<String, dynamic> official) {
    return GestureDetector(
      onTap: () => _showOfficialModal(official),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: official['image_url'] != null
                    ? Image.network(
                        official['image_url']!,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFA9D2B),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.person,
                              size: 35,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.person,
                          size: 35,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _buildFullName(official),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  official['position']?.toString() ?? 'No Position',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataDisplay() {
    return SizedBox(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No officials information available',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
