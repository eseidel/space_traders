import 'package:db/db.dart';
import 'package:types/types.dart';

/// A Store of static data that does not typically change between resets.
abstract class StaticStore<Symbol extends Object, Record extends Object> {
  /// Creates a new static Store.
  StaticStore(Database db, Traits<Symbol, Record> traits)
    : _db = db,
      _traits = traits;

  final Database _db;
  final Traits<Symbol, Record> _traits;

  /// The key for the given record.
  Symbol keyFor(Record record) => _traits.keyFor(record);

  /// Copy and normalize the record for comparison and storage.
  Record copyAndNormalize(Record record) => _traits.copyAndNormalize(record);

  /// Compare two records.
  int compare(Record a, Record b) => _traits.compare(a, b);

  /// Used for writing to a JSON file.
  Future<List<Json>> asSortedJsonList() async {
    final records = await getAll();
    final sorted = records.toList()..sort(compare);
    return sorted.map(_traits.toJson).toList();
  }

  /// Get a record from the Store.
  Future<Record?> get(Symbol key) async {
    final record = await _db.getFromStaticCache(
      type: Record,
      key: key.toString(),
    );
    if (record == null) {
      return null;
    }
    return _traits.fromJson(record);
  }

  /// Create a snapshot of the Store.
  Future<StaticSnapshot<Symbol, Record>> snapshot();

  /// Get all records from the Store.
  Future<List<Record>> getAll() async {
    final records = await _db.getAllFromStaticCache(type: Record);
    return records.map(_traits.fromJson).toList();
  }

  /// Adds a record to the Store.
  Future<void> add(Record value) async {
    final json = _traits.toJson(_traits.copyAndNormalize(value));
    await _db.upsertInStaticCache(
      type: Record,
      key: keyFor(value).toString(),
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
class ShipMountStore extends StaticStore<ShipMountSymbolEnum, ShipMount> {
  /// Creates a new ship mount Store.
  ShipMountStore(Database db) : super(db, ShipMountTraits());

  @override
  Future<ShipMountSnapshot> snapshot() async =>
      ShipMountSnapshot(await getAll());
}

/// A Store of ship modules.
class ShipModuleStore extends StaticStore<ShipModuleSymbolEnum, ShipModule> {
  /// Creates a new ship module Store.
  ShipModuleStore(Database db) : super(db, ShipModuleTraits());

  @override
  Future<ShipModuleSnapshot> snapshot() async =>
      ShipModuleSnapshot(await getAll());
}

/// A Store of shipyard ships.
class ShipyardShipStore extends StaticStore<ShipType, ShipyardShip> {
  /// Creates a new shipyard ship Store.
  ShipyardShipStore(Database db) : super(db, ShipyardShipTraits());

  @override
  Future<ShipyardShipSnapshot> snapshot() async =>
      ShipyardShipSnapshot(await getAll());
}

/// A Store of ship engines.
class ShipEngineStore extends StaticStore<ShipEngineSymbolEnum, ShipEngine> {
  /// Creates a new ship engine Store.
  ShipEngineStore(Database db) : super(db, ShipEngineTraits());

  @override
  Future<ShipEngineSnapshot> snapshot() async =>
      ShipEngineSnapshot(await getAll());
}

/// A Store of ship reactors.
class ShipReactorStore extends StaticStore<ShipReactorSymbolEnum, ShipReactor> {
  /// Creates a new ship reactor Store.
  ShipReactorStore(Database db) : super(db, ShipReactorTraits());

  @override
  Future<ShipReactorSnapshot> snapshot() async =>
      ShipReactorSnapshot(await getAll());
}

/// A Store of waypoint traits.
class WaypointTraitStore
    extends StaticStore<WaypointTraitSymbol, WaypointTrait> {
  /// Creates a new waypoint trait Store.
  WaypointTraitStore(Database db) : super(db, WaypointTraitTraits());

  @override
  Future<WaypointTraitSnapshot> snapshot() async =>
      WaypointTraitSnapshot(await getAll());
}

/// A Store of trade goods.
class TradeGoodStore extends StaticStore<TradeSymbol, TradeGood> {
  /// Creates a new waypoint trait Store.
  TradeGoodStore(Database db) : super(db, TradeGoodTraits());

  @override
  Future<TradeGoodSnapshot> snapshot() async =>
      TradeGoodSnapshot(await getAll());
}

/// A Store of trade exports.
class TradeExportStore extends StaticStore<TradeSymbol, TradeExport> {
  /// Creates a new waypoint trait Store.
  TradeExportStore(Database db) : super(db, TradeExportTraits());

  @override
  Future<TradeExportSnapshot> snapshot() async =>
      TradeExportSnapshot(await getAll());
}

/// A Store of events.
class EventStore
    extends StaticStore<ShipConditionEventSymbolEnum, ShipConditionEvent> {
  /// Creates a new waypoint trait Store.
  EventStore(Database db) : super(db, EventTraits());

  @override
  Future<EventSnapshot> snapshot() async => EventSnapshot(await getAll());
}
