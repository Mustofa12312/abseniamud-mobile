import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DocumentViewerService {
  static const MethodChannel _channel = MethodChannel(
    'id.ac.iaimu.absensi/document_viewer',
  );

  static bool isImageAttachment({required String fileName, String? contentType}) {
    final mime = (contentType ?? '').split(';').first.trim().toLowerCase();
    if (mime.startsWith('image/')) return true;

    final lower = fileName.trim().toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  static String inferMimeType({required String fileName, String? contentType}) {
    final mime = (contentType ?? '').split(';').first.trim().toLowerCase();
    if (mime.isNotEmpty && mime != 'application/octet-stream') {
      return mime;
    }

    final lower = fileName.trim().toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return '*/*';
  }

  /// Writes bytes to app cache and opens them via Android FileProvider + ACTION_VIEW.
  static Future<String?> openFile({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return 'Pembukaan dokumen eksternal saat ini hanya didukung di perangkat Android.';
    }

    final mimeType = inferMimeType(fileName: fileName, contentType: contentType);
    try {
      await _channel.invokeMethod<void>('openFile', {
        'fileName': fileName,
        'bytes': bytes,
        'mimeType': mimeType,
      });
      return null;
    } on PlatformException catch (e) {
      return e.message ?? 'Tidak ada aplikasi pembuka dokumen yang tersedia.';
    } catch (e) {
      return 'Gagal membuka dokumen: ${e.toString()}';
    }
  }

  /// Opens an http/https attachment link via Android ACTION_VIEW.
  static Future<String?> openUrl(String url) async {
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || (uri.scheme.toLowerCase() != 'http' && uri.scheme.toLowerCase() != 'https')) {
      return 'Tautan dokumen tidak valid.';
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return 'Pembukaan tautan saat ini hanya didukung di perangkat Android.';
    }

    try {
      await _channel.invokeMethod<void>('openUrl', {'url': trimmed});
      return null;
    } on PlatformException catch (e) {
      return e.message ?? 'Tidak dapat membuka tautan dokumen.';
    } catch (e) {
      return 'Gagal membuka tautan: ${e.toString()}';
    }
  }
}
