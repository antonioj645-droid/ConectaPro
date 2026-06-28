import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {

  static const _black         = Color(0xFF000000);
  static const _white         = Color(0xFFFFFFFF);
  static const _accent        = Color(0xFF276EF1);
  static const _textSecondary = Color(0xFF757575);

  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  bool _loading         = false;
  bool _loadingGoogle   = false;
  bool _obscurePassword = true;

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Recuperar senha',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Digite seu email',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _black,
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

  InputDecoration _inputDec(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
      prefixIcon: Icon(icon, color: _textSecondary),
      filled: true,
      fillColor: _white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _campoComSombra({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _googleIcon() {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F4FF), Color(0xFFF6F6F6)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      // LOGO
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(39, 110, 241, 0.25),
                              blurRadius: 30,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 120,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // TAGLINE
                      const Text(
                        'Conectando clientes aos\nmelhores profissionais.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // CAMPO EMAIL
                      _campoComSombra(
                        child: TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDec(
                            'Email', 'Digite seu email', Icons.email_outlined),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // CAMPO SENHA
                      _campoComSombra(
                        child: TextField(
                          controller: _senhaCtrl,
                          obscureText: _obscurePassword,
                          decoration: _inputDec(
                            'Senha', 'Digite sua senha', Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _textSecondary,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ESQUECI SENHA
                      Center(
                        child: TextButton(
                          onPressed: _esqueciSenha,
                          child: const Text(
                            'Esqueci minha senha',
                            style: TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // BOTÃO ENTRAR
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(0, 0, 0, 0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _entrar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _black,
                              foregroundColor: _white,
                              disabledBackgroundColor: Colors.grey.shade400,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: _white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Entrar',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // DIVISOR OU
                      Row(
                        children: [
                          const Expanded(
                              child: Divider(color: Color(0xFFDDDDDD))),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('ou',
                                style: TextStyle(
                                    color: _textSecondary, fontSize: 13)),
                          ),
                          const Expanded(
                              child: Divider(color: Color(0xFFDDDDDD))),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // BOTÃO GOOGLE
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: _loadingGoogle ? null : _entrarComGoogle,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFDDDDDD)),
                            backgroundColor: _white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _loadingGoogle
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _googleIcon(),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Entrar com Google',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF333333)),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // CRIAR CONTA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Não tem conta?',
                              style: TextStyle(
                                  color: _textSecondary, fontSize: 14)),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterPage()),
                            ),
                            child: const Text(
                              'Criar conta',
                              style: TextStyle(
                                  color: _black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
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
      ),
    );
  }
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

    // Fundo branco circular
    canvas.drawCircle(Offset(cx, cy), r, paintWht);

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.85);

    // Vermelho: topo-esquerda
    canvas.drawArc(rect, -2.6, 1.6, true, paintRed);
    // Amarelo: baixo-esquerda
    canvas.drawArc(rect, 2.2, 1.1, true, paintYel);
    // Verde: baixo-direita
    canvas.drawArc(rect, 3.3, 1.2, true, paintGrn);
    // Azul: direita e topo-direita
    canvas.drawArc(rect, 4.5, 2.3, true, paintBlue);

    // Buraco central branco
    canvas.drawCircle(Offset(cx, cy), r * 0.55, paintWht);

    // Faixa horizontal azul do "G"
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