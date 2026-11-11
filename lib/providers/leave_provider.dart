import 'package:dio/dio.dart';
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

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clear() {
    _leaves = [];
    _errorMessage = null;
    _isLoading = false;
    _isSubmitting = false;
    notifyListeners();
  }

  /// Fetch user leave requests
  Future<void> fetchLeaves() async {
    _isLoading = true;
    _errorMessage = null;
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
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Gagal memuat daftar pengajuan izin & cuti.';
    }

    _isLoading = false;
    notifyListeners();
  }

  static const int maxAttachmentBytes = 5 * 1024 * 1024;
  static const List<String> allowedAttachmentExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

  /// Validates an optional selected file extension and size (<= 5 MB).
  static String? validateAttachment({
    required String fileName,
    required int sizeBytes,
  }) {
    final parts = fileName.trim().toLowerCase().split('.');
    final ext = parts.length > 1 ? parts.last : '';
    if (!allowedAttachmentExtensions.contains(ext)) {
      return 'Format berkas harus PDF, JPG, JPEG, atau PNG.';
    }
    if (sizeBytes > maxAttachmentBytes) {
      return 'Ukuran berkas maksimal 5 MB.';
    }
    return null;
  }

  /// Builds request payload (FormData when a physical file is attached, Map otherwise).
  @visibleForTesting
  Future<dynamic> buildSubmitPayload({
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
    String? documentPath,
    String? documentFilePath,
    String? documentFileName,
    List<int>? documentBytes,
  }) async {
    final cleanDocPath = documentPath?.trim();
    final hasFileBytes = documentBytes != null && documentBytes.isNotEmpty;
    final hasFilePath = documentFilePath != null && documentFilePath.trim().isNotEmpty;

    if (!hasFileBytes && !hasFilePath) {
      return {
        'type': type,
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
        if (cleanDocPath != null && cleanDocPath.isNotEmpty) 'document_path': cleanDocPath,
      };
    }

    final resolvedName = (documentFileName != null && documentFileName.trim().isNotEmpty)
        ? documentFileName.trim()
        : (documentFilePath ?? 'document').split(RegExp(r'[/\\]')).last;

    final multipartFile = hasFileBytes
        ? MultipartFile.fromBytes(documentBytes, filename: resolvedName)
        : await MultipartFile.fromFile(documentFilePath!.trim(), filename: resolvedName);

    return FormData.fromMap({
      'type': type,
      'start_date': startDate,
      'end_date': endDate,
      'reason': reason,
      'document': multipartFile,
      if (cleanDocPath != null && cleanDocPath.isNotEmpty) 'document_path': cleanDocPath,
    });
  }

  /// Submit a new leave request (Izin / Sakit / Cuti), with optional file or reference
  Future<Map<String, dynamic>> submitLeave({
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
    String? documentPath,
    String? documentFilePath,
    String? documentFileName,
    List<int>? documentBytes,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final payload = await buildSubmitPayload(
        type: type,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        documentPath: documentPath,
        documentFilePath: documentFilePath,
        documentFileName: documentFileName,
        documentBytes: documentBytes,
      );

      final response = await _apiClient.post(ApiConstants.leaves, data: payload);
      _isSubmitting = false;

      if (response != null && response['success'] == true) {
        await fetchLeaves();
        return {
          'success': true,
          'message': response['message'] ?? 'Pengajuan berhasil dikirim dan menunggu persetujuan.',
        };
      } else {
        notifyListeners();
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
