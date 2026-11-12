import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iaimu_mobile/core/device/device_info_service.dart';
import 'package:iaimu_mobile/core/network/api_client.dart';
import 'package:iaimu_mobile/data/models/attendance_today_model.dart';
import 'package:iaimu_mobile/data/models/campus_location_model.dart';
import 'package:iaimu_mobile/providers/attendance_provider.dart';
import 'package:iaimu_mobile/providers/correction_provider.dart';
import 'package:iaimu_mobile/providers/device_security_provider.dart';
import 'package:iaimu_mobile/providers/leave_provider.dart';
import 'package:iaimu_mobile/widgets/mock_location_warning.dart';
import 'package:iaimu_mobile/widgets/status_badge.dart';

void main() {
  group('ApiClient Security & URL Validation', () {
    test('isLocalOrPrivateHost identifies local/private hosts accurately', () {
      expect(ApiClient.isLocalOrPrivateHost('localhost'), isTrue);
      expect(ApiClient.isLocalOrPrivateHost('127.0.0.1'), isTrue);
      expect(ApiClient.isLocalOrPrivateHost('::1'), isTrue);
      expect(ApiClient.isLocalOrPrivateHost('10.0.2.2'), isTrue);
      expect(ApiClient.isLocalOrPrivateHost('10.10.20.30'), isTrue);
      expect(ApiClient.isLocalOrPrivateHost('192.168.1.87'), isTrue);
      expect(ApiClient.isLocalOrPrivateHost('172.16.0.10'), isTrue);
      expect(ApiClient.isLocalOrPrivateHost('172.31.255.1'), isTrue);

      expect(ApiClient.isLocalOrPrivateHost('172.32.0.1'), isFalse);
      expect(ApiClient.isLocalOrPrivateHost('8.8.8.8'), isFalse);
      expect(ApiClient.isLocalOrPrivateHost('api.iaimiftahululum.com'), isFalse);
      expect(ApiClient.isLocalOrPrivateHost('evil.com'), isFalse);
    });

    test('shouldAllowBadCertificate only permits private/local hosts in debug mode', () {
      // Never allow bad certificates in release builds, even for local/private hosts
      expect(ApiClient.shouldAllowBadCertificate('localhost', isDebug: false), isFalse);
      expect(ApiClient.shouldAllowBadCertificate('10.0.2.2', isDebug: false), isFalse);
      expect(ApiClient.shouldAllowBadCertificate('192.168.1.87', isDebug: false), isFalse);
      expect(
        ApiClient.shouldAllowBadCertificate('api.iaimiftahululum.com', isDebug: false),
        isFalse,
      );

      // In debug mode, only private/local hosts are allowed; public domains are rejected
      expect(ApiClient.shouldAllowBadCertificate('localhost', isDebug: true), isTrue);
      expect(ApiClient.shouldAllowBadCertificate('10.0.2.2', isDebug: true), isTrue);
      expect(ApiClient.shouldAllowBadCertificate('192.168.1.87', isDebug: true), isTrue);
      expect(
        ApiClient.shouldAllowBadCertificate('api.iaimiftahululum.com', isDebug: true),
        isFalse,
      );
      expect(ApiClient.shouldAllowBadCertificate('evil.com', isDebug: true), isFalse);
    });

    test('normalizeServerUrl trims whitespace and trailing slashes', () {
      expect(
        ApiClient.normalizeServerUrl('  https://api.iaimiftahululum.com/api///  '),
        'https://api.iaimiftahululum.com/api',
      );
      expect(
        ApiClient.normalizeServerUrl('http://10.0.2.2:8000/api/'),
        'http://10.0.2.2:8000/api',
      );
    });

    test('validateServerUrl enforces HTTPS in release mode and validates format', () {
      expect(ApiClient.validateServerUrl('', isDebug: true), isNotNull);
      expect(ApiClient.validateServerUrl('not-a-url', isDebug: true), isNotNull);
      expect(ApiClient.validateServerUrl('ftp://example.com/api', isDebug: true), isNotNull);

      // Release enforces HTTPS
      expect(
        ApiClient.validateServerUrl('http://192.168.1.87:8000/api', isDebug: false),
        isNotNull,
      );
      expect(
        ApiClient.validateServerUrl('http://api.iaimiftahululum.com/api', isDebug: false),
        isNotNull,
      );
      expect(
        ApiClient.validateServerUrl('https://api.iaimiftahululum.com/api', isDebug: false),
        isNull,
      );

      // Debug permits local HTTP
      expect(
        ApiClient.validateServerUrl('http://10.0.2.2:8000/api', isDebug: true),
        isNull,
      );
    });
  });

  group('DeviceSecurityProvider Campus Location Sync', () {
    const geolocatorChannel = MethodChannel('flutter.baseflow.com/geolocator');

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(geolocatorChannel, (MethodCall call) async {
        if (call.method == 'isLocationServiceEnabled') {
          return false;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(geolocatorChannel, null);
    });

    CampusLocationModel campus(int id, String name, {double radius = 75}) => CampusLocationModel(
          id: id,
          name: name,
          latitude: -7.166316 + id * 0.001,
          longitude: 113.483162 + id * 0.001,
          radius: radius,
          maxAccuracy: 50,
        );

    test('setCampusLocations selects first, preserves matching ID, and handles empty', () async {
      final provider = DeviceSecurityProvider();

      // Initially empty
      expect(provider.campusLocations, isEmpty);
      expect(provider.selectedCampus, isNull);

      // First set auto-selects first campus
      provider.setCampusLocations([campus(1, 'Kampus A'), campus(2, 'Kampus B')]);
      expect(provider.selectedCampus?.id, 1);
      expect(provider.selectedCampus?.name, 'Kampus A');

      // Select Kampus B explicitly
      provider.selectCampus(campus(2, 'Kampus B'));
      await Future<void>.delayed(Duration.zero);
      expect(provider.selectedCampus?.id, 2);

      // Refresh list where Kampus B still exists with updated metadata
      provider.setCampusLocations([
        campus(1, 'Kampus A'),
        campus(2, 'Kampus B Renovasi', radius: 120),
      ]);
      expect(provider.selectedCampus?.id, 2);
      expect(provider.selectedCampus?.name, 'Kampus B Renovasi');
      expect(provider.selectedCampus?.radius, 120);

      // Refresh list where selected ID 2 is removed -> falls back to first
      provider.setCampusLocations([campus(3, 'Kampus C')]);
      expect(provider.selectedCampus?.id, 3);

      // Empty list clears selection
      provider.setCampusLocations([]);
      expect(provider.campusLocations, isEmpty);
      expect(provider.selectedCampus, isNull);

      // clearLocationState resets locations
      provider.setCampusLocations([campus(1, 'Kampus A')]);
      provider.clearLocationState();
      expect(provider.campusLocations, isEmpty);
      expect(provider.selectedCampus, isNull);
    });
  });

  group('AttendanceTodayModel Status Mapping', () {
    test('parses HOLIDAY, NOT_CHECKED_IN, CHECKED_IN, CHECKED_OUT states', () {
      final holiday = AttendanceTodayModel.fromJson({'status': 'HOLIDAY'});
      expect(holiday.isHoliday, isTrue);
      expect(holiday.isNotCheckedIn, isFalse);
      expect(holiday.isCheckedIn, isFalse);
      expect(holiday.isCheckedOut, isFalse);

      final notCheckedIn = AttendanceTodayModel.fromJson({'status': 'NOT_CHECKED_IN'});
      expect(notCheckedIn.isNotCheckedIn, isTrue);
      expect(notCheckedIn.isHoliday, isFalse);

      final checkedIn = AttendanceTodayModel.fromJson({'status': 'CHECKED_IN'});
      expect(checkedIn.isCheckedIn, isTrue);
      expect(checkedIn.isCheckedOut, isFalse);

      final checkedOut = AttendanceTodayModel.fromJson({'status': 'CHECKED_OUT'});
      expect(checkedOut.isCheckedOut, isTrue);
      expect(checkedOut.isCheckedIn, isFalse);
    });
  });

  group('Core Status & Security Widgets', () {
    testWidgets('StatusBadge renders HOLIDAY and case-insensitive statuses without crashing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(status: 'HOLIDAY'),
                StatusBadge(status: 'approved'),
                StatusBadge(status: 'rejected'),
                StatusBadge(status: 'sakit'),
                StatusBadge(status: 'CUTI'),
                StatusBadge(status: 'VALID'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(StatusBadge), findsNWidgets(6));
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      expect(texts.length, 6);
      expect(texts.toSet().length, 6);
    });

    testWidgets('MockLocationWarning renders distinct UI states for mock, error, and safe', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MockLocationWarning(
                  isMockDetected: true,
                  reason: 'Fake GPS terdeteksi',
                ),
                MockLocationWarning(
                  isMockDetected: false,
                  errorMessage: 'Izin lokasi ditolak',
                ),
                MockLocationWarning(
                  isMockDetected: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(MockLocationWarning), findsNWidgets(3));
      expect(find.textContaining('Fake GPS terdeteksi'), findsOneWidget);
      expect(find.textContaining('Izin lokasi ditolak'), findsOneWidget);
    });
  });

  group('Prioritas Tinggi: Fingerprint, Pagination & Leave Attachment', () {
    test('DeviceInfoService builds deterministic SHA-256 fingerprint', () {
      final fp1 = DeviceInfoService.buildDeterministicFingerprint(
        platform: 'android',
        manufacturer: 'Xiaomi',
        brand: 'Redmi',
        model: '2312DRA50G',
        hardwareId: 'qcom:garnet:garnet:garnet',
      );
      final fp2 = DeviceInfoService.buildDeterministicFingerprint(
        platform: 'android',
        manufacturer: '  xiaomi ',
        brand: 'redmi',
        model: '2312dra50g',
        hardwareId: 'qcom:garnet:garnet:garnet',
      );
      final fpDifferent = DeviceInfoService.buildDeterministicFingerprint(
        platform: 'ios',
        manufacturer: 'Apple',
        brand: 'Apple',
        model: 'iPhone 15 Pro',
        hardwareId: 'UUID-9988',
      );

      expect(fp1, matches(RegExp(r'^IAIMU-[0-9A-F]{16}$')));
      expect(fp1, fp2);
      expect(fpDifferent, isNot(fp1));
      expect(fpDifferent, matches(RegExp(r'^IAIMU-[0-9A-F]{16}$')));
    });

    test('AttendanceProvider & CorrectionProvider apply paginated responses and deduplicate', () {
      final attendanceProvider = AttendanceProvider();
      attendanceProvider.applyHistoryResponse({
        'data': [
          {'id': 1, 'date': '10 Nov 2026', 'checkIn': '07:05', 'checkOut': '14:00', 'location': 'Kampus', 'status': 'HADIR'},
          {'id': 2, 'date': '09 Nov 2026', 'checkIn': '07:30', 'checkOut': '14:05', 'location': 'Kampus', 'status': 'TERLAMBAT'},
        ],
        'meta': {'current_page': 1, 'last_page': 2, 'total': 3},
      });
      expect(attendanceProvider.historyList.length, 2);
      expect(attendanceProvider.hasMoreHistory, isTrue);
      expect(attendanceProvider.historyTotal, 3);

      attendanceProvider.applyHistoryResponse({
        'data': [
          {'id': 2, 'date': '09 Nov 2026', 'checkIn': '07:30', 'checkOut': '14:05', 'location': 'Kampus', 'status': 'TERLAMBAT'},
          {'id': 3, 'date': '08 Nov 2026', 'checkIn': '07:01', 'checkOut': '14:10', 'location': 'Kampus', 'status': 'HADIR'},
        ],
        'meta': {'current_page': 2, 'last_page': 2, 'total': 3},
      }, append: true);
      expect(attendanceProvider.historyList.length, 3);
      expect(attendanceProvider.hasMoreHistory, isFalse);

      final correctionProvider = CorrectionProvider();
      correctionProvider.applyCorrectionsResponse({
        'data': [
          {'id': 10, 'date': '10 Nov 2026', 'type': 'Lupa Presensi Masuk', 'reason': 'Lupa', 'status': 'PENDING', 'created_at': '10/11/2026'},
        ],
        'meta': {'current_page': 1, 'last_page': 2, 'total': 2},
      });
      expect(correctionProvider.corrections.length, 1);
      expect(correctionProvider.hasMore, isTrue);

      correctionProvider.applyCorrectionsResponse({
        'data': [
          {'id': 10, 'date': '10 Nov 2026', 'type': 'Lupa Presensi Masuk', 'reason': 'Lupa', 'status': 'PENDING', 'created_at': '10/11/2026'},
          {'id': 11, 'date': '09 Nov 2026', 'type': 'Lupa Presensi Pulang', 'reason': 'HP mati', 'status': 'APPROVED', 'created_at': '09/11/2026'},
        ],
        'meta': {'current_page': 2, 'last_page': 2, 'total': 2},
      }, append: true);
      expect(correctionProvider.corrections.length, 2);
      expect(correctionProvider.hasMore, isFalse);
    });

    test('LeaveProvider validates attachments and builds multipart FormData when file bytes provided', () async {
      expect(LeaveProvider.validateAttachment(fileName: 'surat.docx', sizeBytes: 1024), isNotNull);
      expect(LeaveProvider.validateAttachment(fileName: 'besar.pdf', sizeBytes: 6 * 1024 * 1024), isNotNull);
      expect(LeaveProvider.validateAttachment(fileName: 'surat_dokter.PDF', sizeBytes: 2048), isNull);
      expect(LeaveProvider.validateAttachment(fileName: 'foto.jpeg', sizeBytes: 4096), isNull);

      final leaveProvider = LeaveProvider();
      final textPayload = await leaveProvider.buildSubmitPayload(
        type: 'Izin',
        startDate: '2026-11-11',
        endDate: '2026-11-11',
        reason: 'Urusan keluarga',
        documentPath: 'SRT-001',
      );
      expect(textPayload, isA<Map<String, dynamic>>());
      expect((textPayload as Map)['document_path'], 'SRT-001');

      final multipartPayload = await leaveProvider.buildSubmitPayload(
        type: 'Sakit',
        startDate: '2026-11-11',
        endDate: '2026-11-12',
        reason: 'Demam tinggi',
        documentBytes: [1, 2, 3, 4],
        documentFileName: 'surat.pdf',
      );
      expect(multipartPayload, isA<FormData>());
      final formData = multipartPayload as FormData;
      expect(formData.files.any((entry) => entry.key == 'document' && entry.value.filename == 'surat.pdf'), isTrue);
    });
  });

  group('Konsistensi Izin & holiday_name Model Mapping', () {
    test('AttendanceTodayModel parses holiday_name and ON_LEAVE payload accurately', () {
      final holiday = AttendanceTodayModel.fromJson({
        'status': 'HOLIDAY',
        'holiday_name': 'Maulid Nabi Muhammad SAW',
      });
      expect(holiday.isHoliday, isTrue);
      expect(holiday.isOnLeave, isFalse);
      expect(holiday.holidayName, 'Maulid Nabi Muhammad SAW');

      final onLeave = AttendanceTodayModel.fromJson({
        'status': 'ON_LEAVE',
        'leave_type': 'Sakit',
        'attendance_status': 'SAKIT',
      });
      expect(onLeave.isOnLeave, isTrue);
      expect(onLeave.isHoliday, isFalse);
      expect(onLeave.leaveType, 'Sakit');
      expect(onLeave.attendanceStatus, 'SAKIT');
    });
  });
}
