import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class MeuPerfilProfissionalPage extends StatefulWidget {
  const MeuPerfilProfissionalPage({super.key});

  @override
  State<MeuPerfilProfissionalPage> createState() =>
      _MeuPerfilProfissionalPageState();
}

class _MeuPerfilProfissionalPageState
    extends State<MeuPerfilProfissionalPage> {
  static const _black         = Color(0xFF000000);
  static const _white         = Color(0xFFFFFFFF);
  static const _accent        = Color(0xFF276EF1);
  static const _surface       = Color(0xFFF6F6F6);
  static const _textSecondary = Color(0xFF757575);
  static const _green         = Color(0xFF34C759);
  static const _red           = Color(0xFFFF3B30);
  static const _gold          = Color(0xFFFFCC00);

  final _nomeCtrl      = TextEditingController();
  final _telefoneCtrl  = TextEditingController();
  final _categoriaCtrl = TextEditingController();
  final _bioCtrl       = TextEditingController();

  String _fotoUrl      = '';
  String _fotoBase64   = '';
  bool   _carregando   = true;
  bool   _salvando     = false;
  bool   _enviandoFoto = false;
  bool   _verificado   = false;

  Uint8List? _fotoBytes;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telefoneCtrl.dispose();
    _categoriaCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarPerfil() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      _nomeCtrl.text      = data['nome']       ?? '';
      _telefoneCtrl.text  = data['telefone']   ?? '';
      _categoriaCtrl.text = data['categoria']  ?? data['especialidade'] ?? '';
      _bioCtrl.text       = data['bio']        ?? data['descricao'] ?? '';
      _fotoUrl            = data['fotoUrl']    ?? data['photoUrl'] ?? '';
      _fotoBase64         = data['fotoBase64'] ?? '';
      _verificado         = data['verificado'] ?? false;

      // Se tem base64 salvo, carrega como bytes
      if (_fotoBase64.isNotEmpty) {
        _fotoBytes = base64Decode(_fotoBase64);
      }
    }

    setState(() => _carregando = false);
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

    // Verifica tamanho — Firestore suporta até ~1MB por campo
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
      final user = FirebaseAuth.instance.currentUser!;
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

  Future<void> _salvarPerfil() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _salvando = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'nome':      _nomeCtrl.text.trim(),
        'telefone':  _telefoneCtrl.text.trim(),
        'categoria': _categoriaCtrl.text.trim(),
        'bio':       _bioCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil salvo com sucesso! ✅'),
            backgroundColor: _green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: _red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  ImageProvider? get _imagemAtual {
    if (_fotoBytes != null) return MemoryImage(_fotoBytes!);
    if (_fotoUrl.isNotEmpty) return NetworkImage(_fotoUrl);
    return null;
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
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  if (_verificado)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFCC00), Color(0xFFFF9500)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFCC00).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Profissional Verificado',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!_verificado)
                    _buildProgressoVerificacao(user?.uid ?? ''),

                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: _enviandoFoto ? null : _escolherFoto,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: _accent.withOpacity(0.1),
                          backgroundImage: _imagemAtual,
                          child: _imagemAtual == null
                              ? Text(
                                  _nomeCtrl.text.isNotEmpty
                                      ? _nomeCtrl.text[0].toUpperCase()
                                      : (user?.email?[0].toUpperCase() ?? 'P'),
                                  style: const TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w700,
                                      color: _accent),
                                )
                              : null,
                        ),
                        Container(
                          width: 36,
                          height: 36,
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
                                  color: _white, size: 18),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Text(
                    'Toque na foto para alterar',
                    style: TextStyle(fontSize: 12, color: _textSecondary),
                  ),

                  const SizedBox(height: 28),

                  _campo(
                    controller: _nomeCtrl,
                    label: 'Nome completo',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  _campo(
                    controller: _telefoneCtrl,
                    label: 'Telefone / WhatsApp',
                    icon: Icons.phone_outlined,
                    tipo: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  _campo(
                    controller: _categoriaCtrl,
                    label: 'Especialidade (ex: Encanador, Eletricista)',
                    icon: Icons.build_outlined,
                  ),
                  const SizedBox(height: 14),
                  _campo(
                    controller: _bioCtrl,
                    label: 'Sobre você',
                    icon: Icons.description_outlined,
                    linhas: 4,
                    hint: 'Conte um pouco sobre sua experiência...',
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: _salvando ? null : _salvarPerfil,
                      child: _salvando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: _white, strokeWidth: 2),
                            )
                          : const Text(
                              'Salvar perfil',
                              style: TextStyle(
                                  color: _white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  _buildAvaliacoes(user?.uid ?? ''),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressoVerificacao(String uid) {
    if (uid.isEmpty) return const SizedBox();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        final total = ((data['totalAvaliacoes'] ?? 0) as num).toInt();
        final media = ((data['mediaAvaliacao'] ?? 0) as num).toDouble();

        final progressoAval = (total / 5).clamp(0.0, 1.0);
        final atingiuMeta   = total >= 5 && media >= 4.5;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_outlined,
                      color: Color(0xFFFFCC00), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Progresso para Verificado',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF000000)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressoAval,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE5E5E5),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFCC00)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$total / 5 avaliações',
                    style: const TextStyle(
                        fontSize: 12, color: _textSecondary),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 13, color: Color(0xFFFFCC00)),
                      const SizedBox(width: 2),
                      Text(
                        media > 0
                            ? '${media.toStringAsFixed(1)} / 4.5 mínimo'
                            : 'Sem avaliações ainda',
                        style: const TextStyle(
                            fontSize: 12, color: _textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              if (atingiuMeta) ...[
                const SizedBox(height: 8),
                const Text(
                  '🎉 Parabéns! Você será verificado em breve.',
                  style: TextStyle(
                      fontSize: 12,
                      color: _green,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType tipo = TextInputType.text,
    int linhas = 1,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: tipo,
      maxLines: linhas,
      style: const TextStyle(fontSize: 14, color: _black),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: _textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: _accent, size: 20),
        filled: true,
        fillColor: _white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: _textSecondary, fontSize: 13),
      ),
    );
  }

  Widget _buildAvaliacoes(String uid) {
    if (uid.isEmpty) return const SizedBox();

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('requests')
          .where('providerId', isEqualTo: uid)
          .where('status', isEqualTo: 'concluido')
          .get(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();

        final docs = snap.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['avaliacao'] != null;
        }).toList();

        if (docs.isEmpty) return const SizedBox();

        final soma = docs.fold<double>(
            0, (acc, d) => acc + ((d.data() as Map)['avaliacao'] as num));
        final media = soma / docs.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Minhas avaliações',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _black),
                ),
                const Spacer(),
                const Icon(Icons.star, color: _gold, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${media.toStringAsFixed(1)} (${docs.length})',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _black),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...docs.map((doc) {
              final data       = doc.data() as Map<String, dynamic>;
              final nota       = (data['avaliacao'] as num).toInt();
              final comentario = data['comentario'] ?? '';
              final titulo     = data['titulo'] ?? data['descricao'] ?? 'Serviço';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < nota ? Icons.star : Icons.star_border,
                          color: _gold,
                          size: 16,
                        ),
                      ),
                    ),
                    if (titulo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(titulo,
                          style: const TextStyle(
                              fontSize: 12,
                              color: _accent,
                              fontWeight: FontWeight.w600)),
                    ],
                    if (comentario.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(comentario,
                          style: const TextStyle(
                              fontSize: 13, color: _textSecondary)),
                    ],
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}