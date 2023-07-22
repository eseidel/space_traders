import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  final contents = File('../cli/data/ships.json').readAsStringSync();
  return Response(body: contents);
}
