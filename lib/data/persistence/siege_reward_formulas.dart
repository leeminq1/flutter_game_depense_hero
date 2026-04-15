import 'dart:math' as math;

/// Pure computation helpers for siege reward and failure formulas.
///
/// These functions contain no side-effects and no dependency on the store
/// implementation so they can be used by both [InMemoryProgressStore] and
/// [LocalProgressStore] without duplication.
///
/// Economy spec reference: docs/product-specs/economy-and-monetization.md
/// Meta progression spec:  docs/product-specs/meta-progression.md
class SiegeRewardFormulas {
  SiegeRewardFormulas._();

  // -------------------------------------------------------------------------
  // Siege Token awards
  // -------------------------------------------------------------------------

  /// Awards per siege clear result.
  ///
  /// Rules (from economy spec):
  ///   - Clear                           → 1 token
  ///   - Clear + citadel HP above target → +1 token
  ///   - Clear + one mastery objective   → +1 token
  ///   - Maximum per siege               → 3 tokens
  ///   - Failure                         → 0 tokens, always
  static int computeSiegeTokensEarned({
    required bool cleared,
    required bool hpObjectiveMet,
    required bool masteryObjectiveMet,
  }) {
    if (!cleared) return 0;
    final tokens = 1 + (hpObjectiveMet ? 1 : 0) + (masteryObjectiveMet ? 1 : 0);
    return tokens.clamp(0, 3);
  }

  // -------------------------------------------------------------------------
  // Failure reward formulas
  // -------------------------------------------------------------------------

  /// Minimum cycle progress ratio applied on any started siege.
  static const double minCycleProgressRatio = 0.25;

  /// Clamps [completedCycles] / [totalCycles] to [minCycleProgressRatio] floor.
  static double cycleProgressRatio({
    required int completedCycles,
    required int totalCycles,
  }) {
    if (totalCycles <= 0) return minCycleProgressRatio;
    final raw = completedCycles / totalCycles;
    return math.max(raw, minCycleProgressRatio);
  }

  /// Meta Gold awarded on failure.
  ///
  ///   failureMetaGold = round(clearMetaGoldBase × 0.35 × cycleProgressRatio)
  static int computeFailureMetaGold({
    required int clearMetaGoldBase,
    required int completedCycles,
    required int totalCycles,
  }) {
    final ratio = cycleProgressRatio(
      completedCycles: completedCycles,
      totalCycles: totalCycles,
    );
    return (clearMetaGoldBase * 0.35 * ratio).round();
  }

  /// XP awarded on failure.
  ///
  ///   failureXp = round(clearXpBase × 0.50 × cycleProgressRatio)
  static int computeFailureXp({
    required int clearXpBase,
    required int completedCycles,
    required int totalCycles,
  }) {
    final ratio = cycleProgressRatio(
      completedCycles: completedCycles,
      totalCycles: totalCycles,
    );
    return (clearXpBase * 0.50 * ratio).round();
  }

  // -------------------------------------------------------------------------
  // Recovery payout bonuses
  // -------------------------------------------------------------------------

  /// Flat cycle-completion gold bonus by act (siege 1-5 = act 1, etc.).
  ///
  /// From economy spec: +40 to +80 gold depending on act.
  static int cycleCompletionGoldBonus(int actNumber) {
    return switch (actNumber) {
      1 => 40,
      2 => 48,
      3 => 56,
      4 => 64,
      5 => 72,
      _ => 80,
    };
  }

  /// Returns the act number (1–6) for a given siege number (1–30).
  static int actForSiege(int siegeNumber) {
    return ((siegeNumber - 1) ~/ 5) + 1;
  }
}
