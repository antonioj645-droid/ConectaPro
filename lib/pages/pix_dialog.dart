import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PixDialog extends StatefulWidget {
  const PixDialog({super.key});

  @override
  State<PixDialog> createState() => _PixDialogState();
}

class _PixDialogState extends State<PixDialog> {

  final TextEditingController controller = TextEditingController();

  String? codigoPix;
  double? valor;
  String? erro;

  void gerarPix() {

    final v = double.tryParse(controller.text);

    // ✅ VALIDAÇÃO REAL
    if (v == null || v < 10) {
      setState(() {
        erro = "Valor mínimo R\$10";
      });
      return;
    }

    // ✅ LIMPA ERRO
    setState(() {
      erro = null;
      valor = v;

      // 🔥 mantém sua lógica (simulação ou futura API)
      codigoPix =
          "000201PIX${DateTime.now().millisecondsSinceEpoch}";
    });
  }

  @override
  Widget build(BuildContext context) {

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F2C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ✅ VALOR GRANDE (igual seu layout)
            if (valor != null)
              Text(
                "R\$ ${valor!.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.cyan,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 20),

            // ✅ QR CODE VISUAL
            if (codigoPix != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.cyan),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: 180,
                  height: 180,
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: const Text("QR"),
                ),
              ),

            const SizedBox(height: 15),

            // ✅ INPUT (antes de gerar)
            if (codigoPix == null)
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Digite valor (mín 10)",
                  hintStyle: TextStyle(color: Colors.white54),
                ),
              ),

            // ✅ ERRO
            if (erro != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  erro!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // ✅ CÓDIGO PIX
            if (codigoPix != null) ...[
              const SizedBox(height: 10),

              const Text(
                "CÓDIGO PIX",
                style: TextStyle(color: Colors.white54),
              ),

              const SizedBox(height: 5),

              SelectableText(
                codigoPix!,
                style: const TextStyle(color: Colors.white),
              ),
            ],

            const SizedBox(height: 20),

            // ✅ BOTÕES
            if (codigoPix == null)
              ElevatedButton(
                onPressed: gerarPix,
                child: const Text("Gerar PIX"),
              ),

            if (codigoPix != null)
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: codigoPix!),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Código copiado ✅"),
                    ),
                  );
                },
                child: const Text("Copiar código PIX"),
              ),
          ],
        ),
      ),
    );
  }
}