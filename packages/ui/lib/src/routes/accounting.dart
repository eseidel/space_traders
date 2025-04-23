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
  const BalanceSheetView(this.balance, {super.key});

  final BalanceSheet balance;

  @override
  Widget build(BuildContext context) {
    const c = creditsString;
    return Column(
      children: [
        const Text('Balance Sheet'),
        Text('Cash: ${c(balance.cash)}'),
        Text('Assets: ${c(balance.totalAssets)}'),
        Text('Liabilities: ${c(balance.totalLiabilities)}'),
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
    return Column(
      children: [
        const Text('Income Statement'),
        Text('Revenue: ${c(incomeStatement.revenue)}'),
        Text('Expenses: ${c(incomeStatement.expenses)}'),
        Text('Net Income: ${c(incomeStatement.netIncome)}'),
      ],
    );
  }
}
