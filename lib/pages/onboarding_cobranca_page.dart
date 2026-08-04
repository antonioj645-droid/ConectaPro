import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'area_cliente_page.dart';
import 'area_profissional_page.dart';

// Tela exibida uma única vez, logo após o primeiro login, explicando
// como funcionam os pedidos e as cobranças do app. O conteúdo muda
// conforme o papel do usuário (cliente ou profissional).
class OnboardingCobrancaPage extends StatefulWidget {
  final String role;

  const OnboardingCobrancaPage({super.key, required this.role});

  @override
  State<OnboardingCobrancaPage> createState() => _OnboardingCobrancaPageState();
}

class _OnboardingCobrancaPageState extends State<OnboardingCobrancaPage> {
  static const _black   = Color(0xFF000000);
  static const _white   = Color(0xFFFFFFFF);
  static const _accent  = Color(0xFF276EF1);
  static const _surface = Color(0xFFF6F6F6);

  final _controller = PageController();
  int _paginaAtual = 0;

  late final List<_OnboardingSlide> _slides =
      widget.role == 'profissional' ? _slidesProfissional : _slidesCliente;

  static const _slidesCliente = [
    _OnboardingSlide(
      icone: Icons.assignment_outlined,
      titulo: 'Peça um serviço',
      texto: 'Descreva o que você precisa e escolha a categoria. '
          'Profissionais da sua região vão receber o seu pedido.',
    ),
    _OnboardingSlide(
      icone: Icons.payments_outlined,
      titulo: 'Como funciona o pagamento',
      texto: 'Solicitar um serviço não tem custo nenhum. '
          'O pagamento é feito diretamente ao profissional, '
          'somente depois que o serviço for concluído.',
    ),
    _OnboardingSlide(
      icone: Icons.shield_outlined,
      titulo: 'Sua segurança em primeiro lugar',
      texto: 'Nunca faça pagamentos antecipados. '
          'Combine tudo com o profissional pelo chat do app '
          'antes de confirmar o serviço.',
    ),
  ];

  static const _slidesProfissional = [
    _OnboardingSlide(
      icone: Icons.work_outline,
      titulo: 'Receba pedidos',
      texto: 'Você recebe pedidos de clientes de acordo com a sua '
          'categoria de atuação e a sua região.',
    ),
    _OnboardingSlide(
      icone: Icons.lock_open_outlined,
      titulo: 'Taxa de desbloqueio',
      texto: 'Para ver os dados completos do cliente e iniciar a '
          'conversa, é cobrada uma taxa única de R\$ 1,00 por pedido.',
    ),
    _OnboardingSlide(
      icone: Icons.percent_outlined,
      titulo: 'Comissão sobre o serviço',
      texto: 'Ao concluir um serviço, é descontada uma comissão de 7% '
          'sobre o valor combinado com o cliente. O restante fica '
          'disponível na sua carteira.',
    ),
  ];

  Future<void> _finalizar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'viuOnboarding': true});
      } catch (_) {
        // Se a gravação falhar, o usuário simplesmente verá esta tela
        // novamente no próximo login. Não é motivo para travar o fluxo.
      }
    }

    if (!mounted) return;

    final destino = widget.role == 'profissional'
        ? AreaProfissionalPage()
        : const AreaClientePage();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destino),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ultimaPagina = _paginaAtual == _slides.length - 1;

    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finalizar,
                child: const Text(
                  'Pular',
                  style: TextStyle(color: Color(0xFF757575)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _paginaAtual = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide.icone, size: 48, color: _accent),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.titulo,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.texto,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final ativo = i == _paginaAtual;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: ativo ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: ativo ? _accent : const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    if (ultimaPagina) {
                      _finalizar();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    ultimaPagina ? 'Entendi' : 'Próximo',
                    style: const TextStyle(
                      color: _white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icone;
  final String titulo;
  final String texto;

  const _OnboardingSlide({
    required this.icone,
    required this.titulo,
    required this.texto,
  });
}