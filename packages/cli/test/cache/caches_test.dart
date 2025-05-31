import 'package:cli/cli.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockAgentsApi extends Mock implements AgentsApi {}

class _MockApi extends Mock implements Api {}

class _MockBehaviorStore extends Mock implements BehaviorStore {}

class _MockConstructionStore extends Mock implements ConstructionStore {}

class _MockContractsApi extends Mock implements ContractsApi {}

class _MockDataApi extends Mock implements DataApi {}

class _MockDatabase extends Mock implements Database {}

class _MockFactionsApi extends Mock implements FactionsApi {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockGlobalApi extends Mock implements GlobalApi {}

class _MockJumpGateStore extends Mock implements JumpGateStore {}

class _MockLogger extends Mock implements Logger {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockMarketListingStore extends Mock implements MarketListingStore {}

class _MockMarketPriceStore extends Mock implements MarketPriceStore {}

class _MockRoutePlanner extends Mock implements RoutePlanner {}

class _MockShipyardListingStore extends Mock implements ShipyardListingStore {}

class _MockShipyardPriceStore extends Mock implements ShipyardPriceStore {}

class _MockSystemConnectivity extends Mock implements SystemConnectivity {}

class _MockSystemsApi extends Mock implements SystemsApi {}

class _MockSystemsStore extends Mock implements SystemsStore {}

class _MockWaypointCache extends Mock implements WaypointCache {}

void main() {
  test('Caches load test', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final systemsStore = _MockSystemsStore();
    when(() => db.systems).thenReturn(systemsStore);
    final agentsApi = _MockAgentsApi();
    when(() => api.agents).thenReturn(agentsApi);
    final agent = Agent.test();
    when(db.getMyAgent).thenAnswer((_) => Future.value(agent));
    when(agentsApi.getMyAgent).thenAnswer(
      (_) => Future.value(GetMyAgent200Response(data: agent.toOpenApi())),
    );
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    when(
      () => fleetApi.getMyShips(
        limit: any(named: 'limit'),
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) =>
          Future.value(GetMyShips200Response(meta: Meta(total: 0), data: [])),
    );
    final contractsApi = _MockContractsApi();
    when(() => api.contracts).thenReturn(contractsApi);
    when(
      () => contractsApi.getContracts(
        limit: any(named: 'limit'),
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) =>
          Future.value(GetContracts200Response(meta: Meta(total: 0), data: [])),
    );
    final factionsApi = _MockFactionsApi();
    when(() => api.factions).thenReturn(factionsApi);
    when(
      () => factionsApi.getFactions(
        limit: any(named: 'limit'),
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) =>
          Future.value(GetFactions200Response(meta: Meta(total: 0), data: [])),
    );
    when(db.allFactions).thenAnswer((_) => Future.value(<Faction>[]));
    registerFallbackValue(
      Faction(
        symbol: FactionSymbol.ANCIENTS,
        name: '',
        description: '',
        headquarters: '',
        isRecruiting: false,
      ),
    );
    when(() => db.upsertFaction(any())).thenAnswer((_) async => {});

    final constructionStore = _MockConstructionStore();
    when(() => db.construction).thenReturn(constructionStore);
    when(
      constructionStore.snapshotAll,
    ).thenAnswer((_) async => ConstructionSnapshot([]));

    when(
      constructionStore.all,
    ).thenAnswer((_) => Future.value(<ConstructionRecord>[]));

    final jumpGateStore = _MockJumpGateStore();
    when(() => db.jumpGates).thenReturn(jumpGateStore);
    when(
      jumpGateStore.snapshotAll,
    ).thenAnswer((_) async => JumpGateSnapshot([]));

    final marketListingStore = _MockMarketListingStore();
    when(() => db.marketListings).thenReturn(marketListingStore);
    when(
      marketListingStore.marketsSellingFuel,
    ).thenAnswer((_) async => <WaypointSymbol>{});

    final marketPriceStore = _MockMarketPriceStore();
    when(() => db.marketPrices).thenReturn(marketPriceStore);
    when(
      marketPriceStore.snapshotAll,
    ).thenAnswer((_) async => MarketPriceSnapshot([]));

    final shipyardListingStore = _MockShipyardListingStore();
    when(() => db.shipyardListings).thenReturn(shipyardListingStore);
    when(shipyardListingStore.all).thenAnswer((_) async => []);

    final shipyardPriceStore = _MockShipyardPriceStore();
    when(() => db.shipyardPrices).thenReturn(shipyardPriceStore);
    when(
      shipyardPriceStore.snapshotAll,
    ).thenAnswer((_) async => ShipyardPriceSnapshot([]));

    final behaviorStore = _MockBehaviorStore();
    when(() => db.behaviors).thenReturn(behaviorStore);
    when(behaviorStore.all).thenAnswer((_) async => []);
    when(
      systemsStore.snapshotAllSystems,
    ).thenAnswer((_) async => SystemsSnapshot([]));

    final dataApi = _MockDataApi();
    when(() => api.data).thenReturn(dataApi);
    registerFallbackValue(TradeExport);
    when(
      () => db.getAllFromStaticCache(type: any(named: 'type')),
    ).thenAnswer((_) async => []);
    when(dataApi.getSupplyChain).thenAnswer(
      (_) async => GetSupplyChain200Response(
        data: GetSupplyChain200ResponseData(
          exportToImportMap: GetSupplyChain200ResponseDataExportToImportMap(
            entries: {},
          ),
        ),
      ),
    );

    final globalApi = _MockGlobalApi();
    when(() => api.global).thenReturn(globalApi);
    final status = GetStatus200Response(
      announcements: [],
      version: '1.0.0',
      resetDate: '2021-01-01',
      description: '',
      leaderboards: GetStatus200ResponseLeaderboards(
        mostCredits: [],
        mostSubmittedCharts: [],
      ),
      serverResets: GetStatus200ResponseServerResets(
        next: '2021-01-01',
        frequency: 'daily',
      ),
      stats: GetStatus200ResponseStats(
        systems: 100,
        waypoints: 100,
        agents: 100,
        ships: 100,
      ),
      health: GetStatus200ResponseHealth(),
      status: 'OK',
    );
    when(globalApi.getStatus).thenAnswer((_) => Future.value(status));
    final logger = _MockLogger();
    Never httpGet(f) => throw UnimplementedError();
    final caches = await runWithLogger(
      logger,
      () async => Caches.loadOrFetch(api, db, httpGet: httpGet),
    );
    expect(caches.galaxy.systemCount, 100);
    expect(caches.galaxy.waypointCount, 100);
  });

  test('updateRoutingCaches', () async {
    final db = _MockDatabase();
    final systemsStore = _MockSystemsStore();
    when(() => db.systems).thenReturn(systemsStore);

    final constructionStore = _MockConstructionStore();
    when(() => db.construction).thenReturn(constructionStore);
    when(
      constructionStore.snapshotAll,
    ).thenAnswer((_) async => ConstructionSnapshot([]));

    final jumpGateStore = _MockJumpGateStore();
    when(() => db.jumpGates).thenReturn(jumpGateStore);
    when(
      jumpGateStore.snapshotAll,
    ).thenAnswer((_) async => JumpGateSnapshot([]));

    final marketListingStore = _MockMarketListingStore();
    when(() => db.marketListings).thenReturn(marketListingStore);
    when(
      marketListingStore.marketsSellingFuel,
    ).thenAnswer((_) async => <WaypointSymbol>{});

    final caches = Caches(
      marketPrices: MarketPriceSnapshot([]),
      systems: SystemsSnapshot([]),
      waypoints: _MockWaypointCache(),
      markets: _MockMarketCache(),
      routePlanner: _MockRoutePlanner(),
      systemConnectivity: _MockSystemConnectivity(),
      galaxy: const GalaxyStats(systemCount: 2, waypointCount: 2),
      factions: [],
    );

    // If we've not cached the systems, we need to snapshot them.
    final logger = _MockLogger();
    when(systemsStore.snapshotAllSystems).thenAnswer(
      (_) async => SystemsSnapshot([
        System.test(
          SystemSymbol.fromString('A-B'),
          waypoints: [SystemWaypoint.test(WaypointSymbol.fromString('A-B-C'))],
        ),
        System.test(
          SystemSymbol.fromString('A-C'),
          waypoints: [SystemWaypoint.test(WaypointSymbol.fromString('A-C-E'))],
        ),
      ]),
    );
    expect(caches.systems.systemsCount, 0);
    expect(caches.systems.waypointsCount, 0);
    await runWithLogger(logger, () async {
      await caches.updateRoutingCaches(db);
    });
    expect(caches.systems.systemsCount, 2);
    expect(caches.systems.waypointsCount, 2);
    verify(() => logger.info('Systems Snapshot is incomplete, reloading.'));
    verify(() => db.systems.snapshotAllSystems()).called(1);
    verify(() => db.jumpGates.snapshotAll()).called(1);
    verify(() => db.construction.snapshotAll()).called(1);
    verify(() => db.marketListings.marketsSellingFuel()).called(1);

    await caches.updateRoutingCaches(db);
    // If we've already cached the systems, we don't need to snapshot them again
    verifyNever(() => db.systems.snapshotAllSystems());
  });

  test('fetchAndCacheMyAgent', () async {
    final db = _MockDatabase();
    final api = _MockApi();
    final agentsApi = _MockAgentsApi();
    when(() => api.agents).thenReturn(agentsApi);
    final agent = Agent.test();
    final response = GetMyAgent200Response(data: agent.toOpenApi());
    when(agentsApi.getMyAgent).thenAnswer((_) async => response);
    registerFallbackValue(agent);
    when(() => db.upsertAgent(any())).thenAnswer((_) async => {});
    await runWithLogger(
      _MockLogger(),
      () async => fetchAndCacheMyAgent(db, api),
    );
    verify(agentsApi.getMyAgent).called(1);
    verify(() => db.upsertAgent(agent)).called(1);
  });

  test('getOrFetchJumpGate', () async {
    final db = _MockDatabase();
    final api = _MockApi();
    final systemsApi = _MockSystemsApi();
    when(() => api.systems).thenReturn(systemsApi);

    final symbol = WaypointSymbol.fromString('A-B-C');
    final jumpGate = JumpGate(waypointSymbol: symbol, connections: const {});
    registerFallbackValue(jumpGate);
    final jumpGateStore = _MockJumpGateStore();
    when(() => db.jumpGates).thenReturn(jumpGateStore);

    when(() => jumpGateStore.get(symbol)).thenAnswer((_) async => jumpGate);
    final result = await getOrFetchJumpGate(db, api, symbol);
    expect(result, jumpGate);
    verify(() => jumpGateStore.get(symbol)).called(1);
    verifyNever(() => jumpGateStore.upsert(any()));
    verifyNever(
      () => systemsApi.getJumpGate(symbol.systemString, symbol.waypoint),
    );

    // If the jump gate is not in the database, we should fetch it from the API
    // and cache it.
    when(() => jumpGateStore.get(symbol)).thenAnswer((_) async => null);
    when(
      () => systemsApi.getJumpGate(symbol.systemString, symbol.waypoint),
    ).thenAnswer(
      (_) async => GetJumpGate200Response(data: jumpGate.toOpenApi()),
    );
    when(() => jumpGateStore.upsert(any())).thenAnswer((_) async => {});
    final result2 = await getOrFetchJumpGate(db, api, symbol);
    expect(result2, jumpGate);
    verify(() => jumpGateStore.get(symbol)).called(1);
    verify(
      () => systemsApi.getJumpGate(symbol.systemString, symbol.waypoint),
    ).called(1);
    verify(() => jumpGateStore.upsert(jumpGate)).called(1);
  });
}
