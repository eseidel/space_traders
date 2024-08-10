import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:types/api.dart';
import 'package:types/src/construction.dart';
import 'package:types/src/contract_transaction.dart';
import 'package:types/src/symbol.dart';

/// The accounting type of a transaction.
enum AccountingType {
  /// Capital transaction (e.g. ships, mounts).
  capital,

  /// Fuel transaction (e.g. fuel for transport, not for sale).
  fuel,

  /// Goods transaction (e.g. buying/selling trade goods).
  goods;

  /// Construct an accounting type from json.
  static AccountingType fromJson(String name) {
    return AccountingType.values.firstWhere((e) => e.name == name);
  }

  /// Convert the accounting type to json.
  String toJson() => name;
}

/// The type of transaction which created this transaction.
enum TransactionType {
  /// A market transaction (buy or sell goods or refuel).
  market,

  /// A shipyard transaction (ship purchase).
  shipyard,

  /// A shipyard transaction (ship sale).
  scrapShip,

  /// A ship modification transaction (mount).
  shipModification,

  /// A contract transaction
  contract,

  /// Construction delivery
  construction;

  /// Construct a transaction type from json.
  static TransactionType fromJson(String name) {
    return TransactionType.values.firstWhere((e) => e.name == name);
  }

  /// Convert the transaction type to json.
  String toJson() => name;
}

/// A class to hold transaction data from a ship.
@immutable
class Transaction extends Equatable {
  /// Create a new transaction.
  const Transaction({
    required this.transactionType,
    required this.shipSymbol,
    required this.waypointSymbol,
    required this.tradeSymbol,
    required this.shipType,
    required this.tradeType,
    required this.quantity,
    required this.perUnitPrice,
    required this.timestamp,
    required this.agentCredits,
    required this.accounting,
    required this.contractId,
    required this.contractAction,
  });

  /// Create a new transaction to allow any() use in mocks.
  /// Can also be used for round-trip tests.  Uses all fields, but is not
  /// a valid transaction.
  @visibleForTesting
  Transaction.fallbackValue()
      : this(
          transactionType: TransactionType.market,
          shipSymbol: const ShipSymbol('A', 1),
          waypointSymbol: WaypointSymbol.fromString('S-E-P'),
          tradeSymbol: TradeSymbol.FUEL,
          shipType: ShipType.EXPLORER,
          quantity: 1,
          tradeType: MarketTransactionTypeEnum.PURCHASE,
          perUnitPrice: 2,
          timestamp: DateTime(2021).toUtc(),
          agentCredits: 3,
          accounting: AccountingType.goods,
          contractId: 'abcd',
          contractAction: ContractAction.delivery,
        );

  /// Create a new transaction from json.
  /// This only exists to support CostedDeal.fromJson and should be removed.
  factory Transaction.fromJson(Map<String, dynamic> json) {
    final transactionTypeJson = json['transactionType'];
    final TransactionType transactionType;
    // TODO(eseidel): Remove int check on next reset.
    if (transactionTypeJson is int) {
      transactionType = TransactionType.values[transactionTypeJson];
    } else {
      transactionType = TransactionType.fromJson(transactionTypeJson as String);
    }
    return Transaction(
      transactionType: transactionType,
      shipSymbol: ShipSymbol.fromJson(json['shipSymbol'] as String),
      waypointSymbol: WaypointSymbol.fromJson(json['waypointSymbol'] as String),
      tradeSymbol: TradeSymbol.fromJson(json['tradeSymbol'] as String?),
      shipType: ShipType.fromJson(json['shipType'] as String?),
      quantity: json['quantity'] as int,
      tradeType: MarketTransactionTypeEnum.values
          .firstWhere((e) => e.value == json['tradeType'] as String?),
      perUnitPrice: json['perUnitPrice'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      agentCredits: json['agentCredits'] as int,
      accounting: AccountingType.fromJson(json['accounting'] as String),
      contractId: json['contractId'] as String?,
      contractAction:
          ContractAction.fromJsonOrNull(json['contractAction'] as String?),
    );
  }

  /// Create a new transaction from a market transaction.
  factory Transaction.fromMarketTransaction(
    MarketTransaction transaction,
    int agentCredits,
    AccountingType accounting,
  ) {
    // Using a local to force non-null.
    final tradeSymbol = TradeSymbol.fromJson(transaction.tradeSymbol)!;
    return Transaction(
      transactionType: TransactionType.market,
      shipSymbol: transaction.shipSymbolObject,
      waypointSymbol: transaction.waypointSymbolObject,
      tradeSymbol: tradeSymbol,
      shipType: null,
      quantity: transaction.units,
      tradeType: transaction.type,
      perUnitPrice: transaction.pricePerUnit,
      timestamp: transaction.timestamp,
      agentCredits: agentCredits,
      accounting: accounting,
      contractId: null,
      contractAction: null,
    );
  }

  /// Create a new transaction from a shipyard transaction.
  factory Transaction.fromShipyardTransaction(
    ShipyardTransaction transaction,
    int agentCredits,
    ShipSymbol purchaser,
  ) {
    // shipSymbol is the trade symbol for the shipyard transaction, not
    // the new ship's id.
    // Using a local to force non-null.
    return Transaction(
      transactionType: TransactionType.shipyard,
      // .shipSymbol is the new ship type, not a ShipSymbol involved
      // in the transaction.
      // https://github.com/SpaceTradersAPI/api-docs/issues/68
      shipSymbol: purchaser,
      waypointSymbol: transaction.waypointSymbolObject,
      shipType: transaction.shipTypeObject,
      tradeSymbol: null,
      quantity: 1,
      tradeType: MarketTransactionTypeEnum.PURCHASE,
      perUnitPrice: transaction.price,
      timestamp: transaction.timestamp,
      agentCredits: agentCredits,
      accounting: AccountingType.capital,
      contractId: null,
      contractAction: null,
    );
  }

  /// Create a new transaction from a shipyard transaction.
  factory Transaction.fromScrapTransaction(
    ScrapTransaction transaction,
    int agentCredits,
    ShipSymbol shipSymbol,
  ) {
    // shipSymbol is the trade symbol for the shipyard transaction, not
    // the new ship's id.
    // Using a local to force non-null.
    return Transaction(
      transactionType: TransactionType.scrapShip,
      shipSymbol: shipSymbol,
      waypointSymbol: transaction.waypointSymbolObject,
      shipType: null, // Could use guessShipType.
      tradeSymbol: null,
      quantity: 1,
      tradeType: MarketTransactionTypeEnum.SELL,
      perUnitPrice: transaction.totalPrice,
      timestamp: transaction.timestamp,
      agentCredits: agentCredits,
      accounting: AccountingType.capital,
      contractId: null,
      contractAction: null,
    );
  }

  /// Create a new transaction from a ship modification transaction.
  factory Transaction.fromShipModificationTransaction(
    ShipModificationTransaction transaction,
    int agentCredits,
  ) {
    // Using a local to force non-null.
    final tradeSymbol = TradeSymbol.fromJson(transaction.tradeSymbol)!;
    assert(
      mountSymbolForTradeSymbol(tradeSymbol) != null,
      'Shipyard transaction with unknown mount symbol: $tradeSymbol',
    );
    return Transaction(
      transactionType: TransactionType.shipModification,
      // shipSymbol is the new ship, not the ship that made the transaction.
      shipSymbol: transaction.shipSymbolObject,
      waypointSymbol: transaction.waypointSymbolObject,
      tradeSymbol: tradeSymbol,
      shipType: null,
      quantity: 1,
      // This is more a service than a purchase.
      tradeType: MarketTransactionTypeEnum.PURCHASE,
      perUnitPrice: transaction.totalPrice,
      timestamp: transaction.timestamp,
      agentCredits: agentCredits,
      accounting: AccountingType.capital,
      contractId: null,
      contractAction: null,
    );
  }

  /// Create a new transaction from a contract transaction.
  factory Transaction.fromContractTransaction(
    ContractTransaction transaction,
    int agentCredits,
  ) {
    // This is a bit of a hack, using "creditsChange" as the per-unit-price
    // creditsChange is only non-zero for fulfillment transactions.
    final quantity = transaction.unitsDelivered ??
        (transaction.contractAction == ContractAction.fulfillment ? 1 : 0);
    final perUnitPrice = transaction.creditsChange;

    return Transaction(
      transactionType: TransactionType.contract,
      shipSymbol: transaction.shipSymbol,
      waypointSymbol: transaction.waypointSymbol,
      tradeSymbol: null,
      shipType: null,
      quantity: quantity,
      tradeType: null,
      perUnitPrice: perUnitPrice,
      timestamp: transaction.timestamp,
      agentCredits: agentCredits,
      accounting: AccountingType.goods,
      contractId: transaction.contractId,
      contractAction: transaction.contractAction,
    );
  }

  /// Create a new transaction from a construction delivery.
  factory Transaction.fromConstructionDelivery(
    ConstructionDelivery delivery,
    int agentCredits,
  ) {
    return Transaction(
      transactionType: TransactionType.construction,
      shipSymbol: delivery.shipSymbol,
      waypointSymbol: delivery.waypointSymbol,
      tradeSymbol: delivery.tradeSymbol,
      shipType: null,
      quantity: delivery.unitsDelivered,
      tradeType: null,
      perUnitPrice: 0,
      timestamp: delivery.timestamp,
      agentCredits: agentCredits,
      accounting: AccountingType.goods,
      contractId: null,
      contractAction: null,
    );
  }

  /// What type of market transaction created this transaction.
  final TransactionType transactionType;

  /// Ship symbol which made the transaction.
  final ShipSymbol shipSymbol;

  /// Waypoint symbol where the transaction was made.
  final WaypointSymbol waypointSymbol;

  /// Trade symbol of the transaction.
  final TradeSymbol? tradeSymbol;

  /// Only used for Shipyard transactions.
  final ShipType? shipType;

  /// Quantity of units transacted.
  final int quantity;

  /// Market transaction type (e.g. PURCHASE, SELL)
  final MarketTransactionTypeEnum? tradeType;

  /// Per-unit price of the transaction.
  final int perUnitPrice;

  /// Timestamp of the transaction.
  final DateTime timestamp;

  /// Credits of the agent after the transaction.
  final int agentCredits;

  /// The accounting classification of the transaction.
  final AccountingType accounting;

  /// The id of the contract involved in the transaction.
  final String? contractId;

  /// The action of the contract involved in the transaction.
  final ContractAction? contractAction;

  @override
  List<Object?> get props => [
        transactionType,
        shipSymbol,
        waypointSymbol,
        tradeSymbol,
        shipType,
        quantity,
        tradeType,
        perUnitPrice,
        timestamp,
        agentCredits,
        accounting,
        contractId,
        contractAction,
      ];

  /// The change in credits from this transaction.
  int get creditsChange {
    final sign = tradeType == MarketTransactionTypeEnum.PURCHASE ? -1 : 1;
    return sign * perUnitPrice * quantity;
  }

  /// Purchase from market.  tradeType can be null for non-market transactions.
  bool get isPurchase => tradeType == MarketTransactionTypeEnum.PURCHASE;

  /// Sale to market. tradeType can be null for non-market transactions.
  bool get isSale => tradeType == MarketTransactionTypeEnum.SELL;

  /// Convert the transaction to json.
  /// This only exists to support CostedDeal.toJson and should be removed.
  Map<String, dynamic> toJson() {
    return {
      'transactionType': transactionType.toJson(),
      'shipSymbol': shipSymbol.toJson(),
      'waypointSymbol': waypointSymbol.toJson(),
      'tradeSymbol': tradeSymbol?.toJson(),
      'shipType': shipType?.toJson(),
      'quantity': quantity,
      'tradeType': tradeType?.value,
      'perUnitPrice': perUnitPrice,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'agentCredits': agentCredits,
      'accounting': accounting.toJson(),
      'contractId': contractId,
      'contractAction': contractAction?.name,
    };
  }
}
