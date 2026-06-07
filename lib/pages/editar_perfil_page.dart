import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarPerfilPage extends StatefulWidget {
  const EditarPerfilPage({super.key});

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {

  final nomeController = TextEditingController();
  final telefoneController = TextEditingController();
  final cidadeController = TextEditingController();
  final enderecoController = TextEditingController();
  final servicoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();

    nomeController.text = data?['nome'] ?? '';
    telefoneController.text = data?['telefone'] ?? '';
    cidadeController.text = data?['cidade'] ?? '';
    enderecoController.text = data?['endereco'] ?? '';
    servicoController.text = data?['servico'] ?? '';
  }

  Future<void> _salvar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'nome': nomeController.text,
      'telefone': telefoneController.text,
      'cidade': cidadeController.text,
      'endereco': enderecoController.text,
      'servico': servicoController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Dados atualizados ✅")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: telefoneController,
              decoration: const InputDecoration(labelText: 'Telefone'),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: cidadeController,
              decoration: const InputDecoration(labelText: 'Cidade'),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: enderecoController,
              decoration: const InputDecoration(labelText: 'Endereço'),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: servicoController,
              decoration: const InputDecoration(labelText: 'Serviço'),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvar,
                child: const Text("Salvar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}