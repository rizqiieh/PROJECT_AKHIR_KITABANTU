import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/data/local/database_helper.dart';
import 'package:kitabantu/providers/auth_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saran & Kesan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text(
              'Kesan & Pesan Mata Kuliah',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pemrograman Aplikasi Mobile',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),

            // ── Formulir ──
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _kesanController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Kesan',
                      hintText:
                          'Tuliskan kesan Anda selama mengikuti perkuliahan...',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Kesan tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _saranController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Saran',
                      hintText:
                          'Tuliskan saran Anda untuk perbaikan ke depan...',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Saran tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.send),
                      label: const Text('Kirim'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Riwayat Saran & Kesan ──
            Row(
              children: [
                Text(
                  'Riwayat Kiriman',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_feedbackList.length}',
                    style: const TextStyle(
                        color: AppColors.onPrimary, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_feedbackList.isEmpty)
              _buildEmptyState()
            else
              ..._feedbackList.map(_buildFeedbackCard),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppColors.textHint),
            const SizedBox(height: 8),
            Text(
              'Belum ada kiriman.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item['student_name'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  _formatDate(item['created_at']),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text('Kesan:', style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontSize: 13)),
            const SizedBox(height: 4),
            Text(item['impression'] ?? '-'),
            const SizedBox(height: 10),
            Text('Saran:', style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontSize: 13)),
            const SizedBox(height: 4),
            Text(item['suggestion'] ?? '-'),
          ],
        ),
      ),
    );
  }

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
