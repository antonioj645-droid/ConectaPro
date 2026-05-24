import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String chatId;

  const ChatPage({super.key, required this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final user = FirebaseAuth.instance.currentUser;

  // 🔒 BLOQUEIO HARD
  bool _mensagemValida(String texto) {

    final textoLower = texto.toLowerCase();

    final temNumero = RegExp(r'[0-9]{5,}').hasMatch(texto);

    final numerosExtenso = [
      'zero','um','dois','três','tres','quatro',
      'cinco','seis','sete','oito','nove'
    ];

    final contemExtenso = numerosExtenso.any(
      (n) => textoLower.contains(n),
    );

    final palavras = [
      'whatsapp','zap','telefone','numero',
      'contato','pix','ligar','chama'
    ];

    final contemPalavra = palavras.any(
      (p) => textoLower.contains(p),
    );

    return !(temNumero || contemExtenso || contemPalavra);
  }

  // 💰 ENVIAR PROPOSTA
  Future<void> _enviarProposta(double valor) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'type': 'proposal',
      'price': valor,
      'senderId': user?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ✅ ENVIAR MENSAGEM NORMAL
  Future<void> _sendMessage() async {

    final texto = _msgController.text.trim();

    if (texto.isEmpty) return;

    if (!_mensagemValida(texto)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não é permitido compartilhar contato ❌'),
        ),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': texto,
      'senderId': user?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),

      body: Column(
        children: [

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),

              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final msgs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {

                    final data = msgs[index].data();
                    final isMe = data['senderId'] == user?.uid;
                    final isProposal = data['type'] == 'proposal';

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,

                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.deepPurple
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),

                        child: isProposal
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    '💰 Proposta: R\$ ${data['price']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  // ✅ ACEITAR PROPOSTA + TAXA
                                  ElevatedButton(
                                    onPressed: () async {

                                      final query = await FirebaseFirestore
                                          .instance
                                          .collection('requests')
                                          .where('chatId',
                                              isEqualTo: widget.chatId)
                                          .get();

                                      if (query.docs.isNotEmpty) {

                                        final docId = query.docs.first.id;

                                        final double valor =
                                            (data['price'] ?? 0).toDouble();

                                        final double taxa = valor * 0.07;
                                        final double liquido =
                                            valor - taxa;

                                        await FirebaseFirestore.instance
                                            .collection('requests')
                                            .doc(docId)
                                            .update({
                                          'price': valor,
                                          'tax': taxa,
                                          'providerValue': liquido,
                                          'status': 'accepted',
                                        });

                                        // 💰 REGISTRA SEU GANHO
                                        await FirebaseFirestore.instance
                                            .collection('earnings')
                                            .add({
                                          'requestId': docId,
                                          'total': valor,
                                          'tax': taxa,
                                          'createdAt': FieldValue.serverTimestamp(),
                                        });
                                      }

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Proposta aceita ✅💰'),
                                        ),
                                      );
                                    },
                                    child: const Text('Aceitar'),
                                  ),
                                ],
                              )
                            : Text(
                                data['text'] ?? '',
                                style: TextStyle(
                                  color:
                                      isMe ? Colors.white : Colors.black,
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),

            child: Row(
              children: [

                // 💰 PROPOSTA
                IconButton(
                  icon: const Icon(Icons.attach_money,
                      color: Colors.green),
                  onPressed: () {

                    final controller = TextEditingController();

                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Enviar proposta'),

                        content: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Valor (R\$)',
                          ),
                        ),

                        actions: [

                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),

                          ElevatedButton(
                            onPressed: () {

                              final valor =
                                  double.tryParse(controller.text);

                              if (valor == null) return;

                              _enviarProposta(valor);
                              Navigator.pop(context);
                            },
                            child: const Text('Enviar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: 'Digite uma mensagem...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
