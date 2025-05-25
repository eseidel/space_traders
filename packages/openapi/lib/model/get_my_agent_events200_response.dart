import 'package:openapi/model/agent_event.dart';

class GetMyAgentEvents200Response {
  GetMyAgentEvents200Response({this.data = const []});

  factory GetMyAgentEvents200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetMyAgentEvents200Response(
      data:
          (json['data'] as List<dynamic>)
              .map<AgentEvent>(
                (e) => AgentEvent.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetMyAgentEvents200Response? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetMyAgentEvents200Response.fromJson(json);
  }

  List<AgentEvent> data;

  Map<String, dynamic> toJson() {
    return {'data': data.map((e) => e.toJson()).toList()};
  }
}
