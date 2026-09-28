import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../auth/welcome_screen.dart';
import '../settings/emergency_contact_screen.dart';
import 'settings_screen.dart';
import 'privacy_screen.dart';
import 'help_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final profile = await _apiService.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
  }

  void _showModal(String title, Widget content) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5E6D3),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.close, color: Color(0xFF2C3E50)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: content,
                    ),
                  ),
                  // Footer Button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale:
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack).value,
          child: child,
        );
      },
    );
  }

  Widget _buildPrivacyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Privacy Policy',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          'Your data is secure with us. We only use your camera data for real-time analysis and do not store video feeds permanently unless explicitly saved for incident reporting.',
          style: TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF455A64)),
        ),
        SizedBox(height: 20),
        Text(
          'Data Security',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          'All transmission is encrypted using industry-standard protocols. Your personal information is never shared with third parties.',
          style: TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF455A64)),
        ),
      ],
    );
  }

  Widget _buildHelpContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'How it works',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          'The app uses your phone camera to monitor road conditions and driver alertness. Ensure your phone is mounted securely with a clear view of the road.',
          style: TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF455A64)),
        ),
        SizedBox(height: 20),
        Text(
          'Contact Support',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          'Need help? Email us at support@haniny.com or call our 24/7 helpline.',
          style: TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF455A64)),
        ),
      ],
    );
  }

  void _showPairDeviceDialog(BuildContext context) {
    final deviceIdController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Pair Device'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Enter the 6-digit ID displayed on your hardware device.'),
              const SizedBox(height: 16),
              TextField(
                controller: deviceIdController,
                decoration: InputDecoration(
                  labelText: 'Device ID',
                  border: const OutlineInputBorder(),
                  errorText: errorMessage,
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              if (isLoading)
                const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: CircularProgressIndicator()),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final deviceId = deviceIdController.text.trim();

                      // Validate device ID
                      if (deviceId.length != 6 ||
                          !RegExp(r'^\d{6}$').hasMatch(deviceId)) {
                        setState(
                            () => errorMessage = 'Must be exactly 6 digits');
                        return;
                      }

                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      final success = await _apiService.pairDevice(deviceId);

                      if (mounted) {
                        setState(() => isLoading = false);
                        Navigator.pop(context);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Device Paired Successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _fetchProfile(); // Refresh UI
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Failed to pair device. Check the ID and try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Pair'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnpairDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpair Device'),
        content: const Text(
            'Are you sure you want to disconnect from this device? You will stop receiving alerts from it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              setState(() => _isLoading = true);

              final success = await _apiService.unpairDevice();

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Device unpaired successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _fetchProfile(); // Refresh profile to update UI
                } else {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to unpair device'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Unpair'),
          ),
        ],
      ),
    );
  }

  void _showInsuranceReward() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7FC8A9), Color(0xFF5F9E7E)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '🎉 Congratulations!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Safe Driving Reward',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your excellent driving has earned you:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '15% OFF',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7FC8A9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'on your next insurance premium',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Excellent Driving Score!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF7FC8A9),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Awesome!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: null,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Profile',
          style:
              TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                children: [
                  // User Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7FC8A9).withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF7FC8A9), width: 3),
                          ),
                          child: const CircleAvatar(
                            radius: 50,
                            backgroundColor: Color(0xFFF5E6D3),
                            child: Icon(Icons.person,
                                size: 50, color: Color(0xFF7FC8A9)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userProfile?['full_name'] ?? 'Ahmed Mohamed',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _userProfile?['email'] ?? 'demo@haniny.com',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF455A64),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _userProfile?['car_model'] ?? 'Golf',
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats Section

                  const SizedBox(height: 24),

                  // Menu Options
                  _buildMenuCard(
                    title: 'Privacy & Security',
                    icon: Icons.security,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuCard(
                    title: 'Help & Support',
                    icon: Icons.help_outline,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuCard(
                    title: 'Notifications & Rewards',
                    icon: Icons.notifications_active,
                    onTap: () => _showInsuranceReward(),
                  ),
                  const SizedBox(height: 20),
                  if (_userProfile?['device_id'] != null)
                    _buildMenuCard(
                      icon: Icons.link_off,
                      title: 'Unpair Device (${_userProfile!['device_id']})',
                      isDestructive: true,
                      onTap: () => _showUnpairDialog(context),
                    )
                  else
                    _buildMenuCard(
                      icon: Icons.devices,
                      title: 'Pair Hardware Device',
                      onTap: () => _showPairDeviceDialog(context),
                    ),
                  const SizedBox(height: 16),
                  _buildMenuCard(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuCard(
                    title: 'Emergency Contact',
                    icon: Icons.emergency,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmergencyContactScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuCard(
                    title: 'Logout',
                    icon: Icons.logout,
                    isDestructive: true,
                    onTap: _logout,
                  ),

                  const SizedBox(height: 40),

                  // Bottom Logo
                  Opacity(
                    opacity: 0.7,
                    child: Image.asset(
                      'assets/haniny_green.png',
                      height: 160,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? const Color(0xFFFFEBEE)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (isDestructive
                                ? Colors.red
                                : const Color(0xFF7FC8A9))
                            .withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: isDestructive ? Colors.red : const Color(0xFF7FC8A9),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          isDestructive ? Colors.red : const Color(0xFF2C3E50),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
