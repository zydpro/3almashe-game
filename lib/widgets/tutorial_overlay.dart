import 'package:flutter/material.dart';

class TutorialOverlay extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onTap;

  const TutorialOverlay({
    super.key,
    required this.isVisible,
    this.onTap,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(TutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.forward();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && _controller.isDismissed) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTutorialCard(
                icon: Icons.arrow_upward,
                title: 'اسحب للأعلى للقفز',
                description: 'تخطي العقبات الأرضية والفراغات',
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              _buildTutorialCard(
                icon: Icons.arrow_downward,
                title: 'اسحب لأسفل للانحناء',
                description: 'تجنب العقبات السماوية المرتفعة',
                color: Colors.blue,
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ستختفي هذه التعليمات بعد 5 ثواني',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}