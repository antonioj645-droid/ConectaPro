import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class NovoPedidoPage extends StatefulWidget {
  final String? categoriaInicial;
  final String? subcategoriaInicial;
  const NovoPedidoPage({super.key, this.categoriaInicial, this.subcategoriaInicial});

  @override
  State<NovoPedidoPage> createState() => _NovoPedidoPageState();
}

class _NovoPedidoPageState extends State<NovoPedidoPage> {
  static const _black = Color(0xFF000000);
  static const _white = Color(0xFFFFFFFF);
  static const _accent = Color(0xFF276EF1);

  final _formKey       = GlobalKey<FormState>();
  final _tituloCtrl    = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _cepCtrl       = TextEditingController();
  final _bairroCtrl    = TextEditingController();
  final _cidadeCtrl    = TextEditingController();
  final _estadoCtrl    = TextEditingController();
  final _valorMinCtrl  = TextEditingController();
  final _valorMaxCtrl  = TextEditingController();

  bool _carregando = false;
  bool _buscandoCep = false;
  String? _categoriaSelecionada;
  String? _subcategoriaSelecionada;

  static const Map<String, List<String>> _categorias = {
    'Casa e Construção': [
      'Pedreiro','Servente','Pintor','Azulejista','Gesseiro','Drywall',
      'Marceneiro','Carpinteiro','Serralheiro','Vidraceiro','Telhadista',
      'Impermeabilização','Calheiro','Instalador de Piso',
      'Instalador de Porcelanato','Marmoraria','Jardinagem','Paisagismo',
      'Piscinas','Cercas e Portões',
    ],
    'Elétrica': [
      'Eletricista Residencial','Eletricista Predial','Eletricista Industrial',
      'Instalação de Chuveiro','Instalação de Ventilador',
      'Instalação de Luminárias','Padrão de Energia','Energia Solar',
      'Automação Residencial',
    ],
    'Hidráulica': [
      'Encanador','Desentupimento','Caça Vazamentos',
      'Instalação de Caixa d\'Água','Instalação de Bombas',
      'Aquecedores','Limpeza de Caixa d\'Água',
    ],
    'Refrigeração e Climatização': [
      'Ar-Condicionado','Geladeira','Freezer','Câmara Fria',
      'Máquina de Lavar','Secadora','Lava e Seca','Micro-ondas',
      'Purificador de Água',
    ],
    'Assistência Técnica': [
      'Celulares','Smartphones','Tablets','Computadores','Notebooks',
      'Impressoras','Videogames','TVs','Monitores','Redes Wi-Fi',
      'Câmeras de Segurança','Alarmes','Interfones',
    ],
    'Automotivo': [
      'Mecânico','Eletricista Automotivo','Chaveiro Automotivo','Guincho',
      'Borracheiro','Troca de Bateria','Troca de Óleo','Lava Rápido',
      'Martelinho de Ouro','Funilaria','Pintura Automotiva',
      'Higienização','Insulfilm','Som Automotivo',
    ],
    'Limpeza': [
      'Limpeza Residencial','Limpeza Comercial','Limpeza Pós-Obra',
      'Faxina','Diarista','Limpeza de Estofados','Limpeza de Sofás',
      'Limpeza de Colchões','Limpeza de Tapetes','Limpeza de Piscinas',
      'Limpeza de Vidros',
    ],
    'Mudanças e Fretes': [
      'Frete','Carreto','Mudanças Residenciais','Mudanças Comerciais',
      'Montagem de Móveis','Desmontagem de Móveis',
    ],
    'Chaveiro': [
      'Residencial','Comercial','Automotivo','Cofres','Fechaduras Digitais',
    ],
    'Segurança': [
      'Instalação de Câmeras','Alarmes','Cerca Elétrica',
      'Portão Eletrônico','Controle de Acesso',
    ],
    'Tecnologia': [
      'Desenvolvimento de Sites','Desenvolvimento de Apps','Suporte Técnico',
      'Formatação','Recuperação de Dados','Redes',
      'Instalação de Softwares','Configuração de Impressoras',
    ],
    'Beleza': [
      'Cabeleireiro','Barbeiro','Maquiador','Designer de Sobrancelhas',
      'Manicure','Pedicure','Esteticista','Massagista','Depilação',
    ],
    'Saúde e Bem-estar': [
      'Personal Trainer','Nutricionista','Psicólogo','Fisioterapeuta',
      'Massoterapia','Cuidador de Idosos','Cuidador Infantil',
    ],
    'Eventos': [
      'Fotógrafo','Filmagem','DJ','Banda','Garçom','Churrasqueiro',
      'Decorador','Cerimonialista','Recreador Infantil',
    ],
    'Educação': [
      'Professor Particular','Reforço Escolar','Idiomas','Música',
      'Informática','Preparatório para Concursos',
    ],
    'Pet': [
      'Banho e Tosa','Passeador','Adestrador','Pet Sitter',
      'Veterinário Domiciliar',
    ],
    'Moda': [
      'Costureira','Ajustes de Roupas','Bordados','Personal Stylist',
    ],
    'Serviços Empresariais': [
      'Contador','Advogado','Consultoria','Marketing Digital',
      'Social Media','Designer Gráfico','Redator','Tradução',
    ],
    'Entregas': [
      'Motoboy','Bike Entregador','Entregador de Carro',
    ],
    'Outros Serviços': [
      'Dedetização','Controle de Pragas','Lavagem de Caixa d\'Água',
      'Soldador','Tapeceiro','Restauração de Móveis',
      'Escavação','Poço Artesiano',
    ],
  };

  @override
  void initState() {
    super.initState();
    _categoriaSelecionada    = widget.categoriaInicial;
    _subcategoriaSelecionada = widget.subcategoriaInicial;
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descricaoCtrl.dispose();
    _cepCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeCtrl.dispose();
    _estadoCtrl.dispose();
    _valorMinCtrl.dispose();
    _valorMaxCtrl.dispose();
    super.dispose();
  }

  // ─── Busca endereço automaticamente a partir do CEP (API ViaCEP) ───────────
  Future<void> _buscarCep() async {
    final cep = _cepCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CEP inválido. Digite os 8 números.')));
      return;
    }

    setState(() => _buscandoCep = true);
    try {
      final response = await http
          .get(Uri.parse('https://viacep.com.br/ws/$cep/json/'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['erro'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CEP não encontrado')));
          return;
        }
        setState(() {
          _bairroCtrl.text = data['bairro'] ?? '';
          _cidadeCtrl.text = data['localidade'] ?? '';
          _estadoCtrl.text = data['uf'] ?? '';
        });
      } else {
        throw Exception('Erro ao consultar CEP');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível buscar o CEP. Preencha manualmente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria')));
      return;
    }
    if (_subcategoriaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma especialidade')));
      return;
    }

    // Valida faixa de valor estimado, se preenchida
    double? valorMin;
    double? valorMax;
    if (_valorMinCtrl.text.trim().isNotEmpty || _valorMaxCtrl.text.trim().isNotEmpty) {
      valorMin = double.tryParse(_valorMinCtrl.text.trim().replaceAll(',', '.'));
      valorMax = double.tryParse(_valorMaxCtrl.text.trim().replaceAll(',', '.'));
      if (valorMin == null || valorMax == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe valores válidos para a faixa estimada')));
        return;
      }
      if (valorMax < valorMin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O valor máximo deve ser maior ou igual ao mínimo')));
        return;
      }
    }

    setState(() => _carregando = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      // Código de confirmação (estilo iFood) — só o cliente vê,
      // e só passa pro profissional quando o serviço estiver pronto.
      final codigoConfirmacao =
          (100 + Random().nextInt(900)).toString() + Random().nextInt(10).toString();

      final docRef = await FirebaseFirestore.instance.collection('requests').add({
        'clienteId':    user.uid,
        'titulo':       _tituloCtrl.text.trim(),
        'descricao':    _descricaoCtrl.text.trim(),
        'categoria':    _categoriaSelecionada,
        'subcategoria': _subcategoriaSelecionada,
        'bairro':       _bairroCtrl.text.trim(),
        'cep':          _cepCtrl.text.trim(),
        'cidade':       _cidadeCtrl.text.trim(),
        'estado':       _estadoCtrl.text.trim(),
        'valorEstimadoMin': valorMin,
        'valorEstimadoMax': valorMax,
        'visualizacoes': 0,
        'status':       'aberto',
        'criadoEm':     FieldValue.serverTimestamp(),
        'providerId':   null,
        'chatId':       null,
        'valorServico': null,
        'comissaoPaga': false,
        'codigoConfirmacao': codigoConfirmacao,
      });

      try {
        await http.post(
          Uri.parse('https://conectapro-backend-1.onrender.com/pedidos/novo-pedido'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'pedidoId':     docRef.id,
            'titulo':       _tituloCtrl.text.trim(),
            'categoria':    _categoriaSelecionada ?? '',
            'subcategoria': _subcategoriaSelecionada ?? '',
          }),
        );
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido enviado com sucesso!')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _selecionarCategoria() async {
    final escolha = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            const Text('Selecione a categoria',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(controller: ctrl,
                children: _categorias.keys.map((cat) => ListTile(
                  title: Text(cat),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(_, cat),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );

    if (escolha != null) {
      setState(() {
        _categoriaSelecionada    = escolha;
        _subcategoriaSelecionada = null;
      });
    }
  }

  void _selecionarSubcategoria() async {
    if (_categoriaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria primeiro')));
      return;
    }

    final subs = _categorias[_categoriaSelecionada!] ?? [];
    final escolha = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text(_categoriaSelecionada!,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(controller: ctrl,
                children: subs.map((sub) => ListTile(
                  title: Text(sub),
                  onTap: () => Navigator.pop(_, sub),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );

    if (escolha != null) {
      setState(() => _subcategoriaSelecionada = escolha);
    }
  }

  InputDecoration _decoracaoPadrao({
    required String label,
    required String hint,
    required IconData icone,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icone, color: const Color(0xFF757575)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: _black,
        foregroundColor: _white,
        elevation: 0,
        title: const Text('Novo Pedido',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // TÍTULO
            TextFormField(
              controller: _tituloCtrl,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Informe o título' : null,
              decoration: _decoracaoPadrao(
                label: 'Título do serviço',
                hint: 'Ex: Trocar tomada na sala',
                icone: Icons.title,
              ),
            ),

            const SizedBox(height: 16),

            // DESCRIÇÃO
            TextFormField(
              controller: _descricaoCtrl,
              maxLines: 3,
              decoration: _decoracaoPadrao(
                label: 'Descrição (opcional)',
                hint: 'Detalhe o que precisa ser feito',
                icone: Icons.notes,
              ),
            ),

            const SizedBox(height: 16),

            // CEP
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cepCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _decoracaoPadrao(
                      label: 'CEP',
                      hint: 'Ex: 83000000',
                      icone: Icons.markunread_mailbox_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _buscandoCep ? null : _buscarCep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: _buscandoCep
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: _white, strokeWidth: 2),
                          )
                        : const Text('Buscar',
                            style: TextStyle(
                                color: _white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Preenche bairro, cidade e estado automaticamente.',
                style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
              ),
            ),

            const SizedBox(height: 16),

            // BAIRRO
            TextFormField(
              controller: _bairroCtrl,
              decoration: _decoracaoPadrao(
                label: 'Bairro',
                hint: 'Ex: Centro',
                icone: Icons.location_on_outlined,
              ),
            ),

            const SizedBox(height: 16),

            // CIDADE E ESTADO
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _cidadeCtrl,
                    decoration: _decoracaoPadrao(
                      label: 'Cidade',
                      hint: 'Ex: Curitiba',
                      icone: Icons.location_city_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _estadoCtrl,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 2,
                    decoration: _decoracaoPadrao(
                      label: 'UF',
                      hint: 'PR',
                      icone: Icons.flag_outlined,
                    ).copyWith(counterText: ''),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // FAIXA DE VALOR ESTIMADO
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _valorMinCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _decoracaoPadrao(
                      label: 'Valor mín. (R\$)',
                      hint: 'Ex: 80',
                      icone: Icons.attach_money,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _valorMaxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _decoracaoPadrao(
                      label: 'Valor máx. (R\$)',
                      hint: 'Ex: 150',
                      icone: Icons.attach_money,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Opcional, mas ajuda o profissional a decidir se vale a pena.',
                style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
              ),
            ),

            const SizedBox(height: 16),

            // CATEGORIA
            GestureDetector(
              onTap: _selecionarCategoria,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.category_outlined, color: Color(0xFF757575)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _categoriaSelecionada ?? 'Selecione a categoria',
                        style: TextStyle(
                          fontSize: 16,
                          color: _categoriaSelecionada != null
                              ? _black : const Color(0xFF757575)),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFFBBBBBB)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // SUBCATEGORIA
            GestureDetector(
              onTap: _selecionarSubcategoria,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: _categoriaSelecionada != null
                      ? Colors.white : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.build_outlined, color: Color(0xFF757575)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _subcategoriaSelecionada ?? 'Selecione a especialidade',
                        style: TextStyle(
                          fontSize: 16,
                          color: _subcategoriaSelecionada != null
                              ? _black : const Color(0xFF757575)),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFFBBBBBB)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // BOTÃO
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _carregando ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                ),
                child: _carregando
                    ? const CircularProgressIndicator(color: _white, strokeWidth: 2)
                    : const Text('Enviar pedido',
                        style: TextStyle(color: _white, fontSize: 16,
                          fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
