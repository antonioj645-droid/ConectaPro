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
  // ─── Tema (mesmo padrão navy usado no resto do app) ─────────────────────────
  static const _black         = Color(0xFF0A0A12);
  static const _navyDark      = Color(0xFF0A0A16);
  static const _white         = Color(0xFFFFFFFF);
  static const _accent        = Color(0xFF2F6FED);
  static const _surface       = Color(0xFFF3F4F8);
  static const _textSecondary = Color(0xFF6B7280);
  static const _green         = Color(0xFF34C759);
  static const _red           = Color(0xFFFF3B30);
  static const _gold          = Color(0xFFFFCC00);
  static const _orange        = Color(0xFFFF9500);

  final _nomeCtrl      = TextEditingController();
  final _telefoneCtrl  = TextEditingController();
  final _categoriaCtrl = TextEditingController();
  final _bioCtrl       = TextEditingController();
  final _placaCtrl     = TextEditingController();

  String _fotoUrl      = '';
  String _fotoBase64   = '';
  bool   _carregando   = true;
  bool   _salvando     = false;
  bool   _enviandoFoto = false;
  bool   _verificado   = false;

  Uint8List? _fotoBytes;

  // ─── Documentos (entregador, guincho e frete) ───────────────────────────────
  // Ficam numa coleção separada (docs_entregador), NUNCA no doc público 'users'.
  String _tipoVeiculo      = 'Moto';
  String _statusDocs       = ''; // '', 'pendente', 'aprovado', 'reprovado'
  String _motivoReprovacao = '';
  bool   _enviandoDocs     = false;

  final Map<String, Uint8List> _docsBytes = {};
  final Set<String> _docsAlterados = {};

  // Usada para rolar a tela direto até a seção de documentos
  final GlobalKey _docsKey = GlobalKey();

  static const List<String> _tiposVeiculo = [
    'Moto',
    'Carro',
    'Van / Utilitário',
    'Caminhão',
    'Guincho / Reboque',
  ];

  // Atalhos de especialidade que exigem documentos (um toque preenche o campo)
  static const List<String> _atalhosDocs = [
    'Entregador / Moto',
    'Guincho',
    'Frete',
  ];

  // Limite por imagem (o doc do Firestore aceita ~1MB, e o base64 aumenta ~33%)
  static const int _limiteBytesDoc = 600000;

  @override
  void initState() {
    super.initState();
    // Atualiza a tela quando o profissional digita a especialidade,
    // para mostrar/esconder o aviso e a seção de documentos.
    _categoriaCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _carregarPerfil();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telefoneCtrl.dispose();
    _categoriaCtrl.dispose();
    _bioCtrl.dispose();
    _placaCtrl.dispose();
    super.dispose();
  }

  // Como a especialidade é texto livre, detecta pelo texto digitado.
  // Vale para entregador/moto, guincho e frete.
  bool get _exigeDocs {
    final c = _categoriaCtrl.text.toLowerCase();
    return c.contains('entreg') ||
        c.contains('motoboy') ||
        c.contains('delivery') ||
        c.contains('guincho') ||
        c.contains('reboque') ||
        c.contains('frete') ||
        c.contains('carreto');
  }

  bool _atalhoSelecionado(String esp) {
    final c = _categoriaCtrl.text.toLowerCase();
    if (esp.startsWith('Entreg')) return c.contains('entreg');
    return c.contains(esp.toLowerCase());
  }

  String _veiculoPadrao(String esp) {
    final e = esp.toLowerCase();
    if (e.contains('guincho')) return 'Guincho / Reboque';
    if (e.contains('frete')) return 'Van / Utilitário';
    return 'Moto';
  }

  void _escolherEspecialidade(String esp) {
    setState(() {
      _categoriaCtrl.text = esp;
      // Só sugere o tipo de veículo se ainda não enviou documentos
      if (_statusDocs.isEmpty) _tipoVeiculo = _veiculoPadrao(esp);
    });
  }

  void _irParaDocs() {
    final ctx = _docsKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.03,
    );
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

    await _carregarDocsEntregador(user.uid);

    setState(() => _carregando = false);
  }

  Future<void> _carregarDocsEntregador(String uid) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('docs_entregador')
          .doc(uid);
      final doc = await ref.get();
      if (!doc.exists) return;

      final d = doc.data()!;
      _placaCtrl.text   = (d['placa'] ?? '') as String;
      _tipoVeiculo      = (d['tipoVeiculo'] ?? 'Moto') as String;
      _statusDocs       = (d['status'] ?? '') as String;
      _motivoReprovacao = (d['motivoReprovacao'] ?? '') as String;
      if (!_tiposVeiculo.contains(_tipoVeiculo)) _tipoVeiculo = 'Moto';

      final arquivos = await ref.collection('arquivos').get();
      for (final a in arquivos.docs) {
        final b64 = (a.data()['base64'] ?? '') as String;
        if (b64.isNotEmpty) _docsBytes[a.id] = base64Decode(b64);
      }
    } catch (_) {
      // Se falhar (ex: regras ainda não publicadas), a seção só aparece vazia.
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

  // ─── Documentos: escolher imagem ────────────────────────────────────────────
  Future<void> _escolherDoc(String tipo) async {
    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _accent),
              title: const Text('Tirar foto agora'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _accent),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (origem == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: origem,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 50,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      if (bytes.lengthInBytes > _limiteBytesDoc) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagem muito grande! Tire outra foto com menos zoom.'),
              backgroundColor: _red,
            ),
          );
        }
        return;
      }

      setState(() {
        _docsBytes[tipo] = bytes;
        _docsAlterados.add(tipo);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir a imagem: $e'),
            backgroundColor: _red,
          ),
        );
      }
    }
  }

  // Aceita placa antiga (ABC1234) e Mercosul (ABC1D23)
  String _normalizarPlaca(String s) =>
      s.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

  bool _placaValida(String placa) {
    final antiga   = RegExp(r'^[A-Z]{3}[0-9]{4}$');
    final mercosul = RegExp(r'^[A-Z]{3}[0-9][A-Z][0-9]{2}$');
    return antiga.hasMatch(placa) || mercosul.hasMatch(placa);
  }

  void _avisoErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _red),
    );
  }

  Future<void> _enviarDocs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final placa = _normalizarPlaca(_placaCtrl.text);
    if (!_placaValida(placa)) {
      _avisoErro('Placa inválida. Use o formato ABC-1234 ou ABC1D23.');
      return;
    }
    if (!_docsBytes.containsKey('selfie')) {
      _avisoErro('Falta a selfie (foto do seu rosto).');
      return;
    }
    if (!_docsBytes.containsKey('cnh')) {
      _avisoErro('Falta a foto da CNH.');
      return;
    }
    if (!_docsBytes.containsKey('crlv')) {
      _avisoErro('Falta a foto do documento do veículo.');
      return;
    }

    setState(() => _enviandoDocs = true);

    try {
      final db  = FirebaseFirestore.instance;
      final ref = db.collection('docs_entregador').doc(user.uid);
      final batch = db.batch();

      batch.set(
        ref,
        {
          'uid':              user.uid,
          'nome':             _nomeCtrl.text.trim(),
          'placa':            placa,
          'tipoVeiculo':      _tipoVeiculo,
          'especialidade':    _categoriaCtrl.text.trim(),
          'status':           'pendente',
          'motivoReprovacao': '',
          'enviadoEm':        FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      for (final tipo in _docsAlterados) {
        final bytes = _docsBytes[tipo];
        if (bytes == null) continue;
        batch.set(ref.collection('arquivos').doc(tipo), {
          'base64':        base64Encode(bytes),
          'atualizadoEm':  FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Garante que a especialidade escolhida também fique salva no perfil,
      // mesmo que o profissional esqueça de tocar em "Salvar perfil".
      try {
        await db.collection('users').doc(user.uid).update({
          'categoria': _categoriaCtrl.text.trim(),
        });
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _statusDocs       = 'pendente';
        _motivoReprovacao = '';
        _placaCtrl.text   = placa;
        _docsAlterados.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documentos enviados para análise! ✅'),
          backgroundColor: _green,
        ),
      );
    } catch (e) {
      if (mounted) _avisoErro('Erro ao enviar documentos: $e');
    } finally {
      if (mounted) setState(() => _enviandoDocs = false);
    }
  }

  ImageProvider? get _imagemAtual {
    if (_fotoBytes != null) return MemoryImage(_fotoBytes!);
    if (_fotoUrl.isNotEmpty) return NetworkImage(_fotoUrl);
    return null;
  }

  // ─── Card branco com sombra suave, radius 18 (padrão do resto do app) ───────
  BoxDecoration get _cardDecoration => BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(15, 15, 30, 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _navyDark,
        foregroundColor: _white,
        elevation: 0,
        title: const Text(
          'Meu Perfil',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
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
                          colors: [Color(0xFF34C759), Color(0xFF1FA24A)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: _green.withOpacity(0.4),
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
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _accent.withOpacity(0.25),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
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

                  // Atalhos: um toque preenche a especialidade
                  const SizedBox(height: 10),
                  _buildAtalhosEspecialidade(),

                  // Aviso + status dos documentos (só entregador/guincho/frete)
                  if (_exigeDocs) ...[
                    const SizedBox(height: 12),
                    _buildStatusDocs(onTap: _irParaDocs),
                  ],

                  const SizedBox(height: 14),
                  _campo(
                    controller: _bioCtrl,
                    label: 'Sobre você',
                    icon: Icons.description_outlined,
                    linhas: 4,
                    hint: 'Conte um pouco sobre sua experiência...',
                  ),

                  // Seção de documentos logo acima do "Salvar perfil"
                  if (_exigeDocs) ...[
                    const SizedBox(height: 28),
                    KeyedSubtree(
                      key: _docsKey,
                      child: _buildDocsEntregador(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
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

  // ─── Atalhos de especialidade (Entregador / Guincho / Frete) ────────────────
  Widget _buildAtalhosEspecialidade() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trabalha com entregas, guincho ou frete? Toque aqui:',
            style: TextStyle(fontSize: 12, color: _textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _atalhosDocs.map((esp) {
              final sel = _atalhoSelecionado(esp);
              return ChoiceChip(
                label: Text(esp),
                selected: sel,
                onSelected: (_) => _escolherEspecialidade(esp),
                backgroundColor: _white,
                selectedColor: _accent.withOpacity(0.15),
                side: BorderSide(
                  color: sel ? _accent : const Color(0xFFE3E5EC),
                ),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel ? _accent : _black,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Seção: documentos (entregador, guincho e frete) ────────────────────────
  Widget _buildDocsEntregador() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.shield_outlined, color: _accent, size: 20),
            SizedBox(width: 8),
            Text(
              'Documentos de segurança',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: _black),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Para a segurança dos clientes, quem trabalha com entregas, guincho '
          'ou frete envia placa, CNH, documento do veículo e uma selfie. Só a '
          'equipe do ConectaPro+ vê esses documentos.',
          style: TextStyle(fontSize: 12, color: _textSecondary),
        ),
        const SizedBox(height: 14),

        _buildStatusDocs(),

        const SizedBox(height: 14),

        // Tipo do veículo
        Container(
          decoration: _cardDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _tipoVeiculo,
              icon: const Icon(Icons.keyboard_arrow_down, color: _accent),
              style: const TextStyle(fontSize: 14, color: _black),
              items: _tiposVeiculo
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _tipoVeiculo = v);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        _campo(
          controller: _placaCtrl,
          label: 'Placa do veículo (ex: ABC-1234 ou ABC1D23)',
          icon: Icons.pin_outlined,
          capitalizacao: TextCapitalization.characters,
          maxLength: 8,
        ),
        const SizedBox(height: 14),

        _docTile('selfie', 'Selfie (seu rosto)',
            'Foto nítida, sem óculos escuros nem boné.'),
        const SizedBox(height: 10),
        _docTile('cnh', 'CNH',
            'Foto da CNH aberta, com todos os dados legíveis.'),
        const SizedBox(height: 10),
        _docTile('crlv', 'Documento do veículo (CRLV)',
            'Foto do documento do veículo, legível.'),
        const SizedBox(height: 10),
        _docTile('veiculo', 'Foto do veículo (opcional)',
            'Mostre o veículo inteiro, com a placa visível.'),

        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: _enviandoDocs ? null : _enviarDocs,
            child: _enviandoDocs
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: _white, strokeWidth: 2),
                  )
                : Text(
                    _statusDocs.isEmpty
                        ? 'Enviar documentos para análise'
                        : 'Reenviar documentos para análise',
                    style: const TextStyle(
                        color: _white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        if (_statusDocs == 'aprovado')
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Se você reenviar, seus documentos voltam para análise.',
              style: TextStyle(fontSize: 11, color: _textSecondary),
            ),
          ),
      ],
    );
  }

  // Card de status. Com onTap, vira o aviso que leva até a seção de documentos.
  Widget _buildStatusDocs({VoidCallback? onTap}) {
    Color cor;
    IconData icone;
    String titulo;
    String sub;

    switch (_statusDocs) {
      case 'aprovado':
        cor = _green;
        icone = Icons.verified_user;
        titulo = 'Documentos aprovados';
        sub = 'Tudo certo! Seu cadastro está liberado.';
        break;
      case 'reprovado':
        cor = _red;
        icone = Icons.error_outline;
        titulo = 'Documentos reprovados';
        sub = _motivoReprovacao.isNotEmpty
            ? 'Motivo: $_motivoReprovacao\nCorrija e envie de novo.'
            : 'Corrija os documentos e envie de novo.';
        break;
      case 'pendente':
        cor = _orange;
        icone = Icons.hourglass_top;
        titulo = 'Em análise';
        sub = 'Recebemos seus documentos. Avisaremos quando for aprovado.';
        break;
      default:
        cor = _orange;
        icone = Icons.upload_file;
        titulo = 'Envie seus documentos';
        sub = 'Para atender como entregador, guincho ou frete, envie placa, '
            'CNH, documento do veículo e selfie.';
    }

    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cor.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: cor)),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 12, color: _textSecondary)),
                if (onTap != null) ...[
                  const SizedBox(height: 6),
                  Text('Toque aqui para ir até os documentos',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cor)),
                ],
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.keyboard_arrow_down, color: cor, size: 24),
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }

  Widget _docTile(String tipo, String titulo, String dica) {
    final bytes   = _docsBytes[tipo];
    final alterou = _docsAlterados.contains(tipo);

    String sub;
    Color subCor = _textSecondary;
    if (bytes == null) {
      sub = 'Toque para adicionar';
    } else if (alterou) {
      sub = 'Nova imagem — envie para análise';
      subCor = _orange;
    } else {
      sub = 'Enviada ✓ (toque para trocar)';
      subCor = _green;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _enviandoDocs ? null : () => _escolherDoc(tipo),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 72,
                height: 72,
                color: _accent.withOpacity(0.08),
                child: bytes != null
                    ? Image.memory(bytes, fit: BoxFit.cover)
                    : const Icon(Icons.add_a_photo_outlined,
                        color: _accent, size: 26),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _black)),
                  const SizedBox(height: 2),
                  Text(dica,
                      style: const TextStyle(
                          fontSize: 11, color: _textSecondary)),
                  const SizedBox(height: 4),
                  Text(sub,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: subCor)),
                ],
              ),
            ),
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
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_outlined,
                      color: _gold, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Progresso para Verificado',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _black),
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
                  valueColor: const AlwaysStoppedAnimation<Color>(_gold),
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
                          size: 13, color: _gold),
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
    TextCapitalization capitalizacao = TextCapitalization.none,
    int? maxLength,
  }) {
    return Container(
      decoration: _cardDecoration,
      child: TextField(
        controller: controller,
        keyboardType: tipo,
        maxLines: linhas,
        maxLength: maxLength,
        textCapitalization: capitalizacao,
        style: const TextStyle(fontSize: 14, color: _black),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          counterText: '',
          hintStyle: const TextStyle(color: _textSecondary, fontSize: 13),
          prefixIcon: Icon(icon, color: _accent, size: 20),
          filled: true,
          fillColor: _white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
          labelStyle: const TextStyle(color: _textSecondary, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
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
            const Divider(color: Color(0xFFE3E5EC)),
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
                decoration: _cardDecoration,
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
