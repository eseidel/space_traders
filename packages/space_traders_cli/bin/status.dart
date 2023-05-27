import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/printing.dart';

void main(List<String> args) async {
  final status = await DefaultApi().getStatus();
  prettyPrintJson(status!.toJson());
}
