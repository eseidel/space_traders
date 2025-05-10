import 'dart:math';

import 'package:collection/collection.dart';
import 'package:types/types.dart';

/// This is mostly used for reference.
final kOreHoundDefault = ShipTemplate(
  frameSymbol: ShipFrameSymbolEnum.MINER,
  mounts: MountSymbolSet.from([
    ShipMountSymbolEnum.MINING_LASER_I,
    ShipMountSymbolEnum.SURVEYOR_I,
  ]),
);

// According to SAF: Surveyor = 2x mk2s,  miner = 2x mk2 + 1x mk1
/// A template for a ship which mines and surveys.
final kMineAndSurveyTemplate = ShipTemplate(
  frameSymbol: ShipFrameSymbolEnum.MINER,
  mounts: MountSymbolSet.from([
    ShipMountSymbolEnum.MINING_LASER_II,
    ShipMountSymbolEnum.MINING_LASER_II,
    ShipMountSymbolEnum.SURVEYOR_I,
  ]),
);

/// A template for a ship which only surveys.
/// Only available after we've found SURVEYOR_II modules to buy.
final kSurveyOnlyTemplate = ShipTemplate(
  frameSymbol: ShipFrameSymbolEnum.MINER,
  mounts: MountSymbolSet.from([
    ShipMountSymbolEnum.SURVEYOR_II,
    ShipMountSymbolEnum.SURVEYOR_II,
    ShipMountSymbolEnum.SURVEYOR_II,
  ]),
);

/// A template for a ship which only mines.
/// Only used after we have dedicated surveyors.
final kMineOnlyTemplate = ShipTemplate(
  frameSymbol: ShipFrameSymbolEnum.MINER,
  mounts: MountSymbolSet.from([
    ShipMountSymbolEnum.MINING_LASER_II,
    ShipMountSymbolEnum.MINING_LASER_II,
    ShipMountSymbolEnum.MINING_LASER_I,
  ]),
);

/// A group of ships which mine and survey together.
class ExtractionSquad {
  /// Creates a new mining squad from a list of ships.
  ExtractionSquad(this.job) : ships = [];

  /// Determines the template to use for [ship].
  ShipTemplate? templateForShip(
    Ship ship, {
    required Set<ShipMountSymbolEnum> availableMounts,
  }) {
    if (!ships.any((s) => s.symbol == ship.symbol)) {
      throw ArgumentError('Ship ${ship.symbol} not in squad.');
    }
    if (ship.frame.symbol != ShipFrameSymbolEnum.MINER) {
      return null;
    }
    // If we're the only ship in this squad, we need to both mine and survey.
    if (ships.length == 1) {
      return kMineAndSurveyTemplate;
    }
    // If we have SURVEYOR_II, our first ship should be a surveyor.
    final surveyor = ships.first;
    if (surveyor.symbol == ship.symbol) {
      if (availableMounts.contains(ShipMountSymbolEnum.SURVEYOR_II)) {
        return kSurveyOnlyTemplate;
      } else {
        return kMineAndSurveyTemplate;
      }
    }
    // If our first ship has already mounted at least one surveyor, we should
    // only mine.
    if (surveyor.mountedMountSymbols.contains(
      ShipMountSymbolEnum.SURVEYOR_II,
    )) {
      return kMineOnlyTemplate;
    }
    // Otherwise we also need to survey.
    return kMineAndSurveyTemplate;
  }

  /// Returns true if this squad contains [ship].
  bool contains(Ship ship) => ships.any((s) => s.symbol == ship.symbol);

  /// Count the number of ships in this squad with [role].
  int countOfRole(FleetRole role) {
    return ships.where((s) => s.fleetRole == role).length;
  }

  /// Haulers in this squad.
  Iterable<Ship> get haulers => ships.where((s) => s.isHauler);

  /// The ships in this squad.
  final List<Ship> ships;

  /// The job this squad is currently working on.
  ExtractionJob job;
}

/// Compute the number of surveys we can expect to complete with [mounts].
/// This is used when you have a template you want to know how many surveys
/// you can expect to complete with, rather than a specific ship.
int surveysExpectedPerSurveyWithMounts(
  ShipMountSnapshot mountSnapshot,
  MountSymbolSet mounts,
) {
  return mounts.fold(0, (sum, mountSymbol) {
    if (!kSurveyMountSymbols.contains(mountSymbol)) {
      return sum;
    }
    return sum + mountSnapshot[mountSymbol]!.strength!;
  });
}

/// Compute the cooldown time for an extraction by [ship].
int cooldownTimeForExtraction(Ship ship) {
  final power = powerUsedByLasers(ship);
  return 60 + 10 * power;
}

/// Compute the cooldown time for a survey by [ship].
int cooldownTimeForSurvey(Ship ship) {
  final power = powerUsedBySurveyors(ship);
  return 60 + 10 * power;
}

/// Variance in units extracted per laser.
const variancePerLaser = 5;

// https://discord.com/channels/792864705139048469/792864705139048472/1132761138849923092
// "Each laser adds its strength +-5. Power is 10 for laser I, 25 for laser II,
// 60 for laser III. So for example laser I plus laser II is 35 +- 10"
/// Compute the maximum number of units we can expect from an extraction.
int maxExtractedUnits(Ship ship) {
  return min(
    ship.cargo.capacity,
    expectedExtractedUnits(ship) +
        ship.mountedMiningLasers.length * variancePerLaser,
  );
}

/// Compute the minimum number of units we can expect from an extraction.
int minExtractedUnits(Ship ship) {
  return max(
    // Unclear if this should be 0 or 1, but right now the server will
    // return 0 for some extractions.
    0,
    expectedExtractedUnits(ship) -
        ship.mountedMiningLasers.length * variancePerLaser,
  );
}

/// Compute the number of units we can expect from an extraction.
int expectedExtractedUnits(Ship ship) {
  return min(
    ship.cargo.capacity,
    ship.mountedMiningLasers.map((m) => m.strength!).sum,
  );
}
