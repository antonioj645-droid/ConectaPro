import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  Future<void> _createRequest(BuildContext context) async {
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Novo pedido'),
        content: TextField(
          controller: descController,
          decoration: const InputDecoration(
            labelText: 'Descrição do serviço',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            child: const Text('Enviar'),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser!;
              final text = descController.text.trim();

              if (text.isEmpty) return;

              await FirebaseFirestore.instance
                  .collection('requests')
                  .add({
                'clientId': user.uid,
                'description': text,
                'status': 'open',
                'createdAt': Timestamp.now(),
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pedido criado com sucesso ✅'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área do Cliente'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bem-vindo, Cliente 👋',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Solicitar novo serviço'),
              onPressed: () => _createRequest(context),
            ),
          ],
        ),
      ),
    );
  }
}