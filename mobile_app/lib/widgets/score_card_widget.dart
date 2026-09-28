import 'package:flutter/material.dart';

class ScoreCardWidget extends StatelessWidget {
  final double score;

  const ScoreCardWidget({
    Key? key,
    required this.score,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF7FC8A9).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7FC8A9).withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 14,
                    color: const Color(0xFF7FC8A9),
                    backgroundColor: const Color(0xFFE8F5F0),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF7FC8A9),
                          Color(0xFF5FA88A),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        '${score.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                          shadows: [
                            Shadow(
                              color: Color(0xFF7FC8A9),
                              blurRadius: 2,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Score de\nConduite',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF5F7A6A).withOpacity(0.8),
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
