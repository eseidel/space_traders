import 'package:db/db.dart';
import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// A Store of static data that does not typically change between resets.
abstract class StaticStore<Symbol extends Object, Record extends Object> {
  /// Creates a new static Store.
  StaticStore(Database db, Traits<Symbol, Record> traits)
    : _db = db,
      _traits = traits;

  final Database _db;
  final Traits<Symbol, Record> _traits;

  /// Get static data of type [type] and key [key] from the static_data_ table.
  /// Returns null if not found.
  Future<Map<String, dynamic>?> _getFromStaticCache({
    required Type type,
    required String key,
  }) async {
    final result = await _db.queryOne(
      Query(
        'SELECT json FROM static_data_ WHERE type = @type AND key = @key',
        parameters: {'type': type.toString(), 'key': key},
      ),
      (map) => map['json'] as Map<String, dynamic>,
    );
    return result;
  }

  /// Get all static data of type [type] from the static_data_ table.
  /// Returns an empty list if not found.
  Future<Iterable<Map<String, dynamic>>> _getAllFromStaticCache({
    required Type type,
  }) async {
    final result = await _db.queryMany(
      Query(
        'SELECT json FROM static_data_ WHERE type = @type',
        parameters: {'type': type.toString()},
      ),
      (map) => map['json'] as Map<String, dynamic>,
    );
    return result;
  }

  /// Upsert static data of type [type] and key [key] into the
  /// static_data_ table.
  /// If the data already exists, it will be updated.
  Future<void> _upsertInStaticCache({
    required Type type,
    required String key,
    required Map<String, dynamic> json,
    // Reset is intended to store which reset the data was created in.
    // But we've not wired it up yet.
    String reset = '1',
  }) async {
    await _db.execute(
      Query(
        'INSERT INTO static_data_ (type, key, reset, json) '
        'VALUES (@type, @key, @reset, @json) '
        'ON CONFLICT (type, key) DO UPDATE SET json = EXCLUDED.json',
        parameters: {
          'type': type.toString(),
          'key': key,
          'json': json,
          'reset': reset,
        },
      ),
    );
  }

  /// Used for writing to a JSON file.
  Future<List<Json>> asSortedJsonList() async {
    final records = await all();
    final sorted = records.toList()..sort(_traits.compare);
    return sorted.map(_traits.toJson).toList();
  }

  /// Get a record from the Store.
  Future<Record?> get(Symbol key) async {
    final record = await _getFromStaticCache(type: Record, key: key.toString());
    if (record == null) {
      return null;
    }
    return _traits.fromJson(record);
  }

  /// Create a snapshot of the Store.
  Future<StaticSnapshot<Symbol, Record>> snapshot();

  /// Get all records from the Store.
  Future<List<Record>> all() async {
    final records = await _getAllFromStaticCache(type: Record);
    return records.map(_traits.fromJson).toList();
  }

  /// Adds a record to the Store.
  Future<void> add(Record value) async {
    final json = _traits.toJson(_traits.copyAndNormalize(value));
    await _upsertInStaticCache(
      type: Record,
      key: _traits.keyFor(value).toString(),
      json: json,
    );
  }

  /// Adds a list of values to the Store.
  Future<void> addAll(Iterable<Record> values) async {
    for (final value in values) {
      await add(value);
    }
  }
}

/// A Store of ship mounts.
class ShipMountStore extends StaticStore<ShipMountSymbol, ShipMount> {
  /// Creates a new ship mount Store.
  ShipMountStore(Database db) : super(db, ShipMountTraits());

  @override
  Future<ShipMountSnapshot> snapshot() async => ShipMountSnapshot(await all());
}

/// A Store of ship modules.
class ShipModuleStore extends StaticStore<ShipModuleSymbol, ShipModule> {
  /// Creates a new ship module Store.
  ShipModuleStore(Database db) : super(db, ShipModuleTraits());

  @override
  Future<ShipModuleSnapshot> snapshot() async =>
      ShipModuleSnapshot(await all());
}

/// A Store of shipyard ships.
class ShipyardShipStore extends StaticStore<ShipType, ShipyardShip> {
  /// Creates a new shipyard ship Store.
  ShipyardShipStore(Database db) : super(db, ShipyardShipTraits());

  @override
  Future<ShipyardShipSnapshot> snapshot() async =>
      ShipyardShipSnapshot(await all());
}

/// A Store of ship engines.
class ShipEngineStore extends StaticStore<ShipEngineSymbol, ShipEngine> {
  /// Creates a new ship engine Store.
  ShipEngineStore(Database db) : super(db, ShipEngineTraits());

  @override
  Future<ShipEngineSnapshot> snapshot() async =>
      ShipEngineSnapshot(await all());
}

/// A Store of ship reactors.
class ShipReactorStore extends StaticStore<ShipReactorSymbol, ShipReactor> {
  /// Creates a new ship reactor Store.
  ShipReactorStore(Database db) : super(db, ShipReactorTraits());

  @override
  Future<ShipReactorSnapshot> snapshot() async =>
      ShipReactorSnapshot(await all());
}

/// A Store of waypoint traits.
class WaypointTraitStore
    extends StaticStore<WaypointTraitSymbol, WaypointTrait> {
  /// Creates a new waypoint trait Store.
  WaypointTraitStore(Database db) : super(db, WaypointTraitTraits());

  @override
  Future<WaypointTraitSnapshot> snapshot() async =>
      WaypointTraitSnapshot(await all());
}

/// A Store of trade goods.
class TradeGoodStore extends StaticStore<TradeSymbol, TradeGood> {
  /// Creates a new waypoint trait Store.
  TradeGoodStore(Database db) : super(db, TradeGoodTraits());

  @override
  Future<TradeGoodSnapshot> snapshot() async => TradeGoodSnapshot(await all());
}

/// A Store of trade exports.
class TradeExportStore extends StaticStore<TradeSymbol, TradeExport> {
  /// Creates a new waypoint trait Store.
  TradeExportStore(Database db) : super(db, TradeExportTraits());

  @override
  Future<TradeExportSnapshot> snapshot() async =>
      TradeExportSnapshot(await all());
}

/// A Store of events.
class EventStore
    extends StaticStore<ShipConditionEventSymbol, ShipConditionEvent> {
  /// Creates a new waypoint trait Store.
  EventStore(Database db) : super(db, EventTraits());

  @override
  Future<EventSnapshot> snapshot() async => EventSnapshot(await all());
}
