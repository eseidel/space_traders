import 'package:openapi/model/shipyard_ship.dart';
import 'package:openapi/model/shipyard_ship_types_inner.dart';
import 'package:openapi/model/shipyard_transaction.dart';

class Shipyard {
  Shipyard({
    required this.symbol,
    required this.shipTypes,
    required this.modificationsFee,
    this.transactions,
    this.ships,
  });

  factory Shipyard.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return Shipyard(
      symbol: json['symbol'] as String,
      shipTypes:
          (json['shipTypes'] as List<dynamic>)
              .map<ShipyardShipTypesInner>(
                (e) =>
                    ShipyardShipTypesInner.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      transactions:
          (json['transactions'] as List<dynamic>)
              .map<ShipyardTransaction>(
                (e) => ShipyardTransaction.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      ships:
          (json['ships'] as List<dynamic>)
              .map<ShipyardShip>(
                (e) => ShipyardShip.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      modificationsFee: json['modificationsFee'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Shipyard? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Shipyard.fromJson(json);
  }

  String symbol;
  List<ShipyardShipTypesInner> shipTypes;
  List<ShipyardTransaction>? transactions;
  List<ShipyardShip>? ships;
  int modificationsFee;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'shipTypes': shipTypes.map((e) => e.toJson()).toList(),
      'transactions': transactions?.map((e) => e.toJson()).toList(),
      'ships': ships?.map((e) => e.toJson()).toList(),
      'modificationsFee': modificationsFee,
    };
  }
}
