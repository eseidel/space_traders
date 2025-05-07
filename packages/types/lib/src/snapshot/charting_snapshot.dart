import 'package:types/types.dart';

/// A snapshot of the charting records.
class ChartingSnapshot {
  /// Creates a new charting snapshot.
  ChartingSnapshot(Iterable<ChartingRecord> records) {
    for (final record in records) {
      _recordsByWaypointSymbol[record.waypointSymbol] = record;
    }
  }

  /// The charting records.
  final Map<WaypointSymbol, ChartingRecord> _recordsByWaypointSymbol =
      <WaypointSymbol, ChartingRecord>{};

  /// The charting records.
  Iterable<ChartingRecord> get records => _recordsByWaypointSymbol.values;

  /// The number of waypoints in this snapshot.
  /// Records are expected to be one-per-waypoint but this method is
  /// separate from [records] on the assumption that may change.
  int get waypointCount => _recordsByWaypointSymbol.length;

  /// Returns all charted values.
  Iterable<ChartedValues> get values =>
      records.where((r) => r.values != null).map((r) => r.values!);

  /// Returns true if the given waypoint is known to be charted.
  /// Will return null if the waypoint is not in the snapshot.
  bool? isCharted(WaypointSymbol waypointSymbol) =>
      getRecord(waypointSymbol)?.isCharted;

  /// Returns the ChartingRecord for the given waypoint, or null if it is not
  /// in the snapshot.
  ChartingRecord? getRecord(WaypointSymbol waypointSymbol) =>
      _recordsByWaypointSymbol[waypointSymbol];

  /// Returns the ChartingRecord for the given waypoint, or null if it is not
  ChartingRecord? operator [](WaypointSymbol waypointSymbol) =>
      getRecord(waypointSymbol);
}
