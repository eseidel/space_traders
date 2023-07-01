import 'package:cli/api.dart';
import 'package:cli/cache/response_cache.dart';
import 'package:cli/net/queries.dart';
import 'package:file/file.dart';

/// On disk cache of factions.
class FactionCache extends ResponseListCache<Faction> {
  /// Creates a new faction cache.
  FactionCache(
    super.contracts, {
    // Factions should never change.
    super.checkEvery = 10000,
    super.fs,
    super.path = defaultPath,
  }) : super(
          entryToJson: (c) => c.toJson(),
          refreshEntries: (Api api) => getAllFactions(api).toList(),
        );

  /// Creates a new FactionCache from the Api or FileSystem if provided.
  static Future<FactionCache> load(
    Api api, {
    FileSystem? fs,
    String path = defaultPath,
  }) async {
    if (fs != null && await fs.isFile(path)) {
      final factions = await ResponseListCache.load<Faction>(
        fs,
        path,
        (j) => Faction.fromJson(j)!,
      );
      return FactionCache(factions, fs: fs, path: path);
    }
    final factions = await getAllFactions(api).toList();
    return FactionCache(factions, fs: fs, path: path);
  }

  /// The default path to the factions cache.
  static const String defaultPath = 'factions.json';

  /// Factions in the cache.
  List<Faction> get factions => entries;
}
