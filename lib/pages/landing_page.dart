import 'package:flutter/material.dart';
import '../main.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1F44),

      body: SafeArea(
        child: Column(
          children: [

            const SizedBox(height: 40),

            // 🔥 TÍTULO
            const Text(
              "CONECTA",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Text(
              "PRO",
              style: TextStyle(
                color: Colors.blue,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Conectando pessoas. Gerando oportunidades.",
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // 🔥 ÍCONE CENTRAL
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: const Icon(Icons.all_inclusive, color: Colors.white, size: 40),
            ),

            const SizedBox(height: 10),

            const Text(
              "A CONEXÃO QUE TRANSFORMA",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            // 🔥 CLIENTE E PROFISSIONAL
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                Column(
                  children: [
                    Icon(Icons.person, color: Colors.blue),
                    SizedBox(height: 6),
                    Text("CLIENTE", style: TextStyle(color: Colors.blue)),
                    Text("Busca soluções", style: TextStyle(color: Colors.white70)),
                  ],
                ),

                Column(
                  children: [
                    Icon(Icons.build, color: Colors.green),
                    SizedBox(height: 6),
                    Text("PROFISSIONAL", style: TextStyle(color: Colors.green)),
                    Text("Oferece soluções", style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),

            const Spacer(),

            // 🔥 FEATURES
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("Confiança", style: TextStyle(color: Colors.white70)),
                Text("Qualidade", style: TextStyle(color: Colors.white70)),
                Text("Crescimento", style: TextStyle(color: Colors.white70)),
              ],
            ),

            const SizedBox(height: 20),

            // 🔥 BOTÃO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AuthCheck(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Entrar"),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}