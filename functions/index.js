const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// ─── HELPER: monta e envia notificação com prioridade máxima ──────────────
async function enviarNotificacao(tokens, titulo, corpo, data = {}) {
  if (!tokens || tokens.length === 0) return null;

  const listaTokens = Array.isArray(tokens) ? tokens : [tokens];

  const mensagem = {
    notification: {
      title: titulo,
      body: corpo,
    },
    android: {
      priority: "high",                  // acorda o dispositivo mesmo fechado
      notification: {
        sound: "default",
        priority: "high",
        channelId: "default_channel",    // canal padrão do ConectaPro
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
          contentAvailable: true,
        },
      },
      headers: {
        "apns-priority": "10",           // prioridade máxima no iOS
      },
    },
    data: {
      ...data,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
  };

  // Envia em lote se for múltiplos tokens
  if (listaTokens.length === 1) {
    mensagem.token = listaTokens[0];
    return admin.messaging().send(mensagem);
  }

  mensagem.tokens = listaTokens;
  const result = await admin.messaging().sendEachForMulticast(mensagem);
  console.log(`Enviadas: ${result.successCount} | Falhas: ${result.failureCount}`);
  return result;
}

// ─── 1. Notificação de nova mensagem no chat ──────────────────────────────
exports.sendMessageNotification = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const chatId  = context.params.chatId;
    const senderId = message.senderId;
    const text     = message.text || "Nova mensagem";

    // Busca o chat para achar o destinatário
    const chatDoc  = await admin.firestore().collection("chats").doc(chatId).get();
    const chatData = chatDoc.data();
    if (!chatData?.users) return null;

    const receiverId = chatData.users.find(uid => uid !== senderId);
    if (!receiverId) return null;

    // Busca nome do remetente
    const senderDoc  = await admin.firestore().collection("users").doc(senderId).get();
    const senderNome = senderDoc.data()?.nome || "Alguém";

    // Busca token do destinatário
    const userDoc = await admin.firestore().collection("users").doc(receiverId).get();
    const token   = userDoc.data()?.fcmToken;
    if (!token) {
      console.log("Token não encontrado para:", receiverId);
      return null;
    }

    console.log("Enviando notificação de mensagem para:", receiverId);

    return enviarNotificacao(
      token,
      `💬 ${senderNome}`,
      text,
      { tipo: "mensagem", chatId },
    );
  });

// ─── 2. Notificação de novo pedido para todos os profissionais ────────────
exports.notificarNovoPedido = functions.firestore
  .document("requests/{pedidoId}")
  .onCreate(async (snap, context) => {
    const pedido = snap.data();

    // Só notifica pedidos abertos
    if (pedido.status !== "aberto") return null;

    const titulo    = pedido.titulo    || pedido.title    || "Novo serviço disponível";
    const categoria = pedido.categoria || pedido.category || "";
    const corpo     = categoria ? `${categoria} — ${titulo}` : titulo;

    // Busca todos os profissionais com token FCM
    const profSnap = await admin.firestore()
      .collection("users")
      .where("role", "==", "profissional")
      .get();

    if (profSnap.empty) {
      console.log("Nenhum profissional encontrado.");
      return null;
    }

    const tokens = [];
    profSnap.forEach(doc => {
      const token = doc.data()?.fcmToken;
      if (token) tokens.push(token);
    });

    if (tokens.length === 0) {
      console.log("Nenhum token FCM encontrado.");
      return null;
    }

    console.log(`Enviando para ${tokens.length} profissionais: ${corpo}`);

    return enviarNotificacao(
      tokens,
      "🔔 Novo pedido disponível!",
      corpo,
      { tipo: "novo_pedido", pedidoId: context.params.pedidoId },
    );
  });

// ─── 3. Notificação quando profissional aceita o pedido ──────────────────
exports.notificarPedidoAceito = functions.firestore
  .document("requests/{pedidoId}")
  .onUpdate(async (change, context) => {
    const antes  = change.before.data();
    const depois = change.after.data();

    // Só dispara quando muda de "aberto" para "aceito"
    if (antes.status === depois.status) return null;
    if (depois.status !== "aceito") return null;

    const clienteId     = depois.clienteId || depois.userId;
    const profissionalId = depois.profissionalId;
    if (!clienteId) return null;

    // Busca nome do profissional
    let nomeProfissional = "Um profissional";
    if (profissionalId) {
      const profDoc = await admin.firestore().collection("users").doc(profissionalId).get();
      nomeProfissional = profDoc.data()?.nome || "Um profissional";
    }

    // Busca token do cliente
    const clienteDoc = await admin.firestore().collection("users").doc(clienteId).get();
    const token      = clienteDoc.data()?.fcmToken;
    if (!token) return null;

    const titulo = depois.titulo || depois.title || "seu pedido";

    console.log("Notificando cliente que pedido foi aceito:", clienteId);

    return enviarNotificacao(
      token,
      "✅ Pedido aceito!",
      `${nomeProfissional} aceitou: ${titulo}`,
      { tipo: "pedido_aceito", pedidoId: context.params.pedidoId },
    );
  });