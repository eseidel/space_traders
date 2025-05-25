class ShipyardTransaction {
  ShipyardTransaction({
    required this.waypointSymbol,
    required this.shipSymbol,
    required this.shipType,
    required this.price,
    required this.agentSymbol,
    required this.timestamp,
  });

  factory ShipyardTransaction.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipyardTransaction(
      waypointSymbol: json['waypointSymbol'] as String,
      shipSymbol: json['shipSymbol'] as String,
      shipType: json['shipType'] as String,
      price: json['price'] as int,
      agentSymbol: json['agentSymbol'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipyardTransaction? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipyardTransaction.fromJson(json);
  }

  String waypointSymbol;
  String shipSymbol;
  String shipType;
  int price;
  String agentSymbol;
  DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {
      'waypointSymbol': waypointSymbol,
      'shipSymbol': shipSymbol,
      'shipType': shipType,
      'price': price,
      'agentSymbol': agentSymbol,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
