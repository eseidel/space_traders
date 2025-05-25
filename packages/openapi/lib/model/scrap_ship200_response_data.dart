import 'package:openapi/model/agent.dart';
import 'package:openapi/model/scrap_transaction.dart';

class ScrapShip200ResponseData {
  ScrapShip200ResponseData({required this.agent, required this.transaction});

  factory ScrapShip200ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ScrapShip200ResponseData(
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
      transaction: ScrapTransaction.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ScrapShip200ResponseData? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ScrapShip200ResponseData.fromJson(json);
  }

  Agent agent;
  ScrapTransaction transaction;

  Map<String, dynamic> toJson() {
    return {'agent': agent.toJson(), 'transaction': transaction.toJson()};
  }

  @override
  int get hashCode => Object.hash(agent, transaction);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScrapShip200ResponseData &&
        agent == other.agent &&
        transaction == other.transaction;
  }
}
