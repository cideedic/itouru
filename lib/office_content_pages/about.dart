import 'package:itouru/components/info_card.dart'; // about.dart (for buildings)
import 'package:flutter/material.dart';
import 'package:itouru/components/footer.dart';

class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video Preview Section
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video preview background (placeholder)
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              // Play button
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow, color: Colors.white, size: 35),
              ),
            ],
          ),
        ),

        SizedBox(height: 20),

        // Description text
        Text(
          'Ricardo A. Arcilla, lawyer and the first president of Bicol University (1969-1970), born in Oas, province of Camarines Sur. During his term, President Arcilla ensured the establishment of satellite campuses and turned the university into a training institution for professionals and a responsive social catalyst through the creation of several colleges such as the BU College of Education, the College of Engineering, the Graduate School, and the College of Nursing.',
          style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
          textAlign: TextAlign.justify,
        ),

        SizedBox(height: 24),

        // Directions Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Add navigation to directions functionality
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Opening directions...')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions, size: 20),
                SizedBox(width: 8),
                Text(
                  'Directions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
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
}
