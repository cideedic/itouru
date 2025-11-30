import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfServiceModal extends StatefulWidget {
  const TermsOfServiceModal({super.key});

  @override
  State<TermsOfServiceModal> createState() => _TermsOfServiceModalState();
}

class _TermsOfServiceModalState extends State<TermsOfServiceModal> {
  bool _hasAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.description,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Terms of Service',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Updated: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildParagraph(
                      'ACCEPTANCE OF TERMS',
                      'By accessing, downloading, installing, or using the iTOURu mobile application (hereinafter referred to as "the Application" or "the App"), you acknowledge that you have read, understood, and agree to be bound by these Terms of Service (hereinafter referred to as "Terms" or "Agreement"), including any additional guidelines, policies, and future modifications thereof. This Agreement constitutes a legally binding contract between you (hereinafter referred to as "User," "you," or "your") and Bicol University (hereinafter referred to as "we," "us," "our," or "the University"). If you do not agree to these Terms in their entirety, you are expressly prohibited from accessing or using the Application and must discontinue use immediately. Your continued use of the Application following any modifications to these Terms shall constitute your acceptance of such modifications.',
                    ),

                    _buildParagraph(
                      'DESCRIPTION OF SERVICE',
                      'iTOURu is a comprehensive campus navigation and information system designed exclusively for use within the premises of Bicol University. The Application provides users with access to interactive digital mapping services, real-time global positioning system (GPS) navigation, location-based wayfinding assistance, detailed information regarding university buildings, offices, facilities, and points of interest, virtual campus tour functionality, and comprehensive search capabilities for campus locations and services. The Application is provided as a convenience to the university community and visitors, and while we endeavor to maintain accuracy and reliability, we reserve the right to modify, suspend, or discontinue any aspect of the service at any time without prior notice.',
                    ),

                    _buildParagraph(
                      'USER ACCOUNTS AND REGISTRATION',
                      'The Application offers two distinct modes of access: authenticated Bicol University accounts and guest access. Users registering with a Bicol University account must utilize official university-issued credentials and are granted full access to all application features and functionalities. Such accounts remain active for the duration of the user\'s affiliation with the university. Guest accounts provide limited access to basic navigation features and are subject to automatic session expiration after twenty-four hours of initial access or upon termination of the application session, whichever occurs first. Users are solely responsible for maintaining the confidentiality and security of their account credentials and for all activities that occur under their account. You agree to immediately notify us of any unauthorized use of your account or any other breach of security. The University shall not be liable for any loss or damage arising from your failure to protect your account information.',
                    ),

                    _buildParagraph(
                      'ACCEPTABLE USE AND PROHIBITED CONDUCT',
                      'You agree to use the Application solely for lawful purposes and in accordance with these Terms. Acceptable uses include navigating to campus locations, accessing publicly available campus information, utilizing location services for wayfinding purposes, and viewing virtual campus tours. You expressly agree not to use the Application in any manner that violates any applicable federal, state, local, or international law or regulation; infringes upon or violates the intellectual property rights or privacy rights of the University or any third party; transmits any material that is defamatory, obscene, indecent, abusive, offensive, harassing, violent, hateful, inflammatory, or otherwise objectionable; transmits any advertising or promotional material, including junk mail, spam, chain letters, or any other form of solicitation; impersonates or attempts to impersonate the University, a University employee, another user, or any other person or entity; engages in any conduct that restricts or inhibits anyone\'s use or enjoyment of the Application, or which, as determined by us, may harm the University or users of the Application or expose them to liability; attempts to gain unauthorized access to any portion of the Application, other users\' accounts, or any systems or networks connected to the Application; interferes with or disrupts the Application or servers or networks connected to the Application; or uses the Application in any manner that could disable, overburden, damage, or impair the Application.',
                    ),

                    _buildParagraph(
                      'LOCATION SERVICES AND DATA',
                      'The Application requires access to your device\'s location services to provide core functionality, including displaying your current position on campus maps, providing turn-by-turn navigation instructions, calculating optimal routes and distances between locations, and determining your proximity to campus facilities. Location data is collected only when the Application is actively in use and is processed in real-time to provide navigation services. By using the Application, you consent to the collection and processing of your location data as described herein. You may control location permissions through your device settings; however, disabling location access will significantly impair or prevent the proper functioning of navigation features. We do not store your precise location data permanently and do not track your location when the Application is not in active use.',
                    ),

                    _buildParagraph(
                      'CONTENT ACCURACY AND UPDATES',
                      'While the University makes reasonable efforts to ensure that all information, maps, locations, and facility details provided through the Application are accurate and current, we do not warrant or guarantee the accuracy, completeness, reliability, or timeliness of any content. Campus information, including building locations, office assignments, facility hours, and available services, is subject to change without notice. The Application displays information retrieved from our content management system, which is updated periodically. Users are advised to verify critical information, such as office hours, room assignments, or event locations, through official university channels before making important decisions based solely on information provided by the Application.',
                    ),

                    _buildParagraph(
                      'INTELLECTUAL PROPERTY RIGHTS',
                      'The Application, including all content, features, functionality, software code, user interface design, graphics, logos, maps, and documentation, is the exclusive property of Bicol University and is protected by Philippine and international copyright, trademark, patent, trade secret, and other intellectual property laws. These Terms grant you a limited, non-exclusive, non-transferable, non-sublicensable, revocable license to access and use the Application solely for personal, non-commercial purposes in accordance with these Terms. You may not reproduce, distribute, modify, create derivative works of, publicly display, publicly perform, republish, download, store, or transmit any of the material on our Application, except as incidentally necessary for normal use of the Application. You may not reverse engineer, decompile, disassemble, or otherwise attempt to discover the source code of the Application. Campus maps and geographic data may not be extracted, downloaded, or used for any commercial purposes or in any manner inconsistent with these Terms.',
                    ),

                    _buildParagraph(
                      'DISCLAIMER OF WARRANTIES',
                      'THE APPLICATION IS PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE, AND NON-INFRINGEMENT. THE UNIVERSITY DOES NOT WARRANT THAT THE APPLICATION WILL BE UNINTERRUPTED, SECURE, OR ERROR-FREE; THAT DEFECTS WILL BE CORRECTED; THAT THE APPLICATION OR THE SERVERS THAT MAKE IT AVAILABLE ARE FREE OF VIRUSES OR OTHER HARMFUL COMPONENTS; OR THAT THE APPLICATION WILL MEET YOUR REQUIREMENTS OR EXPECTATIONS. GPS AND LOCATION SERVICES ARE DEPENDENT ON VARIOUS FACTORS INCLUDING DEVICE CAPABILITIES, SATELLITE VISIBILITY, NETWORK CONNECTIVITY, AND ENVIRONMENTAL CONDITIONS, AND THE UNIVERSITY MAKES NO REPRESENTATIONS REGARDING THE PRECISION OR RELIABILITY OF LOCATION DATA. THE UNIVERSITY DOES NOT GUARANTEE COMPATIBILITY WITH ALL DEVICES OR OPERATING SYSTEMS.',
                    ),

                    _buildParagraph(
                      'LIMITATION OF LIABILITY',
                      'TO THE FULLEST EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL BICOL UNIVERSITY, ITS TRUSTEES, OFFICERS, EMPLOYEES, AGENTS, AFFILIATES, OR LICENSORS BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING WITHOUT LIMITATION, LOSS OF PROFITS, DATA, USE, GOODWILL, OR OTHER INTANGIBLE LOSSES, RESULTING FROM YOUR ACCESS TO OR USE OF OR INABILITY TO ACCESS OR USE THE APPLICATION; ANY CONDUCT OR CONTENT OF ANY THIRD PARTY ON THE APPLICATION; ANY CONTENT OBTAINED FROM THE APPLICATION; OR UNAUTHORIZED ACCESS, USE, OR ALTERATION OF YOUR TRANSMISSIONS OR CONTENT, WHETHER BASED ON WARRANTY, CONTRACT, TORT (INCLUDING NEGLIGENCE), OR ANY OTHER LEGAL THEORY, WHETHER OR NOT WE HAVE BEEN INFORMED OF THE POSSIBILITY OF SUCH DAMAGE. THE UNIVERSITY SHALL NOT BE LIABLE FOR ANY ERRORS IN NAVIGATION, DELAYS IN REACHING DESTINATIONS, OR ANY CONSEQUENCES ARISING FROM RELIANCE ON INFORMATION PROVIDED BY THE APPLICATION.',
                    ),

                    _buildParagraph(
                      'MODIFICATIONS TO TERMS',
                      'The University reserves the right, at its sole discretion, to modify, amend, or replace these Terms at any time. We will provide notice of material changes by updating the "Last Updated" date at the beginning of these Terms and, where appropriate, may provide additional notice through the Application or via email to registered users. Your continued use of the Application following the posting of revised Terms constitutes your acceptance of and agreement to be bound by such changes. You are responsible for reviewing these Terms periodically to ensure you are aware of any modifications. If you do not agree to the modified Terms, you must discontinue use of the Application.',
                    ),

                    _buildParagraph(
                      'TERMINATION AND SUSPENSION',
                      'The University reserves the right to suspend or terminate your access to the Application immediately, with or without cause, with or without notice, and without liability. Grounds for termination or suspension include, but are not limited to, breach of these Terms, engagement in fraudulent or illegal activity, conduct that is harmful to other users or the University, misuse or abuse of Application features, violation of university policies or regulations, or termination of your affiliation with the University. Upon termination, your right to use the Application will immediately cease, and you must destroy all copies of any Application materials in your possession.',
                    ),

                    _buildParagraph(
                      'GOVERNING LAW AND DISPUTE RESOLUTION',
                      'These Terms shall be governed by and construed in accordance with the laws of the Republic of the Philippines, without regard to its conflict of law provisions. Any dispute, controversy, or claim arising out of or relating to these Terms or the Application shall be subject to the exclusive jurisdiction of the courts located in Legazpi City, Albay, Philippines. You agree to submit to the personal jurisdiction of such courts and waive any objection based on improper venue or forum non conveniens.',
                    ),

                    _buildParagraph(
                      'SEVERABILITY AND WAIVER',
                      'If any provision of these Terms is found to be unenforceable or invalid under any applicable law, such unenforceability or invalidity shall not render these Terms unenforceable or invalid as a whole, and such provisions shall be deleted without affecting the remaining provisions herein. No waiver of any term of these Terms shall be deemed a further or continuing waiver of such term or any other term, and the University\'s failure to assert any right or provision under these Terms shall not constitute a waiver of such right or provision.',
                    ),

                    _buildParagraph(
                      'CONTACT INFORMATION',
                      'For any questions, concerns, or notices regarding these Terms of Service, please contact us at: Email: jcml2022-2902-58530@bicol-u.edu.ph, Bicol University, Legazpi City, Albay, Philippines. All formal notices and communications regarding these Terms should be sent to the address above and will be deemed given when received.',
                    ),

                    const SizedBox(height: 12),

                    // Acknowledgment Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'By using iTOURu, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Checkbox
            InkWell(
              onTap: () {
                setState(() {
                  _hasAccepted = !_hasAccepted;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _hasAccepted,
                        onChanged: (value) {
                          setState(() {
                            _hasAccepted = value ?? false;
                          });
                        },
                        activeColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'I have read and agree to the Terms of Service',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Close Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _hasAccepted
                    ? () => Navigator.pop(context, true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasAccepted
                      ? Colors.blue
                      : Colors.grey[300],
                  foregroundColor: _hasAccepted
                      ? Colors.white
                      : Colors.grey[500],
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[500],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _hasAccepted ? 2 : 0,
                ),
                child: Text(
                  'I Understand',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            textAlign: TextAlign.justify,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// Privacy Policy Modal
class PrivacyPolicyModal extends StatefulWidget {
  const PrivacyPolicyModal({super.key});

  @override
  State<PrivacyPolicyModal> createState() => _PrivacyPolicyModalState();
}

class _PrivacyPolicyModalState extends State<PrivacyPolicyModal> {
  bool _hasAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.privacy_tip,
                    color: Colors.green[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Privacy Policy',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Effective Date: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),

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

                    const SizedBox(height: 12),

                    // Privacy Commitment Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_user,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your privacy is important to us. We are committed to protecting your personal information and being transparent about our data practices.',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
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
            ),

            const SizedBox(height: 16),

            // Checkbox
            InkWell(
              onTap: () {
                setState(() {
                  _hasAccepted = !_hasAccepted;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _hasAccepted,
                        onChanged: (value) {
                          setState(() {
                            _hasAccepted = value ?? false;
                          });
                        },
                        activeColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'I have read and understand the Privacy Policy',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Close Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _hasAccepted
                    ? () => Navigator.pop(context, true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasAccepted
                      ? Colors.green
                      : Colors.grey[300],
                  foregroundColor: _hasAccepted
                      ? Colors.white
                      : Colors.grey[500],
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[500],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _hasAccepted ? 2 : 0,
                ),
                child: Text(
                  'I Understand',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            textAlign: TextAlign.justify,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
