import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/device_security_provider.dart';
import 'dashboard_screen.dart';
import 'attendance_action_screen.dart';
import 'history_screen.dart';
import 'schedules_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();

  static MainNavigationScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainNavigationScreenState>();
  }
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AttendanceActionScreen(),
    HistoryScreen(),
    SchedulesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final attProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final devProvider = Provider.of<DeviceSecurityProvider>(context, listen: false);

      attProvider.refreshDashboard().then((_) {
        devProvider.setCampusLocations(attProvider.campusLocations);
        devProvider.refreshLocation();
      });
    });
  }

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 1) {
      // Trigger live GPS scanning when tapping Presensi
      Provider.of<DeviceSecurityProvider>(context, listen: false).refreshLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
          border: const Border(
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Beranda',
                ),
                _buildPresensiHeroItem(),
                _buildNavItem(
                  index: 2,
                  icon: Icons.history_rounded,
                  activeIcon: Icons.history_toggle_off_rounded,
                  label: 'Riwayat',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_month_rounded,
                  label: 'Jadwal',
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECFDF5) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? const Color(0xFF047857) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? const Color(0xFF047857) : const Color(0xFF64748B),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresensiHeroItem() {
    final isSelected = _currentIndex == 1;

    return InkWell(
      onTap: () => _onTabSelected(1),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF047857), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFA7F3D0),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fingerprint_rounded,
              size: 24,
              color: isSelected ? Colors.white : const Color(0xFF047857),
            ),
            const SizedBox(height: 2),
            Text(
              'Presensi',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF047857),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
