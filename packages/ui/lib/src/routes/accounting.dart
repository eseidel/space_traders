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
        Text('Ships: ${c(b.ships)}'),
        Text('Total Assets: ${c(b.totalAssets)}'),
        Text('Liabilities: ${c(b.totalLiabilities)}'),
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
        Text('Revenue: ${c(i.revenue)}'),
        Text('COGS: ${c(i.costOfGoodsSold)}'),
        Text('Gross Profit: ${c(i.grossProfit)}'),
        Text('Expenses: ${c(i.expenses)}'),
        Text('Net Income: ${c(i.netIncome)}'),
      ],
    );
  }
}
