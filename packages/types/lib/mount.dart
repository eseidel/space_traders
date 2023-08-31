import 'package:more/collection.dart';
import 'package:types/api.dart';

/// Set of ship mount symbols.
typedef MountSymbolSet = Multiset<ShipMountSymbolEnum>;

/// Mounts template for a ship.
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

/// Mounts to add to make [ship] match [template].
MountSymbolSet mountsToAddToShip(Ship ship, ShipTemplate template) {
  return template.mounts.difference(ship.mountedMountSymbols);
}

/// Mounts to remove to make [ship] match [template].
MountSymbolSet mountsToRemoveFromShip(Ship ship, ShipTemplate template) {
  return ship.mountedMountSymbols.difference(template.mounts);
}
