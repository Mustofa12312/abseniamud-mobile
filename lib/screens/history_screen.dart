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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detail Presensi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        item.date,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                  StatusBadge(status: item.status),
                ],
              ),
              const Divider(height: 24),
              _buildDetailItem(Icons.login_rounded, 'Jam Masuk (Check-in)', item.checkIn),
              _buildDetailItem(Icons.logout_rounded, 'Jam Pulang (Check-out)', item.checkOut),
              _buildDetailItem(Icons.location_on_outlined, 'Lokasi Kampus', item.location),
              _buildDetailItem(
                Icons.radar_rounded,
                'Jarak ke Geofence',
                item.distance != null ? '${item.distance} meter' : '-',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.brand700),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight)),
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Riwayat Presensi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CorrectionsScreen()),
              );
            },
            icon: const Icon(Icons.edit_calendar_rounded),
            tooltip: 'Koreksi Presensi',
          ),
        ],
      ),
      body: Column(
        children: [
          // Month & Year Selector Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.brand600),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedMonth,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
                  items: List.generate(12, (index) {
                    return DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text(_months[index]),
                    );
                  }),
                  onChanged: (newMonth) {
                    if (newMonth != null) {
                      setState(() {
                        _selectedMonth = newMonth;
                      });
                      _loadHistory();
                    }
                  },
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedYear,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
                  items: [2024, 2025, 2026, 2027].map((yr) {
                    return DropdownMenuItem<int>(
                      value: yr,
                      child: Text(yr.toString()),
                    );
                  }).toList(),
                  onChanged: (newYear) {
                    if (newYear != null) {
                      setState(() {
                        _selectedYear = newYear;
                      });
                      _loadHistory();
                    }
                  },
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadHistory,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                ),
              ],
            ),
          ),

          // Mini Monthly Stats Summary Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.brand50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('Hadir', summary.hadir, AppColors.statusHadir),
                _buildMiniStat('Terlambat', summary.terlambat, AppColors.statusTerlambat),
                _buildMiniStat('Izin', summary.izinSakit, AppColors.statusIzin),
                _buildMiniStat('Alpha', summary.tidakHadir, AppColors.statusAlpha),
              ],
            ),
          ),

          // History List with Pull to Refresh
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
                            SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_rounded, size: 54, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum ada rekaman presensi pada bulan ${_months[_selectedMonth - 1]} $_selectedYear',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                          final item = history[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _showDetailBottomSheet(item),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item.date,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        StatusBadge(status: item.status),
                                      ],
                                    ),
                                    const Divider(height: 18),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Masuk', style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                                            Text(
                                              item.checkIn,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.brand800),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Pulang', style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                                            Text(
                                              item.checkOut,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF3730A3)),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('Lokasi Kampus', style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                                            Text(
                                              item.location,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
                                            ),
                                          ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CorrectionsScreen()),
          );
        },
        backgroundColor: AppColors.brand600,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text('Ajukan Koreksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }
}
