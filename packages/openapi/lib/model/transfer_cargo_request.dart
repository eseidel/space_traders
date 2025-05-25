import 'package:openapi/model/trade_symbol.dart';

class TransferCargoRequest {
  TransferCargoRequest({
    required this.tradeSymbol,
    required this.units,
    required this.shipSymbol,
  });

  factory TransferCargoRequest.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return TransferCargoRequest(
      tradeSymbol: TradeSymbol.fromJson(json['tradeSymbol'] as String),
      units: json['units'] as int,
      shipSymbol: json['shipSymbol'] as String,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static TransferCargoRequest? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return TransferCargoRequest.fromJson(json);
  }

  TradeSymbol tradeSymbol;
  int units;
  String shipSymbol;

  Map<String, dynamic> toJson() {
    return {
      'tradeSymbol': tradeSymbol.toJson(),
      'units': units,
      'shipSymbol': shipSymbol,
    };
  }
}
