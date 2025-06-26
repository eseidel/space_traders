import 'package:meta/meta.dart';
import 'package:spacetraders/model/agent.dart';
import 'package:spacetraders/model/scrap_transaction.dart';

@immutable
class ScrapShip200ResponseDataProp {
  const ScrapShip200ResponseDataProp({
    required this.agent,
    required this.transaction,
  });

  factory ScrapShip200ResponseDataProp.fromJson(Map<String, dynamic> json) {
    return ScrapShip200ResponseDataProp(
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
      transaction: ScrapTransaction.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ScrapShip200ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return ScrapShip200ResponseDataProp.fromJson(json);
  }

  final Agent agent;
  final ScrapTransaction transaction;

  Map<String, dynamic> toJson() {
    return {'agent': agent.toJson(), 'transaction': transaction.toJson()};
  }

  @override
  int get hashCode => Object.hashAll([agent, transaction]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScrapShip200ResponseDataProp &&
        agent == other.agent &&
        transaction == other.transaction;
  }
}
