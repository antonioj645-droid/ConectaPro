const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// ─── 1. Notificação de nova mensagem no chat ───────────────────────────────
exports.sendMessageNotification = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const chatId = context.params.chatId;
    const senderId = message.senderId;
    const text = message.text;

    const chatDoc = await admin.firestore()
      .collection("chats")
      .doc(chatId)
      .get();

    const chatData = chatDoc.data();
    if (!chatData || !chatData.users) return null;

    const receiverId = chatData.users.find(uid => uid !== senderId);
    if (!receiverId) return null;

    const userDoc = await admin.firestore()
      .collection("users")
      .doc(receiverId)
      .get();

    const token = userDoc.data()?.fcmToken;
    if (!token) return null;

    const payload = {
      notification: {
        title: "Nova mensagem 💬",
        body: text,
      }
    };

    console.log("Enviando notificação de mensagem para:", receiverId);
    return admin.messaging().sendToDevice(token, payload);
  });

// ─── 2. Notificação de novo pedido para todos os profissionais ─────────────
exports.notificarNovoPedido = functions.firestore
  .document("requests/{pedidoId}")
  .onCreate(async (snap, context) => {
    const pedido = snap.data();

    // Só notifica se o pedido estiver aberto (sem profissional)
    if (pedido.status !== "aberto") return null;

    const titulo   = pedido.titulo   || pedido.title       || "Novo serviço disponível";
    const categoria = pedido.categoria || pedido.category  || "";

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

    const body = categoria
      ? `${categoria} — ${titulo}`
      : titulo;

    const payload = {
      notification: {
        title: "🔔 Novo pedido disponível!",
        body: body,
      },
      data: {
        tipo: "novo_pedido",
        pedidoId: context.params.pedidoId,
      }
    };

    console.log(`Enviando para ${tokens.length} profissionais:`, body);
    return admin.messaging().sendToDevice(tokens, payload);
  });