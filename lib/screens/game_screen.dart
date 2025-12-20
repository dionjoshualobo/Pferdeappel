import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../widgets/widgets.dart';

/// Main game screen with layered Stack architecture
class GameScreen extends ConsumerWidget {
  final VoidCallback? onHomePressed;
  
  const GameScreen({super.key, this.onHomePressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final isPlayer2FirstMove = gameState.isPlayer2FirstMove;
    final isSmallBoard = gameState.gridSize == 4; // Show message only on 4x4 boards
    
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
                GameHud(onHomePressed: onHomePressed),

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
            
            // First move protection message overlay (only on small boards)
            if (isPlayer2FirstMove && isSmallBoard)
              const _FirstMoveOverlay(),
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
