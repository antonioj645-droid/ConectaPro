import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

class MeusServicosPage extends StatelessWidget {
  const MeusServicosPage({super.key});

  static const _black         = Color(0xFF000000);
  static const _white         = Color(0xFFFFFFFF);
  static const _accent        = Color(0xFF276EF1);
  static const _green         = Color(0xFF34C759);
  static const _surface       = Color(0xFFF6F6F6);
  static const _textSecondary = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _black,
        foregroundColor: _white,
        elevation: 0,
        title: const Text('Meus Serviços',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('providerId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _accent));
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work_outline, size: 56, color: _textSecondary),
                  SizedBox(height: 12),
                  Text('Você ainda não aceitou serviços',
                      style: TextStyle(
                          fontSize: 16,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc    = docs[index];
              final data   = doc.data() as Map<String, dynamic>;

              // ✅ campos corrigidos
              final titulo   = data['titulo'] ?? data['description'] ?? 'Sem título';
              final status   = data['status'] ?? '';
              final chatId   = data['chatId'] ?? doc.id; // ✅ sem requestId

              String labelStatus() {
                switch (status) {
                  case 'aceito':    return 'Em andamento';
                  case 'concluido': return 'Concluído';
                  case 'aberto':    return 'Aberto';
                  default:          return status;
                }
              }

              Color corStatus() {
                switch (status) {
                  case 'aceito':    return _accent;
                  case 'concluido': return _green;
                  default:          return _textSecondary;
                }
              }

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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Ícone
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(
                              corStatus().red,
                              corStatus().green,
                              corStatus().blue,
                              0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.build_circle_outlined,
                            color: corStatus(), size: 22),
                      ),
                      const SizedBox(width: 12),

                      // Título e status
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
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(
                                    corStatus().red,
                                    corStatus().green,
                                    corStatus().blue,
                                    0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                labelStatus(),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: corStatus()),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Botão chat (só se aceito)
                      if (status == 'aceito')
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(chatId: chatId), // ✅ só chatId
                            ),
                          ),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.chat_outlined,
                                color: _white, size: 18),
                          ),
                        ),

                      if (status == 'concluido')
                        const Icon(Icons.check_circle,
                            color: _green, size: 28),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}