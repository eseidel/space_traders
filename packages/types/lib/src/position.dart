import 'dart:math';

import 'package:meta/meta.dart';
import 'package:types/src/symbol.dart';

/// A position within an unspecified coordinate space.
@immutable
class Position {
  const Position._(this.x, this.y);

  /// The x coordinate.
  final int x;

  /// The y coordinate.
  final int y;
}

/// An x, y position within the System coordinate space.
@immutable
class SystemPosition extends Position {
  /// Construct a SystemPosition with the given x and y.
  const SystemPosition(super.x, super.y) : super._();

  /// Returns the distance between this position and the given position.
  int distanceTo(SystemPosition other) {
    // Use euclidean distance.
    final dx = other.x - x;
    final dy = other.y - y;
    return sqrt(dx * dx + dy * dy).round();
  }
}

/// An x, y position within the Waypoint coordinate space.
@immutable
class WaypointPosition extends Position {
  /// Construct a WaypointPosition with the given x and y.
  const WaypointPosition(super.x, super.y, this.system) : super._();

  /// The system symbol of the waypoint.
  final SystemSymbol system;

  /// Returns the distance between this position and the given position.
  double distanceTo(WaypointPosition other) {
    if (system != other.system) {
      throw ArgumentError(
        'Waypoints must be in the same system: $this, $other',
      );
    }
    // Use euclidean distance.
    final dx = other.x - x;
    final dy = other.y - y;
    return sqrt(dx * dx + dy * dy);
  }

  @override
  String toString() => '$x, $y in $system';
}
