import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../data/models/leave_model.dart';

class LeaveProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<LeaveModel> _leaves = [];
  List<LeaveModel> get leaves => _leaves;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  /// Fetch user leave requests
  Future<void> fetchLeaves() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConstants.leaves);
      if (response != null && response['data'] is List) {
        final list = response['data'] as List;
        _leaves = list
            .whereType<Map>()
            .map((item) => LeaveModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  /// Submit a new leave request (Izin / Sakit / Cuti)
  Future<Map<String, dynamic>> submitLeave({
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
    String? documentPath,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final payload = {
        'type': type,
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
        'document_path': ?documentPath,
      };

      final response = await _apiClient.post(ApiConstants.leaves, data: payload);
      _isSubmitting = false;

      if (response != null && response['success'] == true) {
        await fetchLeaves();
        return {
          'success': true,
          'message': response['message'] ?? 'Pengajuan berhasil dikirim dan menunggu persetujuan.',
        };
      } else {
        return {
          'success': false,
          'message': response?['message'] ?? 'Gagal mengirim pengajuan.',
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
