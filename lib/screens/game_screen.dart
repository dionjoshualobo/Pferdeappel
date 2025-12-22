import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/game_provider.dart';
import '../widgets/widgets.dart';

/// Main game screen with layered Stack architecture
class GameScreen extends ConsumerStatefulWidget {
  final VoidCallback? onHomePressed;
  
  const GameScreen({super.key, this.onHomePressed});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  Timer? _computerMoveTimer;

  @override
  void initState() {
    super.initState();
    // Schedule initial computer move check after 1 second
    _computerMoveTimer = Timer(const Duration(seconds: 1), () {
      _checkAndExecuteComputerMove();
    });
  }

  @override
  void dispose() {
    _computerMoveTimer?.cancel();
    super.dispose();
  }

  void _checkAndExecuteComputerMove() {
    if (!mounted) return;
    
    final gameState = ref.read(gameStateProvider);
    final isComputerTurn = ref.read(isComputerTurnProvider);
    final isGameOver = gameState.result != GameResult.ongoing;
    final isAnimating = gameState.fallingTilePosition != null;
    
    if (isComputerTurn && !isGameOver && !isAnimating) {
      final move = ref.read(computerMoveProvider);
      if (move != null) {
        ref.read(gameStateProvider.notifier).makeMove(move);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final isPlayer2FirstMove = gameState.isPlayer2FirstMove;
    final isSmallBoard = gameState.gridSize == 4;
    final isGameOver = ref.watch(isGameOverProvider);
    final winner = ref.watch(winnerProvider);
    final isComputerTurn = ref.watch(isComputerTurnProvider);

    // Listen for turn changes and execute computer moves
    ref.listen<GameState>(gameStateProvider, (previous, next) {
      if (previous == null) return;
      
      // Check if turn changed, animation completed, or game reset
      final turnChanged = previous.currentPlayer != next.currentPlayer;
      final animationCompleted = previous.fallingTilePosition != null && next.fallingTilePosition == null;
      final gameReset = previous.moveCount > 0 && next.moveCount == 0;
      
      if ((turnChanged || animationCompleted || gameReset) && 
          next.result == GameResult.ongoing &&
          next.currentPlayer.isComputer(next.settings)) {
        // Small delay to let animations complete
        _computerMoveTimer?.cancel();
        _computerMoveTimer = Timer(const Duration(milliseconds: 100), () {
          _checkAndExecuteComputerMove();
        });
      }
    });
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // LAYER 1 (Bottom): The Abyss Background
            const AbyssBackground(),

            // LAYER 2 (Middle): Board frame glow effect
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B4EFF).withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            // LAYER 3 (Top): Game content
            Column(
              children: [
                // Top HUD with home and restart buttons
                GameHud(onHomePressed: widget.onHomePressed),

                // Game Board (takes remaining space)
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: GameBoard(),
                  ),
                ),

                // Bottom spacing
                const SizedBox(height: 24),
              ],
            ),

            // Vignette overlay for dramatic effect
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    stops: const [0.5, 0.8, 1.0],
                  ),
                ),
              ),
            ),
            
            // First move protection message overlay (only on small boards, not for computer)
            if (isPlayer2FirstMove && isSmallBoard && !isComputerTurn)
              const _FirstMoveOverlay(),
            
            // Win overlay
            if (isGameOver && winner != null)
              _WinOverlay(winner: winner, settings: gameState.settings),
            
            // Tie overlay
            if (isGameOver && winner == null && ref.watch(isTieProvider))
              const _TieOverlay(),
          ],
        ),
      ),
    );
  }
}

/// Overlay message that appears for player 2's first move and auto-dismisses
class _FirstMoveOverlay extends StatefulWidget {
  const _FirstMoveOverlay();

  @override
  State<_FirstMoveOverlay> createState() => _FirstMoveOverlayState();
}

class _FirstMoveOverlayState extends State<_FirstMoveOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.forward().then((_) {
          if (mounted) {
            setState(() => _visible = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            );
          },
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      "Not like Player 1 had any other choice!",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w500
                        
                      ),
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

/// Overlay that shows winner and Play Again button
class _WinOverlay extends ConsumerWidget {
  final Player winner;
  final GameSettings settings;

  const _WinOverlay({required this.winner, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = winner.getColor(settings);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: color.withValues(alpha: 0.6),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trophy icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.5),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 45,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Winner text
                Text(
                  '${winner.getDisplayName(settings)} wins!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.8),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Play Again button
                GestureDetector(
                  onTap: () => ref.read(gameStateProvider.notifier).resetGame(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.replay, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Play Again',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay shown when game ends in a tie
class _TieOverlay extends ConsumerWidget {
  const _TieOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const color = Color(0xFF9E9E9E); // Gray for tie

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: color.withValues(alpha: 0.6),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tie icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.5),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.handshake,
                    size: 35,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tie message
                Text(
                  "IT'S A TIE!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.8),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Only 2 tiles remain!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Play Again button
                GestureDetector(
                  onTap: () => ref.read(gameStateProvider.notifier).resetGame(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.replay, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Play Again',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
