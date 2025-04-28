import 'dart:io';

import 'package:cli/logger.dart';
import 'package:dart_frog/dart_frog.dart';

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
  final logger = Logger();
  return runWithLogger(logger, () async {
    // Start the server and listen for incoming requests.
    final server = await serve(handler, ip, port);
    logger.info('Server started on $ip:$port');
    return server;
  });
}
