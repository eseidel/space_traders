import 'package:dart_frog/dart_frog.dart';

// This should never be seen, since packages/ui/nginx.conf only exposes
// endpoints under /api/
Response onRequest(RequestContext context) {
  return Response(body: 'Welcome to Dart Frog!');
}
