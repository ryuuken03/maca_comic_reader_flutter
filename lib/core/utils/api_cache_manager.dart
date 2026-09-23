
class _CacheEntry<T> {
  final T data;
  final DateTime expiry;

  _CacheEntry({required this.data, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// Simple, efficient in-memory TTL (Time-To-Live) cache manager.
/// Prevents redundant backend calls and reduces bot detection risks.
class ApiCacheManager {
  static final ApiCacheManager instance = ApiCacheManager._internal();
  ApiCacheManager._internal();

  final Map<String, _CacheEntry<dynamic>> _cache = {};

  /// Retrieve cached data if present and not expired.
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T?;
  }

  /// Store data in cache with a specified TTL.
  void set<T>(String key, T data, {Duration ttl = const Duration(minutes: 15)}) {
    _cache[key] = _CacheEntry<T>(
      data: data,
      expiry: DateTime.now().add(ttl),
    );
  }

  /// Invalidate/remove a specific key from cache.
  void invalidate(String key) {
    _cache.remove(key);
  }

  /// Invalidate keys that start with a specific prefix (e.g. 'series_').
  void invalidatePrefix(String prefix) {
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Clear all cached data.
  void clear() {
    _cache.clear();
  }
}
