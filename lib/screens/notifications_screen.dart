import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../data/models/notification_item_model.dart';
import 'schedules_screen.dart';
import 'leaves_screen.dart';
import 'corrections_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedCategory = 'all';

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showSettingsModal(BuildContext context, SmartNotificationProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Pengaturan Notifikasi Pintar',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Kelola preferensi pemberitahuan otomatis ke smartphone Anda.',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 18),

                    _buildSwitchTile(
                      title: 'Pengingat Jadwal Mengajar',
                      subtitle: 'Notifikasi 15 menit sebelum jam kuliah dimulai',
                      icon: Icons.school_rounded,
                      value: provider.scheduleAlertsEnabled,
                      onChanged: (val) {
                        provider.toggleSetting('schedule', val);
                        setModalState(() {});
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Pengingat Jam Pulang (16:00)',
                      subtitle: 'Pemberitahuan saat jam pulang kerja telah tiba',
                      icon: Icons.logout_rounded,
                      value: provider.checkOutAlertsEnabled,
                      onChanged: (val) {
                        provider.toggleSetting('checkout', val);
                        setModalState(() {});
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Status Persetujuan Izin & Koreksi',
                      subtitle: 'Notifikasi instan saat pengajuan disetujui/ditolak',
                      icon: Icons.verified_user_rounded,
                      value: provider.approvalAlertsEnabled,
                      onChanged: (val) {
                        provider.toggleSetting('approval', val);
                        setModalState(() {});
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Pengumuman Penting Kampus',
                      subtitle: 'Siaran langsung edaran akademik & rektorat',
                      icon: Icons.campaign_rounded,
                      value: provider.announcementAlertsEnabled,
                      onChanged: (val) {
                        provider.toggleSetting('announcement', val);
                        setModalState(() {});
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Deteksi Kedatangan Kampus (Geofence)',
                      subtitle: 'Pengingat check-in saat tiba di area kampus',
                      icon: Icons.location_on_rounded,
                      value: provider.geofenceAlertsEnabled,
                      onChanged: (val) {
                        provider.toggleSetting('geofence', val);
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF047857),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Simpan Pengaturan', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF047857)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: const Color(0xFF047857),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _handleItemTap(NotificationItemModel item) {
    final notifProvider = Provider.of<SmartNotificationProvider>(context, listen: false);
    notifProvider.markAsRead(item.id);

    if (item.type == 'schedule') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SchedulesScreen()));
    } else if (item.type == 'approval') {
      if (item.title.contains('Cuti')) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LeavesScreen()));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CorrectionsScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<SmartNotificationProvider>(context);
    final allItems = notifProvider.items;

    List<NotificationItemModel> filteredItems = allItems;
    if (_selectedCategory == 'schedule') {
      filteredItems = allItems.where((e) => e.type == 'schedule' || e.type == 'checkout').toList();
    } else if (_selectedCategory == 'approval') {
      filteredItems = allItems.where((e) => e.type == 'approval').toList();
    } else if (_selectedCategory == 'announcement') {
      filteredItems = allItems.where((e) => e.type == 'announcement').toList();
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
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const Text(
                          'Pusat Notifikasi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: () => _showSettingsModal(context, notifProvider),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                ),
                                child: const Icon(Icons.tune_rounded, size: 16, color: Colors.white),
                              ),
                            ),
                            if (allItems.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => notifProvider.markAllAsRead(),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                  ),
                                  child: const Icon(Icons.done_all_rounded, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category Pill Bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildCategoryCapsule('all', 'Semua', allItems.length, notifProvider.unreadCount),
                          _buildCategoryCapsule('schedule', 'Jadwal & Pulang', allItems.where((e) => e.type == 'schedule' || e.type == 'checkout').length, 0),
                          _buildCategoryCapsule('approval', 'Persetujuan', allItems.where((e) => e.type == 'approval').length, 0),
                          _buildCategoryCapsule('announcement', 'Pengumuman', allItems.where((e) => e.type == 'announcement').length, 0),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── NOTIFICATION ITEMS LIST ───
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                            ),
                            child: const Icon(Icons.notifications_none_rounded, size: 40, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Belum Ada Notifikasi',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Pemberitahuan jadwal mengajar, pengingat jam pulang, dan status pengajuan akan muncul di sini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => notifProvider.sendTestNotification(),
                            icon: const Icon(Icons.notifications_active_rounded, size: 16),
                            label: const Text('Kirim Uji Coba Notifikasi', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF047857),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _buildNotificationCard(item);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: allItems.isNotEmpty
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => notifProvider.sendTestNotification(),
                      icon: const Icon(Icons.send_rounded, size: 14, color: Color(0xFF047857)),
                      label: const Text(
                        'Tes Notifikasi',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF047857)),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => notifProvider.clearAll(),
                      icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                      label: const Text(
                        'Bersihkan Riwayat',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCategoryCapsule(String id, String label, int count, int unread) {
    final isSelected = _selectedCategory == id;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = id;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF047857) : Colors.white,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (unread > 0 ? const Color(0xFFDC2626) : const Color(0xFF047857))
                        : (unread > 0 ? const Color(0xFFDC2626) : Colors.white.withValues(alpha: 0.25)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItemModel item) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (item.type) {
      case 'schedule':
        icon = Icons.school_rounded;
        iconColor = const Color(0xFF047857);
        bgColor = const Color(0xFFECFDF5);
        break;
      case 'checkout':
        icon = Icons.logout_rounded;
        iconColor = const Color(0xFFD97706);
        bgColor = const Color(0xFFFFFBEB);
        break;
      case 'approval':
        icon = Icons.verified_user_rounded;
        iconColor = const Color(0xFF4F46E5);
        bgColor = const Color(0xFFEEF2FF);
        break;
      case 'announcement':
        icon = Icons.campaign_rounded;
        iconColor = const Color(0xFFDC2626);
        bgColor = const Color(0xFFFEF2F2);
        break;
      case 'geofence':
        icon = Icons.location_on_rounded;
        iconColor = const Color(0xFF059669);
        bgColor = const Color(0xFFF0FDF4);
        break;
      default:
        icon = Icons.notifications_rounded;
        iconColor = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
    }

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
      ),
      onDismissed: (_) {
        final prov = Provider.of<SmartNotificationProvider>(context, listen: false);
        prov.items.removeWhere((e) => e.id == item.id);
        prov.notifyListeners();
      },
      child: InkWell(
        onTap: () => _handleItemTap(item),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.isRead ? const Color(0xFFE2E8F0) : const Color(0xFFA7F3D0),
              width: item.isRead ? 1 : 1.3,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTimestamp(item.timestamp),
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
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
