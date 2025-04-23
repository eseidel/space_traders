import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/src/routes.dart';

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
