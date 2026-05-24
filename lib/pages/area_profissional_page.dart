import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';
import 'meus_servicos_page.dart';
import 'ganhos_page.dart';

class AreaProfissionalPage extends StatelessWidget {
  const AreaProfissionalPage({super.key});

  // 💰 ACEITAR PEDIDO + CRIAR CHAT
  Future<void> _aceitarPedido(String requestId, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Definir valor do serviço'),

          content: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Valor (R\$)',
            ),
          ),

          actions: [

            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),

            ElevatedButton(
              onPressed: () async {

                final price = double.tryParse(priceController.text);

                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Valor inválido ❌')),
                  );
                  return;
                }

                try {
                  final docRef = FirebaseFirestore.instance
                      .collection('requests')
                      .doc(requestId);

                  final doc = await docRef.get();
                  final data = doc.data();

                  // ✅ evita aceitar duas vezes
                  if (data?['status'] != 'open') {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pedido já aceito ❌')),
                    );
                    return;
                  }

                  final clientId = data?['clientId'];

                  final docUser = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();

                  final dataUser = docUser.data();

                  final nome = dataUser?['nome'] ?? 'Sem nome';
                  final telefone = dataUser?['phone'] ?? '';

                  // ✅ CRIA CHAT
                  final chatRef = FirebaseFirestore.instance
                      .collection('chats')
                      .doc();

                  await chatRef.set({
                    'participants': [user.uid, clientId],
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  // ✅ ATUALIZA PEDIDO
                  await docRef.update({
                    'status': 'accepted',
                    'providerId': user.uid,
                    'providerName': nome,
                    'providerPhone': telefone,
                    'price': price,
                    'chatId': chatRef.id, // 🔥 ESSENCIAL
                  });

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pedido aceito + chat criado ✅💬'),
                    ),
                  );

                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  // 🚪 LOGOUT
  Future<void> _sair(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text('Painel Profissional'),

        actions: [

          // 💰 GANHOS
          IconButton(
            icon: const Icon(Icons.attach_money),
            tooltip: 'Ganhos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GanhosPage(),
                ),
              );
            },
          ),

          // 📊 MEUS SERVIÇOS
          IconButton(
            icon: const Icon(Icons.work),
            tooltip: 'Meus serviços',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MeusServicosPage(),
                ),
              );
            },
          ),

          // 🚪 SAIR
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => _sair(context),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('status', isEqualTo: 'open')
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar pedidos'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Nenhum pedido disponível'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.all(10),

                child: ListTile(
                  title: Text(
                    data['description'] ?? 'Sem descrição',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Text(
                    'Cliente: ${data['clientName'] ?? '---'}',
                  ),

                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    onPressed: () =>
                        _aceitarPedido(doc.id, context),

                    child: const Text('Aceitar'),
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