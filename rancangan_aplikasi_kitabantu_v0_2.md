# Rancangan Aplikasi KitaBantu — V0.2 (Siap Eksekusi)

**Status:** Revisi V0.2 — Keputusan arsitektur dikunci agar efisien dan siap diimplementasikan tanpa hambatan teknis.  
**Platform:** Flutter / Dart  
**Aplikasi:** KitaBantu — Crowdfunding Sosial dan Pengelolaan Zakat Digital  
**Tim Pengembang (SRS):**
1. Alif Shatrya Timurlangit
2. Maulana Rizqi Ma’rufi
3. Muhammad Said Najih

---

## 1. Tujuan Rancangan V0.2

Dokumen ini merupakan acuan teknis yang menerjemahkan ketentuan dosen dan SRS menjadi arsitektur aplikasi yang **realistis untuk dikerjakan oleh 3 orang**. Pada versi V0.2 ini, seluruh keraguan arsitektur pada V0.1 telah diputuskan menggunakan pendekatan paling efisien agar tim tidak kehabisan waktu akibat *over-engineering* atau kesalahan *copy-paste* yang ada pada dokumen SRS awal.

---

## 2. Aturan Utama Pengembangan

1. **Pemenuhan Rubrik Dosen adalah Prioritas Mutlak:** Setiap fitur wajib (Autentikasi Lokal Enkripsi, Biometrik, SQLite + API Online, LBS, Konverter Waktu & Kurs, Blockchain/Ledger, AI/LLM, 2 Sensor, Mini-game, Notifikasi, dan 3 item Bottom Navigation) harus berfungsi nyata, bukan sekadar tampilan UI.
2. **Standarisasi *State Management*:** Seluruh anggota tim dan *AI coding assistant* wajib memisahkan logika bisnis dari UI menggunakan **`flutter_riverpod`** (atau `provider`). Dilarang menaruh pemanggilan API atau query SQLite langsung di dalam blok `build()` widget.
3. **Keamanan *Secret Key*:** Dilarang keras memasukkan API Key (Supabase / Gemini AI) ke dalam repositori GitHub. Gunakan file `.env` lokal yang diabaikan oleh `.gitignore` dan jalankan melalui argumen `--dart-define-from-file=.env`.
4. **Kejujuran Status Transaksi:** Karena tidak menggunakan *payment gateway* berbayar, seluruh alur pembayaran donasi/zakat diberi label jelas sebagai **"Simulasi Transaksi Demo"**.
5. **Kontrol Kode AI:** Setiap kode yang dihasilkan oleh AI (*Antigravity* / *AI Studio*) wajib mengikuti struktur folder yang telah ditetapkan, lolos `flutter analyze`, dan ditinjau melalui *Pull Request* sebelum masuk ke branch `main`.

---

## 3. Keputusan Stack Teknis (V0.2)

Susunan *package* berikut dipilih karena bebas biaya langganan/kartu kredit, ringan, dan langsung menjawab seluruh poin penilaian dosen:

| Lapisan | Keputusan Stack V0.2 | Peran Konkret dalam Aplikasi |
|---|---|---|
| **Framework & State** | Flutter + `flutter_riverpod` | Membangun UI reaktif, memisahkan logika bisnis dari tampilan, dan memudahkan *unit testing*. |
| **Autentikasi & Sesi** | `sqflite` + `crypto` + `flutter_secure_storage` | Menyimpan akun pengguna di tabel `users` SQLite dengan *hash* password `SHA-256` (+ *salt*) serta menyimpan sesi login untuk biometrik. |
| **Biometrik** | `local_auth` | Memvalidasi sidik jari / pengenalan wajah perangkat untuk membuka sesi pengguna yang masih aktif. |
| **Database Lokal** | `sqflite` | Menyimpan data murni lokal: tabel `users`, `bookmarked_campaigns` (kampanye favorit), dan `zakat_history` (riwayat hitung zakat). |
| **Database Online** | Supabase PostgreSQL (`supabase_flutter`) | Menyimpan data bersama secara *online*: daftar kampanye, transaksi donasi, pembaruan penyaluran, dan *ledger* transparansi. |
| **API Kurs Mata Uang** | `http` / `dio` + **Frankfurter API** | Mengambil kurs *real-time* gratis tanpa API key untuk konversi `IDR`, `USD`, `EUR`, dan `GBP`. |
| **LBS & Peta** | `flutter_map` (OpenStreetMap) + `geolocator` | Menampilkan peta titik panti asuhan/bencana secara gratis (tanpa kartu kredit Google Cloud) dan menghitung jarak dari koordinat GPS pengguna. |
| **Waktu & Format** | `intl` + `timezone` | Mengonversi waktu akurat lintas zona (`WIB`, `WITA`, `WIT`, dan `London` termasuk penyesuaian *Daylight Saving Time*) serta format mata uang. |
| **Sensor & Mini-game** | `sensors_plus` | Mengakses **Gyroscope** dan **Accelerometer** sekaligus di dalam modul *Mini-Game Kotak Infak & Kuis Zakat*. |
| **AI / LLM** | `google_generative_ai` | Menghubungkan aplikasi ke model Gemini untuk fitur Asisten & Kalkulator Zakat Cerdas (API key disuntikkan lewat `--dart-define-from-file`). |
| **Notifikasi** | `flutter_local_notifications` | Memicu notifikasi lokal di perangkat saat simulasi donasi berhasil dicatat ke *ledger* atau saat pengingat kampanye diaktifkan. |

---

## 4. Keputusan Arsitektur yang Dikunci (Solusi Konflik SRS)

Untuk menghindari kebingungan saat implementasi, lima area abu-abu pada SRS dan V0.1 resmi diselesaikan dengan aturan berikut:

### 4.1. Strategi Autentikasi Hibrida (Tanpa Firebase)
* **Masalah:** PBI-001 mewajibkan SQLite untuk *user* dan *hashing* `SHA-256`, sedangkan aplikasi juga membutuhkan database *online* (Supabase).
* **Keputusan V0.2:** Autentikasi dilakukan **100% menggunakan SQLite lokal (`users`) + `crypto` (`SHA-256` dengan *salt*)** agar sesuai persis dengan rubrik penilaian dosen. Saat pengguna berhasil login, ID dan nama pengguna disimpan di `flutter_secure_storage`. Ketika pengguna berdonasi atau mengirim Saran & Kesan ke Supabase, aplikasi mengirimkan `local_user_id` dan `donor_name` tersebut ke tabel Supabase melalui Data API.

### 4.2. Pembagian Peran SQLite vs Supabase (Bebas Konflik Sinkronisasi)
* **Masalah:** Menyimpan *cache* tabel kampanye dari Supabase ke SQLite lokal membutuhkan mekanisme sinkronisasi dua arah yang rumit dan rawan *bug*.
* **Keputusan V0.2:** Pisahkan fungsi keduanya secara tegas:
  * **SQLite Lokal** hanya menyimpan: (1) Akun Pengguna (`users`), (2) Daftar Bookmark/Kampanye Tersimpan (`bookmarked_campaigns`), dan (3) Riwayat Perhitungan Kalkulator Zakat (`zakat_history`).
  * **Supabase Online** menyimpan: (1) Data Kampanye (`campaigns`), (2) Transaksi Donasi (`donations`), (3) Kabar Penyaluran (`campaign_updates`), dan (4) Catatan Rantai Hash (`ledger_entries`).

### 4.3. Struktur Bottom Navigation (Patuh Rubrik & Ramah UX)
* **Masalah:** Dosen mewajibkan *Bottom Navigation* berisi **Profil**, **Saran & Kesan**, dan **Logout**, sementara pengguna tetap membutuhkan akses cepat ke halaman utama.
* **Keputusan V0.2:** Gunakan `BottomNavigationBar` dengan **4 Tab tetap**:
  1. **Beranda** (Pusat navigasi menuju Jelajah Kampanye, Peta LBS, Kalkulator Zakat AI, Konverter Kurs/Waktu, Ledger Transparansi, dan Mini-Game Sensor).
  2. **Profil** (Menampilkan foto profil, data akun, daftar *bookmark* dari SQLite, dan pengaturan aktif/nonaktif login biometrik).
  3. **Saran & Kesan** (Formulir penilaian/masukan mata kuliah beserta daftar riwayat saran yang tersimpan).
  4. **Logout** (Menekan tab ini tidak memindahkan halaman, melainkan langsung mencegat event `onTap` untuk memunculkan `AlertDialog` konfirmasi keluar dan menghapus sesi).

### 4.4. Penggabungan Fitur 2 Sensor (RF-010) & Mini-Game (RF-011)
* **Masalah:** Membuat fitur sensor terpisah dari mini-game menggandakan beban pembuatan UI dan pengujian.
* **Keputusan V0.2:** Gabungkan keduanya menjadi fitur **"Tangkap Berkah & Kuis Zakat"**:
  * **Gyroscope:** Pengguna memiringkan ponsel ke kiri/kanan untuk menggerakkan keranjang/kotak infak guna menangkap koin sedekah yang jatuh.
  * **Kuis Edukasi:** Setiap 3 koin yang tertangkap akan memunculkan 1 kartu pertanyaan kuis singkat seputar hukum zakat/sedekah untuk menambah skor.
  * **Accelerometer:** Pengguna menggoyangkan ponsel (*shake*) untuk membuka "Kotak Kejutan Harian" atau mereset permainan dengan konfirmasi dialog.

### 4.5. Perhitungan Hash Ledger di Sisi Database (PostgreSQL Trigger)
* **Masalah:** Jika `previous_hash` dan `entry_hash` dihitung di aplikasi Flutter, dua donasi yang masuk bersamaan dapat merusak urutan rantai hash (*race condition*).
* **Keputusan V0.2:** Buat **PostgreSQL Function & Trigger** di Supabase yang otomatis mengambil `entry_hash` terakhir sebagai `previous_hash` dan menghitung `SHA-256` untuk baris baru setiap kali ada `INSERT` pada tabel `donations` / `ledger_entries`. Aplikasi Flutter bertugas menampilkan rantai tersebut dan memiliki tombol **"Verifikasi Integritas Rantai"** yang menghitung ulang hash di sisi klien untuk membuktikan tidak ada manipulasi data.

---

## 5. Peta Fitur & Bukti Pengujian (RF-001 s.d. RF-011)

| ID | Kebutuhan | Implementasi V0.2 | Bukti Pengujian Minimum |
|---|---|---|---|
| **RF-001** | Registrasi, Login, Password Terenkripsi (`SHA-256`), Session; Tanpa Firebase | Tabel `users` di SQLite, *password* di-*hash* dengan `SHA-256` + *salt* via paket `crypto`, sesi disimpan di `flutter_secure_storage`. | Registrasi berhasil, inspeksi DB SQLite membuktikan password berupa *hash*, sesi bertahan saat aplikasi ditutup dan dibuka kembali. |
| **RF-002** | Login Biometrik | Validasi `local_auth` pada halaman Login untuk membuka sesi yang tersimpan di `flutter_secure_storage`; dilengkapi tombol *fallback* password biasa. | Sukses masuk dengan sidik jari/wajah; sukses kembali ke input password jika biometrik dibatalkan/gagal. |
| **RF-003** | Bottom Navigation: Profil (bergambar), Saran & Kesan, Logout | `BottomNavigationBar` 4 item: `Beranda`, `Profil`, `Saran & Kesan`, `Logout` (memicu dialog konfirmasi). | Keempat tab berfungsi; foto tampil di Profil; form Saran & Kesan tersimpan; Logout menghapus sesi dan kembali ke layar Login. |
| **RF-004** | Penyimpanan Lokal (SQLite) & Online (API) | SQLite untuk `users`, `bookmarked_campaigns`, dan `zakat_history`. Supabase API untuk `campaigns`, `donations`, dan `ledger_entries`. | Data kampanye tampil dari internet (Supabase); *bookmark* dan riwayat zakat tetap bisa dibuka dari SQLite saat mode pesawat (*offline*). |
| **RF-005** | Cari/Pilih Kampanye & LBS (Panti Asuhan / Bencana Terdekat) | Pencarian & filter kategori kampanye; peta `flutter_map` (OpenStreetMap) dengan perhitungan jarak radius menggunakan `geolocator`. | Pencarian kata kunci akurat; marker peta tampil; jarak dalam $\text{km}$ dihitung dari titik GPS perangkat pengguna. |
| **RF-006** | Konversi Mata Uang (`IDR`, `USD`, `EUR`, `GBP`) & Waktu (`WIB`, `WITA`, `WIT`, `London`) | Kurs ditarik dari **Frankfurter API** (dengan nilai *fallback* jika *offline*); konversi zona waktu memakai paket `timezone`. | Nominal donasi/zakat terkonversi akurat ke 4 mata uang; jadwal berakhir kampanye tampil serempak di 4 zona waktu. |
| **RF-007** | Ledger Transparansi (Konsep Blockchain Sederhana) | Tabel `ledger_entries` append-only dengan `previous_hash` dan `entry_hash` (`SHA-256`), dilengkapi fitur cek validitas rantai di Flutter. | Urutan blok tampil rapi; tombol "Cek Integritas" menunjukkan status **Valid (Hijau)**, atau **Rusak (Merah)** jika ada data yang diubah paksa di DB. |
| **RF-008** | Fitur AI / LLM | Kalkulator & Asisten Zakat Cerdas berbasis Gemini (`google_generative_ai`). Menghitung zakat mal ($2.5\%$) / penghasilan dan menjawab tanya-jawab fiqih zakat dasar. | Input harta menghasilkan perhitungan nisab dan zakat ($2.5\%$); AI merespons pertanyaan dengan ramah dan menyertakan *disclaimer* edukasi. |
| **RF-009** | Notifikasi Mobile *(mengabaikan teks salah salin "pesanan produk" di SRS)* | `flutter_local_notifications` memicu notifikasi instan saat donasi berhasil dicatat ke *ledger* dan saat pengguna menekan tombol "Ingatkan Kampanye Ini". | Notifikasi muncul di *status bar* HP lengkap dengan judul kampanye dan nominal donasi simulasi. |
| **RF-010 & RF-011** | Minimal 2 Sensor (`Accelerometer` & `Gyroscope`) + Mini-Game Edukasi Zakat | Permainan **"Tangkap Berkah & Kuis Zakat"**: *Gyroscope* menggerakkan kotak infak penangkap koin, setiap 3 koin memunculkan kuis zakat, dan *Accelerometer* (*shake*) membuka bonus/reset. | Gerakan miring HP menggerakkan objek di layar; goyangan HP terdeteksi; kuis menghitung skor akhir dan menyimpannya. |

---

## 6. Struktur Layar Aplikasi (10 Layar Inti)

Pemangkasan dan penggabungan layar dilakukan agar tim fokus pada kualitas dan penyelesaian tepat waktu:

### A. Alur Autentikasi
1. **Splash & Onboarding Singkat:** Menampilkan logo KitaBantu, pengecekan sesi aktif, dan 3–4 slide pengenalan singkat (hanya muncul saat pertama kali instal).
2. **Halaman Login & Biometrik:** Input username/email & password, tombol "Masuk dengan Biometrik" (jika sesi biometrik sudah diaktifkan), dan tautan ke Registrasi.
3. **Halaman Registrasi:** Input nama lengkap, username/email, password, dan pemilihan avatar/foto profil.

### B. Area Utama (Di Dalam Kerangka 4 Tab Bottom Navigation)
4. **Tab 1 — Beranda (Dashboard Utama):**
   * Header sapaan pengguna & ringkasan singkat.
   * **Grid Pintasan Fitur Wajib:** (1) Peta LBS Sekitar, (2) Kalkulator & AI Zakat, (3) Konverter Kurs & Waktu, (4) Ledger Transparansi, (5) Mini-Game Sensor.
   * **Daftar & Pencarian Kampanye:** Kolom *search*, *chip* filter kategori (`Bencana`, `Panti Asuhan`, `Pendidikan`, `Kesehatan`), dan kartu kampanye.
5. **Halaman Detail Kampanye & Simulasi Donasi:**
   * Deskripsi, bilah progres dana terkumpul vs target, batas waktu (dapat dilihat dalam `WIB`/`WITA`/`WIT`/`London`), lokasi di peta mini, dan tombol *Bookmark* (simpan ke SQLite).
   * *Bottom Sheet* **Simulasi Donasi**: Input nominal (dilengkapi pratinjau konversi `IDR`/`USD`/`EUR`/`GBP`), konfirmasi pembayaran simulasi, pencatatan ke *Ledger*, dan pemicu **Notifikasi Lokal**.
6. **Halaman Peta LBS (Panti Asuhan & Bencana Terdekat):**
   * Peta interaktif OpenStreetMap (`flutter_map`), titik lokasi pengguna saat ini, marker kampanye di sekitar lengkap dengan jarak ($\text{km}$), dan kartu ringkas saat marker ditekan.
7. **Halaman Kalkulator Zakat & Asisten AI:**
   * Tab Kalkulator: Input nilai harta/penghasilan, perhitungan otomatis nisab dan tarif zakat ($2.5\%$), tombol simpan riwayat ke SQLite.
   * Tab Tanya AI: Antarmuka *chat* terarah dengan asisten AI untuk konsultasi seputar zakat dan rekomendasi donasi.
8. **Halaman Ledger Transparansi (Hash-Chain):**
   * Daftar blok transaksi berurutan (Menampilkan kode referensi, nominal, waktu, potongan `previous_hash`, dan `entry_hash`) serta tombol **"Verifikasi Rantai Blockchain"**.
9. **Halaman Mini-Game Sensor ("Tangkap Berkah & Kuis Zakat"):**
   * Kanvas permainan menggunakan *Gyroscope* (miringkan layar) dan *Accelerometer* (goyangkan layar), pop-up pertanyaan kuis zakat, dan papan skor akhir.
10. **Tab 2, 3, 4 — Profil, Saran & Kesan, dan Dialog Logout:**
    * **Tab 2 (Profil):** Foto profil, nama, toggle aktifkan Biometrik, tab daftar Kampanye Favorit (SQLite), dan tab Riwayat Hitung Zakat (SQLite).
    * **Tab 3 (Saran & Kesan):** Formulir input kesan & pesan selama mengikuti mata kuliah Pemrograman Aplikasi Mobile beserta daftar kiriman.
    * **Tab 4 (Logout):** Memunculkan modal konfirmasi keluar aplikasi.

---

## 7. Arahan Visual & Desain UI

- **Palet Warna Resmi:**
  - Hijau Utama (*Primary*): `#4F8268`
  - Hijau Sage (*Secondary / Accent*): `#98B18A`
  - Latar Belakang Hangat (*Background*): `#F7F7F1`
  - Permukaan Kartu (*Surface*): `#FFFFFF`
  - Teks Utama (*On Surface*): `#24352C`
  - Status Valid / Sukses: `#2E7D32` | Peringatan / Simulasi: `#EF6C00` | Error: `#C62828`
- **Aturan Antarmuka:**
  - Hindari gaya visual generik seperti gradasi ungu-biru atau efek *neon glow*. Gunakan sudut membulat yang bersih (`borderRadius: 12` atau `16`) dengan bayangan lembut.
  - Setiap layar yang memuat data **wajib** memiliki 4 tampilan keadaan (*state*): **Loading** (`CircularProgressIndicator` / *Shimmer*), **Data Tampil**, **Kosong** (*Empty State* dengan ilustrasi/ikon jelas), dan **Error / Offline** (lengkap dengan tombol *Coba Lagi*).

---

## 8. Skema Struktur Data (SQLite & Supabase)

### 8.1. Database Lokal — SQLite (`kitabantu_local.db`)

```sql
-- 1. Tabel Pengguna Lokal (PBI-001 / RF-001)
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  full_name TEXT NOT NULL,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL, -- SHA-256(password + salt)
  salt TEXT NOT NULL,
  avatar_path TEXT,
  biometric_enabled INTEGER DEFAULT 0,
  created_at TEXT NOT NULL
);

-- 2. Tabel Bookmark Kampanye (Bukti CRUD Lokal RF-004)
CREATE TABLE bookmarked_campaigns (
  campaign_id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  target_amount REAL NOT NULL,
  image_url TEXT,
  location_label TEXT,
  saved_at TEXT NOT NULL
);

-- 3. Tabel Riwayat Hitung Zakat & Catatan Saran Lokal
CREATE TABLE zakat_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  zakat_type TEXT NOT NULL, -- 'Penghasilan' atau 'Maal'
  total_wealth REAL NOT NULL,
  zakat_amount REAL NOT NULL, -- 2.5% dari total_wealth jika mencapai nisab
  created_at TEXT NOT NULL
);
```

### 8.2. Database Online — Supabase PostgreSQL

```sql
-- 1. Tabel Kampanye Donasi
CREATE TABLE campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL, -- 'Panti Asuhan', 'Bencana', 'Pendidikan', 'Kesehatan'
  target_amount NUMERIC NOT NULL,
  collected_amount NUMERIC DEFAULT 0,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  location_label TEXT NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Tabel Transaksi Donasi (Simulasi Demo)
CREATE TABLE donations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
  local_user_id INTEGER NOT NULL,
  donor_name TEXT NOT NULL,
  amount_idr NUMERIC NOT NULL,
  original_currency TEXT DEFAULT 'IDR',
  reference_code TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Tabel Ledger Transparansi (Hash-Chain RF-007)
CREATE TABLE ledger_entries (
  block_index SERIAL PRIMARY KEY,
  donation_id UUID REFERENCES donations(id),
  campaign_id UUID REFERENCES campaigns(id),
  description TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  previous_hash TEXT NOT NULL,
  entry_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Tabel Saran & Kesan Mata Kuliah (RF-003)
CREATE TABLE course_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  local_user_id INTEGER NOT NULL,
  student_name TEXT NOT NULL,
  impression TEXT NOT NULL,
  suggestion TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

---

## 9. Struktur Folder Kode Flutter

Seluruh anggota tim dan *tool* AI wajib mematuhi struktur direktori berikut agar tidak terjadi kekacauan file:

```text
lib/
├── main.dart
├── core/
│   ├── constants/       # Palet warna, teks statis, konfigurasi env
│   ├── theme/           # AppTheme (Light mode hijau sage)
│   └── utils/           # Helper SHA-256, konverter zona waktu, format Rupiah
├── data/
│   ├── local/           # DatabaseHelper SQLite & SecureStorageService
│   ├── models/          # Class model Dart (UserModel, CampaignModel, LedgerModel, dll.)
│   ├── remote/          # SupabaseService, CurrencyApiService, GeminiAiService
│   └── repositories/    # Penghubung antara sumber data dan state provider
├── providers/           # State management Riverpod/Provider per fitur
└── ui/
    ├── widgets/         # Komponen bersama (CustomButton, CampaignCard, EmptyState)
    └── screens/
        ├── auth/        # Login, Register, Splash
        ├── home/        # MainShell (BottomNav 4 tab) & Beranda
        ├── campaign/    # Jelajah, Detail Kampanye, BottomSheet Donasi
        ├── map_lbs/     # Peta OpenStreetMap & daftar lokasi terdekat
        ├── utilities/   # Konverter Kurs & Waktu, Kalkulator & Chat AI Zakat
        ├── ledger/      # Layar Transparansi Blockchain Hash-Chain
        ├── minigame/    # Game Sensor Gyroscope + Accelerometer & Kuis
        └── profile/     # Profil, Bookmark, Saran & Kesan
```

---

## 10. Rekomendasi Pembagian Tugas Tim (3 Orang)

Agar tidak terjadi konflik *merge* di GitHub (`git conflict`), bagi pekerjaan berdasarkan modul layar dan lapisan data berikut:

| Anggota Tim | Fokus Modul & Tanggung Jawab Utama | Branch GitHub Utama |
|---|---|---|
| **Anggota 1** (Alif Shatrya Timurlangit) | **Pondasi, Autentikasi, & Profil:** Setup proyek, Design System, SQLite `DatabaseHelper`, Autentikasi `SHA-256` (`RF-001`), Biometrik (`RF-002`), Kerangka BottomNav 4 Tab, Profil + Bookmark, dan Saran & Kesan (`RF-003`). | `feature/core-auth-profile` |
| **Anggota 2** (Maulana Rizqi Ma’rufi) | **Kampanye, LBS, Donasi, & Ledger:** Setup tabel Supabase, Daftar & Cari Kampanye (`RF-004`, `RF-005`), Peta OpenStreetMap + Geolocator (`RF-005`), Alur Simulasi Donasi + Notifikasi Lokal (`RF-009`), dan Ledger Hash-Chain (`RF-007`). | `feature/campaigns-map-ledger` |
| **Anggota 3** (Muhammad Said Najih) | **Utilitas, AI/LLM, Sensor & Mini-Game:** Konverter Mata Uang Frankfurter API & Zona Waktu (`RF-006`), Kalkulator & Asisten Zakat AI Gemini (`RF-008`), serta Mini-Game 2 Sensor Gyroscope + Accelerometer (`RF-010`, `RF-011`). | `feature/ai-utilities-minigame` |

---

## 11. Urutan Kerja Mingguan (Action Plan)

1. **Tahap 1 — Pondasi & Data Lokal (Hari 1–3):**
   Inisialisasi repositori Flutter, pasang semua *package* di `pubspec.yaml`, buat `AppTheme`, bangun `DatabaseHelper` SQLite, dan selesaikan alur Registrasi/Login (`SHA-256`) + Biometrik + Kerangka 4 Tab *Bottom Navigation*.
2. **Tahap 2 — Kampanye Online & Peta LBS (Hari 4–7):**
   Buat tabel di Supabase dan isi 10–15 data kampanye contoh (panti asuhan & lokasi bencana di sekitar Yogyakarta/Indonesia dengan koordinat asli). Hubungkan daftar kampanye, fitur pencarian, halaman detail, *bookmark* SQLite, dan peta OpenStreetMap (`flutter_map`).
3. **Tahap 3 — Transaksi Simulasi, Ledger, & Notifikasi (Hari 8–10):**
   Bangun fitur simulasi donasi, hubungkan dengan pemicu pembuatan blok hash di `ledger_entries`, buat layar verifikasi rantai hash, dan pasang `flutter_local_notifications` saat donasi selesai.
4. **Tahap 4 — Utilitas, AI Zakat, & Mini-Game Sensor (Hari 11–14):**
   Integrasikan API kurs mata uang (`IDR`, `USD`, `EUR`, `GBP`) dan konversi waktu (`WIB`, `WITA`, `WIT`, `London`). Hubungkan Gemini API untuk Kalkulator/Asisten Zakat, lalu bangun layar Mini-Game Sensor (`sensors_plus`).
5. **Tahap 5 — Pengujian & Dokumentasi Laporan (Hari 15–16):**
   Jalankan *unit test* pada fungsi logika inti, rapikan tampilan *error/offline state*, rekam video demo, dan lengkapi laporan akhir.

---

## 12. Definition of Done (Realistis & Terukur)

Mengingat waktu perkuliahan dan jumlah tim 3 orang, standar *Definition of Done* disesuaikan agar fokus pada penilaian dosen:

### Fokus Unit Testing (Logika Murni)
Daripada mengejar 80% *widget coverage* yang menyita waktu pada komponen peta dan sensor, **Unit Test wajib lulus 100% pada 4 fungsi logika utama**:
1. Fungsi *hashing* password `SHA-256` beserta verifikasi *salt*.
2. Fungsi perhitungan dan verifikasi keutuhan rantai hash (*hash-chain ledger*).
3. Fungsi rumus konversi mata uang dan konversi zona waktu (`WIB`, `WITA`, `WIT`, `London`).
4. Fungsi perhitungan nisab dan zakat ($2.5\%$).

### Checklist Penerimaan AkhirSebelum Demo
- [ ] Registrasi dan Login lokal dengan SQLite + `SHA-256` berfungsi tanpa Firebase.
- [ ] Login Biometrik (`local_auth`) berjalan lancar dan memiliki opsi kembali ke password biasa.
- [ ] Bottom Navigation menampilkan `Beranda`, `Profil` (dengan foto), `Saran & Kesan`, dan `Logout`.
- [ ] Database SQLite lokal dan Supabase API online sama-sama terbukti aktif digunakan.
- [ ] Pencarian kampanye, filter kategori, dan peta LBS (`flutter_map` + jarak GPS) berfungsi.
- [ ] Konversi mata uang (`IDR`, `USD`, `EUR`, `GBP`) dan waktu (`WIB`, `WITA`, `WIT`, `London`) akurat.
- [ ] Ledger transparansi menampilkan rantai hash dan memiliki fitur cek integritas rantai.
- [ ] Asisten/Kalkulator Zakat AI merespons dengan baik tanpa membocorkan API key di GitHub.
- [ ] Sensor *Accelerometer* dan *Gyroscope* bekerja nyata di dalam Mini-Game edukasi zakat.
- [ ] Notifikasi lokal muncul di perangkat saat simulasi donasi berhasil dilakukan.
- [ ] Aplikasi tidak mengalami *force close* ketika koneksi internet dimatikan atau izin lokasi ditolak.

---

## 13. Catatan Koreksi Anomali SRS (Untuk Lampiran Laporan)

Bagian ini mendokumentasikan pelurusan kesalahan redaksional pada dokumen SRS awal agar tim memiliki argumen akademis yang jelas saat presentasi/sidang:
1. **Koreksi RF-009 (Notifikasi vs Pesanan Produk):** Deskripsi tentang "detail produk, jumlah, dan alamat pengiriman" pada SRS merupakan sisa *template e-commerce* yang tidak relevan dengan domain donasi/zakat. Pada implementasi KitaBantu, RF-009 dikembalikan ke fungsi aslinya yaitu **Notifikasi Status Donasi & Pengingat Kampanye**.
2. **Koreksi Penamaan Sprint 3 ("Manajemen Pesanan") & Sprint 4 ("Manajemen Stok"):** Nama *sprint* diabaikan dan eksekusi mengacu penuh pada isi deskripsi tugas di dalamnya (Integrasi API Kampanye, LBS Peta, Ledger Blockchain, AI, dan Sensor).