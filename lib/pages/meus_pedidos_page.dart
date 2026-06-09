import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'chat_page.dart';
import 'pix_dialog.dart';
import 'meus_servicos_page.dart';
import 'historico_servicos_page.dart';

class AreaProfissionalPage extends StatefulWidget {
  const AreaProfissionalPage({Key? key}) : super(key: key);

  @override
  State<AreaProfissionalPage> createState() =>
      _AreaProfissionalPageState();
}

class _AreaProfissionalPageState extends State<AreaProfissionalPage> {

  final Set<String> _processandoPedidos = {};

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

  Future<void> desbloquearPedido(
    String pedidoId,
    String? chatId,
  ) async {

    if (_processandoPedidos.contains(pedidoId)) return;

    setState(() {
      _processandoPedidos.add(pedidoId);
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _processandoPedidos.remove(pedidoId));
      return;
    }

    try {

      final docUser = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final saldo =
          ((docUser.data()?['balance'] ?? 0) as num).toDouble();

      if (saldo >= 3) {

        final uri = Uri.https(
          'conectapro-backend-1.onrender.com',
          '/carteira/desbloquear',
        );

        final response = await http.post(
          uri,
          headers: {
            "Content-Type": "application/json"
          },
          body: jsonEncode({
            "userId": user.uid,
            "pedidoId": pedidoId,
          }),
        );

        if (response.statusCode != 200) {
          throw Exception(response.body);
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

          setState(() {});

          final chatFinal =
              (chatId != null && chatId.toString().isNotEmpty)
                  ? chatId
                  : pedidoId;

          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPage(chatId: chatFinal),
            ),
          );
        }

        return;
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e")),
        );
      }
    } finally {
      setState(() {
        _processandoPedidos.remove(pedidoId);
      });
    }
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

        actions: [

          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Histórico",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistoricoServicosPage(),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.work),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MeusServicosPage(),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),

          // ✅ PIX COM VALOR ESCOLHIDO
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: "Adicionar saldo",
            onPressed: () async {

              final controller = TextEditingController();

              final valor = await showDialog<double>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Digite o valor"),
                  content: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "Ex: 10, 50, 100",
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancelar"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final v = double.tryParse(controller.text);

                        if (v == null || v < 10) return;

                        Navigator.pop(context, v);
                      },
                      child: const Text("Continuar"),
                    ),
                  ],
                ),
              );

              if (valor == null) return;

              // ✅ CHAMA PIX REAL
              showDialog(
                context: context,
                builder: (_) => PixDialog(valor: valor),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pop(context);
            },
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
                saldo = ((data['balance'] ?? 0) as num).toDouble();
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
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docsTodos = snapshot.data!.docs;

                final temServicoAtivo = docsTodos.any((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return data['providerId'] == user.uid &&
                         data['status'] == 'aceito';
                });

                final docs = docsTodos.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['providerId'] == null;
                }).toList();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {

                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final carregando =
                        _processandoPedidos.contains(doc.id);

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

                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (carregando || temServicoAtivo)
                                    ? null
                                    : () {
                                        desbloquearPedido(
                                          doc.id,
                                          data['chatId'],
                                        );
                                      },
                                child: carregando
                                    ? const CircularProgressIndicator()
                                    : Text(
                                        temServicoAtivo
                                            ? "Finalize seu serviço primeiro"
                                            : "Pegar pedido (R\$3)",
                                      ),
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