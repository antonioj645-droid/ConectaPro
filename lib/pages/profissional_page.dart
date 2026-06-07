import 'package:flutter/material.dart';

class ProfissionalPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProfissionalPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profissional"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              data['nome'] ?? 'Sem nome',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text("📞 ${data['telefone'] ?? 'Sem telefone'}"),

            const SizedBox(height: 10),

            Text("📍 ${data['cidade'] ?? 'Sem cidade'}"),

            const SizedBox(height: 10),

            Text("🔧 ${data['servico'] ?? 'Serviço não informado'}"),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // 🔥 aqui depois vai WhatsApp
                },
                child: const Text("Contratar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
