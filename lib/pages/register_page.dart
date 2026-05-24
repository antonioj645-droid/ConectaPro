import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();

  String _tipoUsuario = 'cliente';
  bool _loading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {

    // ✅ valida campos
    if (_nomeController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _senhaController.text.isEmpty ||
        _telefoneController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    try {
      setState(() => _loading = true);

      final credencial =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      final uid = credencial.user!.uid;

      // ✅ salva no Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'nome': _nomeController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _telefoneController.text.trim(),
        'role': _tipoUsuario,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // ✅ VOLTA PRO SISTEMA PRINCIPAL (AuthCheck decide)
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada com sucesso ✅')),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );

    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar conta'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: SingleChildScrollView(
          child: Column(

            children: [

              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone / WhatsApp',
                ),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _tipoUsuario,
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
                onChanged: (value) {
                  setState(() {
                    _tipoUsuario = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Tipo de usuário',
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 45,

                child: ElevatedButton(
                  onPressed: _loading ? null : _registrar,

                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Criar conta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}