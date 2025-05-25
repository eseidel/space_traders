import 'package:openapi/model/trade_symbol.dart';

class SurveyDeposit {
  SurveyDeposit({required this.symbol});

  factory SurveyDeposit.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return SurveyDeposit(
      symbol: TradeSymbol.fromJson(json['symbol'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static SurveyDeposit? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return SurveyDeposit.fromJson(json);
  }

  TradeSymbol symbol;

  Map<String, dynamic> toJson() {
    return {'symbol': symbol.toJson()};
  }
}
