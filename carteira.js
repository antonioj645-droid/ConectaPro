const admin = require("firebase-admin");
const db = admin.firestore();

// =====================================
// 🔥 DESBLOQUEAR PEDIDO (cobra R$3)
// =====================================
async function desbloquearPedido(userId, pedidoId) {

  const userRef = db.collection("users").doc(userId);
  const pedidoRef = db.collection("pedidos").doc(pedidoId);

  return await db.runTransaction(async (t) => {

    const userDoc = await t.get(userRef);
    const pedidoDoc = await t.get(pedidoRef);

    // ⚠️ valida usuário
    if (!userDoc.exists) {
      throw new Error("Usuário não encontrado");
    }

    // ⚠️ valida pedido
    if (!pedidoDoc.exists) {
      throw new Error("Pedido não encontrado");
    }

    const user = userDoc.data();
    const pedido = pedidoDoc.data();

    // ❌ BLOQUEIA SE TEM TAXA PENDENTE (7%)
    if (user.taxaPendente === true) {
      throw new Error("Você precisa pagar a taxa pendente");
    }

    // ❌ BLOQUEIA SE NÃO TEM SALDO
    if (user.saldo < 3) {
      throw new Error("Saldo insuficiente");
    }

    // ❌ EVITA PAGAR DUAS VEZES
    if (pedido.desbloqueados && pedido.desbloqueados[userId]) {
      throw new Error("Pedido já desbloqueado");
    }

    // ✅ DESCONTA SALDO
    const novoSaldo = user.saldo - 3;

    t.update(userRef, {
      saldo: novoSaldo
    });

    // ✅ LIBERA O PEDIDO PARA ESSE PROFISSIONAL
    t.update(pedidoRef, {
      [`desbloqueados.${userId}`]: true
    });

    // ✅ REGISTRA TRANSAÇÃO
    const txRef = db.collection("transacoes").doc();

    t.set(txRef, {
      userId,
      pedidoId,
      tipo: "desbloqueio",
      valor: -3,
      createdAt: new Date()
    });

    return { success: true };
  });
}

// =====================================
// EXPORT
// =====================================
module.exports = {
  desbloquearPedido
};
