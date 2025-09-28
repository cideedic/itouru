// content.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Import your tab components
import 'about.dart';
import 'history.dart';
import 'programs.dart';
import 'buildings.dart';

class ContentPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final String logoPath;

  const ContentPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.logoPath,
  });

  @override
  _ContentPageState createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabTitles = ['About', 'History', 'Programs', 'Buildings'];

  // Add this sample data for history
  final List<Map<String, String>> _historyEntries = [
    {
      'title': 'Foundation, 1985',
      'date': 'June 13, 1985',
      'description':
          'Bicol University, College of Science was founded on June 13, 1985 by Waza M. Lil.',
    },
    {
      'title': 'First Graduating Class, 1990',
      'date': 'April 30, 1990',
      'description':
          'The first batch of graduates from the College of Science completed their studies and embarked on their professional journeys.',
    },
    {
      'title': 'New Research Center, 2000',
      'date': 'September 15, 2000',
      'description':
          'The college inaugurated a new research center to foster innovation and scientific exploration among students and faculty.',
    },
    {
      'title': 'Accreditation, 2005',
      'date': 'March 22, 2005',
      'description':
          'The College of Science received accreditation from the Philippine Accrediting Association of Schools, Colleges, and Universities (PAASCU).',
    },
    {
      'title': 'Centennial Celebration, 2015',
      'date': 'October 10, 2015',
      'description':
          'The college celebrated its centennial anniversary with various academic and cultural events.',
    },
    {
      'title': 'New Degree Programs, 2020',
      'date': 'January 5, 2020',
      'description':
          'Introduction of new degree programs in Data Science and Environmental Science to meet the evolving demands of the industry.',
    },
    // Add more entries as needed
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(),
                _buildHistoryTab(),
                _buildProgramsTab(),
                _buildBuildingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 285,
      child: Stack(
        children: [
          // Background Image
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(widget.imagePath),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
          // Back Button and Title
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Logo
          Positioned(
            top: 160,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Image.asset(
                      widget.logoPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.school, color: Colors.blue, size: 40);
                      },
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

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue,
        unselectedLabelColor: Color(0xFF65789F),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ), // Reduced font size
        unselectedLabelStyle: TextStyle(
          fontSize: 13, // Reduced font size
          fontWeight: FontWeight.w400,
        ),
        indicatorColor: Colors.blue,
        indicatorWeight: 3,
        labelPadding: EdgeInsets.symmetric(
          horizontal: 8,
        ), // Reduced horizontal padding
        tabs: _tabTitles
            .map(
              (title) => Tab(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4,
                  ), // Additional padding reduction
                  child: Text(title),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // Each tab returns its own scrollable widget:
  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: AboutTab(),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: HistoryTab(historyEntries: _historyEntries),
    );
  }

  Widget _buildProgramsTab() {
    return ProgramsTab(); // No SingleChildScrollView here!
  }

  Widget _buildBuildingsTab() {
    return BuildingsTab(); // No SingleChildScrollView here!
  }
}
