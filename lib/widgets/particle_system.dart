import 'package:flutter/material.dart';
import 'dart:math';

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  double maxLife;
  Color color;
  double size;
  
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.maxLife,
    required this.color,
    required this.size,
  });
  
  void update() {
    x += vx;
    y += vy;
    life -= 0.02;
    
    // Apply gravity
    vy += 0.1;
  }
  
  bool get isDead => life <= 0;
  
  double get opacity => (life / maxLife).clamp(0.0, 1.0);
}

class ParticleSystem extends StatefulWidget {
  final double width;
  final double height;
  final bool isActive;
  final Color particleColor;
  final int particleCount;
  
  const ParticleSystem({
    super.key,
    required this.width,
    required this.height,
    this.isActive = true,
    this.particleColor = Colors.yellow,
    this.particleCount = 50,
  });

  @override
  State<ParticleSystem> createState() => _ParticleSystemState();
}

class _ParticleSystemState extends State<ParticleSystem>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  List<Particle> particles = [];
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    if (widget.isActive) {
      _animationController.repeat();
      _initializeParticles();
    }
    
    _animationController.addListener(_updateParticles);
  }

  @override
  void didUpdateWidget(ParticleSystem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _animationController.repeat();
        _initializeParticles();
      } else {
        _animationController.stop();
        particles.clear();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeParticles() {
    particles.clear();
    for (int i = 0; i < widget.particleCount; i++) {
      _addParticle();
    }
  }

  void _addParticle() {
    particles.add(Particle(
      x: random.nextDouble() * widget.width,
      y: widget.height + 10,
      vx: (random.nextDouble() - 0.5) * 2,
      vy: -random.nextDouble() * 3 - 1,
      life: 1.0,
      maxLife: 1.0,
      color: widget.particleColor,
      size: random.nextDouble() * 4 + 2,
    ));
  }

  void _updateParticles() {
    if (!widget.isActive) return;
    
    setState(() {
      // Update existing particles
      for (var particle in particles) {
        particle.update();
      }
      
      // Remove dead particles
      particles.removeWhere((particle) => particle.isDead);
      
      // Add new particles to maintain count
      while (particles.length < widget.particleCount) {
        _addParticle();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(widget.width, widget.height),
      painter: ParticlePainter(particles),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  
  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Explosion effect for power-ups and achievements
class ExplosionEffect extends StatefulWidget {
  final Offset position;
  final Color color;
  final VoidCallback? onComplete;
  
  const ExplosionEffect({
    super.key,
    required this.position,
    this.color = Colors.yellow,
    this.onComplete,
  });

  @override
  State<ExplosionEffect> createState() => _ExplosionEffectState();
}

class _ExplosionEffectState extends State<ExplosionEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  List<Particle> explosionParticles = [];
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _createExplosion();
    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
    
    _controller.addListener(() {
      setState(() {
        _updateExplosion();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createExplosion() {
    explosionParticles.clear();
    
    for (int i = 0; i < 20; i++) {
      double angle = (i / 20) * 2 * pi;
      double speed = random.nextDouble() * 3 + 2;
      
      explosionParticles.add(Particle(
        x: widget.position.dx,
        y: widget.position.dy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        life: 1.0,
        maxLife: 1.0,
        color: widget.color,
        size: random.nextDouble() * 6 + 3,
      ));
    }
  }

  void _updateExplosion() {
    for (var particle in explosionParticles) {
      particle.x += particle.vx;
      particle.y += particle.vy;
      particle.life = 1.0 - _animation.value;
      
      // Slow down particles over time
      particle.vx *= 0.98;
      particle.vy *= 0.98;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ParticlePainter(explosionParticles),
      child: Container(),
    );
  }
}