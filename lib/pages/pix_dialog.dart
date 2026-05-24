import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

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

  String pix = '';
  String paymentId = '';
  Uint8List? qr;

  Timer? timer;
  int tempo = 600;

  @override
  void initState() {
    super.initState();
    gerarPix();
    iniciarTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
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
        Uri.parse('http://127.0.0.1:3000/criar-pix'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'valor': widget.valor,
          'email': 'cliente@gmail.com',
          'nome': 'Antonio',
        }),
      );

      final data = jsonDecode(res.body);

      setState(() {
        pix = data['pixCopiaECola'];
        paymentId = data['paymentId'];
        qr = base64Decode(data['qrCodeBase64'].split(',').last);
        loading = false;
      });

      verificarPagamento();
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> verificarPagamento() async {
    await Future.delayed(const Duration(seconds: 5));
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
            ? const Center(child: CircularProgressIndicator())
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

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.cyanAccent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "R\$ ${widget.valor.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [

                      /// PASSOS
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("1. Abra seu banco",
                                style: TextStyle(color: Colors.white)),
                            SizedBox(height: 10),
                            Text("2. Escaneie o QR",
                                style: TextStyle(color: Colors.white)),
                            SizedBox(height: 10),
                            Text("3. Confirme pagamento",
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      /// QR
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.purpleAccent),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purpleAccent
                                  .withOpacity(0.8),
                              blurRadius: 40,
                            )
                          ],
                        ),
                        child: qr != null
                            ? Image.memory(qr!, width: 200)
                            : const Text("Erro QR"),
                      ),

                      const SizedBox(width: 10),

                      /// SEGURANÇA
                      Expanded(
                        child: Column(
                          children: const [
                            Icon(Icons.security,
                                color: Colors.cyanAccent),
                            SizedBox(height: 10),
                            Text("Pagamento Seguro",
                                style:
                                    TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      pix.substring(0, pix.length > 60 ? 60 : pix.length),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: copiar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        copiado ? "COPIADO ✅" : "COPIAR CÓDIGO PIX",
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    tempoFormatado(),
                    style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 15),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancelar pagamento",
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
      ),
    );
  }
}