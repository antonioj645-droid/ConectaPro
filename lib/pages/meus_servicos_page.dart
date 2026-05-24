import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_page.dart';

class MeusServicosPage extends StatelessWidget {
  const MeusServicosPage({super.key});

  // ✅ FINALIZAR SERVIÇO
  Future<void> _finalizarServico(String requestId, BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({
      'status': 'completed',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Serviço finalizado ✅')),
    );
  }

  // ✅ STATUS BONITO
  Widget _statusWidget(String status) {
    switch (status) {
      case 'accepted':
        return Row(
          children: const [
            Icon(Icons.build_circle, color: Colors.blue, size: 16),
            SizedBox(width: 5),
            Text('Em andamento', style: TextStyle(color: Colors.blue)),
          ],
        );

      case 'completed':
        return Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            SizedBox(width: 5),
            Text('Concluído', style: TextStyle(color: Colors.green)),
          ],
        );

      default:
        return const Text('---');
    }
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Serviços'),
      ),

      // ✅ CORREÇÃO DO ERRO DO STREAMBUILDER
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('providerId', isEqualTo: user?.uid)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text('Você ainda não aceitou serviços'),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final doc = docs[index];
              final data = doc.data();

              final status = data['status'] ?? '';
              final chatId = data['chatId'];
              final price = data['price'];

              return Card(
                elevation: 4,
                margin: const EdgeInsets.all(10),

                child: ListTile(
                  title: Text(
                    data['description'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text('Cliente: ${data['clientName'] ?? ''}'),

                      const SizedBox(height: 5),

                      _statusWidget(status),

                      const SizedBox(height: 5),

                      // 💰 MOSTRA PREÇO
                      if (price != null)
                        Text(
                          'Valor: R\$ $price',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),

                  // 💬 + ✅ AQUI É O POWER
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // 💬 CHAT
                      if (chatId != null)
                        IconButton(
                          icon: const Icon(Icons.chat, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(chatId: chatId),
                              ),
                            );
                          },
                        ),

                      // ✅ FINALIZAR
                      if (status == 'accepted')
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () =>
                              _finalizarServico(doc.id, context),
                        ),
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