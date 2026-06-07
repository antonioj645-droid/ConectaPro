import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_page.dart';
import 'novo_pedido_page.dart';
import 'meus_pedidos_page.dart';
import 'perfil_page.dart';
import 'map_page.dart'; // ✅ IMPORT DO MAPA

class AreaClientePage extends StatefulWidget {
  const AreaClientePage({super.key});

  @override
  State<AreaClientePage> createState() => _AreaClientePageState();
}

class _AreaClientePageState extends State<AreaClientePage> {

  String _nomeUsuario = '';
  String _role = '';
  bool _loadingNome = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _nomeUsuario = 'Usuário';
        _role = 'cliente';
        _loadingNome = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      final data = doc.data();

      setState(() {
        _nomeUsuario = (data?['nome'] ?? user.email ?? 'Usuário').toString();
        _role = (data?['role'] ?? 'cliente').toString();
        _loadingNome = false;
      });

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _nomeUsuario = user.email ?? 'Usuário';
        _role = 'cliente';
        _loadingNome = false;
      });
    }
  }

  Future<void> _sair() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _virarProfissional(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'role': 'profissional'});

    await user.reload();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  // ✅ ABRIR MAPA
  void _abrirMapa() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPage()),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Início'),

        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerfilPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _sair,
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ✅ BOAS-VINDAS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _loadingNome
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Olá, ${_nomeUsuario.split(' ').first} 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // 🔥 NOVO BOTÃO DO MAPA (DESTAQUE)
            ListTile(
              leading: const Icon(Icons.map, color: Colors.green),
              title: const Text('Ver profissionais no mapa'),
              subtitle: const Text('Encontre serviços próximos'),
              onTap: _abrirMapa,
            ),

            // ✅ NOVO PEDIDO
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Solicitar serviço'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NovoPedidoPage()),
              ),
            ),

            // ✅ MEUS PEDIDOS
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Meus pedidos'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MeusPedidosPage()),
              ),
            ),

            // ✅ PERFIL
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Meu perfil'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerfilPage()),
              ),
            ),

            const SizedBox(height: 20),

            if (_role != 'profissional')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _virarProfissional(context),
                  child: const Text('Quero ser profissional'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}