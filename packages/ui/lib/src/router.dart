import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/src/routes.dart';
import 'package:ui/src/routes/deals.dart';

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
          path: 'accounting',
          builder: (BuildContext context, GoRouterState state) {
            return const AccountingScreen();
          },
        ),
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
        GoRoute(
          path: 'accounting/transactions/recent',
          builder: (BuildContext context, GoRouterState state) {
            return const TransactionsScreen();
          },
        ),
        GoRoute(
          path: 'system_stats',
          builder: (BuildContext context, GoRouterState state) {
            return const SystemStatsScreen();
          },
        ),
        GoRoute(
          path: 'explore/map',
          builder: (BuildContext context, GoRouterState state) {
            return const MapScreen();
          },
        ),
        GoRoute(
          path: 'deals/nearby',
          builder: (BuildContext context, GoRouterState state) {
            return const DealsNearbyScreen();
          },
        ),
      ],
    ),
  ],
);
