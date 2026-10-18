import 'package:flutter/material.dart';

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
      duration: const Duration(milliseconds: 2200),
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
    List<Color> gradientColors;

    if (widget.isMockDetected) {
      activeColor = const Color(0xFFDC2626);
      gradientColors = [const Color(0xFFEF4444), const Color(0xFFB91C1C)];
    } else if (widget.isWithinGeofence) {
      activeColor = const Color(0xFF059669);
      gradientColors = [const Color(0xFF10B981), const Color(0xFF047857)];
    } else {
      activeColor = const Color(0xFFD97706);
      gradientColors = [const Color(0xFFF59E0B), const Color(0xFFB45309)];
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ambient Idle Concentric Ring 2
                    Container(
                      width: 168,
                      height: 168,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: activeColor.withValues(alpha: 0.12),
                          width: 1.2,
                        ),
                      ),
                    ),

                    // Ambient Idle Concentric Ring 1
                    Container(
                      width: 136,
                      height: 136,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeColor.withValues(alpha: 0.05),
                        border: Border.all(
                          color: activeColor.withValues(alpha: 0.2),
                          width: 1.2,
                        ),
                      ),
                    ),

                    // Outer Animated Scanning Ripple 2
                    if (widget.isScanning)
                      Container(
                        width: 120 + (_controller.value * 55),
                        height: 120 + (_controller.value * 55),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: activeColor.withValues(alpha: (1 - _controller.value) * 0.45),
                            width: 2,
                          ),
                        ),
                      ),

                    // Outer Animated Scanning Ripple 1
                    if (widget.isScanning)
                      Container(
                        width: 104 + (_controller.value * 35),
                        height: 104 + (_controller.value * 35),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: activeColor.withValues(alpha: (1 - _controller.value) * 0.2),
                        ),
                      ),

                    // Inner Main Action Pod
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2.5,
                        ),
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
          const SizedBox(height: 4),
          Text(
            widget.isScanning ? 'Memindai Koordinat GPS...' : 'Ketuk radar untuk pindai ulang lokasi',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.isScanning ? activeColor : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
