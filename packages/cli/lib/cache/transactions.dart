import 'package:cli/api.dart';
import 'package:cli/cache/json_log.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';

/// The accounting type of a transaction.
enum AccountingType {
  /// Capital transaction (e.g. ships, mounts).
  capital,

  /// Fuel transaction (e.g. fuel for transport, not for sale).
  fuel,

  /// Goods transaction (e.g. buying/selling trade goods).
  goods,
}

/// The type of transaction which created this transaction.
enum TransactionType {
  /// A market transaction.
  market,

  /// A shipyard transaction.
  shipyard,

  /// A ship modification transaction.
  shipModification,
}

Transaction _migrate(Map<String, dynamic> json) {
  assert(json['transactionType'] == null, 'Already migrated');
  final oldSymbol = json['tradeSymbol'] as String;
  var transactionType = TransactionType.market;
  ShipType? shipType;
  TradeSymbol? tradeSymbol;
  if (oldSymbol.startsWith('SHIP')) {
    transactionType = TransactionType.shipyard;
    shipType = ShipType.fromJson(oldSymbol);
  } else {
    if (oldSymbol.startsWith('MOUNT') && json['quantity'] == 1) {
      transactionType = TransactionType.shipModification;
    } else {
      transactionType = TransactionType.market;
    }
    tradeSymbol = TradeSymbol.fromJson(oldSymbol);
  }
  return Transaction(
    transactionType: transactionType,
    shipSymbol: ShipSymbol.fromJson(json['shipSymbol'] as String),
    waypointSymbol: WaypointSymbol.fromJson(json['waypointSymbol'] as String),
    tradeSymbol: tradeSymbol,
    shipType: shipType,
    quantity: json['quantity'] as int,
    tradeType: MarketTransactionTypeEnum.values
        .firstWhere((e) => e.value == json['tradeType'] as String),
    perUnitPrice: json['perUnitPrice'] as int,
    timestamp: DateTime.parse(json['timestamp'] as String),
    agentCredits: json['agentCredits'] as int,
    accounting: json['accounting'] == null
        ? null
        : AccountingType.values
            .firstWhere((e) => e.name == json['accounting'] as String),
  );
}

/// A class to hold transaction data from a ship.
@immutable
class Transaction {
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
  });

  /// Create a new transaction from json.
  factory Transaction.fromJson(Map<String, dynamic> json) {
    if (json['transactionType'] == null) {
      return _migrate(json);
    }
    return Transaction(
      transactionType: TransactionType.values
          .firstWhere((e) => e.index == json['transactionType'] as int),
      shipSymbol: ShipSymbol.fromJson(json['shipSymbol'] as String),
      waypointSymbol: WaypointSymbol.fromJson(json['waypointSymbol'] as String),
      tradeSymbol: TradeSymbol.fromJson(json['tradeSymbol'] as String?),
      shipType: ShipType.fromJson(json['shipType'] as String?),
      quantity: json['quantity'] as int,
      tradeType: MarketTransactionTypeEnum.values
          .firstWhere((e) => e.value == json['tradeType'] as String),
      perUnitPrice: json['perUnitPrice'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      agentCredits: json['agentCredits'] as int,
      accounting: json['accounting'] == null
          ? null
          : AccountingType.values
              .firstWhere((e) => e.name == json['accounting'] as String),
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
    final shipType = ShipType.fromJson(transaction.shipSymbol)!;
    return Transaction(
      transactionType: TransactionType.shipyard,
      // .shipSymbol is the new ship type, not a ShipSymbol involved
      // in the transaction.
      // https://github.com/SpaceTradersAPI/api-docs/issues/68
      shipSymbol: purchaser,
      waypointSymbol: transaction.waypointSymbolObject,
      shipType: shipType,
      tradeSymbol: null,
      quantity: 1,
      tradeType: MarketTransactionTypeEnum.PURCHASE,
      perUnitPrice: transaction.price,
      timestamp: transaction.timestamp,
      agentCredits: agentCredits,
      accounting: AccountingType.capital,
    );
  }

  /// Create a new transaction from a ship modification transaction.
  factory Transaction.fromShipModificationTransaction(
    ShipModificationTransaction transaction,
    int agentCredits,
  ) {
    // TODO(eseidel): Is this a ShipMountSymbol?
    // Using a local to force non-null.
    final tradeSymbol = TradeSymbol.fromJson(transaction.tradeSymbol)!;
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
  final MarketTransactionTypeEnum tradeType;

  /// Per-unit price of the transaction.
  final int perUnitPrice;

  /// Timestamp of the transaction.
  final DateTime timestamp;

  /// Credits of the agent after the transaction.
  final int agentCredits;

  /// The accounting classification of the transaction.
  final AccountingType? accounting;

  /// The change in credits from this transaction.
  int get creditChange {
    if (tradeType == MarketTransactionTypeEnum.PURCHASE) {
      return -perUnitPrice * quantity;
    } else {
      return perUnitPrice * quantity;
    }
  }

  /// Convert the transaction to json.
  Map<String, dynamic> toJson() {
    return {
      'transactionType': transactionType.index,
      'shipSymbol': shipSymbol.toJson(),
      'waypointSymbol': waypointSymbol.toJson(),
      'tradeSymbol': tradeSymbol?.toJson(),
      'shipType': shipType?.toJson(),
      'quantity': quantity,
      'tradeType': tradeType.value,
      'perUnitPrice': perUnitPrice,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'agentCredits': agentCredits,
      'accounting': accounting?.name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          transactionType == other.transactionType &&
          runtimeType == other.runtimeType &&
          shipSymbol == other.shipSymbol &&
          waypointSymbol == other.waypointSymbol &&
          tradeSymbol == other.tradeSymbol &&
          quantity == other.quantity &&
          tradeType == other.tradeType &&
          perUnitPrice == other.perUnitPrice &&
          timestamp == other.timestamp &&
          agentCredits == other.agentCredits;

  @override
  int get hashCode =>
      transactionType.hashCode ^
      shipSymbol.hashCode ^
      waypointSymbol.hashCode ^
      tradeSymbol.hashCode ^
      quantity.hashCode ^
      tradeType.hashCode ^
      perUnitPrice.hashCode ^
      timestamp.hashCode ^
      agentCredits.hashCode;
}

/// A class to manage a transaction log file.
class TransactionLog extends JsonLog<Transaction> {
  /// Create a new transaction log.
  TransactionLog(
    super.entries, {
    required super.fs,
    required super.path,
  }) : super(recordToJson: (record) => record.toJson());

  /// The default path to the transaction log.
  static const String defaultPath = 'data/transactions.json';

  /// Load the transaction log from the file system.
  // ignore: prefer_constructors_over_static_methods
  static TransactionLog load(
    FileSystem fs, {
    String path = defaultPath,
  }) {
    final entries = JsonLog.load<Transaction>(fs, path, Transaction.fromJson);
    return TransactionLog(entries, fs: fs, path: path);
  }

  /// Return transactions with the given filter applied.
  List<Transaction> where(bool Function(Transaction t) filter) {
    return entries.where(filter).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Return all the ship symbols in the transaction log.
  Set<ShipSymbol> get shipSymbols {
    return entries.map((e) => e.shipSymbol).toSet();
  }
}

/// Load all transactions from the file system.
// Hack around our lack of a real database or log rolling.
Iterable<Transaction> loadAllTransactions(FileSystem fs) {
  // This won't do anything if we don't have a transactions1.json file
  // since it defaults to an empty list.
  final transactionLogOld =
      TransactionLog.load(fs, path: 'data/transactions1.json');
  final transactionLog = TransactionLog.load(fs);
  return transactionLogOld.entries.followedBy(transactionLog.entries);
}
