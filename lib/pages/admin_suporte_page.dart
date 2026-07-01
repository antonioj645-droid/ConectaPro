import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_page.dart';

class AdminSuportePage extends StatelessWidget {
  const AdminSuportePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suporte Admin'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('status', isEqualTo: 'aceito')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text('Nenhum chat ativo'),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data =
                  docs[index].data() as Map<String, dynamic>;

              final pedidoId = docs[index].id;
              final chatId = data['chatId'] ?? pedidoId;
              final titulo =
                  data['titulo'] ?? 'Pedido sem título';

              return ListTile(
                leading: const Icon(Icons.support_agent),
                title: Text(titulo),
                subtitle: Text(chatId),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        chatId: chatId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}