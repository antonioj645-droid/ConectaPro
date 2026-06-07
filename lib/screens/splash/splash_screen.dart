import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../main.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _fadeController;
  late AnimationController _zoomController;
  late AnimationController _particleController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();

    // ✅ FADE
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();

    // ✅ ZOOM
    _zoomController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 6),
    );

    _zoomAnimation = Tween<double>(begin: 1, end: 1.05).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeInOut),
    );

    _zoomController.repeat(reverse: true);

    // ✅ PARTÍCULAS
    _particleController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    )..repeat();

    // ✅ TRANSIÇÃO FINAL
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 800),
          pageBuilder: (context, a1, a2) => const AuthCheck(),
          transitionsBuilder: (context, animation, a2, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _zoomController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [

                    /// ✅ IMAGEM + ZOOM
                    AnimatedBuilder(
                      animation: _zoomAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _zoomAnimation.value,
                          child: child,
                        );
                      },
                      child: Image.asset(
                        "assets/images/splash.png",
                        fit: BoxFit.cover,
                      ),
                    ),

                    /// ✅ PARTÍCULAS
                    Positioned.fill(
                      child: CustomPaint(
                        painter: ParticlePainter(_particleController),
                      ),
                    ),

                    /// ✅ LUZ CENTRAL (CINEMA)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.8,
                            colors: [
                              Colors.blue.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    /// ✅ ESCURECIMENTO SUAVE
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.25),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final Animation<double> animation;
  final Random random = Random();

  ParticlePainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3);

    for (int i = 0; i < 40; i++) {
      double x = random.nextDouble() * size.width;
      double y = (random.nextDouble() * size.height +
              animation.value * 100) %
          size.height;

      canvas.drawCircle(Offset(x, y), 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}