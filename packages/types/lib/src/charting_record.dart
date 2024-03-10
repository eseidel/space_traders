import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:types/api.dart';
import 'package:types/src/symbol.dart';

/// A charted value.
@immutable
class ChartedValues {
  /// Creates a new charted values.
  const ChartedValues({
    required this.chart,
    required this.faction,
    required this.traitSymbols,
  });

  /// Creates a new charted values for testing.
  @visibleForTesting
  factory ChartedValues.test({
    WaypointFaction? faction,
    Set<WaypointTraitSymbol>? traitSymbols,
    Chart? chart,
  }) =>
      ChartedValues(
        faction: faction,
        traitSymbols: traitSymbols ?? {},
        chart: chart ?? Chart(),
      );

  /// Creates a new charted values from JSON data.
  factory ChartedValues.fromJson(Map<String, dynamic> json) {
    final faction =
        WaypointFaction.fromJson(json['faction'] as Map<String, dynamic>?);
    final traitSymbols = (json['traitSymbols'] as List<dynamic>)
        .cast<String>()
        .map((e) => WaypointTraitSymbol.fromJson(e)!)
        .toSet();
    final chart = Chart.fromJson(json['chart'] as Map<String, dynamic>)!;
    return ChartedValues(
      faction: faction,
      traitSymbols: traitSymbols,
      chart: chart,
    );
  }

  /// Creates a new charted values from JSON data.
  static ChartedValues? fromJsonOrNull(Map<String, dynamic>? json) =>
      json == null ? null : ChartedValues.fromJson(json);

  /// Faction for this waypoint.
  final WaypointFaction? faction;

  /// The traits of the waypoint.
  final Set<WaypointTraitSymbol> traitSymbols;

  /// Chart for this waypoint.
  final Chart chart;

  /// Converts this charted values to JSON data.
  Map<String, dynamic> toJson() {
    // Work around that OpenAPI's toJson method doesn't handle nested objects.
    Map<String, dynamic>? factionToJson(WaypointFaction? faction) {
      if (faction == null) {
        return null;
      }
      final json = faction.toJson();
      json['symbol'] = faction.symbol.toJson();
      return json;
    }

    final sortedTradeSymbols = traitSymbols.sortedBy((s) => s.value);
    return <String, dynamic>{
      'faction': factionToJson(faction),
      'traitSymbols': sortedTradeSymbols.map((e) => e.toJson()).toList(),
      'chart': chart.toJson(),
    };
  }

  /// Whether this waypoint has a shipyard.
  bool get hasShipyard => traitSymbols.contains(WaypointTraitSymbol.SHIPYARD);

  /// Whether this waypoint has a market.
  bool get hasMarket => traitSymbols.contains(WaypointTraitSymbol.MARKETPLACE);
}

/// Charting record for a given waypoint.
class ChartingRecord {
  /// Creates a new charting record.
  const ChartingRecord({
    required this.waypointSymbol,
    required this.values,
    required this.timestamp,
  });

  /// Create a fallback value for mocking.
  @visibleForTesting
  ChartingRecord.fallbackValue()
      : waypointSymbol = WaypointSymbol.fromString('W-A-Y'),
        values = null,
        timestamp = DateTime(0);

  /// Creates a new charting record from JSON data.
  ChartingRecord.fromJson(Map<String, dynamic> json)
      : values = ChartedValues.fromJsonOrNull(
          json['values'] as Map<String, dynamic>?,
        ),
        waypointSymbol =
            WaypointSymbol.fromJson(json['waypointSymbol'] as String),
        timestamp = DateTime.parse(json['timestamp'] as String);

  /// Symbol for this waypoint.
  final WaypointSymbol waypointSymbol;

  /// The charted values.  Will be null for uncharted waypoints.
  final ChartedValues? values;

  /// The timestamp for this record.
  final DateTime timestamp;

  /// Whether this waypoint was charted at record time.
  bool get isCharted => values != null;

  /// Converts this charting record to JSON data.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'values': values?.toJson(),
        'waypointSymbol': waypointSymbol.toJson(),
        'timestamp': timestamp.toIso8601String(),
      };
}
