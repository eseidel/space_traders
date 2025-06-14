import 'package:openapi/model/agent.dart';
import 'package:openapi/model/cooldown.dart';
import 'package:openapi/model/market_transaction.dart';
import 'package:openapi/model/ship_nav.dart';

class JumpShip200ResponseData {
  JumpShip200ResponseData({
    required this.nav,
    required this.cooldown,
    required this.transaction,
    required this.agent,
  });

  factory JumpShip200ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return JumpShip200ResponseData(
      nav: ShipNav.fromJson(json['nav'] as Map<String, dynamic>),
      cooldown: Cooldown.fromJson(json['cooldown'] as Map<String, dynamic>),
      transaction: MarketTransaction.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static JumpShip200ResponseData? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return JumpShip200ResponseData.fromJson(json);
  }

  ShipNav nav;
  Cooldown cooldown;
  MarketTransaction transaction;
  Agent agent;

  Map<String, dynamic> toJson() {
    return {
      'nav': nav.toJson(),
      'cooldown': cooldown.toJson(),
      'transaction': transaction.toJson(),
      'agent': agent.toJson(),
    };
  }

  @override
  int get hashCode => Object.hash(nav, cooldown, transaction, agent);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JumpShip200ResponseData &&
        nav == other.nav &&
        cooldown == other.cooldown &&
        transaction == other.transaction &&
        agent == other.agent;
  }
}
