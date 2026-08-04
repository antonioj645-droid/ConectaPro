import 'dart:async';
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
  bool _erroVideo = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 8), _navegar);
    _controller = VideoPlayerController.asset(
      'assets/videos/splash_animation.mp4',
    )..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller!.setVolume(0);
        _controller!.play();
        _controller!.addListener(_verificarFim);
      }).catchError((e) {
        if (!mounted) return;
        setState(() => _erroVideo = true);
        _navegar();
      });
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
    final videoPronto = _controller?.value.isInitialized == true && !_erroVideo;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1128),
      body: videoPronto
          ? Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          : const SizedBox.shrink(), // tela preta lisa enquanto o vídeo carrega, sem imagem
    );
  }
}