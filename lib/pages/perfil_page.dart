import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'excluir_conta_page.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  static const _black         = Color(0xFF000000);
  static const _white         = Color(0xFFFFFFFF);
  static const _accent        = Color(0xFF276EF1);
  static const _surface       = Color(0xFFF6F6F6);
  static const _textSecondary = Color(0xFF757575);
  static const _red           = Color(0xFFFF3B30);
  static const _green         = Color(0xFF34C759);

  final _nomeCtrl     = TextEditingController();
  final _telefoneCtrl = TextEditingController();

  bool       _loading      = false;
  bool       _enviandoFoto = false;
  String     _fotoBase64   = '';
  Uint8List? _fotoBytes;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telefoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data != null) {
      final base64Salvo = data['fotoBase64'] ?? '';
      setState(() {
        _nomeCtrl.text  = data['nome']  ?? '';
        _telefoneCtrl.text = data['phone'] ?? data['telefone'] ?? '';
        _fotoBase64     = base64Salvo;
        if (base64Salvo.isNotEmpty) {
          try {
            _fotoBytes = base64Decode(base64Salvo);
          } catch (_) {}
        }
      });
    }
  }

  Future<void> _escolherFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 60,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    if (bytes.lengthInBytes > 900000) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto muito grande! Escolha uma menor.'),
            backgroundColor: _red,
          ),
        );
      }
      return;
    }

    setState(() {
      _fotoBytes    = bytes;
      _enviandoFoto = true;
    });

    try {
      final user      = FirebaseAuth.instance.currentUser!;
      final base64Str = base64Encode(bytes);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fotoBase64': base64Str});

      setState(() => _fotoBase64 = base64Str);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto atualizada! ✅'),
            backgroundColor: _green,
          ),
        );
      }
    } catch (e) {
      setState(() => _fotoBytes = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar foto: $e'),
            backgroundColor: _red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviandoFoto = false);
    }
  }

  Future<void> _salvar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'nome':     _nomeCtrl.text.trim(),
      'phone':    _telefoneCtrl.text.trim(),
      'telefone': _telefoneCtrl.text.trim(),
    });
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado ✅')),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _textSecondary),
      filled: true,
      fillColor: _white,
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
        borderSide: const BorderSide(color: _accent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _black,
        foregroundColor: _white,
        elevation: 0,
        title: const Text(
          'Meu Perfil',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── FOTO ────────────────────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _enviandoFoto ? null : _escolherFoto,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: _accent.withOpacity(0.1),
                      backgroundImage: _fotoBytes != null
                          ? MemoryImage(_fotoBytes!)
                          : null,
                      child: _fotoBytes == null
                          ? Text(
                              _nomeCtrl.text.isNotEmpty
                                  ? _nomeCtrl.text[0].toUpperCase()
                                  : (user?.email?[0].toUpperCase() ?? 'U'),
                              style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w700,
                                  color: _accent),
                            )
                          : null,
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: _white, width: 2),
                      ),
                      child: _enviandoFoto
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                  color: _white, strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt,
                              color: _white, size: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Center(
              child: Text(
                'Toque na foto para alterar',
                style: TextStyle(fontSize: 12, color: _textSecondary),
              ),
            ),

            const SizedBox(height: 32),

            // ── NOME ─────────────────────────────────────────────────────────
            TextField(
              controller: _nomeCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration('Nome completo', Icons.person_outline),
            ),

            const SizedBox(height: 14),

            // ── TELEFONE ──────────────────────────────────────────────────────
            TextField(
              controller: _telefoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration('Telefone / WhatsApp', Icons.phone_outlined),
            ),

            const SizedBox(height: 32),

            // ── BOTÃO SALVAR ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _black,
                  foregroundColor: _white,
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: _white, strokeWidth: 2),
                      )
                    : const Text(
                        'Salvar alterações',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),

            const SizedBox(height: 48),
            const Divider(color: Color(0xFFE0E0E0)),
            const SizedBox(height: 24),

            // ── ZONA DE PERIGO ────────────────────────────────────────────────
            const Text(
              'Zona de perigo',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _textSecondary,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ExcluirContaPage()),
                ),
                icon: const Icon(Icons.delete_outline, color: _red),
                label: const Text(
                  'Excluir minha conta',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}