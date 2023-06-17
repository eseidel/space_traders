import 'package:mason_logger/mason_logger.dart';
import 'package:space_traders_cli/api.dart';

// This should be replaceable/mockable/configurable?
/// Global logger.
Logger logger = Logger();

/// Set the global logger to verbose logging.
void setVerboseLogging() {
  logger.level = Level.verbose;
}

String _shipLabel(Ship ship) => ship.emojiName.padRight(5);

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
