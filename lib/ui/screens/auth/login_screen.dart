import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/providers/auth_provider.dart';
import 'package:kitabantu/ui/screens/auth/register_screen.dart';
import 'package:kitabantu/ui/screens/home/main_shell.dart';

/// Halaman Login & Biometrik dengan Desain Stitch AI (Sage Green).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _canBiometric = false;
  bool _hasBiometricSession = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final notifier = ref.read(authProvider.notifier);
    final canUse = await notifier.canUseBiometric();
    final storage = await notifier.canUseBiometric();
    if (mounted) {
      setState(() {
        _canBiometric = canUse;
        _hasBiometricSession = storage;
      });
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF26533C);
    const bgSage = Color(0xFFEAF5EE);

    return Scaffold(
      backgroundColor: bgSage,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo Header ──
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_rounded,
                        color: primaryGreen,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── App Title & Tagline ──
                const Text(
                  'KitaBantu',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B3B2B),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Menghubungkan Kebaikan & Menyalurkan\nZakat Berkah',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Color(0xFF4A5568),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Card Formulir Putih ──
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label Email / Username
                        const Text(
                          'Email atau Username',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameCtrl,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'contoh: ahmad@email.com',
                            hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 13),
                            prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20, color: Color(0xFF718096)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Username tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 16),

                        // Label Password
                        const Text(
                          'Kata Sandi',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'Masukkan kata sandi',
                            hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 13),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF718096)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: 20,
                                color: const Color(0xFF718096),
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Password tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 10),

                        // Ingat Saya & Lupa Kata Sandi
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: primaryGreen,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    side: const BorderSide(color: Color(0xFFCBD5E0), width: 1.2),
                                    onChanged: (val) => setState(() => _rememberMe = val ?? false),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Ingat Saya',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF4A5568)),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Lupa Kata Sandi?',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Tombol Masuk
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Masuk',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),

                        // Pembatas / Teks Opsi Biometrik
                        const SizedBox(height: 16),
                        Row(
                          children: const [
                            Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 0.8)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'atau masuk lebih cepat',
                                style: TextStyle(fontSize: 11, color: Color(0xFF718096)),
                              ),
                            ),
                            Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 0.8)),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Tombol Biometrik
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _handleBiometricLogin,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.fingerprint_rounded, color: Color(0xFF4A5568), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Masuk dengan Biometrik',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // ── Tautan Registrasi ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Belum memiliki akun? ',
                      style: TextStyle(fontSize: 13, color: Color(0xFF4A5568)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text(
                        'Daftar Akun Baru',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Footer Proteksi Keamanan ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF718096)),
                    SizedBox(width: 6),
                    Text(
                      'Dilindungi enkripsi end-to-end',
                      style: TextStyle(fontSize: 11, color: Color(0xFF718096)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Login dengan username + password.
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await ref.read(authProvider.notifier).login(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error != null) {
      _showSnackBar(error, isError: true);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  /// Login dengan biometrik.
  Future<void> _handleBiometricLogin() async {
    setState(() => _isLoading = true);

    final error = await ref.read(authProvider.notifier).loginWithBiometric();

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error != null) {
      _showSnackBar(error, isError: true);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}