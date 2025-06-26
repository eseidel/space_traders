import 'package:meta/meta.dart';
import 'package:spacetraders/model/contract.dart';

@immutable
class NegotiateContract201ResponseDataProp {
  const NegotiateContract201ResponseDataProp({required this.contract});

  factory NegotiateContract201ResponseDataProp.fromJson(
    Map<String, dynamic> json,
  ) {
    return NegotiateContract201ResponseDataProp(
      contract: Contract.fromJson(json['contract'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static NegotiateContract201ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return NegotiateContract201ResponseDataProp.fromJson(json);
  }

  final Contract contract;

  Map<String, dynamic> toJson() {
    return {'contract': contract.toJson()};
  }

  @override
  int get hashCode => contract.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NegotiateContract201ResponseDataProp &&
        contract == other.contract;
  }
}
