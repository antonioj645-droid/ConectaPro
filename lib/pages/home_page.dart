import 'package:flutter/material.dart';

import 'package:conectapro/pages/pix_dialog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ConectaPro'),
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => PixDialog(
                valor: 30,
              ),
            );
          },
          icon: const Icon(Icons.pix),
          label: const Text('Pagar com PIX'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}
