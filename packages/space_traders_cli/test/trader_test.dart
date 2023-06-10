import 'package:mocktail/mocktail.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/prices.dart';

class MockPriceData extends Mock implements PriceData {}

class MockApi extends Mock implements Api {}

class MockShip extends Mock implements Ship {}

class MockWaypoint extends Mock implements Waypoint {}

void main() {}
