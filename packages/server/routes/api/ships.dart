import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:db/db.dart';

extension ReadAsync on RequestContext {
  Future<T> readAsync<T extends Object>() => read<Future<T>>();
}

Future<Response> onRequest(RequestContext context) async {
  final db = await context.readAsync<Database>();
  final ships = await db.allShips();
  return Response(body: jsonEncode(ships.toList()));
}
