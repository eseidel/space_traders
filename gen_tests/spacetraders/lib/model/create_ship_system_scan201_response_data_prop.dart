import 'package:meta/meta.dart';
import 'package:spacetraders/model/cooldown.dart';
import 'package:spacetraders/model/scanned_system.dart';
import 'package:spacetraders/model_helpers.dart';

@immutable
class CreateShipSystemScan201ResponseDataProp {
  const CreateShipSystemScan201ResponseDataProp({
    required this.cooldown,
    this.systems = const [],
  });

  factory CreateShipSystemScan201ResponseDataProp.fromJson(
    Map<String, dynamic> json,
  ) {
    return CreateShipSystemScan201ResponseDataProp(
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
  static CreateShipSystemScan201ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return CreateShipSystemScan201ResponseDataProp.fromJson(json);
  }

  final Cooldown cooldown;
  final List<ScannedSystem> systems;

  Map<String, dynamic> toJson() {
    return {
      'cooldown': cooldown.toJson(),
      'systems': systems.map((e) => e.toJson()).toList(),
    };
  }

  @override
  int get hashCode => Object.hashAll([cooldown, systems]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateShipSystemScan201ResponseDataProp &&
        cooldown == other.cooldown &&
        listsEqual(systems, other.systems);
  }
}
