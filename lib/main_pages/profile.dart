import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  final String email;

  const ProfilePage({super.key, required this.email});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String studentName = "";
  String userType = "";
  String birthDate = "";
  String nationality = "";
  String sex = "";
  String contactNumber = "";
  String email = "";
  String? selectedAvatar;

  bool isLoading = true;

  // Available avatars stored in Supabase Storage
  static const List<String> avatarOptions = [
    'avatar_1.png',
    'avatar_2.webp',
    'avatar_3.png',
    'avatar_4.png',
    'avatar_5.webp',
    'avatar_6.png',
  ];

  // Supabase bucket name
  static const String avatarBucket = 'avatars';

  String _getAvatarUrl(String filename) {
    return Supabase.instance.client.storage
        .from(avatarBucket)
        .getPublicUrl(filename);
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      print('Fetching user data for email: ${widget.email}');

      final response = await Supabase.instance.client
          .from('Users')
          .select('''
          first_name,
          middle_name,
          last_name,
          suffix,
          user_type,
          birthday,
          nationality,
          sex,
          phone_number,
          email,
          avatar
        ''')
          .eq('email', widget.email)
          .maybeSingle()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('Database query timeout');
              throw Exception('Request timeout');
            },
          );

      print('Response received: ${response != null}');

      if (response != null) {
        final first = response['first_name'] ?? "";
        final middle = response['middle_name'] ?? "";
        final last = response['last_name'] ?? "";
        final suffix = response['suffix'] ?? "";

        // Build full name with suffix if it exists
        String fullName = "$first ${middle.isNotEmpty ? "$middle " : ""}$last"
            .trim();
        if (suffix.isNotEmpty) {
          fullName = "$fullName $suffix";
        }

        setState(() {
          studentName = fullName.isNotEmpty ? fullName : "No Name";
          userType = response['user_type']?.toString() ?? "N/A";

          if (response['birthday'] != null &&
              response['birthday'].toString().isNotEmpty) {
            try {
              final date = DateTime.parse(response['birthday'].toString());
              birthDate = DateFormat('MMMM d, y').format(date);
            } catch (e) {
              birthDate = response['birthday']?.toString() ?? "N/A";
            }
          } else {
            birthDate = "N/A";
          }

          nationality = response['nationality']?.toString() ?? "N/A";
          sex = response['sex']?.toString() ?? "N/A";
          contactNumber = response['phone_number']?.toString() ?? "N/A";
          email = response['email']?.toString() ?? "N/A";

          // Load the saved avatar from database, or use default
          selectedAvatar = response['avatar']?.toString() ?? avatarOptions[0];
          isLoading = false;
        });
        print('Data loaded successfully');
      } else {
        print('No user found with email: ${widget.email}');
        setState(() {
          isLoading = false;
          studentName = "User Not Found";
          userType = "N/A";
          selectedAvatar = avatarOptions[0];
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        studentName = "Error Loading";
        userType = "N/A";
        selectedAvatar = avatarOptions[0];
      });

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load profile: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateAvatar(String newAvatar) async {
    try {
      // Update avatar in database - this makes it persistent
      await Supabase.instance.client
          .from('Users')
          .update({'avatar': newAvatar})
          .eq('email', widget.email);

      setState(() {
        selectedAvatar = newAvatar;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Avatar updated successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating avatar: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showAvatarModal() {
    showDialog(
      context: context,
      builder: (context) {
        String tempSelectedAvatar = selectedAvatar ?? avatarOptions[0];

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 600,
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      'Choose Avatar',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select your profile picture',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Scrollable Avatar Grid
                    Expanded(
                      child: SingleChildScrollView(
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: avatarOptions.length,
                          itemBuilder: (context, index) {
                            final avatar = avatarOptions[index];
                            final isSelected = tempSelectedAvatar == avatar;

                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  tempSelectedAvatar = avatar;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.orange
                                        : Colors.grey[300]!,
                                    width: isSelected ? 3 : 2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.orange.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    _getAvatarUrl(avatar),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Buttons in Column (Confirm above Cancel)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              _updateAvatar(tempSelectedAvatar);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Confirm Changes',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 280,
                          child: Stack(
                            children: [
                              // Header image with rounded bottom corners
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                                child: Container(
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
                                          Colors.black.withValues(alpha: 0.3),
                                          Colors.black.withValues(alpha: 0.1),
                                        ],
                                      ),
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
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.black,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                ),
                              ),
                              // Avatar and name
                              Positioned(
                                top: 120,
                                left: 0,
                                right: 0,
                                child: Column(
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.blue,
                                              width: 0.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.2,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 58,
                                            backgroundColor: Colors.grey[300],
                                            backgroundImage:
                                                selectedAvatar != null
                                                ? NetworkImage(
                                                    _getAvatarUrl(
                                                      selectedAvatar!,
                                                    ),
                                                  )
                                                : null,
                                            child: selectedAvatar == null
                                                ? Icon(
                                                    Icons.person,
                                                    size: 60,
                                                    color: Colors.grey[600],
                                                  )
                                                : null,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: GestureDetector(
                                            onTap: _showAvatarModal,
                                            child: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.orange,
                                                border: Border.all(
                                                  color: const Color.fromARGB(
                                                    255,
                                                    248,
                                                    181,
                                                    100,
                                                  ),
                                                  width: 2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            studentName,
                                            style: GoogleFonts.montserrat(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF060870),
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            userType,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PERSONAL INFORMATION',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 20),
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
                                label: 'Sex',
                                value: sex,
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
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
