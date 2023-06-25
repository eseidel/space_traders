import 'package:cli/api.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:flutter/material.dart';
import 'package:ui/main.dart';

const Color darkBlue = Color.fromARGB(255, 18, 32, 47);

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: SizedBox.expand(
        child: CustomPaint(painter: SystemMapPainter(systemsCache)),
      ),
    );
  }
}

class SystemMapPainter extends CustomPainter {
  const SystemMapPainter(this.systemsCache);

  final SystemsCache systemsCache;

  Rect getMapExtents() {
    var minX = double.infinity;
    var maxX = double.negativeInfinity;
    var minY = double.infinity;
    var maxY = double.negativeInfinity;

    for (final system in systemsCache.systems) {
      final x = system.x;
      final y = system.y;

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

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final colorBySystemType = <SystemType, Color>{
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

    final paint = Paint()
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

    for (final system in systemsCache.systems) {
      final x = system.x;
      final y = system.y;
      const radius = 100.0;
      paint.color = colorBySystemType[system.type] ?? Colors.white;
      canvas.drawCircle(Offset(x.toDouble(), y.toDouble()), radius, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SystemMapPainter oldDelegate) => false;
}
