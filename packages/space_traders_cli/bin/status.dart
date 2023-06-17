import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/printing.dart';

void main(List<String> args) async {
  final maybeStatus = await DefaultApi().getStatus();
  printStatus(maybeStatus!);

  prettyPrintJson(maybeStatus.toJson());
}
