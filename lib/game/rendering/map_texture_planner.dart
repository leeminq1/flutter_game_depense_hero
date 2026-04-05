import 'dart:ui';

import 'package:depense_game/game/models/stage_definition.dart';
import 'package:flame/game.dart';

enum MapTextureMarkShape {
  oval,
  rect,
  roundedRect,
  circle,
}

class MapTextureMark {
  const MapTextureMark({
    required this.shape,
    required this.color,
    required this.center,
    this.width = 0,
    this.height = 0,
    this.radius = 0,
    this.cornerRadius = 0,
  });

  final MapTextureMarkShape shape;
  final Color color;
  final Offset center;
  final double width;
  final double height;
  final double radius;
  final double cornerRadius;
}

class MapTexturePlan {
  const MapTexturePlan({
    this.groundMarks = const [],
    this.pathMarks = const [],
    this.anchorMarks = const [],
    this.crestMarks = const [],
  });

  final List<MapTextureMark> groundMarks;
  final List<MapTextureMark> pathMarks;
  final List<MapTextureMark> anchorMarks;
  final List<MapTextureMark> crestMarks;

  static const empty = MapTexturePlan();
}

class MapTexturePlanner {
  const MapTexturePlanner._();

  static MapTexturePlan build({
    required int stageNumber,
    required StageEnvironmentTheme theme,
    required Vector2 canvasSize,
    required List<Vector2> pathPoints,
    required List<Offset> buildSlots,
    required List<StageDecorationDefinition> decorations,
  }) {
    if (canvasSize.x <= 0 || canvasSize.y <= 0 || pathPoints.isEmpty) {
      return MapTexturePlan.empty;
    }

    final groundMarks = <MapTextureMark>[];
    final pathMarks = <MapTextureMark>[];
    final anchorMarks = <MapTextureMark>[];

    final suppressionZones = _suppressionZones(
      canvasSize: canvasSize,
      buildSlots: buildSlots,
      decorations: decorations,
    );
    final groundAccents = _groundAccentColors(theme);

    for (var gx = 0; gx < 8; gx += 1) {
      for (var gy = 0; gy < 6; gy += 1) {
        final seed = (stageNumber * 31) + (gx * 17) + (gy * 13);
        final cx = ((gx + 0.5) / 8) * canvasSize.x + (((seed % 9) - 4) * 3.0);
        final cy = ((gy + 0.5) / 6) * canvasSize.y + ((((seed ~/ 3) % 9) - 4) * 3.0);
        final center = Offset(cx, cy);
        if (_isSuppressed(center, suppressionZones, padding: 12)) {
          continue;
        }
        groundMarks.add(
          MapTextureMark(
            shape: _groundShapeForTheme(theme),
            color: groundAccents[seed % groundAccents.length],
            center: center,
            width: 14.0 + ((seed % 5) * 4.0),
            height: 8.0 + (((seed ~/ 2) % 4) * 3.0),
            cornerRadius: theme == StageEnvironmentTheme.cursedChapel ? 6 : 0,
          ),
        );
        if (theme == StageEnvironmentTheme.throneMarch) {
          groundMarks.add(
            MapTextureMark(
              shape: MapTextureMarkShape.circle,
              color: const Color(0x33FF9B52),
              center: center.translate(2, -1),
              radius: 1.5 + (seed % 2),
            ),
          );
        }
      }
    }

    final detailColor = _pathDetailColor(theme);
    final shadowColor = _pathShadowColor(theme);
    for (final point in _pathSamplePoints(pathPoints)) {
      if (_isSuppressed(point, suppressionZones, padding: 10)) {
        continue;
      }
      pathMarks.addAll(
        _pathDetailMarksForTheme(
          theme,
          point,
          detailColor: detailColor,
          shadowColor: shadowColor,
        ),
      );
    }

    anchorMarks.addAll(
      _anchorMarksForTheme(
        theme,
        pathPoints.first.toOffset(),
        detailColor: detailColor.withValues(alpha: 0.42),
        shadowColor: shadowColor.withValues(alpha: 0.34),
        radius: 22,
      ),
    );
    anchorMarks.addAll(
      _anchorMarksForTheme(
        theme,
        pathPoints.last.toOffset(),
        detailColor: detailColor.withValues(alpha: 0.50),
        shadowColor: shadowColor.withValues(alpha: 0.42),
        radius: 26,
      ),
    );
    for (final bend in _majorPathBendPoints(pathPoints)) {
      if (_isSuppressed(bend, suppressionZones, padding: 8)) {
        continue;
      }
      anchorMarks.addAll(
        _anchorMarksForTheme(
          theme,
          bend,
          detailColor: detailColor.withValues(alpha: 0.34),
          shadowColor: shadowColor.withValues(alpha: 0.28),
          radius: 18,
        ),
      );
    }

    final crestMarks = _crestStageMarks(
      stageNumber: stageNumber,
      theme: theme,
      canvasSize: canvasSize,
      pathPoints: pathPoints,
      suppressionZones: suppressionZones,
    );

    return MapTexturePlan(
      groundMarks: groundMarks,
      pathMarks: pathMarks,
      anchorMarks: anchorMarks,
      crestMarks: crestMarks,
    );
  }

  static List<MapTextureMark> _crestStageMarks({
    required int stageNumber,
    required StageEnvironmentTheme theme,
    required Vector2 canvasSize,
    required List<Vector2> pathPoints,
    required List<_SuppressionZone> suppressionZones,
  }) {
    final marks = <MapTextureMark>[];
    final isCrest = switch (stageNumber) {
      5 || 10 || 15 || 20 || 25 || 30 => true,
      _ => false,
    };
    if (!isCrest || pathPoints.isEmpty) {
      return marks;
    }

    final mid = pathPoints[pathPoints.length ~/ 2].toOffset();
    final latePath = pathPoints[(pathPoints.length * 3 ~/ 4).clamp(0, pathPoints.length - 1)].toOffset();

    void add(MapTextureMark mark, {double padding = 6}) {
      if (_isSuppressed(mark.center, suppressionZones, padding: padding)) {
        return;
      }
      marks.add(mark);
    }

    switch (stageNumber) {
      case 5:
        add(
          MapTextureMark(
            shape: MapTextureMarkShape.oval,
            color: const Color(0x3F6F5A34),
            center: mid.translate(-18, -6),
            width: 34,
            height: 12,
          ),
        );
        add(
          MapTextureMark(
            shape: MapTextureMarkShape.oval,
            color: const Color(0x44E3CB93),
            center: mid.translate(10, 4),
            width: 12,
            height: 6,
          ),
        );
        break;
      case 10:
        add(
          MapTextureMark(
            shape: MapTextureMarkShape.rect,
            color: const Color(0x45593B24),
            center: mid.translate(16, -10),
            width: 26,
            height: 8,
          ),
        );
        add(
          MapTextureMark(
            shape: MapTextureMarkShape.rect,
            color: const Color(0x44D9B77E),
            center: latePath.translate(-8, 6),
            width: 10,
            height: 3,
          ),
        );
        break;
      case 15:
        add(
          MapTextureMark(
            shape: MapTextureMarkShape.circle,
            color: const Color(0x3F4F5E57),
            center: mid.translate(-12, 8),
            radius: 8,
          ),
        );
        add(
          MapTextureMark(
            shape: MapTextureMarkShape.rect,
            color: const Color(0x44B7C4B8),
            center: latePath.translate(8, -6),
            width: 14,
            height: 2,
          ),
        );
        break;
      case 20:
        add(
          MapTextureMark(
            shape: MapTextureMarkShape.roundedRect,
            color: const Color(0x4A6A4B88),
            center: mid.translate(18, 2),
            width: 20,
            height: 8,
            cornerRadius: 4,
          ),
        );
        add(
          MapTextureMark(
            shape: MapTextureMarkShape.circle,
            color: const Color(0x44CFAAF5),
            center: latePath.translate(-10, -8),
            radius: 3,
          ),
        );
        add(
          MapTextureMark(
            shape: MapTextureMarkShape.circle,
            color: const Color(0x338A63D8),
            center: latePath.translate(-2, -2),
            radius: 2,
          ),
        );
        break;
      case 25:
        add(
          MapTextureMark(
            shape: MapTextureMarkShape.rect,
            color: const Color(0x464B4F58),
            center: mid.translate(-20, 0),
            width: 30,
            height: 10,
          ),
        );
        add(
          MapTextureMark(
            shape: MapTextureMarkShape.rect,
            color: const Color(0x44CDC3B5),
            center: latePath.translate(12, 6),
            width: 12,
            height: 2,
          ),
        );
        break;
      case 30:
        add(
          MapTextureMark(
            shape: MapTextureMarkShape.oval,
            color: const Color(0x4A5B2B1E),
            center: mid.translate(14, -4),
            width: 28,
            height: 10,
          ),
        );
        add(
          MapTextureMark(
            shape: MapTextureMarkShape.circle,
            color: const Color(0x44FF934E),
            center: latePath.translate(-14, 6),
            radius: 3,
          ),
        );
        add(
          MapTextureMark(
            shape: MapTextureMarkShape.circle,
            color: const Color(0x33FF6C3B),
            center: latePath.translate(-6, 0),
            radius: 2,
          ),
        );
        break;
    }

    return marks;
  }

  static List<Offset> _pathSamplePoints(List<Vector2> pathPoints, {double spacing = 54}) {
    if (pathPoints.length < 2) {
      return const [];
    }
    final path = Path()..moveTo(pathPoints.first.x, pathPoints.first.y);
    for (final point in pathPoints.skip(1)) {
      path.lineTo(point.x, point.y);
    }
    final metrics = path.computeMetrics().toList();
    final points = <Offset>[];
    for (final metric in metrics) {
      for (double distance = spacing * 0.6; distance < metric.length; distance += spacing) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          points.add(tangent.position);
        }
      }
    }
    return points;
  }

  static List<Offset> _majorPathBendPoints(List<Vector2> pathPoints) {
    if (pathPoints.length < 3) {
      return const [];
    }
    final bends = <Offset>[];
    for (var index = 1; index < pathPoints.length - 1; index += 1) {
      final previous = pathPoints[index - 1];
      final current = pathPoints[index];
      final next = pathPoints[index + 1];
      final incoming = (current - previous)..normalize();
      final outgoing = (next - current)..normalize();
      if (incoming.dot(outgoing) < 0.82) {
        bends.add(current.toOffset());
      }
    }
    return bends;
  }

  static List<_SuppressionZone> _suppressionZones({
    required Vector2 canvasSize,
    required List<Offset> buildSlots,
    required List<StageDecorationDefinition> decorations,
  }) {
    return [
      for (final slot in buildSlots)
        _SuppressionZone(
          center: Offset(slot.dx * canvasSize.x, slot.dy * canvasSize.y),
          radius: 30,
        ),
      for (final decoration in decorations)
        _SuppressionZone(
          center: Offset(
            decoration.position.dx * canvasSize.x,
            decoration.position.dy * canvasSize.y,
          ),
          radius: (((decoration.assetPath.contains('/landmarks/') ? 86.0 : 44.0) * decoration.scale) * 0.42),
        ),
    ];
  }

  static bool _isSuppressed(
    Offset point,
    List<_SuppressionZone> zones, {
    required double padding,
  }) {
    for (final zone in zones) {
      if ((zone.center - point).distance <= zone.radius + padding) {
        return true;
      }
    }
    return false;
  }

  static MapTextureMarkShape _groundShapeForTheme(StageEnvironmentTheme theme) {
    return switch (theme) {
      StageEnvironmentTheme.frontierRoad => MapTextureMarkShape.oval,
      StageEnvironmentTheme.banditCrossroads => MapTextureMarkShape.oval,
      StageEnvironmentTheme.graveFields => MapTextureMarkShape.oval,
      StageEnvironmentTheme.cursedChapel => MapTextureMarkShape.roundedRect,
      StageEnvironmentTheme.bastionApproach => MapTextureMarkShape.rect,
      StageEnvironmentTheme.throneMarch => MapTextureMarkShape.oval,
    };
  }

  static List<Color> _groundAccentColors(StageEnvironmentTheme theme) {
    return switch (theme) {
      StageEnvironmentTheme.frontierRoad => const [
          Color(0x223E5B30),
          Color(0x1F8E724D),
          Color(0x16564231),
        ],
      StageEnvironmentTheme.banditCrossroads => const [
          Color(0x22593B24),
          Color(0x1D7A5937),
          Color(0x18442B1A),
        ],
      StageEnvironmentTheme.graveFields => const [
          Color(0x223D5147),
          Color(0x1E6E6D61),
          Color(0x18424A44),
        ],
      StageEnvironmentTheme.cursedChapel => const [
          Color(0x224B3760),
          Color(0x1F7A5B90),
          Color(0x18352A44),
        ],
      StageEnvironmentTheme.bastionApproach => const [
          Color(0x224B4D57),
          Color(0x1F6B6F77),
          Color(0x18383A40),
        ],
      StageEnvironmentTheme.throneMarch => const [
          Color(0x225B3424),
          Color(0x1F8C5A32),
          Color(0x184A231A),
        ],
    };
  }

  static Color _pathDetailColor(StageEnvironmentTheme theme) {
    return switch (theme) {
      StageEnvironmentTheme.frontierRoad => const Color(0x55E1C893),
      StageEnvironmentTheme.banditCrossroads => const Color(0x55D9B77E),
      StageEnvironmentTheme.graveFields => const Color(0x559AB3A1),
      StageEnvironmentTheme.cursedChapel => const Color(0x55C2A3EC),
      StageEnvironmentTheme.bastionApproach => const Color(0x55C8C0B4),
      StageEnvironmentTheme.throneMarch => const Color(0x55F0B374),
    };
  }

  static Color _pathShadowColor(StageEnvironmentTheme theme) {
    return switch (theme) {
      StageEnvironmentTheme.frontierRoad => const Color(0x553E2D1E),
      StageEnvironmentTheme.banditCrossroads => const Color(0x55412D1F),
      StageEnvironmentTheme.graveFields => const Color(0x55404442),
      StageEnvironmentTheme.cursedChapel => const Color(0x5540334F),
      StageEnvironmentTheme.bastionApproach => const Color(0x55444953),
      StageEnvironmentTheme.throneMarch => const Color(0x5556382A),
    };
  }

  static List<MapTextureMark> _pathDetailMarksForTheme(
    StageEnvironmentTheme theme,
    Offset point, {
    required Color detailColor,
    required Color shadowColor,
  }) {
    return switch (theme) {
      StageEnvironmentTheme.frontierRoad => [
          MapTextureMark(
            shape: MapTextureMarkShape.oval,
            color: shadowColor,
            center: point,
            width: 18,
            height: 7,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.circle,
            color: detailColor,
            center: point.translate(6, -1),
            radius: 1.8,
          ),
        ],
      StageEnvironmentTheme.banditCrossroads => [
          MapTextureMark(
            shape: MapTextureMarkShape.rect,
            color: shadowColor,
            center: point,
            width: 14,
            height: 6,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.rect,
            color: detailColor,
            center: point.translate(4, -2),
            width: 4,
            height: 2,
          ),
        ],
      StageEnvironmentTheme.graveFields => [
          MapTextureMark(
            shape: MapTextureMarkShape.circle,
            color: shadowColor,
            center: point,
            radius: 4.5,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.rect,
            color: detailColor,
            center: point.translate(4, -2),
            width: 8,
            height: 1.6,
          ),
        ],
      StageEnvironmentTheme.cursedChapel => [
          MapTextureMark(
            shape: MapTextureMarkShape.circle,
            color: shadowColor,
            center: point,
            radius: 4.2,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.circle,
            color: detailColor,
            center: point.translate(1.5, -1.5),
            radius: 1.7,
          ),
        ],
      StageEnvironmentTheme.bastionApproach => [
          MapTextureMark(
            shape: MapTextureMarkShape.rect,
            color: shadowColor,
            center: point,
            width: 12,
            height: 6,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.rect,
            color: detailColor,
            center: point.translate(0, -2),
            width: 8,
            height: 1.6,
          ),
        ],
      StageEnvironmentTheme.throneMarch => [
          MapTextureMark(
            shape: MapTextureMarkShape.oval,
            color: shadowColor,
            center: point,
            width: 14,
            height: 6,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.circle,
            color: detailColor,
            center: point.translate(-4, -1),
            radius: 1.3,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.circle,
            color: detailColor,
            center: point.translate(3, 1),
            radius: 1.1,
          ),
        ],
    };
  }

  static List<MapTextureMark> _anchorMarksForTheme(
    StageEnvironmentTheme theme,
    Offset center, {
    required Color detailColor,
    required Color shadowColor,
    required double radius,
  }) {
    return switch (theme) {
      StageEnvironmentTheme.frontierRoad => [
          MapTextureMark(
            shape: MapTextureMarkShape.oval,
            color: shadowColor,
            center: center.translate(-8, 0),
            width: radius * 1.3,
            height: radius * 0.48,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.oval,
            color: shadowColor,
            center: center.translate(8, 2),
            width: radius * 1.1,
            height: radius * 0.42,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.circle,
            color: detailColor,
            center: center.translate(10, -4),
            radius: 2.3,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.circle,
            color: detailColor,
            center: center.translate(-12, 6),
            radius: 1.9,
          ),
        ],
      StageEnvironmentTheme.banditCrossroads => [
          MapTextureMark(
            shape: MapTextureMarkShape.rect,
            color: shadowColor,
            center: center.translate(-6, 0),
            width: radius * 1.0,
            height: radius * 0.42,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.rect,
            color: shadowColor,
            center: center.translate(8, 4),
            width: radius * 0.72,
            height: radius * 0.26,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.rect,
            color: detailColor,
            center: center.translate(10, -3),
            width: 6,
            height: 2,
          ),
        ],
      StageEnvironmentTheme.graveFields => [
          MapTextureMark(
            shape: MapTextureMarkShape.circle,
            color: shadowColor,
            center: center.translate(-6, 0),
            radius: radius * 0.24,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.circle,
            color: shadowColor,
            center: center.translate(8, 2),
            radius: radius * 0.18,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.rect,
            color: detailColor,
            center: center.translate(9, -4),
            width: 10,
            height: 1.8,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.rect,
            color: detailColor,
            center: center.translate(-10, 5),
            width: 7,
            height: 1.4,
          ),
        ],
      StageEnvironmentTheme.cursedChapel => [
          MapTextureMark(
            shape: MapTextureMarkShape.roundedRect,
            color: shadowColor,
            center: center.translate(-5, 1),
            width: radius * 0.75,
            height: radius * 0.46,
            cornerRadius: 4,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.roundedRect,
            color: detailColor,
            center: center.translate(8, -3),
            width: radius * 0.55,
            height: radius * 0.32,
            cornerRadius: 3,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.circle,
            color: detailColor,
            center: center.translate(11, 6),
            radius: 1.8,
          ),
        ],
      StageEnvironmentTheme.bastionApproach => [
          MapTextureMark(
            shape: MapTextureMarkShape.rect,
            color: shadowColor,
            center: center.translate(-7, 0),
            width: radius * 0.82,
            height: radius * 0.38,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.rect,
            color: shadowColor,
            center: center.translate(8, 0),
            width: radius * 0.66,
            height: radius * 0.30,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.rect,
            color: detailColor,
            center: center.translate(0, -5),
            width: radius * 0.72,
            height: 2,
          ),
        ],
      StageEnvironmentTheme.throneMarch => [
          MapTextureMark(
            shape: MapTextureMarkShape.oval,
            color: shadowColor,
            center: center.translate(-7, 0),
            width: radius * 1.0,
            height: radius * 0.38,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.oval,
            color: shadowColor,
            center: center.translate(8, 3),
            width: radius * 0.7,
            height: radius * 0.24,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.circle,
            color: detailColor,
            center: center.translate(8, -5),
            radius: 2.0,
          ),
          MapTextureMark(
            shape: MapTextureMarkShape.circle,
            color: detailColor,
            center: center.translate(-10, 6),
            radius: 1.6,
          ),
        ],
    };
  }
}

class _SuppressionZone {
  const _SuppressionZone({
    required this.center,
    required this.radius,
  });

  final Offset center;
  final double radius;
}
