import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/footer.dart';
import 'package:itouru/page_components/info_card.dart'; // Import the new reusable InfoCard

class AboutTab extends StatefulWidget {
  const AboutTab({super.key});

  @override
  State<AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends State<AboutTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video Player Section
        _buildVideoSection(),

        SizedBox(height: 24),

        // About Description
        _buildDescriptionSection(),

        SizedBox(height: 32),

        // Vision Section
        _buildInfoSection(
          title: 'Vision',
          content:
              'Committed to humanity development, productive scholarship, transformative leadership, collaborative service and distinctive character for sustainable societies.',
          icon: Icons.visibility_outlined,
          color: Colors.blue,
        ),

        SizedBox(height: 24),

        // Mission Section
        _buildInfoSection(
          title: 'Mission',
          content:
              'The Bicol University shall primarily give professional and technical training, conduct research, promote arts, sciences and technology, advanced instruction in literature, philosophy, the sciences, arts and business studies and provide progressive leadership in its community, as well as in the promotion of scientific and technological researches.',
          icon: Icons.rocket_launch_outlined,
          color: Colors.green,
        ),

        SizedBox(height: 24),

        // Goals and Objectives Section
        _buildInfoSection(
          title: 'Goals and Objective',
          content:
              'To offer curricula that lead to baccalaureate degrees in teacher education, agriculture, fishery, forestry, engineering, arts and sciences, medicine, law, and other professions; To undertake research and extension in support of national, regional and local development; To provide technical assistance and consultancy services.',
          icon: Icons.flag_outlined,
          color: Colors.orange,
        ),

        // Dean's Information Card (now using InfoCard)
        InfoCard(
          name: 'Prof. Jocelyn E. Serrano',
          title: 'Dean, College of Science',
          socials: {
            'email': 'serrano@bicoluniversity.edu.ph',
            'facebook': 'https://facebook.com/deanserrano',
            // 'instagram': 'https://instagram.com/deanserrano', // Uncomment if available
            // 'x': 'https://x.com/deanserrano', // Uncomment if available
          },
        ),

        AppFooter(),
      ],
    );
  }

  Widget _buildVideoSection() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Video placeholder background
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey[200]!, Colors.grey[400]!],
              ),
            ),
          ),

          // Play button
          Center(
            child: GestureDetector(
              onTap: () {
                // Handle video play
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(Icons.play_arrow, color: Colors.white, size: 35),
              ),
            ),
          ),

          // Video duration indicator (optional)
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '2:30',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'Bicol University\'s College of Science is a leading academic institution dedicated to nurturing future scientists and technology professionals. It offers a wide range of undergraduate programs including Information Technology, Computer Science, Biology, Chemistry, and Mathematics designed to equip students with both theoretical knowledge and practical skills.',
        style: GoogleFonts.poppins(
          fontSize: 13,
          height: 1.6,
          color: Colors.grey[700],
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with Icon
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors
                      .blue[800], // Changed from Colors.black87 to Colors.blue
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Content
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 12, // Reduced from 14 to 12
              height: 1.6,
              color: Colors.grey[700],
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  void _showVideoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 60,
                        color: Colors.white,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Video Player',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Video functionality would be implemented here',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
