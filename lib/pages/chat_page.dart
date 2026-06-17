import 'dart:convert';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  final String chatId;
  const ChatPage({super.key, required this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const _black         = Color(0xFF000000);
  static const _white         = Color(0xFFFFFFFF);
  static const _accent        = Color(0xFF276EF1);
  static const _green         = Color(0xFF34C759);
  static const _surface       = Color(0xFFF6F6F6);
  static const _textSecondary = Color(0xFF757575);

  final TextEditingController _msgCtrl   = TextEditingController();
  final TextEditingController _valorCtrl = TextEditingController();
  final ScrollController _scrollCtrl     = ScrollController();

  bool _enviando     = false;
  bool _finalizando  = false;

  // ─── Enviar mensagem normal ───────────────────────────────────────────────
  Future<void> _enviarMensagem() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final texto = _msgCtrl.text.trim();
    if (texto.isEmpty) return;

    setState(() => _enviando = true);
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'text':      texto,
        'senderId':  user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead':    false,
        'tipo':      'texto',
      });

      _msgCtrl.clear();
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .set({'typing': null}, SetOptions(merge: true));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  // ─── Profissional define o valor ─────────────────────────────────────────
  Future<void> _definirValor(String pedidoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _valorCtrl.clear();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Definir valor do serviço',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: _valorCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Valor (R\$)',
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final valor = double.tryParse(
                  _valorCtrl.text.trim().replaceAll(',', '.'));
              if (valor == null || valor <= 0) return;

              // Salva valor no pedido
              await FirebaseFirestore.instance
                  .collection('requests')
                  .doc(pedidoId)
                  .update({'valorServico': valor});

              // Envia mensagem especial no chat
              await FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .add({
                'text':      'R\$ ${valor.toStringAsFixed(2)}',
                'senderId':  user.uid,
                'createdAt': FieldValue.serverTimestamp(),
                'isRead':    false,
                'tipo':      'valor_proposto',
                'valor':     valor,
              });

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Enviar proposta',
                style: TextStyle(color: _white)),
          ),
        ],
      ),
    );
  }

  // ─── Finalizar serviço (cobra 7% via backend) ────────────────────────────
  Future<void> _finalizarServico(String pedidoId, double valorServico) async {
    final comissao = valorServico * 0.07;

    // Confirmar
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Finalizar serviço',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valor do serviço: R\$ ${valorServico.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text(
              'Comissão (7%): R\$ ${comissao.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Esse valor será descontado da sua carteira.',
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar e finalizar',
                style: TextStyle(color: _white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    setState(() => _finalizando = true);

    try {
      // ✅ Chama backend — validação de saldo e comissão acontece com segurança
      final uri = Uri.https(
        'conectapro-backend-1.onrender.com',
        '/pedidos/finalizar-servico/$pedidoId',
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['erro'] ?? 'Erro ao finalizar');
      }

      // Mensagem de conclusão no chat
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'text':      'Serviço finalizado ✅',
        'senderId':  FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead':    false,
        'tipo':      'sistema',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Serviço finalizado! Comissão de R\$ ${comissao.toStringAsFixed(2)} descontada.'),
          backgroundColor: _green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('Saldo insuficiente')
              ? '💰 Saldo insuficiente! Adicione créditos na carteira para finalizar.'
              : e.toString().contains('Valor do serviço não definido')
                ? '⚠️ Defina o valor do serviço antes de finalizar.'
                : 'Erro ao finalizar: $e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _finalizando = false);
    }
  }

  Future<void> _marcarComoLido() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();
    for (var doc in snap.docs) {
      if (doc.data()['senderId'] != user.uid) {
        doc.reference.update({'isRead': true});
      }
    }
  }

  void _scrollParaBaixo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _valorCtrl.dispose();
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .set({'typing': null}, SetOptions(merge: true));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _black,
        foregroundColor: _white,
        elevation: 0,
        title: const Text('Chat',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // Busca o pedido vinculado ao chatId
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('chatId', isEqualTo: widget.chatId)
            .limit(1)
            .snapshots()
            .map((s) => s.docs.isNotEmpty ? s.docs.first : null)
            .where((d) => d != null)
            .cast<DocumentSnapshot>(),
        builder: (context, snapPedido) {
          final pedidoData =
              snapPedido.data?.data() as Map<String, dynamic>?;
          final pedidoId      = snapPedido.data?.id;
          final valorServico  = (pedidoData?['valorServico'] as num?)?.toDouble();
          final status        = pedidoData?['status'] ?? 'aberto';
          final providerId    = pedidoData?['providerId'] ?? '';
          final isProfissional = user?.uid == providerId;
          final isConcluido   = status == 'concluido';

          return Column(
            children: [

              // ─── Banner valor proposto ──────────────────────────────────
              if (valorServico != null && !isConcluido)
                Container(
                  color: const Color(0xFFE8F5E9),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_money,
                          color: _green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Valor do serviço: R\$ ${valorServico.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: _green,
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),

              // ─── Banner concluído ───────────────────────────────────────
              if (isConcluido)
                Container(
                  color: const Color(0xFFE8F5E9),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: _green, size: 20),
                      SizedBox(width: 8),
                      Text('Serviço concluído ✅',
                          style: TextStyle(
                              color: _green,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),

              // ─── Digitando ─────────────────────────────────────────────
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatId)
                    .snapshots(),
                builder: (_, snap) {
                  final d = snap.data?.data() as Map<String, dynamic>?;
                  final typing = d?['typing'];
                  if (typing != null && typing != user?.uid) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Digitando...',
                            style: TextStyle(
                                color: _textSecondary, fontSize: 12)),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),

              // ─── Mensagens ─────────────────────────────────────────────
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatId)
                      .collection('messages')
                      .orderBy('createdAt', descending: false)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: _accent));
                    }

                    final docs = snap.data!.docs;
                    _marcarComoLido();
                    _scrollParaBaixo();

                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final data =
                            docs[i].data() as Map<String, dynamic>;
                        final isMe = data['senderId'] == user?.uid;
                        final tipo = data['tipo'] ?? 'texto';

                        // Mensagem de sistema
                        if (tipo == 'sistema') {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  data['text'] ?? '',
                                  style: const TextStyle(
                                      color: _green,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                              ),
                            ),
                          );
                        }

                        // Mensagem de valor proposto
                        if (tipo == 'valor_proposto') {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E1),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.amber.shade300),
                                ),
                                child: Column(
                                  children: [
                                    const Text('💰 Proposta de valor',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'R\$ ${(data['valor'] as num).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: _green),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Pagamento combinado fora do app',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: _textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        // Mensagem normal
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width *
                                      0.72,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? _black : _white,
                              borderRadius: BorderRadius.only(
                                topLeft:
                                    const Radius.circular(16),
                                topRight:
                                    const Radius.circular(16),
                                bottomLeft: Radius.circular(
                                    isMe ? 16 : 4),
                                bottomRight: Radius.circular(
                                    isMe ? 4 : 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromRGBO(
                                      0, 0, 0, 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    data['text'] ?? '',
                                    style: TextStyle(
                                      color: isMe
                                          ? _white
                                          : _black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (isMe)
                                  Icon(
                                    data['isRead'] == true
                                        ? Icons.done_all
                                        : Icons.done,
                                    size: 14,
                                    color: data['isRead'] == true
                                        ? _accent
                                        : Colors.white54,
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

              // ─── Botões do profissional ────────────────────────────────
              if (isProfissional && !isConcluido && pedidoId != null)
                Container(
                  color: _white,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      // Definir valor — bloqueado se já definiu
                      if (valorServico == null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _definirValor(pedidoId),
                            icon: const Icon(Icons.attach_money, size: 16),
                            label: const Text('Definir valor'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _accent,
                              side: const BorderSide(color: _accent),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      if (valorServico != null) ...[
                        const SizedBox(width: 8),
                        // Finalizar
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _finalizando
                                ? null
                                : () => _finalizarServico(pedidoId, valorServico),
                            icon: _finalizando
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: _white))
                                : const Icon(Icons.check_circle_outline, size: 16),
                            label: Text(_finalizando ? 'Aguarde...' : 'Finalizar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: _white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // ─── Input de mensagem ─────────────────────────────────────
              if (!isConcluido)
                Container(
                  color: _white,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          onChanged: (text) async {
                            await FirebaseFirestore.instance
                                .collection('chats')
                                .doc(widget.chatId)
                                .set({
                              'typing': text.isNotEmpty
                                  ? user?.uid
                                  : null,
                            }, SetOptions(merge: true));
                          },
                          decoration: InputDecoration(
                            hintText: 'Digite uma mensagem...',
                            hintStyle: const TextStyle(
                                color: _textSecondary),
                            filled: true,
                            fillColor: _surface,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _enviando ? null : _enviarMensagem,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _black,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: _enviando
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                      color: _white, strokeWidth: 2),
                                )
                              : const Icon(Icons.send,
                                  color: _white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}