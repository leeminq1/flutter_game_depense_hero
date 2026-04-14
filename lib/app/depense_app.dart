import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:depense_game/app/screens/title_screen.dart';
import 'package:depense_game/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class DepenseApp extends StatelessWidget {
  const DepenseApp({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Depense Game',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      builder: (context, child) {
        if (child == null) {
          return const SizedBox.shrink();
        }

        final mediaQuery = MediaQuery.of(context);
        final isPortrait = mediaQuery.size.height >= mediaQuery.size.width;
        if (!isPortrait) {
          return const _PortraitOnlyScaffold();
        }

        return child;
      },
      home: TitleScreen(bootstrap: bootstrap),
    );
  }
}

class _PortraitOnlyScaffold extends StatelessWidget {
  const _PortraitOnlyScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF071B2F),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.screen_lock_portrait_rounded,
                    size: 72,
                    color: Color(0xFFE4C67A),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Portrait Only',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'This game is designed for phone and tablet portrait play. Rotate the device or browser to portrait orientation to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
