import 'package:openapi/model/siphon_yield.dart';

class Siphon {
  Siphon({required this.shipSymbol, required this.yield_});

  factory Siphon.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return Siphon(
      shipSymbol: json['shipSymbol'] as String,
      yield_: SiphonYield.fromJson(json['yield'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Siphon? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Siphon.fromJson(json);
  }

  String shipSymbol;
  SiphonYield yield_;

  Map<String, dynamic> toJson() {
    return {'shipSymbol': shipSymbol, 'yield': yield_.toJson()};
  }

  @override
  int get hashCode => Object.hash(shipSymbol, yield_);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Siphon &&
        shipSymbol == other.shipSymbol &&
        yield_ == other.yield_;
  }
}
