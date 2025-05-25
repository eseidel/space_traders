import 'package:openapi/model/ship_mount_deposits_inner.dart';
import 'package:openapi/model/ship_mount_symbol.dart';
import 'package:openapi/model/ship_requirements.dart';

class ShipMount {
  ShipMount({
    required this.symbol,
    required this.name,
    required this.description,
    required this.requirements,
    this.strength,
    this.deposits = const [],
  });

  factory ShipMount.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipMount(
      symbol: ShipMountSymbol.fromJson(json['symbol'] as String),
      name: json['name'] as String,
      description: json['description'] as String,
      strength: json['strength'] as int,
      deposits:
          (json['deposits'] as List<dynamic>).cast<ShipMountDepositsInner>(),
      requirements: ShipRequirements.fromJson(
        json['requirements'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipMount? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipMount.fromJson(json);
  }

  ShipMountSymbol symbol;
  String name;
  String description;
  int? strength;
  List<ShipMountDepositsInner> deposits;
  ShipRequirements requirements;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol.toJson(),
      'name': name,
      'description': description,
      'strength': strength,
      'deposits': deposits,
      'requirements': requirements.toJson(),
    };
  }
}
