import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  final String email; // Use email to fetch user data

  const ProfilePage({super.key, required this.email});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Profile fields
  String studentName = "";
  String userType = "";
  String birthDate = "";
  String nationality = "";
  String gender = "";
  String contactNumber = "";
  String email = "";
  String address = "";
  String? profileImageUrl;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await Supabase.instance.client
          .from('Users') // make sure your table name is correct
          .select()
          .eq('email', widget.email)
          .maybeSingle();

      if (response != null) {
        setState(() {
          final first = response['first_name'] ?? "";
          final middle = response['middle_name'] ?? "";
          final last = response['last_name'] ?? "";

          // If middle name exists, add it, otherwise skip
          studentName = "$first ${middle.isNotEmpty ? "$middle " : ""}$last"
              .trim();
          userType = response['user_type'] ?? "N/A";
          birthDate = response['birthday'] ?? "N/A";
          nationality = response['nationality'] ?? "N/A";
          gender = response['sex'] ?? "N/A";
          contactNumber = response['phone_number'] ?? "N/A";
          email = response['email'] ?? "N/A";
          address = response['address'] ?? "N/A";
          profileImageUrl = response['profileImageUrl'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching user: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with background image and overlapping profile
                SizedBox(
                  height: 280,
                  child: Stack(
                    children: [
                      // Background header image
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                              'assets/images/profile_image.png',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Back button
                      Positioned(
                        top: 40,
                        left: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),

                      // Overlapping profile image
                      Positioned(
                        top: 120,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 58,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: profileImageUrl != null
                                    ? NetworkImage(profileImageUrl!)
                                    : null,
                                child: profileImageUrl == null
                                    ? Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey[600],
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Student name and type
                            Text(
                              studentName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userType,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Personal Information Panel
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PERSONAL INFORMATION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Colors.black54,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Personal information items
                        Column(
                          children: [
                            _buildInfoItem(
                              icon: Icons.calendar_today,
                              iconColor: Colors.orange,
                              label: 'Birth Date',
                              value: birthDate,
                            ),
                            _buildInfoItem(
                              icon: Icons.flag,
                              iconColor: Colors.orange,
                              label: 'Nationality',
                              value: nationality,
                            ),
                            _buildInfoItem(
                              icon: Icons.person,
                              iconColor: Colors.orange,
                              label: 'Gender',
                              value: gender,
                            ),
                            _buildInfoItem(
                              icon: Icons.phone,
                              iconColor: Colors.orange,
                              label: 'Contact Number',
                              value: contactNumber,
                            ),
                            _buildInfoItem(
                              icon: Icons.email,
                              iconColor: Colors.orange,
                              label: 'Email',
                              value: email,
                            ),
                            _buildInfoItem(
                              icon: Icons.location_on,
                              iconColor: Colors.orange,
                              label: 'Address',
                              value: address,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      backgroundColor: Colors.grey[100],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
