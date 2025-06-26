import 'package:meta/meta.dart';
import 'package:spacetraders/model/transfer_cargo200_response_data_prop.dart';

@immutable
class TransferCargo200Response {
  const TransferCargo200Response({required this.data});

  factory TransferCargo200Response.fromJson(Map<String, dynamic> json) {
    return TransferCargo200Response(
      data: TransferCargo200ResponseDataProp.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static TransferCargo200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return TransferCargo200Response.fromJson(json);
  }

  final TransferCargo200ResponseDataProp data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransferCargo200Response && data == other.data;
  }
}
