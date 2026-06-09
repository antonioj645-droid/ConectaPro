import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoricoServicosPage extends StatelessWidget {
  const HistoricoServicosPage({super.key});

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("Não logado"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Histórico de Serviços"),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('providerId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'finalizado')
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
              child: Text("Nenhum serviço finalizado"),
            );
          }

          double total = 0;

          for (var doc in docs) {
            final data = doc.data();

            final valorFinal = data['valorFinal'];

            if (valorFinal is num) {
              total += valorFinal.toDouble();
            }
          }

          return Column(
            children: [

              // ✅ TOTAL GANHO
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                color: Colors.green,
                child: Text(
                  "Total ganho: R\$ ${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // ✅ LISTA
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {

                    final doc = docs[index];
                    final data = doc.data();

                    final descricao = data['description'] ?? '';
                    final valorFinal = data['valorFinal'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(descricao),

                        subtitle: Text(
                          "R\$ ${valorFinal.toString()}",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        trailing: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
