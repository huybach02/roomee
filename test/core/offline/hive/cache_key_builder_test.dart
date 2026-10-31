import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/offline/hive/cache_key_builder.dart';

void main() {
  test('builds account-scoped entity keys for UUID accounts', () {
    expect(
      CacheKeyBuilder.entity('account-uuid', 42),
      'account:account-uuid:42',
    );
  });

  test('builds metadata and global keys', () {
    expect(
      CacheKeyBuilder.metadata('account-uuid', 'workspace'),
      'account-uuid:workspace',
    );
    expect(CacheKeyBuilder.global(92), 'global:92');
  });
}
