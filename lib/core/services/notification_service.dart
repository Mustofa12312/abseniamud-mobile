import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Channel IDs
  static const String channelReminders = 'iaimu_reminders';
  static const String channelApprovals = 'iaimu_approvals';
  static const String channelBroadcasts = 'iaimu_broadcasts';
  static const String channelGeofence = 'iaimu_geofence';

  /// Initialize local notification plugin and channels
  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      // Create Android Notification Channels
      if (Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          // Channel 1: Schedule & Check-out Reminders
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              channelReminders,
              'Pengingat Presensi & Jadwal',
              description: 'Pengingat otomatis jadwal mengajar dan waktu check-out',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );

          // Channel 2: Approvals (Leaves & Corrections)
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              channelApprovals,
              'Status Pengajuan Izin & Koreksi',
              description: 'Pemberitahuan persetujuan cuti dan koreksi presensi',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
          );

          // Channel 3: Campus Announcements Broadcast
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              channelBroadcasts,
              'Pengumuman Kampus',
              description: 'Siaran pengumuman akademik dan institusi',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
          );

          // Channel 4: Geofence Arrival
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              channelGeofence,
              'Kedatangan Kampus',
              description: 'Notifikasi saat perangkat memasuki area kampus',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
          );
        }
      }

      _isInitialized = true;
      debugPrint('NotificationService successfully initialized.');
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Request runtime permissions (especially Android 13+)
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    }
    return true;
  }

  /// Display an immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
    String? payload,
  }) async {
    final channel = channelId ?? channelReminders;

    String channelName = 'Pengingat Presensi';
    if (channel == channelApprovals) channelName = 'Persetujuan Izin & Koreksi';
    if (channel == channelBroadcasts) channelName = 'Pengumuman Kampus';
    if (channel == channelGeofence) channelName = 'Kedatangan Kampus';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channel,
      channelName,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all active notifications
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
