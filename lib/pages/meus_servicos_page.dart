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
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [

                      /// ✅ DESCRIÇÃO
                      Text(
                        descricao,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// ✅ ABRIR CHAT
                      ElevatedButton(
                        onPressed: () {

                          if (chatId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Chat não disponível")),
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
                        child: const Text("Abrir chat 💬"),
                      ),

                      const SizedBox(height: 10),

                      /// ✅ FINALIZAR SERVIÇO
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () {

                          final controller = TextEditingController();

                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Finalizar serviço"),
                              content: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Valor do serviço",
                                ),
                              ),
                              actions: [

                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancelar"),
                                ),

                                ElevatedButton(
                                  onPressed: () async {

                                    final valor = double.tryParse(controller.text);

                                    if (valor == null || valor <= 0) return;

                                    final comissao = valor * 0.07;

                                    // ✅ DESCONTAR COMISSÃO
                                    final userRef = FirebaseFirestore.instance
                                        .collection("users")
                                        .doc(user.uid);

                                    final userDoc = await userRef.get();
                                    final saldo =
                                        ((userDoc.data()?["balance"] ?? 0) as num)
                                            .toDouble();

                                    if (saldo < comissao) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Saldo insuficiente para comissão"),
                                        ),
                                      );
                                      return;
                                    }

                                    await userRef.update({
                                      "balance": saldo - comissao
                                    });

                                    // ✅ FINALIZA PEDIDO
                                    await FirebaseFirestore.instance
                                        .collection("requests")
                                        .doc(doc.id)
                                        .update({
                                      "status": "finalizado",
                                      "valorFinal": valor,
                                      "finishedAt": FieldValue.serverTimestamp(),
                                    });

                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            "Serviço finalizado ✅ Comissão: R\$${comissao.toStringAsFixed(2)}"),
                                      ),
                                    );
                                  },
                                  child: const Text("Finalizar"),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text("Finalizar serviço 💰"),
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