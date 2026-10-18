import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../data/models/campus_location_model.dart';
import '../providers/attendance_provider.dart';
import '../providers/device_security_provider.dart';
import '../widgets/radar_pulse_widget.dart';
import '../widgets/mock_location_warning.dart';
import '../widgets/status_badge.dart';

class AttendanceActionScreen extends StatefulWidget {
  const AttendanceActionScreen({super.key});

  @override
  State<AttendanceActionScreen> createState() => _AttendanceActionScreenState();
}

class _AttendanceActionScreenState extends State<AttendanceActionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanGps();
    });
  }

  Future<void> _scanGps() async {
    final devProvider = Provider.of<DeviceSecurityProvider>(context, listen: false);
    await devProvider.refreshLocation();
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '-';
    if (meters >= 1000) {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  void _handleAttendanceAction({required bool isCheckIn}) async {
    final devProvider = Provider.of<DeviceSecurityProvider>(context, listen: false);
    final attProvider = Provider.of<AttendanceProvider>(context, listen: false);

    // 1. HARD SECURITY CHECK: Fake GPS / Mock Location block
    if (devProvider.isMockDetected) {
      _showSecurityBlockDialog();
      return;
    }

    // 2. Location ready check
    final loc = devProvider.lastLocationResult;
    if (loc == null || !loc.isSuccess || loc.position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi GPS belum siap. Silakan klik tombol Pindai GPS.'),
          backgroundColor: AppColors.statusAlpha,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _scanGps();
      return;
    }

    // 3. Confirm dialog
    HapticFeedback.lightImpact();
    final confirmed = await _showConfirmationDialog(
      isCheckIn: isCheckIn,
      campus: devProvider.selectedCampus,
      distance: loc.distanceInMeters ?? 0,
      accuracy: loc.position!.accuracy,
      device: devProvider.deviceMetadata?.displayName ?? 'Android Device',
    );

    if (confirmed != true) return;

    HapticFeedback.mediumImpact();

    // 4. Submit to Laravel API
    Map<String, dynamic> result;
    if (isCheckIn) {
      result = await attProvider.checkIn(
        latitude: loc.position!.latitude,
        longitude: loc.position!.longitude,
        accuracy: loc.position!.accuracy,
        locationId: devProvider.selectedCampus?.id,
      );
    } else {
      result = await attProvider.checkOut(
        latitude: loc.position!.latitude,
        longitude: loc.position!.longitude,
        accuracy: loc.position!.accuracy,
      );
    }

    if (!mounted) return;

    if (result['success'] == true) {
      HapticFeedback.mediumImpact();
      _showSuccessDialog(result['message'] ?? 'Presensi berhasil dicatat!');
    } else {
      HapticFeedback.heavyImpact();
      _showErrorDialog(result['message'] ?? 'Gagal memproses presensi.');
    }
  }

  void _showSecurityBlockDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.gpp_bad_rounded, size: 54, color: AppColors.securityAlertText),
          title: const Text(
            'LOKASI PALSU TERDETEKSI',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.securityAlertText,
            ),
          ),
          content: const Text(
            'Aplikasi mendeteksi adanya penggunaan Mock Location Provider / Fake GPS pada smartphone Anda.\n\n'
            'Demi integritas data kehadiran kampus IAIMU, proses presensi diblokir.\n\n'
            'Silakan nonaktifkan Fake GPS / Mock Location di opsi pengembang, lalu coba kembali.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _scanGps();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.securityAlertText),
              child: const Text('Saya Sudah Nonaktifkan, Pindai Ulang'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showConfirmationDialog({
    required bool isCheckIn,
    CampusLocationModel? campus,
    required double distance,
    required double accuracy,
    required String device,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isCheckIn ? 'Konfirmasi Check-in Masuk' : 'Konfirmasi Check-out Pulang',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin ingin melakukan ${isCheckIn ? "Check-in" : "Check-out"} dengan data lokasi saat ini?',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Column(
                  children: [
                    _buildConfirmRow('Lokasi Kampus', campus?.name ?? 'Gedung Utama'),
                    _buildConfirmRow('Jarak ke Geofence', _formatDistance(distance)),
                    _buildConfirmRow('Akurasi GPS', '± ${accuracy.toStringAsFixed(1)} meter'),
                    _buildConfirmRow('Perangkat', device),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCheckIn ? const Color(0xFF047857) : const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isCheckIn ? 'Kirim Check-in' : 'Kirim Check-out'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight)),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.check_circle_rounded, size: 54, color: Color(0xFF047857)),
          title: const Text('Presensi Berhasil', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF047857),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.error_outline_rounded, size: 54, color: AppColors.statusAlpha),
          title: const Text('Presensi Gagal', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusAlpha,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final devProvider = Provider.of<DeviceSecurityProvider>(context);
    final attProvider = Provider.of<AttendanceProvider>(context);

    final today = attProvider.todayStatus;
    final isNotCheckedIn = today == null || today.isNotCheckedIn;
    final isCheckedIn = today != null && today.isCheckedIn;
    final isCheckedOut = today != null && today.isCheckedOut;

    final locResult = devProvider.lastLocationResult;
    final position = locResult?.position;
    final distance = locResult?.distanceInMeters;
    final isWithinGeofence = devProvider.isWithinGeofence;
    final isMock = devProvider.isMockDetected;
    final meta = devProvider.deviceMetadata;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ─── UNIFIED EMERALD HERO HEADER ───
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF042412),
                  Color(0xFF064E26),
                  Color(0xFF14532D),
                  Color(0xFF15803D),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Presensi Mandiri GPS',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Verifikasi Geofence & Koordinat Satelit',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFD1FAE5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Action: Pindai Ulang GPS Button
                        InkWell(
                          onTap: devProvider.isScanningLocation ? null : _scanGps,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                devProvider.isScanningLocation
                                    ? const SizedBox(
                                        width: 13,
                                        height: 13,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.my_location_rounded, size: 14, color: Colors.white),
                                const SizedBox(width: 5),
                                Text(
                                  devProvider.isScanningLocation ? 'Pindai...' : 'Pindai',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Integrated Campus Selector Capsule
                    if (devProvider.campusLocations.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_rounded, color: Color(0xFFA7F3D0), size: 17),
                            const SizedBox(width: 8),
                            const Text(
                              'Titik Kampus:',
                              style: TextStyle(fontSize: 12, color: Color(0xFFD1FAE5), fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<CampusLocationModel>(
                                  value: devProvider.campusLocations.firstWhere(
                                    (loc) => loc.id == devProvider.selectedCampus?.id,
                                    orElse: () => devProvider.campusLocations.first,
                                  ),
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
                                  dropdownColor: const Color(0xFF064E26),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  items: devProvider.campusLocations.map((loc) {
                                    return DropdownMenuItem<CampusLocationModel>(
                                      value: loc,
                                      child: Text(
                                        loc.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newLoc) {
                                    if (newLoc != null) {
                                      devProvider.selectCampus(newLoc);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ─── SCROLLABLE CONTENT ───
          Expanded(
            child: RefreshIndicator(
              onRefresh: _scanGps,
              color: const Color(0xFF047857),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                child: Column(
                  children: [
                    // Mock Location / GPS Error Warning Box
                    MockLocationWarning(
                      isMockDetected: isMock,
                      reason: devProvider.mockReason,
                      errorMessage: (locResult != null && !locResult.isSuccess && !isMock) ? locResult.errorMessage : null,
                      onRefresh: _scanGps,
                      onOpenSettings: () async {
                        final isPerm = (locResult?.errorMessage ?? '').toLowerCase().contains('izin');
                        if (isPerm) {
                          await devProvider.openAppSettings();
                        } else {
                          await devProvider.openLocationSettings();
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Radar Pulse Centerpiece
                    Center(
                      child: RadarPulseWidget(
                        isScanning: devProvider.isScanningLocation,
                        isMockDetected: isMock,
                        isWithinGeofence: isWithinGeofence,
                        onTap: _scanGps,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Geofence Distance Indicator Capsule
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMock
                            ? const Color(0xFFFEE2E2)
                            : isWithinGeofence
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isMock
                              ? const Color(0xFFFCA5A5)
                              : isWithinGeofence
                                  ? const Color(0xFFA7F3D0)
                                  : const Color(0xFFFDE68A),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isMock
                                ? Icons.error_rounded
                                : isWithinGeofence
                                    ? Icons.check_circle_rounded
                                    : Icons.warning_amber_rounded,
                            size: 16,
                            color: isMock
                                ? Colors.red.shade700
                                : isWithinGeofence
                                    ? const Color(0xFF047857)
                                    : const Color(0xFFB45309),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            isMock
                                ? 'Lokasi Tidak Sah (Mock Location)'
                                : isWithinGeofence
                                    ? 'Di Dalam Area Kampus (${_formatDistance(distance)})'
                                    : 'Di Luar Area Kampus (${_formatDistance(distance)})',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isMock
                                  ? Colors.red.shade800
                                  : isWithinGeofence
                                      ? const Color(0xFF047857)
                                      : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // GPS Telemetry Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.satellite_alt_rounded, size: 15, color: Color(0xFF047857)),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Telemetri GPS & Geofence',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: _scanGps,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.refresh_rounded, size: 13, color: Color(0xFF047857)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Perbarui',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF047857),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          _buildTelemetryRow(
                            'Koordinat Anda',
                            position != null
                                ? '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'
                                : 'Memindai...',
                            isMonospace: true,
                            onCopy: position != null
                                ? () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: '${position.latitude}, ${position.longitude}',
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Koordinat berhasil disalin ke clipboard!'),
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                : null,
                          ),
                          _buildTelemetryRow(
                            'Akurasi Sinyal GPS',
                            position != null ? '± ${position.accuracy.toStringAsFixed(1)} meter' : '-',
                            valueColor: position != null && position.accuracy <= 50
                                ? const Color(0xFF047857)
                                : const Color(0xFFD97706),
                          ),
                          _buildTelemetryRow(
                            'Jarak ke Titik Kampus',
                            distance != null ? _formatDistance(distance) : '-',
                            valueColor: isWithinGeofence ? const Color(0xFF047857) : const Color(0xFFDC2626),
                          ),
                          _buildTelemetryRow(
                            'Batas Radius Kampus',
                            '${devProvider.selectedCampus?.radius ?? 75.0} meter',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ACTION BUTTONS SECTION
                    if (isMock) ...[
                      // Blocked Button State
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _showSecurityBlockDialog,
                          icon: const Icon(Icons.block_rounded),
                          label: const Text(
                            'PRESENSI DIBLOKIR: Matikan Fake GPS',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ] else if (isNotCheckedIn) ...[
                      // Check-In Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: attProvider.isSubmitting
                              ? null
                              : () => _handleAttendanceAction(isCheckIn: true),
                          icon: attProvider.isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(
                            attProvider.isSubmitting ? 'Mengirim Data...' : 'CHECK-IN MASUK SEKARANG',
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF047857),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: const Color(0xFF047857).withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ] else if (isCheckedIn) ...[
                      // Today Checked-In Pod
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF047857).withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDCFCE7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF047857), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sudah Masuk: ${today.checkInAt ?? "-"} WIB',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF064E26),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Lokasi: ${today.location ?? "-"} (${_formatDistance(today.distance?.toDouble())})',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF047857),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(status: today.attendanceStatus ?? 'HADIR', fontSize: 10),
                          ],
                        ),
                      ),

                      // Check-Out Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: attProvider.isSubmitting
                              ? null
                              : () => _handleAttendanceAction(isCheckIn: false),
                          icon: attProvider.isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.logout_rounded),
                          label: Text(
                            attProvider.isSubmitting ? 'Mengirim Data...' : 'CHECK-OUT PULANG SEKARANG',
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ] else if (isCheckedOut) ...[
                      // Finished Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF047857).withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.task_alt_rounded, size: 42, color: Color(0xFF047857)),
                            const SizedBox(height: 8),
                            const Text(
                              'Presensi Hari Ini Telah Lengkap',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF064E26),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Masuk: ${today.checkInAt} WIB • Pulang: ${today.checkOutAt} WIB',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ] else if (today.isHoliday == true) ...[
                      // Holiday Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.weekend_rounded, size: 42, color: Color(0xFF64748B)),
                            SizedBox(height: 10),
                            Text(
                              'Hari Libur / Bukan Hari Kerja Wajib',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Hari ini di luar jadwal kerja wajib Anda. Presensi tidak diperlukan.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Detected device subtitle
                    if (meta != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.smartphone_rounded, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Perangkat: ${meta.displayName} • ID: ${meta.deviceFingerprint.length > 12 ? "${meta.deviceFingerprint.substring(0, 12)}..." : meta.deviceFingerprint}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isMonospace = false,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? const Color(0xFF0F172A),
                      fontFamily: isMonospace ? 'monospace' : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onCopy != null) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: onCopy,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.copy_rounded, size: 13, color: Color(0xFF047857)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
