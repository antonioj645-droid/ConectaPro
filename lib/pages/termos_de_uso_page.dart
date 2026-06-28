import 'package:flutter/material.dart';

class TermosDeUsoPage extends StatelessWidget {
  const TermosDeUsoPage({super.key});

  static const _black         = Color(0xFF000000);
  static const _white         = Color(0xFFFFFFFF);
  static const _accent        = Color(0xFF276EF1);
  static const _surface       = Color(0xFFF6F6F6);
  static const _textSecondary = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _black,
        foregroundColor: _white,
        elevation: 0,
        title: const Text(
          'Termos de Uso',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [

          // Cabeçalho
          Text(
            'ConectaPro',
            style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w900, color: _accent,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Última atualização: junho de 2025',
            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
          SizedBox(height: 24),

          _Section(
            numero: '1',
            titulo: 'Aceitação dos Termos',
            corpo:
              'Ao baixar, instalar ou utilizar o ConectaPro, você concorda integralmente com estes Termos de Uso. '
              'Se não concordar com qualquer parte, não utilize o aplicativo.\n\n'
              'Reservamo-nos o direito de alterar estes Termos a qualquer momento, '
              'mediante aviso prévio no aplicativo.',
          ),

          _Section(
            numero: '2',
            titulo: 'Descrição do Serviço',
            corpo:
              'O ConectaPro é uma plataforma de marketplace que conecta clientes a profissionais autônomos de serviços. '
              'Atuamos como intermediário tecnológico, não sendo parte da relação contratual entre clientes e profissionais.\n\n'
              'A ConectaPro não garante a qualidade ou adequação dos serviços oferecidos pelos profissionais cadastrados.',
          ),

          _Section(
            numero: '3',
            titulo: 'Cadastro e Conta de Usuário',
            corpo: 'Para utilizar o ConectaPro, você deve:',
            bullets: [
              'Ter pelo menos 18 anos de idade;',
              'Fornecer informações verdadeiras e completas no cadastro;',
              'Manter suas informações de conta atualizadas;',
              'Manter a confidencialidade de suas credenciais de acesso.',
            ],
          ),

          _Section(
            numero: '4',
            titulo: 'Tipos de Usuário',
            corpo: 'Clientes contratam serviços e são responsáveis por descrever com precisão o serviço desejado e realizar o pagamento acordado.\n\n'
              'Profissionais oferecem serviços e são responsáveis por executá-los com qualidade, cumprir obrigações fiscais e manter sigilo sobre informações dos clientes.',
          ),

          _Section(
            numero: '5',
            titulo: 'Pagamentos e Taxas',
            corpo: 'O ConectaPro processa pagamentos de forma segura. Ao realizar uma transação, você concorda que:',
            bullets: [
              'Os valores são definidos livremente pelos profissionais;',
              'A plataforma pode cobrar taxa de intermediação;',
              'Pagamentos fora da plataforma não são cobertos pela nossa proteção;',
              'Estornos seguem a política de cancelamento vigente.',
            ],
          ),

          _Section(
            numero: '6',
            titulo: 'Conduta do Usuário',
            corpo: 'É expressamente proibido:',
            bullets: [
              'Publicar informações falsas ou fraudulentas;',
              'Assediar ou ameaçar outros usuários;',
              'Negociar fora da plataforma para burlar taxas;',
              'Utilizar o app para fins ilegais;',
              'Criar contas falsas ou representar outra pessoa.',
            ],
          ),

          _Section(
            numero: '7',
            titulo: 'Privacidade e Proteção de Dados',
            corpo:
              'O ConectaPro está comprometido com a proteção dos seus dados pessoais, em conformidade com a LGPD (Lei nº 13.709/2018). '
              'Coletamos apenas os dados necessários para a prestação do serviço, como nome, e-mail, telefone e histórico de transações.\n\n'
              'Não vendemos seus dados a terceiros.',
          ),

          _Section(
            numero: '8',
            titulo: 'Cancelamento e Reembolso',
            corpo: '',
            bullets: [
              'Cancelamentos antes do início do serviço podem ser reembolsados integralmente;',
              'Cancelamentos após o início estão sujeitos a avaliação;',
              'Disputas serão mediadas pela plataforma;',
              'Valores podem ser retidos em caso de suspeita de fraude.',
            ],
          ),

          _Section(
            numero: '9',
            titulo: 'Propriedade Intelectual',
            corpo:
              'Todo o conteúdo do ConectaPro — textos, imagens, logotipos, código-fonte e design — é de propriedade exclusiva da ConectaPro ou de seus licenciantes. '
              'É vedada a reprodução ou uso comercial sem autorização expressa e por escrito.',
          ),

          _Section(
            numero: '10',
            titulo: 'Limitação de Responsabilidade',
            corpo: 'A ConectaPro não se responsabiliza por:',
            bullets: [
              'Danos decorrentes da execução dos serviços pelos profissionais;',
              'Falhas temporárias no aplicativo por manutenção ou causas externas;',
              'Condutas de terceiros, incluindo outros usuários.',
            ],
          ),

          _Section(
            numero: '11',
            titulo: 'Rescisão e Suspensão',
            corpo:
              'A ConectaPro pode suspender ou encerrar sua conta em casos de violação destes Termos, comportamento fraudulento ou determinação judicial. '
              'Você pode encerrar sua conta a qualquer momento nas configurações do aplicativo.',
          ),

          _Section(
            numero: '12',
            titulo: 'Disposições Gerais',
            corpo:
              'Estes Termos são regidos pelas leis da República Federativa do Brasil. '
              'Fica eleito o foro da comarca de Curitiba/PR para dirimir quaisquer controvérsias, '
              'com renúncia expressa a qualquer outro.',
          ),

          _Section(
            numero: '13',
            titulo: 'Contato',
            corpo: 'Para dúvidas ou reclamações, entre em contato:',
            bullets: [
              'E-mail: suporte@conectapro.com.br',
              'Aplicativo: acesse "Ajuda" no menu principal',
            ],
          ),

          SizedBox(height: 16),
          Divider(color: Color(0xFFE0E0E0)),
          SizedBox(height: 12),

          Text(
            'ConectaPro — Conectando você aos melhores profissionais',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12, color: _textSecondary, fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Widget auxiliar de seção ───────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String numero;
  final String titulo;
  final String corpo;
  final List<String> bullets;

  const _Section({
    required this.numero,
    required this.titulo,
    required this.corpo,
    this.bullets = const [],
  });

  static const _black  = Color(0xFF000000);
  static const _accent = Color(0xFF276EF1);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Título da seção
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28, height: 28,
                decoration: const BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  numero,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Corpo
          if (corpo.isNotEmpty)
            Text(
              corpo,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Color(0xFF333333),
              ),
            ),

          // Bullets
          if (bullets.isNotEmpty) ...[
            if (corpo.isNotEmpty) const SizedBox(height: 8),
            ...bullets.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: CircleAvatar(
                        radius: 3,
                        backgroundColor: _accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
