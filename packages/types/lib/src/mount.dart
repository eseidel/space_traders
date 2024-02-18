import 'package:meta/meta.dart';
import 'package:more/collection.dart';
import 'package:types/api.dart';
import 'package:types/behavior.dart';
import 'package:types/src/symbol.dart';

/// Symbols of all cargo modules.
final kCargoModules = {
  ShipModuleSymbolEnum.CARGO_HOLD_I,
  ShipModuleSymbolEnum.CARGO_HOLD_II,
  ShipModuleSymbolEnum.CARGO_HOLD_III,
};

/// The symbols of all laser mounts.
final kLaserMountSymbols = {
  ShipMountSymbolEnum.MINING_LASER_I,
  ShipMountSymbolEnum.MINING_LASER_II,
  ShipMountSymbolEnum.MINING_LASER_III,
};

/// The symbols of all gas siphon mounts.
final kSiphonMountSymbols = {
  ShipMountSymbolEnum.GAS_SIPHON_I,
  ShipMountSymbolEnum.GAS_SIPHON_II,
  ShipMountSymbolEnum.GAS_SIPHON_III,
};

/// The symbols of all survey mounts.
final kSurveyMountSymbols = {
  ShipMountSymbolEnum.SURVEYOR_I,
  ShipMountSymbolEnum.SURVEYOR_II,
  ShipMountSymbolEnum.SURVEYOR_III,
};

/// Set of ship mount symbols.
/// Caution: equals and hashCode are not defined for this type.
/// Use [ShipTemplate.mountsSymbolSetEquals] instead.
typedef MountSymbolSet = Multiset<ShipMountSymbolEnum>;

/// Mounts template for a ship.
@immutable
class ShipTemplate {
  /// Create a new ship template.
  const ShipTemplate({
    required this.frameSymbol,
    required this.mounts,
  });

  /// Frame type that this template is for.
  final ShipFrameSymbolEnum frameSymbol;

  /// Mounts that this template has.
  final MountSymbolSet mounts;

  /// Returns true if we know how to purchase all needed mounts.
  bool canPurchaseAllMounts(Set<ShipMountSymbolEnum> availableMounts) {
    for (final mountSymbol in mounts) {
      if (!availableMounts.contains(mountSymbol)) {
        return false;
      }
    }
    return true;
  }

  /// Returns true if the given ship matches this template.
  bool matches(Ship ship) {
    return ship.frame.symbol == frameSymbol &&
        mountsSymbolSetEquals(ship.mountedMountSymbols, mounts);
  }

  /// Returns true if [a] and [b] have the same mounts.
  static bool mountsSymbolSetEquals(MountSymbolSet a, MountSymbolSet b) {
    return a.length == b.length && a.intersection(b).length == a.length;
  }

  @override
  String toString() => 'ShipTemplate($frameSymbol, $mounts)';

  @override
  bool operator ==(Object other) =>
      other is ShipTemplate &&
      frameSymbol == other.frameSymbol &&
      mountsSymbolSetEquals(mounts, other.mounts);

  @override
  int get hashCode => Object.hash(
        frameSymbol,
        mounts.fold<int>(0, (previous, value) => previous ^ value.hashCode),
      );
}

/// Extensions for dealing with mounts on ships.
extension ShipMountsExtension on Ship {
  /// Compute the mounts in the given ship's inventory.
  MountSymbolSet get mountSymbolsInInventory {
    final counts = MountSymbolSet();
    for (final item in cargo.inventory) {
      final mountSymbol = mountSymbolForTradeSymbol(item.tradeSymbol);
      // Will be null if the item isn't a mount.
      if (mountSymbol == null) {
        continue;
      }
      counts.add(mountSymbol, item.units);
    }
    return counts;
  }

  /// Compute the mounts mounted on the given ship.
  MountSymbolSet get mountedMountSymbols {
    return MountSymbolSet.fromIterable(mounts.map((m) => m.symbol));
  }
}

/// Extensions for dealing with mounts on ShipyardShips.
extension ShipyardShipMountsExtension on ShipyardShip {
  /// Compute the mounts mounted on the given ShipyardShip.
  MountSymbolSet get mountedMountSymbols {
    return MountSymbolSet.fromIterable(mounts.map((m) => m.symbol));
  }
}

/// Mounts to add to make [ship] match [template].
MountSymbolSet mountsToAddToShip(Ship ship, ShipTemplate template) {
  return template.mounts.difference(ship.mountedMountSymbols);
}

/// Mounts to remove to make [ship] match [template].
MountSymbolSet mountsToRemoveFromShip(Ship ship, ShipTemplate template) {
  return ship.mountedMountSymbols.difference(template.mounts);
}

/// A queued request to buy and mount a mount on a ship.
class MountRequest {
  /// Create a new mount request.
  MountRequest({
    required this.shipSymbol,
    required this.mountSymbol,
    required this.marketSymbol,
    required this.shipyardSymbol,
    required this.creditsNeeded,
  });

  /// The ship that needs this mount.
  final ShipSymbol shipSymbol;

  /// The mount we need to buy.
  final ShipMountSymbolEnum mountSymbol;

  /// The market we need to buy the mount from.
  final WaypointSymbol marketSymbol;

  /// The shipyard we will use to install the mount.
  final WaypointSymbol shipyardSymbol;

  /// The credits we need to buy the mount and install it.
  final int creditsNeeded;

  /// The buy job for this mount request.
  BuyJob get buyJob => BuyJob(
        tradeSymbol: tradeSymbolForMountSymbol(mountSymbol),
        units: 1,
        buyLocation: marketSymbol,
      );

  /// The mount job for this mount request.
  MountJob get mountJob => MountJob(
        mountSymbol: mountSymbol,
        shipyardSymbol: shipyardSymbol,
      );
}

/// Compute the total strength of all mounts on [ship]
/// with symbols in [mountSymbols].
int strengthOfMounts(Ship ship, Set<ShipMountSymbolEnum> mountSymbols) {
  return ship.mounts.fold(0, (sum, m) {
    final strength = m.strength ?? 0;
    return mountSymbols.contains(m.symbol) ? sum + strength : sum;
  });
}

/// Compute the total strength of all laser mounts on [ship].
int laserMountStrength(Ship ship) => strengthOfMounts(ship, kLaserMountSymbols);

/// Compute the total strength of all siphon mounts on [ship].
int siphonMountStrength(Ship ship) =>
    strengthOfMounts(ship, kSiphonMountSymbols);

/// Compute the total power of all mounts on [ship]
/// with symbols in [mountSymbols].
int powerUsedByMounts(Ship ship, Set<ShipMountSymbolEnum> mountSymbols) {
  return ship.mounts.fold(0, (sum, m) {
    final power = m.requirements.power ?? 0;
    return mountSymbols.contains(m.symbol) ? sum + power : sum;
  });
}

/// Compute the total power of all laser mounts on [ship].
int powerUsedByLasers(Ship ship) => powerUsedByMounts(ship, kLaserMountSymbols);

/// Compute the total power of all siphon mounts on [ship].
int powerUsedBySiphons(Ship ship) =>
    powerUsedByMounts(ship, kSiphonMountSymbols);

/// Compute the total power of all survey mounts on [ship].
int powerUsedBySurveyors(Ship ship) =>
    powerUsedByMounts(ship, kSurveyMountSymbols);
