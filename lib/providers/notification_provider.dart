import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/notification_service.dart';
import '../data/models/notification_item_model.dart';
import '../data/models/schedule_model.dart';
import '../data/models/attendance_today_model.dart';
import '../data/models/leave_model.dart';
import '../data/models/correction_model.dart';
import '../data/models/announcement_model.dart';

class SmartNotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  // Settings
  bool _scheduleAlertsEnabled = true;
  bool _checkOutAlertsEnabled = true;
  bool _approvalAlertsEnabled = true;
  bool _announcementAlertsEnabled = true;
  bool _geofenceAlertsEnabled = true;

  bool get scheduleAlertsEnabled => _scheduleAlertsEnabled;
  bool get checkOutAlertsEnabled => _checkOutAlertsEnabled;
  bool get approvalAlertsEnabled => _approvalAlertsEnabled;
  bool get announcementAlertsEnabled => _announcementAlertsEnabled;
  bool get geofenceAlertsEnabled => _geofenceAlertsEnabled;

  // In-App Notification Items
  List<NotificationItemModel> _items = [];
  List<NotificationItemModel> get items => _items;
  int get unreadCount => _items.where((e) => !e.isRead).length;

  bool _isLoaded = false;
  int _idCounter = 0;

  SmartNotificationProvider() {
    _init();
  }

  Future<void> _init() async {
    if (_isLoaded) return;
    await _service.init();
    await _loadPreferences();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _scheduleAlertsEnabled = prefs.getBool('pref_notif_sched') ?? true;
      _checkOutAlertsEnabled = prefs.getBool('pref_notif_checkout') ?? true;
      _approvalAlertsEnabled = prefs.getBool('pref_notif_approval') ?? true;
      _announcementAlertsEnabled = prefs.getBool('pref_notif_ann') ?? true;
      _geofenceAlertsEnabled = prefs.getBool('pref_notif_geofence') ?? true;

      final itemsJson = prefs.getString('pref_notif_items');
      if (itemsJson != null) {
        final List decoded = jsonDecode(itemsJson);
        _items = decoded
            .whereType<Map>()
            .map((e) => NotificationItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_notif_sched', _scheduleAlertsEnabled);
      await prefs.setBool('pref_notif_checkout', _checkOutAlertsEnabled);
      await prefs.setBool('pref_notif_approval', _approvalAlertsEnabled);
      await prefs.setBool('pref_notif_ann', _announcementAlertsEnabled);
      await prefs.setBool('pref_notif_geofence', _geofenceAlertsEnabled);

      final encoded = jsonEncode(_items.map((e) => e.toJson()).toList());
      await prefs.setString('pref_notif_items', encoded);
    } catch (_) {}
  }

  Future<void> toggleSetting(String key, bool value) async {
    switch (key) {
      case 'schedule':
        _scheduleAlertsEnabled = value;
        break;
      case 'checkout':
        _checkOutAlertsEnabled = value;
        break;
      case 'approval':
        _approvalAlertsEnabled = value;
        break;
      case 'announcement':
        _announcementAlertsEnabled = value;
        break;
      case 'geofence':
        _geofenceAlertsEnabled = value;
        break;
    }
    notifyListeners();
    await _savePreferences();
  }

  Future<void> requestPermissions() async {
    await _service.requestPermissions();
  }

  String _getTodayDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  // ─── ADD NOTIFICATION TO LIST & PUSH SYSTEM NOTIFICATION ───
  Future<void> addNotification({
    required String title,
    required String body,
    required String type,
    String? channelId,
    String? payload,
    int? notificationId,
  }) async {
    final notifItem = NotificationItemModel(
      id: '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}',
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
      payload: payload,
    );

    _items.insert(0, notifItem);
    // Keep max 50 recent items
    if (_items.length > 50) {
      _items = _items.sublist(0, 50);
    }

    notifyListeners();
    await _savePreferences();

    // Show native system notification
    await _service.showNotification(
      id: notificationId ?? (DateTime.now().millisecondsSinceEpoch % 100000),
      title: title,
      body: body,
      channelId: channelId,
      payload: payload,
    );
  }

  void markAsRead(String id) {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx].isRead = true;
      notifyListeners();
      _savePreferences();
    }
  }

  void markAllAsRead() {
    for (var item in _items) {
      item.isRead = true;
    }
    notifyListeners();
    _savePreferences();
  }

  void clearAll() {
    _items.clear();
    notifyListeners();
    _savePreferences();
  }

  // ─── TRIGGER 1: SCHEDULE CLASS REMINDER (15 MIN BEFORE CLASS) ───
  Future<void> checkScheduleReminders(List<ScheduleItem> todaySchedules) async {
    if (!_scheduleAlertsEnabled || todaySchedules.isEmpty) return;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final todayKey = _getTodayDateKey();
    final prefs = await SharedPreferences.getInstance();

    for (var item in todaySchedules) {
      try {
        final parts = item.startTime.split(':').map((e) => int.tryParse(e) ?? 0).toList();
        if (parts.length >= 2) {
          final startMinutes = parts[0] * 60 + parts[1];
          final diff = startMinutes - currentMinutes;

          // Alert 15 minutes before class (window 0 to 15 minutes)
          if (diff >= 0 && diff <= 15) {
            final cacheKey = 'reminded_sched_${item.id}_$todayKey';
            final alreadyReminded = prefs.getBool(cacheKey) ?? false;

            if (!alreadyReminded) {
              await addNotification(
                title: 'Pengingat Kuliah: ${item.courseName}',
                body: 'Jadwal di ${item.roomName} dimulai pukul ${item.startTime} WIB ($diff menit lagi). Jangan lupa presensi masuk!',
                type: 'schedule',
                channelId: NotificationService.channelReminders,
                notificationId: item.id + 1000,
              );
              await prefs.setBool(cacheKey, true);
            }
          } else if (diff > 15) {
            // Schedule background alarm 15 minutes before class
            final reminderDate = DateTime(
              now.year,
              now.month,
              now.day,
              parts[0],
              parts[1],
            ).subtract(const Duration(minutes: 15));

            if (reminderDate.isAfter(now)) {
              await _service.scheduleNotification(
                id: item.id + 1000,
                title: 'Pengingat Kuliah: ${item.courseName}',
                body: 'Jadwal di ${item.roomName} dimulai pukul ${item.startTime} WIB (15 menit lagi). Jangan lupa presensi masuk!',
                scheduledDate: reminderDate,
                channelId: NotificationService.channelReminders,
                payload: 'schedule_${item.id}',
              );
            }
          }
        }
      } catch (_) {}
    }
  }

  // ─── TRIGGER 2: CHECK-OUT PULANG REMINDER (DYNAMIC SERVER SETTING / 16:00 WIB) ───
  Future<void> checkCheckOutReminder(
    AttendanceTodayModel? today, {
    DateTime? nowOverride,
  }) async {
    if (!_checkOutAlertsEnabled || today == null) return;

    // If user has already checked out, cancel any pending check-out alarm
    if (today.isCheckedOut) {
      await _service.cancel(9999);
      return;
    }

    // Only if already checked in and not yet checked out
    if (today.isCheckedIn && !today.isCheckedOut) {
      final now = nowOverride ?? DateTime.now();
      final checkout = today.resolvedCheckoutTime;
      final currentMinutes = now.hour * 60 + now.minute;
      final checkoutMinutes = checkout.hour * 60 + checkout.minute;

      if (currentMinutes >= checkoutMinutes) {
        final todayKey = _getTodayDateKey();
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = 'reminded_checkout_$todayKey';
        final alreadyReminded = prefs.getBool(cacheKey) ?? false;

        if (!alreadyReminded) {
          final formattedTime = today.formattedCheckoutTime;
          await addNotification(
            title: 'Waktu Pulang Kerja ($formattedTime WIB)',
            body: 'Jam kerja wajib telah selesai. Pastikan Anda telah melakukan Check-Out Pulang sebelum meninggalkan kampus.',
            type: 'checkout',
            channelId: NotificationService.channelReminders,
            notificationId: 9999,
          );
          await prefs.setBool(cacheKey, true);
        }
      } else {
        // Schedule future alarm for checkout time today
        final targetDate = DateTime(
          now.year,
          now.month,
          now.day,
          checkout.hour,
          checkout.minute,
        );
        if (targetDate.isAfter(now)) {
          final formattedTime = today.formattedCheckoutTime;
          await _service.scheduleNotification(
            id: 9999,
            title: 'Waktu Pulang Kerja ($formattedTime WIB)',
            body: 'Jam kerja wajib telah selesai. Pastikan Anda telah melakukan Check-Out Pulang sebelum meninggalkan kampus.',
            scheduledDate: targetDate,
            channelId: NotificationService.channelReminders,
            payload: 'checkout_reminder',
          );
        }
      }
    }
  }

  void removeItem(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    _savePreferences();
  }

  Future<void> clearUserData() async {
    _items.clear();
    notifyListeners();
    await _savePreferences();
  }

  // ─── TRIGGER 3: APPROVAL STATUS UPDATES (LEAVES & CORRECTIONS) ───
  Future<void> checkApprovalUpdates(List<LeaveModel> leaves, List<AttendanceCorrectionModel> corrections) async {
    if (!_approvalAlertsEnabled) return;
    final prefs = await SharedPreferences.getInstance();

    // 1. Check Leaves
    for (var leave in leaves) {
      final key = 'prev_leave_status_${leave.id}';
      final prevStatus = prefs.getString(key);

      if (prevStatus != null && prevStatus != leave.status) {
        if (leave.status == 'APPROVED') {
          await addNotification(
            title: 'Pengajuan ${leave.type} Disetujui ✓',
            body: 'Permohonan ${leave.type} tanggal ${leave.startDate} telah disetujui oleh Bagian Kepegawaian.',
            type: 'approval',
            channelId: NotificationService.channelApprovals,
            payload: 'leave',
            notificationId: leave.id + 2000,
          );
        } else if (leave.status == 'REJECTED') {
          await addNotification(
            title: 'Pengajuan ${leave.type} Ditolak',
            body: 'Permohonan ${leave.type} tanggal ${leave.startDate} ditolak.',
            type: 'approval',
            channelId: NotificationService.channelApprovals,
            payload: 'leave',
            notificationId: leave.id + 2000,
          );
        }
      }
      await prefs.setString(key, leave.status);
    }

    // 2. Check Corrections
    for (var corr in corrections) {
      final key = 'prev_corr_status_${corr.id}';
      final prevStatus = prefs.getString(key);

      if (prevStatus != null && prevStatus != corr.status) {
        if (corr.status == 'APPROVED') {
          await addNotification(
            title: 'Koreksi Presensi Disetujui ✓',
            body: 'Koreksi presensi tanggal ${corr.date} berhasil diverifikasi dan disetujui.',
            type: 'approval',
            channelId: NotificationService.channelApprovals,
            payload: 'correction',
            notificationId: corr.id + 4000,
          );
        } else if (corr.status == 'REJECTED') {
          await addNotification(
            title: 'Koreksi Presensi Ditolak',
            body: 'Koreksi presensi tanggal ${corr.date} ditolak oleh verifikator.',
            type: 'approval',
            channelId: NotificationService.channelApprovals,
            payload: 'correction',
            notificationId: corr.id + 4000,
          );
        }
      }
      await prefs.setString(key, corr.status);
    }
  }

  // ─── TRIGGER 4: CAMPUS ANNOUNCEMENTS BROADCAST ───
  Future<void> checkAnnouncementAlerts(List<AnnouncementModel> announcements) async {
    if (!_announcementAlertsEnabled || announcements.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();

    for (var ann in announcements) {
      if (ann.isImportant) {
        final key = 'reminded_ann_${ann.id}';
        final alreadyReminded = prefs.getBool(key) ?? false;

        if (!alreadyReminded) {
          final preview = ann.content.length > 80 ? '${ann.content.substring(0, 80)}...' : ann.content;
          await addNotification(
            title: '[PENTING] ${ann.title}',
            body: preview,
            type: 'announcement',
            channelId: NotificationService.channelBroadcasts,
            notificationId: ann.id + 5000,
          );
          await prefs.setBool(key, true);
        }
      }
    }
  }

  // ─── TRIGGER 5: GEOFENCE ARRIVAL ALERT ───
  Future<void> checkGeofenceArrival(bool isWithinGeofence, String campusName, AttendanceTodayModel? today) async {
    if (!_geofenceAlertsEnabled) return;
    if (!isWithinGeofence || (today != null && !today.isNotCheckedIn)) return;

    final todayKey = _getTodayDateKey();
    final prefs = await SharedPreferences.getInstance();
    final key = 'geofence_arrival_$todayKey';
    final alreadyReminded = prefs.getBool(key) ?? false;

    if (!alreadyReminded) {
      await addNotification(
        title: 'Selamat Datang di Kampus!',
        body: 'Anda telah berada di area $campusName. Jangan lupa lakukan Presensi Masuk di aplikasi.',
        type: 'geofence',
        channelId: NotificationService.channelGeofence,
        notificationId: 8888,
      );
      await prefs.setBool(key, true);
    }
  }

  // ─── MANUAL TEST NOTIFICATION ───
  Future<void> sendTestNotification() async {
    await addNotification(
      title: 'Uji Coba Notifikasi Pintar IAIMU',
      body: 'Sistem notifikasi pengingat presensi dan jadwal berhasil aktif pada smartphone Anda.',
      type: 'schedule',
      channelId: NotificationService.channelReminders,
      notificationId: 7777,
    );
  }
}
