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
          content: Text('Lokasi GPS belum siap. Silakan klik tombol Segarkan GPS.'),
          backgroundColor: AppColors.statusAlpha,
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                  color: AppColors.brand50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.brand200),
                ),
                child: Column(
                  children: [
                    _buildConfirmRow('Lokasi Kampus', campus?.name ?? 'Gedung Utama'),
                    _buildConfirmRow('Jarak ke Geofence', '${distance.toStringAsFixed(0)} meter'),
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
                backgroundColor: isCheckIn ? AppColors.brand600 : const Color(0xFF1E293B),
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
          icon: const Icon(Icons.check_circle_rounded, size: 54, color: AppColors.brand600),
          title: const Text('Presensi Berhasil', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
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
          title: const Text('Presensi Gagal', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusAlpha),
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Presensi Mandiri GPS',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: devProvider.isScanningLocation ? null : _scanGps,
            icon: devProvider.isScanningLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            tooltip: 'Pindai Lokasi GPS',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Campus Building Selector
            if (devProvider.campusLocations.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_rounded, color: AppColors.brand700, size: 20),
                    const SizedBox(width: 10),
                    const Text('Lokasi Kampus:', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CampusLocationModel>(
                          value: devProvider.campusLocations.firstWhere(
                            (loc) => loc.id == devProvider.selectedCampus?.id,
                            orElse: () => devProvider.campusLocations.first,
                          ),
                          isExpanded: true,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
                          items: devProvider.campusLocations.map((loc) {
                            return DropdownMenuItem<CampusLocationModel>(
                              value: loc,
                              child: Text(loc.name, overflow: TextOverflow.ellipsis),
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
              const SizedBox(height: 16),
            ],

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

            // Radar Pulse Widget (Centerpiece animation)
            Center(
              child: RadarPulseWidget(
                isScanning: devProvider.isScanningLocation,
                isMockDetected: isMock,
                isWithinGeofence: isWithinGeofence,
                onTap: _scanGps,
              ),
            ),
            const SizedBox(height: 16),

            // Geofence Distance Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isMock
                    ? const Color(0xFFFEE2E2)
                    : isWithinGeofence
                        ? AppColors.brand100
                        : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
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
                        ? Colors.red
                        : isWithinGeofence
                            ? AppColors.brand800
                            : const Color(0xFFB45309),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isMock
                        ? 'Lokasi Tidak Sah (Mock Location)'
                        : isWithinGeofence
                            ? 'Di Dalam Area Kampus (${distance?.toStringAsFixed(0) ?? 0}m)'
                            : 'Di Luar Area Kampus (${distance?.toStringAsFixed(0) ?? 0}m)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isMock
                          ? Colors.red
                          : isWithinGeofence
                              ? AppColors.brand900
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
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Telemetri GPS & Geofence',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
                      ),
                      InkWell(
                        onTap: _scanGps,
                        child: Row(
                          children: const [
                            Icon(Icons.refresh_rounded, size: 14, color: AppColors.brand600),
                            SizedBox(width: 4),
                            Text('Perbarui', style: TextStyle(fontSize: 11.5, color: AppColors.brand600, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const Divider(height: 20),
                  _buildTelemetryRow(
                    'Koordinat Anda',
                    position != null
                        ? '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'
                        : 'Memindai...',
                    isMonospace: true,
                  ),
                  _buildTelemetryRow(
                    'Akurasi Sinyal GPS',
                    position != null ? '± ${position.accuracy.toStringAsFixed(1)} meter' : '-',
                    valueColor: position != null && position.accuracy <= 50 ? AppColors.brand700 : AppColors.statusTerlambat,
                  ),
                  _buildTelemetryRow(
                    'Jarak ke Titik Kampus',
                    distance != null ? '${distance.toStringAsFixed(1)} meter' : '-',
                    valueColor: isWithinGeofence ? AppColors.brand700 : AppColors.statusAlpha,
                  ),
                  _buildTelemetryRow(
                    'Batas Radius Kampus',
                    '${devProvider.selectedCampus?.radius ?? 75.0} meter',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ACTION BUTTONS SECTION
            if (isMock) ...[
              // Blocked Button State
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _showSecurityBlockDialog,
                  icon: const Icon(Icons.block_rounded),
                  label: const Text('PRESENSI DIBLOKIR: Matikan Fake GPS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
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
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand600,
                  ),
                ),
              ),
            ] else if (isCheckedIn) ...[
              // Check-Out Button
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brand50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.brand200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.brand700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sudah Masuk: ${today.checkInAt ?? "-"} WIB',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brand900),
                          ),
                          Text(
                            'Lokasi: ${today.location ?? "-"} (${today.distance ?? 0}m)',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.brand800),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: today.attendanceStatus ?? 'HADIR', fontSize: 10),
                  ],
                ),
              ),
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
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ] else if (isCheckedOut) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.brand50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.brand200),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.task_alt_rounded, size: 40, color: AppColors.brand700),
                    const SizedBox(height: 8),
                    const Text(
                      'Presensi Hari Ini Telah Lengkap',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.brand900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Masuk: ${today.checkInAt} • Pulang: ${today.checkOutAt}',
                      style: const TextStyle(fontSize: 13, color: AppColors.brand800),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Detected device subtitle
            if (meta != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.smartphone_rounded, size: 14, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 6),
                  Text(
                    'Perangkat: ${meta.displayName} • ID: ${meta.deviceFingerprint}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryRow(String label, String value, {Color? valueColor, bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimaryLight,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }
}
