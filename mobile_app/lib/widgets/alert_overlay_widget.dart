import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AlertOverlayWidget extends StatelessWidget {
  final String alertMessage;
  final bool isAlarm;
  final AnimationController alertSlideController;
  final AnimationController alertShakeController;
  final Animation<Offset> alertSlideAnimation;
  final Animation<double> alertShakeAnimation;
  final Animation<double> alertScaleAnimation;
  final Animation<double> pulseAnimation;
  final AnimationController pulseAnimationController;
  final Color borderColor;

  const AlertOverlayWidget({
    Key? key,
    required this.alertMessage,
    required this.isAlarm,
    required this.alertSlideController,
    required this.alertShakeController,
    required this.alertSlideAnimation,
    required this.alertShakeAnimation,
    required this.alertScaleAnimation,
    required this.pulseAnimation,
    required this.pulseAnimationController,
    required this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation:
            Listenable.merge([alertSlideController, alertShakeController]),
        builder: (context, child) {
          return Stack(
            children: [
              AnimatedOpacity(
                opacity: alertSlideController.value * 0.5,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: 8.0,
                      sigmaY: 8.0,
                    ),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ),
              Center(
                child: SlideTransition(
                  position: alertSlideAnimation,
                  child: Transform.translate(
                    offset: Offset(isAlarm ? alertShakeAnimation.value : 0, 0),
                    child: ScaleTransition(
                      scale: alertScaleAnimation,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        constraints: const BoxConstraints(maxWidth: 340),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isAlarm
                                ? [
                                    const Color(0xFFFF6B35),
                                    const Color(0xFFFF8C42),
                                  ]
                                : [
                                    const Color(0xFFFFA726),
                                    const Color(0xFFF2C078),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: borderColor.withOpacity(0.8),
                              blurRadius: 40,
                              spreadRadius: 8,
                              offset: const Offset(0, 15),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: pulseAnimationController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: pulseAnimation.value,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.6),
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isAlarm
                                          ? Icons.warning_rounded
                                          : Icons.info_rounded,
                                      color: Colors.white,
                                      size: 44,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.4),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            Text(
                              isAlarm ? 'ALERTE CRITIQUE' : 'AVERTISSEMENT',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.white.withOpacity(0.95),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              alertMessage,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.4,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (index) {
                                return AnimatedBuilder(
                                  animation: pulseAnimationController,
                                  builder: (context, child) {
                                    final delay = index * 0.3;
                                    final animValue =
                                        (pulseAnimation.value - 0.95 + delay) %
                                            0.1;
                                    return Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withOpacity(0.5 + animValue * 5),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white
                                                .withOpacity(animValue * 5),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
