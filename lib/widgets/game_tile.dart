import 'package:flutter/material.dart';
import '../models/models.dart';

/// A single tile on the game board - styled as a floating stone platform
/// 
/// ASSET NOTE: For production, replace the gradient with:
/// DecorationImage(image: AssetImage('assets/images/stone_tile.png'), fit: BoxFit.cover)
class GameTile extends StatefulWidget {
  final TileState tileState;
  final Position position;
  final bool isValidMove;
  final bool hasPlayer1;
  final bool hasPlayer2;
  final VoidCallback? onTap;
  final VoidCallback? onFallComplete;

  const GameTile({
    super.key,
    required this.tileState,
    required this.position,
    this.isValidMove = false,
    this.hasPlayer1 = false,
    this.hasPlayer2 = false,
    this.onTap,
    this.onFallComplete,
  });

  @override
  State<GameTile> createState() => _GameTileState();
}

class _GameTileState extends State<GameTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _fallController;
  late Animation<double> _fallAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fallController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fallAnimation = Tween<double>(begin: 0, end: 400).animate(
      CurvedAnimation(parent: _fallController, curve: Curves.easeInCubic),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 0.8).animate(
      CurvedAnimation(parent: _fallController, curve: Curves.easeIn),
    );

    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _fallController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _fallController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFallComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(GameTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Start fall animation when tile status changes to falling
    if (widget.tileState.isFalling && !oldWidget.tileState.isFalling) {
      _fallController.forward();
    }
    // Reset animation when tile becomes active again (new game started)
    if (widget.tileState.isPlayable && !oldWidget.tileState.isPlayable) {
      _fallController.reset();
    }
  }

  @override
  void dispose() {
    _fallController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't render void tiles
    if (widget.tileState.isVoid) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _fallController,
      builder: (context, child) {
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(1, 3, _fallAnimation.value) // Translate Y
            ..rotateZ(_rotateAnimation.value)
            ..rotateX(_rotateAnimation.value * 0.5),
          alignment: Alignment.center,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.isValidMove ? widget.onTap : null,
        child: _buildTileContent(),
      ),
    );
  }

  Widget _buildTileContent() {
    // Calculate checkerboard pattern
    final isLightSquare = (widget.position.row + widget.position.col) % 2 == 0;

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        // Stone tile appearance
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLightSquare
              ? [
                  const Color(0xFF4a4a5c),
                  const Color(0xFF3a3a4c),
                  const Color(0xFF2a2a3c),
                ]
              : [
                  const Color(0xFF3a3a4c),
                  const Color(0xFF2a2a3c),
                  const Color(0xFF1a1a2c),
                ],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: widget.isValidMove
              ? const Color(0xFF00FF88).withValues(alpha: 0.8)
              : const Color(0xFF666688).withValues(alpha: 0.3),
          width: widget.isValidMove ? 2 : 1,
        ),
        boxShadow: [
          // Outer glow for valid moves
          if (widget.isValidMove)
            BoxShadow(
              color: const Color(0xFF00FF88).withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          // Bottom shadow (floating effect)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          // Inner highlight
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Stone texture overlay (placeholder pattern)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: RadialGradient(
                center: const Alignment(-0.5, -0.5),
                radius: 1.5,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Valid move indicator pulsing
          if (widget.isValidMove)
            _ValidMoveIndicator(),
        ],
      ),
    );
  }
}

class _ValidMoveIndicator extends StatefulWidget {
  @override
  State<_ValidMoveIndicator> createState() => _ValidMoveIndicatorState();
}

class _ValidMoveIndicatorState extends State<_ValidMoveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: const Color(0xFF00FF88).withValues(
              alpha: 0.1 + (_pulseController.value * 0.15),
            ),
          ),
        );
      },
    );
  }
}
