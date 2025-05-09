import 'package:db/migrations/01_request.dart';
import 'package:db/migrations/02_response.dart';
import 'package:db/migrations/03_transaction.dart';
import 'package:db/migrations/04_survey.dart';
import 'package:db/migrations/05_faction.dart';
import 'package:db/migrations/06_behavior.dart';
import 'package:db/migrations/07_extraction.dart';
import 'package:db/migrations/08_construction.dart';
import 'package:db/migrations/09_charting.dart';
import 'package:db/migrations/10_agent.dart';
import 'package:db/migrations/11_market_listing.dart';
import 'package:db/migrations/12_shipyard_listing.dart';
import 'package:db/migrations/13_shipyard_price.dart';
import 'package:db/migrations/14_market_price.dart';
import 'package:db/migrations/15_jump_gate.dart';
import 'package:db/migrations/16_contract.dart';
import 'package:db/migrations/17_ship.dart';
import 'package:db/migrations/18_config.dart';
import 'package:db/migrations/19_static_data.dart';
import 'package:db/migrations/20_system_record.dart';
import 'package:db/migrations/21_system_waypoint.dart';
import 'package:db/migrations/22_contract_deadline.dart';
import 'package:db/src/migration.dart';

/// All migrations in order.
final allMigrations = validateMigrations(<Migration>[
  CreateRequestMigration(),
  CreateResponseMigration(),
  CreateTransactionMigration(),
  CreateSurveyMigration(),
  CreateFactionMigration(),
  CreateBehaviorMigration(),
  CreateExtractionMigration(),
  CreateConstructionMigration(),
  CreateChartingMigration(),
  CreateAgentMigration(),
  CreateMarketListingMigration(),
  CreateShipyardListingMigration(),
  CreateShipyardPriceMigration(),
  CreateMarketPriceMigration(),
  CreateJumpGateMigration(),
  CreateContractMigration(),
  CreateShipMigration(),
  CreateConfigMigration(),
  CreateStaticDataMigration(),
  CreateSystemRecordMigration(),
  CreateSystemWaypointMigration(),
  ContractDeadlineMigration(),
]);

/// Validates that:
///   - The migration scripts are in the correct order.
///   - All migrations have a unique version.
///   - There are no gaps in the migration versions.
List<Migration> validateMigrations(List<Migration> migrations) {
  final versions = migrations.map((m) => m.version);
  for (final (i, version) in versions.indexed) {
    // Versions start at 1 (0 is the initial empty schema).
    if (version != i + 1) {
      throw StateError('Found migration version $version, was expecting $i.');
    }
  }
  return migrations;
}

/// Returns the migration scripts to run between two schema versions, in the
/// order they should be run.
List<String> migrationScripts({
  required int fromVersion,
  required int toVersion,
}) {
  final isUp = fromVersion < toVersion;
  if (isUp) {
    return allMigrations
        .sublist(fromVersion, toVersion)
        .map((m) => m.up)
        .toList();
  } else {
    return allMigrations
        .sublist(toVersion, fromVersion)
        .reversed
        .map((m) => m.down)
        .toList();
  }
}
