import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/data/local/database_helper.dart';
import 'package:kitabantu/providers/auth_provider.dart';

// Warna tambahan khusus halaman ini (nuansa mint sesuai desain Stitch)
const _ink = Color(0xFF1B3A2A);
const _mint = Color(0xFFDDF3E5);
const _mintBorder = Color(0xFFD5EBDD);
const _fieldBorder = Color(0xFFD9E3DC);

/// Layar Saran & Kesan (Tab 3 — RF-003).
///
/// Formulir penilaian mata kuliah Pemrograman Aplikasi Mobile
/// beserta daftar riwayat saran yang tersimpan (Bab 6 §10).
class SaranKesanScreen extends ConsumerStatefulWidget {
  const SaranKesanScreen({super.key});

  @override
  ConsumerState<SaranKesanScreen> createState() => _SaranKesanScreenState();
}

class _SaranKesanScreenState extends ConsumerState<SaranKesanScreen> {
  static const _quickTags = [
    'Materi interaktif & aplikatif',
    'Studi kasus relevan',
    'Kolaborasi tim solid',
  ];

  final _formKey = GlobalKey<FormState>();
  final _kesanController = TextEditingController();
  final _saranController = TextEditingController();
  List<Map<String, dynamic>> _feedbackList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    final list = await DatabaseHelper.instance.getFeedbackList();
    if (mounted) {
      setState(() {
        _feedbackList = list;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _kesanController.dispose();
    _saranController.dispose();
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
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 16),
                const Text(
                  'Saran & Kesan',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: _ink),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pemrograman Aplikasi Mobile',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                _buildFormCard(),
                const SizedBox(height: 24),
                _buildHistoryHeader(),
                const SizedBox(height: 12),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_feedbackList.isEmpty)
                  _buildEmptyState()
                else
                  ..._feedbackList.map(_buildFeedbackCard),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Header ──────────────────────────────────────────
  Widget _buildTopBar() => Row( // Hapus const di sini
  children: [
    Image.asset(
      'assets/images/LogoKitaBantu.png',
      width: 32,
      height: 32,
    ),
    const SizedBox(width: 8), // Tambahkan const di sini
    Text(
      'KitaBantu',
      style: TextStyle(
        fontSize: 20, 
        fontWeight: FontWeight.w800, 
        color: _ink, // Pastikan _ink tidak error, jika error hapus const di Text ini
      ),
    ),
  ],
);
  // ───────────────────────── Kartu formulir ──────────────────────────────────
  Widget _buildFormCard() => _card(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul kartu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _mint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.rate_review_outlined,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saran & Kesan Mata Kuliah',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _ink)),
                        SizedBox(height: 4),
                        Text(
                          'Tuliskan masukan berharga, pengalaman belajar, atau refleksi Anda terkait pengembangan aplikasi KitaBantu.',
                          style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Kesan
              _label('Kesan'),
              TextFormField(
                controller: _kesanController,
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(
                    'Tuliskan kesan Anda selama mengikuti perkuliahan...'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kesan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Chip cepat: ketuk untuk menambahkan ke kolom Kesan
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickTags.map(_buildTagChip).toList(),
              ),
              const SizedBox(height: 16),

              // Saran
              _label('Saran'),
              TextFormField(
                controller: _saranController,
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(
                    'Tuliskan saran Anda untuk perbaikan ke depan...'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Saran tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tombol kirim
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Kirim',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      SizedBox(width: 8),
                      Icon(Icons.send, size: 18),
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

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF9AA8A0)),
        counterStyle:
            const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
        alignLabelWithHint: true,
        filled: true,
        fillColor: const Color(0xFFF6FBF8),
        contentPadding: const EdgeInsets.all(14),
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

  Widget _buildTagChip(String tag) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _addTag(tag),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _mint,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _mintBorder),
          ),
          child: Text('+ $tag',
              style: const TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w600, color: _ink)),
        ),
      );

  void _addTag(String tag) {
    final text = _kesanController.text.trim();
    if (text.contains(tag)) return; // hindari duplikat
    final newText = text.isEmpty
        ? tag
        : (text.endsWith('.') ? '$text $tag' : '$text. $tag');
    _kesanController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  // ───────────────────────── Riwayat ─────────────────────────────────────────
  Widget _buildHistoryHeader() => Row(
        children: [
          const Text('Riwayat Kiriman',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_feedbackList.length}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );

  Widget _buildEmptyState() => _card(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: const Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _mint,
                child: Icon(Icons.inbox_outlined,
                    size: 28, color: AppColors.primary),
              ),
              SizedBox(height: 12),
              Text('Belum ada kiriman.',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
      );

  Widget _buildFeedbackCard(Map<String, dynamic> item) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: _mint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person,
                        size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (item['student_name'] ?? '-').toString(),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _ink),
                    ),
                  ),
                  Text(
                    _formatDate(item['created_at']),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: _mintBorder),
              ),
              _feedbackSection('Kesan', item['impression']),
              const SizedBox(height: 10),
              _feedbackSection('Saran', item['suggestion']),
            ],
          ),
        ),
      );

  Widget _feedbackSection(String label, dynamic value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const SizedBox(height: 4),
          Text((value ?? '-').toString(),
              style: const TextStyle(fontSize: 13.5, height: 1.4, color: _ink)),
        ],
      );

  // ───────────────────────── Kartu putih generik ─────────────────────────────
  Widget _card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) =>
      Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _mintBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x143A6B4F),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: child,
      );

  // ───────────────────────── Logika (tidak berubah) ──────────────────────────
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider).user;
    if (user == null) return;

    await DatabaseHelper.instance.insertFeedback(
      userId: user.id!,
      studentName: user.fullName,
      impression: _kesanController.text.trim(),
      suggestion: _saranController.text.trim(),
    );

    _kesanController.clear();
    _saranController.clear();
    await _loadFeedback();

    if (!mounted) return;

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Saran & Kesan berhasil disimpan! ✓'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '-';
    }
  }
}