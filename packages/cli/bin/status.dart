import 'package:cli/api.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:file/file.dart';

Future<void> command(FileSystem fs, List<String> args) async {
  final maybeStatus = await DefaultApi().getStatus();
  printStatus(maybeStatus!);

  prettyPrintJson(maybeStatus.toJson());
}

void main(List<String> args) async {
  await runOffline(args, command);
}
