// content.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Import your tab components
import 'content_pages/about.dart';
// import 'history_tab.dart';    // Will create later
// import 'programs_tab.dart';   // Will create later
// import 'buildings_tab.dart';  // Will create later

class ContentPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imagePath; // Changed from imageUrl to imagePath for local images
  final String logoPath; // Changed from logoUrl to logoPath for local images

  const ContentPage({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.logoPath,
  }) : super(key: key);

  @override
  _ContentPageState createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  final List<String> _tabTitles = ['About', 'History', 'Programs', 'Buildings'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header Section with Image and Info
          _buildHeaderSection(),

          // Tab Bar
          _buildTabBar(),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                AboutTab(),
                _buildComingSoonTab('History'),
                _buildComingSoonTab('Programs'),
                _buildComingSoonTab('Buildings'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      height: 350, // Made taller (was 300)
      child: Stack(
        children: [
          // Background Image - Using AssetImage for local images
          Container(
            height: 350, // Made taller (was 300)
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(widget.imagePath), // Changed to AssetImage
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Gradient Overlay
          Container(
            height: 350, // Made taller (was 300)
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              ),
            ),
          ),

          // Title and Subtitle - Moved to upper right
          Positioned(
            top: 80, // Positioned near the top
            right: 20, // Positioned on the right
            left: 100, // Give some space from the left for better layout
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end, // Align to the right
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right, // Right align the text
                ),
                SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.right, // Right align the text
                ),
              ],
            ),
          ),

          // Logo - Moved to bottom right
          Positioned(
            right: 20,
            bottom: 20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  widget.logoPath, // Changed to Image.asset
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.school, color: Colors.blue, size: 30);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.blue,
        unselectedLabelColor: Color(0xFF65789F),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        indicatorColor: Colors.blue,
        indicatorWeight: 3,
        labelPadding: EdgeInsets.symmetric(horizontal: 20),
        tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
      ),
    );
  }

  // Placeholder for tabs that haven't been implemented yet
  Widget _buildComingSoonTab(String tabName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 60, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            '$tabName Coming Soon',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
