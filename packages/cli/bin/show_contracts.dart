import 'package:cli/cache/contract_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';
import 'package:file/file.dart';

Future<void> command(FileSystem fs, List<String> args) async {
  final contractCache = ContractCache.loadCached(fs)!;
  final completed = contractCache.completedContracts;
  if (completed.isNotEmpty) {
    logger.info('${completed.length} completed.');
  }
  final expired = contractCache.expiredContracts;
  if (expired.isNotEmpty) {
    logger.info('${expired.length} expired.');
  }
  final active = contractCache.activeContracts;
  if (active.isNotEmpty) {
    logger.info('${active.length} active:');
    for (final contract in active) {
      logger.info(contractDescription(contract));
    }
  }
  final unaccepted = contractCache.unacceptedContracts;
  if (unaccepted.isNotEmpty) {
    logger.info('${unaccepted.length} unaccepted:');
    for (final contract in unaccepted) {
      logger.info(contractDescription(contract));
    }
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
