import 'package:client/client.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:protocol/protocol.dart';
import 'package:ui/src/api_builder.dart';

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
            Text('Gate Open: ${data.gateOpen}'),
            Text('Game Phase: ${data.gamePhase.name}'),
            ElevatedButton(
              onPressed: () => context.go('/fleet'),
              child: const Text('Fleet'),
            ),
            ElevatedButton(
              onPressed: () => context.go('/fleet/inventory'),
              child: const Text('Fleet Inventory'),
            ),
            ElevatedButton(
              onPressed: () => context.go('/accounting'),
              child: const Text('Accounting'),
            ),
            ElevatedButton(
              onPressed: () => context.go('/accounting/transactions/recent'),
              child: const Text('Recent Transactions'),
            ),
            ElevatedButton(
              onPressed: () => context.go('/system_stats'),
              child: const Text('System Stats'),
            ),
          ],
        ),
      ),
    );
  }
}
