import 'package:cli/cli.dart';
import 'package:cli/net/auth.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/printing.dart';
import 'package:file/file.dart';

Future<void> command(FileSystem fs, List<String> args) async {
  final api = defaultApi(fs);
  final response = await getMyAgent(api);
  prettyPrintJson(response.toJson());
}

void main(List<String> args) async {
  await runOffline(args, command);
}
