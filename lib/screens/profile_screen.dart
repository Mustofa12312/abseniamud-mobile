import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/api_constants.dart';
import '../core/storage/secure_storage_service.dart';
import '../providers/auth_provider.dart';
import '../providers/device_security_provider.dart';
import '../widgets/device_info_card.dart';
import 'login_screen.dart';
import 'leaves_screen.dart';
import 'corrections_screen.dart';

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

  void _showChangePasswordDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Ubah Kata Sandi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPassController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi Saat Ini',
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.length < 6) return 'Minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPassController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi Baru',
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.length < 6) return 'Minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPassController,
                      obscureText: obscureNew,
                      decoration: const InputDecoration(
                        labelText: 'Konfirmasi Kata Sandi Baru',
                      ),
                      validator: (val) {
                        if (val != newPassController.text) return 'Konfirmasi kata sandi tidak cocok';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    final nav = Navigator.of(dialogCtx);
                    final messenger = ScaffoldMessenger.of(context);

                    final result = await auth.changePassword(
                      currentPassword: currentPassController.text,
                      newPassword: newPassController.text,
                    );

                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(result['message']),
                        backgroundColor: result['success'] ? AppColors.brand600 : AppColors.statusAlpha,
                      ),
                    );
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditContactDialog(BuildContext context, String? currentPhone) {
    final phoneController = TextEditingController(text: currentPhone ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Perbarui Kontak', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nomor HP / WhatsApp:', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 6),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '081234567890',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final nav = Navigator.of(dialogCtx);
                final messenger = ScaffoldMessenger.of(context);

                final result = await auth.updateContact(phone: phoneController.text.trim());

                nav.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['success'] ? AppColors.brand600 : AppColors.statusAlpha,
                  ),
                );
              },
              child: const Text('Simpan'),
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
                    _buildProfileRow(
                      'No. HP / WA',
                      user.lecturer!.phone ?? 'Belum diatur',
                      action: InkWell(
                        onTap: () => _showEditContactDialog(context, user.lecturer?.phone),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.edit_outlined, size: 16, color: AppColors.brand600),
                        ),
                      ),
                    ),
                  ] else if (user?.staffProfile != null) ...[
                    const Divider(height: 24),
                    if (user!.staffProfile!['nip'] != null)
                      _buildProfileRow('NIP / ID Tendik', user.staffProfile!['nip'].toString()),
                    if (user.staffProfile!['department'] != null)
                      _buildProfileRow('Unit / Bagian', user.staffProfile!['department'].toString()),
                    _buildProfileRow(
                      'No. HP / WA',
                      user.staffProfile!['phone']?.toString() ?? 'Belum diatur',
                      action: InkWell(
                        onTap: () => _showEditContactDialog(context, user.staffProfile!['phone']?.toString()),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.edit_outlined, size: 16, color: AppColors.brand600),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // LAYANAN AKADEMIK & PRESENSI MENU CARD
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF0FDF4),
                      child: Icon(Icons.assignment_turned_in_rounded, color: AppColors.brand700, size: 20),
                    ),
                    title: const Text('Pengajuan Izin, Sakit & Cuti', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Ajukan permohonan tidak hadir resmi', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LeavesScreen()));
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFEF3C7),
                      child: Icon(Icons.edit_calendar_rounded, color: Color(0xFFB45309), size: 20),
                    ),
                    title: const Text('Pengajuan Koreksi Presensi', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Lupa presensi atau kendala lokasi', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CorrectionsScreen()));
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF1F5F9),
                      child: Icon(Icons.lock_reset_rounded, color: AppColors.textPrimaryLight, size: 20),
                    ),
                    title: const Text('Ubah Kata Sandi', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Ganti password akun Anda secara berkala', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showChangePasswordDialog(context),
                  ),
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
                    children: const [
                      Text('Sertifikat SSL:', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight)),
                      SizedBox(width: 8),
                      Text(
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

  Widget _buildProfileRow(String label, String value, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight)),
          Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
              ?action,
            ],
          ),
        ],
      ),
    );
  }
}
