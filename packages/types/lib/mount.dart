import 'package:meta/meta.dart';
import 'package:more/collection.dart';
import 'package:types/api.dart';

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

/// Mounts to add to make [ship] match [template].
MountSymbolSet mountsToAddToShip(Ship ship, ShipTemplate template) {
  return template.mounts.difference(ship.mountedMountSymbols);
}

/// Mounts to remove to make [ship] match [template].
MountSymbolSet mountsToRemoveFromShip(Ship ship, ShipTemplate template) {
  return ship.mountedMountSymbols.difference(template.mounts);
}
