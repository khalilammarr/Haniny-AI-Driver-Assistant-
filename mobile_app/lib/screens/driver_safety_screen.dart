import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
// import 'dart:ui' as ui; // Removed unused import
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image/image.dart' as img;
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:sensors_plus/sensors_plus.dart';

import '../widgets/driver_profile_widget.dart';
import '../widgets/metrics_row_widget.dart';
import '../widgets/control_buttons_widget.dart';
import '../widgets/alert_overlay_widget.dart';
import '../widgets/co2_metric_widget.dart';
import '../services/api_service.dart';
import '../services/co2_calculator.dart';
import '../services/emergency_service.dart';

class DriverSafetyScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const DriverSafetyScreen({required this.cameras, Key? key}) : super(key: key);

  @override
  State<DriverSafetyScreen> createState() => _DriverSafetyScreenState();
}

class _DriverSafetyScreenState extends State<DriverSafetyScreen>
    with TickerProviderStateMixin {
  CameraController? _driverCam;
  CameraController? _roadCam;
  CameraController? _activeCamera; // Caméra actuellement active
  bool _isDriverCamActive = true; // true = selfie, false = route

  // Stockage des descriptions de caméras (sans les initialiser toutes)
  CameraDescription? _frontCameraDesc; // Description selfie (conducteur)
  CameraDescription? _backCameraDesc; // Description avant (route)

  late AnimationController _borderAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  late AnimationController _alertSlideController;
  late AnimationController _alertShakeController;
  late Animation<Offset> _alertSlideAnimation;
  late Animation<double> _alertShakeAnimation;
  late Animation<double> _alertScaleAnimation;

  IOWebSocketChannel? _channel;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isMonitoring = false;
  bool _cameraEnabled = true;
  bool _isCameraInitialized = false;
  bool _isProcessingFrame = false;
  int _frameCount = 0;
  DateTime? _lastFrameTime;

  double _score = 88.0;
  double _speed = 0.0;
  double _acceleration = 0.0;
  Color _borderColor = Colors.transparent;
  String _alertMessage = '';
  bool _isAlarm = false;

  // CO2 tracking
  double _co2EmissionRate = 0.0; // g/km
  double _totalCO2 = 0.0; // grams
  DateTime? _lastCO2Update;

  String _userName = 'Conducteur';
  String _carModel = 'Véhicule';
  final _apiService = ApiService();

  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;
  DateTime? _lastPositionTime;

  final List<LatLng> _routePoints = [];
  LatLng? _currentPosition;

  bool get _isDesktopOrWeb =>
      kIsWeb || Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  String _deviceId = '...';
  String? _pairedUserName;

  // Per-alert-type cooldown system
  final Map<String, DateTime> _lastAlertTimes = {};
  // Rate limit for backend logging (prevent >1 log per second per alert type)
  final Map<String, DateTime> _lastLoggedTimes = {};
  static const Duration _alertCooldown = Duration(seconds: 8);

  int? _currentTripId;

  // Accident detection variables
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  static const double ACCIDENT_THRESHOLD =
      50.0; // G-force threshold (m/s²) - Increased to reduce false alarms
  DateTime? _lastAccidentCheck;
  bool _accidentDetected = false;

  @override
  void initState() {
    super.initState();
    _initializeDeviceId();
    _initializeAnimations();
    _initializeCameras();
    // WebSocket connection will be called after device ID is ready
    _fetchUserProfile();
    if (!_isDesktopOrWeb) _requestLocationPermission();
  }

  Future<void> _initializeDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null) {
      // Generate a random 6-digit ID
      var rng = Random();
      id = (rng.nextInt(900000) + 100000).toString();
      await prefs.setString('device_id', id);
    }
    setState(() {
      _deviceId = id!;
    });
    _checkPairedUser();
    _connectWebSocket();
  }

  Future<void> _fetchUserProfile() async {
    final profile = await _apiService.getUserProfile();
    if (mounted) {
      setState(() {
        if (profile != null) {
          _userName = profile['full_name'] ?? 'Conducteur';
          _carModel = profile['car_model'] ?? 'Véhicule';
        }
      });
    }
  }

  Future<void> _simulateAccident() async {
    debugPrint('🚨 SIMULATION ACCIDENT');

    // 1. Trigger local alert
    _triggerAlert(isAlarm: true, message: 'ACCIDENT DÉTECTÉ!');

    // 2. Send to backend/User App via WebSocket
    // In a real scenario, this would be sent via MQTT or direct API
    // For prototype, we'll use the existing WebSocket channel to broadcast

    final accidentData = {
      'type': 'ACCIDENT',
      'device_id': _deviceId,
      'timestamp': DateTime.now().toIso8601String(),
      'acceleration_g': 6.5, // Simulated high impact
      'gps': {
        'lat': _currentPosition?.latitude ?? 48.8566,
        'lon': _currentPosition?.longitude ?? 2.3522
      },
    };

    // Send via WebSocket (if connected)
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(accidentData));
      debugPrint('📤 Accident data sent via WebSocket');
    }

    // Also call API endpoint
    try {
      // We need to implement reportAccident in ApiService or call endpoint directly
      // For now, let's assume the WebSocket broadcast is enough for the prototype demo
      // or we can add a specific API call here if needed.
    } catch (e) {
      debugPrint('❌ Error reporting accident: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 Accident simulé et envoyé!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _initializeAnimations() {
    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _alertSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _alertSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _alertSlideController,
      curve: Curves.elasticOut,
    ));

    _alertScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _alertSlideController,
        curve: Curves.easeOutBack,
      ),
    );

    _alertShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _alertShakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _alertShakeController,
      curve: Curves.linear,
    ));
  }

  Future<void> _initializeCameras() async {
    if (!_cameraEnabled || widget.cameras.isEmpty || _isDesktopOrWeb) {
      debugPrint('💻 Skipping camera initialization on Desktop/Web');
      setState(() => _isCameraInitialized = true);
      return;
    }

    try {
      debugPrint('📱 Nombre de caméras disponibles: ${widget.cameras.length}');

      for (int i = 0; i < widget.cameras.length; i++) {
        debugPrint(
            '📷 Caméra $i: ${widget.cameras[i].lensDirection} - ${widget.cameras[i].name}');
      }

      // Identifier les caméras disponibles (sans les initialiser)
      for (var camera in widget.cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          _frontCameraDesc = camera;
          debugPrint(
              '✅ Caméra frontale/selfie (conducteur) détectée: ${camera.name}');
        } else if (camera.lensDirection == CameraLensDirection.back) {
          _backCameraDesc = camera;
          debugPrint('✅ Caméra arrière/avant (route) détectée: ${camera.name}');
        }
      }

      // Fallback si les caméras ne sont pas détectées par lensDirection
      if (_backCameraDesc == null && widget.cameras.isNotEmpty) {
        _backCameraDesc = widget.cameras[0];
        debugPrint('⚠️ Utilisation caméra index 0 (route/avant)');
      }

      if (_frontCameraDesc == null && widget.cameras.length > 1) {
        _frontCameraDesc = widget.cameras[1];
        debugPrint('⚠️ Utilisation caméra index 1 (conducteur/selfie)');
      } else if (_frontCameraDesc == null && widget.cameras.isNotEmpty) {
        _frontCameraDesc = widget.cameras[0];
        debugPrint('⚠️ Une seule caméra trouvée');
      }

      if (_frontCameraDesc == null && _backCameraDesc == null) {
        throw Exception('Aucune caméra disponible');
      }

      // Initialiser UNIQUEMENT la caméra conducteur (selfie) par défaut
      if (_frontCameraDesc != null) {
        _driverCam = CameraController(
          _frontCameraDesc!,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );
        await _driverCam!.initialize();
        _activeCamera = _driverCam;
        _isDriverCamActive = true;
        debugPrint(
            '✅ Caméra conducteur (selfie) initialisée: ${_driverCam!.value.previewSize}');
        debugPrint('🎯 Caméra active: Conducteur (selfie)');
      } else if (_backCameraDesc != null) {
        // Si pas de caméra frontale, initialiser l'arrière
        _roadCam = CameraController(
          _backCameraDesc!,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );
        await _roadCam!.initialize();
        _activeCamera = _roadCam;
        _isDriverCamActive = false;
        debugPrint(
            '✅ Caméra route (avant) initialisée: ${_roadCam!.value.previewSize}');
        debugPrint('🎯 Caméra active: Route (avant)');
      }

      if (mounted) {
        setState(() => _isCameraInitialized = true);
        debugPrint(
            '🎉 Initialisation terminée! Une seule caméra active à la fois.');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ERREUR initialisation caméras: $e');
      debugPrint('📋 StackTrace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur caméra: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _connectWebSocket() async {
    if (_isDesktopOrWeb) return;
    if (_channel != null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id');

      final tripParam =
          _currentTripId != null ? '&trip_id=$_currentTripId' : '';
      final wsUrl = 'ws://192.168.1.159:8000/ws?device_id=$deviceId$tripParam';
      debugPrint('🔌 Connecting to WebSocket: $wsUrl');

      _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));

      _channel?.stream.listen(
        (message) {
          debugPrint('📨 Message WebSocket reçu: $message');
          try {
            final alert = jsonDecode(message);
            debugPrint('📢 Alert décodé: $alert');
            _handleAlert(alert);
          } catch (e) {
            debugPrint('❌ Erreur décodage JSON: $e');
          }
        },
        onError: (error) {
          debugPrint('❌ WebSocket erreur: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('WebSocket erreur: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        onDone: () {
          debugPrint('⚠️ WebSocket connexion fermée');
        },
      );

      debugPrint('✅ WebSocket connecté');
    } catch (e) {
      debugPrint('❌ Connexion WebSocket échouée: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de se connecter au serveur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _handleAlert(Map<String, dynamic> alert) {
    debugPrint('📢 Traitement alert: $alert');

    final message = alert['message'] ?? alert['status'] ?? '';
    final isCritical = alert['critical'] == true;

    debugPrint('  - message: $message');
    debugPrint('  - critical: $isCritical');

    if (message != 'OK' && message.isNotEmpty) {
      _triggerAlert(isAlarm: isCritical, message: message);
      _updateScore(isCritical ? -5 : -2);
    }
  }

  Future<void> _triggerAlert(
      {required bool isAlarm, String message = ''}) async {
    final now = DateTime.now();
    final alertKey =
        message.isEmpty ? (isAlarm ? 'ALARM' : 'WARNING') : message;

    debugPrint('🚨 Alert triggered: isAlarm=$isAlarm, message=$message');

    // Rate limit logging to max 1 per second per alert type
    if (_lastLoggedTimes.containsKey(alertKey) &&
        now.difference(_lastLoggedTimes[alertKey]!) < _alertCooldown) {
      debugPrint(
          '⏳ Logging rate limit active for $alertKey (skip backend log)');
    } else {
      // ALWAYS log alert to backend first (even if visual alert is in cooldown)
      if (_currentTripId != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final baseUrl =
              prefs.getString('backend_url') ?? 'http://192.168.1.159:8000';

          final alertType =
              message.isNotEmpty ? message : (isAlarm ? 'ALARM' : 'WARNING');
          final severity = isAlarm ? 'high' : 'medium';

          final uri =
              Uri.parse('$baseUrl/alerts/log').replace(queryParameters: {
            'trip_id': _currentTripId.toString(),
            'alert_type': alertType,
            'severity': severity,
          });

          debugPrint('📤 Logging alert to backend: $uri');

          final response = await http.post(uri);

          if (response.statusCode == 200) {
            debugPrint('✅ Alert logged to backend: ${response.body}');
          } else {
            debugPrint(
                '⚠️ Failed to log alert: ${response.statusCode} - ${response.body}');
          }
          // Update last logged time
          _lastLoggedTimes[alertKey] = now;
        } catch (e) {
          debugPrint('❌ Error logging alert to backend: $e');
        }
      } else {
        debugPrint('⚠️ No active trip - alert not logged to backend');
      }
    }

    // Check cooldown for VISUAL/AUDIO alert (but we already logged to DB above)
    if (_lastAlertTimes.containsKey(alertKey)) {
      final lastTime = _lastAlertTimes[alertKey]!;
      if (now.difference(lastTime) < _alertCooldown) {
        debugPrint(
            '⏳ Alert cooldown active for $alertKey (visual/audio suppressed, but logged to DB)');
        return; // Skip visual/audio alert but DB logging already happened
      }
    }
    _lastAlertTimes[alertKey] = now;

    setState(() {
      _borderColor =
          isAlarm ? const Color(0xFFFF8C42) : const Color(0xFFF2C078);
      _alertMessage = message.isNotEmpty
          ? message
          : (isAlarm ? 'ALARME!' : 'Avertissement');
      _isAlarm = isAlarm;
    });

    _borderAnimationController.forward(from: 0).then((_) {
      _borderAnimationController.reverse();
    });

    _alertSlideController.forward(from: 0);

    if (isAlarm) {
      _alertShakeController.forward(from: 0);
    }

    try {
      final soundPath = isAlarm ? 'alarm.wav' : 'warning.wav';
      debugPrint('🔊 Tentative lecture du son: $soundPath');

      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource('sounds/$soundPath'),
        volume: 1.0,
        mode: PlayerMode.lowLatency,
      );

      debugPrint('✅ Son joué: $soundPath');
    } catch (e) {
      debugPrint('❌ Erreur son: $e');
    }

    Future.delayed(Duration(seconds: isAlarm ? 2 : 1), () {
      if (mounted) {
        _alertSlideController.reverse().then((_) {
          setState(() {
            _borderColor = Colors.transparent;
            _alertMessage = '';
            _isAlarm = false;
          });
        });
      }
    });
  }

  void _updateScore(double delta) {
    setState(() {
      _score = (_score + delta).clamp(0.0, 100.0);
    });
  }

  void _toggleCameras() {
    setState(() {
      _cameraEnabled = !_cameraEnabled;
    });

    if (_cameraEnabled) {
      _initializeCameras();
    } else {
      if (_isMonitoring) {
        _toggleMonitoring();
      }
      // Dispose uniquement la caméra active
      _activeCamera?.dispose();
      _driverCam?.dispose();
      _roadCam?.dispose();
      _driverCam = null;
      _roadCam = null;
      _activeCamera = null;
      _isCameraInitialized = false;
      debugPrint('📷 Toutes les caméras désactivées');
    }
  }

  void _toggleMonitoring() async {
    // Changed to async
    if (!_cameraEnabled || !_isCameraInitialized || _activeCamera == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez activer les caméras d\'abord'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check server connection before starting monitoring
    if (!_isMonitoring) {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vérification de la connexion au serveur...'),
          duration: Duration(seconds: 2),
        ),
      );

      final isServerReachable = await _apiService.checkServerHealth();
      if (!isServerReachable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '❌ Serveur non accessible. Veuillez démarrer le backend.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }
    }

    setState(() => _isMonitoring = !_isMonitoring);

    if (_isMonitoring) {
      // Start a new trip
      final tripData = await _apiService.startTrip(_deviceId);
      if (tripData != null) {
        setState(() {
          _currentTripId = tripData['trip_id'];
        });
        debugPrint('✅ Trip started: $_currentTripId');
      }
      _connectWebSocket();
      if (!_isDesktopOrWeb) _startLocationTracking();
      _startMonitoring(); // Existing call
    } else {
      // End the current trip
      if (_currentTripId != null) {
        await _apiService.endTrip(_currentTripId!, finalScore: _score.toInt());
        debugPrint('✅ Trip ended: $_currentTripId');
        setState(() {
          _currentTripId = null;
        });
      }
      _channel?.sink.close();
      if (!_isDesktopOrWeb) _stopLocationTracking();
      _stopMonitoring();
    }
  }

  void _startMonitoring() {
    debugPrint('🚀 Démarrage de la surveillance...');

    _frameCount = 0;
    _lastFrameTime = DateTime.now();

    _startLocationTracking();
    _startAccidentDetection();

    if (_activeCamera?.value.isInitialized == true) {
      _activeCamera!.startImageStream((CameraImage image) {
        final now = DateTime.now();
        final timeSinceLastFrame = _lastFrameTime != null
            ? now.difference(_lastFrameTime!).inMilliseconds
            : 1000;

        if (!_isProcessingFrame && timeSinceLastFrame >= 250) {
          _isProcessingFrame = true;
          _lastFrameTime = now;
          _sendFrame(image, _isDriverCamActive ? "driver" : "road");
        }
      });
    }

    debugPrint(
        '✅ Surveillance active avec caméra ${_isDriverCamActive ? "conducteur" : "route"}');
  }

  void _stopMonitoring() {
    debugPrint('⏹️ Arrêt de la surveillance...');

    _stopLocationTracking();
    _stopAccidentDetection();

    try {
      _activeCamera?.stopImageStream();
      _isProcessingFrame = false;
    } catch (e) {
      debugPrint('❌ Erreur arrêt stream: $e');
    }

    debugPrint('✅ Surveillance arrêtée (${_frameCount} frames envoyés)');
  }

  Future<void> _sendFrame(CameraImage image, String camType) async {
    try {
      _frameCount++;

      final int width = image.width;
      final int height = image.height;

      final int targetWidth = 320;
      final int targetHeight = (height * targetWidth / width).round();

      final imgBuffer = img.Image(width: targetWidth, height: targetHeight);

      final yPlane = image.planes[0].bytes;
      final uPlane = image.planes[1].bytes;
      final vPlane = image.planes[2].bytes;

      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

      final double scaleX = width / targetWidth;
      final double scaleY = height / targetHeight;

      for (int y = 0; y < targetHeight; y++) {
        for (int x = 0; x < targetWidth; x++) {
          final int srcX = (x * scaleX).round();
          final int srcY = (y * scaleY).round();

          final int yIndex = srcY * width + srcX;
          final int uvIndex =
              (srcY ~/ 2) * uvRowStride + (srcX ~/ 2) * uvPixelStride;

          if (yIndex < yPlane.length &&
              uvIndex < uPlane.length &&
              uvIndex < vPlane.length) {
            final int yValue = yPlane[yIndex];
            final int uValue = uPlane[uvIndex];
            final int vValue = vPlane[uvIndex];

            int r = (yValue + 1.370705 * (vValue - 128)).round().clamp(0, 255);
            int g =
                (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128))
                    .round()
                    .clamp(0, 255);
            int b = (yValue + 1.732446 * (uValue - 128)).round().clamp(0, 255);

            imgBuffer.setPixelRgba(x, y, r, g, b, 255);
          }
        }
      }

      final jpeg = img.encodeJpg(imgBuffer, quality: 80);
      final base64String = base64Encode(jpeg);

      final payload = jsonEncode({
        'camera': camType,
        'frame': base64String,
        'timestamp': DateTime.now().toIso8601String(),
        'speed': _speed,
        'acceleration': _acceleration,
      });

      _channel?.sink.add(payload);

      if (_frameCount % 5 == 0) {
        final fps = _lastFrameTime != null
            ? 1000 / DateTime.now().difference(_lastFrameTime!).inMilliseconds
            : 0;
        debugPrint(
            '📤 Frame #$_frameCount envoyé ($camType): ${imgBuffer.width}x${imgBuffer.height}, '
            'taille: ${(base64String.length / 1024).toStringAsFixed(1)} KB, '
            'FPS: ${fps.toStringAsFixed(1)}, Vitesse: ${_speed.toStringAsFixed(1)} km/h');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur envoi frame: $e');
      debugPrint('Stack: $stackTrace');
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _checkPairedUser() async {
    final deviceUser = await _apiService.getDeviceUser(_deviceId);
    if (mounted && deviceUser != null && deviceUser['paired'] == true) {
      setState(() {
        _pairedUserName = deviceUser['user_name'];
        // Update main display info with paired user details
        _userName = deviceUser['user_name'] ?? 'Conducteur';
        _carModel = deviceUser['car_model'] ?? 'Véhicule';
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    if (_isDesktopOrWeb) return;
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('⚠️ Services de localisation désactivés');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ Permission de localisation refusée');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('⚠️ Permission de localisation refusée définitivement');
      return;
    }

    _startLocationTracking();
  }

  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      _updateLocation(position);
    });
  }

  void _stopLocationTracking() {
    _positionStream?.cancel();
  }

  /// Start monitoring accelerometer for accident detection
  void _startAccidentDetection() {
    if (_isDesktopOrWeb) {
      debugPrint('💻 Accident detection skipped on Desktop/Web');
      return;
    }

    debugPrint('🚨 Starting accident detection...');
    final startupTime = DateTime.now(); // Record when detection starts

    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        final now = DateTime.now();

        // Ignore readings for first 5 seconds after startup (settling period)
        if (now.difference(startupTime) < const Duration(seconds: 5)) {
          return;
        }

        // Calculate total acceleration magnitude (G-force) using CORRECT formula
        final double totalAcceleration =
            sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

        // Check if acceleration exceeds threshold
        if (totalAcceleration > ACCIDENT_THRESHOLD && !_accidentDetected) {
          // Prevent multiple detections within 30 seconds
          if (_lastAccidentCheck == null ||
              now.difference(_lastAccidentCheck!) >
                  const Duration(seconds: 30)) {
            _lastAccidentCheck = now;
            _accidentDetected = true;

            debugPrint(
                '🚨 ACCIDENT DETECTED! G-force: ${totalAcceleration.toStringAsFixed(2)} m/s²');
            _handleAccidentDetected(totalAcceleration);

            // Reset flag after 5 seconds
            Future.delayed(const Duration(seconds: 5), () {
              _accidentDetected = false;
            });
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Accelerometer error: $error');
      },
    );
  }

  /// Stop accident detection
  void _stopAccidentDetection() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    debugPrint('⏹️ Accident detection stopped');
  }

  /// Handle detected accident
  Future<void> _handleAccidentDetected(double gForce) async {
    // Trigger alarm
    _triggerAlert(isAlarm: true, message: 'ACCIDENT DÉTECTÉ!');

    // Prepare accident data
    final accidentData = {
      'type': 'ACCIDENT',
      'device_id': _deviceId,
      'timestamp': DateTime.now().toIso8601String(),
      'acceleration_g': gForce,
      'gps': {
        'lat': _currentPosition?.latitude ?? 0.0,
        'lon': _currentPosition?.longitude ?? 0.0,
      },
    };

    // Send to backend via WebSocket
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(accidentData));
      debugPrint('📤 Accident data sent via WebSocket');
    }

    // Show emergency modal
    if (mounted) {
      await EmergencyService().showAccidentModal(context, accidentData);
    }
  }

  void _updateLocation(Position position) {
    if (_lastPosition != null && _lastPositionTime != null) {
      // Use GPS-provided speed (more accurate than distance/time calculation)
      // GPS speed is in m/s, convert to km/h
      final newSpeed = position.speed * 3.6; // m/s to km/h

      final timeDiff =
          position.timestamp.difference(_lastPositionTime!).inMilliseconds /
              1000.0; // seconds

      if (timeDiff > 0) {
        final oldSpeed = _speed;

        // Calculate acceleration in m/s²
        // Convert km/h to m/s for acceleration calculation
        final speedDiffMs = (newSpeed - oldSpeed) / 3.6; // km/h to m/s
        final rawAcceleration = speedDiffMs / timeDiff; // m/s²

        setState(() {
          // Apply smoothing to reduce GPS noise (exponential moving average)
          _speed = _speed * 0.7 + newSpeed * 0.3; // 70% old, 30% new
          _acceleration = _acceleration * 0.7 + rawAcceleration * 0.3;

          // Calculate CO2 emissions (only on mobile platforms)
          if (!_isDesktopOrWeb) {
            _co2EmissionRate =
                CO2Calculator.calculateEmissionRate(_speed, _acceleration);

            // Accumulate total CO2 for the trip
            final co2PerSecond =
                CO2Calculator.calculateCO2PerSecond(_speed, _acceleration);
            _totalCO2 += co2PerSecond * timeDiff;
            _lastCO2Update = DateTime.now();

            // Trigger alert if emissions are too high
            final emissionLevel =
                CO2Calculator.getEmissionLevel(_co2EmissionRate);
            if (emissionLevel == EmissionLevel.high) {
              _triggerAlert(
                  isAlarm: false,
                  message: '🌍 Émissions CO₂ élevées! Ralentissez.');
            }
          }
        });
      }
    }

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _routePoints.add(_currentPosition!);
      _lastPosition = position;
      _lastPositionTime = position.timestamp;
    });
  }

  @override
  void dispose() {
    debugPrint('🧹 Nettoyage des ressources...');

    _borderAnimationController.dispose();
    _pulseAnimationController.dispose();
    _alertSlideController.dispose();
    _alertShakeController.dispose();
    _stopLocationTracking();

    try {
      _activeCamera?.stopImageStream();
    } catch (e) {
      debugPrint('Erreur lors de l\'arrêt du stream: $e');
    }

    // Dispose uniquement la caméra active (les autres sont déjà null)
    _activeCamera?.dispose();
    _driverCam?.dispose();
    _roadCam?.dispose();

    _channel?.sink.close();
    _audioPlayer.dispose();

    debugPrint('✅ Nettoyage terminé');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAlarm = _borderColor == const Color(0xFFFF8C42);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5E6D3), // Match background
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/haniny_green.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text(
              'Driver Safety',
              style: TextStyle(
                  color: Color(0xFF2C3E50), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          if (_pairedUserName != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.green,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _pairedUserName!,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blue,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.devices, color: Colors.blue, size: 16),
                const SizedBox(width: 6),
                Text(
                  'ID: $_deviceId',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF5E6D3),
                    const Color(0xFFE8D5BD),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  margin: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5F0),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Column(
                              children: [
                                DriverProfileWidget(
                                  userName: _userName,
                                  carModel: _carModel,
                                ),
                                const SizedBox(height: 16),
                                // Dual Camera Placeholder Layout
                                Container(
                                  height: 240,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(
                                    children: [
                                      // Driver Camera (Left)
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: _isDriverCamActive &&
                                                      _cameraEnabled
                                                  ? Colors.green
                                                  : Colors.grey
                                                      .withOpacity(0.3),
                                              width: _isDriverCamActive &&
                                                      _cameraEnabled
                                                  ? 3
                                                  : 1,
                                            ),
                                            boxShadow: [
                                              if (_isDriverCamActive &&
                                                  _cameraEnabled)
                                                BoxShadow(
                                                  color: Colors.green
                                                      .withOpacity(0.3),
                                                  blurRadius: 10,
                                                  spreadRadius: 2,
                                                ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                if (_isDriverCamActive &&
                                                    _cameraEnabled &&
                                                    _driverCam != null &&
                                                    _driverCam!
                                                        .value.isInitialized)
                                                  CameraPreview(_driverCam!)
                                                else
                                                  Container(
                                                    color:
                                                        const Color(0xFF1A1A1A),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.face,
                                                          color: Colors.white
                                                              .withOpacity(0.2),
                                                          size: 40,
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Text(
                                                          'Driver Cam',
                                                          style: TextStyle(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.4),
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                // Label
                                                Positioned(
                                                  top: 10,
                                                  left: 10,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.6),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: const Text(
                                                      'Driver',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Road Camera (Right)
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: !_isDriverCamActive &&
                                                      _cameraEnabled
                                                  ? Colors.green
                                                  : Colors.grey
                                                      .withOpacity(0.3),
                                              width: !_isDriverCamActive &&
                                                      _cameraEnabled
                                                  ? 3
                                                  : 1,
                                            ),
                                            boxShadow: [
                                              if (!_isDriverCamActive &&
                                                  _cameraEnabled)
                                                BoxShadow(
                                                  color: Colors.green
                                                      .withOpacity(0.3),
                                                  blurRadius: 10,
                                                  spreadRadius: 2,
                                                ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                if (!_isDriverCamActive &&
                                                    _cameraEnabled &&
                                                    _roadCam != null &&
                                                    _roadCam!
                                                        .value.isInitialized)
                                                  CameraPreview(_roadCam!)
                                                else
                                                  Container(
                                                    color:
                                                        const Color(0xFF1A1A1A),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.add_road,
                                                          color: Colors.white
                                                              .withOpacity(0.2),
                                                          size: 40,
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Text(
                                                          'Road Cam',
                                                          style: TextStyle(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.4),
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                // Label
                                                Positioned(
                                                  top: 10,
                                                  left: 10,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.6),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: const Text(
                                                      'Road',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        // MapCardWidget removed
                                        const SizedBox(height: 16),
                                        MetricsRowWidget(
                                          speed: _speed,
                                          acceleration: _acceleration,
                                        ),
                                        const SizedBox(height: 16),
                                        CO2MetricWidget(
                                          emissionRate: _co2EmissionRate,
                                          totalCO2: _totalCO2,
                                        ),
                                        ControlButtonsWidget(
                                          onCameraToggle: _toggleCameras,
                                          onMonitoringToggle: _toggleMonitoring,
                                          onSimulateAccident: _simulateAccident,
                                          isCameraEnabled: _cameraEnabled,
                                          isMonitoring: _isMonitoring,
                                        ),
                                        const SizedBox(
                                            height: 80), // Space for bottom nav
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Border alert animation
          if (_borderColor != Colors.transparent)
            AnimatedBuilder(
              animation: _borderAnimationController,
              builder: (context, child) {
                return IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _borderColor
                            .withOpacity(_borderAnimationController.value),
                        width: 8,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.all(4),
                  ),
                );
              },
            ),
          // Alert overlay
          if (_alertMessage.isNotEmpty)
            AlertOverlayWidget(
              alertMessage: _alertMessage,
              isAlarm: _isAlarm,
              alertSlideController: _alertSlideController,
              alertShakeController: _alertShakeController,
              alertSlideAnimation: _alertSlideAnimation,
              alertShakeAnimation: _alertShakeAnimation,
              alertScaleAnimation: _alertScaleAnimation,
              pulseAnimation: _pulseAnimation,
              pulseAnimationController: _pulseAnimationController,
              borderColor: _borderColor,
            ),
        ],
      ),
    );
  }
}
