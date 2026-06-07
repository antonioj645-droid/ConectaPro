require('dotenv').config();

const express = require('express');
const cors = require('cors');

// ✅ Firebase
const admin = require('firebase-admin');

const app = express();

// ✅ 🔥 ESSA LINHA RESOLVE O PROBLEMA DO RENDER
app.set('trust proxy', 1);

// ✅ MIDDLEWARES
app.use(cors());
app.use(express.json());

// =========================
// ✅ FIREBASE
// =========================
try {

  if (!process.env.FIREBASE_KEY) {
    throw new Error("FIREBASE_KEY não encontrada.");
  }

  const serviceAccount =
    JSON.parse(process.env.FIREBASE_KEY);

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  console.log("✅ Firebase conectado com sucesso");

} catch (err) {
  console.error("❌ Erro ao iniciar Firebase:", err.message);
  process.exit(1);
}

// =========================
// ✅ ROTAS
// =========================
const pixRoutes = require('./routes/pix');

// ✅ prefixo /pix
app.use('/pix', pixRoutes);

// =========================
// ✅ ROTA TESTE
// =========================
app.get('/', (req, res) => {
  res.send('✅ Backend ConectaPro rodando');
});

// =========================
// ✅ PORTA (Render usa essa)
// =========================
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 Servidor rodando na porta ${PORT}`);
});
