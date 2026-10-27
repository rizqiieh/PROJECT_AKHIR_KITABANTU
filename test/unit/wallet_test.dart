import 'package:flutter_test/flutter_test.dart';
import 'package:kitabantu/data/models/user_model.dart';
import 'package:kitabantu/data/models/wallet_transaction_model.dart';

void main() {
  group('5. Unit Test: Saldo Kantong Amanah & Mutasi Dompet SQLite', () {
    test('UserModel memiliki default balance Rp 1.000.000 dan biometricEnabled bernilai true', () {
      final user = UserModel(
        id: 1,
        fullName: 'Ahmad Muzakki',
        username: 'ahmad',
        passwordHash: 'dummy_hash',
        salt: 'dummy_salt',
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(user.balance, equals(1000000.0));
      expect(user.biometricEnabled, isTrue);
    });

    test('Top Up menambah saldo dan Donasi mengurangi saldo secara presisi', () {
      var user = const UserModel(
        id: 1,
        fullName: 'Ahmad Muzakki',
        username: 'ahmad',
        passwordHash: 'hash',
        salt: 'salt',
        balance: 1000000.0,
        createdAt: '2026-10-27T10:00:00',
      );

      // Simulasi Top Up Rp 500.000
      const topUpAmount = 500000.0;
      user = user.copyWith(balance: user.balance + topUpAmount);
      expect(user.balance, equals(1500000.0));

      // Simulasi Donasi Rp 200.000
      const donationAmount = 200000.0;
      expect(user.balance >= donationAmount, isTrue); // Cek kecukupan saldo
      user = user.copyWith(balance: user.balance - donationAmount);
      expect(user.balance, equals(1300000.0));
    });

    test('Validasi saldo tidak mencukupi ketika nominal donasi melebihi saldo', () {
      const user = UserModel(
        id: 1,
        fullName: 'Donatur Test',
        username: 'test',
        passwordHash: 'hash',
        salt: 'salt',
        balance: 50000.0, // Saldo hanya Rp 50.000
        createdAt: '2026-10-27T10:00:00',
      );

      const requiredDonation = 100000.0; // Ingin donasi Rp 100.000
      final isSufficient = user.balance >= requiredDonation;

      expect(isSufficient, isFalse);
    });

    test('Serialisasi dan Deserialisasi WalletTransactionModel dari SQLite Map', () {
      final tx = WalletTransactionModel(
        id: 10,
        userId: 1,
        type: 'TOPUP',
        amount: 250000.0,
        description: 'Top Up Kantong Amanah via QRIS',
        referenceId: 'TOP-123456789',
        createdAt: '2026-10-27T12:00:00',
      );

      final map = tx.toMap();
      expect(map['id'], equals(10));
      expect(map['user_id'], equals(1));
      expect(map['type'], equals('TOPUP'));
      expect(map['amount'], equals(250000.0));
      expect(map['reference_id'], equals('TOP-123456789'));

      final restored = WalletTransactionModel.fromMap(map);
      expect(restored.id, equals(tx.id));
      expect(restored.userId, equals(tx.userId));
      expect(restored.type, equals(tx.type));
      expect(restored.amount, equals(tx.amount));
      expect(restored.description, equals(tx.description));
    });
  });
}
