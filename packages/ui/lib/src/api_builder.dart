import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

extension JsonDecode on http.Response {
  Map<String, dynamic> get json => jsonDecode(body) as Map<String, dynamic>;
}

class ApiBuilder<T> extends StatefulWidget {
  const ApiBuilder({
    required this.uri,
    required this.builder,
    required this.decoder,
    super.key,
  });

  final Uri uri;
  final T Function(Map<String, dynamic> json) decoder;
  final Widget Function(BuildContext context, T response) builder;

  @override
  State<ApiBuilder<T>> createState() => _ApiBuilderState<T>();
}

class _ApiBuilderState<T> extends State<ApiBuilder<T>> {
  late final T data;
  bool loading = true;

  Future<void> load() async {
    final uri = widget.uri;
    final json = (await http.get(uri)).json;
    final response = widget.decoder(json);
    setState(() {
      data = response;
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return widget.builder(context, data);
  }
}
