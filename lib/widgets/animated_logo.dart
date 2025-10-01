import 'package:flutter/material.dart';
import 'dart:math';

class AnimatedLogo extends StatefulWidget {
  final double size;
  final bool isWalking;
  
  const AnimatedLogo({
    super.key,
    this.size = 150,
    this.isWalking = false,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _walkController;
  late AnimationController _bounceController;
  late Animation<double> _walkAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    // Walking animation
    _walkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _walkAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _walkController,
      curve: Curves.linear,
    ));
    
    // Bounce animation
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    if (widget.isWalking) {
      _walkController.repeat();
    }
    
    _bounceController.forward();
  }

  @override
  void didUpdateWidget(AnimatedLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isWalking != oldWidget.isWalking) {
      if (widget.isWalking) {
        _walkController.repeat();
      } else {
        _walkController.stop();
      }
    }
  }

  @override
  void dispose() {
    _walkController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_walkAnimation, _bounceAnimation]),
      builder: (context, child) {
        double walkOffset = widget.isWalking ? sin(_walkAnimation.value) * 5 : 0;
        double scale = 0.8 + (_bounceAnimation.value * 0.2);
        
        return Transform.scale(
          scale: scale,
          child: Transform.translate(
            offset: Offset(0, walkOffset),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFFD700),
                    Color(0xFFFFA500),
                  ],
                ),
                borderRadius: BorderRadius.circular(widget.size / 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Walking person icon
                  Icon(
                    Icons.directions_walk,
                    size: widget.size * 0.6,
                    color: Colors.black87,
                  ),
                  
                  // Arabic text overlay
                  Positioned(
                    bottom: widget.size * 0.1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'عالماشي',
                        style: TextStyle(
                          fontSize: widget.size * 0.12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}