import 'package:cli/api.dart';
import 'package:cli/printing.dart';

void main(List<String> args) async {
  final maybeStatus = await DefaultApi().getStatus();
  printStatus(maybeStatus!);

  prettyPrintJson(maybeStatus.toJson());
}
