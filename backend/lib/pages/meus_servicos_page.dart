import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

class MeusServicosPage extends StatelessWidget {
  const MeusServicosPage({super.key});

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Não logado")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meus Serviços"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('providerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("Nenhum serviço em andamento"),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final descricao = data['description'] ?? '';
              final chatId = data['chatId'];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(descricao),

                  subtitle: const Text("Conversar com cliente"),

                  trailing: ElevatedButton(
                    onPressed: () {

                      if (chatId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Chat não disponível"),
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(chatId: chatId),
                        ),
                      );
                    },
                    child: const Text("Abrir 💬"),
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
