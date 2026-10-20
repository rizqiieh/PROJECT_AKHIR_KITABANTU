import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:kitabantu/core/constants/app_colors.dart';

/// Layar Mini-Game 2 Sensor: Gyroscope + Accelerometer & Kuis Zakat (Bab 4.4, RF-010 & RF-011).
class MinigameScreen extends StatefulWidget {
  const MinigameScreen({super.key});

  @override
  State<MinigameScreen> createState() => _MinigameScreenState();
}

class _MinigameScreenState extends State<MinigameScreen> {
  // ── State Permainan ──
  double _basketX = 0.5; // Posisi horizontal kotak infak (0.0 kiri s.d 1.0 kanan)
  double _coinX = 0.5; // Posisi horizontal koin
  double _coinY = 0.0; // Posisi vertikal koin jatuh (0.0 atas s.d 1.0 bawah)
  int _score = 0;
  int _coinsCaught = 0;
  bool _isPlaying = true;
  bool _isQuizOpen = false;

  // ── Sensor Subscriptions ──
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Timer? _gameLoopTimer;

  // ── Bank Soal Kuis Fiqih Singkat ──
  final List<Map<String, dynamic>> _quizQuestions = [
    {
      'question': 'Berapakah nisab standar emas untuk Zakat Maal?',
      'options': ['50 Gram', '85 Gram', '100 Gram', '200 Gram'],
      'answer': 1,
    },
    {
      'question': 'Berapa persen tarif wajib zakat mal dan penghasilan?',
      'options': ['1.0%', '2.5%', '5.0%', '10.0%'],
      'answer': 1,
    },
    {
      'question': 'Berapakah jumlah golongan (asnaf) yang berhak menerima zakat?',
      'options': ['5 Golongan', '6 Golongan', '8 Golongan', '10 Golongan'],
      'answer': 2,
    },
    {
      'question': 'Syarat kepemilikan harta selama satu tahun penuh dalam zakat disebut?',
      'options': ['Nisab', 'Haul', 'Riba', 'Kifarat'],
      'answer': 1,
    },
    {
      'question': 'Petugas yang bertugas menghimpun dan menyalurkan zakat disebut?',
      'options': ['Muzakki', 'Gharimin', 'Amil', 'Ibnu Sabil'],
      'answer': 2,
    },
  ];
  int _currentQuizIndex = 0;

  @override
  void initState() {
    super.initState();
    _initSensors();
    _startGameLoop();
  }

  void _initSensors() {
    // 1. Sensor Gyroscope: Deteksi rotasi/kemiringan untuk menggerakkan kotak infak (RF-010)
    try {
      _gyroscopeSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
        if (!_isPlaying || _isQuizOpen) return;

        // event.y mengukur rotasi ke kiri / kanan (radian per detik)
        setState(() {
          // Sesuaikan sensitivitas kemiringan
          _basketX -= event.y * 0.04;
          if (_basketX < 0.05) _basketX = 0.05;
          if (_basketX > 0.95) _basketX = 0.95;
        });
      });
    } catch (_) {}

    // 2. Sensor Accelerometer: Deteksi guncangan ponsel (Shake) untuk Bonus / Reset (RF-010)
    try {
      _accelerometerSubscription =
          accelerometerEventStream().listen((AccelerometerEvent event) {
        final totalG = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        // Jika ponsel diguncang kuat (> 22 m/s²)
        if (totalG > 22.0 && !_isQuizOpen) {
          _triggerShakeBonus();
        }
      });
    } catch (_) {}
  }

  void _startGameLoop() {
    final random = Random();
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!_isPlaying || _isQuizOpen) return;

      setState(() {
        _coinY += 0.02; // Koin meluncur turun

        // Deteksi tabrakan (Koin ditangkap Kotak Infak di bagian bawah layar)
        if (_coinY >= 0.85 && _coinY <= 0.95) {
          if ((_coinX - _basketX).abs() < 0.14) {
            // Berhasil tertangkap!
            _score += 10;
            _coinsCaught++;
            _resetCoin(random);

            // Setiap 3 koin berhasil ditangkap, munculkan Kuis Zakat (Bab 4.4)
            if (_coinsCaught % 3 == 0) {
              _showQuizDialog();
            }
          }
        }

        // Koin jatuh melewati dasar layar tanpa tertangkap
        if (_coinY > 1.0) {
          _resetCoin(random);
        }
      });
    });
  }

  void _resetCoin(Random random) {
    _coinY = 0.0;
    _coinX = 0.1 + random.nextDouble() * 0.8;
  }

  void _triggerShakeBonus() {
    setState(() {
      _score += 50;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✨ Guncangan Sensor Terdeteksi! Bonus Koin Berkah +50!'),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQuizDialog() {
    setState(() => _isQuizOpen = true);
    final quiz = _quizQuestions[_currentQuizIndex % _quizQuestions.length];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.help_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Kuis Zakat Berkah!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jawab benar untuk mendapatkan bonus +30 poin:',
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Text(
              quiz['question'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 14),
            ...List.generate(
              (quiz['options'] as List).length,
              (idx) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final isCorrect = idx == (quiz['answer'] as int);
                      _handleQuizAnswer(isCorrect);
                    },
                    child: Text((quiz['options'] as List)[idx] as String),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuizAnswer(bool isCorrect) {
    setState(() {
      _isQuizOpen = false;
      _currentQuizIndex++;
      if (isCorrect) {
        _score += 30;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect
            ? 'Jawaban Benar! 🎉 (+30 Skor)'
            : 'Kurang Tepat! Tetap semangat belajar fiqih zakat.'),
        backgroundColor: isCorrect ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _gameLoopTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini-Game Sensor Zakat'),
        actions: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () => setState(() => _isPlaying = !_isPlaying),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Skor',
            onPressed: () => setState(() {
              _score = 0;
              _coinsCaught = 0;
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Skor & Info Sensor Bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surfaceVariant.withValues(alpha: 0.6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                    const SizedBox(width: 6),
                    Text(
                      'Skor: $_score',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  'Koin: $_coinsCaught',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.screen_rotation,
                          size: 14, color: AppColors.primaryDark),
                      SizedBox(width: 4),
                      Text('2 Sensor Aktif',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Kanvas Game Interaktif ──
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                final coinPixelX = _coinX * (width - 40);
                final coinPixelY = _coinY * (height - 60);
                final basketPixelX = _basketX * (width - 70);
                final basketPixelY = height - 70;

                return Stack(
                  children: [
                    // Latar Belakang Gradasi Lembut
                    Container(
                      color: AppColors.background,
                    ),

                    // Koin Sedekah Jatuh
                    Positioned(
                      left: coinPixelX,
                      top: coinPixelY,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.orange, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Rp',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Kotak Infak Penampung (Digerakkan Gyroscope)
                    Positioned(
                      left: basketPixelX,
                      top: basketPixelY,
                      child: Container(
                        width: 70,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.inbox, color: Colors.white, size: 22),
                            Text(
                              'KOTAK INFAK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Instruksi Sensor di Atas
                    Positioned(
                      top: 10,
                      left: 16,
                      right: 16,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '📱 Miringkan HP (Gyroscope) untuk gerakkan kotak | Goyangkan HP (Shake) untuk bonus!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Tombol Kontrol Alternatif (Untuk Emulator / Desktop) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.arrow_left),
                  tooltip: 'Geser Kiri (Manual)',
                  onPressed: () {
                    setState(() {
                      _basketX = (_basketX - 0.1).clamp(0.05, 0.95);
                    });
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                  ),
                  icon: const Icon(Icons.vibration),
                  label: const Text('Simulasi Shake'),
                  onPressed: _triggerShakeBonus,
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.arrow_right),
                  tooltip: 'Geser Kanan (Manual)',
                  onPressed: () {
                    setState(() {
                      _basketX = (_basketX + 0.1).clamp(0.05, 0.95);
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
