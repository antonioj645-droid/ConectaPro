import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PixDialog extends StatefulWidget {
  final double? valor; // agora opcional

  const PixDialog({super.key, this.valor});

  @override
  State<PixDialog> createState() => _PixDialogState();
}

class _PixDialogState extends State<PixDialog> {
  // ─── Tema (mesmo padrão navy usado no resto do app) ─────────────────────────
  static const _navyDark = Color(0xFF0A0A16);
  static const _navyLight = Color(0xFF1B1F3B);
  static const _accent = Color(0xFF2F6FED);
  static const _accentLight = Color(0xFF4FA1FF);
  static const _white = Color(0xFFFFFFFF);
  static const _red = Color(0xFFFF3B30);

  // ─── Estados ───────────────────────────────────────────────────────────────
  bool _loading  = false;
  bool _copiado  = false;
  bool _erro     = false;
  bool _escolhendo = true; // tela de coleta de dados (valor + CPF/CNPJ)
  bool _carregandoCpf = true; // buscando CPF salvo no Firestore

  String     _pix       = '';
  String     _paymentId = '';
  String     _erroMsg   = '';
  Uint8List? _qr;
  Timer?     _timer;
  int        _tempo     = 600;

  double?                  _valorEscolhido;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();

  final String _baseUrl = "https://conectapro-backend-1.onrender.com/pix";

  // ─── Valida CPF (11 dígitos) ou CNPJ (14 dígitos) ───────────────────────────
  bool get _cpfCnpjValido {
    final digitos = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return digitos.length == 11 || digitos.length == 14;
  }

  @override
  void initState() {
    super.initState();
    _valorEscolhido = widget.valor;
    _prepararTela();
  }

  // ─── Busca CPF/CNPJ já salvo do usuário e decide qual tela mostrar ──────────
  Future<void> _prepararTela() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final salvo = doc.data()?['cpfCnpj']?.toString() ?? '';
        if (salvo.isNotEmpty) _cpfController.text = salvo;
      }
    } catch (_) {
      // segue sem CPF pré-preenchido
    }

    if (!mounted) return;

    if (widget.valor != null && _cpfCnpjValido) {
      // já temos valor e CPF válido — vai direto para o PIX
      setState(() { _escolhendo = false; _carregandoCpf = false; });
      _inicializarPix();
    } else {
      setState(() { _carregandoCpf = false; });
    }
  }

  // ─── Salva o CPF/CNPJ no perfil do usuário para não pedir de novo ──────────
  Future<void> _salvarCpfNoPerfil() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'cpfCnpj': _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '')},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  // ─── Inicializa PIX ────────────────────────────────────────────────────────
  Future<void> _inicializarPix() async {
    setState(() { _loading = true; _erro = false; _erroMsg = ''; });
    try {
      // Render free tier pode estar "dormindo" — tenta acordar por até ~50s.
      bool acordou = false;
      for (int tentativa = 0; tentativa < 5 && !acordou; tentativa++) {
        try {
          final resp = await http
              .get(Uri.parse(_baseUrl))
              .timeout(const Duration(seconds: 12));
          if (resp.statusCode >= 200 && resp.statusCode < 500) {
            acordou = true;
          }
        } catch (_) {
          // ainda dormindo / instável — tenta de novo
        }
        if (!acordou) await Future.delayed(const Duration(seconds: 2));
      }
      await _gerarPix();
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = true;
          _loading = false;
          _erroMsg = 'Não foi possível conectar ao servidor. $e';
        });
      }
    }
  }

  Future<void> _gerarPix() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _erro = true;
          _loading = false;
          _erroMsg = 'Usuário não autenticado.';
        });
      }
      return;
    }

    try {
      final idToken = await user.getIdToken();
      final res = await http
          .post(
            Uri.parse('$_baseUrl/criar-pix'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'valor': _valorEscolhido,
              'email': user.email ?? '${user.uid}@conectapro.app',
              'nome': user.displayName ?? 'Usuário ConectaPro',
              'userId': user.uid,
              'cpfCnpj': _cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            }),
          )
          .timeout(const Duration(seconds: 45));

      Map<String, dynamic> data;
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        data = {};
      }

      if (data['success'] != true) {
        final motivo = data['error'];
        String msg;
        if (motivo is Map) {
          msg = (motivo['errors'] is List && (motivo['errors'] as List).isNotEmpty)
              ? (motivo['errors'][0]['description'] ?? motivo.toString()).toString()
              : motivo.toString();
        } else if (motivo != null) {
          msg = motivo.toString();
        } else {
          msg = 'Resposta inesperada do servidor (HTTP ${res.statusCode}).';
        }
        if (mounted) {
          setState(() { _erro = true; _loading = false; _erroMsg = msg; });
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        _pix       = data['pixCopiaECola'] ?? '';
        _paymentId = data['paymentId'] ?? '';
        _qr        = data['qrCodeBase64'] != null &&
                (data['qrCodeBase64'] as String).isNotEmpty
            ? base64Decode(data['qrCodeBase64'].split(',').last)
            : null;
        _loading   = false;
      });

      _salvarCpfNoPerfil();
      _iniciarVerificacao();
      _iniciarTimer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = true;
          _loading = false;
          _erroMsg = 'Falha na comunicação com o servidor. $e';
        });
      }
    }
  }

  void _iniciarTimer() {
    _timer?.cancel();
    _tempo = 600;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_tempo > 0 && mounted) setState(() => _tempo--);
    });
  }

  void _iniciarVerificacao() {
    _timer = Timer.periodic(const Duration(seconds: 5), (t) async {
      if (_paymentId.isEmpty) return;
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        final idToken = await user.getIdToken();
        final res = await http.get(
          Uri.parse('$_baseUrl/verificar-pagamento/$_paymentId'),
          headers: {'Authorization': 'Bearer $idToken'},
        );
        final data = jsonDecode(res.body);
        if (data['status'] == 'CONFIRMED' || data['status'] == 'RECEIVED') {
          t.cancel();
          if (mounted) Navigator.pop(context, true);
        }
      } catch (_) {}
    });
  }

  String get _tempoFormatado {
    final m = (_tempo ~/ 60).toString().padLeft(2, '0');
    final s = (_tempo % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _copiar() async {
    await Clipboard.setData(ClipboardData(text: _pix));
    setState(() => _copiado = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiado = false);
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_navyDark, _navyLight],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(10, 10, 20, 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _carregandoCpf
                ? _buildLoading()
                : _escolhendo
                    ? _buildEscolhaValor()
                    : _loading
                        ? _buildLoading()
                        : _erro
                            ? _buildErro()
                            : _buildPix(),
          ),
        ),
      ),
    );
  }

  // ─── Tela 1: escolha de valor + CPF/CNPJ ────────────────────────────────────
  Widget _buildEscolhaValor() {
    final precisaValor = widget.valor == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.account_balance_wallet,
            color: _accentLight, size: 36),
        const SizedBox(height: 12),
        const Text('Adicionar Saldo',
            style: TextStyle(
                color: _white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          precisaValor
              ? 'Mínimo R\$ 5,00'
              : 'Valor: R\$ ${widget.valor!.toStringAsFixed(2).replaceAll('.', ',')}',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 24),

        if (precisaValor) ...[
          // Atalhos rápidos
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [5, 10, 20, 50, 100].map((v) {
              final selecionado = _valorEscolhido == v.toDouble();
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _valorEscolhido = v.toDouble();
                    _controller.text = v.toString();
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: selecionado
                        ? _accent
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selecionado ? _accent : Colors.white24,
                    ),
                  ),
                  child: Text(
                    'R\$ $v',
                    style: TextStyle(
                      color: selecionado ? _white : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Campo manual
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: _white),
            decoration: InputDecoration(
              prefixText: 'R\$ ',
              prefixStyle: const TextStyle(color: _accentLight),
              hintText: 'Outro valor',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _accent, width: 1.5),
              ),
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v.replaceAll(',', '.'));
              setState(() => _valorEscolhido = parsed);
            },
          ),

          const SizedBox(height: 20),
        ],

        // Campo CPF/CNPJ — exigido pelo Asaas para gerar a cobrança PIX
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'CPF ou CNPJ',
            style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _cpfController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: _white),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(14),
          ],
          decoration: InputDecoration(
            hintText: 'Somente números',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _accent, width: 1.5),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Exigido pela Asaas para gerar a cobrança PIX.',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
          ),
        ),

        const SizedBox(height: 24),

        // Botão continuar
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: _white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: (_valorEscolhido == null ||
                    _valorEscolhido! < 5 ||
                    !_cpfCnpjValido)
                ? null
                : () {
                    setState(() => _escolhendo = false);
                    _inicializarPix();
                  },
            child: const Text('Gerar PIX',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),

        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: _red)),
        ),
      ],
    );
  }

  // ─── Tela 2: loading ───────────────────────────────────────────────────────
  Widget _buildLoading() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 20),
        CircularProgressIndicator(color: _accentLight),
        SizedBox(height: 16),
        Text('Gerando PIX...', style: TextStyle(color: Colors.white70)),
        SizedBox(height: 20),
      ],
    );
  }

  // ─── Tela 3: erro ─────────────────────────────────────────────────────────
  Widget _buildErro() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: _red, size: 48),
        const SizedBox(height: 12),
        const Text('Erro ao gerar PIX',
            style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w700)),
        if (_erroMsg.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              _erroMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _inicializarPix,
          child: const Text('Tentar novamente',
              style: TextStyle(color: _white)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar', style: TextStyle(color: _red)),
        ),
      ],
    );
  }

  // ─── Tela 4: QR Code ──────────────────────────────────────────────────────
  Widget _buildPix() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.qr_code_2_rounded, color: _accentLight, size: 30),
        const SizedBox(height: 8),
        const Text('PAGAMENTO',
            style: TextStyle(color: Colors.white70, letterSpacing: 3)),
        const Text('PIX',
            style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: _white)),
        const SizedBox(height: 8),
        Text(
          'R\$ ${_valorEscolhido!.toStringAsFixed(2)}',
          style: const TextStyle(
              color: _accentLight,
              fontSize: 28,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        if (_qr != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(_qr!, width: 200, height: 200, fit: BoxFit.cover),
            ),
          )
        else
          const Text('Erro ao carregar QR Code',
              style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _pix,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _copiar,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: _white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _copiado ? 'COPIADO ✅' : 'COPIAR CÓDIGO PIX',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _tempoFormatado,
          style: const TextStyle(color: _accentLight, fontSize: 22),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar pagamento',
              style: TextStyle(color: _red)),
        ),
      ],
    );
  }
}