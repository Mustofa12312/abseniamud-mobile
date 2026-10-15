import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/schedule_provider.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  @override
  void initState() {
    super.initState();
    // Default to today's day of week
    final todayWeekday = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
    _tabController = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: (todayWeekday - 1).clamp(0, 6),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScheduleProvider>(context, listen: false).fetchSchedules();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schedProvider = Provider.of<ScheduleProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Jadwal Mengajar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.brand700,
          unselectedLabelColor: AppColors.textSecondaryLight,
          indicatorColor: AppColors.brand600,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: _days.map((day) => Tab(text: day)).toList(),
        ),
      ),
      body: schedProvider.isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : TabBarView(
              controller: _tabController,
              children: _days.map((day) {
                final schedules = schedProvider.getSchedulesForDay(day);

                if (schedules.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_busy_rounded, size: 54, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada jadwal kuliah pada hari $day.',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => schedProvider.fetchSchedules(),
                  color: AppColors.brand600,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: schedules.length,
                    itemBuilder: (context, index) {
                      final item = schedules[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.brand800,
                                      ),
                                    ),
                                    const Text('s/d', style: TextStyle(fontSize: 10, color: AppColors.textMutedLight)),
                                    Text(
                                      item.endTime,
                                      style: const TextStyle(
                                        fontSize: 13,
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
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.meeting_room_outlined, size: 16, color: AppColors.textSecondaryLight),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Ruang: ${item.roomName}',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
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
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
    );
  }
}
