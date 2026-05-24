import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'chat_page.dart';
import 'pix_dialog.dart';

class MeusPedidosPage extends StatefulWidget {

  const MeusPedidosPage({super.key});

  @override
  State<MeusPedidosPage> createState() =>
      _MeusPedidosPageState();
}

class _MeusPedidosPageState
    extends State<MeusPedidosPage> {

  bool loading = false;

  @override
  Widget build(BuildContext context) {

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {

      return const Scaffold(

        body: Center(
          child: Text(
            'Usuário não autenticado',
          ),
        ),
      );
    }

    return Scaffold(

      appBar: AppBar(
        title: const Text('Meus Pedidos'),
      ),

      body: Stack(

        children: [

          StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(

            stream: FirebaseFirestore.instance
                .collection('requests')
                .where(
              'clientId',
              isEqualTo: user.uid,
            )
                .snapshots(),

            builder: (context, snapshot) {

              if (!snapshot.hasData) {

                return const Center(
                  child:
                  CircularProgressIndicator(),
                );
              }

              final docs =
                  snapshot.data!.docs;

              if (docs.isEmpty) {

                return const Center(
                  child: Text(
                    'Nenhum pedido encontrado',
                  ),
                );
              }

              return ListView.builder(

                padding:
                const EdgeInsets.all(10),

                itemCount: docs.length,

                itemBuilder: (
                    context,
                    index,
                    ) {

                  final doc = docs[index];

                  final data = doc.data();

                  final descricao =
                      data['description'] ?? '';

                  final chatId =
                  data['chatId'];

                  final price =
                  data['price'];

                  final pago =
                      data['paid'] ?? false;

                  return Card(

                    margin:
                    const EdgeInsets.only(
                      bottom: 12,
                    ),

                    child: Padding(

                      padding:
                      const EdgeInsets.all(14),

                      child: Column(

                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: [

                          /*
                          ==========================
                          DESCRIÇÃO
                          ==========================
                          */

                          Text(

                            descricao,

                            style:
                            const TextStyle(

                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          /*
                          ==========================
                          PROFISSIONAL
                          ==========================
                          */

                          Text(

                            pago

                                ? 'Profissional: ${data['providerName']}'

                                : 'Profissional: 🔒 bloqueado',
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          /*
                          ==========================
                          VALOR
                          ==========================
                          */

                          if (price != null)

                            Text(

                              'Valor: R\$ $price',

                              style:
                              const TextStyle(

                                color: Colors.green,

                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                          const SizedBox(
                            height: 10,
                          ),

                          /*
                          ==========================
                          BOTÃO PIX
                          ==========================
                          */

                          if (!pago)

                            ElevatedButton(

                              onPressed:

                              loading

                                  ? null

                                  : () async {

                                setState(() {

                                  loading = true;
                                });

                                try {

                                  final response =
                                  await http.post(

                                    Uri.parse(
                                      'http://localhost:3000/criar-pix',
                                    ),

                                    headers: {

                                      'Content-Type':
                                      'application/json'
                                    },

                                    body:
                                    jsonEncode({

                                      'valor':
                                      price ?? 50,

                                      'email':
                                      user.email,
                                    }),
                                  );

                                  final dataPix =
                                  jsonDecode(
                                    response.body,
                                  );

                                  print(
                                    "RETORNO BACKEND => $dataPix",
                                  );

                                  if (dataPix[
                                  'success'] !=
                                      true) {

                                    throw Exception(
                                      dataPix
                                          .toString(),
                                    );
                                  }

                                  // ✅ MOSTRAR PIX NOVO
                                  showDialog(

                                    context:
                                    context,

                                    barrierDismissible:
                                    false,

                                    builder:
                                        (_) =>
                                        PixDialog(

                                          valor:
                                          (price ??
                                              50)
                                              .toDouble(),
                                        ),
                                  );

                                } catch (e) {

                                  ScaffoldMessenger.of(
                                      context)
                                      .showSnackBar(

                                    SnackBar(

                                      content:
                                      Text(
                                        'Erro PIX: $e',
                                      ),
                                    ),
                                  );

                                } finally {

                                  setState(() {

                                    loading =
                                    false;
                                  });
                                }
                              },

                              child: const Text(
                                'Pagar com PIX 💰',
                              ),
                            ),

                          const SizedBox(
                            height: 10,
                          ),

                          /*
                          ==========================
                          CHAT
                          ==========================
                          */

                          if (chatId != null)

                            ElevatedButton(

                              onPressed: () {

                                if (!pago) {

                                  ScaffoldMessenger.of(
                                      context)
                                      .showSnackBar(

                                    const SnackBar(

                                      content: Text(
                                        'Pague antes do chat',
                                      ),
                                    ),
                                  );

                                  return;
                                }

                                Navigator.push(

                                  context,

                                  MaterialPageRoute(

                                    builder: (_) =>
                                        ChatPage(
                                          chatId:
                                          chatId,
                                        ),
                                  ),
                                );
                              },

                              child: const Text(
                                'Abrir chat',
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

          /*
          ==========================
          LOADING
          ==========================
          */

          if (loading)

            Container(

              color: Colors.black26,

              child: const Center(

                child:
                CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
