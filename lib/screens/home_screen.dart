import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../widgets/abyss_background.dart';
import 'how_to_play_screen.dart';

/// Home screen with play button, knight color selectors, and grid size input
class HomeScreen extends StatefulWidget {
  final void Function(GameSettings settings) onStartGame;
  final GameSettings? initialSettings;

  const HomeScreen({
    super.key, 
    required this.onStartGame,
    this.initialSettings,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Color _player1Color;
  late Color _player2Color;
  late int _gridSize;
  late TextEditingController _gridController;
  late bool _isPlayer1Computer;
  late bool _isPlayer2Computer;
  late Difficulty _player1Difficulty;
  late Difficulty _player2Difficulty;

  @override
  void initState() {
    super.initState();
    // Use initial settings if provided, otherwise use defaults
    final settings = widget.initialSettings;
    _player1Color = settings?.player1Color ?? GameSettings.availableColors[0];
    _player2Color = settings?.player2Color ?? GameSettings.availableColors[3];
    _gridSize = settings?.gridSize ?? 8;
    _gridController = TextEditingController(text: _gridSize.toString());
    _isPlayer1Computer = settings?.isPlayer1Computer ?? false;
    _isPlayer2Computer = settings?.isPlayer2Computer ?? false;
    _player1Difficulty = settings?.player1Difficulty ?? Difficulty.easy;
    _player2Difficulty = settings?.player2Difficulty ?? Difficulty.easy;
  }

  @override
  void dispose() {
    _gridController.dispose();
    super.dispose();
  }

  void _showColorPicker(Player player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ColorPickerSheet(
        currentColor: player == Player.player1 ? _player1Color : _player2Color,
        otherPlayerColor: player == Player.player1 ? _player2Color : _player1Color,
        onColorSelected: (color) {
          setState(() {
            if (player == Player.player1) {
              _player1Color = color;
            } else {
              _player2Color = color;
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _startGame() {
    final settings = GameSettings(
      gridSize: _gridSize.clamp(4, 12), // Min 4x4, Max 12x12
      player1Color: _player1Color,
      player2Color: _player2Color,
      isPlayer1Computer: _isPlayer1Computer,
      isPlayer2Computer: _isPlayer2Computer,
      player1Difficulty: _player1Difficulty,
      player2Difficulty: _player2Difficulty,
    );
    widget.onStartGame(settings);
  }

  /// Get available difficulty levels based on grid size
  /// Impossible mode is disabled for 4x4 boards (mathematically unsolvable)
  List<Difficulty> _getAvailableDifficulties() {
    if (_gridSize == 4) {
      // On 4x4, Impossible is disabled - P2 has forced win, P1 cannot avoid loss
      return Difficulty.values.where((d) => d != Difficulty.impossible).toList();
    }
    return Difficulty.values.toList();
  }

  /// Ensure difficulty is valid for current grid size
  void _validateDifficulties() {
    if (_gridSize == 4) {
      // Downgrade Impossible to Hard on 4x4
      if (_player1Difficulty == Difficulty.impossible) {
        _player1Difficulty = Difficulty.hard;
      }
      if (_player2Difficulty == Difficulty.impossible) {
        _player2Difficulty = Difficulty.hard;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Abyss background
          const AbyssBackground(),
          
          // Vignette overlay
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
          
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    _buildTitle(),
                    
                    const SizedBox(height: 48),
                    
                    // Knight color selectors and play button
                    _buildPlaySection(),
                    
                    const SizedBox(height: 32),
                    
                    // Grid size selector
                    _buildGridSizeSelector(),
                    
                    const SizedBox(height: 24),
                    
                    // How to Play button
                    _buildHowToPlayButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'PFERDEÄPPEL',
      style: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.bold,
        letterSpacing: 6,
        color: Colors.white.withValues(alpha: 0.95),
        shadows: [
          Shadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.8),
            blurRadius: 30,
          ),
          const Shadow(
            color: Colors.black,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaySection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Player 1 knight
        _buildKnightSelector(Player.player1, _player1Color),
        
        const SizedBox(width: 24),
        
        // Play button
        _buildPlayButton(),
        
        const SizedBox(width: 24),
        
        // Player 2 knight
        _buildKnightSelector(Player.player2, _player2Color),
      ],
    );
  }

  Widget _buildKnightSelector(Player player, Color color) {
    final isPlayer1 = player == Player.player1;
    final isComputer = isPlayer1 ? _isPlayer1Computer : _isPlayer2Computer;
    final difficulty = isPlayer1 ? _player1Difficulty : _player2Difficulty;

    return Column(
      children: [
        // Knight icon (tap to change color)
        GestureDetector(
          onTap: () => _showColorPicker(player),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.3),
                radius: 0.8,
                colors: [
                  color,
                  GameSettings.getAccentColor(color),
                  GameSettings.getAccentColor(color).withValues(alpha: 0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '♞', // Unicode chess knight
                style: TextStyle(
                  fontSize: 42,
                  color: Colors.white.withValues(alpha: 0.95),
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Player label (Computer or Player 1/2)
        Text(
          isComputer ? 'Computer' : player.displayName,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          'Tap to change color',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 12),
        // Computer toggle
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Computer',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 24,
              child: Switch(
                value: isComputer,
                onChanged: (value) {
                  setState(() {
                    if (isPlayer1) {
                      _isPlayer1Computer = value;
                      // Prevent both being computer
                      if (value && _isPlayer2Computer) {
                        _isPlayer2Computer = false;
                      }
                    } else {
                      _isPlayer2Computer = value;
                      // Prevent both being computer
                      if (value && _isPlayer1Computer) {
                        _isPlayer1Computer = false;
                      }
                    }
                  });
                },
                activeColor: color,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        // Difficulty dropdown (only visible when computer is enabled)
        if (isComputer) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.5),
              ),
            ),
            child: DropdownButton<Difficulty>(
              value: difficulty,
              items: _getAvailableDifficulties().map((d) {
                return DropdownMenuItem(
                  value: d,
                  child: Text(
                    d.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    if (isPlayer1) {
                      _player1Difficulty = value;
                    } else {
                      _player2Difficulty = value;
                    }
                  });
                }
              },
              dropdownColor: const Color(0xFF2a2a3e),
              underline: const SizedBox(),
              isDense: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: color,
                size: 18,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: _startGame,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B4EFF),
              Color(0xFF9B59B6),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B4EFF).withValues(alpha: 0.6),
              blurRadius: 30,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 3,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.play_arrow,
            size: 50,
            color: Colors.white.withValues(alpha: 0.95),
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridSizeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            'GRID SIZE',
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 2,
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grid size input
              Container(
                width: 60,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6B4EFF).withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: TextField(
                    controller: _gridController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null) {
                        setState(() {
                          _gridSize = parsed.clamp(4, 12);
                          _validateDifficulties(); // Auto-downgrade Impossible on 4x4
                        });
                      }
                    },
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Text(
                'x',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Display matching size
              Container(
                width: 60,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${_gridSize.clamp(4, 12)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Min: 4 • Max: 12',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToPlayButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HowToPlayScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.help_outline,
              color: Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'How to Play?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for color selection
class _ColorPickerSheet extends StatelessWidget {
  final Color currentColor;
  final Color otherPlayerColor;
  final void Function(Color) onColorSelected;

  const _ColorPickerSheet({
    required this.currentColor,
    required this.otherPlayerColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Choose Color',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: GameSettings.availableColors.map((color) {
              final isSelected = color == currentColor;
              final isOtherPlayer = color == otherPlayerColor;
              
              return GestureDetector(
                onTap: isOtherPlayer ? null : () => onColorSelected(color),
                child: Opacity(
                  opacity: isOtherPlayer ? 0.3 : 1.0,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : isOtherPlayer
                            ? const Icon(Icons.block, color: Colors.white54)
                            : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
