require('dotenv').config();

const express = require('express');
const axios = require('axios');
const cors = require('cors');

const app = express();

/*
==================================================
MIDDLEWARES
==================================================
*/

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type'],
}));

app.use(express.json());

/*
==================================================
CONFIGURAÇÕES
==================================================
*/

const PORT = 3000;

const ASAAS_API_KEY = process.env.ASAAS_API_KEY;

if (!ASAAS_API_KEY) {

  console.log('====================================');
  console.log('❌ ERRO: API KEY NÃO ENCONTRADA');
  console.log('====================================');
  console.log('Crie um arquivo .env');
  console.log('====================================');

  process.exit(1);
}

const BASE_URL = 'https://api.asaas.com/v3';

const headers = {
  access_token: ASAAS_API_KEY,
  'Content-Type': 'application/json'
};

/*
==================================================
FUNÇÕES
==================================================
*/

// ✅ DATA +1 DIA
function getDueDate() {

  const date = new Date();

  date.setDate(date.getDate() + 1);

  return date.toISOString().split('T')[0];
}

// ✅ ESPERAR PIX
async function gerarPix(paymentId) {

  for (let i = 0; i < 10; i++) {

    try {

      const response = await axios.get(
        `${BASE_URL}/payments/${paymentId}/pixQrCode`,
        {
          headers,
          timeout: 15000,
        }
      );

      if (
        response.data &&
        response.data.payload
      ) {

        return response.data;
      }

    } catch (error) {

      console.log('⏳ Aguardando PIX...');

    }

    await new Promise(
      resolve => setTimeout(resolve, 1500)
    );
  }

  throw new Error('PIX não ficou pronto');
}

// ✅ BUSCAR CLIENTE
async function buscarCliente(email) {

  try {

    const response = await axios.get(
      `${BASE_URL}/customers?email=${email}`,
      {
        headers,
        timeout: 15000,
      }
    );

    if (
      response.data &&
      response.data.data &&
      response.data.data.length > 0
    ) {

      return response.data.data[0];
    }

    return null;

  } catch (e) {

    return null;
  }
}

// ✅ CRIAR CLIENTE
async function criarCliente(
  nome,
  email,
  cpfCnpj
) {

  const response = await axios.post(
    `${BASE_URL}/customers`,
    {
      name: nome,
      email: email,
      cpfCnpj: cpfCnpj
    },
    {
      headers,
      timeout: 15000,
    }
  );

  return response.data;
}

/*
==================================================
ROTAS
==================================================
*/

// ✅ TESTE API
app.get('/', (req, res) => {

  return res.json({
    success: true,
    status: 'ONLINE'
  });

});

// ✅ CRIAR PIX
app.post('/criar-pix', async (req, res) => {

  console.log('====================================');
  console.log('🚀 NOVA REQUISIÇÃO PIX');
  console.log('====================================');

  try {

    const {
      valor,
      email,
      nome,
      cpfCnpj
    } = req.body;

    console.log(req.body);

    /*
    ==========================================
    VALIDAÇÕES
    ==========================================
    */

    if (!valor || Number(valor) <= 0) {

      return res.status(400).json({
        success: false,
        error: 'Valor inválido'
      });
    }

    if (!email) {

      return res.status(400).json({
        success: false,
        error: 'Email obrigatório'
      });
    }

    /*
    ==========================================
    BUSCAR CLIENTE
    ==========================================
    */

    let cliente = await buscarCliente(email);

    /*
    ==========================================
    CRIAR CLIENTE
    ==========================================
    */

    if (!cliente) {

      console.log('👤 Criando cliente...');

      cliente = await criarCliente(
        nome || 'Cliente App',
        email,
        cpfCnpj || '12345678909'
      );

    } else {

      console.log('✅ Cliente encontrado');

    }

    /*
    ==========================================
    CRIAR PAGAMENTO PIX
    ==========================================
    */

    console.log('💰 Criando pagamento PIX...');

    const pagamentoResponse = await axios.post(
      `${BASE_URL}/payments`,
      {
        customer: cliente.id,
        billingType: 'PIX',
        value: Number(valor),
        dueDate: getDueDate(),
        description: 'Pagamento PIX'
      },
      {
        headers,
        timeout: 15000,
      }
    );

    const paymentId = pagamentoResponse.data.id;

    console.log('✅ Pagamento criado:', paymentId);

    /*
    ==========================================
    GERAR PIX
    ==========================================
    */

    const pix = await gerarPix(paymentId);

    console.log('✅ PIX GERADO');

    /*
    ==========================================
    RETORNO
    ==========================================
    */

    return res.json({

      success: true,

      paymentId: paymentId,

      valor: valor,

      pixCopiaECola: pix.payload,

      qrCodeBase64: pix.encodedImage,

      expirationDate: pix.expirationDate
    });

  } catch (error) {

    console.log('====================================');
    console.log('❌ ERRO ASAAS');
    console.log('====================================');

    if (error.response?.data) {

      console.log(
        JSON.stringify(
          error.response.data,
          null,
          2
        )
      );

    } else {

      console.log(error.message);

    }

    console.log('====================================');

    const erroMensagem =
      error.response?.data?.errors?.[0]?.description ||
      error.response?.data?.message ||
      error.message;

    return res.status(500).json({
      success: false,
      error: erroMensagem
    });
  }
});

// ✅ VERIFICAR STATUS PAGAMENTO
app.get('/verificar-pagamento/:id', async (req, res) => {

  try {

    const paymentId = req.params.id;

    const response = await axios.get(
      `${BASE_URL}/payments/${paymentId}`,
      {
        headers,
        timeout: 15000,
      }
    );

    return res.json({
      success: true,
      status: response.data.status
    });

  } catch (e) {

    return res.status(500).json({
      success: false,
      error: e.message
    });
  }
});

/*
==================================================
START SERVIDOR
==================================================
*/

app.listen(PORT, '0.0.0.0', () => {

  console.log('====================================');
  console.log('🔥 SERVIDOR RODANDO');
  console.log(`🌎 http://localhost:${PORT}`);
  console.log('====================================');

});