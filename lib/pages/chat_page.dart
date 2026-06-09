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

  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  Future<void> enviarMensagem() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final texto = controller.text.trim();
    if (texto.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': texto,
      'senderId': user.uid,
      'createdAt': FieldValue.serverTimestamp(), // ✅ PADRÃO
      'isRead': false, // ✅ NOVO (✔✔)
    });

    controller.clear();

    await Future.delayed(const Duration(milliseconds: 200));

    scrollController.jumpTo(
      scrollController.position.maxScrollExtent,
    );
  }

  // ✅ MARCAR COMO LIDO (✔✔)
  Future<void> marcarComoLido() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['senderId'] != user.uid) {
        doc.reference.update({'isRead': true});
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),

      body: Column(
        children: [

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: false) // ✅ ORDEM CORRETA
                  .snapshots(),

              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                // ✅ marca como lido sempre que atualizar
                marcarComoLido();

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollController.hasClients) {
                    scrollController.jumpTo(
                      scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {

                    final data =
                        docs[index].data() as Map<String, dynamic>;

                    final isMe = data['senderId'] == user?.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,

                      child: Container(
                        margin:
                        const EdgeInsets.symmetric(vertical: 4),

                        padding: const EdgeInsets.all(10),

                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.deepPurple
                              : Colors.grey[300],
                          borderRadius:
                          BorderRadius.circular(12),
                        ),

                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            Text(
                              data['text'] ?? '',
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),

                            const SizedBox(width: 5),

                            // ✅ CHECK ✔✔ estilo WhatsApp
                            if (isMe)
                              Icon(
                                data['isRead'] == true
                                    ? Icons.done_all
                                    : Icons.done,
                                size: 16,
                                color: data['isRead'] == true
                                    ? Colors.blue
                                    : Colors.white,
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

          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Digite uma mensagem...',
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: enviarMensagem,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}