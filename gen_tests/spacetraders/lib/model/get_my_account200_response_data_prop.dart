import 'package:meta/meta.dart';
import 'package:spacetraders/model/get_my_account200_response_data_prop_account_prop.dart';

@immutable
class GetMyAccount200ResponseDataProp {
  const GetMyAccount200ResponseDataProp({required this.account});

  factory GetMyAccount200ResponseDataProp.fromJson(Map<String, dynamic> json) {
    return GetMyAccount200ResponseDataProp(
      account: GetMyAccount200ResponseDataPropAccountProp.fromJson(
        json['account'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetMyAccount200ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetMyAccount200ResponseDataProp.fromJson(json);
  }

  final GetMyAccount200ResponseDataPropAccountProp account;

  Map<String, dynamic> toJson() {
    return {'account': account.toJson()};
  }

  @override
  int get hashCode => account.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetMyAccount200ResponseDataProp && account == other.account;
  }
}
