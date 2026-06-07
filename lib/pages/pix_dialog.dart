import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────
// CONFIG
// ─────────────────────────────

const String _kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

const Duration _kHttpTimeout     = Duration(seconds: 60);
const Duration _kPollingInterval = Duration(seconds: 5);
const int      _kMaxAttempts     = 60;

// ─────────────────────────────
// WIDGET
// ─────────────────────────────

class PixDialog extends StatefulWidget {
  final double valor;

  const PixDialog({super.key, required this.valor});

  @override
  State<PixDialog> createState() => _PixDialogState();
}

class _PixDialogState extends State<PixDialog> {

  bool _loading = true;
  bool _erro    = false;

  String _pixCopiaCola = '';
  String _paymentId    = '';

  Uint8List? _qrCodeImage;

  Timer? _timer;
  int _tentativas = 0;

  @override
  void initState() {
    super.initState();
    _gerarPix();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────
  // GERAR PIX
  // ─────────────────────────────
  Future<void> _gerarPix() async {

    setState(() {
      _loading = true;
      _erro = false;
    });

    try {
      final response = await http.post(
        Uri.parse('$_kBaseUrl/pix/criar-pix'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'valor': widget.valor,
          'email': 'cliente@gmail.com',
          'nome': 'Antonio',
        }),
      ).timeout(_kHttpTimeout);

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        throw Exception(data['error']);
      }

      String raw = data['qrCodeBase64'] ?? '';
      if (raw.contains(',')) raw = raw.split(',').last;

      setState(() {
        _pixCopiaCola = data['pixCopiaECola'] ?? '';
        _paymentId = data['paymentId'] ?? '';
        _qrCodeImage = raw.isNotEmpty ? base64Decode(raw) : null;

        _loading = false;
        _erro = _qrCodeImage == null;
      });

      if (_paymentId.isNotEmpty) {
        _iniciarPolling();
      }

    } catch (e) {

      setState(() {
        _loading = false;
        _erro = true;
      });
    }
  }

  // ─────────────────────────────
  // POLLING
  // ─────────────────────────────
  void _iniciarPolling() {

    _tentativas = 0;

    _timer = Timer.periodic(_kPollingInterval, (_) async {

      if (++_tentativas > _kMaxAttempts) {
        _timer?.cancel();
        return;
      }

      try {
        final response = await http.get(
          Uri.parse('$_kBaseUrl/pix/verificar-pagamento/$_paymentId'),
        );

        final status = jsonDecode(response.body)['status'];

        if (status == 'RECEIVED' || status == 'CONFIRMED') {
          _timer?.cancel();
          if (mounted) Navigator.pop(context, true);
        }

      } catch (_) {}
    });
  }

  // ─────────────────────────────
  // COPIAR PIX
  // ─────────────────────────────
  Future<void> _copiarPix() async {

    if (_pixCopiaCola.isEmpty) return;

    await Clipboard.setData(
      ClipboardData(text: _pixCopiaCola),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIX copiado!')),
    );
  }

  // ─────────────────────────────
  // UI
  // ─────────────────────────────
  @override
  Widget build(BuildContext context) {

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F2B),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.3),
              blurRadius: 40,
            ),
          ],
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const Text(
              "PAGAMENTO PIX",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "R\$ ${widget.valor.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 32,
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // QR
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.cyanAccent,
                  width: 2,
                ),
              ),
              child: _buildQr(),
            ),

            const SizedBox(height: 20),

            const Text(
              "CÓDIGO PIX",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 6),

            SelectableText(
              _pixCopiaCola,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _copiarPix,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.cyanAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "COPIAR CÓDIGO PIX",
                    style: TextStyle(color: Colors.cyanAccent),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Aguardando pagamento...",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────
  // QR BUILD
  // ─────────────────────────────
  Widget _buildQr() {

    if (_loading) {
      return const Column(
        children: [
          CircularProgressIndicator(color: Colors.cyanAccent),
          SizedBox(height: 10),
          Text(
            "Gerando PIX...",
            style: TextStyle(color: Colors.white70),
          )
        ],
      );
    }

    if (_erro && _qrCodeImage == null) {
      return Column(
        children: [
          const Text(
            "Erro ao gerar PIX",
            style: TextStyle(color: Colors.white70),
          ),
          TextButton(
            onPressed: _gerarPix,
            child: const Text(
              "Tentar novamente",
              style: TextStyle(color: Colors.cyanAccent),
            ),
          )
        ],
      );
    }

    if (_qrCodeImage != null) {
      return Image.memory(
        _qrCodeImage!,
        width: 210,
        height: 210,
      );
    }

    return const Text("QR indisponível");
  }
}
