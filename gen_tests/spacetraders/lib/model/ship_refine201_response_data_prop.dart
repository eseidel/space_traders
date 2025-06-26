import 'package:meta/meta.dart';
import 'package:spacetraders/model/cooldown.dart';
import 'package:spacetraders/model/ship_cargo.dart';
import 'package:spacetraders/model/ship_refine201_response_data_prop_consumed_prop_inner.dart';
import 'package:spacetraders/model/ship_refine201_response_data_prop_produced_prop_inner.dart';
import 'package:spacetraders/model_helpers.dart';

@immutable
class ShipRefine201ResponseDataProp {
  const ShipRefine201ResponseDataProp({
    required this.cargo,
    required this.cooldown,
    this.produced = const [],
    this.consumed = const [],
  });

  factory ShipRefine201ResponseDataProp.fromJson(Map<String, dynamic> json) {
    return ShipRefine201ResponseDataProp(
      cargo: ShipCargo.fromJson(json['cargo'] as Map<String, dynamic>),
      cooldown: Cooldown.fromJson(json['cooldown'] as Map<String, dynamic>),
      produced: (json['produced'] as List)
          .map<ShipRefine201ResponseDataPropProducedPropInner>(
            (e) => ShipRefine201ResponseDataPropProducedPropInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      consumed: (json['consumed'] as List)
          .map<ShipRefine201ResponseDataPropConsumedPropInner>(
            (e) => ShipRefine201ResponseDataPropConsumedPropInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipRefine201ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return ShipRefine201ResponseDataProp.fromJson(json);
  }

  final ShipCargo cargo;
  final Cooldown cooldown;
  final List<ShipRefine201ResponseDataPropProducedPropInner> produced;
  final List<ShipRefine201ResponseDataPropConsumedPropInner> consumed;

  Map<String, dynamic> toJson() {
    return {
      'cargo': cargo.toJson(),
      'cooldown': cooldown.toJson(),
      'produced': produced.map((e) => e.toJson()).toList(),
      'consumed': consumed.map((e) => e.toJson()).toList(),
    };
  }

  @override
  int get hashCode => Object.hashAll([cargo, cooldown, produced, consumed]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipRefine201ResponseDataProp &&
        cargo == other.cargo &&
        cooldown == other.cooldown &&
        listsEqual(produced, other.produced) &&
        listsEqual(consumed, other.consumed);
  }
}
