import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'chat_page.dart';
import 'pix_dialog.dart';

class MeusPedidosPage extends StatefulWidget {
  const MeusPedidosPage({super.key});

  @override
  State<MeusPedidosPage> createState() => _MeusPedidosPageState();
}

class _MeusPedidosPageState extends State<MeusPedidosPage> {

  // ✅ MANTIDO (não removi)
  Future<void> desbloquearPedidoCompleto(
    BuildContext context,
    String userId,
    String pedidoId,
    String? chatId,
  ) async {

    final pagou = await showDialog(
      context: context,
      builder: (_) => const PixDialog(valor: 3),
    );

    if (pagou != true) return;

    try {

      final response = await http.post(
        Uri.parse(
          'https://conectapro-backend-1.onrender.com/carteira/desbloquear',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "userId": userId,
          "pedidoId": pedidoId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Pedido desbloqueado"),
          ),
        );

        final chatFinal =
            (chatId != null && chatId.toString().isNotEmpty)
                ? chatId
                : pedidoId;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(chatId: chatFinal),
          ),
        );

      } else {
        throw Exception(data["error"]);
      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Usuário não autenticado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pedidos'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('clientId', isEqualTo: user.uid)
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
              child: Text('Nenhum pedido encontrado'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final doc = docs[index];
              final data = doc.data();

              final descricao = data['description'] ?? '';
              final chatId = data['chatId'];
              final price = data['price'];
              final providerId = data['providerId'];
              final confirmado = data['confirmadoCliente'] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ✅ DESCRIÇÃO
                      Text(
                        descricao,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ✅ STATUS
                      Text(
                        (providerId == null ||
                                providerId.toString().isEmpty)
                            ? 'Profissional: 🔒 aguardando'
                            : 'Profissional em atendimento ✅',
                      ),

                      const SizedBox(height: 5),

                      // ✅ VALOR
                      if (price != null)
                        Text(
                          'Valor: R\$ $price',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      const SizedBox(height: 10),

                      // ✅ CONFIRMAR VALOR
                      if (price != null && !confirmado)
                        ElevatedButton(
                          onPressed: () async {

                            await FirebaseFirestore.instance
                                .collection('requests')
                                .doc(doc.id)
                                .update({
                              'confirmadoCliente': true,
                            });

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text("Valor confirmado ✅"),
                              ),
                            );
                          },
                          child: const Text("Confirmar valor ✅"),
                        ),

                      if (confirmado)
                        const Text(
                          '✅ Valor confirmado',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      const SizedBox(height: 10),

                      // ✅ CHAT FUNCIONANDO (SEM PIX)
                      if (providerId != null)
                        ElevatedButton(
                          onPressed: () {

                            final chatFinal =
                                (chatId != null &&
                                        chatId.toString().isNotEmpty)
                                    ? chatId
                                    : doc.id;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChatPage(chatId: chatFinal),
                              ),
                            );
                          },
                          child: const Text('Abrir chat 💬'),
                        ),

                      const SizedBox(height: 10),

                      // ✅ STATUS FINAL
                      if (providerId != null)
                        const Text(
                          '🛠 Serviço em andamento',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
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