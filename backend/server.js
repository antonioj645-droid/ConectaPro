require("dotenv").config();
const express = require("express");
const cors = require("cors");
const rateLimit = require("express-rate-limit");

const app = express();

/// ✅ RATE LIMIT
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
});
app.use(limiter);

/// ✅ CORS (TEMPORARIAMENTE LIBERADO PRA TESTAR)
app.use(cors());

/// ✅ JSON
app.use(express.json({ limit: "1mb" }));

/// ✅ HEADER PROTECTION (CORRIGIDO)
app.use((req, res, next) => {
  // ✅ permite requests sem user-agent (curl/flutter)
  next();
});

/// ✅ ROTA TESTE (ANTES DAS OUTRAS)
app.get("/", (req, res) => {
  res.json({
    success: true,
    status: "ONLINE ✅",
    timestamp: new Date().toISOString(),
  });
});

/// ✅ ROTAS PIX (CORRIGIDO CAMINHO)
const pixRoutes = require("./routes/pix");
app.use("/pix", pixRoutes);

/// ✅ WEBHOOK ASAAS
app.post("/webhook/asaas", async (req, res) => {
  try {
    const token = req.headers["asaas-access-token"];

    if (token !== process.env.ASAAS_API_KEY) {
      console.log("🚫 webhook inválido");
      return res.sendStatus(403);
    }

    const data = req.body;

    if (!data || !data.event) {
      return res.sendStatus(400);
    }

    console.log("✅ webhook:", data.event);

    return res.sendStatus(200);

  } catch (error) {
    console.error("Erro webhook:", error);
    return res.sendStatus(500);
  }
});

/// ✅ 404
app.use((req, res) => {
  res.status(404).json({ error: "Rota não encontrada" });
});

/// ✅ ERROR GLOBAL
app.use((err, req, res, next) => {
  console.error("Erro global:", err);
  res.status(500).json({ error: "Erro interno" });
});

/// ✅ PORT
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 Rodando porta ${PORT}`);
});