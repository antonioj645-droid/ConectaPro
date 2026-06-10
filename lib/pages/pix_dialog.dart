import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class PixDialog extends StatefulWidget {
  final double? valor; // agora opcional

  const PixDialog({super.key, this.valor});

  @override
  State<PixDialog> createState() => _PixDialogState();
}

class _PixDialogState extends State<PixDialog> {
  // ─── Tema ──────────────────────────────────────────────────────────────────
  static const _cyan   = Colors.cyanAccent;
  static const _purple = Colors.purpleAccent;

  // ─── Estados ───────────────────────────────────────────────────────────────
  bool _loading  = false;
  bool _copiado  = false;
  bool _erro     = false;
  bool _escolhendo = true; // começa na tela de escolha se valor não foi passado

  String     _pix       = '';
  String     _paymentId = '';
  Uint8List? _qr;
  Timer?     _timer;
  int        _tempo     = 600;

  double?                  _valorEscolhido;
  final TextEditingController _controller = TextEditingController();

  final String _baseUrl = "https://conectapro-backend-y7oe.onrender.com";

  @override
  void initState() {
    super.initState();
    if (widget.valor != null) {
      // valor já veio — vai direto para o PIX
      _valorEscolhido = widget.valor;
      _escolhendo = false;
      _inicializarPix();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ─── Inicializa PIX ────────────────────────────────────────────────────────
  Future<void> _inicializarPix() async {
    setState(() { _loading = true; _erro = false; });
    try {
      await http.get(Uri.parse(_baseUrl)); // acorda backend
      await _gerarPix();
    } catch (_) {
      if (mounted) setState(() { _erro = true; _loading = false; });
    }
  }

  Future<void> _gerarPix() async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/criar-pix'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'valor': _valorEscolhido,
          'email': 'cliente@gmail.com',
          'nome': 'Antonio',
        }),
      );

      final data = jsonDecode(res.body);

      if (!mounted) return;
      setState(() {
        _pix       = data['pixCopiaECola'] ?? '';
        _paymentId = data['paymentId'] ?? '';
        _qr        = data['qrCodeBase64'] != null
            ? base64Decode(data['qrCodeBase64'].split(',').last)
            : null;
        _loading   = false;
      });

      _iniciarVerificacao();
      _iniciarTimer();
    } catch (_) {
      if (mounted) setState(() { _erro = true; _loading = false; });
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
        final res = await http.get(
            Uri.parse('$_baseUrl/verificar-pagamento/$_paymentId'));
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
          gradient: RadialGradient(
            radius: 1.5,
            center: Alignment.topRight,
            colors: [Colors.purple.shade900, Colors.black],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _escolhendo
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

  // ─── Tela 1: escolha de valor ──────────────────────────────────────────────
  Widget _buildEscolhaValor() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.account_balance_wallet,
            color: Colors.cyanAccent, size: 36),
        const SizedBox(height: 12),
        const Text('Adicionar Saldo',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Mínimo R\$ 10,00',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 24),

        // Atalhos rápidos
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [10, 20, 50, 100].map((v) {
            final selecionado = _valorEscolhido == v.toDouble();
            return GestureDetector(
              onTap: () {
                setState(() {
                  _valorEscolhido = v.toDouble();
                  _controller.text = v.toString();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: selecionado
                      ? Colors.cyanAccent
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selecionado ? Colors.cyanAccent : Colors.white24,
                  ),
                ),
                child: Text(
                  'R\$ $v',
                  style: TextStyle(
                    color: selecionado ? Colors.black : Colors.white,
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
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixText: 'R\$ ',
            prefixStyle: const TextStyle(color: Colors.cyanAccent),
            hintText: 'Outro valor',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.cyanAccent),
            ),
          ),
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '.'));
            setState(() => _valorEscolhido = parsed);
          },
        ),

        const SizedBox(height: 24),

        // Botão continuar
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: (_valorEscolhido == null || _valorEscolhido! < 10)
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
          child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
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
        CircularProgressIndicator(color: Colors.cyanAccent),
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
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 12),
        const Text('Erro ao gerar PIX',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
          onPressed: _inicializarPix,
          child: const Text('Tentar novamente',
              style: TextStyle(color: Colors.black)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  // ─── Tela 4: QR Code ──────────────────────────────────────────────────────
  Widget _buildPix() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.hexagon, color: Colors.cyanAccent, size: 30),
        const SizedBox(height: 8),
        const Text('PAGAMENTO',
            style: TextStyle(color: Colors.white70, letterSpacing: 3)),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.cyanAccent, Colors.purpleAccent],
          ).createShader(bounds),
          child: const Text('PIX',
              style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
        const SizedBox(height: 8),
        Text(
          'R\$ ${_valorEscolhido!.toStringAsFixed(2)}',
          style: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 28,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        if (_qr != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(_qr!, width: 200, height: 200, fit: BoxFit.cover),
          )
        else
          const Text('Erro ao carregar QR Code',
              style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
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
          height: 44,
          child: ElevatedButton(
            onPressed: _copiar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
          style: const TextStyle(color: Colors.cyanAccent, fontSize: 22),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar pagamento',
              style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}