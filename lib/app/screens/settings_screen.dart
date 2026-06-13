import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
    final settings = bootstrap.audioSettingsController;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
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
                        'Audio',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Audio enabled'),
                        value: !settings.muted,
                        onChanged: (value) async {
                          settings.setMuted(!value);
                          await bootstrap.persistAudioSettings();
                        },
                      ),
                      _VolumeSlider(
                        label: 'Master',
                        value: settings.masterVolume,
                        onChanged: (value) async {
                          settings.setMasterVolume(value);
                          await bootstrap.persistAudioSettings();
                        },
                      ),
                      _VolumeSlider(
                        label: 'Music',
                        value: settings.musicVolume,
                        onChanged: (value) async {
                          settings.setMusicVolume(value);
                          await bootstrap.persistAudioSettings();
                        },
                      ),
                      _VolumeSlider(
                        label: 'SFX',
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
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Credits & Licenses'),
                  subtitle: const Text('Third-party art and audio credits'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LegalCreditsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class LegalCreditsScreen extends StatelessWidget {
  const LegalCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Third-party Licenses')),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('assets/legal/lpc_credits.txt'),
        builder: (context, snapshot) {
          final details = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Third-party Licenses',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              const Text(
                'Character sprites include assets from the Universal LPC '
                'Spritesheet Character Generator.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Source: '
                'https://github.com/LiberatedPixelCup/'
                'Universal-LPC-Spritesheet-Character-Generator',
              ),
              const SizedBox(height: 8),
              const Text(
                'License: CC-BY-SA 3.0 / GPL 3.0 / compatible LPC asset '
                'licenses. LPC-derived artwork requires attribution and '
                'share-alike handling for modified art.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Sprites contributed as part of the Liberated Pixel Cup '
                'project from OpenGameArt.org.',
              ),
              const Divider(height: 32),
              Text(
                'Detailed Credits',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (snapshot.connectionState != ConnectionState.done)
                const LinearProgressIndicator()
              else
                Text(
                  details ?? 'Detailed license credits could not be loaded.',
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
        SizedBox(width: 72, child: Text(label)),
        Expanded(
          child: Slider(value: value, min: 0, max: 1, onChanged: onChanged),
        ),
      ],
    );
  }
}
