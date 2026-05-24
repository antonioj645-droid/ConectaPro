import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GanhosPage extends StatelessWidget {
  const GanhosPage({super.key});

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Ganhos'),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('providerId', isEqualTo: user?.uid)
            .where('status', isEqualTo: 'completed')
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          double total = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final price = data['price'] ?? 0;
            total += price;
          }

          return Column(
            children: [

              const SizedBox(height: 20),

              // ✅ TOTAL
              Column(
                children: [

                  const Icon(
                    Icons.attach_money,
                    size: 50,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Ganhos totais',
                    style: TextStyle(fontSize: 18),
                  ),

                  Text(
                    'R\$ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Divider(),

              const Text(
                'Histórico',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              // ✅ LISTA DE SERVIÇOS
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {

                    final data =
                        docs[index].data() as Map<String, dynamic>;

                    final descricao = data['description'] ?? '';
                    final price = data['price'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(descricao),

                        trailing: Text(
                          'R\$ $price',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
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
