import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../main.dart';
import 'termos_de_uso_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {

  static const _bgTop         = Color(0xFF050914);
  static const _bgBottom      = Color(0xFF0A1226);
  static const _cardBg        = Color(0xFF0D1730);
  static const _fieldBg       = Color(0xFF0F1B38);
  static const _white         = Color(0xFFFFFFFF);
  static const _accent        = Color(0xFF2F6FED);
  static const _accentLight   = Color(0xFF4FA1FF);
  static const _textSecondary = Color(0xFF8892B0);
  static const _borderGlow    = Color(0xFF2F6FED);
  static const _red           = Color(0xFFFF3B30);

  final _nomeCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _senhaCtrl    = TextEditingController();
  final _telefoneCtrl = TextEditingController();

  bool   _loading        = false;
  bool   _obscureSenha   = true;
  bool   _aceitouTermos  = false;
  String _role           = 'cliente';

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _telefoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvarFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users').doc(uid)
            .update({'fcmToken': token});
      }
    } catch (_) {}
  }

  Future<void> _criarConta() async {
    if (_nomeCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _senhaCtrl.text.trim().isEmpty) {
      _snack('Preencha todos os campos obrigatórios');
      return;
    }
    if (_senhaCtrl.text.trim().length < 6) {
      _snack('A senha deve ter pelo menos 6 caracteres');
      return;
    }
    if (!_aceitouTermos) {
      _snack('Aceite os Termos de Uso para continuar');
      return;
    }

    setState(() => _loading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _senhaCtrl.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'nome':      _nomeCtrl.text.trim(),
        'email':     _emailCtrl.text.trim(),
        'telefone':  _telefoneCtrl.text.trim(),
        'role':      _role,
        'balance':   0.0,
        'blocked':   false,
        'fotoUrl':   '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _salvarFcmToken(credential.user!.uid);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthCheck()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Erro ao criar conta';
      if (e.code == 'email-already-in-use') msg = 'Este email já está em uso';
      else if (e.code == 'weak-password')   msg = 'Senha muito fraca';
      else if (e.code == 'invalid-email')   msg = 'Email inválido';
      _snack(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration _inputDec(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF64708F), fontSize: 14),
      prefixIcon: Icon(icon, color: _accentLight, size: 20),
      filled: true,
      fillColor: _fieldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF243259)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF243259)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgTop,
      body: Stack(
        children: [
          // FUNDO CONSTELAÇÃO
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bgTop, _bgBottom],
                ),
              ),
              child: CustomPaint(
                painter: _ConstelacaoPainter(),
                size: Size.infinite,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // APPBAR
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: _white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text('Criar conta',
                          style: TextStyle(
                              color: _white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),

                // CONTEÚDO
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: _cardBg.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: _borderGlow.withOpacity(0.35),
                                width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: _accent.withOpacity(0.10),
                                blurRadius: 24,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // NOME
                              TextField(
                                controller: _nomeCtrl,
                                style: const TextStyle(color: _white),
                                decoration: _inputDec(
                                    'Nome completo', Icons.person_outline),
                              ),
                              const SizedBox(height: 14),

                              // EMAIL
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: _white),
                                decoration:
                                    _inputDec('Email', Icons.email_outlined),
                              ),
                              const SizedBox(height: 14),

                              // SENHA
                              TextField(
                                controller: _senhaCtrl,
                                obscureText: _obscureSenha,
                                style: const TextStyle(color: _white),
                                decoration:
                                    _inputDec('Senha', Icons.lock_outline)
                                        .copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureSenha
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscureSenha = !_obscureSenha),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // TELEFONE
                              TextField(
                                controller: _telefoneCtrl,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(color: _white),
                                decoration: _inputDec(
                                    'Telefone / WhatsApp',
                                    Icons.phone_outlined),
                              ),
                              const SizedBox(height: 14),

                              // TIPO DE USUÁRIO
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _fieldBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0xFF243259)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _role,
                                    dropdownColor: _cardBg,
                                    style: const TextStyle(
                                        color: _white, fontSize: 14),
                                    icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: _accentLight),
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'cliente',
                                        child: Row(children: [
                                          Icon(Icons.person_outline,
                                              color: Color(0xFF4FA1FF),
                                              size: 20),
                                          SizedBox(width: 10),
                                          Text('Cliente'),
                                        ]),
                                      ),
                                      DropdownMenuItem(
                                        value: 'profissional',
                                        child: Row(children: [
                                          Icon(Icons.build_outlined,
                                              color: Color(0xFF4FA1FF),
                                              size: 20),
                                          SizedBox(width: 10),
                                          Text('Profissional'),
                                        ]),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _role = v!),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // TERMOS
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: Checkbox(
                                      value: _aceitouTermos,
                                      onChanged: (v) => setState(
                                          () => _aceitouTermos = v ?? false),
                                      activeColor: _accent,
                                      checkColor: _white,
                                      side: const BorderSide(
                                          color: Color(0xFF3A4B7A)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Wrap(
                                      children: [
                                        const Text('Li e aceito os ',
                                            style: TextStyle(
                                                color: _textSecondary,
                                                fontSize: 13)),
                                        GestureDetector(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const TermosDeUsoPage()),
                                          ),
                                          child: const Text('Termos de Uso',
                                              style: TextStyle(
                                                  color: _accentLight,
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // BOTÃO CRIAR CONTA
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [_accent, _accentLight],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _accent.withOpacity(0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _criarConta,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                      elevation: 0,
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                                color: _white,
                                                strokeWidth: 2))
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text('Criar conta',
                                                  style: TextStyle(
                                                      color: _white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: 0.5)),
                                              SizedBox(width: 8),
                                              Icon(
                                                  Icons
                                                      .arrow_forward_rounded,
                                                  color: _white,
                                                  size: 18),
                                            ],
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // JÁ TEM CONTA
                              Center(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Já tem conta? Entrar',
                                    style: TextStyle(
                                        color: _accentLight,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

class _ConstelacaoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final pontos = List.generate(55, (_) => Offset(
      random.nextDouble() * size.width,
      random.nextDouble() * size.height,
    ));

    final paintPonto = Paint()
      ..color = const Color(0xFF2F6FED).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final paintLinha = Paint()
      ..color = const Color(0xFF2F6FED).withOpacity(0.10)
      ..strokeWidth = 1;

    for (int i = 0; i < pontos.length; i++) {
      for (int j = i + 1; j < pontos.length; j++) {
        final dist = (pontos[i] - pontos[j]).distance;
        if (dist < 110) {
          canvas.drawLine(pontos[i], pontos[j], paintLinha);
        }
      }
    }

    for (final p in pontos) {
      canvas.drawCircle(p, random.nextDouble() * 1.6 + 0.6, paintPonto);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
