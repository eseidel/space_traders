import 'package:client/client.dart';
import 'package:flutter/material.dart';
import 'package:ui/src/api_builder.dart';

const Color darkBlue = Color.fromARGB(255, 18, 32, 47);

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: ApiBuilder<GetMapDataResponse>(
        fetcher: (c) => c.getMapData(),
        builder:
            (context, data) => ColoredBox(
              color: Colors.black,
              child: SizedBox.expand(
                child: CustomPaint(
                  painter: SystemMapPainter(
                    systems: data.systems,
                    ships: data.ships,
                    paintMode: PaintMode.shipColors,
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

enum PaintMode { systemColors, shipColors }

@immutable
class SystemAttributes {
  const SystemAttributes(this.color, this.scale);
  final Color color;
  final double scale;
}

class SystemMapPainter extends CustomPainter {
  const SystemMapPainter({
    required this.systems,
    required this.paintMode,
    required this.ships,
  });

  final PaintMode paintMode;
  final List<System> systems;
  final List<Ship> ships;

  Rect getMapExtents() {
    var minX = double.infinity;
    var maxX = double.negativeInfinity;
    var minY = double.infinity;
    var maxY = double.negativeInfinity;

    for (final system in systems) {
      final x = system.position.x;
      final y = system.position.y;

      if (x < minX) {
        minX = x.toDouble();
      }
      if (x > maxX) {
        maxX = x.toDouble();
      }
      if (y < minY) {
        minY = y.toDouble();
      }
      if (y > maxY) {
        maxY = y.toDouble();
      }
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  SystemAttributes attributesForSystem(System system) {
    if (paintMode == PaintMode.shipColors) {
      final shipsInSystem = ships.where(
        (ship) => ship.systemSymbol == system.symbol,
      );
      if (shipsInSystem.isNotEmpty) {
        return const SystemAttributes(Colors.green, 2);
      }
      return SystemAttributes(Colors.grey.shade700, 1);
    }

    const colorBySystemType = <SystemType, Color>{
      SystemType.NEUTRON_STAR: Colors.purple,
      SystemType.RED_STAR: Colors.red,
      SystemType.ORANGE_STAR: Colors.orange,
      SystemType.BLUE_STAR: Colors.blue,
      SystemType.YOUNG_STAR: Colors.yellow,
      SystemType.WHITE_DWARF: Colors.white,
      SystemType.BLACK_HOLE: Colors.black,
      SystemType.HYPERGIANT: Colors.green,
      SystemType.NEBULA: Colors.grey,
      SystemType.UNSTABLE: Colors.pink,
    };
    final color = colorBySystemType[system.type] ?? Colors.white;
    return SystemAttributes(color, 1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    final paint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.indigo;

    final extents = getMapExtents();
    final scaleX = size.width / extents.width;
    final scaleY = size.height / extents.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final translation = Offset(-extents.left, -extents.top);
    canvas
      ..scale(scale, scale)
      ..translate(translation.dx, translation.dy);

    for (final system in systems) {
      final attributes = attributesForSystem(system);
      final x = system.position.x;
      final y = system.position.y;
      const defaultRadius = 100.0;
      final radius = defaultRadius * attributes.scale;
      paint.color = attributes.color;
      canvas.drawCircle(Offset(x.toDouble(), y.toDouble()), radius, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SystemMapPainter oldDelegate) => false;
}
