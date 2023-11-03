import 'package:cli/cache/caches.dart';
import 'package:cli/cache/json_list_store.dart';
import 'package:collection/collection.dart';
import 'package:types/types.dart';

// Can't be immutable because Construction is not immutable.
/// A cached construction value or null known to be not under construction.
class ConstructionRecord {
  /// Creates a new construction record.
  ConstructionRecord({
    required this.waypointSymbol,
    required this.construction,
    required this.timestamp,
  });

  /// Creates a new construction record from JSON.
  factory ConstructionRecord.fromJson(Map<String, dynamic> json) {
    return ConstructionRecord(
      construction: Construction.fromJson(json['construction']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      waypointSymbol: WaypointSymbol.fromJson(json['waypointSymbol'] as String),
    );
  }

  /// The waypoint symbol.
  final WaypointSymbol waypointSymbol;

  /// The last time this record was updated.
  final DateTime timestamp;

  /// The construction value if under construction.
  final Construction? construction;

  /// Whether the waypoint is under construction.
  bool get isUnderConstruction => construction != null;

  /// Converts this object to a JSON encodable object.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'timestamp': timestamp.toIso8601String(),
        'construction': construction?.toJson(),
        'waypointSymbol': waypointSymbol.toJson(),
      };
}

/// A cached of construction values from Waypoints.
class ConstructionCache extends JsonListStore<ConstructionRecord> {
  /// Creates a new construction cache.
  ConstructionCache(
    super.records, {
    required super.fs,
    super.path = defaultCacheFilePath,
  });

  /// Load the Construction values from the cache.
  factory ConstructionCache.load(
    FileSystem fs, {
    String path = defaultCacheFilePath,
  }) {
    final records = JsonListStore.load<ConstructionRecord>(
          fs,
          path,
          ConstructionRecord.fromJson,
        ) ??
        [];
    return ConstructionCache(records, fs: fs, path: path);
  }

  /// The default path to the cache file.
  static const String defaultCacheFilePath = 'data/construction.json';

  /// The Construction values.
  List<ConstructionRecord> get values => entries;

  /// The number of waypoints in the cache.
  int get waypointCount => values.length;

  /// Adds a construction to the cache.
  void recordConstruction({
    required WaypointSymbol waypointSymbol,
    required Construction? construction,
    DateTime Function() getNow = defaultGetNow,
  }) {
    final index = entries.indexWhere(
      (record) => record.waypointSymbol == waypointSymbol,
    );

    final newRecord = ConstructionRecord(
      waypointSymbol: waypointSymbol,
      construction: construction,
      timestamp: getNow(),
    );
    if (index >= 0) {
      entries[index] = newRecord;
    } else {
      entries.add(newRecord);
    }

    save();
  }

  /// Returns all the waypointSymbols under construction.
  Iterable<WaypointSymbol> waypointSymbolsUnderConstruction() => values
      .where((record) => record.isUnderConstruction)
      .map((record) => record.waypointSymbol);

  /// Returns true if the given waypoint symbol is under construction.
  /// Returns false if the given waypoint symbol is not under construction.
  /// Returns null if the given waypoint symbol is not in the cache.
  bool? isUnderConstruction(WaypointSymbol waypointSymbol) =>
      recordForSymbol(waypointSymbol)?.isUnderConstruction;

  /// Gets the Construction for the given waypoint symbol.
  ConstructionRecord? recordForSymbol(WaypointSymbol waypointSymbol) =>
      values.firstWhereOrNull(
        (record) => record.waypointSymbol == waypointSymbol,
      );

  /// Returns the age of the cache for a given waypoint.
  Duration? cacheAgeFor(
    WaypointSymbol waypointSymbol, {
    DateTime Function() getNow = defaultGetNow,
  }) {
    final record = recordForSymbol(waypointSymbol);
    if (record == null) {
      return null;
    }
    return getNow().difference(record.timestamp);
  }
}
