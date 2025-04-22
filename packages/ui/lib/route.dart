import 'package:client/client.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:protocol/protocol.dart';
import 'package:types/types.dart';
import 'package:ui/src/api_builder.dart';

/// The route configuration.
final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'fleet',
          builder: (BuildContext context, GoRouterState state) {
            return const FleetScreen();
          },
        ),
        GoRoute(
          path: 'fleet/inventory',
          builder: (BuildContext context, GoRouterState state) {
            return const FleetInventoryScreen();
          },
        ),
      ],
    ),
  ],
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ApiBuilder<AgentStatusResponse>(
      fetcher: (c) => c.getAgentStatus(),
      builder: buildWithData,
    );
  }

  Widget buildWithData(BuildContext context, AgentStatusResponse data) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('${data.name} of ${data.faction}'),
            Text('${data.numberOfShips} ships'),
            Text('Cash: ${creditsString(data.cash)}'),
            Text('Total Assets: ${data.totalAssets}'),
            Text('Gate Open: ${data.gateOpen}'),
            ElevatedButton(
              onPressed: () => context.go('/fleet'),
              child: const Text('Fleet'),
            ),
            ElevatedButton(
              onPressed: () => context.go('/fleet/inventory'),
              child: const Text('Fleet Inventory'),
            ),
          ],
        ),
      ),
    );
  }
}

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
    return ApiBuilder<GetFleetInventoryResponse>(
      fetcher: (c) => c.getFleetInventory(),
      builder: (context, data) {
        return ListView.builder(
          itemCount: data.items.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index == data.items.length) {
              return ListTile(
                title: const Text('Total Value'),
                subtitle: Text(creditsString(data.totalValue)),
              );
            }
            final item = data.items[index];
            final price = item.medianPrice;
            return ListTile(
              title: Text(item.tradeSymbol.value),
              subtitle: Text('${item.count} units'),
              trailing: Text(price != null ? creditsString(price) : '?'),
            );
          },
        );
      },
    );
  }
}
