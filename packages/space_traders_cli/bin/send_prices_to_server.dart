import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:file/local.dart';
import 'package:http/http.dart' as http;
import 'package:space_traders_cli/cache/prices.dart';
import 'package:space_traders_cli/logger.dart';

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final priceData = await PriceData.load(fs);

  logger.info('${priceData.count} prices loaded.');

  const pricesPerRequest = 1000;
  final pricesEndpoint = Uri.parse(PriceData.defaultUrl);
  var sliceNumber = 0;
  for (final slice in priceData.prices.slices(pricesPerRequest)) {
    final jsonEncoded = jsonEncode(slice);
    final headers = <String, String>{
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
    final sliceStart = sliceNumber * pricesPerRequest;
    final sliceEnd = sliceStart + slice.length;
    logger.info('Sending prices $sliceStart-$sliceEnd');
    final response =
        await http.put(pricesEndpoint, headers: headers, body: jsonEncoded);
    logger.info('Response: ${response.statusCode} ${response.body}');
    sliceNumber++;
  }
}
