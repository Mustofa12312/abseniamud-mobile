import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../data/models/attendance_history_model.dart';
import '../providers/attendance_provider.dart';
import '../widgets/status_badge.dart';
import 'corrections_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late int _selectedMonth;
  late int _selectedYear;

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  List<int> get _years {
    final currentYear = DateTime.now().year;
    final yearSet = <int>{currentYear - 2, currentYear - 1, currentYear, currentYear + 1, _selectedYear};
    final list = yearSet.toList()..sort();
    return list;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  void _loadHistory() {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    provider.fetchHistory(month: _selectedMonth, year: _selectedYear);
    provider.fetchSummary(month: _selectedMonth, year: _selectedYear);
  }

  void _showDetailBottomSheet(AttendanceHistoryItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detail Presensi Harian',
                        style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.date,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  StatusBadge(status: item.status),
                ],
              ),
              const Divider(height: 28, color: Color(0xFFF1F5F9)),
              _buildDetailItem(Icons.login_rounded, 'Jam Masuk (Check-in)', item.checkIn, const Color(0xFF047857), const Color(0xFFECFDF5)),
              _buildDetailItem(Icons.logout_rounded, 'Jam Pulang (Check-out)', item.checkOut, const Color(0xFF4F46E5), const Color(0xFFEEF2FF)),
              _buildDetailItem(Icons.location_on_rounded, 'Titik Kampus', item.location, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
              _buildDetailItem(
                Icons.radar_rounded,
                'Jarak ke Geofence',
                item.distance != null ? '${item.distance} meter' : '-',
                const Color(0xFF0284C7),
                const Color(0xFFF0F9FF),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, Color iconColor, Color iconBg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attProvider = Provider.of<AttendanceProvider>(context);
    final history = attProvider.historyList;
    final summary = attProvider.summary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ─── UNIFIED EMERALD HEADER WITH FILTER PILL ───
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
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    // Top Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Riwayat Presensi',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Rekap Kehadiran & Log Harian',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFFD1FAE5)),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CorrectionsScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.edit_calendar_rounded, size: 14, color: Colors.white),
                                SizedBox(width: 5),
                                Text(
                                  'Koreksi',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Modern Month & Year Filter Capsule
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF047857)),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: _selectedMonth,
                            underline: const SizedBox.shrink(),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF047857)),
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            items: List.generate(12, (index) {
                              return DropdownMenuItem<int>(
                                value: index + 1,
                                child: Text(_months[index]),
                              );
                            }),
                            onChanged: (newMonth) {
                              if (newMonth != null) {
                                setState(() => _selectedMonth = newMonth);
                                _loadHistory();
                              }
                            },
                          ),
                          const SizedBox(width: 10),
                          Container(width: 1, height: 16, color: const Color(0xFFE2E8F0)),
                          const SizedBox(width: 10),
                          DropdownButton<int>(
                            value: _selectedYear,
                            underline: const SizedBox.shrink(),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF047857)),
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            items: _years.map((yr) {
                              return DropdownMenuItem<int>(
                                value: yr,
                                child: Text(yr.toString()),
                              );
                            }).toList(),
                            onChanged: (newYear) {
                              if (newYear != null) {
                                setState(() => _selectedYear = newYear);
                                _loadHistory();
                              }
                            },
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: _loadHistory,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── 4 MODERN MONTHLY STATS KPI TILES ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    label: 'Hadir',
                    count: summary.hadir,
                    bg: const Color(0xFFECFDF5),
                    border: const Color(0xFFA7F3D0),
                    textColor: const Color(0xFF047857),
                    icon: Icons.check_circle_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    label: 'Terlambat',
                    count: summary.terlambat,
                    bg: const Color(0xFFFFFBEB),
                    border: const Color(0xFFFDE68A),
                    textColor: const Color(0xFFD97706),
                    icon: Icons.access_time_filled_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    label: 'Izin',
                    count: summary.izinSakit,
                    bg: const Color(0xFFEFF6FF),
                    border: const Color(0xFFBFDBFE),
                    textColor: const Color(0xFF2563EB),
                    icon: Icons.info_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    label: 'Alpha',
                    count: summary.tidakHadir,
                    bg: const Color(0xFFFEF2F2),
                    border: const Color(0xFFFECACA),
                    textColor: const Color(0xFFDC2626),
                    icon: Icons.cancel_rounded,
                  ),
                ),
              ],
            ),
          ),

          // ─── PRESENCE HISTORY LIST ───
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadHistory(),
              color: AppColors.brand600,
              child: attProvider.isLoadingHistory
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                  : history.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.16),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.event_note_rounded, size: 40, color: Color(0xFF94A3B8)),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Belum ada presensi pada ${_months[_selectedMonth - 1]} $_selectedYear',
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final item = history[index];
                            final isTerlambat = item.status.toUpperCase() == 'TERLAMBAT';
                            final isAlpha = item.status.toUpperCase() == 'TIDAK_HADIR' || item.status.toUpperCase() == 'ALPHA';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isTerlambat
                                      ? const Color(0xFFFDE68A)
                                      : (isAlpha ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
                                  width: 1.1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: () => _showDetailBottomSheet(item),
                                borderRadius: BorderRadius.circular(18),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      // Top: Date + Status Badge
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF8FAFC),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF475569)),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                item.date,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ],
                                          ),
                                          StatusBadge(status: item.status),
                                        ],
                                      ),
                                      const Divider(height: 20, color: Color(0xFFF1F5F9)),

                                      // Metrics Row: Masuk, Pulang, Lokasi
                                      Row(
                                        children: [
                                          // Masuk
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF0FDF4),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: const [
                                                      Icon(Icons.login_rounded, size: 12, color: Color(0xFF047857)),
                                                      SizedBox(width: 4),
                                                      Text('Masuk', style: TextStyle(fontSize: 10.5, color: Color(0xFF047857), fontWeight: FontWeight.w600)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    item.checkIn,
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // Pulang
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEEF2FF),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: const [
                                                      Icon(Icons.logout_rounded, size: 12, color: Color(0xFF4F46E5)),
                                                      SizedBox(width: 4),
                                                      Text('Pulang', style: TextStyle(fontSize: 10.5, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    item.checkOut,
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // Lokasi Kampus
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: const [
                                                      Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF64748B)),
                                                      SizedBox(width: 4),
                                                      Text('Lokasi', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    item.location,
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required int count,
    required Color bg,
    required Color border,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: textColor),
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textColor.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}
