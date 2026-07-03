import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'chat_page.dart';
import 'pix_dialog.dart';
import 'meus_servicos_page.dart';
import 'historico_servicos_page.dart';
import 'meu_perfil_profissional_page.dart';

class AreaProfissionalPage extends StatefulWidget {
  AreaProfissionalPage({Key? key}) : super(key: key);

  @override
  State<AreaProfissionalPage> createState() => _AreaProfissionalPageState();
}

class _AreaProfissionalPageState extends State<AreaProfissionalPage> {
  // ─── Tema ──────────────────────────────────────────────────────────────────
  static const _black         = Color(0xFF000000);
  static const _white         = Color(0xFFFFFFFF);
  static const _accent        = Color(0xFF276EF1);
  static const _surface       = Color(0xFFF6F6F6);
  static const _textSecondary = Color(0xFF757575);

  final Set<String> _processandoPedidos = {};

  @override
  void initState() {
    super.initState();
    _salvarLocalizacao();
  }

  // ─── Localização ───────────────────────────────────────────────────────────
  Future<void> _salvarLocalizacao() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'latitude': pos.latitude, 'longitude': pos.longitude});
    } catch (_) {}
  }

  // ─── Abrir chat de suporte com o admin ──────────────────────────────────────
  Future<void> _abrirSuporte() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final chatId = 'suporte_${user.uid}';

    final docUser = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final nome = docUser.data()?['nome'] ??
        docUser.data()?['name'] ??
        user.email ??
        'Usuário';

    await FirebaseFirestore.instance
        .collection('suporte_chats')
        .doc(user.uid)
        .set({
      'userId': user.uid,
      'nome': nome,
      'tipo': 'profissional',
      'chatId': chatId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatPage(chatId: chatId)),
    );
  }

  // ─── Desbloquear pedido ────────────────────────────────────────────────────
  Future<void> _desbloquearPedido(String pedidoId, String? chatId) async {
    if (_processandoPedidos.contains(pedidoId)) return;
    setState(() => _processandoPedidos.add(pedidoId));

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _processandoPedidos.remove(pedidoId));
      return;
    }

    try {
      final docUser = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final saldo = ((docUser.data()?['balance'] ?? 0) as num).toDouble();

      // Saldo insuficiente → abre PIX para adicionar saldo
      if (saldo < 1) {
        setState(() => _processandoPedidos.remove(pedidoId));
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => const PixDialog(),
        );
        return;
      }

      final uri = Uri.https(
        'conectapro-backend-1.onrender.com',
        '/carteira/desbloquear',
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': user.uid, 'pedidoId': pedidoId}),
      );

      if (response.statusCode != 200) throw Exception(response.body);

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        await FirebaseFirestore.instance
            .collection('requests')
            .doc(pedidoId)
            .update({
          'providerId': user.uid,
          'status': 'aceito',
          'acceptedAt': FieldValue.serverTimestamp(),
        });

        final chatFinal =
            (chatId != null && chatId.isNotEmpty) ? chatId : pedidoId;

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatPage(chatId: chatFinal)),
        );
      } else {
        throw Exception(data['message'] ?? 'Falha ao desbloquear.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processandoPedidos.remove(pedidoId));
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Não logado')));
    }

    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSaldoBanner(user),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pedidos disponíveis',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _black),
              ),
            ),
          ),
          Expanded(child: _buildListaPedidos(user)),
        ],
      ),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _black,
      foregroundColor: _white,
      elevation: 0,
      title: const Text(
        'Painel Profissional',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history_outlined),
          tooltip: 'Histórico',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HistoricoServicosPage()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.work_outline),
          tooltip: 'Meus serviços',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MeusServicosPage()),
          ),
        ),
        // ✅ Abre PixDialog sem valor — profissional digita o valor lá dentro
        IconButton(
          icon: const Icon(Icons.account_balance_wallet_outlined),
          tooltip: 'Adicionar saldo',
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const PixDialog(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          tooltip: 'Meu perfil',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MeuPerfilProfissionalPage()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.help_outline),
          tooltip: 'Ajuda',
          onPressed: _abrirSuporte,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sair',
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (!mounted) return;
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  // ─── Banner de saldo ───────────────────────────────────────────────────────
  Widget _buildSaldoBanner(User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snap) {
        double saldo = 0;
        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data() as Map<String, dynamic>;
          saldo = ((d['balance'] ?? 0) as num).toDouble();
        }
        return Container(
          color: _black,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet,
                  color: _accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Saldo: R\$ ${saldo.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: _white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (saldo < 1)
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const PixDialog(),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Adicionar',
                      style: TextStyle(
                          color: _white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── Lista de pedidos ──────────────────────────────────────────────────────
  Widget _buildListaPedidos(User user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('status', isEqualTo: 'aberto')
          .orderBy('criadoEm', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _accent));
        }

        if (snap.hasError) {
          return Center(
              child: Text('Erro: ${snap.error}',
                  style: const TextStyle(color: Colors.red)));
        }

        final docs = snap.data?.docs ?? [];

        // Verifica se o profissional já tem serviço ativo
        final temServicoAtivo = docs.any((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['providerId'] == user.uid &&
              data['status'] == 'aceito';
        });

        // Filtra apenas pedidos sem profissional
        final pedidos = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['providerId'] == null ||
              (data['providerId'] as String).isEmpty;
        }).toList();

        if (pedidos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 56, color: _textSecondary),
                SizedBox(height: 12),
                Text('Nenhum pedido disponível',
                    style: TextStyle(
                        fontSize: 16,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: 4),
                Text('Novos pedidos aparecerão aqui automaticamente.',
                    style: TextStyle(fontSize: 13, color: _textSecondary)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: _accent,
          onRefresh: () async => setState(() {}),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: pedidos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc  = pedidos[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildCardPedido(
                  doc.id, data, temServicoAtivo);
            },
          ),
        );
      },
    );
  }

  // ─── Card de pedido ────────────────────────────────────────────────────────
  Widget _buildCardPedido(
      String pedidoId, Map<String, dynamic> data, bool temServicoAtivo) {
    final titulo    = data['titulo'] ?? data['title'] ?? 'Serviço sem título';
    final descricao = data['descricao'] ?? data['description'] ?? '';
    final categoria = data['categoria'] ?? data['category'] ?? '';
    final bairro    = data['bairro'] ?? data['neighborhood'] ?? '';
    final chatId    = data['chatId'] as String?;
    final isProcessando = _processandoPedidos.contains(pedidoId);

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(39, 110, 241, 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.build_circle_outlined,
                      color: _accent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _black),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (categoria.isNotEmpty)
                        Text(categoria,
                            style: const TextStyle(
                                fontSize: 12,
                                color: _accent,
                                fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (bairro.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: _textSecondary),
                      const SizedBox(width: 2),
                      Text(bairro,
                          style: const TextStyle(
                              fontSize: 12, color: _textSecondary)),
                    ],
                  ),
              ],
            ),
          ),

          const Divider(color: Color(0xFFE5E5E5), height: 1, indent: 16, endIndent: 16),

          if (descricao.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(
                descricao,
                style: const TextStyle(
                    fontSize: 13.5, color: _textSecondary, height: 1.45),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Aviso serviço ativo
          if (temServicoAtivo)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 14, color: Color(0xFFFF9500)),
                  SizedBox(width: 6),
                  Text(
                    'Finalize seu serviço atual primeiro',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF9500),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

          // Botão aceitar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      temServicoAtivo ? const Color(0xFFCCCCCC) : _black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: (isProcessando || temServicoAtivo)
                    ? null
                    : () => _desbloquearPedido(pedidoId, chatId),
                child: isProcessando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: _white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.lock_open_outlined,
                              size: 18, color: _white),
                          SizedBox(width: 8),
                          Text(
                            'Aceitar pedido (R\$ 1,00)',
                            style: TextStyle(
                                color: _white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}