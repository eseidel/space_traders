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

  /// Creates a new FactionCache from the cache if possible.
  static FactionCache? loadFromCache(
    FileSystem fs, {
    String path = defaultPath,
  }) {
    final factions = ResponseListCache.load<Faction>(
      fs,
      path,
      (j) => Faction.fromJson(j)!,
    );
    if (factions == null) {
      return null;
    }
    return FactionCache(factions, fs: fs, path: path);
  }

  /// Creates a new FactionCache from the Api or FileSystem if provided.
  static Future<FactionCache> load(
    Api api, {
    FileSystem? fs,
    String path = defaultPath,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && fs != null && await fs.isFile(path)) {
      final factions = ResponseListCache.load<Faction>(
        fs,
        path,
        (j) => Faction.fromJson(j)!,
      );
      if (factions != null) {
        return FactionCache(factions, fs: fs, path: path);
      }
    }
    final factions = await getAllFactions(api).toList();
    return FactionCache(factions, fs: fs, path: path);
  }

  /// The default path to the factions cache.
  static const String defaultPath = 'data/factions.json';

  /// Factions in the cache.
  List<Faction> get factions => entries;

  /// Gets the faction with the given symbol.
  Faction factionBySymbol(FactionSymbols symbol) =>
      factions.firstWhere((f) => f.symbol == symbol);
}
