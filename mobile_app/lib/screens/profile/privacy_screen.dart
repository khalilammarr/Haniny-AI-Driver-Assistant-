import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: const Color(0xFF7FC8A9),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Privacy Policy',
              'Your privacy is important to us. This application is designed to enhance driver safety while respecting your personal information.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Data Collection',
              'We collect the following data:\n\n'
                  '• Driving behavior metrics (speed, acceleration, braking)\n'
                  '• Safety alerts (drowsiness, distraction, smoking)\n'
                  '• Trip history and scores\n'
                  '• GPS location during trips\n'
                  '• Camera frames for real-time analysis\n\n'
                  'All data is collected solely for safety monitoring and improvement purposes.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Data Usage',
              'Your data is used to:\n\n'
                  '• Provide real-time safety alerts\n'
                  '• Calculate driving scores\n'
                  '• Generate trip statistics\n'
                  '• Detect accidents and emergencies\n'
                  '• Improve our detection algorithms\n\n'
                  'We do NOT sell or share your personal data with third parties for marketing purposes.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Data Security',
              'We implement industry-standard security measures:\n\n'
                  '• End-to-end encryption for data transmission\n'
                  '• Secure authentication with JWT tokens\n'
                  '• Password hashing using bcrypt\n'
                  '• Secure database storage\n'
                  '• Regular security audits\n\n'
                  'Your data is stored on secure servers and protected against unauthorized access.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Camera & Location Access',
              'The app requires camera and location permissions to:\n\n'
                  '• Monitor driver behavior in real-time\n'
                  '• Detect safety hazards\n'
                  '• Provide accurate trip tracking\n'
                  '• Send emergency location in case of accidents\n\n'
                  'Camera frames are processed locally and only metadata is transmitted to our servers.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Your Rights',
              'You have the right to:\n\n'
                  '• Access your personal data\n'
                  '• Request data deletion\n'
                  '• Opt-out of data collection\n'
                  '• Export your trip history\n'
                  '• Update your information\n\n'
                  'Contact us at support@haniny.com to exercise these rights.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Data Retention',
              'We retain your data for as long as your account is active. Trip history is kept for 90 days by default. You can request earlier deletion at any time.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Updates to Privacy Policy',
              'We may update this privacy policy from time to time. We will notify you of any significant changes via email or in-app notification.',
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Last updated: November 2024',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Color(0xFF34495E),
          ),
        ),
      ],
    );
  }
}
