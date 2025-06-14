// Cache for server static data that does not typically change
// between resets and thus can be checked into source control.

import 'dart:convert';

import 'package:types/types.dart';

/// Class that defines the traits of a record in a static cache.
abstract class Traits<Symbol extends Object, Record extends Object> {
  /// Creates a new traits.
  const Traits();

  /// The key for the given record.
  Symbol keyFor(Record record);

  /// Copy and normalize the record for comparison and storage.
  /// Subclasses should override this method to provide normalization.
  /// The default implementation simply converts the record to JSON and back.
  Record copyAndNormalize(Record record) => deepCopy(record);

  /// Create a deep copy of the record.
  Record deepCopy(Record record) {
    // OpenAPI doesn't properly recurse toJson, so we do an explicit jsonEncode
    // and jsonDecode to force everything to be converted.
    // TODO(eseidel): We could do this *only* for OpenAPI records.
    return fromJson(
      jsonDecode(jsonEncode(toJson(record))) as Map<String, dynamic>,
    );
  }

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

  /// The number of records in this snapshot.
  int get length => records.length;

  /// Copy and normalize the record for comparison and storage.
  Record copyAndNormalize(Record record) => _traits.copyAndNormalize(record);

  /// Get a record from the cache.
  Record? operator [](Symbol key) {
    for (final record in records) {
      if (_traits.keyFor(record) == key) {
        return record;
      }
    }
    return null;
  }
}

/// Traits for ShipMounts.
class ShipMountTraits extends Traits<ShipMountSymbol, ShipMount> {
  @override
  ShipMount fromJson(Map<String, dynamic> json) => ShipMount.fromJson(json);

  @override
  Json toJson(ShipMount record) => record.toJson();

  @override
  int compare(ShipMount a, ShipMount b) =>
      a.symbol.value.compareTo(b.symbol.value);

  @override
  ShipMountSymbol keyFor(ShipMount record) => record.symbol;
}

/// A snapshot of ship mounts.
class ShipMountSnapshot extends StaticSnapshot<ShipMountSymbol, ShipMount> {
  /// Creates a new ship mount snapshot.
  ShipMountSnapshot(List<ShipMount> records)
    : super(records, ShipMountTraits());
}

/// A cache of ship modules.
class ShipModuleTraits extends Traits<ShipModuleSymbol, ShipModule> {
  @override
  ShipModule fromJson(Map<String, dynamic> json) {
    return ShipModule.fromJson(json);
  }

  @override
  Json toJson(ShipModule record) => record.toJson();

  @override
  int compare(ShipModule a, ShipModule b) =>
      a.symbol.value.compareTo(b.symbol.value);

  @override
  ShipModuleSymbol keyFor(ShipModule record) => record.symbol;
}

/// A snapshot of ship modules.
class ShipModuleSnapshot extends StaticSnapshot<ShipModuleSymbol, ShipModule> {
  /// Creates a new ship module snapshot.
  ShipModuleSnapshot(List<ShipModule> records)
    : super(records, ShipModuleTraits());
}

/// Traits for ShipyardShips.
class ShipyardShipTraits extends Traits<ShipType, ShipyardShip> {
  @override
  ShipyardShip fromJson(Map<String, dynamic> json) =>
      ShipyardShip.fromJson(json);

  @override
  Json toJson(ShipyardShip record) => record.toJson();

  @override
  ShipyardShip copyAndNormalize(ShipyardShip record) {
    return deepCopy(record)
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
    : super(records, ShipyardShipTraits());
}

/// Traits for ShipEngines.
class ShipEngineTraits extends Traits<ShipEngineSymbol, ShipEngine> {
  @override
  Json toJson(ShipEngine record) => record.toJson();

  @override
  ShipEngine fromJson(Map<String, dynamic> json) => ShipEngine.fromJson(json);

  @override
  ShipEngine copyAndNormalize(ShipEngine record) =>
      deepCopy(record)..condition = 1.0;

  @override
  int compare(ShipEngine a, ShipEngine b) =>
      a.symbol.value.compareTo(b.symbol.value);

  @override
  ShipEngineSymbol keyFor(ShipEngine record) => record.symbol;
}

/// A snapshot of ship engines.
class ShipEngineSnapshot extends StaticSnapshot<ShipEngineSymbol, ShipEngine> {
  /// Creates a new ship engine snapshot.
  ShipEngineSnapshot(List<ShipEngine> records)
    : super(records, ShipEngineTraits());
}

/// Traits for ShipReactors.
class ShipReactorTraits extends Traits<ShipReactorSymbol, ShipReactor> {
  @override
  ShipReactor fromJson(Map<String, dynamic> json) => ShipReactor.fromJson(json);

  @override
  Json toJson(ShipReactor record) => record.toJson();

  @override
  ShipReactor copyAndNormalize(ShipReactor record) =>
      deepCopy(record)..condition = 1.0;

  @override
  int compare(ShipReactor a, ShipReactor b) =>
      a.symbol.value.compareTo(b.symbol.value);

  @override
  ShipReactorSymbol keyFor(ShipReactor record) => record.symbol;
}

/// A snapshot of ship reactors.
class ShipReactorSnapshot
    extends StaticSnapshot<ShipReactorSymbol, ShipReactor> {
  /// Creates a new ship reactor snapshot.
  ShipReactorSnapshot(List<ShipReactor> records)
    : super(records, ShipReactorTraits());
}

/// Traits for WaypointTraits.
class WaypointTraitTraits extends Traits<WaypointTraitSymbol, WaypointTrait> {
  @override
  WaypointTrait fromJson(Map<String, dynamic> json) =>
      WaypointTrait.fromJson(json);

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
    : super(records, WaypointTraitTraits());
}

/// A cache of trade good descriptions.
class TradeGoodTraits extends Traits<TradeSymbol, TradeGood> {
  @override
  TradeGood fromJson(Map<String, dynamic> json) => TradeGood.fromJson(json);
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
    : super(records, TradeGoodTraits());
}

/// Traits for TradeExports.
class TradeExportTraits extends Traits<TradeSymbol, TradeExport> {
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
    : super(records, TradeExportTraits());
}

/// Traits for ShipConditionEvents.
class EventTraits extends Traits<ShipConditionEventSymbol, ShipConditionEvent> {
  @override
  ShipConditionEvent fromJson(Map<String, dynamic> json) =>
      ShipConditionEvent.fromJson(json);
  @override
  Json toJson(ShipConditionEvent record) => record.toJson();

  @override
  int compare(ShipConditionEvent a, ShipConditionEvent b) =>
      a.symbol.value.compareTo(b.symbol.value);

  @override
  ShipConditionEventSymbol keyFor(ShipConditionEvent record) => record.symbol;
}

/// A snapshot of events.
class EventSnapshot
    extends StaticSnapshot<ShipConditionEventSymbol, ShipConditionEvent> {
  /// Creates a new event snapshot.
  EventSnapshot(List<ShipConditionEvent> records)
    : super(records, EventTraits());
}
