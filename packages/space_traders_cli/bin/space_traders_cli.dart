import 'package:args/args.dart';
import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/logic.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/surveys.dart';
import 'package:space_traders_cli/systems_cache.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Verbose logging.')
    ..addFlag(
      'update-prices',
      help: 'Force update of prices from server.',
    );
  final results = parser.parse(args);

  logger =
      Logger(level: results['verbose'] as bool ? Level.verbose : Level.info);

  logger.info('Welcome to Space Traders! 🚀');
  // Use package:file to make things mockable.
  const fs = LocalFileSystem();

  final token = await loadAuthTokenOrRegister(fs);
  final api = apiFromAuthToken(token);
  final db = DataStore();
  await db.open();

  final priceData = await PriceData.load(
    fs,
    updateFromServer: results['update-prices'] as bool,
  );
  final surveyData = await SurveyData.load(fs);
  logger.info(
    'Loaded ${priceData.count} prices from '
    '${priceData.waypointCount} waypoints.',
  );

  final systemsCache = await SystemsCache.load(fs);

  final status = await api.defaultApi.getStatus();
  printStatus(status!);

  await logic(api, db, systemsCache, priceData, surveyData);
}
