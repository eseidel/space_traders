import 'package:openapi/model/construction_material.dart';
import 'package:openapi/model_helpers.dart';

class Construction {
  Construction({
    required this.symbol,
    required this.isComplete,
    this.materials = const [],
  });

  factory Construction.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return Construction(
      symbol: json['symbol'] as String,
      materials: (json['materials'] as List)
          .map<ConstructionMaterial>(
            (e) => ConstructionMaterial.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      isComplete: json['isComplete'] as bool,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Construction? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Construction.fromJson(json);
  }

  String symbol;
  List<ConstructionMaterial> materials;
  bool isComplete;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'materials': materials.map((e) => e.toJson()).toList(),
      'isComplete': isComplete,
    };
  }

  @override
  int get hashCode => Object.hash(symbol, materials, isComplete);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Construction &&
        symbol == other.symbol &&
        listsEqual(materials, other.materials) &&
        isComplete == other.isComplete;
  }
}
