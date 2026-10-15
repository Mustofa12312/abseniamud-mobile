import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../data/models/correction_model.dart';

class CorrectionProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<AttendanceCorrectionModel> _corrections = [];
  List<AttendanceCorrectionModel> get corrections => _corrections;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  /// Fetch user corrections
  Future<void> fetchCorrections() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConstants.corrections);
      if (response != null && response['data'] is List) {
        final list = response['data'] as List;
        _corrections = list
            .whereType<Map>()
            .map((item) => AttendanceCorrectionModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  /// Submit correction
  Future<Map<String, dynamic>> submitCorrection({
    required String date,
    required String type,
    required String reason,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final payload = {
        'date': date,
        'type': type,
        'reason': reason,
      };

      final response = await _apiClient.post(ApiConstants.corrections, data: payload);
      _isSubmitting = false;

      if (response != null && response['success'] == true) {
        await fetchCorrections();
        return {
          'success': true,
          'message': response['message'] ?? 'Pengajuan koreksi presensi berhasil dikirim.',
        };
      } else {
        return {
          'success': false,
          'message': response?['message'] ?? 'Gagal mengirim pengajuan koreksi.',
        };
      }
    } on ApiException catch (e) {
      _isSubmitting = false;
      notifyListeners();
      return {'success': false, 'message': e.message};
    } catch (e) {
      _isSubmitting = false;
      notifyListeners();
      return {'success': false, 'message': 'Terjadi kendala: ${e.toString()}'};
    }
  }
}
