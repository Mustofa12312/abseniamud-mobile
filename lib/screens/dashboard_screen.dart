import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/device_security_provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/status_badge.dart';
import '../widgets/mock_location_warning.dart';
import '../data/models/announcement_model.dart';
import '../providers/notification_provider.dart';
import '../providers/leave_provider.dart';
import '../providers/correction_provider.dart';
import 'main_navigation_screen.dart';
import 'leaves_screen.dart';
import 'corrections_screen.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final schedProv = Provider.of<ScheduleProvider>(context, listen: false);
      final attProv = Provider.of<AttendanceProvider>(context, listen: false);
      final devProv = Provider.of<DeviceSecurityProvider>(context, listen: false);
      final notifProv = Provider.of<SmartNotificationProvider>(context, listen: false);
      final leaveProv = Provider.of<LeaveProvider>(context, listen: false);
      final corrProv = Provider.of<CorrectionProvider>(context, listen: false);

      await notifProv.requestPermissions();
      await schedProv.fetchSchedules();
      await leaveProv.fetchLeaves();
      await corrProv.fetchCorrections();

      if (!mounted) return;
      final todayName = _getDayName(_currentTime);
      final todaySchedules = schedProv.getSchedulesForDay(todayName);
      await notifProv.checkScheduleReminders(todaySchedules);
      await notifProv.checkCheckOutReminder(attProv.todayStatus);
      await notifProv.checkApprovalUpdates(leaveProv.leaves, corrProv.corrections);
      await notifProv.checkAnnouncementAlerts(attProv.announcements);
      if (devProv.isWithinGeofence && devProv.selectedCampus != null) {
        await notifProv.checkGeofenceArrival(
          true,
          devProv.selectedCampus!.name,
          attProv.todayStatus,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatIndonesianDate(DateTime date) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final dayName = days[date.weekday % 7];
    final monthName = months[date.month];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  String _getDayName(DateTime date) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    return days[date.weekday % 7];
  }

  String _localizePeriod(String period) {
    if (period.isEmpty) return 'Bulan Ini';
    const enMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const idMonths = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    String result = period;
    for (int i = 0; i < enMonths.length; i++) {
      result = result.replaceAll(enMonths[i], idMonths[i]);
    }
    return result;
  }

  void _showAnnouncementModal(AnnouncementModel ann) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(ann.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ann.isImportant) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PENGUMUMAN PENTING',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  ann.content,
                  style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.textPrimaryLight),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final attProvider = Provider.of<AttendanceProvider>(context);
    final devProvider = Provider.of<DeviceSecurityProvider>(context);
    final schedProvider = Provider.of<ScheduleProvider>(context);

    final user = authProvider.currentUser;
    final today = attProvider.todayStatus;
    final summary = attProvider.summary;
    final todaySchedules = schedProvider.getSchedulesForDay(_getDayName(_currentTime));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: () async {
          final notifProv = Provider.of<SmartNotificationProvider>(context, listen: false);
          final leaveProv = Provider.of<LeaveProvider>(context, listen: false);
          final corrProv = Provider.of<CorrectionProvider>(context, listen: false);

          await attProvider.refreshDashboard();
          await schedProvider.fetchSchedules();
          await devProvider.refreshLocation();
          await leaveProv.fetchLeaves();
          await corrProv.fetchCorrections();

          if (!mounted) return;
          final todayName = _getDayName(_currentTime);
          final todaySchedules = schedProvider.getSchedulesForDay(todayName);
          await notifProv.checkScheduleReminders(todaySchedules);
          await notifProv.checkCheckOutReminder(attProvider.todayStatus);
          await notifProv.checkApprovalUpdates(leaveProv.leaves, corrProv.corrections);
          await notifProv.checkAnnouncementAlerts(attProvider.announcements);
        },
        color: AppColors.brand600,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER (Deep Emerald Green Gradient + Clock)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 50, bottom: 24, left: 20, right: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF042412),
                      Color(0xFF064E26),
                      Color(0xFF14532D),
                      Color(0xFF15803D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar with Logo & User Greeting
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.school_rounded,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Civitas IAIMU',
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      (user?.roleName ?? 'Dosen').toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFD1FAE5),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  if (user?.lecturer?.nidn != null) ...[
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'NIDN: ${user!.lecturer!.nidn}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFD1FAE5),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ] else if (user?.staffProfile?['nip'] != null) ...[
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'NIP: ${user!.staffProfile!['nip']}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFD1FAE5),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                        Consumer<SmartNotificationProvider>(
                          builder: (context, notifProv, _) {
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.notifications_outlined, size: 18, color: Colors.white),
                                    if (notifProv.unreadCount > 0)
                                      Positioned(
                                        top: -4,
                                        right: -4,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFDC2626),
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                          child: Center(
                                            child: Text(
                                              notifProv.unreadCount > 9 ? '9+' : notifProv.unreadCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            attProvider.refreshDashboard();
                            devProvider.refreshLocation();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: const Icon(Icons.sync_rounded, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Digital Clock & Date Container
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatIndonesianDate(_currentTime),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFD1FAE5),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${DateFormat('HH:mm:ss').format(_currentTime)} WIB',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4ADE80),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'GPS Online',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. MAIN BODY CONTENT
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mock Location or Location Error Alert
                    if (devProvider.isMockDetected || (devProvider.lastLocationResult != null && !devProvider.lastLocationResult!.isSuccess)) ...[
                      MockLocationWarning(
                        isMockDetected: devProvider.isMockDetected,
                        reason: devProvider.mockReason,
                        errorMessage: !devProvider.isMockDetected ? devProvider.lastLocationResult?.errorMessage : null,
                        onRefresh: () => devProvider.refreshLocation(),
                        onOpenSettings: () async {
                          final isPerm = (devProvider.lastLocationResult?.errorMessage ?? '').toLowerCase().contains('izin');
                          if (isPerm) {
                            await devProvider.openAppSettings();
                          } else {
                            await devProvider.openLocationSettings();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 3. TODAY'S ATTENDANCE HERO CARD
                    _buildTodayAttendanceCard(context, today, attProvider.isLoadingToday),
                    const SizedBox(height: 20),

                    // 4. DEVICE & SECURITY STATUS BANNER
                    _buildSecurityPill(devProvider),
                    const SizedBox(height: 24),

                    // 5. MONTHLY RECAP CARDS (4 GRID)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rekap Presensi (${_localizePeriod(summary.period)})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Total: ${summary.total}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            label: 'Hadir',
                            value: summary.hadir.toString(),
                            icon: Icons.check_circle_rounded,
                            color: const Color(0xFF047857),
                            bgColor: const Color(0xFFF0FDF4),
                            borderColor: const Color(0xFFA7F3D0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            label: 'Terlambat',
                            value: summary.terlambat.toString(),
                            icon: Icons.access_time_filled_rounded,
                            color: const Color(0xFFD97706),
                            bgColor: const Color(0xFFFFFBEB),
                            borderColor: const Color(0xFFFDE68A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            label: 'Izin / Sakit',
                            value: summary.izinSakit.toString(),
                            icon: Icons.info_rounded,
                            color: const Color(0xFF0284C7),
                            bgColor: const Color(0xFFF0F9FF),
                            borderColor: const Color(0xFFBAE6FD),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            label: 'Tanpa Keterangan',
                            value: summary.tidakHadir.toString(),
                            icon: Icons.cancel_rounded,
                            color: const Color(0xFFE11D48),
                            bgColor: const Color(0xFFFFF1F2),
                            borderColor: const Color(0xFFFECDD3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quick Action Row (Izin & Koreksi)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const LeavesScreen()));
                            },
                            icon: const Icon(Icons.assignment_turned_in_rounded, size: 16, color: Color(0xFF047857)),
                            label: const Text(
                              'Ajukan Izin / Cuti',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF064E26)),
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFA7F3D0)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const CorrectionsScreen()));
                            },
                            icon: const Icon(Icons.edit_calendar_rounded, size: 16, color: Color(0xFFB45309)),
                            label: const Text(
                              'Koreksi Presensi',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9A3412)),
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFFED7AA)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 6. TODAY'S CLASS SCHEDULE (Jadwal Hari Ini)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jadwal Kuliah Hari Ini (${_getDayName(_currentTime)})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            final nav = MainNavigationScreen.of(context);
                            nav?.switchTab(3); // Switch to Jadwal tab
                          },
                          child: const Text(
                            'Lihat Semua',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brand600,
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (todaySchedules.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.event_available_rounded, size: 36, color: AppColors.brand500),
                            SizedBox(height: 8),
                            Text(
                              'Tidak ada jadwal kuliah hari ini.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Selamat beristirahat atau menjalankan tugas akademik lainnya.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ...todaySchedules.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.brand50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.brand200),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      item.startTime,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.brand800,
                                      ),
                                    ),
                                    const Text(
                                      's/d',
                                      style: TextStyle(fontSize: 10, color: AppColors.textMutedLight),
                                    ),
                                    Text(
                                      item.endTime,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.brand800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.courseName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.meeting_room_outlined, size: 14, color: AppColors.textSecondaryLight),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.roomName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondaryLight,
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
                      }),
                    ],

                    const SizedBox(height: 24),

                    // 7. ANNOUNCEMENTS SECTION
                    if (attProvider.announcements.isNotEmpty) ...[
                      const Text(
                        'Pengumuman Kampus',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...attProvider.announcements.map((ann) {
                        return InkWell(
                          onTap: () => _showAnnouncementModal(ann),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: ann.isImportant ? AppColors.accent400 : AppColors.borderLight,
                                width: ann.isImportant ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (ann.isImportant) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'PENTING',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(
                                        ann.title,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimaryLight,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.textMutedLight),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  ann.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondaryLight,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TODAY'S ATTENDANCE CARD WIDGET
  Widget _buildTodayAttendanceCard(BuildContext context, dynamic today, bool isLoading) {
    if (isLoading) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    final isNotCheckedIn = today == null || today.isNotCheckedIn;
    final isCheckedIn = today != null && today.isCheckedIn;
    final isCheckedOut = today != null && today.isCheckedOut;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Header status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.brand50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.event_note_rounded, size: 18, color: AppColors.brand700),
                    SizedBox(width: 8),
                    Text(
                      'Status Kehadiran Hari Ini',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand900,
                      ),
                    ),
                  ],
                ),
                StatusBadge(status: today?.status ?? 'NOT_CHECKED_IN'),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                if (isNotCheckedIn) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.login_rounded, size: 28, color: AppColors.brand600),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Anda Belum Melakukan Check-in',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Buka tab Presensi untuk memvalidasi lokasi GPS kampus',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final nav = MainNavigationScreen.of(context);
                        nav?.switchTab(1); // Switch to Presensi
                      },
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Buka Presensi Sekarang'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand600,
                      ),
                    ),
                  ),
                ] else if (isCheckedIn) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('JAM MASUK', style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                          const SizedBox(height: 4),
                          Text(
                            today?.checkInAt ?? '-',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.brand800),
                          ),
                          const SizedBox(height: 2),
                          StatusBadge(status: today?.attendanceStatus ?? 'HADIR', fontSize: 10),
                        ],
                      ),
                      Container(width: 1, height: 44, color: AppColors.borderLight),
                      Column(
                        children: [
                          const Text('LOKASI', style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                          const SizedBox(height: 4),
                          Text(
                            today?.location ?? 'Gedung Kampus',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Jarak: ${today?.distance ?? 0}m',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final nav = MainNavigationScreen.of(context);
                        nav?.switchTab(1); // Switch to Presensi
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text(
                        'Presensi Pulang (Check-Out)',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ] else if (isCheckedOut) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('JAM MASUK', style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                          const SizedBox(height: 4),
                          Text(
                            today?.checkInAt ?? '-',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.brand800),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 40, color: AppColors.borderLight),
                      Column(
                        children: [
                          const Text('JAM PULANG', style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                          const SizedBox(height: 4),
                          Text(
                            today?.checkOutAt ?? '-',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF3730A3)),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 40, color: AppColors.borderLight),
                      Column(
                        children: [
                          const Text('STATUS', style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                          const SizedBox(height: 4),
                          StatusBadge(status: today?.attendanceStatus ?? 'HADIR', fontSize: 10),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.brand50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        '✓ Presensi hari ini telah lengkap. Terima kasih atas dedikasi Anda.',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.brand900),
                      ),
                    ),
                  ),
                ] else if (today != null && today.isHoliday) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.weekend_rounded, size: 28, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Hari Libur / Bukan Hari Kerja',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Hari ini di luar jadwal kerja wajib Anda. Tidak perlu melakukan presensi.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SECURITY STATUS PILL
  // SECURITY STATUS PILL
  Widget _buildSecurityPill(DeviceSecurityProvider devProvider) {
    final meta = devProvider.deviceMetadata;
    final isMock = devProvider.isMockDetected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMock ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isMock ? const Color(0xFFFEE2E2) : const Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMock ? Icons.gpp_bad_rounded : Icons.verified_user_rounded,
              size: 18,
              color: isMock ? Colors.red.shade700 : const Color(0xFF047857),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta != null ? 'Perangkat: ${meta.displayName}' : 'Perangkat Terverifikasi',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  isMock
                      ? '⚠️ Peringatan: Mock Location / Fake GPS Aktif'
                      : '✓ Anti-Fake GPS Aktif • Device Valid',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isMock ? Colors.red.shade700 : const Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: isMock ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isMock ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
              ),
            ),
            child: Text(
              isMock ? 'ALERT' : 'AMAN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isMock ? Colors.red.shade800 : const Color(0xFF15803D),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // RECAP STAT CARD
  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
