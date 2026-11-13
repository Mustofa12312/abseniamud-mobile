import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:iaimu_mobile/core/services/document_viewer_service.dart';
import 'package:iaimu_mobile/data/models/attendance_today_model.dart';
import 'package:iaimu_mobile/data/models/attendance_history_model.dart';
import 'package:iaimu_mobile/data/models/campus_location_model.dart';
import 'package:iaimu_mobile/data/models/leave_model.dart';
import 'package:iaimu_mobile/data/models/schedule_model.dart';

void main() {
  group('Model Resilience Tests', () {
    test('AttendanceTodayModel parses float distance & accuracy safely', () {
      final json = {
        'status': 'CHECKED_IN',
        'attendance_status': 'HADIR',
        'check_in_at': '07:15:00',
        'check_out_at': null,
        'location': 'Gedung A',
        'distance': 23.6,
        'accuracy': '8.4',
      };

      final model = AttendanceTodayModel.fromJson(json);
      expect(model.status, 'CHECKED_IN');
      expect(model.isCheckedIn, true);
      expect(model.distance, 24); // rounded
      expect(model.accuracy, 8); // rounded
    });

    test('AttendanceTodayModel handles nulls gracefully', () {
      final json = <String, dynamic>{};
      final model = AttendanceTodayModel.fromJson(json);
      expect(model.status, 'NOT_CHECKED_IN');
      expect(model.isNotCheckedIn, true);
      expect(model.distance, isNull);
      expect(model.accuracy, isNull);
    });

    test('AttendanceHistoryItem handles both camelCase and snake_case', () {
      final jsonCamel = {
        'id': 1,
        'date': '15 Okt 2026',
        'checkIn': '07:10',
        'checkOut': '16:00',
        'location': 'Gedung B',
        'distance': '15.2',
        'status': 'HADIR',
      };
      final itemCamel = AttendanceHistoryItem.fromJson(jsonCamel);
      expect(itemCamel.checkIn, '07:10');
      expect(itemCamel.checkOut, '16:00');
      expect(itemCamel.distance, 15);

      final jsonSnake = {
        'id': '2',
        'date': '14 Okt 2026',
        'check_in': '07:25',
        'check_out': '16:05',
        'location': 'Gedung B',
        'distance': 18,
        'status': 'TERLAMBAT',
      };
      final itemSnake = AttendanceHistoryItem.fromJson(jsonSnake);
      expect(itemSnake.id, 2);
      expect(itemSnake.checkIn, '07:25');
      expect(itemSnake.checkOut, '16:05');
      expect(itemSnake.distance, 18);
    });

    test('CampusLocationModel serializes and deserializes properly', () {
      final loc = CampusLocationModel(
        id: 1,
        name: 'Kampus Utama',
        latitude: -7.166316,
        longitude: 113.483162,
        radius: 75.0,
        maxAccuracy: 50.0,
      );

      final map = loc.toJson();
      final fromMap = CampusLocationModel.fromJson(map);
      expect(fromMap.name, loc.name);
      expect(fromMap.radius, 75.0);
      expect(fromMap.isActive, true);
    });

    test('LeaveModel parses document_path correctly', () {
      final json = {
        'id': 10,
        'type': 'Sakit',
        'start_date': '2026-10-15',
        'end_date': '2026-10-16',
        'reason': 'Demam',
        'document_path': 'surat-dokter-10.pdf',
        'status': 'APPROVED',
        'created_at': '2026-10-15 08:00:00',
      };

      final leave = LeaveModel.fromJson(json);
      expect(leave.isApproved, true);
      expect(leave.documentPath, 'surat-dokter-10.pdf');
    });

    test('CampusLocationModel supports Laravel LocationResource keys (lat, lng, accuracy)', () {
      final resourceJson = {
        'id': 2,
        'name': 'Gedung B Pascasarjana',
        'lat': -7.165432,
        'lng': 113.484321,
        'radius': 60,
        'accuracy': 45,
        'is_active': true,
        'status': 'Aktif',
      };

      final loc = CampusLocationModel.fromJson(resourceJson);
      expect(loc.id, 2);
      expect(loc.name, 'Gedung B Pascasarjana');
      expect(loc.latitude, -7.165432);
      expect(loc.longitude, 113.484321);
      expect(loc.radius, 60.0);
      expect(loc.maxAccuracy, 45.0);
      expect(loc.isActive, true);
    });

    test('Dio compose URL check', () {
      final req = RequestOptions(path: '/auth/login', baseUrl: 'https://api.iaimiftahululum.com/api');
      expect(req.uri.toString(), 'https://api.iaimiftahululum.com/api/auth/login');
    });

    test('ScheduleItem parses academic metadata and builds labels accurately', () {
      final schedule = ScheduleItem.fromJson({
        'id': 7,
        'academic_year_id': 3,
        'course_name': 'Fikih Munakahat',
        'course_code': 'SYR-204',
        'faculty_name': 'Hukum Keluarga Islam',
        'semester': '4',
        'sks': 3,
        'room_name': 'Ruang 301',
        'day_of_week': 'Minggu',
        'start_time': '08:00',
        'end_time': '10:30',
      });

      expect(schedule.academicYearId, 3);
      expect(schedule.courseCode, 'SYR-204');
      expect(schedule.facultyName, 'Hukum Keluarga Islam');
      expect(schedule.semester, 4);
      expect(schedule.sks, 3);
      expect(schedule.programStudyAndSemesterLabel, 'Hukum Keluarga Islam • Semester 4');
      expect(schedule.courseMetaLabel, 'SYR-204 • 3 SKS');

      final fallback = ScheduleItem.fromJson({
        'id': 8,
        'course_name': 'Metodologi',
        'room_name': 'Aula',
      });
      expect(fallback.programStudyAndSemesterLabel, 'Program Studi belum diatur');
      expect(fallback.courseMetaLabel, isNull);
    });

    test('AttendanceTodayModel resolves configured checkout time with 16:00 fallback', () {
      final dynamicToday = AttendanceTodayModel.fromJson({
        'status': 'CHECKED_IN',
        'expected_checkout_time': '14:30:00',
      });
      expect(dynamicToday.resolvedCheckoutTime, (hour: 14, minute: 30));
      expect(dynamicToday.formattedCheckoutTime, '14:30');

      final fallbackToday = AttendanceTodayModel.fromJson({'status': 'CHECKED_IN'});
      expect(fallbackToday.resolvedCheckoutTime, (hour: 16, minute: 0));
      expect(fallbackToday.formattedCheckoutTime, '16:00');
    });

    test('LeaveModel & DocumentViewerService detect document types cleanly', () {
      final uploaded = LeaveModel.fromJson({
        'id': 1,
        'document_path': 'leave-documents/surat-sakit.pdf',
      });
      expect(uploaded.hasDocument, true);
      expect(uploaded.isRemoteDocumentUrl, false);
      expect(uploaded.documentFileName, 'surat-sakit.pdf');
      expect(
        DocumentViewerService.inferMimeType(fileName: uploaded.documentFileName),
        'application/pdf',
      );
      expect(
        DocumentViewerService.isImageAttachment(fileName: 'foto-resep.jpg'),
        true,
      );

      final link = LeaveModel.fromJson({
        'id': 2,
        'document_path': 'https://drive.google.com/file/d/123/view',
      });
      expect(link.hasDocument, true);
      expect(link.isRemoteDocumentUrl, true);
    });
  });
}
