import 'package:db/src/migration.dart';

/// Migration to create the system_waypoint_ table for storing system waypoints.
class ContractDeadlineMigration implements Migration {
  @override
  int get version => 22;

  @override
  String get up => '''
    ALTER TABLE contract_ ADD COLUMN deadline_to_complete timestamp;
  ''';

  @override
  String get down => '''
    ALTER TABLE contract_ DROP COLUMN deadline_to_complete;
  ''';
}
