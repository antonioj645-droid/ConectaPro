import 'package:flutter/material.dart';

class PoliticaPrivacidadePage extends StatelessWidget {
  const PoliticaPrivacidadePage({super.key});

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
          'Política de Privacidade',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [

          Text(
            'ConectaPro',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _accent),
          ),
          SizedBox(height: 4),
          Text(
            'Última atualização: junho de 2025',
            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
          SizedBox(height: 24),

          _Section(
            numero: '1',
            titulo: 'Introdução',
            corpo:
              'A ConectaPro está comprometida com a proteção da sua privacidade. '
              'Esta Política descreve como coletamos, usamos, armazenamos e protegemos suas informações pessoais.\n\n'
              'Esta política está em conformidade com a LGPD (Lei nº 13.709/2018) e demais legislações aplicáveis.',
          ),

          _Section(
            numero: '2',
            titulo: 'Dados que Coletamos',
            corpo: 'Coletamos as seguintes categorias de dados pessoais:',
            bullets: [
              'Identificação: nome completo, e-mail e telefone/WhatsApp;',
              'Acesso: informações de login e autenticação;',
              'Uso: histórico de pedidos, avaliações e interações;',
              'Financeiros: histórico de transações e saldo;',
              'Dispositivo: token para envio de notificações push;',
              'Localização: apenas quando necessário para o serviço.',
            ],
          ),

          _Section(
            numero: '3',
            titulo: 'Como Usamos seus Dados',
            corpo: 'Utilizamos seus dados para:',
            bullets: [
              'Criar e gerenciar sua conta;',
              'Conectar clientes a profissionais;',
              'Processar pagamentos e transações;',
              'Enviar notificações sobre pedidos;',
              'Garantir segurança e prevenir fraudes;',
              'Cumprir obrigações legais.',
            ],
          ),

          _Section(
            numero: '4',
            titulo: 'Base Legal para o Tratamento',
            corpo: 'O tratamento dos seus dados é realizado com base na LGPD:',
            bullets: [
              'Execução de contrato: para prestação dos serviços solicitados;',
              'Consentimento: para envio de comunicações;',
              'Legítimo interesse: para melhorias e prevenção de fraudes;',
              'Obrigação legal: quando exigido por lei ou autoridade.',
            ],
          ),

          _Section(
            numero: '5',
            titulo: 'Compartilhamento de Dados',
            corpo: 'Não vendemos seus dados. Compartilhamos apenas com:',
            bullets: [
              'Profissionais/clientes envolvidos no serviço contratado;',
              'Provedores de infraestrutura (Firebase/Google);',
              'Processadores de pagamento;',
              'Autoridades públicas, quando exigido por lei.',
            ],
          ),

          _Section(
            numero: '6',
            titulo: 'Armazenamento e Segurança',
            corpo:
              'Seus dados são armazenados em servidores seguros do Firebase (Google Cloud), '
              'com criptografia em trânsito e em repouso, autenticação segura e acesso restrito a funcionários autorizados.',
          ),

          _Section(
            numero: '7',
            titulo: 'Retenção de Dados',
            corpo: '',
            bullets: [
              'Dados de conta: enquanto sua conta estiver ativa;',
              'Dados de transações: por até 5 anos (exigência legal);',
              'Dados de uso: por até 2 anos;',
              'Após encerramento da conta, dados são anonimizados ou excluídos.',
            ],
          ),

          _Section(
            numero: '8',
            titulo: 'Seus Direitos (LGPD)',
            corpo: 'Você tem direito a:',
            bullets: [
              'Acessar seus dados pessoais;',
              'Corrigir dados incompletos ou incorretos;',
              'Solicitar a exclusão dos seus dados;',
              'Portabilidade dos dados;',
              'Revogar o consentimento a qualquer momento;',
              'Opor-se ao tratamento baseado em legítimo interesse.',
            ],
          ),

          _Section(
            numero: '9',
            titulo: 'Crianças e Adolescentes',
            corpo:
              'O ConectaPro não é destinado a menores de 18 anos. '
              'Não coletamos intencionalmente dados de crianças. '
              'Caso identificado, excluiremos essas informações imediatamente.',
          ),

          _Section(
            numero: '10',
            titulo: 'Alterações nesta Política',
            corpo:
              'Podemos atualizar esta Política periodicamente. '
              'Quando houver alterações significativas, notificaremos você pelo aplicativo ou por e-mail. '
              'O uso continuado do app após as alterações constitui aceitação da nova política.',
          ),

          _Section(
            numero: '11',
            titulo: 'Contato — DPO',
            corpo: 'Para dúvidas ou solicitações sobre privacidade:',
            bullets: [
              'E-mail: conectapro.oficia@gmail.com',
              'Aplicativo: acesse "Ajuda" no menu principal',
              'Prazo de resposta: até 15 dias úteis',
            ],
          ),

          SizedBox(height: 16),
          Divider(color: Color(0xFFE0E0E0)),
          SizedBox(height: 12),
          Text(
            'ConectaPro — Sua privacidade é nossa prioridade',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _textSecondary, fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28, height: 28,
                decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  numero,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (corpo.isNotEmpty)
            Text(
              corpo,
              style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF333333)),
            ),
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
                      child: CircleAvatar(radius: 3, backgroundColor: _accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF333333)),
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
