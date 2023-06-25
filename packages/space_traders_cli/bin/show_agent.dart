import 'package:cli/net/auth.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/printing.dart';
import 'package:file/local.dart';

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final response = await getMyAgent(api);
  prettyPrintJson(response.toJson());
}
