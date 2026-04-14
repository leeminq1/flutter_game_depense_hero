class AudioSettingsSnapshot {
  const AudioSettingsSnapshot({
    required this.masterVolume,
    required this.musicVolume,
    required this.sfxVolume,
    required this.muted,
    required this.tutorialDismissed,
  });

  final double masterVolume;
  final double musicVolume;
  final double sfxVolume;
  final bool muted;
  final bool tutorialDismissed;
}
