import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/splash/splash_screen.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _black  = Color(0xFF000000);
  static const _white  = Color(0xFFFFFFFF);
  static const _accent = Color(0xFF276EF1);
  static const _surface = Color(0xFFF6F6F6);
  static const _textSecondary = Color(0xFF757575);

  final _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      icon: Icons.handshake_outlined,
      titulo: 'Bem-vindo ao ConectaPro',
      subtitulo:
          'A plataforma que conecta você aos melhores profissionais autônomos da sua região, de forma rápida e segura.',
      cor: Color(0xFF276EF1),
    ),
    _OnboardingData(
      icon: Icons.search_outlined,
      titulo: 'Encontre o profissional ideal',
      subtitulo:
          'Descreva o serviço que você precisa e receba propostas de profissionais qualificados em minutos.',
      cor: Color(0xFF34C759),
    ),
    _OnboardingData(
      icon: Icons.verified_outlined,
      titulo: 'Contrate com segurança',
      subtitulo:
          'Pagamentos protegidos, avaliações reais e suporte em cada etapa. Sua tranquilidade é nossa prioridade.',
      cor: Color(0xFFFF9500),
    ),
  ];

  Future<void> _finalizarOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_concluido', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => SplashScreen()),
    );
  }

  void _proximaPagina() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finalizarOnboarding();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          children: [

            // PULAR
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finalizarOnboarding,
                child: const Text(
                  'Pular',
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ),
            ),

            // PÁGINAS
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _OnboardingSlide(data: _pages[i]),
              ),
            ),

            // INDICADORES
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? page.cor : const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // BOTÃO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _proximaPagina,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _black,
                    foregroundColor: _white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLast ? 'Começar agora' : 'Próximo',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Slide individual ────────────────────────────────────────────────────────

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingSlide({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // ÍCONE
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: data.cor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 80,
              color: data.cor,
            ),
          ),

          const SizedBox(height: 48),

          // TÍTULO
          Text(
            data.titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF000000),
              height: 1.3,
            ),
          ),

          const SizedBox(height: 16),

          // SUBTÍTULO
          Text(
            data.subtitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Modelo de dados ─────────────────────────────────────────────────────────

class _OnboardingData {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final Color cor;

  const _OnboardingData({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.cor,
  });
}
