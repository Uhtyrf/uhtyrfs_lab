import 'dart:math';

import 'package:flutter/material.dart';

import 'dice_geometry.dart';

class AnimatedDice extends StatefulWidget {
  final int sides;
  final ValueChanged<int> onRolled;

  const AnimatedDice({super.key, required this.sides, required this.onRolled});

  @override
  State<AnimatedDice> createState() => _AnimatedDiceState();
}

class _AnimatedDiceState extends State<AnimatedDice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final DiceGeometry _geometry;

  final Random _random = Random();

  bool _isRolling = false;
  int? _result;

  _Quaternion _targetRotation = _Quaternion.identity();

  @override
  void initState() {
    super.initState();

    _geometry = buildDiceGeometry(widget.sides);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final result = _result;

        setState(() {
          _isRolling = false;
        });

        if (result != null) {
          widget.onRolled(result);
        }
      }
    });
  }

  void _roll() {
    if (_isRolling) return;

    final result = _random.nextInt(widget.sides) + 1;

    final face = _geometry.faces.firstWhere((face) => face.value == result);

    final normal = _faceNormal(face);

    final randomSpin = _random.nextDouble() * 2 * pi;

    _targetRotation =
        _Quaternion.rotationZ(randomSpin) *
        _Quaternion.fromTo(normal, const Vec3(0, 0, 1));

    setState(() {
      _result = result;
      _isRolling = true;
    });

    _controller.forward(from: 0);
  }

  Vec3 _faceNormal(DiceFace face) {
    final a = _geometry.vertices[face.vertices[0]];
    final b = _geometry.vertices[face.vertices[1]];
    final c = _geometry.vertices[face.vertices[2]];

    var normal = (b - a).cross(c - a).normalized();

    var center = const Vec3(0, 0, 0);

    for (final index in face.vertices) {
      center = center + _geometry.vertices[index];
    }

    center = center * (1 / face.vertices.length);

    if (normal.dot(center) < 0) {
      normal = normal * -1;
    }

    return normal;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _roll,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = Curves.easeOutCubic.transform(_controller.value);

          final rotation = _isRolling
              ? _Quaternion.rotationZ(2 * pi * 3 * _controller.value) *
                    _Quaternion.slerp(
                      _Quaternion.identity(),
                      _targetRotation,
                      progress,
                    )
              : _Quaternion.identity();

          return CustomPaint(
            size: const Size(280, 280),
            painter: _DicePainter(geometry: _geometry, rotation: rotation),
          );
        },
      ),
    );
  }
}

class _DicePainter extends CustomPainter {
  final DiceGeometry geometry;
  final _Quaternion rotation;

  _DicePainter({required this.geometry, required this.rotation});

  static const Color metal = Color(0xFFD8C9F5);

  Vec3 _rotate(Vec3 point) {
    return rotation.rotate(point);
  }

  Offset _project(Vec3 point, Size size) {
    const focalLength = 4.5;

    final scale = size.shortestSide * 0.34;

    final perspective = focalLength / (focalLength - point.z);

    return Offset(
      size.width / 2 + point.x * scale * perspective,
      size.height / 2 - point.y * scale * perspective,
    );
  }

  Vec3 _normal(DiceFace face, List<Vec3> vertices) {
    final a = vertices[face.vertices[0]];
    final b = vertices[face.vertices[1]];
    final c = vertices[face.vertices[2]];

    var normal = (b - a).cross(c - a).normalized();

    var center = const Vec3(0, 0, 0);

    for (final index in face.vertices) {
      center = center + vertices[index];
    }

    center = center * (1 / face.vertices.length);

    if (normal.dot(center) < 0) {
      normal = normal * -1;
    }

    return normal;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final vertices = geometry.vertices.map(_rotate).toList();

    final projected = vertices.map((point) => _project(point, size)).toList();

    final faces = geometry.faces.map((face) {
      var center = const Vec3(0, 0, 0);

      for (final index in face.vertices) {
        center = center + vertices[index];
      }

      center = center * (1 / face.vertices.length);

      return (face: face, center: center, normal: _normal(face, vertices));
    }).toList();

    // Сначала рисуем дальние грани.
    faces.sort((a, b) => a.center.z.compareTo(b.center.z));

    // Тень под многогранником.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.84),
        width: size.width * 0.55,
        height: size.height * 0.12,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    for (final item in faces) {
      final face = item.face;
      final normal = item.normal;

      final path = Path();

      for (int i = 0; i < face.vertices.length; i++) {
        final point = projected[face.vertices[i]];

        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      path.close();

      final light = (0.35 + normal.z.abs() * 0.45).clamp(0.0, 1.0);

      final topColor = Color.lerp(
        const Color(0xFFBDA5F7),
        const Color(0xFFE5D9FF),
        light,
      )!;

      final bottomColor = Color.lerp(
        const Color(0xFF32165E),
        const Color(0xFF7545BB),
        light,
      )!;

      final bounds = path.getBounds();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [topColor, const Color(0xFF7546BD), bottomColor],
        ).createShader(bounds);

      canvas.drawPath(path, fillPaint);

      // Металлический контур.
      canvas.drawPath(
        path,
        Paint()
          ..color = metal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeJoin = StrokeJoin.round,
      );

      // Цифры рисуем только на гранях,
      // обращённых к наблюдателю.
      if (normal.z > 0.12) {
        final center = _project(item.center, size);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${face.value}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 4,
                  offset: Offset(1, 2),
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        textPainter.paint(
          canvas,
          Offset(
            center.dx - textPainter.width / 2,
            center.dy - textPainter.height / 2,
          ),
        );
      }
    }

    // Дополнительный металлический блеск.
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.27),
      3,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  @override
  bool shouldRepaint(covariant _DicePainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}

class _Quaternion {
  final double w;
  final double x;
  final double y;
  final double z;

  const _Quaternion(this.w, this.x, this.y, this.z);

  factory _Quaternion.identity() {
    return const _Quaternion(1, 0, 0, 0);
  }

  factory _Quaternion.rotationZ(double angle) {
    return _Quaternion(cos(angle / 2), 0, 0, sin(angle / 2));
  }

  factory _Quaternion.fromTo(Vec3 from, Vec3 to) {
    final a = from.normalized();
    final b = to.normalized();

    final dot = a.dot(b);

    if (dot < -0.999999) {
      final axis = a
          .cross(a.x.abs() < 0.9 ? const Vec3(1, 0, 0) : const Vec3(0, 1, 0))
          .normalized();

      return _Quaternion(0, axis.x, axis.y, axis.z);
    }

    final cross = a.cross(b);

    return _Quaternion(1 + dot, cross.x, cross.y, cross.z).normalized();
  }

  _Quaternion operator *(_Quaternion b) {
    return _Quaternion(
      w * b.w - x * b.x - y * b.y - z * b.z,
      w * b.x + x * b.w + y * b.z - z * b.y,
      w * b.y - x * b.z + y * b.w + z * b.x,
      w * b.z + x * b.y - y * b.x + z * b.w,
    );
  }

  _Quaternion normalized() {
    final length = sqrt(w * w + x * x + y * y + z * z);

    return _Quaternion(w / length, x / length, y / length, z / length);
  }

  Vec3 rotate(Vec3 point) {
    final p = _Quaternion(0, point.x, point.y, point.z);

    final conjugate = _Quaternion(w, -x, -y, -z);

    final result = this * p * conjugate;

    return Vec3(result.x, result.y, result.z);
  }

  static _Quaternion slerp(_Quaternion a, _Quaternion b, double t) {
    var dot = a.w * b.w + a.x * b.x + a.y * b.y + a.z * b.z;

    var target = b;

    if (dot < 0) {
      dot = -dot;
      target = _Quaternion(-b.w, -b.x, -b.y, -b.z);
    }

    if (dot > 0.9995) {
      return _Quaternion(
        a.w + (target.w - a.w) * t,
        a.x + (target.x - a.x) * t,
        a.y + (target.y - a.y) * t,
        a.z + (target.z - a.z) * t,
      ).normalized();
    }

    final theta = acos(dot.clamp(-1.0, 1.0));
    final sinTheta = sin(theta);

    final wa = sin((1 - t) * theta) / sinTheta;
    final wb = sin(t * theta) / sinTheta;

    return _Quaternion(
      a.w * wa + target.w * wb,
      a.x * wa + target.x * wb,
      a.y * wa + target.y * wb,
      a.z * wa + target.z * wb,
    ).normalized();
  }
}
