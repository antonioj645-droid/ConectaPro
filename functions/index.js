const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendMessageNotification = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {

    const message = snap.data();
    const chatId = context.params.chatId;

    const senderId = message.senderId;
    const text = message.text;

    // 👉 pega dados do chat
    const chatDoc = await admin.firestore()
      .collection("chats")
      .doc(chatId)
      .get();

    const chatData = chatDoc.data();

    if (!chatData || !chatData.users) return null;

    const users = chatData.users;

    // 👉 pega o outro usuário
    const receiverId = users.find(uid => uid !== senderId);

    if (!receiverId) return null;

    // 👉 pega token do outro usuário
    const userDoc = await admin.firestore()
      .collection("users")
      .doc(receiverId)
      .get();

    const token = userDoc.data()?.fcmToken;

    if (!token) return null;

    const payload = {
      notification: {
        title: "Nova mensagem",
        body: text,
      }
    };

    console.log("Enviando notificação para:", token);

    return admin.messaging().sendToDevice(token, payload);
  });