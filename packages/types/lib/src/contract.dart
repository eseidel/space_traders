import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:openapi/api.dart' as openapi;
import 'package:types/api.dart';
import 'package:types/types.dart';

/// A contract to deliver goods to a faction.
class Contract {
  /// Returns a new [Contract] instance.
  Contract({
    required this.id,
    required this.factionSymbol,
    required this.type,
    required this.terms,
    required this.deadlineToAccept,
    required this.accepted,
    required this.fulfilled,
    required this.timestamp,
  });

  /// Makes a new Contract for testing.
  @visibleForTesting
  Contract.test({
    required this.id,
    required this.terms,
    String? factionSymbol,
    ContractType? type,
    DateTime? deadlineToAccept,
    bool? accepted,
    bool? fulfilled,
    DateTime? timestamp,
  }) : factionSymbol = factionSymbol ?? 'faction',
       type = type ?? ContractType.PROCUREMENT,
       deadlineToAccept =
           deadlineToAccept ??
           DateTime.timestamp().add(const Duration(days: 1)),
       accepted = accepted ?? false,
       fulfilled = fulfilled ?? false,
       timestamp = timestamp ?? DateTime.timestamp();

  /// Makes a new Contract with a fallback value for testing.
  @visibleForTesting
  Contract.fallbackValue()
    : id = 'fallback',
      factionSymbol = 'faction',
      type = ContractType.PROCUREMENT,
      terms = ContractTerms(
        payment: ContractPayment(onFulfilled: 0, onAccepted: 0),
        deadline: DateTime.timestamp(),
        deliver: [],
      ),
      deadlineToAccept = DateTime.timestamp(),
      accepted = false,
      fulfilled = false,
      timestamp = DateTime.timestamp();

  /// Makes a Contract from OpenAPI.
  Contract.fromOpenApi(openapi.Contract contract, this.timestamp)
    : id = contract.id,
      factionSymbol = contract.factionSymbol,
      type = contract.type,
      terms = contract.terms,
      accepted = contract.accepted,
      fulfilled = contract.fulfilled,
      deadlineToAccept = contract.deadlineToAccept!;

  /// Makes a Contract from JSON.
  Contract.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      factionSymbol = json['factionSymbol'] as String,
      type = ContractType.fromJson(json['type'] as String),
      terms = ContractTerms.fromJson(json['terms'] as Map<String, dynamic>),
      deadlineToAccept = DateTime.parse(json['deadlineToAccept'] as String),
      accepted = json['accepted'] as bool,
      fulfilled = json['fulfilled'] as bool,
      timestamp = DateTime.parse(json['timestamp'] as String);

  /// Converts the Contract to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'factionSymbol': factionSymbol,
      'type': type.value,
      'terms': terms.toJson(),
      'deadlineToAccept': deadlineToAccept.toIso8601String(),
      'accepted': accepted,
      'fulfilled': fulfilled,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// ID of the contract.
  String id;

  /// The symbol of the faction that this contract is for.
  String factionSymbol;

  /// Type of contract.
  ContractType type;

  /// The terms of the contract.
  ContractTerms terms;

  /// Whether the contract has been accepted by the agent
  bool accepted;

  /// Whether the contract has been fulfilled
  bool fulfilled;

  /// The time at which the contract is no longer available to be accepted
  DateTime deadlineToAccept;

  /// Time when this contract was fetched from the server.
  DateTime timestamp;

  /// Returns the contract as OpenAPI object.
  openapi.Contract toOpenApi() {
    return openapi.Contract(
      id: id,
      factionSymbol: factionSymbol,
      type: type,
      terms: terms,
      accepted: accepted,
      fulfilled: fulfilled,
      deadlineToAccept: deadlineToAccept,
      expiration: deadlineToAccept,
    );
  }

  /// Returns the ContractDeliverGood for the given trade good symbol or null if
  /// the contract doesn't need that good.
  openapi.ContractDeliverGood? goodNeeded(openapi.TradeSymbol tradeSymbol) {
    return terms.deliver.firstWhereOrNull(
      (item) => item.tradeSymbol == tradeSymbol.value,
    );
  }

  /// Returns true if the contract has expired.
  bool get isExpired {
    final now = DateTime.timestamp();
    if (!accepted) {
      return now.isAfter(deadlineToAccept);
    }
    return now.isAfter(terms.deadline);
  }
}
