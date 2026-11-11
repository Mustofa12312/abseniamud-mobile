import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/theme/app_colors.dart';

/// Shared dialog for inspecting, testing, and updating the backend API URL.
class ServerConfigDialog extends StatefulWidget {
  final String initialUrl;

  const ServerConfigDialog({
    super.key,
    required this.initialUrl,
  });

  /// Opens the dialog and returns the newly saved URL, or null if cancelled.
  static Future<String?> show(BuildContext context, {String? initialUrl}) async {
    final startUrl = initialUrl ?? await SecureStorageService().getBaseUrl();
    if (!context.mounted) return null;
    return showDialog<String>(
      context: context,
      builder: (_) => ServerConfigDialog(initialUrl: startUrl),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _controller;
  bool _isTesting = false;
  bool _isSaving = false;
  String? _validationError;
  Map<String, dynamic>? _testResult;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    HapticFeedback.selectionClick();
    final err = ApiClient.validateServerUrl(_controller.text);
    if (err != null) {
      setState(() {
        _validationError = err;
        _testResult = null;
      });
      return;
    }

    setState(() {
      _validationError = null;
      _isTesting = true;
      _testResult = null;
    });

    final res = await ApiClient().testConnection(_controller.text);
    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _testResult = res;
    });
  }

  Future<void> _saveAndClose() async {
    HapticFeedback.lightImpact();
    final err = ApiClient.validateServerUrl(_controller.text);
    if (err != null) {
      setState(() {
        _validationError = err;
      });
      return;
    }

    final normalized = ApiClient.normalizeServerUrl(_controller.text);
    setState(() {
      _validationError = null;
      _isSaving = true;
    });

    await SecureStorageService().saveBaseUrl(normalized);
    if (!mounted) return;
    Navigator.pop(context, normalized);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.dns_rounded, size: 22, color: AppColors.brand700),
          SizedBox(width: 8),
          Text(
            'Pengaturan Server API',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Endpoint API Presensi Kampus:',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              onChanged: (_) {
                if (_validationError != null || _testResult != null) {
                  setState(() {
                    _validationError = null;
                    _testResult = null;
                  });
                }
              },
              decoration: InputDecoration(
                hintText: ApiConstants.defaultBaseUrl,
                errorText: _validationError,
                errorMaxLines: 2,
                prefixIcon: const Icon(Icons.cloud_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _validationError = null;
                      _testResult = null;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: (_isTesting || _isSaving) ? null : _testConnection,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.brand50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.brand300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isTesting)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand700),
                      )
                    else
                      const Icon(Icons.network_check_rounded, size: 16, color: AppColors.brand700),
                    const SizedBox(width: 6),
                    Text(
                      _isTesting ? 'Menguji Koneksi...' : 'Tes Koneksi ke Server Ini',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _testResult!['success'] == true
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _testResult!['success'] == true
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testResult!['success'] == true
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      size: 16,
                      color: _testResult!['success'] == true
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB91C1C),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _testResult!['message']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _testResult!['success'] == true
                              ? const Color(0xFF14532D)
                              : const Color(0xFF7F1D1D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'Pilihan Cepat Server:',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.cloud_done_rounded, size: 14, color: AppColors.brand600),
                  label: const Text('Cloud Production', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.brand50,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _controller.text = ApiConstants.defaultBaseUrl;
                    setState(() {
                      _validationError = null;
                      _testResult = null;
                    });
                  },
                ),
                if (kDebugMode) ...[
                  ActionChip(
                    avatar: const Icon(Icons.phone_android_rounded, size: 14, color: AppColors.accent600),
                    label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    backgroundColor: const Color(0xFFFEF3C7),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _controller.text = 'http://10.0.2.2:8000/api';
                      setState(() {
                        _validationError = null;
                        _testResult = null;
                      });
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.wifi_rounded, size: 14, color: Color(0xFF2563EB)),
                    label: const Text('Wi-Fi Laptop (192.168.1.87)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    backgroundColor: const Color(0xFFDBEAFE),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _controller.text = 'http://192.168.1.87:8000/api';
                      setState(() {
                        _validationError = null;
                        _testResult = null;
                      });
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveAndClose,
          child: const Text('Simpan & Gunakan'),
        ),
      ],
    );
  }
}

