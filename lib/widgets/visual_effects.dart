import 'package:flutter/material.dart';
import 'dart:math';

class ParticleEffect extends StatefulWidget {
  final int particleCount;
  final Color particleColor;
  final Duration duration;

  const ParticleEffect({
    super.key,
    this.particleCount = 20,
    this.particleColor = Colors.yellow,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<ParticleEffect> createState() => _ParticleEffectState();
}

class _ParticleEffectState extends State<ParticleEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeParticles();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        setState(() {
          _updateParticles();
        });
      });

    _controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _particles.clear();
        });
      }
    });
  }

  void _initializeParticles() {
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(Particle(
        x: 0.5,
        y: 0.5,
        vx: (_random.nextDouble() - 0.5) * 0.02,
        vy: (_random.nextDouble() - 0.5) * 0.02 - 0.01,
        life: 1.0,
        size: _random.nextDouble() * 4 + 2,
      ));
    }
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.x += particle.vx;
      particle.y += particle.vy;
      particle.life = 1.0 - _animation.value;
      particle.vy += 0.0005; // جاذبية
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ParticlePainter(_particles, widget.particleColor),
      size: Size.infinite,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Particle {
  double x, y, vx, vy, life, size;
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.size,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color particleColor;

  ParticlePainter(this.particles, this.particleColor);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particleColor.withOpacity(particle.life)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// تأثير عند جمع العملات
class CoinCollectionEffect extends StatelessWidget {
  final int coinCount;

  const CoinCollectionEffect({super.key, required this.coinCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ParticleEffect(
          particleCount: coinCount * 2,
          particleColor: Colors.yellow,
        ),
        Positioned(
          top: 100,
          right: 20,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+$coinCount 🪙',
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}