import 'package:openapi/model/cooldown.dart';
import 'package:openapi/model/ship_cargo.dart';
import 'package:openapi/model/ship_crew.dart';
import 'package:openapi/model/ship_engine.dart';
import 'package:openapi/model/ship_frame.dart';
import 'package:openapi/model/ship_fuel.dart';
import 'package:openapi/model/ship_module.dart';
import 'package:openapi/model/ship_mount.dart';
import 'package:openapi/model/ship_nav.dart';
import 'package:openapi/model/ship_reactor.dart';
import 'package:openapi/model/ship_registration.dart';
import 'package:openapi/model_helpers.dart';

class Ship {
  Ship({
    required this.symbol,
    required this.registration,
    required this.nav,
    required this.crew,
    required this.frame,
    required this.reactor,
    required this.engine,
    required this.cargo,
    required this.fuel,
    required this.cooldown,
    this.modules = const [],
    this.mounts = const [],
  });

  factory Ship.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return Ship(
      symbol: json['symbol'] as String,
      registration: ShipRegistration.fromJson(
        json['registration'] as Map<String, dynamic>,
      ),
      nav: ShipNav.fromJson(json['nav'] as Map<String, dynamic>),
      crew: ShipCrew.fromJson(json['crew'] as Map<String, dynamic>),
      frame: ShipFrame.fromJson(json['frame'] as Map<String, dynamic>),
      reactor: ShipReactor.fromJson(json['reactor'] as Map<String, dynamic>),
      engine: ShipEngine.fromJson(json['engine'] as Map<String, dynamic>),
      modules:
          (json['modules'] as List)
              .map<ShipModule>(
                (e) => ShipModule.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      mounts:
          (json['mounts'] as List)
              .map<ShipMount>(
                (e) => ShipMount.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      cargo: ShipCargo.fromJson(json['cargo'] as Map<String, dynamic>),
      fuel: ShipFuel.fromJson(json['fuel'] as Map<String, dynamic>),
      cooldown: Cooldown.fromJson(json['cooldown'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Ship? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Ship.fromJson(json);
  }

  String symbol;
  ShipRegistration registration;
  ShipNav nav;
  ShipCrew crew;
  ShipFrame frame;
  ShipReactor reactor;
  ShipEngine engine;
  List<ShipModule> modules;
  List<ShipMount> mounts;
  ShipCargo cargo;
  ShipFuel fuel;
  Cooldown cooldown;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'registration': registration.toJson(),
      'nav': nav.toJson(),
      'crew': crew.toJson(),
      'frame': frame.toJson(),
      'reactor': reactor.toJson(),
      'engine': engine.toJson(),
      'modules': modules.map((e) => e.toJson()).toList(),
      'mounts': mounts.map((e) => e.toJson()).toList(),
      'cargo': cargo.toJson(),
      'fuel': fuel.toJson(),
      'cooldown': cooldown.toJson(),
    };
  }

  @override
  int get hashCode => Object.hash(
    symbol,
    registration,
    nav,
    crew,
    frame,
    reactor,
    engine,
    modules,
    mounts,
    cargo,
    fuel,
    cooldown,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ship &&
        symbol == other.symbol &&
        registration == other.registration &&
        nav == other.nav &&
        crew == other.crew &&
        frame == other.frame &&
        reactor == other.reactor &&
        engine == other.engine &&
        listsEqual(modules, other.modules) &&
        listsEqual(mounts, other.mounts) &&
        cargo == other.cargo &&
        fuel == other.fuel &&
        cooldown == other.cooldown;
  }
}
