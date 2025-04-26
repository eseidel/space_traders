import 'package:client/client.dart';
import 'package:flutter/material.dart';
import 'package:protocol/protocol.dart';
import 'package:ui/src/api_builder.dart';

class AccountingScreen extends StatelessWidget {
  const AccountingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounting')),
      body: ApiBuilder<AccountingSummaryResponse>(
        fetcher: (c) => c.getAccountingSummary(),
        builder: (context, data) {
          return Column(
            children: [
              BalanceSheetView(data.balanceSheet),
              const Divider(),
              IncomeStatementView(data.incomeStatement),
            ],
          );
        },
      ),
    );
  }
}

class BalanceSheetView extends StatelessWidget {
  const BalanceSheetView(this.balanceSheet, {super.key});

  final BalanceSheet balanceSheet;

  @override
  Widget build(BuildContext context) {
    const c = creditsString;
    final b = balanceSheet;
    return Column(
      children: [
        const Text('Balance Sheet'),
        Text('Cash: ${c(b.cash)}'),
        Text('Inventory: ${c(b.inventory)}'),
        Text('Total Current Assets: ${c(b.currentAssets)}'),
        Text('Equiptment: ${c(b.ships)}'),
        Text('Total Non-Current Assets: ${c(b.nonCurrentAssets)}'),
        Text('Total Assets: ${c(b.totalAssets)}'),
        Text('Loans: ${c(b.loans)}'),
        Text('Total Liabilities: ${c(b.totalLiabilities)}'),
      ],
    );
  }
}

class IncomeStatementView extends StatelessWidget {
  const IncomeStatementView(this.incomeStatement, {super.key});

  final IncomeStatement incomeStatement;

  @override
  Widget build(BuildContext context) {
    const c = creditsString;
    final i = incomeStatement;
    return Column(
      children: [
        const Text('Income Statement'),
        Text('Transactions: ${i.numberOfTransactions}'),
        Text('Start: ${i.start}'),
        Text('End: ${i.end}'),
        Text('Duration: ${approximateDuration(i.duration)}'),
        Text('Sales: ${c(i.goodsRevenue)}'),
        Text('Contracts: ${c(i.contractsRevenue)}'),
        Text('Asset Sales: ${c(i.assetSale)}'),
        Text('Total Revenues: ${c(i.revenue)}'),
        Text('Goods: ${c(i.goodsPurchase)}'),
        Text('Fuel: ${c(i.fuelPurchase)}'),
        Text('Total Cost of Goods Sold: ${c(i.costOfGoodsSold)}'),
        Text('COGS Ratio: ${i.cogsRatio.toStringAsFixed(1)}%'),
        Text('Gross Profit: ${c(i.grossProfit)}'),
        Text('Construction: ${c(i.constructionMaterials)}'),
        Text('Total Expenses: ${c(i.expenses)}'),
        Text('Net Income: ${c(i.netIncome)}'),
        Text('Net Income per second: ${c(i.netIncomePerSecond)}'),
      ],
    );
  }
}
