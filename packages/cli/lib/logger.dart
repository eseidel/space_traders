import 'package:collection/collection.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:scoped_deps/scoped_deps.dart';
import 'package:types/types.dart';

export 'package:mason_logger/mason_logger.dart';

/// A reference to the global logger using package:scoped to create.
final loggerRef = create(Logger.new);

/// A getter for the global logger using package:scoped to read.
/// This is a getter so that it cannot be replaced directly, if you wish
/// to mock the logger use runScoped with override values.
Logger get logger => read(loggerRef);

/// Run [fn] with the global logger replaced with [logger].
R runWithLogger<R>(Logger logger, R Function() fn) {
  return runScoped(fn, values: {loggerRef.overrideWith(() => logger)});
}

/// Set the global logger to verbose logging.
void setVerboseLogging() {
  logger.level = Level.verbose;
}

String _shipLabel(Ship ship) {
  final name = ship.emojiName.padRight(5);
  final maxLength = FleetRole.values.map((e) => e.name.length).max;
  final role = ship.fleetRole.name.padRight(maxLength + 1);
  return '$name $role';
}

/// Log [message] for [ship] to the global logger at the detail level.
void shipDetail(Ship ship, String message) {
  logger.detail('${_shipLabel(ship)} $message');
}

/// Log [message] for [ship] to the global logger at the info level.
void shipInfo(Ship ship, String message) {
  logger.info('${_shipLabel(ship)} $message');
}

/// Log [message] for [ship] to the global logger at the warning level.
void shipWarn(Ship ship, String message) {
  logger.warn('${_shipLabel(ship)} $message');
}

/// Log [message] for [ship] to the global logger at the error level.
void shipErr(Ship ship, String message) {
  logger.err('${_shipLabel(ship)} $message');
}
