class ShipModificationTransaction {
  ShipModificationTransaction({
    required this.waypointSymbol,
    required this.shipSymbol,
    required this.tradeSymbol,
    required this.totalPrice,
    required this.timestamp,
  });

  factory ShipModificationTransaction.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipModificationTransaction(
      waypointSymbol: json['waypointSymbol'] as String,
      shipSymbol: json['shipSymbol'] as String,
      tradeSymbol: json['tradeSymbol'] as String,
      totalPrice: json['totalPrice'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipModificationTransaction? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return ShipModificationTransaction.fromJson(json);
  }

  String waypointSymbol;
  String shipSymbol;
  String tradeSymbol;
  int totalPrice;
  DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {
      'waypointSymbol': waypointSymbol,
      'shipSymbol': shipSymbol,
      'tradeSymbol': tradeSymbol,
      'totalPrice': totalPrice,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  int get hashCode => Object.hash(
    waypointSymbol,
    shipSymbol,
    tradeSymbol,
    totalPrice,
    timestamp,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipModificationTransaction &&
        waypointSymbol == other.waypointSymbol &&
        shipSymbol == other.shipSymbol &&
        tradeSymbol == other.tradeSymbol &&
        totalPrice == other.totalPrice &&
        timestamp == other.timestamp;
  }
}
