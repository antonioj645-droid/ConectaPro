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

  // ✅ ENVIAR MENSAGEM
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
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // ✅ limpa campo + para typing
    controller.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .set({
      'typing': null,
    }, SetOptions(merge: true));
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
  void dispose() {
    controller.dispose();

    // ✅ parar typing ao sair
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .set({
      'typing': null,
    }, SetOptions(merge: true));

    super.dispose();
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

          // ✅ MOSTRAR "DIGITANDO..."
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(widget.chatId)
                .snapshots(),
            builder: (_, snapshot) {

              final data =
                  snapshot.data?.data() as Map<String, dynamic>?;

              final typingUser = data?['typing'];

              if (typingUser != null &&
                  typingUser != user?.uid) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    "Digitando...",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return const SizedBox();
            },
          ),

          // ✅ CHAT
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),

              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                // ✅ marcar como lido
                marcarComoLido();

                // ✅ SCROLL AUTOMÁTICO
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollController.hasClients) {
                    scrollController.animateTo(
                      scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
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

                            // ✅ CHECK ✔✔
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

          // ✅ INPUT
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: controller,

                    // ✅ DETECTAR DIGITAÇÃO
                    onChanged: (text) async {
                      final user = FirebaseAuth.instance.currentUser;

                      await FirebaseFirestore.instance
                          .collection('chats')
                          .doc(widget.chatId)
                          .set({
                        'typing': text.isNotEmpty ? user?.uid : null,
                      }, SetOptions(merge: true));
                    },

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