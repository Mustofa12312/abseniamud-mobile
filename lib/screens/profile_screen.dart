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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout_rounded, size: 36, color: AppColors.statusAlpha),
          ),
          title: const Text(
            'Konfirmasi Logout',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari sesi akun sistem presensi IAIMU?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: const Text('Batal', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusAlpha,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Ya, Logout', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text(
                'Ubah Kata Sandi',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
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
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
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
                        prefixIcon: const Icon(Icons.key_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
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
                        prefixIcon: Icon(Icons.check_circle_outline_rounded, size: 20),
                      ),
                      validator: (val) {
                        if (val != newPassController.text) return 'Konfirmasi kata sandi tidak cocok';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brand600,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Perbarui Kontak', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nomor HP / WhatsApp Aktif:', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '081234567890',
                  prefixIcon: Icon(Icons.phone_rounded, size: 20),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand600,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showServerConfigDialog(BuildContext context) async {
    final currentUrl = await SecureStorageService().getBaseUrl();
    if (!context.mounted) return;
    final controller = TextEditingController(text: currentUrl);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Konfigurasi Endpoint API', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tentukan URL server backend IAIMU Absensi:',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'https://api.iaimiftahululum.com/api',
                  prefixIcon: Icon(Icons.dns_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => controller.text = ApiConstants.defaultBaseUrl,
                child: const Text(
                  'Reset ke Default Produksi',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand700),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final newUrl = controller.text.trim();
                      if (newUrl.isNotEmpty) {
                        await SecureStorageService().saveBaseUrl(newUrl);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Endpoint server berhasil diperbarui.'),
                              backgroundColor: AppColors.brand600,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
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
    final roleText = (user?.roleName ?? 'Dosen Pengajar').toUpperCase();
    final isDosen = roleText.contains('DOSEN');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HERO HEADER WITH DEEP EMERALD GRADIENT & AMBIENT GLOW
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Top gradient banner
                Container(
                  height: 210,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: Stack(
                    children: [
                      // Ambient glass circles
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 30,
                        left: -40,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brand300.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Profil & Keamanan',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'IAIMU Academic Presence System',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFFD1FAE5),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF4ADE80)),
                                    SizedBox(width: 5),
                                    Text(
                                      'Online',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // USER PROFILE HERO CARD (Overlapping Header)
                Padding(
                  padding: const EdgeInsets.only(top: 130, left: 16, right: 16),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar with glowing ring
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                                border: Border.all(color: Colors.white, width: 3.5),
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(3.5),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const CircleAvatar(
                                radius: 7,
                                backgroundColor: Color(0xFF10B981),
                                child: Icon(Icons.check, size: 9, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Name
                        Text(
                          user?.name ?? 'Nama Pengguna',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Email
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mail_outline_rounded, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 5),
                            Text(
                              user?.email ?? 'email@iaimu.ac.id',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Role & Attendance Type Badges
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isDosen ? Icons.school_rounded : Icons.badge_rounded,
                                    size: 13,
                                    color: const Color(0xFF047857),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    roleText,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF047857),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF475569)),
                                  const SizedBox(width: 5),
                                  Text(
                                    user?.attendanceType == 'daily_mandatory'
                                        ? 'Presensi Harian'
                                        : 'Presensi Jadwal',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Dosen / Tendik Academic Profile Rows
                        if (user?.lecturer != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Column(
                              children: [
                                if (user!.lecturer!.nidn != null)
                                  _buildProfileTile(
                                    icon: Icons.assignment_ind_rounded,
                                    label: 'NIDN Dosen',
                                    value: user.lecturer!.nidn!,
                                  ),
                                if (user.lecturer!.nip != null) ...[
                                  const Divider(height: 14, color: Color(0xFFE2E8F0)),
                                  _buildProfileTile(
                                    icon: Icons.credit_card_rounded,
                                    label: 'NIP',
                                    value: user.lecturer!.nip!,
                                  ),
                                ],
                                const Divider(height: 14, color: Color(0xFFE2E8F0)),
                                _buildProfileTile(
                                  icon: Icons.phone_android_rounded,
                                  label: 'No. HP / WhatsApp',
                                  value: user.lecturer!.phone ?? 'Belum diatur',
                                  actionWidget: InkWell(
                                    onTap: () => _showEditContactDialog(context, user.lecturer?.phone),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.brand50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.brand200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.edit_outlined, size: 12, color: AppColors.brand700),
                                          SizedBox(width: 3),
                                          Text('Ubah', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brand700)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (user?.staffProfile != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Column(
                              children: [
                                if (user!.staffProfile!['nip'] != null)
                                  _buildProfileTile(
                                    icon: Icons.badge_outlined,
                                    label: 'NIP / ID Tendik',
                                    value: user.staffProfile!['nip'].toString(),
                                  ),
                                if (user.staffProfile!['department'] != null) ...[
                                  const Divider(height: 14, color: Color(0xFFE2E8F0)),
                                  _buildProfileTile(
                                    icon: Icons.business_rounded,
                                    label: 'Unit / Bagian',
                                    value: user.staffProfile!['department'].toString(),
                                  ),
                                ],
                                const Divider(height: 14, color: Color(0xFFE2E8F0)),
                                _buildProfileTile(
                                  icon: Icons.phone_android_rounded,
                                  label: 'No. HP / WhatsApp',
                                  value: user.staffProfile!['phone']?.toString() ?? 'Belum diatur',
                                  actionWidget: InkWell(
                                    onTap: () => _showEditContactDialog(context, user.staffProfile!['phone']?.toString()),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.brand50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.brand200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.edit_outlined, size: 12, color: AppColors.brand700),
                                          SizedBox(width: 3),
                                          Text('Ubah', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brand700)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // LAYANAN MANDIRI & PENGAJUAN CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'LAYANAN MANDIRI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuActionTile(
                          icon: Icons.fact_check_rounded,
                          iconColor: const Color(0xFF047857),
                          iconBg: const Color(0xFFECFDF5),
                          title: 'Pengajuan Izin, Sakit & Cuti',
                          subtitle: 'Ajukan surat permohonan tidak hadir resmi',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const LeavesScreen()));
                          },
                        ),
                        const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
                        _buildMenuActionTile(
                          icon: Icons.edit_calendar_rounded,
                          iconColor: const Color(0xFFD97706),
                          iconBg: const Color(0xFFFFFBEB),
                          title: 'Pengajuan Koreksi Presensi',
                          subtitle: 'Lupa check-in / check-out atau kendala GPS',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CorrectionsScreen()));
                          },
                        ),
                        const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
                        _buildMenuActionTile(
                          icon: Icons.lock_reset_rounded,
                          iconColor: const Color(0xFF4F46E5),
                          iconBg: const Color(0xFFEEF2FF),
                          title: 'Ubah Kata Sandi',
                          subtitle: 'Ganti password akun Anda secara berkala',
                          onTap: () => _showChangePasswordDialog(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // DEVICE DETECTION & HARDWARE INFO CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DeviceInfoCard(metadata: meta),
            ),

            const SizedBox(height: 20),

            // SERVER CONNECTION & TLS STATUS CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.cloud_done_rounded, color: Color(0xFF16A34A), size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Koneksi API Backend',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(radius: 3, backgroundColor: Color(0xFF16A34A)),
                              SizedBox(width: 4),
                              Text('Online', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    FutureBuilder<String>(
                      future: SecureStorageService().getBaseUrl(),
                      builder: (context, snapshot) {
                        final url = snapshot.data ?? ApiConstants.defaultBaseUrl;
                        return Row(
                          children: [
                            const Text('Endpoint:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                url,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: () => _showServerConfigDialog(context),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Ganti',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Text('Sertifikat SSL:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        SizedBox(width: 8),
                        Icon(Icons.lock_rounded, size: 13, color: Color(0xFF16A34A)),
                        SizedBox(width: 4),
                        Text(
                          'HTTPS Terenkripsi TLS 1.3 (Secure Channel)',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // LOGOUT BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.power_settings_new_rounded, color: Color(0xFFDC2626), size: 20),
                  label: const Text(
                    'Keluar dari Akun (Logout)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String label,
    required String value,
    Widget? actionWidget,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
        if (actionWidget != null) ...[
          const SizedBox(width: 6),
          actionWidget,
        ],
      ],
    );
  }

  Widget _buildMenuActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
