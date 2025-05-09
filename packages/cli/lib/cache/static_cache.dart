// Cache for server static data that does not typically change
// between resets and thus can be checked into source control.

import 'package:db/db.dart';
import 'package:meta/meta.dart';
import 'package:types/types.dart';

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
    final json = _traits.toJson(_traits.copyAndNormalize(value));
    await _db.upsertInStaticCache(
      type: Record,
      key: keyFor(value).toString(),
      json: json,
    );
  }

  /// Adds a list of values to the cache.
  Future<void> addAll(Iterable<Record> values) async {
    for (final value in values) {
      await add(value);
    }
  }
}

/// A cache of ship mounts.
class ShipMountCache extends StaticCache<ShipMountSymbolEnum, ShipMount> {
  /// Creates a new ship mount cache.
  ShipMountCache(Database db) : super(db, ShipMountTraits());

  @override
  Future<ShipMountSnapshot> snapshot() async =>
      ShipMountSnapshot(await getAll());
}

/// A cache of ship modules.
class ShipModuleCache extends StaticCache<ShipModuleSymbolEnum, ShipModule> {
  /// Creates a new ship module cache.
  ShipModuleCache(Database db) : super(db, ShipModuleTraits());

  @override
  Future<ShipModuleSnapshot> snapshot() async =>
      ShipModuleSnapshot(await getAll());
}

/// A cache of shipyard ships.
class ShipyardShipCache extends StaticCache<ShipType, ShipyardShip> {
  /// Creates a new shipyard ship cache.
  ShipyardShipCache(Database db) : super(db, ShipyardShipTraits());

  @override
  Future<ShipyardShipSnapshot> snapshot() async =>
      ShipyardShipSnapshot(await getAll());
}

/// A cache of ship engines.
class ShipEngineCache extends StaticCache<ShipEngineSymbolEnum, ShipEngine> {
  /// Creates a new ship engine cache.
  ShipEngineCache(Database db) : super(db, ShipEngineTraits());

  @override
  Future<ShipEngineSnapshot> snapshot() async =>
      ShipEngineSnapshot(await getAll());
}

/// A cache of ship reactors.
class ShipReactorCache extends StaticCache<ShipReactorSymbolEnum, ShipReactor> {
  /// Creates a new ship reactor cache.
  ShipReactorCache(Database db) : super(db, ShipReactorTraits());

  @override
  Future<ShipReactorSnapshot> snapshot() async =>
      ShipReactorSnapshot(await getAll());
}

/// A cache of waypoint traits.
class WaypointTraitCache
    extends StaticCache<WaypointTraitSymbol, WaypointTrait> {
  /// Creates a new waypoint trait cache.
  WaypointTraitCache(Database db) : super(db, WaypointTraitTraits());

  @override
  Future<WaypointTraitSnapshot> snapshot() async =>
      WaypointTraitSnapshot(await getAll());
}

/// A cache of trade goods.
class TradeGoodCache extends StaticCache<TradeSymbol, TradeGood> {
  /// Creates a new waypoint trait cache.
  TradeGoodCache(Database db) : super(db, TradeGoodTraits());

  @override
  Future<TradeGoodSnapshot> snapshot() async =>
      TradeGoodSnapshot(await getAll());
}

/// A cache of trade exports.
class TradeExportCache extends StaticCache<TradeSymbol, TradeExport> {
  /// Creates a new waypoint trait cache.
  TradeExportCache(Database db) : super(db, TradeExportTraits());

  @override
  Future<TradeExportSnapshot> snapshot() async =>
      TradeExportSnapshot(await getAll());
}

/// A cache of events.
class EventCache
    extends StaticCache<ShipConditionEventSymbolEnum, ShipConditionEvent> {
  /// Creates a new waypoint trait cache.
  EventCache(Database db) : super(db, EventTraits());

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

/// Log the adverse events in the given [events].
void recordEvents(Database db, Ship ship, List<ShipConditionEvent> events) {
  if (events.isEmpty) {
    return;
  }
  // TODO(eseidel): Queue the ship for update if it had events.
  // Responses containing events don't return the ship parts effected, so
  // we'd need to queue a full update of the ship to get the condition changes.
  EventCache(db).addAll(events);
}
