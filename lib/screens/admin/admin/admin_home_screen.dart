import 'package:flutter/material.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área Administrativa'),
      ),
      body: const Center(
        child: Text(
          'Bem-vindo ao ConectaPro 🚀',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}