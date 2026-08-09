import 'dart:ui';

class BattlefieldCameraSnapshot {
  const BattlefieldCameraSnapshot({this.zoom = 1, this.pan = Offset.zero});

  final double zoom;
  final Offset pan;

  bool get isTransformed => (zoom - 1).abs() > 0.001 || pan.distance > 0.5;

  @override
  bool operator ==(Object other) =>
      other is BattlefieldCameraSnapshot &&
      other.zoom == zoom &&
      other.pan == pan;

  @override
  int get hashCode => Object.hash(zoom, pan);
}

class BattlefieldCameraTransform {
  static const minZoom = 0.7;
  static const maxZoom = 2.5;
  static const dragThreshold = 8.0;

  double _zoom = 1;
  Offset _pan = Offset.zero;
  Offset _gestureStart = Offset.zero;
  Offset _lastFocalPoint = Offset.zero;
  bool _dragging = false;
  bool _pinching = false;

  double get zoom => _zoom;
  Offset get pan => _pan;
  bool get suppressTap => _dragging || _pinching;
  bool get isTransformed => snapshot.isTransformed;
  BattlefieldCameraSnapshot get snapshot =>
      BattlefieldCameraSnapshot(zoom: _zoom, pan: _pan);

  void beginGesture(Offset focalPoint) {
    _gestureStart = focalPoint;
    _lastFocalPoint = focalPoint;
    _dragging = false;
    _pinching = false;
  }

  bool updatePan(Offset focalPoint) {
    if (!_dragging && (focalPoint - _gestureStart).distance <= dragThreshold) {
      _lastFocalPoint = focalPoint;
      return false;
    }
    _dragging = true;
    _pan += focalPoint - _lastFocalPoint;
    _lastFocalPoint = focalPoint;
    return true;
  }

  void applyScale({required double scale, required Offset focalPoint}) {
    _pinching = true;
    final worldBefore = worldPointAt(focalPoint);
    _zoom = scale.clamp(minZoom, maxZoom).toDouble();
    _pan = focalPoint - (worldBefore * _zoom);
    _lastFocalPoint = focalPoint;
  }

  void endGesture() {
    _dragging = false;
    _pinching = false;
  }

  Offset worldPointAt(Offset screenPoint) => (screenPoint - _pan) / _zoom;

  void clampPan({required Size viewport, required Size world}) {
    final renderedWidth = world.width * _zoom;
    final renderedHeight = world.height * _zoom;
    final minX = mathMin(0, viewport.width - renderedWidth);
    final minY = mathMin(0, viewport.height - renderedHeight);
    final maxX = renderedWidth < viewport.width
        ? (viewport.width - renderedWidth) / 2
        : 0.0;
    final maxY = renderedHeight < viewport.height
        ? (viewport.height - renderedHeight) / 2
        : 0.0;
    final resolvedMinX = renderedWidth < viewport.width ? maxX : minX;
    final resolvedMinY = renderedHeight < viewport.height ? maxY : minY;
    _pan = Offset(
      _pan.dx.clamp(resolvedMinX, maxX).toDouble(),
      _pan.dy.clamp(resolvedMinY, maxY).toDouble(),
    );
  }

  void reset() {
    _zoom = 1;
    _pan = Offset.zero;
    _dragging = false;
    _pinching = false;
  }
}

double mathMin(double a, double b) => a < b ? a : b;
