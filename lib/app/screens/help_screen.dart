import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How To Play')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _HelpCard(
            title: 'Core Loop',
            body:
                'Place towers on glowing slots, start waves when you are ready, and keep building or upgrading during combat. Focus damage around one or two bends instead of spreading weak towers across the full map.',
          ),
          _HelpCard(
            title: 'Tower Roles',
            body:
                'Archer is cheap damage, Barracks holds lanes, Mage breaks armor, Frost stabilizes mixed pressure, Coin Mill buys stronger mid-wave economy, Ballista hunts elites, and Emberkeep punishes clusters.',
          ),
          _HelpCard(
            title: 'Enemy Roles',
            body:
                'Scouts leak if you wait too long, Shield Infantry punish pure physical builds, Cult Adepts buff allies, Grave Guards resist control, and Warlocks create support chaos. Fix the first enemy role that breaks your line.',
          ),
          _HelpCard(
            title: 'Meta Progress',
            body:
                'Stage clears grant XP and Meta Gold. First clears, stronger star results, and crest stages all add bonus Meta Gold. Use that to improve openings, unlock stronger buildables, and smooth long-run pacing.',
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(body),
            ],
          ),
        ),
      ),
    );
  }
}
