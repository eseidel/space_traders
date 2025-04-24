import 'package:client/client.dart';
import 'package:flutter/material.dart';
import 'package:protocol/protocol.dart';
import 'package:ui/src/api_builder.dart';

class FleetScreen extends StatelessWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet')),
      body: const FleetList(),
    );
  }
}

class FleetList extends StatelessWidget {
  const FleetList({super.key});

  @override
  Widget build(BuildContext context) {
    return ApiBuilder<FleetShipsResponse>(
      fetcher: (c) => c.getFleetShips(),
      builder: (context, data) {
        return ListView.builder(
          itemCount: data.ships.length,
          itemBuilder: (BuildContext context, int index) {
            final ship = data.ships[index];
            final cargoStatus =
                ship.cargo.capacity == 0
                    ? ''
                    : '${ship.cargo.units}/${ship.cargo.capacity}';

            return ListTile(
              title: Text(ship.symbol.hexNumber),
              subtitle: Text(ship.nav.waypointSymbol),
              leading: Text(cargoStatus),
            );
          },
        );
      },
    );
  }
}

class FleetInventoryScreen extends StatelessWidget {
  const FleetInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Inventory')),
      body: const FleetInventoryList(),
    );
  }
}

class FleetInventoryList extends StatelessWidget {
  const FleetInventoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return ApiBuilder<PricedInventory>(
      fetcher: (c) => c.getFleetInventory(),
      builder: (context, data) {
        return ListView.builder(
          itemCount: data.items.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index == data.items.length) {
              return ListTile(
                title: const Text('Total Value'),
                trailing: Text(creditsString(data.totalValue)),
              );
            }
            final item = data.items[index];
            final value = item.totalValue;
            return ListTile(
              title: Text('${item.count} x ${item.tradeSymbol.value}'),
              trailing: Text(value != null ? creditsString(value) : '?'),
            );
          },
        );
      },
    );
  }
}
