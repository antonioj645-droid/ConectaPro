import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// ==========================
// CONFIG
// ==========================
const String _kBaseUrl =
    'https://conectapro-backend-1.onrender.com';

const Duration _kHttpTimeout = Duration(seconds: 90);
const Duration _kPollingInterval = Duration(seconds: 5);
const int _kMaxAttempts = 60;

// ==========================
// WIDGET
// ==========================
class PixDialog extends StatefulWidget {
  final double valor;

  const PixDialog({
    super.key,
    required this.valor,
  });

  @override
  State<PixDialog> createState() => _PixDialogState();
}

class _PixDialogState extends State<PixDialog> {

  bool _loading = true;
  bool _erro = false;

  String _pixCopiaCola = '';
  String _paymentId = '';

  Uint8List? _qrImage;

  Timer? _timer;
  int _tentativas = 0;

  // ==========================
  // INIT
  // ==========================
  @override
  void initState() {
    super.initState();
    _criarPix();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ==========================
  // CRIAR PIX
  // ==========================
  Future<void> _criarPix() async {

    setState(() {
      _loading = true;
      _erro = false;
    });

    try {

      final response = await http.post(
        Uri.parse('$_kBaseUrl/pix/criar-pix'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "valor": widget.valor,
          "email": "cliente@gmail.com",
          "nome": "Antonio"
        }),
      ).timeout(_kHttpTimeout);

      final data = jsonDecode(response.body);

      if (data["success"] != true) {
        throw Exception(data["error"]);
      }

      String base64img = data["qrCodeBase64"] ?? "";
      if (base64img.contains(',')) {
        base64img = base64img.split(',').last;
      }

      setState(() {
        _pixCopiaCola = data["pixCopiaECola"] ?? "";
        _paymentId = data["paymentId"] ?? "";
        _qrImage = base64img.isNotEmpty ? base64Decode(base64img) : null;

        _loading = false;
        _erro = _qrImage == null;
      });

      if (_paymentId.isNotEmpty) {
        _startPolling();
      }

    } catch (e) {

      setState(() {
        _loading = false;
        _erro = true;
      });
    }
  }

  // ==========================
  // POLLING (VERIFICA PAGAMENTO)
  // ==========================
  void _startPolling() {

    _tentativas = 0;

    _timer = Timer.periodic(_kPollingInterval, (_) async {

      if (++_tentativas > _kMaxAttempts) {
        _timer?.cancel();
        return;
      }

      try {

        final res = await http.get(
          Uri.parse('$_kBaseUrl/pix/verificar-pagamento/$_paymentId'),
        );

        final data = jsonDecode(res.body);
        final status = data["status"];

        if (status == "CONFIRMED" || status == "RECEIVED") {

          _timer?.cancel();

          if (mounted) {
            Navigator.pop(context, true);
          }
        }

      } catch (_) {}
    });
  }

  // ==========================
  // COPIAR PIX
  // ==========================
  Future<void> _copiar() async {

    if (_pixCopiaCola.isEmpty) return;

    await Clipboard.setData(
      ClipboardData(text: _pixCopiaCola),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Código PIX copiado")),
    );
  }

  // ==========================
  // UI
  // ==========================
  @override
  Widget build(BuildContext context) {

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
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

        child: SingleChildScrollView(
          child: Column(
            children: [

              // ======================
              // TITULO
              // ======================
              const Text(
                "PAGAMENTO PIX",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "R\$ ${widget.valor.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // ======================
              // QR
              // ======================
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

              // ======================
              // BOTÃO
              // ======================
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _copiar,
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
      ),
    );
  }

  // ==========================
  // BUILD QR
  // ==========================
  Widget _buildQr() {

    if (_loading) {
      return const Column(
        children: [
          CircularProgressIndicator(color: Colors.cyanAccent),
          SizedBox(height: 10),
          Text("Gerando PIX...",
              style: TextStyle(color: Colors.white70)),
        ],
      );
    }

    if (_erro && _qrImage == null) {
      return Column(
        children: [
          const Text(
            "Erro ao gerar PIX",
            style: TextStyle(color: Colors.white70),
          ),
          TextButton(
            onPressed: _criarPix,
            child: const Text(
              "Tentar novamente",
              style: TextStyle(color: Colors.cyanAccent),
            ),
          )
        ],
      );
    }

    if (_qrImage != null) {
      return Image.memory(
        _qrImage!,
        width: 210,
        height: 210,
      );
    }

    return const Text("QR indisponível");
  }
}
