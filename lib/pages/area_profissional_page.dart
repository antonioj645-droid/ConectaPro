import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import 'ganhos_page.dart';
import 'chat_page.dart';
import 'package:conectapro/pages/pix_dialog.dart';
import 'login_page.dart'; // ✅ IMPORTANTE (precisa existir)

class AreaProfissionalPage extends StatefulWidget {
  const AreaProfissionalPage({super.key});

  @override
  State<AreaProfissionalPage> createState() =>
      _AreaProfissionalPageState();
}

class _AreaProfissionalPageState extends State<AreaProfissionalPage> {

  @override
  void initState() {
    super.initState();
    _salvarLocalizacao();
  }

  Future<void> _salvarLocalizacao() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      });
    } catch (e) {
      debugPrint('Erro ao salvar localização: $e');
    }
  }

  Future<void> adicionarSaldo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final TextEditingController valorCtrl = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Adicionar saldo'),
        content: TextField(
          controller: valorCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Valor (mínimo R\$ 5,00)',
            prefixText: 'R\$ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(
                valorCtrl.text.trim().replaceAll(',', '.'),
              );

              if (v == null || v < 5.0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Valor mínimo é R\$ 5,00'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context, true);
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final double valor = double.parse(
      valorCtrl.text.trim().replaceAll(',', '.'),
    );

    if (!mounted) return;

    final result = await showDialog(
      barrierColor: Colors.black87,
      context: context,
      builder: (_) => PixDialog(valor: valor),
    );

    if (result == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'balance': FieldValue.increment(valor),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saldo +R\$${valor.toStringAsFixed(2)} adicionado ✅',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ✅ FUNÇÃO DE LOGOUT PROFISSIONAL
  Future<void> sair() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Usuário não logado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Profissional'),

        // ✅ REMOVE BOTÃO VOLTAR DEFINITIVO
        automaticallyImplyLeading: false,

        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Adicionar saldo',
            onPressed: adicionarSaldo,
          ),
          IconButton(
            icon: const Icon(Icons.attach_money),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GanhosPage(),
                ),
              );
            },
          ),

          // ✅ BOTÃO SAIR CORRETO
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: sair,
          ),
        ],
      ),

      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              double saldo = 0;

              if (snapshot.hasData && snapshot.data!.exists) {
                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};

                final balance = data['balance'];

                if (balance is num) {
                  saldo = balance.toDouble();
                }
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.black12,
                child: Text(
                  'Saldo: R\$${saldo.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            },
          ),

          const Expanded(
            child: Center(
              child: Text(
                'Pedidos funcionando normal ✅',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
