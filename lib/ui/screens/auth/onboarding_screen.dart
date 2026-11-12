import 'package:flutter/material.dart';
import 'package:kitabantu/data/local/secure_storage_service.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Palet warna sesuai desain Figma
  static const Color _bgColor = Color(0xFFF8F9FA);          // Latar abu-abu terang / off-white bersih
  static const Color _primaryGreen = Color(0xFF26533C);    // Hijau utama khas KitaBantu
  static const Color _textColor = Color(0xFF1E293B);        // Teks gelap agar mudah dibaca
  static const Color _subtitleColor = Color(0xFF64748B);     // Abu-abu netral untuk deskripsi

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images/onboarding_1.png',
      'title': 'Berbagi Tanpa Batas Jarak',
      'desc': 'Temukan panti asuhan, korban bencana, dan tetangga yang membutuhkan bantuan di sekitarmu secara cepat dan mudah.',
    },
    {
      'image': 'assets/images/onboarding_2.png',
      'title': 'Penyaluran Terbuka & Terlacak',
      'desc': 'Pantau setiap rupiah donasimu lewat pembaruan laporan berkala dan pencatatan riwayat dana yang aman serta transparan.',
    },
    {
      'image': 'assets/images/onboarding_3.png',
      'title': 'Zakat Digital Makin Praktis',
      'desc': 'Hitung nisab secara otomatis dengan bantuan kalkulator cerdas dan salurkan kewajiban zakatmu tepat pada mustahik.',
    },
  ];

  Future<void> _finishOnboarding() async {
    await SecureStorageService.instance.setOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(item['image']!, height: 260),
                        const SizedBox(height: 36),
                        Text(
                          item['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item['desc']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: _subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indikator Titik (Dots Indicator)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? Color(0xFF1B3B2B) : Color(0xFF1B3B2B).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            const SizedBox(height: 48),

            // Tombol Navigasi Bawah (Skip & Next / Mulai)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _subtitleColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _finishOnboarding,
                        child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded( 
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          if (_currentPage == _pages.length - 1) {
                            _finishOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Text(
                          _currentPage == _pages.length - 1 ? 'Mulai' : 'Next',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
