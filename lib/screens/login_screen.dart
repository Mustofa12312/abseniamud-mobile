import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/api_constants.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/network/api_client.dart';
import '../providers/auth_provider.dart';
import '../providers/device_security_provider.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String _currentBaseUrl = ApiConstants.defaultBaseUrl;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();

    _emailController.addListener(() {
      if (mounted) setState(() {});
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  Future<void> _loadBaseUrl() async {
    final url = await SecureStorageService().getBaseUrl();
    if (!mounted) return;
    setState(() {
      _currentBaseUrl = url;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      HapticFeedback.mediumImpact();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: _currentBaseUrl);
    bool isTesting = false;
    Map<String, dynamic>? testResult;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
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
                      controller: controller,
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'https://api.iaimiftahululum.com/api',
                        prefixIcon: const Icon(Icons.cloud_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => controller.clear(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Test Connection Button & Result
                    InkWell(
                      onTap: isTesting
                          ? null
                          : () async {
                              HapticFeedback.selectionClick();
                              setDialogState(() {
                                isTesting = true;
                                testResult = null;
                              });
                              final res = await ApiClient().testConnection(controller.text.trim());
                              setDialogState(() {
                                isTesting = false;
                                testResult = res;
                              });
                            },
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
                            if (isTesting)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand700),
                              )
                            else
                              const Icon(Icons.network_check_rounded, size: 16, color: AppColors.brand700),
                            const SizedBox(width: 6),
                            Text(
                              isTesting ? 'Menguji Koneksi...' : 'Tes Koneksi ke Server Ini',
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

                    if (testResult != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: testResult!['success'] == true
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: testResult!['success'] == true
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              testResult!['success'] == true
                                  ? Icons.check_circle_rounded
                                  : Icons.error_rounded,
                              size: 16,
                              color: testResult!['success'] == true
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFB91C1C),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                testResult!['message']?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: testResult!['success'] == true
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
                            controller.text = ApiConstants.defaultBaseUrl;
                            setDialogState(() {
                              testResult = null;
                            });
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.phone_android_rounded, size: 14, color: AppColors.accent600),
                          label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          backgroundColor: const Color(0xFFFEF3C7),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            controller.text = 'http://10.0.2.2:8000/api';
                            setDialogState(() {
                              testResult = null;
                            });
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.wifi_rounded, size: 14, color: Color(0xFF2563EB)),
                          label: const Text('Wi-Fi Laptop (192.168.1.87)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          backgroundColor: const Color(0xFFDBEAFE),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            controller.text = 'http://192.168.1.87:8000/api';
                            setDialogState(() {
                              testResult = null;
                            });
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    final nav = Navigator.of(context);
                    final newUrl = controller.text.trim();
                    if (newUrl.isNotEmpty) {
                      await SecureStorageService().saveBaseUrl(newUrl);
                      if (mounted) {
                        setState(() {
                          _currentBaseUrl = newUrl;
                        });
                      }
                    }
                    nav.pop();
                  },
                  child: const Text('Simpan & Gunakan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAccountChip({
    required String name,
    required String role,
    required String email,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _emailController.text = email;
          _passwordController.text = 'password';
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.brand300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle_outlined, size: 14, color: AppColors.brand700),
            const SizedBox(width: 4),
            Text(
              name,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.brand800),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppColors.brand100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                role,
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.brand900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final devProvider = Provider.of<DeviceSecurityProvider>(context);
    final meta = devProvider.deviceMetadata;

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate 100
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── 1. ELEGANT EMERALD GRADIENT HEADER WITH ORBS ───
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: isKeyboardOpen ? 42 : 56,
                    bottom: 48,
                    left: 24,
                    right: 24,
                  ),
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
                  ),
                  child: Column(
                    children: [
                      // Logo Badge with Soft Outer Glow
                      Container(
                        width: 90,
                        height: 90,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.school_rounded,
                            size: 48,
                            color: AppColors.brand700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Institution Title
                      const Text(
                        'IAIMU PRESENSI',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Campus Name
                      const Text(
                        'Institut Agama Islam Miftahul Ulum Pamekasan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFBBF7D0),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Institution Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                        ),
                        child: const Text(
                          'Sistem Kehadiran Dosen & Tenaga Kependidikan',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Subtle Glowing Background Orbs
                Positioned(
                  top: -40,
                  right: -40,
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
                  bottom: -10,
                  left: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ],
            ),

            // ─── 2. FLOATING CARD CONTAINER WITH SLIDE & FADE ───
            Transform.translate(
              offset: const Offset(0, -22),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: AppColors.brand600.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Hardware Fingerprint Banner ──
                            if (meta != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.brand100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.phone_android_rounded,
                                        size: 16,
                                        color: AppColors.brand800,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            meta.displayName,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimaryLight,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'ID: ${meta.deviceFingerprint} • ${meta.isPhysicalDevice ? "Hardware Valid" : "Emulator"}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textSecondaryLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.brand500,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],

                            // Welcome Header
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Selamat Datang 👋',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimaryLight,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Masuk dengan akun terdaftar untuk presensi',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Error Banner
                            if (authProvider.errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.securityAlertBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.securityAlertBorder),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: AppColors.securityAlertText, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        authProvider.errorMessage!,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.securityAlertText,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // ── Email / Username Field ──
                            const Text(
                              'Email / Username / NIDN',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: 'ahmad@iaimu.ac.id atau admin',
                                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.brand700),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email atau username wajib diisi';
                                }
                                return null;
                              },
                            ),

                            // Real-time Gmail Warning Banner
                            if (_emailController.text.trim().toLowerCase().contains('@gmail.com')) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFB45309)),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Perhatian: Gunakan email resmi kampus (@iaimu.ac.id) atau username, bukan akun Gmail pribadi. Akun pribadi tidak terdaftar di database kampus.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF92400E),
                                          fontWeight: FontWeight.w600,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),

                            // ── Password Field ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'Kata Sandi',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: 'Masukkan kata sandi akun',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.brand700),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppColors.textSecondaryLight,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Kata sandi wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // ── Remember Me Checkbox ──
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: AppColors.brand600,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) {
                                      setState(() {
                                        _rememberMe = val ?? true;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Ingat akun di perangkat ini',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // ── Bantuan Akun & Quick Fill ──
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.vpn_key_rounded, size: 14, color: AppColors.brand700),
                                      SizedBox(width: 6),
                                      Text(
                                        'Pilih Akun Terdaftar (Klik untuk Isi Otomatis):',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _buildAccountChip(
                                          name: 'Mustofa, S.H',
                                          role: 'Dosen',
                                          email: 'mustofa@iaimu.ac.id',
                                        ),
                                        const SizedBox(width: 6),
                                        _buildAccountChip(
                                          name: 'Ahmad',
                                          role: 'Dosen',
                                          email: 'ahmad@iaimu.ac.id',
                                        ),
                                        const SizedBox(width: 6),
                                        _buildAccountChip(
                                          name: 'Super Admin',
                                          role: 'Admin',
                                          email: 'admin@iaimu.ac.id',
                                        ),
                                        const SizedBox(width: 6),
                                        _buildAccountChip(
                                          name: 'Dr. Muchlis',
                                          role: 'Tendik',
                                          email: 'muchlis@iaimu.ac.id',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Default kata sandi semua akun: "password"',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // ── Modern Gradient Login Button ──
                            Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF15803D),
                                    Color(0xFF16A34A),
                                    Color(0xFF22C55E),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.brand600.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: authProvider.status == AuthStatus.loading ? null : _handleLogin,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Center(
                                    child: authProvider.status == AuthStatus.loading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: const [
                                              Text(
                                                'Masuk ke Sistem',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // ── Security Badges Strip ──
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.brand50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.brand200),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.verified_user_rounded, size: 16, color: AppColors.brand700),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Proteksi Aktif: Deteksi Fake GPS & Hardware Fingerprint Binding',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.brand900,
                                        fontWeight: FontWeight.w600,
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
                ),
              ),
            ),

            // ─── 3. FOOTER & SERVER CONFIG ───
            Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
              child: Column(
                children: [
                  InkWell(
                    onTap: _showServerConfigDialog,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.brand500,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Server: ${_currentBaseUrl.replaceAll('https://', '').replaceAll('http://', '').replaceAll('/api', '')}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.tune_rounded, size: 13, color: AppColors.textSecondaryLight),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '© 2026 IAIMU Attendance System • Versi 1.0.0',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMutedLight,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
