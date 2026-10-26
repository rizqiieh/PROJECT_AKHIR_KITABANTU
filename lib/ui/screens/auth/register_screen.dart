import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/providers/auth_provider.dart';
import 'package:kitabantu/ui/screens/home/main_shell.dart';
import 'login_screen.dart';

// Warna tambahan khusus halaman ini (nuansa mint sesuai desain Stitch)
const _ink = Color(0xFF1B3A2A);
const _mint = Color(0xFFDDF3E5);
const _mintBorder = Color(0xFFD5EBDD);
const _fieldBorder = Color(0xFFD9E3DC);

/// Halaman Registrasi (Bab 6 §3 — RF-001).
///
/// Input: nama lengkap, username, password, konfirmasi password.
/// Password di-hash SHA-256 + salt sebelum disimpan ke SQLite.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Ubah angka ini kalau ingin minimal password 8 karakter seperti di desain.
  static const int _minPassword = 6;

  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreed = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────── BUILD ───────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4FDF7), Color(0xFFE2F5E9)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 16),
                _buildBadge(),
                const SizedBox(height: 12),
                const Text(
                  'Daftar Akun Baru',
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, color: _ink),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Bergabung bersama komunitas donatur & amil terpercaya',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                _buildFormCard(),
                const SizedBox(height: 14),
                _buildSecurityInfo(),
                const SizedBox(height: 20),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Bagian atas ─────────────────────────────────────
  Widget _buildTopBar() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _goToLogin,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 18, color: _ink),
                  SizedBox(width: 6),
                  Text('Kembali ke Masuk',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _ink)),
                ],
              ),
            ),
          ),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.volunteer_activism,
                  color: AppColors.primary, size: 24),
              SizedBox(width: 6),
              Text('KitaBantu',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _ink)),
            ],
          ),
        ],
      );

  Widget _buildBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _mint,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _mintBorder),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user, size: 14, color: AppColors.primary),
            SizedBox(width: 6),
            Text('Pendaftaran Amanah',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: _ink)),
          ],
        ),
      );

  // ───────────────────────── Kartu formulir ──────────────────────────────────
  Widget _buildFormCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _mintBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x143A6B4F),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nama lengkap
              _label('Nama Lengkap'),
              TextFormField(
                controller: _fullNameCtrl,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration(
                    hint: 'Nama sesuai identitas',
                    icon: Icons.person_outline),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nama lengkap tidak boleh kosong';
                  }
                  if (v.trim().length < 3) {
                    return 'Nama minimal 3 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Username
              _label('Username'),
              TextFormField(
                controller: _usernameCtrl,
                textInputAction: TextInputAction.next,
                decoration: _decoration(
                    hint: 'Pilih username unik', icon: Icons.alternate_email),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Username tidak boleh kosong';
                  }
                  if (v.trim().length < 3) {
                    return 'Username minimal 3 karakter';
                  }
                  if (v.contains(' ')) {
                    return 'Username tidak boleh mengandung spasi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password + indikator kekuatan
              _label('Password'),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}), // refresh meter kekuatan
                decoration: _decoration(
                  hint: 'Buat kata sandi aman',
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  if (v.length < _minPassword) {
                    return 'Password minimal $_minPassword karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _buildStrengthMeter(),
              const SizedBox(height: 16),

              // Konfirmasi password
              _label('Konfirmasi Password'),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                decoration: _decoration(
                  hint: 'Ulangi kata sandi Anda',
                  icon: Icons.lock_reset,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Konfirmasi password tidak boleh kosong';
                  }
                  if (v != _passwordCtrl.text) {
                    return 'Password tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Persetujuan syarat & ketentuan
              _buildAgreement(),
              const SizedBox(height: 16),

              // Tombol daftar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Daftar',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            SizedBox(width: 8),
                            Icon(Icons.person_add_alt_1, size: 18),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
      );

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9AA8A0)),
        prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        border: _border(_fieldBorder),
        enabledBorder: _border(_fieldBorder),
        focusedBorder: _border(AppColors.primary),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error),
      );

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color),
      );

  // ───────────────────────── Indikator kekuatan password ─────────────────────
  int _strengthLevel(String p) {
    if (p.isEmpty) return 0;
    if (p.length < _minPassword) return 1; // Lemah
    final mixedCase = RegExp(r'[a-z]').hasMatch(p) && RegExp(r'[A-Z]').hasMatch(p);
    final hasDigit = RegExp(r'\d').hasMatch(p);
    final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(p);
    final variety = [mixedCase, hasDigit, hasSymbol].where((e) => e).length;
    return variety >= 2 ? 3 : 2; // Kuat : Sedang
  }

  Widget _buildStrengthMeter() {
    final p = _passwordCtrl.text;
    final level = _strengthLevel(p);
    final okLength = p.length >= _minPassword;
    final labels = ['', 'Lemah', 'Sedang', 'Kuat'];
    final colors = [
      Colors.transparent,
      AppColors.error,
      const Color(0xFFF2A900),
      AppColors.primary,
    ];

    return Column(
      children: [
        Row(
          children: [
            Icon(
              okLength ? Icons.check_circle : Icons.circle_outlined,
              size: 14,
              color: okLength ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text('Minimal $_minPassword karakter',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.onSurfaceVariant)),
            const Spacer(),
            Text(labels[level],
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors[level])),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                height: 5,
                decoration: BoxDecoration(
                  color: i < level ? colors[level] : _mintBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Persetujuan ─────────────────────────────────────
  Widget _buildAgreement() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _agreed,
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5)),
              onChanged: (v) => setState(() => _agreed = v ?? false),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _agreed = !_agreed),
              child: const Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 12, color: _ink, height: 1.4),
                  children: [
                    TextSpan(text: 'Saya menyetujui '),
                    TextSpan(
                      text: 'Syarat, Ketentuan & Kebijakan Privasi',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(text: ' KitaBantu'),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  // ───────────────────────── Info keamanan & footer ──────────────────────────
  Widget _buildSecurityInfo() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _mint.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _mintBorder),
        ),
        child: const Row(
          children: [
            Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text('Akun Anda diverifikasi secara aman & transparan',
                  style: TextStyle(fontSize: 12, color: _ink)),
            ),
          ],
        ),
      );

  Widget _buildFooter() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Sudah punya akun? ',
              style: TextStyle(
                  fontSize: 13, color: AppColors.onSurfaceVariant)),
          GestureDetector(
            onTap: _goToLogin,
            child: const Text('Masuk Sekarang',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _ink)),
          ),
        ],
      );

  // ───────────────────────── Logika ──────────────────────────────────────────
  void _goToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Setujui Syarat, Ketentuan & Kebijakan Privasi terlebih dahulu'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await ref.read(authProvider.notifier).register(
          fullName: _fullNameCtrl.text.trim(),
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      // Registrasi berhasil → langsung masuk ke MainShell
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    }
  }
}