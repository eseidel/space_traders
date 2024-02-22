import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Query to get all contracts.
Query allContractsQuery() => const Query('SELECT * FROM contract_');

/// Upsert a contract.
Query upsertContractQuery(Contract contract) {
  return Query(
    '''
    INSERT INTO contract_ (id, json)
    VALUES (@id, @json)
    ON CONFLICT (id) DO UPDATE SET
      json = @json
    ''',
    parameters: contractToColumnMap(contract),
  );
}

/// Fetch a contract by id.
Query contractByIdQuery(String id) {
  return Query(
    'SELECT * FROM contract_ WHERE id = @id',
    parameters: <String, dynamic>{'id': id},
  );
}

/// Get all contracts which are !fulfilled and expiration date is in the future.
Query activeContractsQuery() {
  return Query(
    "SELECT * FROM contract_ WHERE json->>'fulfilled' = 'false' AND json->>'expiration' > @now",
    parameters: {'now': DateTime.timestamp()},
  );
}

/// Get all contracts which are !accepted.
Query unacceptedContractsQuery() {
  return const Query(
    "SELECT * FROM contract_ WHERE json->>'accepted' = 'false'",
  );
}

/// Converts a contract from a column map.
Contract contractFromColumnMap(Map<String, dynamic> map) {
  return Contract.fromJson(map['json'] as Map<String, dynamic>);
}

/// Converts a contract to a column map.
Map<String, dynamic> contractToColumnMap(Contract contract) {
  return <String, dynamic>{
    'id': contract.id,
    'json': contract.toJson(),
  };
}
