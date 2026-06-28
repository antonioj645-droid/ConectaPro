import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ExcluirContaPage extends StatefulWidget {
  const ExcluirContaPage({super.key});

  @override
  State<ExcluirContaPage> createState() => _ExcluirContaPageState();
}

class _ExcluirContaPageState extends State<ExcluirContaPage> {
  static const _black         = Color(0xFF000000);
  static const _white         = Color(0xFFFFFFFF);
  static const _surface       = Color(0xFFF6F6F6);
  static const _textSecondary = Color(0xFF757575);
  static const _red           = Color(0xFFFF3B30);

  final _senhaCtrl = TextEditingController();
  bool _loading   = false;
  bool _obscure   = true;
  bool _confirmou = false;

  // Detecta se o usuário entrou com Google ou e-mail
  bool get _isGoogleUser {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  @override
  void dispose() {
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _excluirConta() async {
    if (!_isGoogleUser && _senhaCtrl.text.isEmpty) {
      _snack('Digite sua senha para confirmar');
      return;
    }

    if (!_confirmou) {
      _snack('Marque a caixa de confirmação para continuar');
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // ── Reautenticação ──────────────────────────────────────────────────────
      if (_isGoogleUser) {
        // Usuário Google: pede consentimento novamente
        final googleSignIn = GoogleSignIn(scopes: ['email']);
        await googleSignIn.signOut(); // força seleção de conta
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          _snack('Autenticação cancelada');
          setState(() => _loading = false);
          return;
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        // Usuário e-mail/senha
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _senhaCtrl.text.trim(),
        );
        await user.reauthenticateWithCredential(credential);
      }
      // ────────────────────────────────────────────────────────────────────────

      // Deletar dados do Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // Deletar conta do Firebase Auth
      await user.delete();

      if (!mounted) return;

      // Volta para raiz (login)
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta excluída com sucesso')),
      );

    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'Senha incorreta. Tente novamente.';
          break;
        case 'too-many-requests':
          msg = 'Muitas tentativas. Tente mais tarde.';
          break;
        case 'user-mismatch':
          msg = 'A conta Google selecionada não corresponde à sua conta.';
          break;
        default:
          msg = e.message ?? 'Erro ao excluir conta';
      }
      _snack(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _mostrarConfirmacaoFinal() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF3B30)),
            SizedBox(width: 8),
            Text(
              'Confirmar exclusão',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'Esta ação é permanente e irreversível. Todos os seus dados serão apagados.\n\nDeseja continuar?',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF757575))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _excluirConta();
            },
            child: const Text('Sim, excluir minha conta'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _black,
        foregroundColor: _white,
        elevation: 0,
        title: const Text(
          'Excluir conta',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // AVISO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _red.withOpacity(0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: _red, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Atenção: esta ação é permanente e não pode ser desfeita. '
                      'Ao excluir sua conta, todos os seus dados serão removidos permanentemente.',
                      style: TextStyle(fontSize: 13, height: 1.5, color: _red),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // O QUE SERÁ EXCLUÍDO
            const Text(
              'O que será excluído:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _black,
              ),
            ),
            const SizedBox(height: 12),
            ...[
              'Seu perfil e informações pessoais',
              'Histórico de pedidos e serviços',
              'Avaliações e comentários',
              'Saldo disponível na plataforma',
              'Acesso ao aplicativo',
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: CircleAvatar(radius: 3, backgroundColor: _red),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item,
                      style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF333333)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // CAMPO SENHA — só mostra para usuários e-mail/senha
            if (!_isGoogleUser) ...[
              const Text(
                'Confirme sua senha:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _black,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _senhaCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Digite sua senha atual',
                  hintStyle: const TextStyle(color: _textSecondary),
                  prefixIcon: const Icon(Icons.lock_outline, color: _textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _textSecondary,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  filled: true,
                  fillColor: _white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _red, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // AVISO para usuários Google
            if (_isGoogleUser) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Você entrou com o Google. Será solicitado que confirme sua conta Google para concluir a exclusão.',
                        style: TextStyle(fontSize: 13, height: 1.5, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // CHECKBOX CONFIRMAÇÃO
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _confirmou,
                  activeColor: _red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  onChanged: (v) => setState(() => _confirmou = v!),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Entendo que esta ação é irreversível e concordo com a exclusão permanente da minha conta e de todos os meus dados.',
                      style: TextStyle(
                          fontSize: 13, height: 1.5, color: _textSecondary),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // BOTÃO EXCLUIR
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _mostrarConfirmacaoFinal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
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
                        'Excluir minha conta',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // CANCELAR
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _black,
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
