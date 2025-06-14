import 'package:openapi/model/cooldown.dart';
import 'package:openapi/model/scanned_ship.dart';
import 'package:openapi/model_helpers.dart';

class CreateShipShipScan201ResponseData {
  CreateShipShipScan201ResponseData({
    required this.cooldown,
    this.ships = const [],
  });

  factory CreateShipShipScan201ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return CreateShipShipScan201ResponseData(
      cooldown: Cooldown.fromJson(json['cooldown'] as Map<String, dynamic>),
      ships: (json['ships'] as List)
          .map<ScannedShip>(
            (e) => ScannedShip.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static CreateShipShipScan201ResponseData? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return CreateShipShipScan201ResponseData.fromJson(json);
  }

  Cooldown cooldown;
  List<ScannedShip> ships;

  Map<String, dynamic> toJson() {
    return {
      'cooldown': cooldown.toJson(),
      'ships': ships.map((e) => e.toJson()).toList(),
    };
  }

  @override
  int get hashCode => Object.hash(cooldown, ships);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateShipShipScan201ResponseData &&
        cooldown == other.cooldown &&
        listsEqual(ships, other.ships);
  }
}
