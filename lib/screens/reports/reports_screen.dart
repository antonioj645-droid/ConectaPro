import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
      ),
      body: const Center(
        child: Text(
          'Tela de Relatórios',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}