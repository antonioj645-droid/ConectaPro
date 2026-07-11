import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {

  // ─── Tema (visual QP Qonex — fundo escuro, neon azul) ───────────────────────
  static const _bgTop         = Color(0xFF050914);
  static const _bgBottom      = Color(0xFF0A1226);
  static const _cardBg        = Color(0xFF0D1730);
  static const _fieldBg       = Color(0xFF0F1B38);
  static const _white         = Color(0xFFFFFFFF);
  static const _accent        = Color(0xFF2F6FED);
  static const _accentLight   = Color(0xFF4FA1FF);
  static const _textSecondary = Color(0xFF8892B0);
  static const _borderGlow    = Color(0xFF2F6FED);

  static const _chaveEmailSalvo = 'login_email_salvo';

  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  bool _loading         = false;
  bool _loadingGoogle   = false;
  bool _obscurePassword = true;
  bool _lembrarMe       = false;

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
    _carregarEmailSalvo();
  }

  Future<void> _carregarEmailSalvo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emailSalvo = prefs.getString(_chaveEmailSalvo);
      if (emailSalvo != null && emailSalvo.isNotEmpty) {
        setState(() {
          _emailCtrl.text = emailSalvo;
          _lembrarMe = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _atualizarEmailSalvo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lembrarMe) {
        await prefs.setString(_chaveEmailSalvo, _emailCtrl.text.trim());
      } else {
        await prefs.remove(_chaveEmailSalvo);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvarFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'fcmToken': token});
      }
    } catch (_) {}
  }

  Future<void> _entrar() async {
    if (_emailCtrl.text.isEmpty || _senhaCtrl.text.isEmpty) {
      _snack('Preencha email e senha');
      return;
    }
    setState(() => _loading = true);
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _senhaCtrl.text.trim(),
      );
      await _salvarFcmToken(credential.user!.uid);
      await _atualizarEmailSalvo();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthCheck()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Erro ao entrar';
      if (e.code == 'user-not-found')      msg = 'Usuário não encontrado';
      else if (e.code == 'wrong-password') msg = 'Senha incorreta';
      else if (e.code == 'invalid-email')  msg = 'Email inválido';
      _snack(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _entrarComGoogle() async {
    setState(() => _loadingGoogle = true);
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email']);
      await googleSignIn.signOut(); // garante seleção de conta sempre
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _loadingGoogle = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user!;

      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await ref.get();
      if (!doc.exists) {
        await ref.set({
          'nome':      user.displayName ?? '',
          'email':     user.email ?? '',
          'fotoUrl':   user.photoURL ?? '',
          'role':      'cliente',
          'createdAt': Timestamp.now(),
        });
      }
      await _salvarFcmToken(user.uid);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthCheck()),
        (route) => false,
      );
    } catch (e) {
      _snack('Erro ao entrar com Google: $e');
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _esqueciSenha() async {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Recuperar senha',
            style: TextStyle(fontWeight: FontWeight.w700, color: _white)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: _white),
          decoration: InputDecoration(
            labelText: 'Digite seu email',
            labelStyle: const TextStyle(color: _textSecondary),
            prefixIcon: const Icon(Icons.email_outlined, color: _accentLight),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF243259)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accent, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final email = ctrl.text.trim();
              if (email.isEmpty) return;
              try {
                FirebaseAuth.instance.setLanguageCode('pt-BR');
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: email);
                if (ctx.mounted) Navigator.pop(ctx);
                _snack('Email de recuperação enviado ✅');
              } catch (e) {
                _snack('Erro: $e');
              }
            },
            child: const Text('Enviar',
                style: TextStyle(color: _white)),
          ),
        ],
      ),
    );
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
          // Fundo com gradiente + estrelas/constelação
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        // LOGO com glow azul
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _accent.withOpacity(0.45),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Transform.scale(
                              scale: 1.35,
                              child: Image.asset(
                                'assets/images/logo_cp.jpeg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
const SizedBox(height: 20),

                        const Text(
                          'Conectando você aos profissionais certos.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 13.5,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // CARTÃO COM BORDA NEON
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: _cardBg.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: _borderGlow.withOpacity(0.35), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: _accent.withOpacity(0.10),
                                blurRadius: 24,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [

                              // CAMPO EMAIL
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: _white),
                                decoration:
                                    _inputDec('E-mail', Icons.person_outline),
                              ),

                              const SizedBox(height: 14),

                              // CAMPO SENHA
                              TextField(
                                controller: _senhaCtrl,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: _white),
                                decoration: _inputDec(
                                  'Senha', Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // LEMBRAR-ME + ESQUECI SENHA
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: Checkbox(
                                          value: _lembrarMe,
                                          onChanged: (v) => setState(
                                              () => _lembrarMe = v ?? false),
                                          activeColor: _accent,
                                          checkColor: _white,
                                          side: const BorderSide(
                                              color: Color(0xFF3A4B7A)),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4)),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text('Lembrar-me',
                                          style: TextStyle(
                                              color: _textSecondary,
                                              fontSize: 12.5)),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: _esqueciSenha,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Esqueceu sua senha?',
                                      style: TextStyle(
                                        color: _accentLight,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // BOTÃO ENTRAR (gradiente azul)
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
                                    onPressed: _loading ? null : _entrar,
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
                                                color: _white, strokeWidth: 2),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Entrar',
                                                style: TextStyle(
                                                    color: _white,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    letterSpacing: 0.5),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward_rounded,
                                                  color: _white, size: 18),
                                            ],
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // DIVISOR "ou"
                              Row(
                                children: [
                                  Expanded(
                                      child: Divider(
                                          color: _borderGlow.withOpacity(0.25))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text('ou',
                                        style: TextStyle(
                                            color: _textSecondary,
                                            fontSize: 12.5)),
                                  ),
                                  Expanded(
                                      child: Divider(
                                          color: _borderGlow.withOpacity(0.25))),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // BOTÃO GOOGLE
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton(
                                  onPressed:
                                      _loadingGoogle ? null : _entrarComGoogle,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: _borderGlow.withOpacity(0.3)),
                                    backgroundColor: _fieldBg,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  child: _loadingGoogle
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              color: _accentLight,
                                              strokeWidth: 2),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            _googleIcon(),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Continuar com Google',
                                              style: TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: _white),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // CRIAR CONTA
                        Column(
                          children: [
                            const Text('Ainda não tem uma conta?',
                                style: TextStyle(
                                    color: _textSecondary, fontSize: 13.5)),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RegisterPage()),
                              ),
                              child: const Text(
                                'Criar conta',
                                style: TextStyle(
                                    color: _accentLight,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _googleIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

// ── Fundo de "constelação" (pontos + linhas conectando) ──────────────────────
class _ConstelacaoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // seed fixa: mesmo padrão sempre, sem "piscar"
    final pontos = List.generate(55, (_) {
      return Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
    });

    final paintPonto = Paint()
      ..color = const Color(0xFF2F6FED).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final paintLinha = Paint()
      ..color = const Color(0xFF2F6FED).withOpacity(0.10)
      ..strokeWidth = 1;

    // Linhas entre pontos próximos (efeito de constelação)
    for (int i = 0; i < pontos.length; i++) {
      for (int j = i + 1; j < pontos.length; j++) {
        final dist = (pontos[i] - pontos[j]).distance;
        if (dist < 110) {
          canvas.drawLine(pontos[i], pontos[j], paintLinha);
        }
      }
    }

    // Pontos (estrelas)
    for (final p in pontos) {
      canvas.drawCircle(p, random.nextDouble() * 1.6 + 0.6, paintPonto);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Painter do "G" colorido do Google ────────────────────────────────────────
class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    final paintBlue = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;
    final paintRed  = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill;
    final paintYel  = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill;
    final paintGrn  = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill;
    final paintWht  = Paint()..color = const Color(0xFFFFFFFF)..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx, cy), r, paintWht);

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.85);

    canvas.drawArc(rect, -2.6, 1.6, true, paintRed);
    canvas.drawArc(rect, 2.2, 1.1, true, paintYel);
    canvas.drawArc(rect, 3.3, 1.2, true, paintGrn);
    canvas.drawArc(rect, 4.5, 2.3, true, paintBlue);

    canvas.drawCircle(Offset(cx, cy), r * 0.55, paintWht);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx, cy - r * 0.18, r * 0.85, r * 0.36),
        const Radius.circular(4),
      ),
      paintBlue,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}