import 'package:depense_game/data/persistence/store_models.dart';
import 'package:flutter/foundation.dart';

class AudioSettingsController extends ChangeNotifier {
  AudioSettingsController({
    double masterVolume = 0.85,
    double musicVolume = 0.55,
    double sfxVolume = 0.90,
    bool muted = false,
  })  : _masterVolume = masterVolume,
        _musicVolume = musicVolume,
        _sfxVolume = sfxVolume,
        _muted = muted;

  factory AudioSettingsController.fromSnapshot(AudioSettingsSnapshot snapshot) {
    return AudioSettingsController(
      masterVolume: snapshot.masterVolume,
      musicVolume: snapshot.musicVolume,
      sfxVolume: snapshot.sfxVolume,
      muted: snapshot.muted,
    );
  }

  double _masterVolume;
  double _musicVolume;
  double _sfxVolume;
  bool _muted;

  double get masterVolume => _masterVolume;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  bool get muted => _muted;

  void setMasterVolume(double value) {
    _masterVolume = value.clamp(0, 1);
    notifyListeners();
  }

  void setMusicVolume(double value) {
    _musicVolume = value.clamp(0, 1);
    notifyListeners();
  }

  void setSfxVolume(double value) {
    _sfxVolume = value.clamp(0, 1);
    notifyListeners();
  }

  void setMuted(bool value) {
    _muted = value;
    notifyListeners();
  }
}
