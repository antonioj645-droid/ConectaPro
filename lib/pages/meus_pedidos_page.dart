import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_page.dart';
import 'perfil_profissional_page.dart';

class MeusPedidosPage extends StatelessWidget {
  const MeusPedidosPage({super.key});

  static const _black         = Color(0xFF000000);
  static const _white         = Color(0xFFFFFFFF);
  static const _accent        = Color(0xFF276EF1);
  static const _surface       = Color(0xFFF6F6F6);
  static const _textSecondary = Color(0xFF757575);
  static const _green         = Color(0xFF34C759);
  static const _orange        = Color(0xFFFF9500);
  static const _red           = Color(0xFFFF3B30);

  Color _corStatus(String s) {
    switch (s) {
      case 'aceito':    return _accent;
      case 'concluido': return _green;
      case 'cancelado': return _red;
      default:          return _orange;
    }
  }

  String _labelStatus(String s) {
    switch (s) {
      case 'pendente':  return 'Aguardando profissional';
      case 'open':      return 'Aguardando profissional';
      case 'aberto':    return 'Aguardando profissional';
      case 'aceito':    return 'Em andamento';
      case 'concluido': return 'Concluído';
      case 'cancelado': return 'Cancelado';
      default:          return s;
    }
  }

  Future<void> _cancelarPedido(BuildContext context, String pedidoId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancelar pedido',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Tem certeza que deseja cancelar este pedido?\nO profissional será notificado.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar',
                style: TextStyle(color: Color(0xFF757575))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar pedido',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(pedidoId)
          .update({
        'status': 'cancelado',
        'canceladoEm': FieldValue.serverTimestamp(),
        'providerId': '',
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido cancelado com sucesso.'),
            backgroundColor: Color(0xFFFF3B30),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cancelar: $e')),
        );
      }
    }
  }

  Future<void> _marcarConcluido(BuildContext context, String pedidoId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirmar conclusão',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'O serviço foi executado e você está satisfeito?\nIsso liberará o pagamento ao profissional.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar',
                style: TextStyle(color: Color(0xFF757575))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34C759),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(pedidoId)
          .update({
        'status': 'concluido',
        'concluidoEm': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço marcado como concluído! ✅'),
            backgroundColor: Color(0xFF34C759),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  void _abrirAvaliacao(BuildContext context, String pedidoId, String providerId) {
    int _estrelas = 0;
    final _comentarioCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Avaliar profissional',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Como foi o serviço?',
                style: TextStyle(color: _textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setStateDialog(() => _estrelas = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < _estrelas ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFFCC00),
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _comentarioCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Deixe um comentário (opcional)',
                  hintStyle: const TextStyle(color: _textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: _surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: _textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: _estrelas == 0
                  ? null
                  : () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('requests')
                            .doc(pedidoId)
                            .update({
                          'avaliacao':  _estrelas,
                          'comentario': _comentarioCtrl.text.trim(),
                          'avaliadoEm': FieldValue.serverTimestamp(),
                        });

                        final userRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(providerId);

                        await FirebaseFirestore.instance
                            .runTransaction((tx) async {
                          final userDoc = await tx.get(userRef);
                          final data = userDoc.data() ?? {};

                          final totalAval =
                              ((data['totalAvaliacoes'] ?? 0) as num).toInt();
                          final somaAval =
                              ((data['somaAvaliacoes'] ?? 0) as num).toDouble();

                          final novoTotal = totalAval + 1;
                          final novaSoma  = somaAval + _estrelas;
                          final novaMedia = novaSoma / novoTotal;

                          final deveSerVerificado =
                              novoTotal >= 5 && novaMedia >= 4.5;

                          tx.update(userRef, {
                            'totalAvaliacoes': novoTotal,
                            'somaAvaliacoes':  novaSoma,
                            'mediaAvaliacao':  novaMedia,
                            'verificado':      deveSerVerificado,
                          });
                        });

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Avaliação enviada! ⭐'),
                              backgroundColor: _green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro: $e')),
                          );
                        }
                      }
                    },
              child: const Text('Enviar avaliação',
                  style: TextStyle(color: _white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _black,
        foregroundColor: _white,
        elevation: 0,
        title: const Text(
          'Meus Pedidos',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: user == null
          ? const Center(child: Text('Não logado'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('clienteId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _accent));
                }

                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: _red, size: 48),
                          const SizedBox(height: 12),
                          Text('Erro: ${snap.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: _textSecondary)),
                        ],
                      ),
                    ),
                  );
                }

                final docs = snap.data?.docs ?? [];

                docs.sort((a, b) {
                  final dataA = (a.data() as Map)['criadoEm'];
                  final dataB = (b.data() as Map)['criadoEm'];
                  if (dataA == null || dataB == null) return 0;
                  return dataB.compareTo(dataA);
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 56, color: _textSecondary),
                        SizedBox(height: 12),
                        Text('Nenhum pedido ainda',
                            style: TextStyle(
                                fontSize: 16,
                                color: _textSecondary,
                                fontWeight: FontWeight.w500)),
                        SizedBox(height: 4),
                        Text('Seus pedidos aparecerão aqui.',
                            style: TextStyle(
                                fontSize: 13, color: _textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final data      = docs[i].data() as Map<String, dynamic>;
                    final pedidoId  = docs[i].id;

                    final titulo     = data['titulo'] ?? data['descricao'] ?? 'Sem título';
                    final status     = data['status'] ?? 'aberto';
                    final chatId     = data['chatId'] ?? pedidoId;
                    final categoria  = data['categoria'] ?? '';
                    final providerId = data['providerId'] ?? '';
                    final avaliacao  = data['avaliacao'];
                    final valorServico = data['valorServico'];

                    final cor = _corStatus(status);

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
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(
                                        cor.red, cor.green, cor.blue, 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.receipt_long_outlined,
                                      color: cor, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        titulo,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(
                                        cor.red, cor.green, cor.blue, 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _labelStatus(status),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: cor),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Valor + aviso de pagamento
                          if (valorServico != null) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.attach_money,
                                      size: 16, color: _green),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Valor: R\$ ${(valorServico as num).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: _green,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: _orange.withOpacity(0.4)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        size: 15, color: _orange),
                                    SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        'Faça o pagamento depois do serviço executado',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: _orange,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Média do profissional + badge verificado
                          if (providerId.isNotEmpty && status != 'aberto')
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(providerId)
                                  .get(),
                              builder: (context, snapProf) {
                                if (!snapProf.hasData ||
                                    !snapProf.data!.exists) {
                                  return const SizedBox();
                                }
                                final profData = snapProf.data!.data()
                                    as Map<String, dynamic>;
                                final media =
                                    (profData['mediaAvaliacao'] as num?)
                                            ?.toDouble() ??
                                        0;
                                final total =
                                    (profData['totalAvaliacoes'] as num?)
                                            ?.toInt() ??
                                        0;
                                final nome = profData['nome'] ??
                                    profData['email'] ??
                                    'Profissional';
                                final verificado =
                                    profData['verificado'] ?? false;

                                return Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person_outline,
                                          size: 14, color: _textSecondary),
                                      const SizedBox(width: 4),
                                      Text(nome,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: _textSecondary,
                                              fontWeight: FontWeight.w500)),
                                      if (verificado) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF34C759),
                                                Color(0xFF27A84A),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.verified,
                                                  color: Colors.white,
                                                  size: 10),
                                              SizedBox(width: 3),
                                              Text(
                                                'Verificado',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (media > 0) ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.star,
                                            size: 14,
                                            color: Color(0xFFFFCC00)),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${media.toStringAsFixed(1)} ($total avaliações)',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: _textSecondary,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),

                          // Avaliação já feita
                          if (avaliacao != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Row(
                                children: [
                                  ...List.generate(
                                      5,
                                      (i) => Icon(
                                            i < (avaliacao as num).toInt()
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: const Color(0xFFFFCC00),
                                            size: 18,
                                          )),
                                  const SizedBox(width: 6),
                                  const Text('Avaliado',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: _textSecondary)),
                                ],
                              ),
                            ),

                          // Botões
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              children: [

                                // Botão chat
                                if (status == 'aceito')
                                  SizedBox(
                                    width: double.infinity,
                                    height: 44,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _black,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.chat_outlined,
                                          size: 16, color: _white),
                                      label: const Text('Abrir chat',
                                          style: TextStyle(
                                              color: _white,
                                              fontWeight: FontWeight.w700)),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                ChatPage(chatId: chatId)),
                                      ),
                                    ),
                                  ),

                                // Botão concluir serviço
                                if (status == 'aceito') ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 44,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _green,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.check_circle_outline,
                                          size: 16, color: _white),
                                      label: const Text('Serviço concluído',
                                          style: TextStyle(
                                              color: _white,
                                              fontWeight: FontWeight.w700)),
                                      onPressed: () =>
                                          _marcarConcluido(context, pedidoId),
                                    ),
                                  ),
                                ],

                                // Botão cancelar
                                if (status == 'aceito' || status == 'aberto' || status == 'pendente' || status == 'open') ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 44,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _red,
                                        side: const BorderSide(color: _red),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(Icons.cancel_outlined,
                                          size: 16),
                                      label: const Text('Cancelar pedido',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700)),
                                      onPressed: () =>
                                          _cancelarPedido(context, pedidoId),
                                    ),
                                  ),
                                ],

                                // Ver perfil profissional
                                if (providerId.isNotEmpty &&
                                    status != 'aberto') ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 44,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _accent,
                                        side: const BorderSide(color: _accent),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(Icons.person_outline,
                                          size: 16),
                                      label: const Text(
                                          'Ver perfil do profissional',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700)),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              PerfilProfissionalPage(
                                                  providerId: providerId),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                // Avaliar profissional
                                if (status == 'concluido' &&
                                    avaliacao == null &&
                                    providerId.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 44,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFFFCC00),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.star_outline,
                                          size: 16, color: _black),
                                      label: const Text(
                                        'Avaliar profissional',
                                        style: TextStyle(
                                            color: _black,
                                            fontWeight: FontWeight.w700),
                                      ),
                                      onPressed: () => _abrirAvaliacao(
                                          context, pedidoId, providerId),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}