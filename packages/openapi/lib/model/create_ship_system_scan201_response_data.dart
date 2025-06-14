import 'package:openapi/model/cooldown.dart';
import 'package:openapi/model/scanned_system.dart';
import 'package:openapi/model_helpers.dart';

class CreateShipSystemScan201ResponseData {
  CreateShipSystemScan201ResponseData({
    required this.cooldown,
    this.systems = const [],
  });

  factory CreateShipSystemScan201ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return CreateShipSystemScan201ResponseData(
      cooldown: Cooldown.fromJson(json['cooldown'] as Map<String, dynamic>),
      systems: (json['systems'] as List)
          .map<ScannedSystem>(
            (e) => ScannedSystem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static CreateShipSystemScan201ResponseData? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return CreateShipSystemScan201ResponseData.fromJson(json);
  }

  Cooldown cooldown;
  List<ScannedSystem> systems;

  Map<String, dynamic> toJson() {
    return {
      'cooldown': cooldown.toJson(),
      'systems': systems.map((e) => e.toJson()).toList(),
    };
  }

  @override
  int get hashCode => Object.hash(cooldown, systems);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateShipSystemScan201ResponseData &&
        cooldown == other.cooldown &&
        listsEqual(systems, other.systems);
  }
}
