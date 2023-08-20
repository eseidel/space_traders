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
