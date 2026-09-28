import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../widgets/score_evolution_widget.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with WidgetsBindingObserver {
  final _apiService = ApiService();
  bool _isLoading = true;
  List<double> _scoreHistory = [];
  List<Map<String, dynamic>> _trips = [];
  double _averageScore = 0.0;
  String _currentView = 'daily'; // 'daily' or 'weekly'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchStats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh stats when app comes back to foreground
      _fetchStats();
    }
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);

    final stats = _currentView == 'daily'
        ? await _apiService.getDailyStats()
        : await _apiService.getWeeklyStats();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (stats != null && stats['data'] != null) {
          final data = stats['data'] as List;

          // Extract scores for evolution chart
          _scoreHistory = [];
          for (var item in data) {
            final avgScore = (item['average_score'] as num?)?.toDouble() ?? 0.0;
            if (avgScore > 0) {
              _scoreHistory.add(avgScore);
            }
          }

          // Calculate overall average
          if (_scoreHistory.isNotEmpty) {
            _averageScore =
                _scoreHistory.reduce((a, b) => a + b) / _scoreHistory.length;
          } else {
            _averageScore = 0.0;
          }

          // Process trips data
          _trips = data.map((item) {
            final trips = item['trips'] as List? ?? [];
            return {
              'date': _currentView == 'daily'
                  ? _formatDate(item['date'] ?? '')
                  : item['week'] ?? '',
              'trip_count': trips.length,
              'total_alerts': item['total_alerts'] ?? 0,
              'average_score':
                  (item['average_score'] as num?)?.toDouble() ?? 0.0,
              'trips_data': trips, // Store the raw trips list
            };
          }).toList();
        }
      });

      // Show insurance reward if good driving score
      if (_averageScore >= 85 && _trips.length >= 5) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _showInsuranceReward();
        });
      }
    }
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
                        children: [
                          const Icon(Icons.star,
                              color: Color(0xFFFFD700), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Your Score: ${_averageScore.toStringAsFixed(1)}',
                            style: const TextStyle(
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return "${months[date.month - 1]} ${date.day}";
    } catch (e) {
      return dateStr;
    }
  }

  String _getTripTitle(Map<String, dynamic> trip) {
    try {
      final startTime = trip['start_time'];
      if (startTime != null && startTime is String) {
        final dateTime = DateTime.parse(startTime);
        final hour = dateTime.hour;
        final minute = dateTime.minute.toString().padLeft(2, '0');

        // Determine time of day
        String timeOfDay;
        if (hour < 12) {
          timeOfDay = 'Morning';
        } else if (hour < 17) {
          timeOfDay = 'Afternoon';
        } else {
          timeOfDay = 'Evening';
        }

        return '$timeOfDay Trip ($hour:$minute)';
      }
    } catch (e) {
      // Fallback
    }
    return 'Trip';
  }

  String _formatDuration(String? durationStr) {
    if (durationStr == null || durationStr == 'N/A') return 'N/A';
    try {
      // Parse duration in format "HH:MM:SS" or seconds
      final parts = durationStr.split(':');
      if (parts.length == 3) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        if (hours > 0) {
          return '${hours}h ${minutes}m';
        } else {
          return '${minutes}m';
        }
      }
      // If it's just seconds
      final seconds = int.tryParse(durationStr);
      if (seconds != null) {
        final hours = seconds ~/ 3600;
        final minutes = (seconds % 3600) ~/ 60;
        if (hours > 0) {
          return '${hours}h ${minutes}m';
        } else if (minutes > 0) {
          return '${minutes}m';
        } else {
          return '${seconds}s';
        }
      }
      return durationStr;
    } catch (e) {
      return durationStr;
    }
  }

  void _showTripAlerts(Map<String, dynamic> trip, int tripNumber) {
    final alerts = trip['alerts'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTripTitle(trip),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Text(
                        'Duration: ${_formatDuration(trip['duration'])}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          _getScoreColor((trip['score'] as num?)?.toInt() ?? 0)
                              .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Score: ${(trip['score'] as num?)?.toInt() ?? 0}',
                      style: TextStyle(
                        color: _getScoreColor(
                            (trip['score'] as num?)?.toInt() ?? 0),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            // Alerts List
            Expanded(
              child: alerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 64, color: Colors.green[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Perfect Trip! No alerts.',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(alert['severity'])
                                .withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          _getSeverityColor(alert['severity'])
                                              .withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getAlertIcon(alert['type']),
                                  color: _getSeverityColor(alert['severity']),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alert['type'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    Text(
                                      'Time: ${alert['time']}',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _getSeverityColor(alert['severity'])
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  alert['severity'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getSeverityColor(alert['severity']),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayDetails(Map<String, dynamic> daySummary) {
    final trips = daySummary['trips_data'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        daySummary['date'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Text(
                        '${trips.length} Trips • ${daySummary['total_alerts']} Alerts',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getScoreColor(daySummary['average_score'].round())
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Avg: ${daySummary['average_score'].toStringAsFixed(0)}',
                      style: TextStyle(
                        color:
                            _getScoreColor(daySummary['average_score'].round()),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            // Trips List
            Expanded(
              child: trips.isEmpty
                  ? Center(
                      child: Text(
                        'No trips recorded for this period.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        final trip = trips[index];
                        final alerts = trip['alerts'] as List? ?? [];
                        final score = (trip['score'] as num?)?.toInt() ?? 0;

                        return GestureDetector(
                          onTap: () => _showTripAlerts(trip, index + 1),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Trip ${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getScoreColor(score)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Score: $score',
                                        style: TextStyle(
                                          color: _getScoreColor(score),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDuration(trip['duration']),
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(Icons.warning_amber_rounded,
                                        size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${alerts.length} alert${alerts.length != 1 ? 's' : ''}',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Tap to view details',
                                      style: TextStyle(
                                        color: const Color(0xFF7FC8A9),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: Color(0xFF7FC8A9),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, String value) {
    final isSelected = _currentView == value;
    return GestureDetector(
      onTap: () {
        if (_currentView != value) {
          setState(() {
            _currentView = value;
          });
          _fetchStats();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7FC8A9) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF2C3E50),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xFF7FC8A9); // Green
    if (score >= 70) return const Color(0xFFFF8C42); // Orange
    return Colors.redAccent;
  }

  Color _getSeverityColor(String severity) {
    final severityLower = severity.toLowerCase();
    switch (severityLower) {
      case 'critical':
      case 'high':
        return Colors.redAccent;
      case 'warning':
      case 'medium':
        return const Color(0xFFFF8C42);
      default:
        return const Color(0xFF7FC8A9);
    }
  }

  IconData _getAlertIcon(String type) {
    final typeLower = type.toLowerCase();

    // Fatigue & Attention
    if (typeLower.contains('drowsy') || typeLower.contains('drowsiness')) {
      return Icons.bedtime;
    }
    if (typeLower.contains('yawn')) {
      return Icons.sentiment_dissatisfied;
    }
    if (typeLower.contains('eyes') || typeLower.contains('closed')) {
      return Icons.visibility_off;
    }
    if (typeLower.contains('head') || typeLower.contains('nod')) {
      return Icons.airline_seat_recline_extra;
    }

    // Distraction
    if (typeLower.contains('phone') || typeLower.contains('distraction')) {
      return Icons.phone_android;
    }
    if (typeLower.contains('looking') || typeLower.contains('away')) {
      return Icons.visibility_off;
    }
    if (typeLower.contains('smoking')) {
      return Icons.smoke_free;
    }
    if (typeLower.contains('eating')) {
      return Icons.restaurant;
    }

    // Road Safety
    if (typeLower.contains('animal')) {
      return Icons.pets;
    }
    if (typeLower.contains('pedestrian')) {
      return Icons.directions_walk;
    }
    if (typeLower.contains('cyclist') || typeLower.contains('bike')) {
      return Icons.directions_bike;
    }
    if (typeLower.contains('obstacle') || typeLower.contains('pothole')) {
      return Icons.report_problem;
    }

    // Traffic Violations
    if (typeLower.contains('stop sign')) {
      return Icons.stop;
    }
    if (typeLower.contains('red light')) {
      return Icons.traffic;
    }
    if (typeLower.contains('speed')) {
      return Icons.speed;
    }
    if (typeLower.contains('lane') && typeLower.contains('wrong')) {
      return Icons.wrong_location;
    }

    // Driving Behavior
    if (typeLower.contains('harsh') && typeLower.contains('brak')) {
      return Icons.front_hand;
    }
    if (typeLower.contains('harsh') && typeLower.contains('accel')) {
      return Icons.rocket_launch;
    }
    if (typeLower.contains('sharp') || typeLower.contains('turn')) {
      return Icons.turn_sharp_right;
    }
    if (typeLower.contains('tailgat')) {
      return Icons.car_crash;
    }
    if (typeLower.contains('lane') && typeLower.contains('departure')) {
      return Icons.alt_route;
    }

    // Environmental
    if (typeLower.contains('co2') || typeLower.contains('emission')) {
      return Icons.cloud;
    }
    if (typeLower.contains('idling')) {
      return Icons.local_gas_station;
    }

    // Default
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Driving History',
          style:
              TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Daily/Weekly Toggle
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleButton('Daily', 'daily'),
                _buildToggleButton('Weekly', 'weekly'),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(
                children: [
                  // Evolution Chart
                  if (_scoreHistory.isNotEmpty)
                    ScoreEvolutionWidget(scoreHistory: _scoreHistory)
                  else
                    const SizedBox(
                      height: 200,
                      child: Center(child: Text("No driving history yet")),
                    ),
                  const SizedBox(height: 24),

                  // Average Score Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7FC8A9).withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Average Score',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF5F7A6A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Last 7 Days',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5F0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _averageScore.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7FC8A9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Recent Trips',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Trips List
                  ..._trips.map((trip) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _showDayDetails(trip),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Date/Week Badge
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5F0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _currentView == 'daily'
                                      ? Icons.calendar_today
                                      : Icons.date_range,
                                  color: const Color(0xFF7FC8A9),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Trip Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      trip['date'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${trip['trip_count']} trip(s) • ${trip['total_alerts']} alert(s)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Score Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getScoreColor(
                                          (trip['average_score'] as double? ??
                                                  0.0)
                                              .round())
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  (trip['average_score'] as double? ?? 0.0)
                                      .toStringAsFixed(0),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _getScoreColor(
                                        (trip['average_score'] as double? ??
                                                0.0)
                                            .round()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }
}
