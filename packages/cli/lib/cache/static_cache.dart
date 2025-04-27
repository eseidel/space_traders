// Cache for server static data that does not typically change
// between resets and thus can be checked into source control.

import 'package:db/db.dart';
import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// A type alias for a JSON object.
typedef Json = Map<String, dynamic>;

/// Class that defines the traits of a record in a static cache.
abstract class Traits<Symbol extends Object, Record extends Object> {
  /// Creates a new traits.
  const Traits();

  /// The key for the given record.
  Symbol keyFor(Record record);

  /// Copy and normalize the record for comparison and storage.
  /// Subclasses should override this method to provide nomalization.
  /// The default implementation simply converts the record to JSON and back.
  Record copyAndNormalize(Record record) => fromJson(toJson(record));

  /// Compare two records.
  int compare(Record a, Record b);

  /// Convert the record to normalized Json for storage.
  Json toJson(Record record);

  /// Convert a JSON object to a record.
  Record fromJson(Map<String, dynamic> json);
}

/// An in-memory snapshot of a static cache.
class StaticSnapshot<Symbol extends Object, Record extends Object> {
  /// Creates a new static cache.
  StaticSnapshot(this.records, Traits<Symbol, Record> traits)
    : _traits = traits;

  /// The records in this snapshot.
  final List<Record> records;
  final Traits<Symbol, Record> _traits;

  /// The key for the given record.
  Symbol keyFor(Record record) => _traits.keyFor(record);

  /// Copy and normalize the record for comparison and storage.
  Record copyAndNormalize(Record record) => _traits.copyAndNormalize(record);

  /// Compare two records.
  int compare(Record a, Record b) => _traits.compare(a, b);

  /// Get a record from the cache.
  Record? operator [](Symbol key) {
    for (final record in records) {
      if (keyFor(record) == key) {
        return record;
      }
    }
    return null;
  }
}

/// A cache of static data that does not typically change between resets and
/// thus can be checked into source control.
abstract class StaticCache<Symbol extends Object, Record extends Object> {
  /// Creates a new static cache.
  StaticCache(Database db, Traits<Symbol, Record> traits)
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

  /// Get a record from the cache.
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

  /// Create a snapshot of the cache.
  Future<StaticSnapshot<Symbol, Record>> snapshot();

  /// Get all records from the cache.
  Future<List<Record>> getAll() async {
    final records = await _db.getAllFromStaticCache(type: Record);
    return records.map(_traits.fromJson).toList();
  }

  /// Adds a record to the cache.
  Future<void> add(Record value) async {
    await _db.upsertInStaticCache(
      type: Record,
      key: keyFor(value).toString(),
      json: _traits.toJson(value),
    );
  }

  /// Adds a list of values to the cache.
  Future<void> addAll(Iterable<Record> values) async {
    for (final value in values) {
      await add(value);
    }
  }
}

class _ShipMountTraits extends Traits<ShipMountSymbolEnum, ShipMount> {
  @override
  ShipMount fromJson(Map<String, dynamic> json) => ShipMount.fromJson(json)!;

  @override
  Json toJson(ShipMount record) => record.toJson();

  @override
  int compare(ShipMount a, ShipMount b) =>
      a.symbol.value.compareTo(b.symbol.value);

  @override
  ShipMountSymbolEnum keyFor(ShipMount record) => record.symbol;
}

/// A snapshot of ship mounts.
class ShipMountSnapshot extends StaticSnapshot<ShipMountSymbolEnum, ShipMount> {
  /// Creates a new ship mount snapshot.
  ShipMountSnapshot(List<ShipMount> records)
    : super(records, _ShipMountTraits());
}

/// A cache of ship mounts.
class ShipMountCache extends StaticCache<ShipMountSymbolEnum, ShipMount> {
  /// Creates a new ship mount cache.
  ShipMountCache(Database db) : super(db, _ShipMountTraits());

  @override
  Future<ShipMountSnapshot> snapshot() async =>
      ShipMountSnapshot(await getAll());
}

/// A cache of ship modules.
class _ShipModuleTraits extends Traits<ShipModuleSymbolEnum, ShipModule> {
  @override
  ShipModule fromJson(Map<String, dynamic> json) {
    return ShipModule.fromJson(json)!;
  }

  @override
  Json toJson(ShipModule record) => record.toJson();

  @override
  int compare(ShipModule a, ShipModule b) =>
      a.symbol.value.compareTo(b.symbol.value);

  @override
  ShipModuleSymbolEnum keyFor(ShipModule record) => record.symbol;
}

/// A snapshot of ship modules.
class ShipModuleSnapshot
    extends StaticSnapshot<ShipModuleSymbolEnum, ShipModule> {
  /// Creates a new ship module snapshot.
  ShipModuleSnapshot(List<ShipModule> records)
    : super(records, _ShipModuleTraits());
}

/// A cache of ship modules.
class ShipModuleCache extends StaticCache<ShipModuleSymbolEnum, ShipModule> {
  /// Creates a new ship module cache.
  ShipModuleCache(Database db) : super(db, _ShipModuleTraits());

  @override
  Future<ShipModuleSnapshot> snapshot() async =>
      ShipModuleSnapshot(await getAll());
}

/// A cache of shipyard ships.
class _ShipyardShipTraits extends Traits<ShipType, ShipyardShip> {
  @override
  ShipyardShip fromJson(Map<String, dynamic> json) =>
      ShipyardShip.fromJson(json)!;

  @override
  Json toJson(ShipyardShip record) => record.toJson();

  @override
  ShipyardShip copyAndNormalize(ShipyardShip record) {
    return fromJson(toJson(record))
      ..purchasePrice = 0
      ..activity = null
      ..supply = SupplyLevel.ABUNDANT
      ..frame.condition = 1.0;
  }

  @override
  int compare(ShipyardShip a, ShipyardShip b) =>
      a.type.value.compareTo(b.type.value);

  @override
  ShipType keyFor(ShipyardShip record) => record.type;
}

/// A snapshot of Shipyard Ships
class ShipyardShipSnapshot extends StaticSnapshot<ShipType, ShipyardShip> {
  /// Creates a new shipyard ship snapshot.
  ShipyardShipSnapshot(List<ShipyardShip> records)
    : super(records, _ShipyardShipTraits());
}

/// A cache of shipyard ships.
class ShipyardShipCache extends StaticCache<ShipType, ShipyardShip> {
  /// Creates a new shipyard ship cache.
  ShipyardShipCache(Database db) : super(db, _ShipyardShipTraits());

  @override
  Future<ShipyardShipSnapshot> snapshot() async =>
      ShipyardShipSnapshot(await getAll());
}

/// A cache of ship engines.
class _ShipEngineTraits extends Traits<ShipEngineSymbolEnum, ShipEngine> {
  @override
  Json toJson(ShipEngine record) => record.toJson();
  @override
  ShipEngine fromJson(Map<String, dynamic> json) => ShipEngine.fromJson(json)!;

  @override
  ShipEngine copyAndNormalize(ShipEngine record) =>
      fromJson(toJson(record))..condition = 1.0;

  @override
  int compare(ShipEngine a, ShipEngine b) =>
      a.symbol.value.compareTo(b.symbol.value);

  @override
  ShipEngineSymbolEnum keyFor(ShipEngine record) => record.symbol;
}

/// A snapshot of ship engines.
class ShipEngineSnapshot
    extends StaticSnapshot<ShipEngineSymbolEnum, ShipEngine> {
  /// Creates a new ship engine snapshot.
  ShipEngineSnapshot(List<ShipEngine> records)
    : super(records, _ShipEngineTraits());
}

/// A cache of ship engines.
class ShipEngineCache extends StaticCache<ShipEngineSymbolEnum, ShipEngine> {
  /// Creates a new ship engine cache.
  ShipEngineCache(Database db) : super(db, _ShipEngineTraits());

  @override
  Future<ShipEngineSnapshot> snapshot() async =>
      ShipEngineSnapshot(await getAll());
}

/// A cache of ship reactors.
class _ShipReactorTraits extends Traits<ShipReactorSymbolEnum, ShipReactor> {
  @override
  ShipReactor fromJson(Map<String, dynamic> json) =>
      ShipReactor.fromJson(json)!;

  @override
  Json toJson(ShipReactor record) => record.toJson();

  @override
  ShipReactor copyAndNormalize(ShipReactor record) =>
      fromJson(toJson(record))..condition = 1.0;

  @override
  int compare(ShipReactor a, ShipReactor b) =>
      a.symbol.value.compareTo(b.symbol.value);

  @override
  ShipReactorSymbolEnum keyFor(ShipReactor record) => record.symbol;
}

/// A snapshot of ship reactors.
class ShipReactorSnapshot
    extends StaticSnapshot<ShipReactorSymbolEnum, ShipReactor> {
  /// Creates a new ship reactor snapshot.
  ShipReactorSnapshot(List<ShipReactor> records)
    : super(records, _ShipReactorTraits());
}

/// A cache of ship reactors.
class ShipReactorCache extends StaticCache<ShipReactorSymbolEnum, ShipReactor> {
  /// Creates a new ship reactor cache.
  ShipReactorCache(Database db) : super(db, _ShipReactorTraits());

  @override
  Future<ShipReactorSnapshot> snapshot() async =>
      ShipReactorSnapshot(await getAll());
}

/// A cache of waypoint traits.
class _WaypointTraitTraits extends Traits<WaypointTraitSymbol, WaypointTrait> {
  @override
  WaypointTrait fromJson(Map<String, dynamic> json) =>
      WaypointTrait.fromJson(json)!;
  @override
  Json toJson(WaypointTrait record) => record.toJson();

  @override
  int compare(WaypointTrait a, WaypointTrait b) =>
      a.symbol.value.compareTo(b.symbol.value);

  @override
  WaypointTraitSymbol keyFor(WaypointTrait record) => record.symbol;
}

/// A snapshot of waypoint traits.
class WaypointTraitSnapshot
    extends StaticSnapshot<WaypointTraitSymbol, WaypointTrait> {
  /// Creates a new waypoint trait snapshot.
  WaypointTraitSnapshot(List<WaypointTrait> records)
    : super(records, _WaypointTraitTraits());
}

/// A cache of waypoint traits.
class WaypointTraitCache
    extends StaticCache<WaypointTraitSymbol, WaypointTrait> {
  /// Creates a new waypoint trait cache.
  WaypointTraitCache(Database db) : super(db, _WaypointTraitTraits());

  @override
  Future<WaypointTraitSnapshot> snapshot() async =>
      WaypointTraitSnapshot(await getAll());
}

/// A cache of trade good descriptions.
class _TradeGoodTraits extends Traits<TradeSymbol, TradeGood> {
  @override
  TradeGood fromJson(Map<String, dynamic> json) => TradeGood.fromJson(json)!;
  @override
  Json toJson(TradeGood record) => record.toJson();

  @override
  int compare(TradeGood a, TradeGood b) =>
      a.symbol.value.compareTo(b.symbol.value);

  @override
  TradeSymbol keyFor(TradeGood record) => record.symbol;
}

/// A snapshot of trade goods.
class TradeGoodSnapshot extends StaticSnapshot<TradeSymbol, TradeGood> {
  /// Creates a new trade good snapshot.
  TradeGoodSnapshot(List<TradeGood> records)
    : super(records, _TradeGoodTraits());
}

/// A cache of trade goods.
class TradeGoodCache extends StaticCache<TradeSymbol, TradeGood> {
  /// Creates a new waypoint trait cache.
  TradeGoodCache(Database db) : super(db, _TradeGoodTraits());

  @override
  Future<TradeGoodSnapshot> snapshot() async =>
      TradeGoodSnapshot(await getAll());
}

/// A cache of trade good descriptions.
class _TradeExportTraits extends Traits<TradeSymbol, TradeExport> {
  @override
  TradeExport fromJson(Map<String, dynamic> json) => TradeExport.fromJson(json);
  @override
  Json toJson(TradeExport record) => record.toJson();

  @override
  int compare(TradeExport a, TradeExport b) =>
      a.export.value.compareTo(b.export.value);

  @override
  TradeSymbol keyFor(TradeExport record) => record.export;
}

/// A snapshot of trade exports.
class TradeExportSnapshot extends StaticSnapshot<TradeSymbol, TradeExport> {
  /// Creates a new trade export snapshot.
  TradeExportSnapshot(List<TradeExport> records)
    : super(records, _TradeExportTraits());
}

/// A cache of trade exports.
class TradeExportCache extends StaticCache<TradeSymbol, TradeExport> {
  /// Creates a new waypoint trait cache.
  TradeExportCache(Database db) : super(db, _TradeExportTraits());

  @override
  Future<TradeExportSnapshot> snapshot() async =>
      TradeExportSnapshot(await getAll());
}

/// A cache of event descriptions.
class _EventTraits
    extends Traits<ShipConditionEventSymbolEnum, ShipConditionEvent> {
  @override
  ShipConditionEvent fromJson(Map<String, dynamic> json) =>
      ShipConditionEvent.fromJson(json)!;
  @override
  Json toJson(ShipConditionEvent record) => record.toJson();

  @override
  int compare(ShipConditionEvent a, ShipConditionEvent b) =>
      a.symbol.value.compareTo(b.symbol.value);

  @override
  ShipConditionEventSymbolEnum keyFor(ShipConditionEvent record) =>
      record.symbol;
}

/// A snapshot of events.
class EventSnapshot
    extends StaticSnapshot<ShipConditionEventSymbolEnum, ShipConditionEvent> {
  /// Creates a new event snapshot.
  EventSnapshot(List<ShipConditionEvent> records)
    : super(records, _EventTraits());
}

/// A cache of events.
class EventCache
    extends StaticCache<ShipConditionEventSymbolEnum, ShipConditionEvent> {
  /// Creates a new waypoint trait cache.
  EventCache(Database db) : super(db, _EventTraits());

  @override
  Future<EventSnapshot> snapshot() async => EventSnapshot(await getAll());
}

/// Caches of static server data that does not typically change between
/// resets and thus can be checked into source control.
class StaticCaches {
  /// Creates a new static caches.
  StaticCaches(Database db)
    : mounts = ShipMountCache(db),
      modules = ShipModuleCache(db),
      shipyardShips = ShipyardShipCache(db),
      engines = ShipEngineCache(db),
      reactors = ShipReactorCache(db),
      waypointTraits = WaypointTraitCache(db),
      tradeGoods = TradeGoodCache(db),
      exports = TradeExportCache(db),
      events = EventCache(db);

  /// Creates a new static caches for testing.
  @visibleForTesting
  StaticCaches.test({
    required this.mounts,
    required this.modules,
    required this.shipyardShips,
    required this.engines,
    required this.reactors,
    required this.waypointTraits,
    required this.tradeGoods,
    required this.exports,
    required this.events,
  });

  /// The ship mount cache.
  final ShipMountCache mounts;

  /// The ship module cache.
  final ShipModuleCache modules;

  /// The shipyard ship cache.
  final ShipyardShipCache shipyardShips;

  /// The ship engine cache.
  final ShipEngineCache engines;

  /// The ship reactor cache.
  final ShipReactorCache reactors;

  /// The waypoint trait cache.
  final WaypointTraitCache waypointTraits;

  /// The trade good cache.
  final TradeGoodCache tradeGoods;

  /// Cache mapping exports to needed imports.
  final TradeExportCache exports;

  /// Cache of event names and descriptions.
  final EventCache events;
}

/// Records ShipyardShips and their components into the caches.
void recordShipyardShips(StaticCaches staticCaches, List<ShipyardShip> ships) {
  staticCaches.shipyardShips.addAll(ships);
  for (final ship in ships) {
    staticCaches.mounts.addAll(ship.mounts);
    staticCaches.modules.addAll(ship.modules);
    staticCaches.engines.add(ship.engine);
    staticCaches.reactors.add(ship.reactor);
  }
}

/// Records a Ship's components into the caches.
void recordShip(StaticCaches staticCaches, Ship ship) {
  staticCaches.mounts.addAll(ship.mounts);
  staticCaches.modules.addAll(ship.modules);
  staticCaches.engines.add(ship.engine);
  staticCaches.reactors.add(ship.reactor);
}
