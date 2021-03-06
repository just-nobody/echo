import 'color.dart';
import 'component_echo.dart';
import 'component_physics.dart';
import 'component_graphics.dart';
import 'game_object.dart';
import 'game_world.dart';

class Level {
  Level(GameWorld world, List<String> levelData) {
    for (int i = 0; i < levelData.length; i++) {
      final row = levelData[i];
      for (int j = 0; j < row.length; j++) {
        final char = row[j];
        if (char == '1') {
          world.add(new MapBlock(j, i));
        }
      }
    }
  }
}

class MapBlock extends GameObject {
  static const size = 80;

  MapBlock(int x, int y) {
    add(new BoundingBox(x * size, y * size, size, size));
    add(new EchoRespondent());
    add(new DrawableRect(Color.asphalt));
  }
}