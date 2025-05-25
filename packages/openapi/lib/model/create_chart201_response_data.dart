import 'package:openapi/model/agent.dart';
import 'package:openapi/model/chart.dart';
import 'package:openapi/model/chart_transaction.dart';
import 'package:openapi/model/waypoint.dart';

class CreateChart201ResponseData {
  CreateChart201ResponseData({
    required this.chart,
    required this.waypoint,
    required this.transaction,
    required this.agent,
  });

  factory CreateChart201ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return CreateChart201ResponseData(
      chart: Chart.fromJson(json['chart'] as Map<String, dynamic>),
      waypoint: Waypoint.fromJson(json['waypoint'] as Map<String, dynamic>),
      transaction: ChartTransaction.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static CreateChart201ResponseData? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return CreateChart201ResponseData.fromJson(json);
  }

  Chart chart;
  Waypoint waypoint;
  ChartTransaction transaction;
  Agent agent;

  Map<String, dynamic> toJson() {
    return {
      'chart': chart.toJson(),
      'waypoint': waypoint.toJson(),
      'transaction': transaction.toJson(),
      'agent': agent.toJson(),
    };
  }
}
