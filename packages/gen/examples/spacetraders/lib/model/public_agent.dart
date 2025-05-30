import 'package:meta/meta.dart';

@immutable
class PublicAgent {
  const PublicAgent({
    required this.symbol,
    required this.headquarters,
    required this.credits,
    required this.startingFaction,
    required this.shipCount,
  });

  factory PublicAgent.fromJson(Map<String, dynamic> json) {
    return PublicAgent(
      symbol: json['symbol'] as String,
      headquarters: json['headquarters'] as String,
      credits: json['credits'] as int,
      startingFaction: json['startingFaction'] as String,
      shipCount: json['shipCount'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static PublicAgent? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return PublicAgent.fromJson(json);
  }

  final String symbol;
  final String headquarters;
  final int credits;
  final String startingFaction;
  final int shipCount;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'headquarters': headquarters,
      'credits': credits,
      'startingFaction': startingFaction,
      'shipCount': shipCount,
    };
  }

  @override
  int get hashCode =>
      Object.hash(symbol, headquarters, credits, startingFaction, shipCount);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PublicAgent &&
        symbol == other.symbol &&
        headquarters == other.headquarters &&
        credits == other.credits &&
        startingFaction == other.startingFaction &&
        shipCount == other.shipCount;
  }
}
