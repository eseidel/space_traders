import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:types/types.dart';

/// The route configuration.
final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const FleetScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'details',
          builder: (BuildContext context, GoRouterState state) {
            return const DetailsScreen();
          },
        ),
      ],
    ),
  ],
);

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

final Uri baseUri = Uri.parse('http://localhost:8081');

class _FleetScreenState extends State<FleetScreen> {
  List<Ship> ships = <Ship>[];
  bool loading = true;

  Future<void> refresh() async {
    final uri = baseUri.replace(path: '/ships');
    print(uri);
    final response = await http.get(uri);
    final json = jsonDecode(response.body) as List<dynamic>;
    final newShips = json
        .map((dynamic item) => Ship.fromJson(item as Map<String, dynamic>))
        .toList();
    setState(() {
      ships = newShips;
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet')),
      body: ListView.builder(
        itemCount: ships.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(ships[index].symbol.symbol),
            subtitle: Text(ships[index].toString()),
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/details'),
          child: const Text('Go to the Details screen'),
        ),
      ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/'),
          child: const Text('Go back to the Home screen'),
        ),
      ),
    );
  }
}
