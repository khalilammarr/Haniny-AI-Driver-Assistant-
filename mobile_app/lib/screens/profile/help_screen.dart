import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: const Color(0xFF7FC8A9),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Getting Started'),
            const SizedBox(height: 16),
            _buildFaqItem(
              'How do I set up the app?',
              '1. Create an account or log in\n'
                  '2. Pair your hardware device using the 6-digit code\n'
                  '3. Set up your emergency contact\n'
                  '4. Grant camera and location permissions\n'
                  '5. Start your first trip!',
            ),
            _buildFaqItem(
              'How do I pair my device?',
              'Go to Profile → Pair Device and enter the 6-digit code displayed on your hardware device. Make sure both devices are connected to the internet.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Using the App'),
            const SizedBox(height: 16),
            _buildFaqItem(
              'How does the safety monitoring work?',
              'The app uses advanced AI to monitor:\n\n'
                  '• Driver drowsiness (eye closure, yawning)\n'
                  '• Distraction (looking away from road)\n'
                  '• Smoking while driving\n'
                  '• Poor posture\n'
                  '• Road signs (stop signs, speed limits)\n'
                  '• Animals on the road\n\n'
                  'Real-time alerts help you stay safe.',
            ),
            _buildFaqItem(
              'What is the driving score?',
              'Your driving score starts at 100 and decreases based on safety violations. Scores are calculated per trip:\n\n'
                  '• 90-100: Excellent\n'
                  '• 70-89: Good\n'
                  '• 50-69: Fair\n'
                  '• Below 50: Needs Improvement',
            ),
            _buildFaqItem(
              'How is CO2 emission calculated?',
              'CO2 emissions are estimated based on your driving behavior:\n\n'
                  '• Speed variations\n'
                  '• Acceleration patterns\n'
                  '• Trip duration\n'
                  '• Distance traveled\n\n'
                  'Smooth driving reduces emissions!',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Safety Features'),
            const SizedBox(height: 16),
            _buildFaqItem(
              'What happens during accident detection?',
              'If a severe impact is detected (G-force > 2.5g):\n\n'
                  '1. Emergency contact is immediately notified via SMS\n'
                  '2. Automatic call is placed to emergency contact\n'
                  '3. Your GPS location is shared\n'
                  '4. Alert is logged in your trip history\n\n'
                  'You have 10 seconds to cancel false alarms.',
            ),
            _buildFaqItem(
              'How do I set up emergency contacts?',
              'Go to Profile → Emergency Contact and enter:\n\n'
                  '• Contact name\n'
                  '• Phone number\n'
                  '• Custom emergency message\n\n'
                  'You can save multiple message templates for quick access.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Trip History & Statistics'),
            const SizedBox(height: 16),
            _buildFaqItem(
              'How do I view my trip history?',
              'Go to the Statistics tab to see:\n\n'
                  '• Daily and weekly summaries\n'
                  '• Individual trip details\n'
                  '• Alert history per trip\n'
                  '• Score trends\n'
                  '• CO2 emissions\n\n'
                  'Tap any day to see all trips, then tap a trip to see its alerts.',
            ),
            _buildFaqItem(
              'Why do I see 0 alerts even though I received alerts?',
              'Make sure to:\n\n'
                  '1. End your trip properly in the hardware app\n'
                  '2. Wait a few seconds for data to sync\n'
                  '3. Pull down to refresh the statistics screen\n\n'
                  'The app now auto-refreshes when you return to it!',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Troubleshooting'),
            const SizedBox(height: 16),
            _buildFaqItem(
              'The app is not detecting my face',
              '• Ensure good lighting conditions\n'
                  '• Position camera to capture full face\n'
                  '• Remove sunglasses or face coverings\n'
                  '• Check camera permissions',
            ),
            _buildFaqItem(
              'Alerts are not showing up',
              '• Check internet connection\n'
                  '• Verify device is paired correctly\n'
                  '• Ensure trip is active\n'
                  '• Try restarting the hardware app',
            ),
            _buildFaqItem(
              'My score seems incorrect',
              'Scores are calculated based on:\n\n'
                  '• Number and severity of alerts\n'
                  '• Trip duration\n'
                  '• Driving behavior\n\n'
                  'Each alert type has different point deductions. Check your trip details to see specific alerts.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Privacy & Data'),
            const SizedBox(height: 16),
            _buildFaqItem(
              'Is my data safe?',
              'Yes! We use:\n\n'
                  '• End-to-end encryption\n'
                  '• Secure JWT authentication\n'
                  '• Local processing for camera frames\n'
                  '• No third-party data sharing\n\n'
                  'See Privacy & Security for full details.',
            ),
            _buildFaqItem(
              'Can I delete my data?',
              'Yes, you can:\n\n'
                  '• Delete individual trips\n'
                  '• Clear trip history\n'
                  '• Delete your account entirely\n\n'
                  'Contact support@haniny.com for account deletion.',
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Contact Us'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildContactItem(Icons.email, 'Email', 'support@haniny.com'),
                  const SizedBox(height: 12),
                  _buildContactItem(Icons.phone, 'Phone', '+1 (555) 123-4567'),
                  const SizedBox(height: 12),
                  _buildContactItem(
                      Icons.language, 'Website', 'www.haniny.com'),
                  const SizedBox(height: 12),
                  _buildContactItem(
                      Icons.schedule, 'Support Hours', 'Mon-Fri, 9AM-6PM EST'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Text(
                    'Haniny Driver Safety',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2024 Haniny. All rights reserved.',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C3E50),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.help_outline,
                color: Color(0xFF7FC8A9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF34495E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF7FC8A9), size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
