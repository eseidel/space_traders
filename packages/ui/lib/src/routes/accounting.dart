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

Widget _row(String label, String value, {bool isBold = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label),
      Text(
        value,
        style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null,
      ),
    ],
  );
}

class BalanceSheetView extends StatelessWidget {
  const BalanceSheetView(this.balanceSheet, {super.key});

  final BalanceSheet balanceSheet;

  @override
  Widget build(BuildContext context) {
    const c = creditsString;
    final b = balanceSheet;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          const Text('Balance Sheet'),
          _row('Cash', c(b.cash)),
          _row('Inventory', c(b.inventory)),
          _row('Total Current Assets', c(b.currentAssets), isBold: true),
          const Divider(),
          _row('Equipment', c(b.ships)),
          _row('Total Non-Current Assets', c(b.nonCurrentAssets), isBold: true),
          const Divider(),
          _row('Total Assets', c(b.totalAssets), isBold: true),
          const Divider(),
          _row('Loans', c(b.loans)),
          _row('Total Liabilities', c(b.totalLiabilities), isBold: true),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          const Text('Income Statement'),
          _row('Transactions', i.numberOfTransactions.toString()),
          _row('Start', i.start.toString()),
          _row('End', i.end.toString()),
          _row('Duration', approximateDuration(i.duration)),
          const Divider(),
          _row('Sales', c(i.goodsRevenue)),
          _row('Contracts', c(i.contractsRevenue)),
          _row('Asset Sales', c(i.assetSale)),
          _row('Charting', c(i.chartingRevenue)),
          _row('Total Revenues', c(i.revenue), isBold: true),
          const Divider(),
          _row('Goods', c(i.goodsPurchase)),
          _row('Fuel', c(i.fuelPurchase)),
          _row('Total Cost of Goods Sold', c(i.costOfGoodsSold), isBold: true),
          _row('COGS Ratio', '${(i.cogsRatio * 100).toStringAsFixed(1)}%'),
          const Divider(),
          _row('Gross Profit', c(i.grossProfit), isBold: true),
          const Divider(),
          _row('Construction', c(i.constructionMaterials)),
          _row('Total Expenses', c(i.expenses), isBold: true),
          const Divider(),
          _row('Net Income', c(i.netIncome), isBold: true),
          _row('Net Income per second', c(i.netIncomePerSecond)),
        ],
      ),
    );
  }
}
