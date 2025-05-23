import 'package:client/client.dart';
import 'package:flutter/material.dart';
import 'package:protocol/protocol.dart';
import 'package:ui/src/api_builder.dart';

class DealsNearbyScreen extends StatelessWidget {
  const DealsNearbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deals Nearby')),
      body: ApiBuilder<DealsNearbyResponse>(
        fetcher: (c) => c.getNearbyDeals(),
        builder: (context, data) => DealsList(deals: data.deals),
      ),
    );
  }
}

class DealsList extends StatelessWidget {
  const DealsList({required this.deals, super.key});

  final List<NearbyDeal> deals;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: deals.length,
      itemBuilder: (BuildContext context, int index) {
        final deal = deals[index];
        return ListTile(
          title: Text(deal.deal.tradeSymbol.toString()),
          subtitle: Text(
            '${deal.deal.sourceSymbol} -> ${deal.deal.destinationSymbol}',
          ),
          trailing: deal.inProgress
              ? const Icon(Icons.hourglass_empty)
              : const Icon(Icons.check_circle),
        );
      },
    );
  }
}
