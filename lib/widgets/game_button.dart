import 'package:flutter/material.dart';

class GameButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isEnabled;
  final double width;
  final double height;
  
  const GameButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isEnabled = true,
    this.width = double.infinity,
    this.height = 60,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isEnabled) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
      widget.onPressed();
    }
  }

  void _onTapCancel() {
    if (widget.isEnabled) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: widget.isEnabled
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.color,
                          widget.color.withOpacity(0.8),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey.shade400,
                          Colors.grey.shade600,
                        ],
                      ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: widget.isEnabled
                    ? [
                        BoxShadow(
                          color: widget.color.withOpacity(0.3),
                          blurRadius: _isPressed ? 5 : 10,
                          offset: Offset(0, _isPressed ? 2 : 5),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: _isPressed ? 3 : 8,
                          offset: Offset(0, _isPressed ? 1 : 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        size: 28,
                        color: widget.isEnabled ? Colors.white : Colors.grey.shade300,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.text,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.isEnabled ? Colors.white : Colors.grey.shade300,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}