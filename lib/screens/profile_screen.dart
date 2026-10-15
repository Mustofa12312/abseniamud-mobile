import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/api_constants.dart';
import '../core/storage/secure_storage_service.dart';
import '../providers/auth_provider.dart';
import '../providers/device_security_provider.dart';
import '../widgets/device_info_card.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.logout_rounded, size: 48, color: AppColors.statusAlpha),
          title: const Text('Konfirmasi Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun sistem presensi IAIMU?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusAlpha),
              child: const Text('Ya, Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final devProvider = Provider.of<DeviceSecurityProvider>(context);
    final user = authProvider.currentUser;
    final meta = devProvider.deviceMetadata;

    final initial = (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Profil & Keamanan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Avatar with Initials
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand600.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    user?.name ?? 'Nama Pengguna',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'email@iaimu.ac.id',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brand50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.brand200),
                    ),
                    child: Text(
                      (user?.roleName ?? 'Dosen Pengajar').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // Lecturer extra details if available
                  if (user?.lecturer != null) ...[
                    const Divider(height: 24),
                    if (user!.lecturer!.nidn != null)
                      _buildProfileRow('NIDN', user.lecturer!.nidn!),
                    if (user.lecturer!.nip != null)
                      _buildProfileRow('NIP', user.lecturer!.nip!),
                    if (user.lecturer!.phone != null)
                      _buildProfileRow('No. HP / WhatsApp', user.lecturer!.phone!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // DEVICE DETECTION & HARDWARE INFO CARD
            DeviceInfoCard(metadata: meta),
            const SizedBox(height: 20),

            // Server & Network Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.cloud_done_rounded, color: AppColors.brand600, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Koneksi API Backend',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      Spacer(),
                      Text(
                        'Online',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brand700),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  FutureBuilder<String>(
                    future: SecureStorageService().getBaseUrl(),
                    builder: (context, snapshot) {
                      final url = snapshot.data ?? ApiConstants.defaultBaseUrl;
                      return Row(
                        children: [
                          const Text('Endpoint:', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              url,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brand900,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('Sertifikat SSL:', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight)),
                      const SizedBox(width: 8),
                      const Text(
                        'HTTPS Terenkripsi TLS 1.3',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout_rounded, color: AppColors.statusAlpha),
                label: const Text(
                  'Keluar dari Akun (Logout)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusAlpha,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.securityAlertBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight)),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
        ],
      ),
    );
  }
}
