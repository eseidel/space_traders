import 'package:json_annotation/json_annotation.dart';

part 'error_response.g.dart';

@JsonSerializable()
class ErrorResponse {
  const ErrorResponse({
    required this.code,
    required this.message,
    this.details,
  });

  /// Converts Json to [ErrorResponse].
  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);

  /// Converts [ErrorResponse] to Json.
  Map<String, dynamic> toJson() => _$ErrorResponseToJson(this);

  /// The unique error code.
  final String code;

  /// Human-readable error message.
  final String message;

  /// Optional details associated with the error.
  final String? details;
}
