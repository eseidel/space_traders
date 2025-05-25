import 'package:openapi/model/cooldown.dart';
import 'package:openapi/model/scanned_ship.dart';

class CreateShipShipScan201ResponseData {
  CreateShipShipScan201ResponseData({
    required this.cooldown,
    this.ships = const [],
  });

  factory CreateShipShipScan201ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return CreateShipShipScan201ResponseData(
      cooldown: Cooldown.fromJson(json['cooldown'] as Map<String, dynamic>),
      ships:
          (json['ships'] as List<dynamic>)
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
}
