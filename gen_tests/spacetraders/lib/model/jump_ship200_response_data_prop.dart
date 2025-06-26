import 'package:meta/meta.dart';
import 'package:spacetraders/model/agent.dart';
import 'package:spacetraders/model/cooldown.dart';
import 'package:spacetraders/model/market_transaction.dart';
import 'package:spacetraders/model/ship_nav.dart';

@immutable
class JumpShip200ResponseDataProp {
  const JumpShip200ResponseDataProp({
    required this.nav,
    required this.cooldown,
    required this.transaction,
    required this.agent,
  });

  factory JumpShip200ResponseDataProp.fromJson(Map<String, dynamic> json) {
    return JumpShip200ResponseDataProp(
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
  static JumpShip200ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return JumpShip200ResponseDataProp.fromJson(json);
  }

  final ShipNav nav;
  final Cooldown cooldown;
  final MarketTransaction transaction;
  final Agent agent;

  Map<String, dynamic> toJson() {
    return {
      'nav': nav.toJson(),
      'cooldown': cooldown.toJson(),
      'transaction': transaction.toJson(),
      'agent': agent.toJson(),
    };
  }

  @override
  int get hashCode => Object.hashAll([nav, cooldown, transaction, agent]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JumpShip200ResponseDataProp &&
        nav == other.nav &&
        cooldown == other.cooldown &&
        transaction == other.transaction &&
        agent == other.agent;
  }
}
