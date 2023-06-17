import 'package:file/local.dart';
import 'package:space_traders_cli/net/auth.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);

  final response = await api.contracts.getContracts();
  final contracts = response!.data;
  for (final contract in contracts) {
    logger.info(contractDescription(contract));
    prettyPrintJson(contract.toJson());
  }
}
