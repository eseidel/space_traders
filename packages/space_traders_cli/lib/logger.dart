import 'package:mason_logger/mason_logger.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/extensions.dart';

// This should be replaceable/mockable/configurable?
/// Global logger.
Logger logger = Logger();

/// Log the [ship] info with [message] to the global logger at the info level.
void shipInfo(Ship ship, String message) {
  logger.info('${ship.emojiName}: $message');
}
