import 'package:json_annotation/json_annotation.dart';

part 'accounting.g.dart';

/// A class representing the assets of the agent.
@JsonSerializable()
class BalanceSheet {
  /// Creates an instance of [BalanceSheet].
  BalanceSheet({
    required this.time,
    required this.cash,
    required this.inventory,
    required this.ships,
  });

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

  // TODO(eseidel): Include contract loans as liabilities.

  /// The total value of the agent's assets.
  int get total => cash + inventory + ships;

  Map<String, dynamic> toJson() => _$BalanceSheetToJson(this);
}

/// A class representing an income statement.
@JsonSerializable()
class IncomeStatement {
  /// Creates an instance of [IncomeStatement].
  IncomeStatement({
    required this.start,
    required this.end,
    required this.sales,
    required this.contracts,
    required this.goods,
    required this.fuel,
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

  /// The number of transactions in the period.
  final int numberOfTransactions;

  /// The total income from sales for the period.
  final int sales;

  /// The total income from contracts for the period.
  final int contracts;

  /// Total cost of goods sold.
  final int goods;

  /// Total fuel cost.
  final int fuel;
  // final int constructionMaterials;
  // final int subsidies;
  // final int categorizationPending;

  /// Ship purchases do not show up as a P&L item.
  /// But they are reflected in the net cash flow.
  final int capEx;

  /// The total income for the period.
  /// There seems to be some debate as to if fuel counts as COGS or not,
  /// for now we're counting it as such.
  int get totalRevenue => sales + contracts + fuel;

  /// The total cost of goods sold for the period.
  int get totalCostOfGoodsSold => goods;

  /// The gross profit for the period.
  int get grossProfit => totalRevenue - totalCostOfGoodsSold;

  /// The total expenses for the period.
  int get totalExpenses => 0;
  // constructionMaterials + subsidies + categorizationPending;

  /// The net income for the period.
  int get netIncome => grossProfit - totalExpenses;

  /// The net cash flow for the period.
  int get netCashFlow => netIncome - capEx;

  /// Converts the [IncomeStatement] to a JSON object.
  Map<String, dynamic> toJson() => _$IncomeStatementToJson(this);
}
