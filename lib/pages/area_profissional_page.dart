import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'ganhos_page.dart';
import 'chat_page.dart';
import 'pix_dialog.dart';
import 'login_page.dart';

class AreaProfissionalPage extends StatefulWidget {
  const AreaProfissionalPage({super.key});

  @override
  State<AreaProfissionalPage> createState() =>
      _AreaProfissionalPageState();
}

class _AreaProfissionalPageState extends State<AreaProfissionalPage> {

  @override
  void initState() {
    super.initState();
    _salvarLocalizacao();
  }

  Future<void> _salvarLocalizacao() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      });
    } catch (_) {}
  }

  Future<void> adicionarSaldo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final TextEditingController valorCtrl = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Adicionar saldo'),
        content: TextField(
          controller: valorCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Valor (mínimo R\$ 5,00)',
            prefixText: 'R\$ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final double valor = double.parse(
      valorCtrl.text.trim().replaceAll(',', '.'),
    );

    final result = await showDialog(
      context: context,
      builder: (_) => PixDialog(valor: valor),
    );

    if (result == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'balance': FieldValue.increment(valor),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saldo +R\$${valor.toStringAsFixed(2)} adicionado ✅',
          ),
        ),
      );
    }
  }

  Future<void> desbloquearPedido(
    String pedidoId,
    String? chatId,
  ) async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {

      final docUser = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final dataUser =
          docUser.data() as Map<String, dynamic>? ?? {};

      final balance = dataUser['balance'];
      final saldo = balance is num ? balance.toDouble() : 0.0;

      if (saldo >= 3) {

        final response = await http.post(
          Uri.parse(
            'https://conectapro-backend-1.onrender.com/carteira/desbloquear',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "userId": user.uid,
            "pedidoId": pedidoId,
          }),
        );

        // ✅ DEBUG PROFISSIONAL
        print("STATUS: ${response.statusCode}");
        print("BODY: ${response.body}");

        // ✅ PROTEÇÃO CONTRA ERRO
        if (response.statusCode != 200) {
          throw Exception(
            "Erro servidor ${response.statusCode}\n${response.body}",
          );
        }

        if (!response.body.trim().startsWith('{')) {
          throw Exception("Resposta inválida do servidor");
        }

        final data = jsonDecode(response.body);

        if (data["success"] == true) {

          await FirebaseFirestore.instance
              .collection('requests')
              .doc(pedidoId)
              .update({
            'providerId': user.uid,
            'status': 'aceito',
            'acceptedAt': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pedido liberado ✅")),
          );

          if (chatId != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(chatId: chatId),
              ),
            );
          }
        }

        return;
      }

      final pagou = await showDialog(
        context: context,
        builder: (_) => const PixDialog(valor: 3),
      );

      if (pagou != true) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pagamento confirmado ✅"),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $e")),
      );
    }
  }

  Future<void> sair() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Não logado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Profissional'),
        automaticallyImplyLeading: false,
        actions: [

          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Adicionar saldo',
            onPressed: adicionarSaldo,
          ),

          IconButton(
            icon: const Icon(Icons.attach_money),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GanhosPage(),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: sair,
          ),
        ],
      ),

      body: Column(
        children: [

          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {

              double saldo = 0;

              if (snapshot.hasData && snapshot.data!.exists) {
                final data =
                    snapshot.data!.data() as Map<String, dynamic>;
                final balance = data['balance'];

                if (balance is num) {
                  saldo = balance.toDouble();
                }
              }

              return Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                color: Colors.black12,
                child: Text(
                  'Saldo: R\$${saldo.toStringAsFixed(2)}',
                ),
              );
            },
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('providerId', isEqualTo: null)
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
                    child: Text('Nenhum pedido disponível'),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {

                    final doc = docs[index];
                    final data =
                        doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            Text(
                              data['description'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(data['category'] ?? ''),

                            const SizedBox(height: 10),

                            ElevatedButton(
                              onPressed: () {
                                desbloquearPedido(
                                  doc.id,
                                  data['chatId'],
                                );
                              },
                              child: const Text(
                                "Pegar pedido (R\$3)",
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
          ),
        ],
      ),
    );
  }
}