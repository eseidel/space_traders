import 'package:openapi/model/scanned_ship_engine.dart';
import 'package:openapi/model/scanned_ship_frame.dart';
import 'package:openapi/model/scanned_ship_mounts_inner.dart';
import 'package:openapi/model/scanned_ship_reactor.dart';
import 'package:openapi/model/ship_nav.dart';
import 'package:openapi/model/ship_registration.dart';
import 'package:openapi/model_helpers.dart';

class ScannedShip {
  ScannedShip({
    required this.symbol,
    required this.registration,
    required this.nav,
    required this.engine,
    this.frame,
    this.reactor,
    this.mounts = const [],
  });

  factory ScannedShip.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ScannedShip(
      symbol: json['symbol'] as String,
      registration: ShipRegistration.fromJson(
        json['registration'] as Map<String, dynamic>,
      ),
      nav: ShipNav.fromJson(json['nav'] as Map<String, dynamic>),
      frame: ScannedShipFrame.maybeFromJson(
        json['frame'] as Map<String, dynamic>?,
      ),
      reactor: ScannedShipReactor.maybeFromJson(
        json['reactor'] as Map<String, dynamic>?,
      ),
      engine: ScannedShipEngine.fromJson(
        json['engine'] as Map<String, dynamic>,
      ),
      mounts:
          (json['mounts'] as List?)
              ?.map<ScannedShipMountsInner>(
                (e) =>
                    ScannedShipMountsInner.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ScannedShip? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ScannedShip.fromJson(json);
  }

  String symbol;
  ShipRegistration registration;
  ShipNav nav;
  ScannedShipFrame? frame;
  ScannedShipReactor? reactor;
  ScannedShipEngine engine;
  List<ScannedShipMountsInner> mounts;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'registration': registration.toJson(),
      'nav': nav.toJson(),
      'frame': frame?.toJson(),
      'reactor': reactor?.toJson(),
      'engine': engine.toJson(),
      'mounts': mounts.map((e) => e.toJson()).toList(),
    };
  }

  @override
  int get hashCode =>
      Object.hash(symbol, registration, nav, frame, reactor, engine, mounts);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScannedShip &&
        symbol == other.symbol &&
        registration == other.registration &&
        nav == other.nav &&
        frame == other.frame &&
        reactor == other.reactor &&
        engine == other.engine &&
        listsEqual(mounts, other.mounts);
  }
}
