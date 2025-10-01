import 'package:flutter/material.dart';
import '../models/character.dart';
import '../services/image_service.dart';

class CharacterWidget extends StatelessWidget {
  final Character character;
  final double size;
  final bool showShadow;

  const CharacterWidget({
    super.key,
    required this.character,
    this.size = 80.0,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: showShadow ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ] : null,
      ),
      child: Stack(
        children: [
          // الشخصية الأساسية
          Center(
            child: Image.asset(
              _getCharacterImage(),
              width: size * 0.8,
              height: size * 0.8,
              fit: BoxFit.contain,
            ),
          ),

          // تأثير الدرع
          if (character.hasShield) _buildShieldEffect(),

          // تأثير الحركة
          if (character.isJumping) _buildJumpEffect(),
          if (character.isDucking) _buildDuckEffect(),

          // مؤقت الدرع
          if (character.hasShield && character.remainingShieldTime != null)
            _buildShieldTimer(),
        ],
      ),
    );
  }

  String _getCharacterImage() {
    if (character.isDucking) {
      return ImageService.characterDuck;
    } else if (character.isJumping) {
      return ImageService.characterJump;
    } else {
      return ImageService.characterRun;
    }
  }

  Widget _buildShieldEffect() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.blue,
          width: 3.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildJumpEffect() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.yellow.withOpacity(0.5),
              Colors.transparent,
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
      ),
    );
  }

  Widget _buildDuckEffect() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.3),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  Widget _buildShieldTimer() {
    final remainingTime = character.remainingShieldTime;
    if (remainingTime == null) return const SizedBox.shrink();

    return Positioned(
      top: -20,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${remainingTime.inSeconds}s',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ويدجت للشخصية مع animations
class AnimatedCharacterWidget extends StatefulWidget {
  final Character character;
  final double size;

  const AnimatedCharacterWidget({
    super.key,
    required this.character,
    this.size = 80.0,
  });

  @override
  State<AnimatedCharacterWidget> createState() => _AnimatedCharacterWidgetState();
}

class _AnimatedCharacterWidgetState extends State<AnimatedCharacterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: CharacterWidget(
            character: widget.character,
            size: widget.size,
          ),
        );
      },
    );
  }
}