import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/api_constants.dart';
import '../core/storage/secure_storage_service.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/correction_provider.dart';
import '../providers/device_security_provider.dart';
import '../providers/leave_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/device_info_card.dart';
import '../widgets/server_config_dialog.dart';
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
                      final nav = Navigator.of(context);
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final attProvider = Provider.of<AttendanceProvider>(context, listen: false);
                      final schedProvider = Provider.of<ScheduleProvider>(context, listen: false);
                      final leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
                      final corrProvider = Provider.of<CorrectionProvider>(context, listen: false);
                      final devProvider = Provider.of<DeviceSecurityProvider>(context, listen: false);
                      final notifProvider = Provider.of<SmartNotificationProvider>(context, listen: false);

                      nav.pop();
                      await authProvider.logout();
                      attProvider.clear();
                      schedProvider.clear();
                      leaveProvider.clear();
                      corrProvider.clear();
                      devProvider.clearLocationState();
                      await notifProvider.clearUserData();

                      nav.pushNamedAndRemoveUntil('/login', (route) => false);
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
    showDialog<void>(
      context: context,
      builder: (_) => _ChangePasswordDialog(
        rootMessenger: ScaffoldMessenger.of(context),
      ),
    );
  }

  void _showEditContactDialog(BuildContext context, String? currentPhone) {
    showDialog<void>(
      context: context,
      builder: (_) => _EditContactDialog(
        currentPhone: currentPhone,
        rootMessenger: ScaffoldMessenger.of(context),
      ),
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

    final hasLecturerDetails = user?.lecturer != null &&
        (user!.lecturer!.nidn != null || user.lecturer!.nip != null || user.lecturer!.phone != null);
    final hasStaffDetails = user?.staffProfile != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
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
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    children: [
                      // Top Bar: Title & Status Chip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Profil & Akun',
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
                                style: TextStyle(fontSize: 11.5, color: Color(0xFFD1FAE5)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
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
                      const SizedBox(height: 22),

                      // Avatar with Glowing Ring
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF34D399)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 3.5),
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 36,
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
                              radius: 8,
                              backgroundColor: Color(0xFF10B981),
                              child: Icon(Icons.check, size: 10, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Name
                      Text(
                        user?.name ?? 'Nama Pengguna',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Email
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mail_outline_rounded, size: 14, color: Color(0xFFD1FAE5)),
                          const SizedBox(width: 5),
                          Text(
                            user?.email ?? 'email@iaimu.ac.id',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFD1FAE5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Role & Attendance Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isDosen ? Icons.school_rounded : Icons.badge_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  roleText,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF86EFAC)),
                                const SizedBox(width: 5),
                                Text(
                                  user?.attendanceType == 'daily_mandatory'
                                      ? 'Presensi Harian'
                                      : 'Presensi Jadwal',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF86EFAC),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─── ACADEMIC / CONTACT DETAILS CARD (If available) ───
            if (hasLecturerDetails || hasStaffDetails) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                      if (user?.lecturer != null) ...[
                        if (user!.lecturer!.nidn != null)
                          _buildProfileTile(
                            icon: Icons.assignment_ind_rounded,
                            label: 'NIDN Dosen',
                            value: user.lecturer!.nidn!,
                          ),
                        if (user.lecturer!.nip != null) ...[
                          const Divider(height: 16, color: Color(0xFFF1F5F9)),
                          _buildProfileTile(
                            icon: Icons.credit_card_rounded,
                            label: 'NIP',
                            value: user.lecturer!.nip!,
                          ),
                        ],
                        const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        _buildProfileTile(
                          icon: Icons.phone_android_rounded,
                          label: 'No. HP / WhatsApp',
                          value: user.lecturer!.phone ?? 'Belum diatur',
                          actionWidget: InkWell(
                            onTap: () => _showEditContactDialog(context, user.lecturer?.phone),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      ] else if (user?.staffProfile != null) ...[
                        if (user!.staffProfile!['nip'] != null)
                          _buildProfileTile(
                            icon: Icons.badge_outlined,
                            label: 'NIP / ID Tendik',
                            value: user.staffProfile!['nip'].toString(),
                          ),
                        if (user.staffProfile!['department'] != null) ...[
                          const Divider(height: 16, color: Color(0xFFF1F5F9)),
                          _buildProfileTile(
                            icon: Icons.business_rounded,
                            label: 'Unit / Bagian',
                            value: user.staffProfile!['department'].toString(),
                          ),
                        ],
                        const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        _buildProfileTile(
                          icon: Icons.phone_android_rounded,
                          label: 'No. HP / WhatsApp',
                          value: user.staffProfile!['phone']?.toString() ?? 'Belum diatur',
                          actionWidget: InkWell(
                            onTap: () => _showEditContactDialog(context, user.staffProfile!['phone']?.toString()),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ─── LAYANAN MANDIRI CARD ───
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

            // ─── DEVICE DETECTION & HARDWARE INFO CARD ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DeviceInfoCard(metadata: meta),
            ),

            const SizedBox(height: 20),

            // ─── SERVER CONNECTION & TLS STATUS CARD ───
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _ServerConnectionCard(),
            ),

            const SizedBox(height: 24),

            // ─── LOGOUT BUTTON ───
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

class _ChangePasswordDialog extends StatefulWidget {
  final ScaffoldMessengerState rootMessenger;

  const _ChangePasswordDialog({required this.rootMessenger});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _isSubmitting = false;
  String? _inlineError;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.changePassword(
      currentPassword: _currentPassController.text,
      newPassword: _newPassController.text,
    );

    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pop(context);
      widget.rootMessenger.showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Kata sandi berhasil diubah.'),
          backgroundColor: AppColors.brand600,
        ),
      );
    } else {
      setState(() {
        _isSubmitting = false;
        _inlineError = result['message']?.toString() ?? 'Gagal mengubah kata sandi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Ubah Kata Sandi',
        style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_inlineError != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.securityAlertBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.securityAlertBorder),
                  ),
                  child: Text(
                    _inlineError!,
                    style: const TextStyle(fontSize: 12, color: AppColors.securityAlertText, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              TextFormField(
                controller: _currentPassController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi Saat Ini',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.length < 6) return 'Minimal 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPassController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi Baru',
                  prefixIcon: const Icon(Icons.key_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.length < 6) return 'Minimal 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPassController,
                obscureText: _obscureNew,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Kata Sandi Baru',
                  prefixIcon: Icon(Icons.check_circle_outline_rounded, size: 20),
                ),
                validator: (val) {
                  if (val != _newPassController.text) return 'Konfirmasi kata sandi tidak cocok';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand600,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditContactDialog extends StatefulWidget {
  final String? currentPhone;
  final ScaffoldMessengerState rootMessenger;

  const _EditContactDialog({
    required this.currentPhone,
    required this.rootMessenger,
  });

  @override
  State<_EditContactDialog> createState() => _EditContactDialogState();
}

class _EditContactDialogState extends State<_EditContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  bool _isSubmitting = false;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.currentPhone ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.updateContact(phone: _phoneController.text.trim());

    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pop(context);
      widget.rootMessenger.showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Kontak berhasil diperbarui.'),
          backgroundColor: AppColors.brand600,
        ),
      );
    } else {
      setState(() {
        _isSubmitting = false;
        _inlineError = result['message']?.toString() ?? 'Gagal memperbarui kontak.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Perbarui Kontak', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_inlineError != null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.securityAlertBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.securityAlertBorder),
                ),
                child: Text(
                  _inlineError!,
                  style: const TextStyle(fontSize: 12, color: AppColors.securityAlertText, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const Text('Nomor HP / WhatsApp Aktif:', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '081234567890',
                prefixIcon: Icon(Icons.phone_rounded, size: 20),
              ),
              validator: (val) {
                final trimmed = val?.trim() ?? '';
                if (trimmed.isNotEmpty && trimmed.length < 8) {
                  return 'Nomor HP minimal 8 digit';
                }
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
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand600,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ServerConnectionCard extends StatefulWidget {
  const _ServerConnectionCard();

  @override
  State<_ServerConnectionCard> createState() => _ServerConnectionCardState();
}

class _ServerConnectionCardState extends State<_ServerConnectionCard> {
  String _currentUrl = ApiConstants.defaultBaseUrl;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final url = await SecureStorageService().getBaseUrl();
    if (!mounted) return;
    setState(() {
      _currentUrl = url;
    });
  }

  Future<void> _openConfig() async {
    final messenger = ScaffoldMessenger.of(context);
    final updatedUrl = await ServerConfigDialog.show(context, initialUrl: _currentUrl);
    if (updatedUrl != null && mounted) {
      setState(() {
        _currentUrl = updatedUrl;
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Endpoint server berhasil diperbarui.'),
          backgroundColor: AppColors.brand600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHttps = _currentUrl.toLowerCase().startsWith('https://');
    return Container(
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
                  color: isHttps ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 3,
                      backgroundColor: isHttps ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isHttps ? 'TLS' : 'Lokal',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isHttps ? const Color(0xFF15803D) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              const Text('Endpoint:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentUrl,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: _openConfig,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Transport:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(width: 6),
              Icon(
                isHttps ? Icons.lock_rounded : Icons.lock_open_rounded,
                size: 13,
                color: isHttps ? const Color(0xFF16A34A) : const Color(0xFFD97706),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isHttps ? 'HTTPS Terenkripsi TLS' : 'HTTP Non-TLS (Khusus Pengembangan Lokal)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isHttps ? const Color(0xFF166534) : const Color(0xFFB45309),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
