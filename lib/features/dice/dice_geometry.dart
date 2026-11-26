import 'dart:math';

/// Трёхмерная точка.
class Vec3 {
  final double x;
  final double y;
  final double z;

  const Vec3(this.x, this.y, this.z);

  Vec3 operator +(Vec3 b) => Vec3(x + b.x, y + b.y, z + b.z);

  Vec3 operator -(Vec3 b) => Vec3(x - b.x, y - b.y, z - b.z);

  Vec3 operator *(double k) => Vec3(x * k, y * k, z * k);

  double dot(Vec3 b) => x * b.x + y * b.y + z * b.z;

  Vec3 cross(Vec3 b) =>
      Vec3(y * b.z - z * b.y, z * b.x - x * b.z, x * b.y - y * b.x);

  double get length => sqrt(dot(this));

  Vec3 normalized() {
    final l = length;
    if (l < 0.000001) return this;
    return this * (1 / l);
  }
}

/// Одна грань многогранника.
class DiceFace {
  final List<int> vertices;
  final int value;

  const DiceFace({required this.vertices, required this.value});
}

/// Геометрия кубика.
class DiceGeometry {
  final List<Vec3> vertices;
  final List<DiceFace> faces;

  const DiceGeometry({required this.vertices, required this.faces});
}

/// Создание геометрии по количеству граней.
DiceGeometry buildDiceGeometry(int sides) {
  switch (sides) {
    case 4:
      return _tetrahedron();
    case 6:
      return _cube();
    case 8:
      return _octahedron();
    case 10:
      return _pentagonalTrapezohedron();
    case 12:
      return _dodecahedron();
    case 20:
      return _icosahedron();
    default:
      throw ArgumentError('Неизвестный тип кубика: D$sides');
  }
}

/// D4 — тетраэдр.
DiceGeometry _tetrahedron() {
  final vertices = [
    Vec3(1, 1, 1),
    Vec3(-1, -1, 1),
    Vec3(-1, 1, -1),
    Vec3(1, -1, -1),
  ];

  return _fromConvexHull(vertices);
}

/// D6 — куб.
DiceGeometry _cube() {
  final vertices = <Vec3>[];

  for (final x in [-1.0, 1.0]) {
    for (final y in [-1.0, 1.0]) {
      for (final z in [-1.0, 1.0]) {
        vertices.add(Vec3(x, y, z));
      }
    }
  }

  return _fromConvexHull(vertices);
}

/// D8 — октаэдр.
DiceGeometry _octahedron() {
  return _fromConvexHull([
    Vec3(1, 0, 0),
    Vec3(-1, 0, 0),
    Vec3(0, 1, 0),
    Vec3(0, -1, 0),
    Vec3(0, 0, 1),
    Vec3(0, 0, -1),
  ]);
}

/// D20 — икосаэдр.
DiceGeometry _icosahedron() {
  final phi = (1 + sqrt(5)) / 2;

  final vertices = <Vec3>[];

  for (final a in [-1.0, 1.0]) {
    for (final b in [-phi, phi]) {
      vertices.add(Vec3(0, a, b));
      vertices.add(Vec3(a, b, 0));
      vertices.add(Vec3(b, 0, a));
    }
  }

  return _fromConvexHull(vertices);
}

/// D12 — додекаэдр.
DiceGeometry _dodecahedron() {
  final phi = (1 + sqrt(5)) / 2;
  final invPhi = 1 / phi;

  final vertices = <Vec3>[];

  for (final x in [-1.0, 1.0]) {
    for (final y in [-1.0, 1.0]) {
      for (final z in [-1.0, 1.0]) {
        vertices.add(Vec3(x, y, z));
      }
    }
  }

  for (final a in [-1.0, 1.0]) {
    for (final b in [-invPhi, invPhi]) {
      vertices.add(Vec3(0, b, a * phi));
      vertices.add(Vec3(b, a * phi, 0));
      vertices.add(Vec3(a * phi, 0, b));
    }
  }

  return _fromConvexHull(vertices);
}

/// D10 — пятиугольный трапецоэдр.
///
/// Строим его как двойственный многогранник
/// пятиугольного антипризмы.
DiceGeometry _pentagonalTrapezohedron() {
  const n = 5;
  const h = 0.65;

  final primal = <Vec3>[];

  for (int i = 0; i < n; i++) {
    final angle = 2 * pi * i / n;

    primal.add(Vec3(cos(angle), sin(angle), h));
  }

  for (int i = 0; i < n; i++) {
    final angle = 2 * pi * i / n + pi / n;

    primal.add(Vec3(cos(angle), sin(angle), -h));
  }

  final primalFaces = <List<int>>[];

  primalFaces.add([0, 1, 2, 3, 4]);
  primalFaces.add([9, 8, 7, 6, 5]);

  for (int i = 0; i < n; i++) {
    final next = (i + 1) % n;

    primalFaces.add([i, next, n + i]);
    primalFaces.add([next, n + next, n + i]);
  }

  // Создаём вершины двойственного многогранника.
  final dualVertices = <Vec3>[];

  for (final face in primalFaces) {
    var center = const Vec3(0, 0, 0);

    for (final index in face) {
      center = center + primal[index];
    }

    dualVertices.add(center * (1 / face.length));
  }

  // Создаём грани двойственного многогранника.
  final dualFaces = <DiceFace>[];

  for (int vertexIndex = 0; vertexIndex < primal.length; vertexIndex++) {
    final incident = <int>[];

    for (int faceIndex = 0; faceIndex < primalFaces.length; faceIndex++) {
      if (primalFaces[faceIndex].contains(vertexIndex)) {
        incident.add(faceIndex);
      }
    }

    final normal = primal[vertexIndex].normalized();

    final axis = normal.x.abs() < 0.9
        ? const Vec3(1, 0, 0)
        : const Vec3(0, 1, 0);

    final u = normal.cross(axis).normalized();
    final v = normal.cross(u).normalized();

    incident.sort((a, b) {
      final pointA = dualVertices[a];
      final pointB = dualVertices[b];

      final angleA = atan2(pointA.dot(v), pointA.dot(u));

      final angleB = atan2(pointB.dot(v), pointB.dot(u));

      return angleA.compareTo(angleB);
    });

    dualFaces.add(DiceFace(vertices: incident, value: dualFaces.length + 1));
  }

  return DiceGeometry(vertices: dualVertices, faces: dualFaces);
}

/// Строит выпуклую оболочку набора вершин.
///
/// Находит плоскости граней, собирает лежащие
/// на них вершины и сортирует их по окружности.
DiceGeometry _fromConvexHull(List<Vec3> vertices) {
  const epsilon = 0.00001;

  final faces = <DiceFace>[];
  final knownFaces = <String>{};

  for (int i = 0; i < vertices.length; i++) {
    for (int j = i + 1; j < vertices.length; j++) {
      for (int k = j + 1; k < vertices.length; k++) {
        final a = vertices[i];
        final b = vertices[j];
        final c = vertices[k];

        var normal = (b - a).cross(c - a);

        if (normal.length < epsilon) continue;

        normal = normal.normalized();

        final distances = vertices.map((v) => normal.dot(v - a)).toList();

        final hasPositive = distances.any((d) => d > epsilon);

        final hasNegative = distances.any((d) => d < -epsilon);

        // Плоскость должна быть опорной.
        if (hasPositive && hasNegative) continue;

        final coplanar = <int>[];

        for (int index = 0; index < vertices.length; index++) {
          if (distances[index].abs() < epsilon) {
            coplanar.add(index);
          }
        }

        if (coplanar.length < 3) continue;

        final key = coplanar.join(',');

        if (!knownFaces.add(key)) continue;

        var center = const Vec3(0, 0, 0);

        for (final index in coplanar) {
          center = center + vertices[index];
        }

        center = center * (1 / coplanar.length);

        // Ориентируем нормаль наружу.
        if (normal.dot(center) < 0) {
          normal = normal * -1;
        }

        final reference = normal.x.abs() < 0.8
            ? const Vec3(1, 0, 0)
            : const Vec3(0, 1, 0);

        final axisX = normal.cross(reference).normalized();

        final axisY = normal.cross(axisX).normalized();

        coplanar.sort((ia, ib) {
          final va = vertices[ia] - center;
          final vb = vertices[ib] - center;

          final angleA = atan2(va.dot(axisY), va.dot(axisX));

          final angleB = atan2(vb.dot(axisY), vb.dot(axisX));

          return angleA.compareTo(angleB);
        });

        faces.add(DiceFace(vertices: coplanar, value: faces.length + 1));
      }
    }
  }

  return DiceGeometry(vertices: vertices, faces: faces);
}
