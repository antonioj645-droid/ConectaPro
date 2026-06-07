import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_page.dart';
import 'package:conectapro/pages/pix_dialog.dart';

class MeusServicosPage extends StatelessWidget {
  const MeusServicosPage({super.key});

  Future<void> _finalizarServico(
      String requestId, BuildContext context) async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final requestRef = FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId);

    final reqDoc = await requestRef.get();
    final data = reqDoc.data();

    final price = (data?['price'] ?? 0).toDouble();
    final taxa = price * 0.07;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final userDoc = await userRef.get();
    double saldo = (userDoc['balance'] ?? 0).toDouble();

    if (saldo < taxa) {
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text("Finalizar serviço"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    "Para concluir, pague a taxa da plataforma"),
                const SizedBox(height: 10),
                Text(
                  "Taxa: R\$${taxa.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () async {

                  Navigator.pop(context);

                  final pago = await showDialog(
                    context: context,
                    builder: (_) => PixDialog(valor: taxa),
                  );

                  if (pago == true) {
                    await userRef.update({
                      'balance': FieldValue.increment(taxa),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Saldo adicionado ✅")),
                    );
                  }
                },
                child: const Text("Pagar com PIX"),
              ),
            ],
          );
        },
      );

      return;
    }

    await userRef.update({
      'balance': FieldValue.increment(-taxa),
    });

    await requestRef.update({
      'status': 'completed',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Serviço finalizado ✅")),
    );
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Serviços')),
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
              child: Text('Sem serviços'),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final doc = docs[index];
              final data = doc.data();

              final status = data['status'];
              final chatId = data['chatId'];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data['description'] ?? ''),
                  subtitle: Text("Cliente: ${data['clientName']}"),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      if (chatId != null)
                        IconButton(
                          icon: const Icon(Icons.chat),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChatPage(chatId: chatId),
                              ),
                            );
                          },
                        ),

                      if (status == 'accepted')
                        IconButton(
                          icon: const Icon(Icons.check,
                              color: Colors.green),
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
