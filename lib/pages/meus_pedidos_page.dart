import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_page.dart';

class MeusPedidosPage extends StatelessWidget {
  const MeusPedidosPage({super.key});

  static const _black          = Color(0xFF000000);
  static const _white          = Color(0xFFFFFFFF);
  static const _accent         = Color(0xFF276EF1);
  static const _surface        = Color(0xFFF6F6F6);
  static const _textSecondary  = Color(0xFF757575);

  Color _corStatus(String status) {
    switch (status) {
      case 'aceito':     return const Color(0xFF34C759);
      case 'concluido':  return _accent;
      case 'cancelado':  return Colors.red;
      default:           return const Color(0xFFFF9500);
    }
  }

  String _labelStatus(String status) {
    switch (status) {
      case 'pendente':   return 'Aguardando';
      case 'aceito':     return 'Em andamento';
      case 'concluido':  return 'Concluído';
      case 'cancelado':  return 'Cancelado';
      default:           return status;
    }
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
                  .where('clientId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _accent));
                }

                if (snap.hasError) {
                  return Center(child: Text('Erro: ${snap.error}'));
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined, size: 56, color: _textSecondary),
                        SizedBox(height: 12),
                        Text('Nenhum pedido ainda',
                            style: TextStyle(fontSize: 16, color: _textSecondary, fontWeight: FontWeight.w500)),
                        SizedBox(height: 4),
                        Text('Seus pedidos aparecerão aqui.',
                            style: TextStyle(fontSize: 13, color: _textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final pedidoId = docs[i].id;
                    final titulo = data['titulo'] ?? data['title'] ?? 'Sem título';
                    final descricao = data['descricao'] ?? data['description'] ?? '';
                    final status = data['status'] ?? 'pendente';
                    final chatId = data['chatId'] ?? pedidoId;

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
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    titulo,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: _black),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(
                                      _corStatus(status).red,
                                      _corStatus(status).green,
                                      _corStatus(status).blue,
                                      0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _labelStatus(status),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _corStatus(status)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (descricao.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Text(
                                descricao,
                                style: const TextStyle(
                                    fontSize: 13, color: _textSecondary, height: 1.4),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (status == 'aceito')
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _black,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.chat_outlined,
                                      size: 16, color: _white),
                                  label: const Text('Abrir chat',
                                      style: TextStyle(
                                          color: _white, fontWeight: FontWeight.w700)),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ChatPage(chatId: chatId)),
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 16),
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