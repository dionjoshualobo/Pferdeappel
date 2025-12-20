import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/models.dart';
import 'providers/game_provider.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock to portrait mode for better gameplay
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: KnightChaseApp(),
    ),
  );
}

class KnightChaseApp extends StatelessWidget {
  const KnightChaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pferdeäppel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4EFF),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: const AppNavigator(),
    );
  }
}

/// Handles navigation between home and game screens
class AppNavigator extends ConsumerStatefulWidget {
  const AppNavigator({super.key});

  @override
  ConsumerState<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends ConsumerState<AppNavigator> {
  bool _isPlaying = false;
  GameSettings? _lastSettings; // Persist settings between screens

  void _startGame(GameSettings settings) {
    _lastSettings = settings; // Remember the settings
    ref.read(gameStateProvider.notifier).startNewGame(settings);
    setState(() {
      _isPlaying = true;
    });
  }

  void _goHome() {
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isPlaying) {
      return GameScreen(onHomePressed: _goHome);
    } else {
      return HomeScreen(
        onStartGame: _startGame,
        initialSettings: _lastSettings,
      );
    }
  }
}
