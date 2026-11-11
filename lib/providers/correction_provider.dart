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

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _lastPage = 1;
  int get lastPage => _lastPage;

  int _total = 0;
  int get total => _total;

  bool get hasMore => _currentPage < _lastPage;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clear() {
    _corrections = [];
    _errorMessage = null;
    _isLoading = false;
    _isLoadingMore = false;
    _currentPage = 1;
    _lastPage = 1;
    _total = 0;
    _isSubmitting = false;
    notifyListeners();
  }

  /// Applies a paginated corrections payload either by replacing or appending items.
  @visibleForTesting
  void applyCorrectionsResponse(Map<String, dynamic> response, {bool append = false, int requestedPage = 1}) {
    final rawList = response['data'] is List ? response['data'] as List : const [];
    final incoming = rawList
        .whereType<Map>()
        .map((item) => AttendanceCorrectionModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    if (append) {
      final existingIds = _corrections.map((e) => e.id).toSet();
      _corrections = [
        ..._corrections,
        ...incoming.where((item) => !existingIds.contains(item.id)),
      ];
    } else {
      _corrections = incoming;
    }

    if (response['meta'] is Map) {
      final meta = Map<String, dynamic>.from(response['meta'] as Map);
      _currentPage = int.tryParse(meta['current_page']?.toString() ?? '') ?? requestedPage;
      _lastPage = int.tryParse(meta['last_page']?.toString() ?? '') ?? _currentPage;
      _total = int.tryParse(meta['total']?.toString() ?? '') ?? _corrections.length;
    } else {
      _currentPage = requestedPage;
      _lastPage = requestedPage;
      _total = _corrections.length;
    }
  }

  /// Fetch user corrections (paginated; set [loadMore] to load the next page)
  Future<void> fetchCorrections({bool loadMore = false, int perPage = 15}) async {
    if (loadMore) {
      if (_isLoading || _isLoadingMore || !hasMore) return;
      _isLoadingMore = true;
    } else {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    final targetPage = loadMore ? _currentPage + 1 : 1;

    try {
      final response = await _apiClient.get(
        ApiConstants.corrections,
        queryParameters: {'page': targetPage, 'per_page': perPage},
      );
      if (response is Map) {
        applyCorrectionsResponse(
          Map<String, dynamic>.from(response),
          append: loadMore,
          requestedPage: targetPage,
        );
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Gagal memuat pengajuan koreksi presensi.';
    }

    _isLoading = false;
    _isLoadingMore = false;
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
        notifyListeners();
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
