/// Symbol of the frame.
enum ShipFrameSymbol {
  PROBE._('FRAME_PROBE'),
  DRONE._('FRAME_DRONE'),
  INTERCEPTOR._('FRAME_INTERCEPTOR'),
  RACER._('FRAME_RACER'),
  FIGHTER._('FRAME_FIGHTER'),
  FRIGATE._('FRAME_FRIGATE'),
  SHUTTLE._('FRAME_SHUTTLE'),
  EXPLORER._('FRAME_EXPLORER'),
  MINER._('FRAME_MINER'),
  LIGHT_FREIGHTER._('FRAME_LIGHT_FREIGHTER'),
  HEAVY_FREIGHTER._('FRAME_HEAVY_FREIGHTER'),
  TRANSPORT._('FRAME_TRANSPORT'),
  DESTROYER._('FRAME_DESTROYER'),
  CRUISER._('FRAME_CRUISER'),
  CARRIER._('FRAME_CARRIER'),
  BULK_FREIGHTER._('FRAME_BULK_FREIGHTER');

  const ShipFrameSymbol._(this.value);

  /// Creates a ShipFrameSymbol from a json string.
  factory ShipFrameSymbol.fromJson(String json) {
    return ShipFrameSymbol.values.firstWhere(
      (value) => value.value == json,
      orElse: () =>
          throw FormatException('Unknown ShipFrameSymbol value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipFrameSymbol? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipFrameSymbol.fromJson(json);
  }

  /// The value of the enum, as a string.  This is the exact value
  /// from the OpenAPI spec and will be used for network transport.
  final String value;

  /// Converts the enum to a json string.
  String toJson() => value;

  /// Returns the string value of the enum.
  @override
  String toString() => value;
}
