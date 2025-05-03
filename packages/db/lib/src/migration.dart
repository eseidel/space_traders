/// {@template migration}
/// A change to the database schema.
/// {@endtemplate}
abstract interface class Migration {
  /// The schema version after running this migration. Should match the name
  /// of the migration file, and should be the number of the previous migration
  /// plus one.
  int get version;

  /// The SQL to run when applying this migration.
  String get up;

  /// The SQL to run when rolling back this migration.
  String get down;
}

/// {@template irreversible_migration}
/// A change to the database schema that cannot be rolled back, due to deletion
/// of data, removal of non-nullable columns, etc.
/// {@endtemplate}
abstract class IrreversibleMigration implements Migration {
  /// The schema version after running this migration. Should match the name
  /// of the migration file, and should be the number of the previous migration
  /// plus one.
  @override
  int get version;

  /// The SQL to run when applying this migration.
  @override
  String get up;

  /// Throws an [IrreversibleMigrationException] when attempting to roll back.
  @override
  String get down => throw IrreversibleMigrationException(this);
}

/// {@template irreversible_migration_exception}
/// Thrown when attempting to roll back an [IrreversibleMigration].
/// {@endtemplate}
class IrreversibleMigrationException implements Exception {
  /// {@macro irreversible_migration_exception}
  IrreversibleMigrationException(this.migration);

  /// The migration that cannot be rolled back.
  final IrreversibleMigration migration;

  @override
  String toString() =>
      '''Attempted to reverse an irreversible migration: version ${migration.version}''';
}
