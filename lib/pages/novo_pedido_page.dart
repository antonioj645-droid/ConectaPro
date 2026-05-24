import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NovoPedidoPage extends StatefulWidget {
  const NovoPedidoPage({super.key});

  @override
  State<NovoPedidoPage> createState() => _NovoPedidoPageState();
}

class _NovoPedidoPageState extends State<NovoPedidoPage> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _priceController = TextEditingController(); // 💰 NOVO

  bool _carregando = false;

  String _categoriaSelecionada = 'Elétrica';

  final List<String> categorias = [
    'Elétrica',
    'Hidráulica',
    'Pintura',
    'Limpeza',
    'Informática',
    'Outros',
  ];

  Future<void> _criarPedido() async {

    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado')),
      );
      return;
    }

    setState(() => _carregando = true);

    try {

      // ✅ pegar nome do cliente
      final docUser = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final nome = docUser.data()?['nome'] ?? user.email;

      await FirebaseFirestore.instance.collection('requests').add({
        'clientId': user.uid,
        'clientName': nome, // ✅ importante para mostrar depois
        'description': _descricaoController.text.trim(),
        'category': _categoriaSelecionada,
        'status': 'open',

        // 💰 PREÇO AUTOMÁTICO
        'price': double.tryParse(_priceController.text) ?? 0,

        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido criado com sucesso ✅')),
      );

      // ✅ limpar campos
      _descricaoController.clear();
      _priceController.clear();

      Navigator.pop(context);

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar pedido: $e')),
      );

    } finally {

      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _priceController.dispose(); // ✅ limpar memória
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Pedido'),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey,

          child: Column(
            children: [

              // ✅ CATEGORIA
              DropdownButtonFormField<String>(
                value: _categoriaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                items: categorias.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaSelecionada = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // ✅ DESCRIÇÃO
              TextFormField(
                controller: _descricaoController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Descrição do problema',
                  hintText: 'Explique detalhadamente o problema...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a descrição';
                  }
                  if (value.trim().length < 10) {
                    return 'Descrição muito curta';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 💰 CAMPO DE PREÇO (NOVO)
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor do serviço (R\$)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o valor';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Valor inválido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // ✅ BOTÃO
              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(
                  onPressed: _carregando ? null : _criarPedido,
                  child: _carregando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Criar Pedido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
