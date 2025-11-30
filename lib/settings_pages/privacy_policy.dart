import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.privacy_tip,
                  color: Colors.green[700],
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: Text(
                'Effective Date: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Content sections
            _buildParagraph(
              'INTRODUCTION AND SCOPE',
              'Bicol University (hereinafter referred to as "we," "us," "our," or "the University") is committed to protecting the privacy and security of personal information collected through the iTOURu mobile application (hereinafter referred to as "the Application" or "the App"). This Privacy Policy explains how we collect, use, disclose, store, and protect your information when you access or use our services. This policy applies to all users of the Application, including students, faculty, staff, visitors, and guest users. By using the Application, you consent to the data practices described in this policy. If you do not agree with the terms of this Privacy Policy, please do not access or use the Application. We encourage you to read this policy carefully and contact us if you have any questions or concerns regarding your privacy rights.',
            ),

            _buildParagraph(
              'INFORMATION WE COLLECT',
              'We collect various types of information in connection with the services we provide through the Application. Account Information includes data provided during registration or account creation, such as your full name, university email address, student or employee identification number, account type designation, and authentication credentials. For users accessing the Application through official Bicol University accounts, we may collect additional institutional information necessary for account verification and access control. Guest users provide minimal identifying information, primarily consisting of temporary session identifiers and device-generated tokens for authentication purposes. Location Data is fundamental to the Application\'s core functionality and includes real-time geographic coordinates obtained through your device\'s Global Positioning System (GPS), calculated position data based on network triangulation, campus area and zone detection information, navigation route history during active sessions, and proximity data to campus facilities and points of interest. Usage Data encompasses information about how you interact with the Application, including specific features accessed, frequency and duration of use, search queries entered, locations viewed or visited, navigation routes selected, time stamps of activities, user interface interactions, and preference settings. Device Information collected includes your device\'s unique identifier, manufacturer and model, operating system type and version, application version installed, screen resolution and display characteristics, network connection type and status, device language settings, and time zone configuration. Technical logs generated during your use of the Application may include IP addresses, access times, pages viewed, crashes or errors encountered, and performance metrics.',
            ),

            _buildParagraph(
              'HOW WE USE YOUR INFORMATION',
              'The information we collect is used to provide, maintain, and improve the Application\'s services and functionality. We use your data to authenticate your identity and manage your account access, display your current location on interactive campus maps, calculate optimal routes and provide turn-by-turn navigation instructions, determine distances between locations and estimated travel times, identify your proximity to campus buildings and facilities, provide personalized recommendations based on your location and preferences, enable search functionality for campus locations and services, facilitate virtual campus tour experiences, and maintain session continuity across application uses. We also use collected information for analytical purposes, including analyzing usage patterns to understand how users interact with the Application, identifying areas for improvement in user experience and interface design, monitoring application performance and identifying technical issues, generating aggregate statistics about application usage, evaluating the effectiveness of navigation features, optimizing map rendering and location services, and conducting research to enhance campus navigation solutions. Additionally, we use your information for communication purposes, such as sending important service announcements and updates to registered university account holders, providing notifications about changes to the Application\'s features or functionality, responding to your inquiries and support requests, gathering feedback about your experience with the Application, and informing users of relevant university events or facilities information when appropriate.',
            ),

            _buildParagraph(
              'LOCATION DATA PRIVACY AND PROTECTION',
              'We recognize that location information is particularly sensitive and take special measures to protect your privacy. Location data is collected only when the Application is actively running in the foreground or when you have explicitly enabled background location access for navigation purposes. The Application does not track your location when it is closed or not in active use unless you have specifically enabled continuous navigation mode. Your real-time location coordinates are processed on your device and transmitted to our servers using encrypted connections solely for the purpose of providing navigation services. We do not permanently store your precise GPS coordinates or maintain a comprehensive history of your movements. Location data used during navigation sessions is retained only for the duration necessary to complete the navigation task and is automatically purged upon session termination or after a maximum of twenty-four hours, whichever occurs first. We do not share your individual location data with other users, third-party services, or external entities. Aggregated and anonymized location data, which cannot be used to identify individual users, may be used for statistical analysis and service improvement purposes, such as identifying high-traffic areas on campus or optimizing suggested routes. You maintain full control over location permissions through your device settings and may revoke the Application\'s access to location services at any time, though this will significantly limit or prevent the functionality of navigation features.',
            ),

            _buildParagraph(
              'DATA SHARING AND DISCLOSURE',
              'We do not sell, rent, lease, or otherwise commercially exploit your personal information. We maintain strict policies regarding data sharing and disclosure. Your personal information is not shared with advertising networks or marketing companies. We do not provide your data to third-party analytics services beyond those essential for application functionality. Individual user location data is never shared with other application users or external parties. We do not engage in cross-promotional activities that involve sharing your information with partner organizations. However, we may share information in limited circumstances as follows: with university administrators and authorized personnel, we may share aggregated, anonymized usage statistics that do not identify individual users for institutional planning and assessment purposes. When required by law, we may disclose your information to comply with legal obligations, respond to lawful requests from public authorities, enforce our terms and conditions, protect our rights and property, investigate potential violations, or protect the safety and security of the university community. In the event of a university restructuring, merger, or transfer of services, your information may be transferred to the successor entity, subject to the same privacy protections outlined in this policy. We may share technical information with third-party service providers who assist in operating the Application, such as cloud hosting services, database management, and authentication systems, provided such parties agree to maintain confidentiality and use the information only for the purposes of providing their services to us.',
            ),

            _buildParagraph(
              'DATA STORAGE, SECURITY, AND RETENTION',
              'We implement comprehensive security measures to protect your information from unauthorized access, alteration, disclosure, or destruction. All data transmission between your device and our servers is encrypted using industry-standard Transport Layer Security (TLS) protocols. Personal information and authentication credentials are stored in secure, access-controlled database systems hosted on Supabase, a reputable cloud infrastructure provider that maintains SOC 2 Type II compliance and adheres to industry best practices for data security. Access to user data is restricted to authorized personnel only and is granted on a need-to-know basis. We implement multi-factor authentication for administrative access, maintain comprehensive audit logs of data access and modifications, conduct regular security assessments and vulnerability testing, and maintain incident response procedures for potential security breaches. Data retention periods vary based on the type of information and account status. Guest user session data is automatically deleted after twenty-four hours from initial login or upon session termination, whichever occurs first. For registered university accounts, basic profile information is retained for the duration of your active affiliation with the university and may be archived or deleted following the termination of your university relationship in accordance with institutional record retention policies. Location data collected during navigation sessions is not permanently stored and is purged after session completion. Usage logs and analytics data are retained in anonymized form for a period not exceeding ninety days, after which they are aggregated into statistical summaries that cannot be used to identify individual users. You may request deletion of your account and associated data at any time by contacting us at the address provided in this policy.',
            ),

            _buildParagraph(
              'THIRD-PARTY SERVICES AND INTEGRATIONS',
              'The Application integrates certain third-party services and components necessary for its operation. These include Supabase, which provides cloud database infrastructure, user authentication services, and backend functionality; OpenStreetMap, which supplies map tiles, geographic data, and cartographic information; and Google Fonts, which delivers typography and font rendering services. Each of these third-party services maintains its own privacy policy governing the collection and use of data. While we carefully select service providers that maintain strong privacy and security standards, we are not responsible for the privacy practices of these external services. We encourage you to review the privacy policies of these providers: Supabase Privacy Policy (supabase.com/privacy), OpenStreetMap Privacy Policy (wiki.openstreetmap.org/wiki/Privacy_Policy), and Google Fonts Privacy Policy (policies.google.com/privacy). The Application does not integrate with social media platforms, advertising networks, or other third-party services beyond those listed above. We do not use third-party tracking technologies, such as cookies or web beacons, beyond those necessary for basic application functionality.',
            ),

            _buildParagraph(
              'YOUR PRIVACY RIGHTS AND CHOICES',
              'You have certain rights regarding your personal information and how it is used. You have the right to access the personal information we hold about you and receive a copy of such data in a commonly used electronic format. You may request correction of any inaccurate or incomplete personal information we maintain. You have the right to request deletion of your personal data, subject to certain exceptions where we are required to retain information for legal or legitimate operational purposes. You may object to or request restriction of certain types of data processing. You have the right to withdraw your consent for data processing activities that are based on consent, without affecting the lawfulness of processing conducted prior to withdrawal. To exercise these rights, please submit a written request to our designated contact email address. We will respond to your request within thirty days of receipt. For verification purposes, we may require you to provide additional information to confirm your identity before processing requests related to personal data. You also maintain control over certain application permissions through your device settings, including the ability to enable or disable location services, grant or revoke camera access for QR code scanning, control notification preferences, and manage storage permissions. Please note that disabling certain permissions may limit the functionality of the Application.',
            ),

            _buildParagraph(
              'CHILDREN\'S PRIVACY',
              'The iTOURu Application is intended for use by members of the Bicol University community, including students, faculty, staff, and visitors to the campus. While the university community includes individuals of various ages, we do not knowingly collect personal information from children under the age of thirteen without verifiable parental or guardian consent. If you are a parent or guardian and believe that your child under thirteen has provided personal information through the Application without your consent, please contact us immediately so that we can take appropriate action to remove such information from our systems. For users between the ages of thirteen and eighteen, we recommend that parents and guardians review this Privacy Policy and discuss the use of the Application with their children to ensure understanding of privacy implications.',
            ),

            _buildParagraph(
              'INTERNATIONAL DATA TRANSFERS',
              'Your information may be transferred to, stored, and processed in facilities located outside of the Philippines, including in jurisdictions that may not provide the same level of data protection as Philippine law. Our cloud service provider, Supabase, operates infrastructure in multiple geographic regions. By using the Application, you consent to the transfer of your information to these locations. We ensure that appropriate safeguards are in place to protect your information in accordance with this Privacy Policy, including contractual obligations with service providers to maintain data security and comply with applicable data protection laws.',
            ),

            _buildParagraph(
              'CHANGES TO THIS PRIVACY POLICY',
              'We reserve the right to modify, amend, or update this Privacy Policy at any time to reflect changes in our practices, legal requirements, or operational needs. When we make material changes to this policy, we will update the "Effective Date" at the top of this document and provide notice through the Application interface or via email to registered university account holders. For significant changes that materially affect your privacy rights, we may require you to review and accept the updated policy before continuing to use the Application. We encourage you to periodically review this Privacy Policy to stay informed about how we are protecting your information. Your continued use of the Application following the posting of changes constitutes your acceptance of such modifications.',
            ),

            _buildParagraph(
              'DATA BREACH NOTIFICATION',
              'In the unlikely event of a data breach that compromises the security of your personal information, we will notify affected users in accordance with applicable law and university policy. Notification will be provided without unreasonable delay and will include information about the nature of the breach, the types of information involved, steps we are taking to address the breach and prevent future occurrences, and recommended actions you can take to protect yourself. Notifications will be sent via email to registered university account holders or through prominent notice within the Application for guest users.',
            ),

            _buildParagraph(
              'CONTACT INFORMATION AND DATA PROTECTION OFFICER',
              'For any questions, concerns, or requests regarding this Privacy Policy, the handling of your personal information, or to exercise your privacy rights, please contact us through the following channels: Email: jcml2022-2902-58530@bicol-u.edu.ph, Phone: 09212814357, Bicol University, Legazpi City, Albay, Philippines. For matters specifically related to data protection and privacy compliance, you may contact our Data Protection Office at: dpo@bicol-u.edu.ph, Attention: Mr. Davie B. Balmadrid, University Director of Data Privacy and Protection Office. We are committed to addressing your privacy concerns promptly and will respond to all inquiries within a reasonable timeframe, typically within thirty days of receipt.',
            ),

            const SizedBox(height: 24),

            // Privacy Commitment Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.green, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your privacy is important to us. We are committed to protecting your personal information and being transparent about our data practices.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.green[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            textAlign: TextAlign.justify,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
