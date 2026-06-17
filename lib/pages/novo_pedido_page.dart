import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NovoPedidoPage extends StatefulWidget {
  const NovoPedidoPage({super.key});

  @override
  State<NovoPedidoPage> createState() => _NovoPedidoPageState();
}

class _NovoPedidoPageState extends State<NovoPedidoPage> {
  static const _black  = Color(0xFF000000);
  static const _white  = Color(0xFFFFFFFF);

  final _formKey    = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();

  bool _carregando = false;

  final List<String> _categorias = [
    'Elétrica', 'Hidráulica', 'Limpeza', 'Pintura',
    'Informática', 'Mudança', 'Montagem', 'Outro',
  ];
  String? _categoriaSelecionada;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      // Salva pedido no Firestore
      final docRef = await FirebaseFirestore.instance.collection('requests').add({
        'clienteId':    user.uid,
        'titulo':       _tituloCtrl.text.trim(),
        'categoria':    _categoriaSelecionada,
        'status':       'aberto',
        'criadoEm':     FieldValue.serverTimestamp(),
        'providerId':   null,
        'chatId':       null,
        'valorServico': null,
        'comissaoPaga': false,
      });

      // Notifica todos os profissionais
      try {
        await http.post(
          Uri.parse('https://conectapro-backend-y7oe.onrender.com/pedidos/novo-pedido'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'pedidoId':  docRef.id,
            'titulo':    _tituloCtrl.text.trim(),
            'categoria': _categoriaSelecionada ?? '',
          }),
        );
      } catch (_) {
        // Não bloqueia o pedido se a notificação falhar
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido enviado com sucesso!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: _black,
        foregroundColor: _white,
        elevation: 0,
        title: const Text('Novo Pedido',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // TÍTULO
            TextFormField(
              controller: _tituloCtrl,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o título' : null,
              decoration: InputDecoration(
                labelText: 'Título do serviço',
                hintText: 'Ex: Trocar tomada na sala',
                prefixIcon: const Icon(Icons.title, color: Color(0xFF757575)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF276EF1), width: 2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // CATEGORIA
            DropdownButtonFormField<String>(
              value: _categoriaSelecionada,
              decoration: InputDecoration(
                labelText: 'Categoria',
                prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF757575)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF276EF1), width: 2),
                ),
              ),
              items: _categorias
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _categoriaSelecionada = v),
              validator: (v) => v == null ? 'Selecione uma categoria' : null,
            ),

            const SizedBox(height: 32),

            // BOTÃO
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _carregando ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _carregando
                    ? const CircularProgressIndicator(color: _white, strokeWidth: 2)
                    : const Text('Enviar pedido',
                        style: TextStyle(
                            color: _white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}