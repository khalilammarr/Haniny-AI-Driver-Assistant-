import 'package:flutter/material.dart';

class DriverProfileWidget extends StatelessWidget {
  final String userName;
  final String carModel;

  const DriverProfileWidget({
    Key? key,
    this.userName = 'Conducteur',
    this.carModel = 'Véhicule',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFD5EDE5).withOpacity(0.6),
            const Color(0xFFB5DDD3).withOpacity(0.3),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7FC8A9).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFB5DDD3),
                  const Color(0xFF7FC8A9),
                ],
              ),
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7FC8A9).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D4739),
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  carModel,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5F7A6A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${userName.hashCode.toString().substring(0, 6).toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF7FC8A9),
                        Color(0xFF6BB395),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7FC8A9).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Prudent',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
