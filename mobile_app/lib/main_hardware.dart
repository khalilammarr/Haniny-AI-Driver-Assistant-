import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/driver_safety_screen.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Error initializing cameras: $e');
  }

  runApp(const HardwareApp());
}

class HardwareApp extends StatelessWidget {
  const HardwareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haniny Hardware',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: DriverSafetyScreen(cameras: cameras),
    );
  }
}
