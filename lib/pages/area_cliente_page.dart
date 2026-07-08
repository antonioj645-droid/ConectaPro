import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart'; // ✅ AuthCheck para logout correto
import 'novo_pedido_page.dart';
import 'meus_pedidos_page.dart';
import 'perfil_page.dart';
import 'map_page.dart';
import 'chat_page.dart';

class AreaClientePage extends StatefulWidget {
  const AreaClientePage({super.key});

  @override
  State<AreaClientePage> createState() => _AreaClientePageState();
}

class _AreaClientePageState extends State<AreaClientePage> {
  // ─── Tema (mesma paleta da área profissional) ───────────────────────────────
  static const _black         = Color(0xFF0A0A12);
  static const _navyDark      = Color(0xFF0A0A16);
  static const _navyLight     = Color(0xFF1B1F3B);
  static const _white         = Color(0xFFFFFFFF);
  static const _accent        = Color(0xFF2F6FED);
  static const _surface       = Color(0xFFF3F4F8);
  static const _textSecondary = Color(0xFF6B7280);

  String _nomeUsuario = '';
  String _role        = '';
  bool   _loadingNome = true;

  final _buscaCtrl  = TextEditingController();
  final _bannerCtrl = PageController();
  int    _bannerAtual = 0;
  Timer? _bannerTimer;

  static const List<Map<String, String>> _banners = [
    {'titulo': 'Ar-Condicionado instalado hoje', 'sub': 'Encontre técnicos próximos de você',       'emoji': '❄️'},
    {'titulo': 'Serviços com até 5 estrelas ⭐',  'sub': 'Profissionais avaliados pela comunidade',  'emoji': '🏆'},
    {'titulo': 'Elétrica, Hidráulica e mais',     'sub': 'Mais de 120 tipos de serviço disponíveis','emoji': '⚡'},
    {'titulo': 'Pagamento só após o serviço',     'sub': 'Sua segurança é nossa prioridade',         'emoji': '🛡️'},
  ];

  static const List<Map<String, dynamic>> _categoriasGrid = [
    {'nome': 'Casa e Construção',           'icon': Icons.home_repair_service,     'cor': Color(0xFFFF6B35)},
    {'nome': 'Elétrica',                    'icon': Icons.bolt,                    'cor': Color(0xFFFFCC00)},
    {'nome': 'Hidráulica',                  'icon': Icons.water_drop,              'cor': Color(0xFF2F6FED)},
    {'nome': 'Refrigeração e Climatização', 'icon': Icons.ac_unit,                 'cor': Color(0xFF00BCD4)},
    {'nome': 'Assistência Técnica',         'icon': Icons.phone_android,           'cor': Color(0xFF9C27B0)},
    {'nome': 'Automotivo',                  'icon': Icons.directions_car,          'cor': Color(0xFF607D8B)},
    {'nome': 'Limpeza',                     'icon': Icons.cleaning_services,       'cor': Color(0xFF4CAF50)},
    {'nome': 'Mudanças e Fretes',           'icon': Icons.local_shipping,          'cor': Color(0xFFFF9800)},
    {'nome': 'Chaveiro',                    'icon': Icons.key,                     'cor': Color(0xFF795548)},
    {'nome': 'Segurança',                   'icon': Icons.security,                'cor': Color(0xFFF44336)},
    {'nome': 'Tecnologia',                  'icon': Icons.computer,                'cor': Color(0xFF3F51B5)},
    {'nome': 'Beleza',                      'icon': Icons.face_retouching_natural, 'cor': Color(0xFFE91E63)},
    {'nome': 'Saúde e Bem-estar',           'icon': Icons.favorite,                'cor': Color(0xFFE53935)},
    {'nome': 'Eventos',                     'icon': Icons.celebration,             'cor': Color(0xFFFF4081)},
    {'nome': 'Educação',                    'icon': Icons.school,                  'cor': Color(0xFF00897B)},
    {'nome': 'Pet',                         'icon': Icons.pets,                    'cor': Color(0xFF8D6E63)},
    {'nome': 'Moda',                        'icon': Icons.checkroom,               'cor': Color(0xFFAD1457)},
    {'nome': 'Serviços Empresariais',       'icon': Icons.business_center,         'cor': Color(0xFF37474F)},
    {'nome': 'Entregas',                    'icon': Icons.delivery_dining,         'cor': Color(0xFFFF5722)},
    {'nome': 'Outros Serviços',             'icon': Icons.miscellaneous_services,  'cor': Color(0xFF757575)},
  ];

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _iniciarBanner();
  }

  void _iniciarBanner() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_bannerAtual + 1) % _banners.length;
      _bannerCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut);
      setState(() => _bannerAtual = next);
    });
  }

  Future<void> _carregarDados() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _nomeUsuario = 'Usuário';
        _role        = 'cliente';
        _loadingNome = false;
      });
      return;
    }
    try {
      final doc  = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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

  // ─── Abrir chat de suporte com o admin ──────────────────────────────────────
  Future<void> _abrirSuporte() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final chatId = 'suporte_${user.uid}';

    await FirebaseFirestore.instance
        .collection('suporte_chats')
        .doc(user.uid)
        .set({
      'userId': user.uid,
      'nome': _nomeUsuario.isNotEmpty ? _nomeUsuario : (user.email ?? 'Usuário'),
      'tipo': 'cliente',
      'chatId': chatId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatPage(chatId: chatId)),
    );
  }

  Future<void> _sair() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sair da conta',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair', style: TextStyle(color: _white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthCheck()),
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
        title: const Text('Virar profissional',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Você passará a ter acesso ao painel profissional. Deseja continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
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

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthCheck()),
      (route) => false,
    );
  }

  void _buscar(String termo) {
    if (termo.trim().isEmpty) return;
    final cat = _categoriasGrid.firstWhere(
      (c) => (c['nome'] as String).toLowerCase().contains(termo.toLowerCase()),
      orElse: () => {},
    );
    if (cat.isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => NovoPedidoPage(categoriaInicial: cat['nome'] as String),
      ));
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => const NovoPedidoPage(),
      ));
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerCtrl.dispose();
    _buscaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NovoPedidoPage())),
        backgroundColor: _accent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: _white),
        label: const Text('Solicitar Serviço',
            style: TextStyle(color: _white, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeaderCard(),
          _buildBannerRotativo(),
          _buildAvisoSeguranca(),
          _buildCategorias(),
          _buildProfissionaisProximosSection(),
          if (_role != 'profissional') ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildBannerProfissional(),
            ),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ─── AppBar (mesmo padrão da área profissional) ─────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _navyDark,
      foregroundColor: _white,
      elevation: 0,
      titleSpacing: 12,
      title: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Conecta',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  letterSpacing: -0.3,
                  color: _white)),
          Text('Pro',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  letterSpacing: -0.3,
                  color: _accent)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline_rounded, size: 22),
          tooltip: 'Ajuda',
          onPressed: _abrirSuporte,
        ),
        IconButton(
          icon: const Icon(Icons.receipt_long_rounded, size: 22),
          tooltip: 'Meus Pedidos',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => MeusPedidosPage())),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline_rounded, size: 22),
          tooltip: 'Perfil',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PerfilPage())),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, size: 22),
          tooltip: 'Sair',
          onPressed: _sair,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── Cartão de saudação + busca (gradiente navy, no padrão do banner de saldo) ─
  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navyDark, _navyLight],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(10, 10, 20, 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color.fromRGBO(255, 255, 255, 0.06),
                      width: 18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              child: _loadingNome
                  ? const Center(
                      child: SizedBox(
                        height: 44,
                        child: CircularProgressIndicator(
                            color: _white, strokeWidth: 2),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, ${_nomeUsuario.split(' ').first} 👋',
                          style: const TextStyle(
                              color: _white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Encontre profissionais confiáveis perto de você.',
                          style: TextStyle(
                              color: Color(0xFFB8BAC9), fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: _white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
                            controller: _buscaCtrl,
                            onSubmitted: _buscar,
                            style: const TextStyle(color: _black),
                            decoration: InputDecoration(
                              hintText: 'Qual serviço você procura?',
                              hintStyle: const TextStyle(
                                  color: Color(0xFF9E9E9E), fontSize: 14),
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: Color(0xFF9E9E9E)),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.arrow_forward_rounded,
                                    color: _accent),
                                onPressed: () => _buscar(_buscaCtrl.text),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: _white,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
// ─── Banner rotativo ─────────────────────────────────────────────────────────
  Widget _buildBannerRotativo() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          SizedBox(
            height: 110,
            child: PageView.builder(
              controller: _bannerCtrl,
              itemCount: _banners.length,
              onPageChanged: (i) => setState(() => _bannerAtual = i),
              itemBuilder: (_, i) {
                final b = _banners[i];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(15, 15, 30, 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(b['emoji']!,
                            style: const TextStyle(fontSize: 26)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(b['titulo']!,
                                style: const TextStyle(
                                    color: _black,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5)),
                            const SizedBox(height: 3),
                            Text(b['sub']!,
                                style: const TextStyle(
                                    color: _textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _bannerAtual == i ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _bannerAtual == i ? _accent : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
        ],
      ),
    );
  }

  // ─── Aviso de segurança ──────────────────────────────────────────────────────
  Widget _buildAvisoSeguranca() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE0A3)),
      ),
      child: const Row(
        children: [
          Text('🛡️', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nunca pague antecipadamente. Efetue o pagamento ao profissional somente após a conclusão do serviço.',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A5A00),
                  fontWeight: FontWeight.w500,
                  height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Categorias ──────────────────────────────────────────────────────────────
  Widget _buildCategorias() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                ),
              ),
              const Text('Categorias de serviço',
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: _black,
                      letterSpacing: -0.2)),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(15, 15, 30, 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categoriasGrid.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 14,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, i) {
              final cat = _categoriasGrid[i];
              return GestureDetector(
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => NovoPedidoPage(
                    categoriaInicial: cat['nome'] as String,
                  )),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: (cat['cor'] as Color).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(cat['icon'] as IconData,
                          color: cat['cor'] as Color, size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat['nome'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Seção "Profissionais próximos" (título + lista) ────────────────────────
  Widget _buildProfissionaisProximosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                ),
              ),
              const Text('Profissionais próximos',
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: _black,
                      letterSpacing: -0.2)),
            ],
          ),
        ),
        _buildProfissionaisProximos(),
      ],
    );
  }

  Widget _buildProfissionaisProximos() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'profissional')
          .limit(10)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const SizedBox();

        return SizedBox(
          height: 168,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data          = docs[i].data() as Map<String, dynamic>;
              final nome          = (data['nome'] ?? data['email'] ?? 'Profissional').toString();
              final primeiroNome  = nome.split(' ').first;
              final especialidade = data['especialidade'] ?? data['categoria'] ?? 'Profissional';
              final media         = ((data['mediaAvaliacao'] ?? 0) as num).toDouble();
              final fotoUrl       = data['fotoUrl'] as String? ?? data['photoUrl'] as String? ?? '';
              final fotoBase64    = data['fotoBase64'] as String? ?? '';

              ImageProvider? imagemFoto;
              if (fotoBase64.isNotEmpty) {
                try {
                  imagemFoto = MemoryImage(base64Decode(fotoBase64));
                } catch (_) {}
              } else if (fotoUrl.isNotEmpty) {
                imagemFoto = NetworkImage(fotoUrl);
              }

              return Container(
                width: 124,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(15, 15, 30, 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _accent.withOpacity(0.10),
                      backgroundImage: imagemFoto,
                      child: imagemFoto == null
                          ? Text(
                              primeiroNome[0].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: _accent),
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      primeiroNome,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _black),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      especialidade,
                      style: const TextStyle(
                          fontSize: 10, color: _textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: Color(0xFFFFC94D)),
                        const SizedBox(width: 2),
                        Text(
                          media > 0 ? media.toStringAsFixed(1) : 'Novo',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ─── Banner "Seja um profissional" ───────────────────────────────────────────
  Widget _buildBannerProfissional() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navyDark, _navyLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(10, 10, 20, 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.work_outline_rounded,
                color: _white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seja um profissional',
                    style: TextStyle(
                        color: _white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
                SizedBox(height: 2),
                Text('Receba pedidos e ganhe dinheiro',
                    style: TextStyle(
                        color: Color(0xFFB8BAC9), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _virarProfissional,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                  color: _accent, borderRadius: BorderRadius.circular(24)),
              child: const Text('Ativar',
                  style: TextStyle(
                      color: _white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}