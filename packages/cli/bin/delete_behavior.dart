import 'package:cli/cli.dart';

Future<void> command(Database db, ArgResults argResults) async {
  var behaviors = await db.behaviors.all();
  final onlyShips = argResults.rest.map((s) => int.parse(s, radix: 16)).toSet();
  behaviors = behaviors
      .where((b) => onlyShips.contains(b.shipSymbol.number))
      .toList();
  if (behaviors.isEmpty) {
    logger.info('No behaviors found.');
    return;
  }

  logger.confirm('Deleting behaviors: ${behaviors.map((b) => b.shipSymbol)}');

  for (final behavior in behaviors) {
    await db.behaviors.delete(behavior.shipSymbol);
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
