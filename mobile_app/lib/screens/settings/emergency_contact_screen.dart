import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = true;
  List<String> _messageHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSavedContact();
  }

  Future<void> _loadSavedContact() async {
    final prefs = await SharedPreferences.getInstance();

    // Load message history
    final historyJson = prefs.getString('message_history');
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = json.decode(historyJson);
        _messageHistory = decoded.cast<String>();
      } catch (e) {
        _messageHistory = [];
      }
    }

    setState(() {
      _phoneController.text = prefs.getString('emergency_phone') ?? '';
      _nameController.text = prefs.getString('emergency_name') ?? '';
      _messageController.text = prefs.getString('emergency_message') ??
          '🚨 ACCIDENT DETECTED BY HANINY\\nI need immediate help!';
      _isLoading = false;
    });
  }

  Future<void> _saveContact() async {
    if (_phoneController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a phone number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_phone', _phoneController.text);
    await prefs.setString('emergency_name', _nameController.text);
    await prefs.setString('emergency_message', _messageController.text);

    // Save to message history
    if (!_messageHistory.contains(_messageController.text)) {
      _messageHistory.insert(0, _messageController.text);
      if (_messageHistory.length > 5) {
        _messageHistory = _messageHistory.sublist(0, 5);
      }
      await prefs.setString('message_history', json.encode(_messageHistory));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Emergency contact saved'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Use Future.delayed to ensure snackbar shows before popping
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _selectMessageFromHistory(String message) {
    setState(() {
      _messageController.text = message;
    });
  }

  Future<void> _deleteMessage(int index) async {
    setState(() {
      _messageHistory.removeAt(index);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('message_history', json.encode(_messageHistory));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message deleted'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showMessagePreview(String message, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saved Message'),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _selectMessageFromHistory(message);
            },
            child: const Text('Use This'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteMessage(index);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        // Ensure clean navigation
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Emergency Contact'),
          backgroundColor: const Color(0xFF7FC8A9),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'In case of detected accident, this contact will be alerted by SMS and automatic call.',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Contact Name
              const Text(
                'Contact Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g., Dad, Mom, Friend...',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Phone Number
              const Text(
                'Phone Number *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'e.g., 0612345678',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Custom Message
              const Text(
                'Custom Emergency Message',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Message sent in case of accident',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'GPS location will be automatically added to the message',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),

              // Message History
              if (_messageHistory.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Saved Messages',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._messageHistory.asMap().entries.map((entry) {
                  final index = entry.key;
                  final message = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showMessagePreview(message, index),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5F0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.message,
                                  color: Color(0xFF7FC8A9),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap to view full message',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check, size: 20),
                                    color: const Color(0xFF7FC8A9),
                                    onPressed: () =>
                                        _selectMessageFromHistory(message),
                                    tooltip: 'Use this message',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20),
                                    color: Colors.red,
                                    onPressed: () => _deleteMessage(index),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveContact,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7FC8A9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
