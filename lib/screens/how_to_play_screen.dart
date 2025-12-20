import 'package:flutter/material.dart';

/// How to Play instructions screen with swipeable pages
class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<InstructionPage> _pages = [
    InstructionPage(
      title: 'Welcome to Pferdeäppel!',
      description: 'A strategic 2-player game where you control knights on a shrinking board.',
      icon: Icons.sports_esports,
      color: const Color(0xFFFFD700),
    ),
    InstructionPage(
      title: 'Knight Movement',
      description: 'Your knight moves in an "L" shape - just like in chess!\n\n2 squares in one direction, then 1 square perpendicular.',
      icon: Icons.moving,
      color: const Color(0xFF4ECDC4),
      imagePath: 'assets/instructions/KnightMoves.png',
    ),
    InstructionPage(
      title: 'Valid Moves',
      description: 'Green highlighted tiles show where you can move.\n\nTap a valid tile to jump there!',
      icon: Icons.touch_app,
      color: const Color(0xFF2ECC71),
      imagePath: 'assets/instructions/ValidMoves.gif',
    ),
    InstructionPage(
      title: 'The Abyss',
      description: 'After you move, the tile you left FALLS INTO THE ABYSS!\n\nThe board shrinks with every move.',
      icon: Icons.blur_on,
      color: const Color(0xFF9B59B6),
      imagePath: 'assets/instructions/Abyss.gif',
    ),
    InstructionPage(
      title: 'Win by Capture',
      description: 'Land on your opponent\'s tile to CAPTURE them and win!',
      icon: Icons.gps_fixed,
      color: const Color(0xFFE74C3C),
      imagePath: 'assets/instructions/AttackOpponent.gif',
    ),
    InstructionPage(
      title: 'Win by Trapping',
      description: 'If your opponent has NO valid moves on their turn, YOU WIN!\n\nStrategically destroy tiles to trap them.',
      icon: Icons.block,
      color: const Color(0xFFFF9F43),
      imagePath: 'assets/instructions/NoValidMoves.gif',
    ),
    InstructionPage(
      title: '4×4 Special Rule',
      description: 'On a 4×4 board, Player 2 cannot capture on their first move.\n\nThis balances the game since Player 1 has limited starting options!',
      icon: Icons.shield,
      color: const Color(0xFF00BCD4),
      imagePath: 'assets/instructions/4x4.gif',
    ),
    InstructionPage(
      title: 'Customize Your Game',
      description: 'Tap the knights on the home screen to change colors.\n\nAdjust the grid size from 4×4 to 12×12.',
      icon: Icons.palette,
      color: const Color(0xFFE91E63),
      imagePaths: ['assets/instructions/ChooseColor.png', 'assets/instructions/Grid.png'],
    ),
    InstructionPage(
      title: 'Ready to Play!',
      description: 'Player 1 (top-left) goes first.\n\nOutsmart your opponent and claim victory!',
      icon: Icons.emoji_events,
      color: const Color(0xFFFFD700),
      isLast: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a14),
      body: SafeArea(
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'HOW TO PLAY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 56), // Balance the close button
                ],
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? _pages[_currentPage].color
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            // Swipeable pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  if (_currentPage > 0)
                    GestureDetector(
                      onTap: _previousPage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Back',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // Skip button on first page
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                    ),

                  // Next/Done button
                  GestureDetector(
                    onTap: _nextPage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _pages[_currentPage].color,
                            _pages[_currentPage].color.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: _pages[_currentPage].color.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == _pages.length - 1 ? 'Let\'s Go!' : 'Next',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _currentPage == _pages.length - 1
                                ? Icons.play_arrow
                                : Icons.arrow_forward,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(InstructionPage page) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          
          // Media content (multiple images, single image, or icon)
          if (page.imagePaths != null && page.imagePaths!.isNotEmpty)
            _buildMultipleImages(page)
          else if (page.imagePath != null)
            _buildImage(page)
          else
            _buildIcon(page),

          const SizedBox(height: 20),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: page.color,
              shadows: [
                Shadow(
                  color: page.color.withValues(alpha: 0.5),
                  blurRadius: 16,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildImage(InstructionPage page) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: page.color.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: page.color.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          page.imagePath!,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildIcon(InstructionPage page) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            page.color,
            page.color.withValues(alpha: 0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: page.color.withValues(alpha: 0.5),
            blurRadius: 25,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Icon(
        page.icon,
        size: 45,
        color: Colors.white,
      ),
    );
  }

  Widget _buildMultipleImages(InstructionPage page) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: page.imagePaths!.map((path) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 140),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: page.color.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: page.color.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                path,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class InstructionPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? imagePath;
  final List<String>? imagePaths; // For multiple images
  final bool isLast;

  const InstructionPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.imagePath,
    this.imagePaths,
    this.isLast = false,
  });
}
