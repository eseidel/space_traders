import 'package:openapi/api_helpers.dart';
import 'package:openapi/model/cooldown.dart';
import 'package:openapi/model/ship_cargo.dart';
import 'package:openapi/model/ship_condition_event.dart';
import 'package:openapi/model/siphon.dart';

class SiphonResources201ResponseData {
  SiphonResources201ResponseData({
    required this.siphon,
    required this.cooldown,
    required this.cargo,
    this.events = const [],
  });

  factory SiphonResources201ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return SiphonResources201ResponseData(
      siphon: Siphon.fromJson(json['siphon'] as Map<String, dynamic>),
      cooldown: Cooldown.fromJson(json['cooldown'] as Map<String, dynamic>),
      cargo: ShipCargo.fromJson(json['cargo'] as Map<String, dynamic>),
      events:
          (json['events'] as List<dynamic>)
              .map<ShipConditionEvent>(
                (e) => ShipConditionEvent.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static SiphonResources201ResponseData? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return SiphonResources201ResponseData.fromJson(json);
  }

  Siphon siphon;
  Cooldown cooldown;
  ShipCargo cargo;
  List<ShipConditionEvent> events;

  Map<String, dynamic> toJson() {
    return {
      'siphon': siphon.toJson(),
      'cooldown': cooldown.toJson(),
      'cargo': cargo.toJson(),
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  @override
  int get hashCode => Object.hash(siphon, cooldown, cargo, events);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SiphonResources201ResponseData &&
        siphon == other.siphon &&
        cooldown == other.cooldown &&
        cargo == other.cargo &&
        listsEqual(events, other.events);
  }
}
