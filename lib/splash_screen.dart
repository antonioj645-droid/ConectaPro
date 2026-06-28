import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'login_page.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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
      _registrarVideoWeb();
      Timer(const Duration(seconds: 5), _navegar);
    } else {
      _controller = VideoPlayerController.asset(
        'assets/videos/splash_animation.mp4',
      )..initialize().then((_) {
          setState(() {});
          _controller!.play();
        });

      _controller!.addListener(() {
        if (!_navegou &&
            _controller!.value.isInitialized &&
            _controller!.value.position >= _controller!.value.duration &&
            _controller!.value.duration > Duration.zero) {
          _navegou = true;
          _navegar();
        }
      });
    }
  }

  void _registrarVideoWeb() {
    final videoElement = html.VideoElement()
      ..src = 'assets/videos/splash_animation.mp4'
      ..autoplay = true
      ..muted = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'contain'
      ..style.backgroundColor = 'black';

    videoElement.onEnded.listen((_) => _navegar());

    ui_web.platformViewRegistry.registerViewFactory(
      'splash-video',
      (int viewId) => videoElement,
    );
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
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: kIsWeb
          ? const HtmlElementView(viewType: 'splash-video')
          : Center(
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