import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatGatePage extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> data;

  const ChatGatePage({
    super.key,
    required this.requestId,
    required this.data,
  });

  @override
  State<ChatGatePage> createState() => _ChatGatePageState();
}

class _ChatGatePageState extends State<ChatGatePage> {

  bool liberado = false;
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _verificarLiberacao();
  }

  Future<void> _verificarLiberacao() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final requestDoc = await FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId)
        .get();

    final data = requestDoc.data();

    final lista = data?['providersLiberados'] ?? [];
    final clienteId = data?['clienteId'];

    setState(() {
      // ✅ LIBERA: quem pagou OU cliente
      liberado = lista.contains(user.uid) || user.uid == clienteId;
      carregando = false;
    });
  }

  Future<void> _desbloquear() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final preco = 3.0;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final requestRef = FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId);

    final userDoc = await userRef.get();

    double saldo = (userDoc['balance'] ?? 0).toDouble();

    // ✅ CORREÇÃO FORTE: não deixa saldo negativo
    if (saldo <= 0 || saldo < preco) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saldo insuficiente ❌")),
      );
      return;
    }

    // ✅ segurança extra: impedir pagamento duplicado
    final requestDoc = await requestRef.get();
    final lista = requestDoc.data()?['providersLiberados'] ?? [];

    if (lista.contains(user.uid)) {
      setState(() => liberado = true);
      return;
    }

    // 💰 desconta saldo com proteção
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final freshUser = await tx.get(userRef);
      double saldoAtual = (freshUser['balance'] ?? 0).toDouble();

      if (saldoAtual < preco) {
        throw Exception("Saldo insuficiente");
      }

      tx.update(userRef, {
        'balance': FieldValue.increment(-preco),
      });

      tx.update(requestRef, {
        'providersLiberados': FieldValue.arrayUnion([user.uid]),
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Chat liberado ✅")),
    );

    setState(() {
      liberado = true;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    /// ✅ SE LIBERADO → ABRE CHAT
    if (liberado) {
      return Scaffold(
        appBar: AppBar(title: const Text("Chat")),

        body: const Center(
          child: Text("💬 Chat liberado (aqui entra sua tela de chat)"),
        ),
      );
    }

    /// ❌ SE NÃO LIBERADO → BLOQUEIA
    return Scaffold(
      appBar: AppBar(title: const Text("Chat bloqueado")),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Text(
                "🔒 Este chat está bloqueado",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                "Desbloqueie por R\$3 para entrar em contato com o cliente",
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _desbloquear,
                  child: const Text("Desbloquear chat R\$3"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

