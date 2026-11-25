import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sauti/features/banking/data/datasources/bank_snapshot_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'saving over a corrupt snapshot repairs the cache and releases the queue',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'bank_snapshot_v1_default': '{corrupt',
      });
      final store = SecureBankSnapshotStore(const FlutterSecureStorage());
      final now = DateTime.utc(2026, 11, 24);

      final write = store.save(accounts: [], at: now);
      final read = store.read();
      await write.timeout(const Duration(seconds: 2));
      final snapshot = await read;

      expect(snapshot?.accounts, isEmpty);
      expect(snapshot?.accountsAt, now);
    },
  );
}
