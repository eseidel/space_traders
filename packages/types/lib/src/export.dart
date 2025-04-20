import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// TradeExport records imports needed for an export.
@immutable
class TradeExport {
  /// Create a TradeExport relationship.
  const TradeExport({required this.export, required this.imports});

  /// Create from JSON.
  factory TradeExport.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    final export = TradeSymbol.fromJson(map['export'] as String)!;
    final importsJson = map['imports'] as List<dynamic>;
    final imports = importsJson.map((i) => TradeSymbol.fromJson(i as String)!);
    return TradeExport(export: export, imports: imports.toList());
  }

  /// The export produced
  final TradeSymbol export;

  /// The imports needed to produce the export.
  // Not sure if imports should be treated as a set or list.
  final List<TradeSymbol> imports;

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'export': export.toJson(),
      'imports': imports.map((i) => i.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradeExport &&
          runtimeType == other.runtimeType &&
          export == other.export &&
          const ListEquality<TradeSymbol>().equals(imports, other.imports);

  @override
  int get hashCode => Object.hashAll([export, ...imports]);
}
