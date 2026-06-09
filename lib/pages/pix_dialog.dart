import 'package:flutter/material.dart';

class PixDialog extends StatefulWidget {
  const PixDialog({super.key});

  @override
  State<PixDialog> createState() => _PixDialogState();
}

class _PixDialogState extends State<PixDialog> {

  final TextEditingController controller = TextEditingController();
  String? erro;

  void gerarPix() {

    final valor = double.tryParse(controller.text);

    if (valor == null || valor < 10) {
      setState(() {
        erro = "Valor mínimo é R\$10";
      });
      return;
    }

    setState(() {
      erro = null;
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("PIX Gerado"),
        content: Text("Valor: R\$${valor.toStringAsFixed(2)}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      title: const Text("Adicionar saldo 💰"),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Digite o valor",
              hintText: "Ex: 10, 20, 50",
            ),
          ),

          if (erro != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                erro!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),

      actions: [

        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),

        ElevatedButton(
          onPressed: gerarPix,
          child: const Text("Gerar PIX"),
        ),
      ],
    );
  }
}