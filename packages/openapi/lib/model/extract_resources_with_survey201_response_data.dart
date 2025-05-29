import 'package:openapi/model/cooldown.dart';
import 'package:openapi/model/extraction.dart';
import 'package:openapi/model/ship_cargo.dart';
import 'package:openapi/model/ship_condition_event.dart';
import 'package:openapi/model/waypoint_modifier.dart';
import 'package:openapi/model_helpers.dart';

class ExtractResourcesWithSurvey201ResponseData {
  ExtractResourcesWithSurvey201ResponseData({
    required this.extraction,
    required this.cooldown,
    required this.cargo,
    this.modifiers = const [],
    this.events = const [],
  });

  factory ExtractResourcesWithSurvey201ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ExtractResourcesWithSurvey201ResponseData(
      extraction: Extraction.fromJson(
        json['extraction'] as Map<String, dynamic>,
      ),
      cooldown: Cooldown.fromJson(json['cooldown'] as Map<String, dynamic>),
      cargo: ShipCargo.fromJson(json['cargo'] as Map<String, dynamic>),
      modifiers:
          (json['modifiers'] as List?)
              ?.map<WaypointModifier>(
                (e) => WaypointModifier.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      events:
          (json['events'] as List)
              .map<ShipConditionEvent>(
                (e) => ShipConditionEvent.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ExtractResourcesWithSurvey201ResponseData? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return ExtractResourcesWithSurvey201ResponseData.fromJson(json);
  }

  Extraction extraction;
  Cooldown cooldown;
  ShipCargo cargo;
  List<WaypointModifier>? modifiers;
  List<ShipConditionEvent> events;

  Map<String, dynamic> toJson() {
    return {
      'extraction': extraction.toJson(),
      'cooldown': cooldown.toJson(),
      'cargo': cargo.toJson(),
      'modifiers': modifiers?.map((e) => e.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  @override
  int get hashCode =>
      Object.hash(extraction, cooldown, cargo, modifiers, events);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExtractResourcesWithSurvey201ResponseData &&
        extraction == other.extraction &&
        cooldown == other.cooldown &&
        cargo == other.cargo &&
        listsEqual(modifiers, other.modifiers) &&
        listsEqual(events, other.events);
  }
}
