import 'package:client/client.dart';
import 'package:flutter/material.dart';

class ApiBuilder<T> extends StatefulWidget {
  const ApiBuilder({required this.fetcher, required this.builder, super.key});

  final Future<T> Function(BackendClient client) fetcher;
  final Widget Function(BuildContext context, T response) builder;

  @override
  State<ApiBuilder<T>> createState() => _ApiBuilderState<T>();
}

class _ApiBuilderState<T> extends State<ApiBuilder<T>> {
  late final T data;
  bool loading = true;
  String? error;

  Future<void> load() async {
    final client = BackendClient(hostedUri: Uri.base);
    try {
      final response = await widget.fetcher(client);
      setState(() {
        data = response;
        loading = false;
      });
    } on Exception catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
      return;
    }
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
