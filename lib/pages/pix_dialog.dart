import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class PixDialog extends StatefulWidget {
  final double valor;

  const PixDialog({super.key, required this.valor});

  @override
  State<PixDialog> createState() => _PixDialogState();
}

class _PixDialogState extends State<PixDialog> {
  bool loading = true;
  bool copiado = false;
  bool erro = false;

  String pix = '';
  String paymentId = '';
  Uint8List? qr;

  Timer? timer;
  int tempo = 600;

  final String baseUrl =
      "https://conectapro-backend-y7oe.onrender.com";

  @override
  void initState() {
    super.initState();
    inicializarPix();
    iniciarTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> inicializarPix() async {
    try {
      await http.get(Uri.parse(baseUrl)); // acorda backend
      await gerarPix();
    } catch (_) {
      setState(() {
        erro = true;
        loading = false;
      });
    }
  }

  void iniciarTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (tempo > 0 && mounted) {
        setState(() => tempo--);
      }
    });
  }

  String tempoFormatado() {
    final m = (tempo ~/ 60).toString().padLeft(2, '0');
    final s = (tempo % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> gerarPix() async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/criar-pix'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'valor': widget.valor,
          'email': 'cliente@gmail.com',
          'nome': 'Antonio',
        }),
      );

      final data = jsonDecode(res.body);

      setState(() {
        pix = data['pixCopiaECola'] ?? '';
        paymentId = data['paymentId'] ?? '';
        qr = data['qrCodeBase64'] != null
            ? base64Decode(data['qrCodeBase64'].split(',').last)
            : null;
        loading = false;
      });

      iniciarVerificacao();

    } catch (e) {
      setState(() {
        erro = true;
        loading = false;
      });
    }
  }

  void iniciarVerificacao() {
    timer = Timer.periodic(const Duration(seconds: 5), (t) async {
      if (paymentId.isEmpty) return;

      try {
        final res = await http.get(
          Uri.parse('$baseUrl/verificar-pagamento/$paymentId'),
        );

        final data = jsonDecode(res.body);

        if (data['status'] == 'CONFIRMED' ||
            data['status'] == 'RECEIVED') {

          t.cancel();

          if (mounted) {
            Navigator.pop(context, true);
          }
        }

      } catch (_) {}
    });
  }

  Future<void> copiar() async {
    await Clipboard.setData(ClipboardData(text: pix));
    setState(() => copiado = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => copiado = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: RadialGradient(
            radius: 1.5,
            center: Alignment.topRight,
            colors: [
              Colors.purple.shade900,
              Colors.black,
            ],
          ),
        ),
        child: loading
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text(
                    "Gerando PIX...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              )
            : erro
                ? const Text(
                    "Erro ao gerar PIX 😥",
                    style: TextStyle(color: Colors.white),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      const Icon(Icons.hexagon,
                          color: Colors.cyanAccent, size: 30),

                      const SizedBox(height: 8),

                      const Text("PAGAMENTO",
                          style: TextStyle(
                              color: Colors.white70,
                              letterSpacing: 3)),

                      Text(
                        "PIX",
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [
                                Colors.cyanAccent,
                                Colors.purpleAccent
                              ],
                            ).createShader(
                                const Rect.fromLTWH(0, 0, 200, 70)),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "R\$ ${widget.valor.toStringAsFixed(2)}",
                        style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 20),

                      qr != null
                          ? Image.memory(qr!, width: 200)
                          : const Text(
                              "Erro QR",
                              style:
                                  TextStyle(color: Colors.white),
                            ),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          pix,
                          style:
                              const TextStyle(fontSize: 10),
                        ),
                      ),

                      const SizedBox(height: 10),

                      ElevatedButton(
                        onPressed: copiar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(
                          copiado
                              ? "COPIADO ✅"
                              : "COPIAR CÓDIGO PIX",
                        ),
                      ),

                      const SizedBox(height: 15),

                      Text(
                        tempoFormatado(),
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 22,
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context),
                        child: const Text(
                          "Cancelar pagamento",
                          style:
                              TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}