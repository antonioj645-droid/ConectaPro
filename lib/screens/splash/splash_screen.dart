import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../pages/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  bool _navegou = false;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      Timer(const Duration(seconds: 4), _navegar);
    } else {
      // Timer de segurança — navega após 8 segundos no máximo
      Timer(const Duration(seconds: 8), _navegar);

      _controller = VideoPlayerController.asset(
        'assets/videos/splash_animation.mp4',
      )..initialize().then((_) {
          setState(() {});
          _controller!.play();
          _controller!.addListener(_verificarFim);
        });
    }
  }

  void _verificarFim() {
    if (!_navegou &&
        _controller!.value.isInitialized &&
        !_controller!.value.isPlaying &&
        _controller!.value.position >= _controller!.value.duration &&
        _controller!.value.duration > Duration.zero) {
      _navegar();
    }
  }

  void _navegar() {
    if (_navegou) return;
    _navegou = true;
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_verificarFim);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        body: Image.asset(
          'assets/images/splash.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller?.value.isInitialized == true
            ? AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}