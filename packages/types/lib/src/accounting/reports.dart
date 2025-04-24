import 'package:json_annotation/json_annotation.dart';

part 'reports.g.dart';

/// A class representing the assets of the agent.
@JsonSerializable()
class BalanceSheet {
  /// Creates an instance of [BalanceSheet].
  BalanceSheet({
    required this.time,
    required this.cash,
    required this.loans,
    required this.inventory,
    required this.ships,
  });

  /// Creates an instance of [BalanceSheet] from a JSON object.
  factory BalanceSheet.fromJson(Map<String, dynamic> json) =>
      _$BalanceSheetFromJson(json);

  /// Balance sheets represent a snapshot in time.
  final DateTime time;

  /// The amount of cash the agent has.
  final int cash;

  /// The value of the agent's inventory.
  final int inventory;

  /// The value of the agent's ships (including modules).
  final int ships;

  /// Total value of contract loans (until forgiven on delivery).
  final int loans;

  /// The total value of the agent's assets.
  int get totalAssets => cash + inventory + ships;

  /// The total value of the agent's liabilities.
  int get totalLiabilities => loans;

  /// The total value of the agent's balance sheet.
  int get total => totalAssets - totalLiabilities;

  /// Converts the [BalanceSheet] to a JSON object.
  Map<String, dynamic> toJson() => _$BalanceSheetToJson(this);
}

/// A class representing an income statement.
@JsonSerializable()
class IncomeStatement {
  /// Creates an instance of [IncomeStatement].
  IncomeStatement({
    required this.start,
    required this.end,
    required this.goodsRevenue,
    required this.contractsRevenue,
    required this.goodsPurchase,
    required this.assetSale,
    required this.constructionMaterials,
    required this.fuelPurchase,
    required this.capEx,
    required this.numberOfTransactions,
  });

  /// Creates an instance of [IncomeStatement] from a JSON object.
  factory IncomeStatement.fromJson(Map<String, dynamic> json) =>
      _$IncomeStatementFromJson(json);

  /// The start date of the income statement.
  final DateTime start;

  /// The end date of the income statement.
  final DateTime end;

  /// The duration of the income statement.
  Duration get duration => end.difference(start);

  /// The number of transactions in the period.
  final int numberOfTransactions;

  /// The total revenue from trading sales for the period.
  final int goodsRevenue;

  /// The total revenue from contracts for the period.
  final int contractsRevenue;

  /// The total income from asset sales for the period (one-offs).
  final int assetSale;

  /// Total cost of goods purchased for resale.
  final int goodsPurchase;

  /// Total cost of fuel purchased for consumption or resale
  /// (not currently separated).
  final int fuelPurchase;

  /// Total cost of construction materials purchased (one time expense).
  final int constructionMaterials;

  // final int subsidies;
  // final int categorizationPending;

  /// Ship purchases do not show up as a P&L item.
  /// But they are reflected in the net cash flow.
  final int capEx;

  /// The total income for the period.
  /// There seems to be some debate as to if fuel counts as COGS or not,
  /// for now we're counting it as such.
  int get revenue => goodsRevenue + contractsRevenue + assetSale;

  /// Net sales for the period, does not include asset sales.
  int get netSales => goodsRevenue + contractsRevenue;

  /// The total cost of goods sold for the period.
  int get costOfGoodsSold => goodsPurchase + fuelPurchase;

  /// Ratio of cost of goods sold to net sales revenue.
  double get cogsRatio => netSales == 0 ? 0 : costOfGoodsSold / netSales;

  /// The gross profit for the period.
  int get grossProfit => revenue - costOfGoodsSold;

  /// The total expenses for the period.
  int get expenses => constructionMaterials;
  // constructionMaterials + subsidies + categorizationPending;

  /// The net income for the period.
  int get netIncome => grossProfit - expenses;

  /// The net income per second over the period.
  double get netIncomePerSecond {
    return duration.inSeconds == 0 ? 0 : netIncome / duration.inSeconds;
  }

  /// The net cash flow for the period.
  int get netCashFlow => netIncome - capEx;

  /// Converts the [IncomeStatement] to a JSON object.
  Map<String, dynamic> toJson() => _$IncomeStatementToJson(this);
}
