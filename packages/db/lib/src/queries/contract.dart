import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Query to get all contracts.
Query allContractsQuery() => const Query('SELECT * FROM contract_');

/// Upsert a contract.
Query upsertContractQuery(Contract contract) {
  return Query(parameters: contractToColumnMap(contract), '''
    INSERT INTO contract_ (id, json, accepted, fulfilled, deadline_to_accept, deadline_to_complete)
    VALUES (@id, @json, @accepted, @fulfilled, @deadline_to_accept, @deadline_to_complete)
    ON CONFLICT (id) DO UPDATE SET json = @json, accepted = @accepted, fulfilled = @fulfilled, deadline_to_accept = @deadline_to_accept, deadline_to_complete = @deadline_to_complete
    ''');
}

/// Fetch a contract by id.
Query contractByIdQuery(String id) {
  return Query(
    'SELECT * FROM contract_ WHERE id = @id',
    parameters: <String, dynamic>{'id': id},
  );
}

/// Get all contracts which are !fulfilled and expiration date is in the future.
/// Both accepted and unaccepted contracts are included.
Query activeContractsQuery(DateTime now) {
  return Query(
    'SELECT * FROM contract_ '
    'WHERE fulfilled = FALSE AND deadline_to_complete > @now',
    parameters: {'now': now},
  );
}

/// Get all contracts which are !accepted.
Query unacceptedContractsQuery(DateTime now) {
  return Query(
    'SELECT * FROM contract_ '
    'WHERE accepted = FALSE AND deadline_to_accept > @now',
    parameters: {'now': now},
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
    // These are ignored during reads from the db, only copied from the
    // json into fields for use in queries.
    // We could also just figure out how to do correct json queries.
    'accepted': contract.accepted,
    'fulfilled': contract.fulfilled,
    'deadline_to_accept': contract.deadlineToAccept,
    'deadline_to_complete': contract.terms.deadline,
  };
}
