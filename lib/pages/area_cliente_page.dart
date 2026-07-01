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
  static const _black   = Color(0xFF000000);
  static const _white   = Color(0xFFFFFFFF);
  static const _accent  = Color(0xFF276EF1);
  static const _surface = Color(0xFFF6F6F6);

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
    {'nome': 'Hidráulica',                  'icon': Icons.water_drop,              'cor': Color(0xFF276EF1)},
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
      appBar: AppBar(
        backgroundColor: _black,
        foregroundColor: _white,
        elevation: 0,
        title: const Text('ConectaPro',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Ajuda',
            onPressed: _abrirSuporte,
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Meus Pedidos',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => MeusPedidosPage())),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PerfilPage())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _sair,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NovoPedidoPage())),
        backgroundColor: _accent,
        icon: const Icon(Icons.add, color: _white),
        label: const Text('Solicitar Serviço',
            style: TextStyle(color: _white, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [

          // ── HEADER ───────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            color: _black,
            child: _loadingNome
                ? const Center(child: CircularProgressIndicator(
                    color: _white, strokeWidth: 2))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, ${_nomeUsuario.split(' ').first} 👋',
                        style: const TextStyle(
                            color: _white, fontSize: 22,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Encontre profissionais confiáveis perto de você.',
                        style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
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
                          decoration: InputDecoration(
                            hintText: 'Qual serviço você procura?',
                            hintStyle: const TextStyle(
                                color: Color(0xFF9E9E9E), fontSize: 14),
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xFF9E9E9E)),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_forward,
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

          // ── BANNER ROTATIVO ──────────────────────────────────────────────
          Container(
            color: _black,
            padding: const EdgeInsets.only(bottom: 20),
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF276EF1), Color(0xFF1A4DB5)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Text(b['emoji']!,
                                style: const TextStyle(fontSize: 36)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(b['titulo']!,
                                      style: const TextStyle(
                                          color: _white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(b['sub']!,
                                      style: const TextStyle(
                                          color: Color(0xFFCCDDFF),
                                          fontSize: 12)),
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
                      color: _bannerAtual == i ? _accent : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  )),
                ),
              ],
            ),
          ),

          // ── AVISO DE SEGURANÇA ───────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCC02)),
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
                        color: Color(0xFF795548),
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // ── CATEGORIAS ───────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text('Categorias de serviço',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222))),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categoriasGrid.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
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
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: (cat['cor'] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(cat['icon'] as IconData,
                            color: cat['cor'] as Color, size: 26),
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
                            color: Color(0xFF333333)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── PROFISSIONAIS PRÓXIMOS ───────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 10),
            child: Text('Profissionais próximos',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222))),
          ),

          _buildProfissionaisProximos(),

          // ── BANNER PROFISSIONAL ──────────────────────────────────────────
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
          height: 160,
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
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFE8F0FE),
                      backgroundImage: imagemFoto,
                      child: imagemFoto == null
                          ? Text(
                              primeiroNome[0].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF276EF1)),
                            )
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      primeiroNome,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF222222)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      especialidade,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF757575)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star,
                            size: 12, color: Color(0xFFFFCC00)),
                        const SizedBox(width: 2),
                        Text(
                          media > 0 ? media.toStringAsFixed(1) : 'Novo',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF555555)),
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

  Widget _buildBannerProfissional() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: _black, borderRadius: BorderRadius.circular(16)),
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
                    style: TextStyle(
                        color: _white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                SizedBox(height: 2),
                Text('Receba pedidos e ganhe dinheiro',
                    style: TextStyle(
                        color: Color(0xFFAAAAAA), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _virarProfissional,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: _accent, borderRadius: BorderRadius.circular(20)),
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