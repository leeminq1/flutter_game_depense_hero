import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
    final settings = bootstrap.audioSettingsController;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '오디오',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('오디오 켜기'),
                        value: !settings.muted,
                        onChanged: (value) async {
                          settings.setMuted(!value);
                          await bootstrap.persistAudioSettings();
                        },
                      ),
                      _VolumeSlider(
                        label: '전체',
                        value: settings.masterVolume,
                        onChanged: (value) async {
                          settings.setMasterVolume(value);
                          await bootstrap.persistAudioSettings();
                        },
                      ),
                      _VolumeSlider(
                        label: '효과음',
                        value: settings.sfxVolume,
                        onChanged: (value) async {
                          settings.setSfxVolume(value);
                          await bootstrap.persistAudioSettings();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label)),
        Expanded(
          child: Slider(value: value, min: 0, max: 1, onChanged: onChanged),
        ),
      ],
    );
  }
}
