import 'package:openapi/model/extraction_yield.dart';

class Extraction {
  Extraction({required this.shipSymbol, required this.yield_});

  factory Extraction.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return Extraction(
      shipSymbol: json['shipSymbol'] as String,
      yield_: ExtractionYield.fromJson(json['yield'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Extraction? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Extraction.fromJson(json);
  }

  String shipSymbol;
  ExtractionYield yield_;

  Map<String, dynamic> toJson() {
    return {'shipSymbol': shipSymbol, 'yield': yield_.toJson()};
  }

  @override
  int get hashCode => Object.hash(shipSymbol, yield_);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Extraction &&
        shipSymbol == other.shipSymbol &&
        yield_ == other.yield_;
  }
}
