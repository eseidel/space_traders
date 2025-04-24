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
  T? data;
  bool loading = true;
  String? error;

  Future<void> load() async {
    // Get just the root URI for the client
    final client = BackendClient(hostedUri: Uri.base.removeFragment());
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
    if (error != null) {
      return Center(
        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
      );
    }
    if (data == null) {
      return const Center(child: Text('No data'));
    } else {
      return widget.builder(context, data as T);
    }
  }
}
