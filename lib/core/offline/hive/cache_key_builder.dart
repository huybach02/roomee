abstract final class CacheKeyBuilder {
  static String entity(String accountId, Object entityId) {
    return 'account:$accountId:$entityId';
  }

  static String metadata(String accountId, String entityName) {
    return '$accountId:$entityName';
  }

  static String global(Object id) {
    return 'global:$id';
  }
}
