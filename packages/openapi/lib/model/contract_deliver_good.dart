class ContractDeliverGood {
  ContractDeliverGood({
    required this.tradeSymbol,
    required this.destinationSymbol,
    required this.unitsRequired,
    required this.unitsFulfilled,
  });

  factory ContractDeliverGood.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ContractDeliverGood(
      tradeSymbol: json['tradeSymbol'] as String,
      destinationSymbol: json['destinationSymbol'] as String,
      unitsRequired: json['unitsRequired'] as int,
      unitsFulfilled: json['unitsFulfilled'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ContractDeliverGood? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ContractDeliverGood.fromJson(json);
  }

  String tradeSymbol;
  String destinationSymbol;
  int unitsRequired;
  int unitsFulfilled;

  Map<String, dynamic> toJson() {
    return {
      'tradeSymbol': tradeSymbol,
      'destinationSymbol': destinationSymbol,
      'unitsRequired': unitsRequired,
      'unitsFulfilled': unitsFulfilled,
    };
  }
}
