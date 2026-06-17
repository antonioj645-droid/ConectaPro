import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  static const _black         = Color(0xFF000000);
  static const _white         = Color(0xFFFFFFFF);
  static const _accent        = Color(0xFF276EF1);
  static const _surface       = Color(0xFFF6F6F6);
  static const _textSecondary = Color(0xFF757575);
  static const _green         = Color(0xFF34C759);

  final _nomeCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _senhaCtrl    = TextEditingController();
  final _telefoneCtrl = TextEditingController();

  String _tipoUsuario    = 'cliente';
  bool   _loading        = false;
  bool   _obscureSenha   = true;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _telefoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_nomeCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _senhaCtrl.text.isEmpty ||
        _telefoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    try {
      setState(() => _loading = true);

      final credencial = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _senhaCtrl.text.trim(),
      );

      final uid = credencial.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'nome':      _nomeCtrl.text.trim(),
        'email':     _emailCtrl.text.trim(),
        'phone':     _telefoneCtrl.text.trim(),
        'role':      _tipoUsuario,
        'balance':   0.0,
        'blocked':   false,
        'criadoEm':  FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta criada com sucesso ✅'),
          backgroundColor: _green,
        ),
      );

    } on FirebaseAuthException catch (e) {
      String mensagem;
      switch (e.code) {
        case 'email-already-in-use':
          mensagem = 'Este email já está em uso';
          break;
        case 'invalid-email':
          mensagem = 'Email inválido';
          break;
        case 'weak-password':
          mensagem = 'Senha fraca (mínimo 6 caracteres)';
          break;
        default:
          mensagem = e.message ?? 'Erro ao criar conta';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _textSecondary),
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
        borderSide: const BorderSide(color: _accent, width: 2),
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
          'Criar conta',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [

              // NOME
              TextField(
                controller: _nomeCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('Nome completo', Icons.person_outline),
              ),

              const SizedBox(height: 14),

              // EMAIL
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Email', Icons.email_outlined),
              ),

              const SizedBox(height: 14),

              // SENHA
              TextField(
                controller: _senhaCtrl,
                obscureText: _obscureSenha,
                decoration: _inputDecoration('Senha', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureSenha
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscureSenha = !_obscureSenha),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // TELEFONE
              TextField(
                controller: _telefoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Telefone / WhatsApp', Icons.phone_outlined),
              ),

              const SizedBox(height: 14),

              // TIPO DE USUÁRIO
              DropdownButtonFormField<String>(
                value: _tipoUsuario,
                decoration: _inputDecoration('Tipo de usuário', Icons.badge_outlined),
                items: const [
                  DropdownMenuItem(
                    value: 'cliente',
                    child: Text('Cliente'),
                  ),
                  DropdownMenuItem(
                    value: 'profissional',
                    child: Text('Profissional'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _tipoUsuario = value!),
              ),

              const SizedBox(height: 32),

              // BOTÃO CRIAR CONTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _registrar,
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
                          'Criar conta',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // JÁ TEM CONTA
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Já tem conta?',
                      style: TextStyle(color: _textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Entrar',
                      style: TextStyle(
                          color: _black, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}