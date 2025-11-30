import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
          'Terms of Service',
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
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.description,
                  color: Colors.blue[700],
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: Text(
                'Last Updated: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
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
              'ACCEPTANCE OF TERMS',
              'By accessing, downloading, installing, or using the iTOURu mobile application (hereinafter referred to as "the Application" or "the App"), you acknowledge that you have read, understood, and agree to be bound by these Terms of Service...',
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

            const SizedBox(height: 24),

            // Acknowledgment Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'By using iTOURu, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
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
