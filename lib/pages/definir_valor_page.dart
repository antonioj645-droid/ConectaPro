import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DefinirValorPage extends StatefulWidget {
  final String requestId;

  const DefinirValorPage({super.key, required this.requestId});

  @override
  State<DefinirValorPage> createState() => _DefinirValorPageState();
}

class _DefinirValorPageState extends State<DefinirValorPage> {

  final controller = TextEditingController();
  bool loading = false;

  Future<void> salvar() async {
    final valor = double.tryParse(controller.text);
    if (valor == null) return;

    setState(() => loading = true);

    await FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId)
        .update({
      'valorServico': valor,
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Definir valor")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Valor do serviço",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : salvar,
              child: const Text("Enviar para cliente"),
            )
          ],
        ),
      ),
    );
  }
}