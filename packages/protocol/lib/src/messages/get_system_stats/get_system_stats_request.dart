import 'package:protocol/src/models/get_request.dart';
import 'package:types/types.dart';

class GetSystemStatsRequest extends GetRequest {
  /// Creates a new [GetSystemStatsRequest].
  GetSystemStatsRequest({required this.startSystem});

  /// Creates a new [GetSystemStatsRequest] from query parameters.
  factory GetSystemStatsRequest.fromQueryParameters(
    Map<String, String?> queryParameters,
  ) {
    final maybeStartSystem = queryParameters['start_system'];
    return GetSystemStatsRequest(
      startSystem:
          maybeStartSystem != null
              ? SystemSymbol.fromJson(maybeStartSystem)
              : null,
    );
  }

  /// The system to get stats for.
  final SystemSymbol? startSystem;

  /// Converts the request to query parameters.
  @override
  Map<String, String?> toQueryParameters() {
    return {if (startSystem != null) 'start_system': startSystem?.toJson()};
  }
}
