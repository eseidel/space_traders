import 'package:openapi/model/survey_deposit.dart';
import 'package:openapi/model/survey_size.dart';

class Survey {
  Survey({
    required this.signature,
    required this.symbol,
    required this.expiration,
    required this.size,
    this.deposits = const [],
  });

  factory Survey.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return Survey(
      signature: json['signature'] as String,
      symbol: json['symbol'] as String,
      deposits:
          (json['deposits'] as List<dynamic>)
              .map<SurveyDeposit>(
                (e) => SurveyDeposit.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      expiration: DateTime.parse(json['expiration'] as String),
      size: SurveySize.fromJson(json['size'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Survey? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Survey.fromJson(json);
  }

  String signature;
  String symbol;
  List<SurveyDeposit> deposits;
  DateTime expiration;
  SurveySize size;

  Map<String, dynamic> toJson() {
    return {
      'signature': signature,
      'symbol': symbol,
      'deposits': deposits.map((e) => e.toJson()).toList(),
      'expiration': expiration.toIso8601String(),
      'size': size.toJson(),
    };
  }
}
