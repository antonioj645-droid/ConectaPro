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

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Nenhum serviço finalizado"),
            );
          }

          final docs = snapshot.data!.docs;

          double total = 0;

          for (final doc in docs) {
            final data = doc.data();

            final valor = data['valorFinal'];

            if (valor is num) {
              total += valor.toDouble();
            }
          }

          return Column(
            children: [

              // ✅ TOTAL GANHO
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                color: Colors.green,
                child: Text(
                  "Total ganho: R\$ ${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              // ✅ LISTA
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {

                    final data = docs[index].data();

                    final descricao =
                        data['description']?.toString() ?? '';

                    final valorFinal =
                        (data['valorFinal'] is num)
                            ? (data['valorFinal'] as num).toDouble()
                            : 0.0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(descricao),

                        subtitle: Text(
                          "R\$ ${valorFinal.toStringAsFixed(2)}",
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