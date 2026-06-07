const admin = require("firebase-admin");
const db = admin.firestore();

async function desbloquearPedido(userId, pedidoId) {

  const userRef = db.collection("users").doc(userId);
  const pedidoRef = db.collection("pedidos").doc(pedidoId);

  return await db.runTransaction(async (t) => {

    const userDoc = await t.get(userRef);
    const pedidoDoc = await t.get(pedidoRef);

    if (!userDoc.exists) {
      throw new Error("Usuário não encontrado");
    }

    if (!pedidoDoc.exists) {
      throw new Error("Pedido não encontrado");
    }

    const user = userDoc.data();
    const pedido = pedidoDoc.data();

    if (user.taxaPendente === true) {
      throw new Error("Você precisa pagar a taxa pendente");
    }

    if (user.saldo < 3) {
      throw new Error("Saldo insuficiente");
    }

    if (pedido.desbloqueados && pedido.desbloqueados[userId]) {
      throw new Error("Pedido já desbloqueado");
    }

    const novoSaldo = user.saldo - 3;

    t.update(userRef, { saldo: novoSaldo });

    t.update(pedidoRef, {
      [`desbloqueados.${userId}`]: true
    });

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

module.exports = {
  desbloquearPedido
};
