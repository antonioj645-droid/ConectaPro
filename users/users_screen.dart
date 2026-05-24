import 'package:flutter/material.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários'),
      ),
      body: const Center(
        child: Text(
          'Tela de Usuários',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}