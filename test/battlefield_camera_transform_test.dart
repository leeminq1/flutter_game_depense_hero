import 'dart:ui';

import 'package:depense_game/game/input/battlefield_camera_transform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('zoom clamps to 0.7 through 2.5 and reset returns identity', () {
    final camera = BattlefieldCameraTransform();

    camera.beginGesture(const Offset(200, 300));
    camera.applyScale(scale: 9, focalPoint: const Offset(200, 300));

    expect(camera.zoom, 2.5);
    expect(camera.isTransformed, isTrue);

    camera.reset();

    expect(camera.snapshot, const BattlefieldCameraSnapshot());
  });

  test('one-finger movement becomes a drag only after eight pixels', () {
    final camera = BattlefieldCameraTransform();

    camera.beginGesture(const Offset(20, 20));

    expect(camera.updatePan(const Offset(27, 20)), isFalse);
    expect(camera.updatePan(const Offset(29, 20)), isTrue);
    expect(camera.suppressTap, isTrue);
  });

  test('ending a drag allows the next independent tap', () {
    final camera = BattlefieldCameraTransform();
    camera.beginGesture(Offset.zero);
    camera.updatePan(const Offset(20, 0));

    camera.endGesture();

    expect(camera.suppressTap, isFalse);
  });

  test('pinch keeps the focal world point stationary', () {
    final camera = BattlefieldCameraTransform();

    camera.beginGesture(const Offset(100, 180));
    camera.applyScale(scale: 2, focalPoint: const Offset(100, 180));

    expect(camera.worldPointAt(const Offset(100, 180)), const Offset(100, 180));
  });

  test('pan is clamped so the battlefield cannot disappear', () {
    final camera = BattlefieldCameraTransform();

    camera.beginGesture(Offset.zero);
    camera.applyScale(scale: 2, focalPoint: Offset.zero);
    camera.updatePan(const Offset(-900, -900));
    camera.clampPan(
      viewport: const Size(400, 600),
      world: const Size(400, 600),
    );

    expect(camera.pan, const Offset(-400, -600));
  });

  test('zooming below one centers the smaller battlefield', () {
    final camera = BattlefieldCameraTransform();

    camera.beginGesture(const Offset(200, 300));
    camera.applyScale(scale: 0.7, focalPoint: const Offset(200, 300));
    camera.clampPan(
      viewport: const Size(400, 600),
      world: const Size(400, 600),
    );

    expect(camera.pan, const Offset(60, 90));
  });
}
