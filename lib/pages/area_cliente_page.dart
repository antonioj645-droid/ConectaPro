import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_page.dart';
import 'novo_pedido_page.dart';
import 'meus_pedidos_page.dart';
import 'perfil_page.dart';
import 'map_page.dart';

class AreaClientePage extends StatefulWidget {
  const AreaClientePage({super.key});

  @override
  State<AreaClientePage> createState() => _AreaClientePageState();
}

class _AreaClientePageState extends State<AreaClientePage> {
  static const _black   = Color(0xFF000000);
  static const _white   = Color(0xFFFFFFFF);
  static const _accent  = Color(0xFF276EF1);
  static const _surface = Color(0xFFF6F6F6);
  static const _textSecondary = Color(0xFF757575);

  String _nomeUsuario = '';
  String _role        = '';
  bool   _loadingNome = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _nomeUsuario = 'Usuário'; _role = 'cliente'; _loadingNome = false; });
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (!mounted) return;
      setState(() {
        _nomeUsuario = (data?['nome'] ?? user.email ?? 'Usuário').toString();
        _role        = (data?['role'] ?? 'cliente').toString();
        _loadingNome = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nomeUsuario = FirebaseAuth.instance.currentUser?.email ?? 'Usuário';
        _role        = 'cliente';
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

  Future<void> _virarProfissional() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Virar profissional', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Você passará a ter acesso ao painel profissional. Deseja continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar', style: TextStyle(color: _white)),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'role': 'profissional'});

    await user.reload();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _black,
      foregroundColor: _white,
      elevation: 0,
      title: const Text('ConectaPro', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline),
          tooltip: 'Perfil',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilPage())),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sair',
          onPressed: _sair,
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final primeiroNome = _nomeUsuario.split(' ').first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        color: _black,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: _loadingNome
          ? const Center(child: CircularProgressIndicator(color: _white, strokeWidth: 2))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $primeiroNome 👋',
                  style: const TextStyle(color: _white, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'O que você precisa hoje?',
                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                ),
              ],
            ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        const _SectionLabel(label: 'Serviços'),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.add_circle_outline,
          iconColor: _accent,
          title: 'Solicitar serviço',
          subtitle: 'Crie um novo pedido e receba propostas',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NovoPedidoPage())),
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.receipt_long_outlined,
          iconColor: const Color(0xFF34C759),
          title: 'Meus pedidos',
          subtitle: 'Acompanhe seus pedidos em andamento',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeusPedidosPage())),
        ),
        const SizedBox(height: 24),
        const _SectionLabel(label: 'Explorar'),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.map_outlined,
          iconColor: const Color(0xFFFF9500),
          title: 'Profissionais no mapa',
          subtitle: 'Encontre profissionais próximos a você',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage())),
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.person_outline,
          iconColor: _textSecondary,
          title: 'Meu perfil',
          subtitle: 'Edite suas informações pessoais',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilPage())),
        ),
        if (_role != 'profissional') ...[
          const SizedBox(height: 32),
          _buildBannerProfissional(),
        ],
      ],
    );
  }

  Widget _buildBannerProfissional() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _black, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(39, 110, 241, 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.work_outline, color: _accent, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seja um profissional',
                    style: TextStyle(color: _white, fontWeight: FontWeight.w700, fontSize: 14)),
                SizedBox(height: 2),
                Text('Receba pedidos e ganhe dinheiro',
                    style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _virarProfissional,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(20)),
              child: const Text('Ativar',
                  style: TextStyle(color: _white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF757575),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Color.fromRGBO(iconColor.red, iconColor.green, iconColor.blue, 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF000000))),
          subtitle: Text(subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFFBBBBBB), size: 20),
        ),
      ),
    );
  }
}