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
        builder: (context, data) => TransactionsView(data),
      ),
    );
  }
}

class TransactionsView extends StatelessWidget {
  const TransactionsView(this.data, {super.key});

  final GetTransactionsResponse data;

  @override
  Widget build(BuildContext context) {
    const c = creditsChangeString;
    final now = data.timestamp;
    final transactions = data.transactions;
    final tiles = <Widget>[];
    for (final t in transactions) {
      final duration = now.difference(t.timestamp);
      final since = approximateDuration(duration);
      tiles.add(
        ListTile(
          title: Text('${c(t.creditsChange)} $since ago'),
          subtitle: Text(
            '${t.tradeType} ${t.quantity} x ${t.unitName} '
            '${t.accounting.name} '
            'by ${t.shipSymbol.hexNumber} @ ${t.waypointSymbol}',
          ),
        ),
      );
    }

    return Column(children: [const Text('Transactions'), ...tiles]);
  }
}
