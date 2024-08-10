import 'package:flutter/material.dart';

const Color darkBlue = Color.fromARGB(255, 18, 32, 47);

// class MapScreen extends StatelessWidget {
//   const MapScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ColoredBox(
//       color: Colors.black,
//       child: SizedBox.expand(
//         child: CustomPaint(
//           painter: SystemMapPainter(systemsCache, PaintMode.shipColors),
//         ),
//       ),
//     );
//   }
// }

enum PaintMode {
  systemColors,
  shipColors,
}

@immutable
class SystemAttributes {
  const SystemAttributes(this.color, this.scale);
  final Color color;
  final double scale;
}

// class SystemMapPainter extends CustomPainter {
//   const SystemMapPainter(this.systemsCache, this.paintMode);

//   final SystemsCache systemsCache;
//   final PaintMode paintMode;

//   Rect getMapExtents() {
//     var minX = double.infinity;
//     var maxX = double.negativeInfinity;
//     var minY = double.infinity;
//     var maxY = double.negativeInfinity;

//     for (final system in systemsCache.systems) {
//       final x = system.position.x;
//       final y = system.position.y;

//       if (x < minX) {
//         minX = x.toDouble();
//       }
//       if (x > maxX) {
//         maxX = x.toDouble();
//       }
//       if (y < minY) {
//         minY = y.toDouble();
//       }
//       if (y > maxY) {
//         maxY = y.toDouble();
//       }
//     }
//     return Rect.fromLTRB(minX, minY, maxX, maxY);
//   }

//   SystemAttributes attributesForSystem(System system) {
//     if (paintMode == PaintMode.shipColors) {
//       final ships =
//           shipCache.ships.where((ship) => ship.systemSymbol == system.symbol);
//       const colorByType = {
//         ShipRole.EXCAVATOR: Colors.green,
//         ShipRole.COMMAND: Colors.blue,
//         ShipRole.HAULER: Colors.red,
//         ShipRole.SATELLITE: Colors.yellow,
//       };
//       if (ships.isNotEmpty) {
//         final color = colorByType[ships.last.registration.role] ?? Colors.brown;
//         final scale = 1.0 + (ships.length * 1.0);
//         return SystemAttributes(color, scale);
//       }
//       return SystemAttributes(Colors.grey.shade700, 1);
//     }

//     const colorBySystemType = <SystemType, Color>{
//       SystemType.NEUTRON_STAR: Colors.purple,
//       SystemType.RED_STAR: Colors.red,
//       SystemType.ORANGE_STAR: Colors.orange,
//       SystemType.BLUE_STAR: Colors.blue,
//       SystemType.YOUNG_STAR: Colors.yellow,
//       SystemType.WHITE_DWARF: Colors.white,
//       SystemType.BLACK_HOLE: Colors.black,
//       SystemType.HYPERGIANT: Colors.green,
//       SystemType.NEBULA: Colors.grey,
//       SystemType.UNSTABLE: Colors.pink,
//     };
//     final color = colorBySystemType[system.type] ?? Colors.white;
//     return SystemAttributes(color, 1);
//   }

//   @override
//   void paint(Canvas canvas, Size size) {
//     canvas.save();

//     final paint = Paint()
//       ..style = PaintingStyle.fill
//       ..color = Colors.indigo;

//     final extents = getMapExtents();
//     final scaleX = size.width / extents.width;
//     final scaleY = size.height / extents.height;
//     final scale = scaleX < scaleY ? scaleX : scaleY;
//     final translation = Offset(-extents.left, -extents.top);
//     canvas
//       ..scale(scale, scale)
//       ..translate(translation.dx, translation.dy);

//     for (final system in systemsCache.systems) {
//       final attributes = attributesForSystem(system);
//       final x = system.position.x;
//       final y = system.position.y;
//       const defaultRadius = 100.0;
//       final radius = defaultRadius * attributes.scale;
//       paint.color = attributes.color;
//       canvas.drawCircle(Offset(x.toDouble(), y.toDouble()), radius, paint);
//     }
//     canvas.restore();
//   }

//   @override
//   bool shouldRepaint(SystemMapPainter oldDelegate) => false;
// }
