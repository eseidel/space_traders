import 'package:openapi/model/ship_role.dart';

class ShipRegistration {
  ShipRegistration({
    required this.name,
    required this.factionSymbol,
    required this.role,
  });

  factory ShipRegistration.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipRegistration(
      name: json['name'] as String,
      factionSymbol: json['factionSymbol'] as String,
      role: ShipRole.fromJson(json['role'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipRegistration? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipRegistration.fromJson(json);
  }

  String name;
  String factionSymbol;
  ShipRole role;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'factionSymbol': factionSymbol,
      'role': role.toJson(),
    };
  }

  @override
  int get hashCode => Object.hash(name, factionSymbol, role);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipRegistration &&
        name == other.name &&
        factionSymbol == other.factionSymbol &&
        role == other.role;
  }
}
