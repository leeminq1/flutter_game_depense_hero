class BombardmentVisualPlan {
  static const int shellFrameCount = 4;
  static const int impactFrameCount = 6;
  static const double shellFramesPerSecond = 10;

  static int shellFrame({
    required double age,
    required double warningSeconds,
    int frameCount = shellFrameCount,
  }) {
    if (warningSeconds <= 0 || frameCount <= 0) {
      throw ArgumentError('warningSeconds and frameCount must be positive');
    }
    if (age >= warningSeconds) {
      return frameCount - 1;
    }
    final safeAge = age.clamp(0.0, warningSeconds);
    return (safeAge * shellFramesPerSecond).floor() % frameCount;
  }

  static int impactFrame({
    required double age,
    required double warningSeconds,
    required double lifetime,
    int frameCount = impactFrameCount,
  }) {
    if (warningSeconds < 0 || lifetime <= warningSeconds || frameCount <= 0) {
      throw ArgumentError(
        'lifetime must exceed warningSeconds and frameCount must be positive',
      );
    }
    final progress = ((age - warningSeconds) / (lifetime - warningSeconds))
        .clamp(0.0, 1.0);
    return (progress * frameCount).floor().clamp(0, frameCount - 1);
  }
}
