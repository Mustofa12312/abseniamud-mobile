import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class RadarPulseWidget extends StatefulWidget {
  final bool isScanning;
  final bool isMockDetected;
  final bool isWithinGeofence;
  final VoidCallback onTap;

  const RadarPulseWidget({
    super.key,
    required this.isScanning,
    required this.isMockDetected,
    required this.isWithinGeofence,
    required this.onTap,
  });

  @override
  State<RadarPulseWidget> createState() => _RadarPulseWidgetState();
}

class _RadarPulseWidgetState extends State<RadarPulseWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color activeColor;
    if (widget.isMockDetected) {
      activeColor = AppColors.statusAlpha;
    } else if (widget.isWithinGeofence) {
      activeColor = AppColors.brand500;
    } else {
      activeColor = AppColors.accent500;
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 180,
        height: 180,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer Pulse Ring 2
                if (widget.isScanning)
                  Container(
                    width: 140 + (_controller.value * 35),
                    height: 140 + (_controller.value * 35),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: activeColor.withOpacity((1 - _controller.value) * 0.4),
                        width: 2,
                      ),
                    ),
                  ),

                // Outer Pulse Ring 1
                if (widget.isScanning)
                  Container(
                    width: 110 + (_controller.value * 25),
                    height: 110 + (_controller.value * 25),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeColor.withOpacity((1 - _controller.value) * 0.15),
                    ),
                  ),

                // Inner Main Circle
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: widget.isMockDetected
                          ? [const Color(0xFFDC2626), const Color(0xFF991B1B)]
                          : widget.isWithinGeofence
                              ? [const Color(0xFF22C55E), const Color(0xFF15803D)]
                              : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      widget.isMockDetected
                          ? Icons.gpp_bad_rounded
                          : widget.isWithinGeofence
                              ? Icons.location_on_rounded
                              : Icons.near_me_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
