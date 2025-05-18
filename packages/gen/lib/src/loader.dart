import 'dart:convert';

import 'package:file/file.dart';
import 'package:http/http.dart' as http;
import 'package:space_gen/src/spec.dart';
import 'package:space_gen/src/visitor.dart';

typedef Json = Map<String, dynamic>;

/// Resolves a JSON pointer into a JSON object.
///
/// The pointer is a string of the form `/path/to/object`.
/// The object is the root object of the JSON document.
/// The pointer is the path to the object in the JSON document.
Json resolvePointerToObject(Json json, String pointer) {
  // If the pointer is empty, split will return a list with an empty string.
  final parts = pointer.split('/');
  if (pointer.isEmpty || parts.isEmpty) {
    return json;
  }
  var i = 0;
  dynamic current = json;
  while (i < parts.length) {
    final part = parts[i];
    // Expect the first part to be empty and skip it.
    if (i == 0) {
      if (part != '') {
        throw Exception('Pointer must start with a slash: $pointer');
      }
      i++;
      continue;
    }
    // Handle the part based on the type of the current object.
    if (current is Json) {
      current = current[part];
    } else if (current is List) {
      current = current[int.parse(part)];
    } else {
      throw Exception('Invalid pointer: $pointer');
    }
    i++;
  }
  if (current is! Json) {
    throw Exception('Invalid pointer: $pointer');
  }
  return current;
}

class Cache {
  Cache(this.fs, {http.Client? client}) : client = client ?? http.Client();

  final FileSystem fs;
  final http.Client client;

  final _cache = <Uri, Json>{};

  // Does not check the cache, does handle both file and network urls.
  Future<Json> _fetchBypassCache(Uri uri) async {
    if (uri.fragment.isNotEmpty) {
      throw Exception('Fragment not supported: $uri');
    }

    if (!uri.hasScheme || uri.scheme == 'file') {
      final content = fs.file(uri.toFilePath()).readAsStringSync();
      return jsonDecode(content) as Json;
    }

    final response = await client.get(uri);
    return jsonDecode(response.body) as Json;
  }

  Future<Json> _loadJson(Uri uri) async {
    final base = uri.removeFragment();
    final pointer = uri.fragment;

    // Check the cache first.
    if (_cache.containsKey(base)) {
      return resolvePointerToObject(_cache[base]!, pointer);
    }

    final json = await _fetchBypassCache(base);
    _cache[base] = json;
    return resolvePointerToObject(json, pointer);
  }

  Json? get(Uri uri) {
    final base = uri.removeFragment();
    final pointer = uri.fragment;
    final json = _cache[base];
    if (json == null) {
      return null;
    }
    return resolvePointerToObject(json, pointer);
  }

  Future<Spec> loadSpec(Uri specUrl) async =>
      Spec.fromJson(await _loadJson(specUrl));

  Future<void> precacheRefs(Uri specUri, Spec spec) async {
    final refs = collectRefs(spec);
    for (final ref in refs) {
      // If any of the refs are network urls, we need to fetch them.
      final resolved = specUri.resolve(ref);
      await _loadJson(resolved);
    }
  }
}
