import 'package:file/local.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/logic.dart';
import 'package:space_traders_cli/prices.dart';

void main(List<String> arguments) async {
  logger.info('Welcome to Space Traders! 🚀');
  // Use package:file to make things mockable.
  const fs = LocalFileSystem();

  final token = await loadAuthTokenOrRegister(fs);
  final api = apiFromAuthToken(token);
  final db = DataStore();
  await db.open();

  final priceData = await PriceData.load(fs);
  await logic(api, db, priceData);
}
