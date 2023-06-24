import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/behavior/central_command.dart';
import 'package:space_traders_cli/behavior/contract_trader.dart';
import 'package:space_traders_cli/cache/caches.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:test/test.dart';

class _MockShipNav extends Mock implements ShipNav {}

class _MockApi extends Mock implements Api {}

class _MockShip extends Mock implements Ship {}

class _MockLogger extends Mock implements Logger {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockContractsApi extends Mock implements ContractsApi {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockCaches extends Mock implements Caches {}

void main() {
  test('advanceContractTrader smoke test', () async {
    final api = _MockApi();
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    final centralCommand = _MockCentralCommand();
    final caches = _MockCaches();

    final contractsApi = _MockContractsApi();
    when(() => api.contracts).thenReturn(contractsApi);
    when(
      () => contractsApi.getContracts(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) => Future.value(
        GetContracts200Response(meta: Meta(total: 0), data: []),
      ),
    );
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    when(() => fleetApi.negotiateContract(any())).thenAnswer(
      (_) => Future.value(
        NegotiateContract200Response(
          data: NegotiateContract200ResponseData(
            contract: Contract(
              id: 'id',
              factionSymbol: 'factionSymbol',
              type: ContractTypeEnum.PROCUREMENT,
              expiration: DateTime(2021),
              terms: ContractTerms(
                deadline: DateTime(2021),
                payment: ContractPayment(onAccepted: 100, onFulfilled: 100),
              ),
            ),
          ),
        ),
      ),
    );

    when(() => ship.symbol).thenReturn('S');
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.waypointSymbol).thenReturn('W');

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceContractTrader(
        api,
        centralCommand,
        caches,
        ship,
      ),
    );
    expect(waitUntil, isNull);
  });
}
