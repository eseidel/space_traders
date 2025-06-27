import 'package:meta/meta.dart';
import 'package:spacetraders/model/cooldown.dart';
import 'package:spacetraders/model/ship_cargo.dart';
import 'package:spacetraders/model/ship_condition_event.dart';
import 'package:spacetraders/model/siphon.dart';
import 'package:spacetraders/model_helpers.dart';

@immutable
class SiphonResources201ResponseDataProp {
  const SiphonResources201ResponseDataProp({
    required this.siphon,
    required this.cooldown,
    required this.cargo,
    List<ShipConditionEvent>? events,
  }) : events = events ?? const [];

  factory SiphonResources201ResponseDataProp.fromJson(
    Map<String, dynamic> json,
  ) {
    return SiphonResources201ResponseDataProp(
      siphon: Siphon.fromJson(json['siphon'] as Map<String, dynamic>),
      cooldown: Cooldown.fromJson(json['cooldown'] as Map<String, dynamic>),
      cargo: ShipCargo.fromJson(json['cargo'] as Map<String, dynamic>),
      events: (json['events'] as List)
          .map<ShipConditionEvent>(
            (e) => ShipConditionEvent.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static SiphonResources201ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return SiphonResources201ResponseDataProp.fromJson(json);
  }

  final Siphon siphon;
  final Cooldown cooldown;
  final ShipCargo cargo;
  final List<ShipConditionEvent> events;

  Map<String, dynamic> toJson() {
    return {
      'siphon': siphon.toJson(),
      'cooldown': cooldown.toJson(),
      'cargo': cargo.toJson(),
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  @override
  int get hashCode => Object.hashAll([siphon, cooldown, cargo, events]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SiphonResources201ResponseDataProp &&
        siphon == other.siphon &&
        cooldown == other.cooldown &&
        cargo == other.cargo &&
        listsEqual(events, other.events);
  }
}
