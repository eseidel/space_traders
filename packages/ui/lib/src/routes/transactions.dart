import 'package:client/client.dart';
import 'package:flutter/material.dart';
import 'package:protocol/protocol.dart';
import 'package:ui/src/api_builder.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recent Transactions')),
      body: ApiBuilder<GetTransactionsResponse>(
        fetcher: (c) => c.getRecentTransactions(),
        builder: (context, data) => TransactionsView(data.transactions),
      ),
    );
  }
}

class TransactionsView extends StatelessWidget {
  const TransactionsView(this.transactions, {super.key});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    const c = creditsString;
    return Column(
      children: [
        const Text('Transactions'),
        for (final t in transactions)
          ListTile(
            title: Text('${t.timestamp} ${t.tradeSymbol}'),
            subtitle: Text(
              '${t.quantity} ${t.tradeType} '
              '${t.shipSymbol} ${t.waypointSymbol} '
              '${c(t.creditsChange)} ${t.accounting}',
            ),
          ),
      ],
    );
  }
}
