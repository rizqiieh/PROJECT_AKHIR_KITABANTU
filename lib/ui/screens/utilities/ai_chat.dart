import 'package:flutter/material.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/data/remote/gemini_ai_service.dart';

const String _welcomeMessage =
    'Assalamu\'alaikum! Saya Pakar Fiqih Zakat dan Filantropi Islam KitaBantu. '
    'Silakan tanyakan studi kasus keuangan Anda—seperti analisis gaji/penghasilan, '
    'emas, tabungan, saham, kaitan pajak dan zakat, atau kriteria penerima (asnaf).';

/// Riwayat percakapan disimpan di level modul supaya tidak hilang saat sheet
/// ditutup. Isinya baru kosong lagi kalau aplikasi di-restart atau pengguna
/// menekan tombol "Mulai ulang".
final List<Map<String, String>> _chatHistory = [
  {'role': 'ai', 'text': _welcomeMessage},
];

/// Membuka Asisten AI Zakat sebagai bottom sheet (dipanggil dari tombol
/// mengambang di Beranda).
Future<void> showAiZakatChatSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AiZakatChatSheet(),
  );
}

class AiZakatChatSheet extends StatefulWidget {
  const AiZakatChatSheet({super.key});

  @override
  State<AiZakatChatSheet> createState() => _AiZakatChatSheetState();
}

class _AiZakatChatSheetState extends State<AiZakatChatSheet> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isAiThinking = false;

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _resetChat() {
    if (_isAiThinking) return;
    setState(() {
      _chatHistory
        ..clear()
        ..add({'role': 'ai', 'text': _welcomeMessage});
    });
  }

  Future<void> _sendMessage(String question) async {
    final q = question.trim();
    if (q.isEmpty || _isAiThinking) return;

    final history = List<Map<String, String>>.from(_chatHistory);

    setState(() {
      _chatHistory.add({'role': 'user', 'text': q});
      _inputCtrl.clear();
      _isAiThinking = true;
    });
    _scrollToBottom();

    final answer = await GeminiAiService.instance.askZakatQuestion(
      q,
      history: history,
    );

    // Simpan jawaban ke riwayat walau sheet sempat ditutup.
    _chatHistory.add({'role': 'ai', 'text': answer});

    if (!mounted) return;
    setState(() => _isAiThinking = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Padding(
      // Naik mengikuti keyboard.
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        height: media.size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildQuickChips(),
            Expanded(child: _buildMessageList(context)),
            if (_isAiThinking) _buildThinkingIndicator(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asisten AI Zakat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'Pakar Fiqih Zakat & Filantropi Islam',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Mulai ulang percakapan',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _isAiThinking ? null : _resetChat,
              ),
              IconButton(
                tooltip: 'Tutup',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  // ── Chip topik cepat ──
  Widget _buildQuickChips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.surfaceVariant.withValues(alpha: 0.5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _quickChip('Gaji 12 juta sebulan, berapa zakatnya?'),
            _quickChip('Punya emas 100 gram, wajib zakat?'),
            _quickChip('Sudah bayar pajak, masih wajib zakat?'),
            _quickChip('Bolehkah zakat untuk saudara kandung?'),
            _quickChip('Siapa saja 8 asnaf penerima?'),
          ],
        ),
      ),
    );
  }

  Widget _quickChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 11)),
        onPressed: () => _sendMessage(text),
      ),
    );
  }

  // ── Daftar pesan ──
  Widget _buildMessageList(BuildContext context) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      itemCount: _chatHistory.length,
      itemBuilder: (ctx, idx) {
        final msg = _chatHistory[idx];
        final isUser = msg['role'] == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : AppColors.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft:
                    isUser ? const Radius.circular(16) : const Radius.circular(2),
                bottomRight:
                    isUser ? const Radius.circular(2) : const Radius.circular(16),
              ),
            ),
            child: SelectableText(
              msg['text'] ?? '',
              style: TextStyle(
                color: isUser ? Colors.white : AppColors.onSurface,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThinkingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Asisten AI sedang menyusun jawaban...',
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ── Kolom input ──
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Tanyakan studi kasus harta atau fiqih zakat...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.primary),
              onPressed: _isAiThinking ? null : () => _sendMessage(_inputCtrl.text),
            ),
          ],
        ),
      ),
    );
  }
}