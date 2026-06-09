// 💰 PIX
IconButton(
  icon: const Icon(Icons.account_balance_wallet),
  tooltip: "Adicionar saldo",
  onPressed: () {
    showDialog(
      context: context,
      builder: (_) => const PixDialog(),
    );
  },
),