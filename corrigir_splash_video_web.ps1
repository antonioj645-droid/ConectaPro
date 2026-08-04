# corrigir_splash_video_web.ps1
# Rode a partir da RAIZ do projeto Flutter (onde está o pubspec.yaml)

$caminho = "lib\screens\splash\splash_screen.dart"

if (-not (Test-Path $caminho)) {
    Write-Host "ERRO: não encontrei $caminho a partir da pasta atual." -ForegroundColor Red
    exit 1
}

Copy-Item $caminho "lib\screens\splash\splash_screen_antes_fix_video_web.dart" -Force
Write-Host "Backup salvo em: lib\screens\splash\splash_screen_antes_fix_video_web.dart" -ForegroundColor Cyan

@'
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

  // video_player funciona em Android, iOS e Web.
  // Só o Windows desktop (app nativo, fora do navegador) não tem suporte.
  bool get _usarVideo =>
      kIsWeb || defaultTargetPlatform != TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    if (_usarVideo) {
      // Timer de segurança — navega após 8 segundos no máximo
      Timer(const Duration(seconds: 8), _navegar);
      _controller = VideoPlayerController.asset(
        'assets/videos/splash_animation.mp4',
      )..initialize().then((_) {
          if (!mounted) return;
          setState(() {});
          _controller!.play();
          _controller!.addListener(_verificarFim);
        });
    } else {
      // Windows desktop nativo: mostra imagem estática por 4 segundos e navega
      Timer(const Duration(seconds: 4), _navegar);
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
    if (!_usarVideo) {
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
'@ | Set-Content -Path $caminho -Encoding UTF8

Write-Host "Splash corrigida: video no Android/iOS/navegador, imagem so no Windows desktop." -ForegroundColor Green
Write-Host "Rodando flutter clean e flutter pub get..." -ForegroundColor Cyan

flutter clean
flutter pub get

Write-Host "Pronto! Teste com: flutter run -d chrome" -ForegroundColor Green
