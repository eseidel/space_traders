class ScrapTransaction {
  ScrapTransaction({
    required this.waypointSymbol,
    required this.shipSymbol,
    required this.totalPrice,
    required this.timestamp,
  });

  factory ScrapTransaction.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ScrapTransaction(
      waypointSymbol: json['waypointSymbol'] as String,
      shipSymbol: json['shipSymbol'] as String,
      totalPrice: json['totalPrice'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ScrapTransaction? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ScrapTransaction.fromJson(json);
  }

  String waypointSymbol;
  String shipSymbol;
  int totalPrice;
  DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {
      'waypointSymbol': waypointSymbol,
      'shipSymbol': shipSymbol,
      'totalPrice': totalPrice,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  int get hashCode =>
      Object.hash(waypointSymbol, shipSymbol, totalPrice, timestamp);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScrapTransaction &&
        waypointSymbol == other.waypointSymbol &&
        shipSymbol == other.shipSymbol &&
        totalPrice == other.totalPrice &&
        timestamp == other.timestamp;
  }
}
