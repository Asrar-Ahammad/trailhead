import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';

/// Manages tile caching for flutter_map.
///
/// Uses [MemCacheStore] for session-level tile caching (no extra packages
/// required). Tiles fetched during a session are reused without re-fetching,
/// reducing data usage on repeated map interactions.
///
/// For persistent across-session tile caching a Hive or SQLite store can be
/// swapped in without changing any call-site code.
///
/// Call [MapTileCacheManager.instance.tileProvider] inside a [TileLayer].
class MapTileCacheManager {
  MapTileCacheManager._() {
    final store = MemCacheStore();
    _provider = CachedTileProvider(
      store: store,
      maxStale: const Duration(hours: 2),
    );
  }

  static final MapTileCacheManager instance = MapTileCacheManager._();

  late final CachedTileProvider _provider;

  /// Returns the tile provider for use in a flutter_map [TileLayer].
  CachedTileProvider get tileProvider => _provider;
}
