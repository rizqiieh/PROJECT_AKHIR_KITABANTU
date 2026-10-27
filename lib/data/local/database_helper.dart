import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/campaign_model.dart';
import '../models/ledger_model.dart';
import '../models/zakat_history_model.dart';
import '../models/wallet_transaction_model.dart';

/// Helper database SQLite lokal KitaBantu (Bab 8.1).
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kitabantu_local.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Tabel Pengguna Lokal (RF-001)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        avatar_path TEXT,
        biometric_enabled INTEGER DEFAULT 1,
        balance REAL DEFAULT 1000000.0,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Tabel Bookmark Kampanye (RF-004)
    await db.execute('''
      CREATE TABLE bookmarked_campaigns (
        campaign_id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        target_amount REAL NOT NULL,
        collected_amount REAL DEFAULT 0,
        latitude REAL DEFAULT 0,
        longitude REAL DEFAULT 0,
        image_url TEXT,
        location_label TEXT,
        ends_at TEXT,
        saved_at TEXT NOT NULL
      )
    ''');

    // 3. Tabel Riwayat Hitung Zakat (RF-008)
    await db.execute('''
      CREATE TABLE zakat_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        zakat_type TEXT NOT NULL,
        total_wealth REAL NOT NULL,
        zakat_amount REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. Tabel Saran & Kesan lokal (RF-003)
    await db.execute('''
      CREATE TABLE course_feedback (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        student_name TEXT NOT NULL,
        impression TEXT NOT NULL,
        suggestion TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 5. Tabel Ledger Transparansi Lokal (RF-007)
    await db.execute('''
      CREATE TABLE ledger_entries (
        block_index INTEGER PRIMARY KEY,
        donation_id TEXT NOT NULL,
        campaign_id TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        previous_hash TEXT NOT NULL,
        entry_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 6. Tabel Riwayat Mutasi Dompet (Top-up & Pengeluaran)
    await db.execute('''
      CREATE TABLE wallet_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        reference_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ledger_entries (
          block_index INTEGER PRIMARY KEY,
          donation_id TEXT NOT NULL,
          campaign_id TEXT NOT NULL,
          description TEXT NOT NULL,
          amount REAL NOT NULL,
          previous_hash TEXT NOT NULL,
          entry_hash TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN balance REAL DEFAULT 1000000.0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE users ADD COLUMN biometric_enabled INTEGER DEFAULT 1');
      } catch (_) {}
      await db.execute('''
        CREATE TABLE IF NOT EXISTS wallet_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          type TEXT NOT NULL,
          amount REAL NOT NULL,
          description TEXT NOT NULL,
          reference_id TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  // ══════════════════════════════════════════════════════
  //  CRUD — Tabel `users` (RF-001)
  // ══════════════════════════════════════════════════════

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<bool> hasAnyUser() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<UserModel?> getLastUserWithBiometric() async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'biometric_enabled = 1',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<int> updateBiometricEnabled(int userId, bool enabled) async {
    final db = await database;
    return db.update(
      'users',
      {'biometric_enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateUserBalance(int userId, double newBalance) async {
    final db = await database;
    return db.update(
      'users',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateAvatarPath(int userId, String? path) async {
    final db = await database;
    return db.update(
      'users',
      {'avatar_path': path},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updatePassword(String username, String passwordHash, String salt) async {
    final db = await database;
    return db.update(
      'users',
      {
        'password_hash': passwordHash,
        'salt': salt,
      },
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<bool> isUsernameTaken(String username) async {
    final user = await getUserByUsername(username);
    return user != null;
  }

  // ══════════════════════════════════════════════════════
  //  CRUD — Tabel `wallet_transactions` (Mutasi Saldo)
  // ══════════════════════════════════════════════════════

  Future<int> insertWalletTransaction(WalletTransactionModel transaction) async {
    final db = await database;
    return db.insert('wallet_transactions', transaction.toMap());
  }

  Future<List<WalletTransactionModel>> getWalletTransactions(int userId) async {
    final db = await database;
    final list = await db.query(
      'wallet_transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return list.map((e) => WalletTransactionModel.fromMap(e)).toList();
  }

  // ══════════════════════════════════════════════════════
  //  CRUD — Tabel `bookmarked_campaigns` (RF-004)
  // ══════════════════════════════════════════════════════

  Future<void> addBookmark(CampaignModel campaign) async {
    final db = await database;
    await db.insert(
      'bookmarked_campaigns',
      {
        'campaign_id': campaign.id,
        'title': campaign.title,
        'description': campaign.description,
        'category': campaign.category,
        'target_amount': campaign.targetAmount,
        'collected_amount': campaign.collectedAmount,
        'latitude': campaign.latitude,
        'longitude': campaign.longitude,
        'image_url': campaign.imageUrl,
        'location_label': campaign.locationLabel,
        'ends_at': campaign.endsAt,
        'saved_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeBookmark(String campaignId) async {
    final db = await database;
    await db.delete(
      'bookmarked_campaigns',
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
    );
  }

  Future<bool> isBookmarked(String campaignId) async {
    final db = await database;
    final result = await db.query(
      'bookmarked_campaigns',
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<List<CampaignModel>> getBookmarks() async {
    final db = await database;
    final list = await db.query('bookmarked_campaigns', orderBy: 'saved_at DESC');
    return list.map((map) => CampaignModel.fromMap(map)).toList();
  }

  // ══════════════════════════════════════════════════════
  //  CRUD — Tabel `zakat_history` (RF-008)
  // ══════════════════════════════════════════════════════

  Future<int> insertZakatHistory(ZakatHistoryModel item) async {
    final db = await database;
    return db.insert('zakat_history', item.toMap());
  }

  Future<List<ZakatHistoryModel>> getZakatHistory(int userId) async {
    final db = await database;
    final result = await db.query(
      'zakat_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return result.map((e) => ZakatHistoryModel.fromMap(e)).toList();
  }

  // ══════════════════════════════════════════════════════
  //  CRUD — Tabel `course_feedback` (RF-003)
  // ══════════════════════════════════════════════════════

  Future<int> insertFeedback({
    required int userId,
    required String studentName,
    required String impression,
    required String suggestion,
  }) async {
    final db = await database;
    return db.insert('course_feedback', {
      'user_id': userId,
      'student_name': studentName,
      'impression': impression,
      'suggestion': suggestion,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getFeedbackList() async {
    final db = await database;
    return db.query('course_feedback', orderBy: 'created_at DESC');
  }

  // ══════════════════════════════════════════════════════
  //  CRUD — Tabel `ledger_entries` (RF-007)
  // ══════════════════════════════════════════════════════

  Future<void> insertLedgerEntry(LedgerModel entry) async {
    final db = await database;
    await db.insert('ledger_entries', entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<LedgerModel>> getLedgerEntries() async {
    final db = await database;
    final list = await db.query('ledger_entries', orderBy: 'block_index ASC');
    return list.map((e) => LedgerModel.fromMap(e)).toList();
  }

  Future<LedgerModel?> getLatestLedgerEntry() async {
    final db = await database;
    final list = await db.query(
      'ledger_entries',
      orderBy: 'block_index DESC',
      limit: 1,
    );
    if (list.isEmpty) return null;
    return LedgerModel.fromMap(list.first);
  }
}
