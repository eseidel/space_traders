import 'package:mason_logger/mason_logger.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/extensions.dart';

// This should be replaceable/mockable/configurable?
/// Global logger.
Logger logger = Logger();

/// Log [message] for [ship] to the global logger at the detail level.
void shipDetail(Ship ship, String message) {
  logger.detail('${ship.emojiName} $message');
}

/// Log [message] for [ship] to the global logger at the info level.
void shipInfo(Ship ship, String message) {
  logger.info('${ship.emojiName} $message');
}

/// Log [message] for [ship] to the global logger at the warning level.
void shipWarn(Ship ship, String message) {
  logger.warn('${ship.emojiName} $message');
}

/// Log [message] for [ship] to the global logger at the error level.
void shipErr(Ship ship, String message) {
  logger.err('${ship.emojiName} $message');
}
