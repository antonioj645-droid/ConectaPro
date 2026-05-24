import 'package:flutter/material.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Serviços')),
      body: const Center(
        child: Text('Tela de Serviços', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
