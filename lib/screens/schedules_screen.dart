import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../data/models/schedule_model.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _dayScrollController = ScrollController();
  final List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  int _selectedDayIndex = 0;

  int get _todayWeekdayIndex {
    final weekday = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
    return (weekday - 1).clamp(0, 6);
  }

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = _todayWeekdayIndex;

    _tabController = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: _selectedDayIndex,
    );

    _tabController.addListener(() {
      if (_tabController.index != _selectedDayIndex) {
        setState(() {
          _selectedDayIndex = _tabController.index;
        });
        _scrollToSelectedDay(_tabController.index);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScheduleProvider>(context, listen: false).fetchSchedules();
      _scrollToSelectedDay(_selectedDayIndex);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dayScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDay([int? targetIndex]) {
    final idx = targetIndex ?? _selectedDayIndex;
    if (!_dayScrollController.hasClients) return;
    // Each day capsule is approx 92px wide with margins
    final targetOffset = (idx * 94.0 - 30.0).clamp(0.0, _dayScrollController.position.maxScrollExtent);
    _dayScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onDaySelected(int index) {
    if (index == _selectedDayIndex) return;
    setState(() {
      _selectedDayIndex = index;
    });
    _tabController.animateTo(index);
    _scrollToSelectedDay(index);
  }

  String _formatTodayDateIndonesian() {
    final now = DateTime.now();
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${_days[_todayWeekdayIndex]}, ${now.day} ${months[now.month]} ${now.year}';
  }

  int _calculateDurationMinutes(String start, String end) {
    try {
      final sParts = start.split(':').map((e) => int.tryParse(e) ?? 0).toList();
      final eParts = end.split(':').map((e) => int.tryParse(e) ?? 0).toList();
      if (sParts.length >= 2 && eParts.length >= 2) {
        final startMin = sParts[0] * 60 + sParts[1];
        final endMin = eParts[0] * 60 + eParts[1];
        final diff = endMin - startMin;
        return diff > 0 ? diff : 90;
      }
    } catch (_) {}
    return 90;
  }

  String _getScheduleStatus(ScheduleItem item, String day) {
    if (day != _days[_todayWeekdayIndex]) {
      return 'Tatap Muka';
    }
    try {
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;
      final sParts = item.startTime.split(':').map((e) => int.tryParse(e) ?? 0).toList();
      final eParts = item.endTime.split(':').map((e) => int.tryParse(e) ?? 0).toList();

      if (sParts.length >= 2 && eParts.length >= 2) {
        final startMin = sParts[0] * 60 + sParts[1];
        final endMin = eParts[0] * 60 + eParts[1];

        if (currentMinutes >= startMin && currentMinutes <= endMin) {
          return 'Sedang Berlangsung';
        } else if (currentMinutes > endMin) {
          return 'Selesai';
        } else {
          return 'Akan Datang';
        }
      }
    } catch (_) {}
    return 'Tatap Muka';
  }

  void _showScheduleDetails(BuildContext context, ScheduleItem item, String day) {
    final duration = _calculateDurationMinutes(item.startTime, item.endTime);
    final status = _getScheduleStatus(item, day);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Top Badge & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Text(
                        'Hari $day',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'Sedang Berlangsung'
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: status == 'Sedang Berlangsung'
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: status == 'Sedang Berlangsung'
                              ? const Color(0xFF15803D)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  item.courseName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Detail Items Grid
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        Icons.access_time_rounded,
                        'Waktu Perkuliahan',
                        '${item.startTime} - ${item.endTime} WIB ($duration Menit)',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                      ),
                      _buildDetailRow(
                        Icons.meeting_room_rounded,
                        'Ruangan Kelas',
                        item.roomName,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                      ),
                      _buildDetailRow(
                        Icons.school_rounded,
                        'Program Studi & Jenjang',
                        'S1 Reguler • Semester Ganjil',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(
                              text: '${item.courseName} | ${item.dayOfWeek}, ${item.startTime}-${item.endTime} | ${item.roomName}',
                            ),
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Info jadwal berhasil disalin ke clipboard!'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Salin Info'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF047857),
                          side: const BorderSide(color: Color(0xFFA7F3D0)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF047857),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF047857)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedProvider = Provider.of<ScheduleProvider>(context);

    // Calculate total schedules across week
    int totalWeekly = 0;
    for (final d in _days) {
      totalWeekly += schedProvider.getSchedulesForDay(d).length;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ─── UNIFIED EMERALD HERO HEADER ───
          Container(
            width: double.infinity,
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
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jadwal Mengajar',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFFA7F3D0)),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      _formatTodayDateIndonesian(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFD1FAE5),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Action: Sinkron Button
                        InkWell(
                          onTap: () => schedProvider.fetchSchedules(),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                schedProvider.isLoading
                                    ? const SizedBox(
                                        width: 13,
                                        height: 13,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.sync_rounded, size: 14, color: Colors.white),
                                const SizedBox(width: 5),
                                const Text(
                                  'Sinkron',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick Weekly Overview Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.school_rounded, size: 15, color: Color(0xFFA7F3D0)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              totalWeekly > 0
                                  ? '$totalWeekly Sesi Kuliah Terjadwal Pekan Ini'
                                  : 'Agenda Perkuliahan Semester Ini',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _days[_selectedDayIndex],
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Modern Horizontal Scrollable Day Capsule Bar
                    SingleChildScrollView(
                      controller: _dayScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: List.generate(_days.length, (index) {
                          final day = _days[index];
                          final isSelected = _selectedDayIndex == index;
                          final isToday = _todayWeekdayIndex == index;
                          final count = schedProvider.getSchedulesForDay(day).length;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => _onDaySelected(index),
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.2),
                                    width: 1.2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.12),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isToday) ...[
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF047857) : const Color(0xFFA7F3D0),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                    Text(
                                      day,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF047857)
                                            : Colors.white,
                                      ),
                                    ),
                                    if (count > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF047857)
                                              : Colors.white.withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          count.toString(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── TAB BAR VIEW FOR SCHEDULES ───
          Expanded(
            child: schedProvider.isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF047857)))
                : TabBarView(
                    controller: _tabController,
                    children: _days.map((day) {
                      final schedules = schedProvider.getSchedulesForDay(day);

                      if (schedules.isEmpty) {
                        return _buildEmptyState(day, schedProvider);
                      }

                      return RefreshIndicator(
                        onRefresh: () => schedProvider.fetchSchedules(),
                        color: const Color(0xFF16A34A),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                          itemCount: schedules.length,
                          itemBuilder: (context, index) {
                            final item = schedules[index];
                            return _buildScheduleCard(item, index, day);
                          },
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String day, ScheduleProvider schedProvider) {
    final isWeekend = day == 'Sabtu' || day == 'Minggu';

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decorative Dual-Ring Circular Icon Container
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isWeekend
                      ? [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)]
                      : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isWeekend ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isWeekend
                        ? const Color(0xFF047857).withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(
                  isWeekend ? Icons.weekend_rounded : Icons.event_available_rounded,
                  size: 38,
                  color: isWeekend ? const Color(0xFF047857) : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              isWeekend ? 'Hari Bebas Kuliah ($day)' : 'Tidak Ada Jadwal Mengajar',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              isWeekend
                  ? 'Tidak ada kegiatan perkuliahan pada hari $day.\nGunakan hari ini untuk rehat bersama keluarga atau persiapan materi akademik.'
                  : 'Belum ada agenda mengajar yang dijadwalkan pada hari $day.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),

            // Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isWeekend ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isWeekend ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 3.5,
                    backgroundColor: isWeekend ? const Color(0xFF047857) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    isWeekend ? 'Status: Libur Perkuliahan' : 'Status: Tidak Ada Jadwal',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isWeekend ? const Color(0xFF047857) : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Convenient Action: Switch to Monday if on Weekend, or Sync if Weekday
            if (isWeekend) ...[
              ElevatedButton.icon(
                onPressed: () => _onDaySelected(0), // Switch to Senin
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text(
                  'Lihat Jadwal Hari Senin',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () => schedProvider.fetchSchedules(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'Sinkronkan Jadwal',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF047857),
                  side: const BorderSide(color: Color(0xFFA7F3D0)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(ScheduleItem item, int index, String day) {
    final status = _getScheduleStatus(item, day);
    final isLive = status == 'Sedang Berlangsung';
    final isDone = status == 'Selesai';
    final duration = _calculateDurationMinutes(item.startTime, item.endTime);

    return InkWell(
      onTap: () => _showScheduleDetails(context, item, day),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLive ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
            width: isLive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isLive
                  ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                  : const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: isLive ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Pod Column
              Container(
                width: 78,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLive
                        ? [const Color(0xFFDCFCE7), const Color(0xFFBBF7D0)]
                        : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isLive ? const Color(0xFF4ADE80) : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isLive ? Icons.play_circle_filled_rounded : Icons.access_time_rounded,
                      size: 15,
                      color: const Color(0xFF047857),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.startTime,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF047857),
                      ),
                    ),
                    const Text(
                      's/d',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item.endTime,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$duration mnt',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Subject & Room Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Class Tag
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isLive
                                ? const Color(0xFFDCFCE7)
                                : isDone
                                    ? const Color(0xFFF1F5F9)
                                    : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isLive
                                  ? const Color(0xFF86EFAC)
                                  : isDone
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFFC7D2FE),
                            ),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isLive
                                  ? const Color(0xFF15803D)
                                  : isDone
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            'Kelas ${index + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Course Name
                    Text(
                      item.courseName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Room Indicator Pod
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.meeting_room_rounded, size: 14, color: Color(0xFF047857)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.roomName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
