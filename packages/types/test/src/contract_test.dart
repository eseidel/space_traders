import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockContractTerms extends Mock implements ContractTerms {}

void main() {
  test('Contract types', () {
    final contractTerms = _MockContractTerms();
    final contract = Contract.test(id: 'id', terms: contractTerms);
    when(
      () => contractTerms.payment,
    ).thenReturn(ContractPayment(onAccepted: 10, onFulfilled: 20));

    const shipSymbol = ShipSymbol('S', 1);
    final waypointSymbol = WaypointSymbol.fromString('S-A-B');
    final timestamp = DateTime(2021);

    final accept = ContractTransaction.accept(
      contract: contract,
      shipSymbol: shipSymbol,
      waypointSymbol: waypointSymbol,
      timestamp: timestamp,
    );
    expect(accept.contractAction, ContractAction.accept);
    expect(accept.creditsChange, 10);
    final deliver = ContractTransaction.delivery(
      contract: contract,
      shipSymbol: shipSymbol,
      waypointSymbol: waypointSymbol,
      timestamp: timestamp,
      unitsDelivered: 10,
    );
    expect(deliver.creditsChange, 0);
    expect(deliver.contractAction, ContractAction.delivery);
    final fulfill = ContractTransaction.fulfillment(
      contract: contract,
      shipSymbol: shipSymbol,
      waypointSymbol: waypointSymbol,
      timestamp: timestamp,
    );
    expect(fulfill.contractAction, ContractAction.fulfillment);
    expect(fulfill.creditsChange, 20);
  });

  test('Contract json round trip', () {
    final now = DateTime(2021);
    final contractTerms = ContractTerms(
      deadline: now,
      payment: ContractPayment(onAccepted: 10, onFulfilled: 20),
    );
    final contract = Contract.test(id: 'id', terms: contractTerms);

    final json = contract.toJson();
    final fromJson = Contract.fromJson(json);
    // Contract does not currently support equality so compare the json.
    expect(fromJson.toJson(), contract.toJson());
  });
}
