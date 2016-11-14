import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'color.dart';
import 'game_world.dart';
import 'graphics.dart';
import 'keyboard.dart';
import 'util.dart';

abstract class GameObject {
  final components = <Type, Component>{};

  void add(Component c) { components[c.runtimeType] = c; }
  bool has(Type ctype) => components.containsKey(ctype);
  dynamic fetch(Type ctype) => components[ctype];

  void update(num dt, GameWorld world) {
    for (final c in components.values) c.update(this, dt, world);
  }

  void draw() {
    for (final c in components.values) c.draw(this);
  }

  dynamic operator [](Type ctype) => fetch(ctype);
}

abstract class Component {
  void update(GameObject self, num dt, GameWorld world) {}
  void draw(GameObject self) {}
}

class BoundingBox extends Component {
  num x, y, width, height;

  BoundingBox(this.x, this.y, this.width, this.height);

  Rectangle get rect => new Rectangle(x, y, width, height);

  Point get center => new Point(x + width / 2, y + height / 2);

  void setPosition(num _x, num _y) {
    x = _x;
    y = _y;
  }

  void setSize(num _width, num _height) {
    width = _width;
    height = _height;
  }

  void setCenterPosition(num cx, num cy) {
    x = cx - width / 2;
    y = cy - height / 2;
  }
}

class Velocity extends Component {
  num vx = 0;
  num vy = 0;
  num gravity = 2500;

  void update(self, dt, world) {
    final box = self[BoundingBox];
    vy += gravity * dt;
    box.x += vx * dt;
    box.y += vy * dt;
  }
}

class PlayerInput extends Component {
  static const jumpSpeed = 800;

  final kb = new Keyboard();

  num walking = 0;
  num walkSpeed = 500;
  int jumps = 0;

  void update(self, dt, world) {
    final vel = self[Velocity];
    final physics = self[Physics];

    num target = 0;
    if (kb.isDown(KeyCode.LEFT)) target -= 1;
    if (kb.isDown(KeyCode.RIGHT)) target += 1;
    walking = target;

    if (kb.wasPressed(KeyCode.UP) && jumps > 0) {
      vel.vy = -jumpSpeed;
      jumps--;
    }
    vel.vx = lerp(vel.vx, walking * walkSpeed, dt * 16);

    if (physics.hitGround) {
      jumps = 2;
    }
  }
}

class Physics extends Component {
  static Point getCenter(Rectangle rect) {
    return (rect.topLeft + rect.bottomRight) * 0.5;
  }

  static List<Rectangle> sortByDistance(List<Rectangle> rects, Point point) {
    return new List<Rectangle>.from(rects)
      ..sort((a, b) {
        final dist1 = point.distanceTo(getCenter(a));
        final dist2 = point.distanceTo(getCenter(b));
        return dist1.compareTo(dist2);
      });
  }

  static Rectangle move(Rectangle rect, num dx, num dy) {
    final left = rect.left + dx;
    final top = rect.top + dy;
    return new Rectangle(left, top, rect.width, rect.height);
  }

  static Point getDisplacement(Rectangle self, List<Rectangle> others) {
    num dx = 0, dy = 0;

    for (final other in others) {
      final selfCenter = getCenter(self);
      final sect = other.intersection(self);
      if (sect != null) {
        if (sect.width < sect.height && sect.width != 0) {
          if (selfCenter.x < getCenter(other).x) {
            dx -= sect.width;
          } else {
            dx += sect.width;
          }
        }
        if (sect.height < sect.width && sect.height != 0) {
          if (selfCenter.y < getCenter(other).y) {
            dy -= sect.height;
          } else {
            dy += sect.height;
          }
        }
      }
      self = move(self, dx, dy);
    }

    return new Point(dx, dy);
  }

  bool onGround = false;
  bool hitGround = false;

  void update(self, dt, GameWorld world) {
    final box = self[BoundingBox] as BoundingBox;
    final vel = self[Velocity];

    final worldRects = world.objects
      .where((obj) => obj != self && obj.has(BoundingBox))
      .map((obj) => (obj[BoundingBox] as BoundingBox).rect);

    final selfRect = box.rect;
    final selfCenter = box.center;

    final closestToFurthest = sortByDistance(worldRects, selfCenter);
    final disp = getDisplacement(selfRect, closestToFurthest);

    box.x += disp.x;
    box.y += disp.y;

    if (disp.x != 0 && vel.vx.sign != disp.x.sign) vel.vx = 0;
    if (disp.y != 0 && vel.vy.sign != disp.y.sign) vel.vy = 0;

    final _onGround = disp.y < 0;
    hitGround = _onGround && !onGround;
    onGround = _onGround;
  }
}

class EchoSource extends Component {
  void update(self, dt, GameWorld world) {
    final box = self[BoundingBox] as BoundingBox;
    final physics = self[Physics] as Physics;
    if (physics.hitGround) {
      trigger(box.center, world);
    }
  }

  void trigger(Point center, GameWorld world) {
    for (final other in world.objects) {
      if (other.has(BoundingBox) && other.has(EchoRespondent)) {
        final otherCenter = (other[BoundingBox] as BoundingBox).center;
        final delay = center.distanceTo(otherCenter);
        final respondent = other[EchoRespondent] as EchoRespondent;

        new Future.delayed(new Duration(milliseconds: delay.round()), () {
          respondent.show();
        });
      }
    }
  }
}

class EchoRespondent extends Component {
  num visibility = 0;

  void update(self, dt, world) {
    visibility = lerp(visibility, 0, 7 * dt);
    final rect = self[DrawableRect] as DrawableRect;
    rect.opacity = visibility;
  }

  void show() {
    visibility = 1;
  }
}

class DrawableRect extends Component {
  Color color;
  num opacity = 1;

  DrawableRect(this.color);

  void draw(self) {
    final box = self[BoundingBox];
    drawRectangle(box.x, box.y, box.width, box.height, color.withOpacity(opacity));
  }
}