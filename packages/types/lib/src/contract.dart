import 'package:meta/meta.dart';
import 'package:types/api.dart';

/// The type of contract action.
enum ContractAction {
  /// Accept a contract.
  accept,

  /// Deliver goods for a contract.
  delivery,

  /// Fulfill a contract.
  fulfillment;

  /// Failed to fulfill a contract before the deadline.  Advance is reclaimed.
  /// We get no notice from the server, so to implement this we'd need to
  /// account for it on *every* transaction.  This is not worth the effort.
  // failure;

  /// Construct a contract action from a string.
  static ContractAction fromJson(String json) {
    return ContractAction.values.firstWhere((e) => e.name == json);
  }

  /// Construct a contract action from a string, or null if the string is null.
  static ContractAction? fromJsonOrNull(String? json) {
    return json == null ? null : fromJson(json);
  }
}

/// A class to hold transaction data from a contract.
@immutable
class ContractTransaction {
  const ContractTransaction._({
    required this.contractId,
    required this.contractAction,
    required this.unitsDelivered,
    required this.creditsChange,
    required this.shipSymbol,
    required this.timestamp,
    required this.waypointSymbol,
  });

  /// Accept a contract.
  factory ContractTransaction.accept({
    required Contract contract,
    required ShipSymbol shipSymbol,
    required WaypointSymbol waypointSymbol,
    required DateTime timestamp,
  }) {
    return ContractTransaction._(
      contractId: contract.id,
      contractAction: ContractAction.accept,
      unitsDelivered: null,
      creditsChange: contract.terms.payment.onAccepted,
      shipSymbol: shipSymbol,
      timestamp: timestamp,
      waypointSymbol: waypointSymbol,
    );
  }

  /// Deliver goods for a contract.
  factory ContractTransaction.delivery({
    required Contract contract,
    required int unitsDelivered,
    required ShipSymbol shipSymbol,
    required WaypointSymbol waypointSymbol,
    required DateTime timestamp,
  }) {
    return ContractTransaction._(
      contractId: contract.id,
      contractAction: ContractAction.delivery,
      unitsDelivered: unitsDelivered,
      creditsChange: 0,
      shipSymbol: shipSymbol,
      timestamp: timestamp,
      waypointSymbol: waypointSymbol,
    );
  }

  /// Fulfill a contract.
  factory ContractTransaction.fulfillment({
    required Contract contract,
    required ShipSymbol shipSymbol,
    required WaypointSymbol waypointSymbol,
    required DateTime timestamp,
  }) {
    return ContractTransaction._(
      contractId: contract.id,
      contractAction: ContractAction.fulfillment,
      unitsDelivered: null,
      creditsChange: contract.terms.payment.onFulfilled,
      shipSymbol: shipSymbol,
      timestamp: timestamp,
      waypointSymbol: waypointSymbol,
    );
  }

  /// The ID of the contract.
  final String contractId;

  /// The type of contract action.
  final ContractAction contractAction;

  /// The number of units delivered.
  final int? unitsDelivered;

  /// The change in credits.
  final int creditsChange;

  /// The ShipSymbol of the ship that performed the action.
  final ShipSymbol shipSymbol;

  /// The timestamp of the action.
  final DateTime timestamp;

  /// The location of the action.
  final WaypointSymbol waypointSymbol;
}
