import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

import 'chat_page.dart';
import '../main.dart';

// ───────── MODELS ─────────

class AppUser {
  final String id, email, role, nome;
  final double balance;
  final bool ativo;
  final bool verificado;
  final int cancelamentosProfissional;
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.nome,
    required this.balance,
    required this.ativo,
    required this.verificado,
    required this.cancelamentosProfissional,
  });
  factory AppUser.fromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: d['email'] ?? '',
      nome: d['nome'] ?? d['email'] ?? 'Sem nome',
      role: d['role'] ?? 'cliente',
      balance: (d['balance'] ?? 0).toDouble(),
      // Campo pode não existir em contas antigas — trata ausência como ativo.
      ativo: d['ativo'] ?? true,
      verificado: d['verificado'] ?? false,
      cancelamentosProfissional: (d['cancelamentosProfissional'] ?? 0) is int
          ? (d['cancelamentosProfissional'] ?? 0) as int
          : (d['cancelamentosProfissional'] as num).toInt(),
    );
  }
}

class Pagamento {
  final String id;
  final double valor;
  final Timestamp? criadoEm;
  final String clienteNome;
  final String profissionalNome;
  final String servico;
  final String metodoPagamento;
  const Pagamento({
    required this.id,
    required this.valor,
    this.criadoEm,
    required this.clienteNome,
    required this.profissionalNome,
    required this.servico,
    required this.metodoPagamento,
  });
  factory Pagamento.fromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Pagamento(
      id: doc.id,
      valor: (d['total'] ?? d['valor'] ?? 0).toDouble(),
      criadoEm: d['createdAt'] is Timestamp ? d['createdAt'] : null,
      clienteNome: d['clienteNome'] ?? d['clienteEmail'] ?? 'Cliente',
      profissionalNome: d['profissionalNome'] ?? d['profissionalEmail'] ?? 'Profissional',
      servico: d['servicoTitulo'] ?? d['titulo'] ?? d['descricao'] ?? 'Serviço',
      metodoPagamento: d['metodoPagamento'] ?? d['paymentMethod'] ?? 'Não informado',
    );
  }
}

class Pedido {
  final String id, descricao, status, clienteEmail;
  const Pedido({required this.id, required this.descricao, required this.status, required this.clienteEmail});
  factory Pedido.fromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Pedido(
      id: doc.id,
      descricao: d['titulo'] ?? d['description'] ?? 'Sem descrição',
      status: (d['status'] ?? 'pendente').toString(),
      clienteEmail: d['clienteEmail'] ?? '',
    );
  }
}

// ───────── TEMA ─────────

const _black   = Color(0xFF0A0A0A);
const _white   = Color(0xFFFFFFFF);
const _accent  = Color(0xFF276EF1);
const _surface = Color(0xFFF2F4F8);
const _card    = Color(0xFFFFFFFF);
const _grey    = Color(0xFF8A8A8E);
const _green   = Color(0xFF34C759);
const _orange  = Color(0xFFFF9500);
const _red     = Color(0xFFFF3B30);

// ───────── ADMIN PAGE ─────────

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _index = 0;

  final _pages = const [
    DashboardTab(),
    UsuariosTab(),
    ProfissionaisTab(),
    PedidosTab(),
    FinanceiroTab(),
    SuporteTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _black,
        foregroundColor: _white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings, color: _white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Painel Admin',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthCheck()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      // ───────── BOTTOM NAV (FIX: fonte menor + 1 linha, não quebra mais "Financeiro"/"Dashboard") ─────────
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? _accent : _grey,
                overflow: TextOverflow.ellipsis,
                height: 1.1,
              );
            }),
          ),
        ),
        child: NavigationBar(
          height: 64,
          backgroundColor: _white,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          indicatorColor: const Color.fromRGBO(39, 110, 241, 0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined, size: 22), selectedIcon: Icon(Icons.dashboard, color: _accent, size: 22), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.people_outline, size: 22), selectedIcon: Icon(Icons.people, color: _accent, size: 22), label: 'Usuários'),
            NavigationDestination(icon: Icon(Icons.build_outlined, size: 22), selectedIcon: Icon(Icons.build, color: _accent, size: 22), label: 'Profissionais'),
            NavigationDestination(icon: Icon(Icons.receipt_outlined, size: 22), selectedIcon: Icon(Icons.receipt, color: _accent, size: 22), label: 'Pedidos'),
            NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined, size: 22), selectedIcon: Icon(Icons.account_balance_wallet, color: _accent, size: 22), label: 'Financeiro'),
            NavigationDestination(icon: Icon(Icons.support_agent_outlined, size: 22), selectedIcon: Icon(Icons.support_agent, color: _accent, size: 22), label: 'Suporte'),
          ],
        ),
      ),
    );
  }
}

// ───────── DASHBOARD ─────────

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});
  static final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _db.collection('users').snapshots(),
      builder: (context, userSnap) => StreamBuilder(
        stream: _db.collection('earnings').snapshots(),
        builder: (context, paySnap) => StreamBuilder(
          stream: _db.collection('requests').snapshots(),
          builder: (context, reqSnap) {
            if (!userSnap.hasData || !paySnap.hasData || !reqSnap.hasData) {
              return const Center(child: CircularProgressIndicator(color: _accent));
            }

            final users      = userSnap.data!.docs.map(AppUser.fromDoc).toList();
            final pagamentos = paySnap.data!.docs.map(Pagamento.fromDoc).toList();
            final pedidos    = reqSnap.data!.docs.map(Pedido.fromDoc).toList();

            final totalGanhos   = pagamentos.fold<double>(0, (s, p) => s + p.valor);
            final profissionais = users.where((u) => u.role == 'profissional').length;
            final pendentes     = pedidos.where((p) => p.status == 'pendente').length;
            final aceitos       = pedidos.where((p) => p.status == 'aceito').length;
            final concluidos    = pedidos.where((p) => p.status == 'concluido').length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1A2E), Color(0xFF276EF1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(39, 110, 241, 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Visão Geral',
                                  style: TextStyle(color: Color(0xFFB0C4FF), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                              SizedBox(height: 4),
                              Text('ConectaPro+',
                                  style: TextStyle(color: _white, fontSize: 22, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(255,255,255,0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.trending_up, color: _white, size: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Total em ganhos',
                          style: TextStyle(color: Color(0xFFB0C4FF), fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('R\$ ${totalGanhos.toStringAsFixed(2)}',
                          style: const TextStyle(color: _white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      const SizedBox(height: 16),
                      // ───────── BADGES (FIX: Flexible + ellipsis, não corta mais "16 pedidos") ─────────
                      Row(
                        children: [
                          Flexible(child: _HeaderBadge(label: '${users.length} usuários', icon: Icons.people)),
                          const SizedBox(width: 8),
                          Flexible(child: _HeaderBadge(label: '$profissionais profissionais', icon: Icons.build)),
                          const SizedBox(width: 8),
                          Flexible(child: _HeaderBadge(label: '${pedidos.length} pedidos', icon: Icons.receipt)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Métricas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _black)),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    _MetricCard(label: 'Usuários', value: users.length.toString(), icon: Icons.people_alt_rounded, color: _accent),
                    _MetricCard(label: 'Profissionais', value: profissionais.toString(), icon: Icons.construction_rounded, color: _green),
                    _MetricCard(label: 'Pendentes', value: pendentes.toString(), icon: Icons.hourglass_empty_rounded, color: _orange),
                    _MetricCard(label: 'Concluídos', value: concluidos.toString(), icon: Icons.check_circle_rounded, color: _green),
                    _MetricCard(label: 'Em andamento', value: aceitos.toString(), icon: Icons.pending_actions_rounded, color: _accent),
                    _MetricCard(label: 'Total pedidos', value: pedidos.length.toString(), icon: Icons.receipt_long_rounded, color: _grey),
                  ],
                ),
                const SizedBox(height: 24),

                if (pagamentos.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Receita',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _black)),
                      Text('${pagamentos.length} registros',
                          style: const TextStyle(fontSize: 12, color: _grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color.fromRGBO(0,0,0,0.06), blurRadius: 16, offset: const Offset(0,4))],
                    ),
                    child: _RevenueChart(pagamentos: pagamentos),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  const _HeaderBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255,255,255,0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _white, size: 12),
          const SizedBox(width: 4),
          // FIX: texto encolhe e corta com "..." em vez de vazar pra fora do card
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: _white, fontSize: 11, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color.fromRGBO(0,0,0,0.06), blurRadius: 12, offset: const Offset(0,4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Color.fromRGBO(color.red, color.green, color.blue, 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _black, height: 1)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 12, color: _grey, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────── GRÁFICO ─────────

class _RevenueChart extends StatelessWidget {
  final List<Pagamento> pagamentos;
  const _RevenueChart({required this.pagamentos});

  @override
  Widget build(BuildContext context) {
    final valid = pagamentos.where((p) => p.valor > 0).toList();
    if (valid.isEmpty) return const Center(child: Text('Sem dados'));

    final spots = List.generate(
        valid.length, (i) => FlSpot(i.toDouble(), valid[i].valor));

    return LineChart(LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF0F0F0), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          getTitlesWidget: (v, _) => Text('R\$${v.toInt()}',
              style: const TextStyle(fontSize: 10, color: _grey)),
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: _accent,
          barWidth: 3,
          dotData: FlDotData(show: spots.length <= 10),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                const Color.fromRGBO(39, 110, 241, 0.18),
                const Color.fromRGBO(39, 110, 241, 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    ));
  }
}

// ───────── BUSCA (reutilizado por Usuários e Profissionais) ─────────

class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: const Color.fromRGBO(0,0,0,0.05), blurRadius: 8, offset: const Offset(0,3))],
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: _black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: _grey),
          prefixIcon: const Icon(Icons.search, color: _grey, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }
}

// ───────── DETALHE / AÇÕES DO USUÁRIO ─────────

class _UserDetailSheet extends StatefulWidget {
  final AppUser user;
  const _UserDetailSheet({required this.user});

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  bool _salvando = false;

  Future<void> _alternarAtivo() async {
    setState(() => _salvando = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({'ativo': !widget.user.ativo});
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e')),
        );
      }
    }
  }

  Future<void> _alternarVerificado() async {
    setState(() => _salvando = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({'verificado': !widget.user.verificado});
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isPro = user.role == 'profissional';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: isPro ? const Color.fromRGBO(52,199,89,0.15) : const Color.fromRGBO(39,110,241,0.12),
                  child: Icon(isPro ? Icons.build : Icons.person, color: isPro ? _green : _accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _black)),
                      Text(user.email, style: const TextStyle(fontSize: 13, color: _grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(label: isPro ? 'Profissional' : 'Cliente', color: isPro ? _green : _accent),
                _Badge(label: user.ativo ? 'Ativo' : 'Suspenso', color: user.ativo ? _green : _red),
                if (isPro)
                  _Badge(label: user.verificado ? 'Verificado' : 'Não verificado', color: user.verificado ? _accent : _grey),
                if (isPro)
                  _Badge(
                    label: user.cancelamentosProfissional == 0
                        ? 'Sem cancelamentos'
                        : '${user.cancelamentosProfissional} cancelamento${user.cancelamentosProfissional == 1 ? '' : 's'}',
                    color: user.cancelamentosProfissional == 0
                        ? _green
                        : (user.cancelamentosProfissional <= 2 ? _orange : _red),
                  ),
                _Badge(label: 'Saldo: R\$ ${user.balance.toStringAsFixed(2)}', color: _grey),
              ],
            ),
            const SizedBox(height: 24),

            if (isPro) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _salvando ? null : _alternarVerificado,
                  icon: Icon(user.verificado ? Icons.remove_moderator_outlined : Icons.verified_outlined),
                  label: Text(user.verificado ? 'Remover verificação' : 'Marcar como verificado'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: const BorderSide(color: _accent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvando ? null : _alternarAtivo,
                icon: _salvando
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _white))
                    : Icon(user.ativo ? Icons.block : Icons.check_circle_outline),
                label: Text(user.ativo ? 'Suspender conta' : 'Reativar conta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: user.ativo ? _red : _green,
                  foregroundColor: _white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            if (user.ativo) ...[
              const SizedBox(height: 8),
              const Text(
                'Suspender bloqueia o uso do app pra essa conta (é preciso que a checagem de "ativo" também exista na tela de login do app).',
                style: TextStyle(fontSize: 11, color: _grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Color.fromRGBO(color.red, color.green, color.blue, 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ───────── USUÁRIOS ─────────

class UsuariosTab extends StatefulWidget {
  const UsuariosTab({super.key});
  @override
  State<UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<UsuariosTab> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _accent));

        var users = snapshot.data!.docs.map(AppUser.fromDoc).toList();

        if (_busca.trim().isNotEmpty) {
          final q = _busca.trim().toLowerCase();
          users = users.where((u) =>
              u.nome.toLowerCase().contains(q) || u.email.toLowerCase().contains(q)).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _SearchField(
                hint: 'Buscar por nome ou e-mail',
                onChanged: (v) => setState(() => _busca = v),
              ),
            ),
            Expanded(
              child: _buildListaUsuarios(
                context: context,
                titulo: '${users.length} usuários',
                users: users,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final isPro = user.role == 'profissional';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: _white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => _UserDetailSheet(user: user),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: const Color.fromRGBO(0,0,0,0.05), blurRadius: 8, offset: const Offset(0,3))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isPro ? const Color.fromRGBO(52,199,89,0.15) : const Color.fromRGBO(39,110,241,0.12),
              child: Icon(isPro ? Icons.build : Icons.person, color: isPro ? _green : _accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(user.nome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _black),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (!user.ativo) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.block, size: 13, color: _red),
                      ],
                      if (isPro && user.verificado) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, size: 13, color: _accent),
                      ],
                      if (isPro && user.cancelamentosProfissional > 2) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.flag_rounded, size: 13, color: _red),
                      ],
                    ],
                  ),
                  Text(user.email, style: const TextStyle(fontSize: 12, color: _grey),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPro ? const Color.fromRGBO(52,199,89,0.12) : const Color.fromRGBO(39,110,241,0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(isPro ? 'Pro' : 'Cliente',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isPro ? _green : _accent)),
                ),
                const SizedBox(height: 4),
                Text('R\$ ${user.balance.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: _grey, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────── PROFISSIONAIS ─────────

class ProfissionaisTab extends StatefulWidget {
  const ProfissionaisTab({super.key});
  @override
  State<ProfissionaisTab> createState() => _ProfissionaisTabState();
}

class _ProfissionaisTabState extends State<ProfissionaisTab> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'profissional').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _accent));

        var users = snapshot.data!.docs.map(AppUser.fromDoc).toList();

        if (_busca.trim().isNotEmpty) {
          final q = _busca.trim().toLowerCase();
          users = users.where((u) =>
              u.nome.toLowerCase().contains(q) || u.email.toLowerCase().contains(q)).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Atalho pra revisar os documentos dos entregadores
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _DocsEntregadoresBanner(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _SearchField(
                hint: 'Buscar por nome ou e-mail',
                onChanged: (v) => setState(() => _busca = v),
              ),
            ),
            Expanded(
              child: _buildListaUsuarios(
                context: context,
                titulo: '${users.length} profissionais',
                users: users,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ───────── DOCUMENTOS DOS ENTREGADORES ─────────

// Card no topo da aba Profissionais, com a contagem de documentos pendentes.
class _DocsEntregadoresBanner extends StatelessWidget {
  const _DocsEntregadoresBanner();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('docs_entregador')
          .where('status', isEqualTo: 'pendente')
          .snapshots(),
      builder: (context, snap) {
        final n = snap.hasData ? snap.data!.docs.length : 0;

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DocsEntregadoresPage()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: const Color.fromRGBO(0,0,0,0.05), blurRadius: 8, offset: const Offset(0,3))],
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(39,110,241,0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.badge_outlined, color: _accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Documentos de entregadores',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _black)),
                      Text(
                        n == 0
                            ? 'Nenhum aguardando análise'
                            : '$n aguardando análise',
                        style: TextStyle(
                            fontSize: 12,
                            color: n == 0 ? _grey : _orange,
                            fontWeight: n == 0 ? FontWeight.w500 : FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                if (n > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$n',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: _white, fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios, size: 14, color: _grey),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Lista dos documentos enviados, filtrada por status.
class DocsEntregadoresPage extends StatefulWidget {
  const DocsEntregadoresPage({super.key});
  @override
  State<DocsEntregadoresPage> createState() => _DocsEntregadoresPageState();
}

class _DocsEntregadoresPageState extends State<DocsEntregadoresPage> {
  String _filtro = 'pendente';

  static const _filtros = {
    'pendente': 'Pendentes',
    'aprovado': 'Aprovados',
    'reprovado': 'Reprovados',
  };

  Color _corStatus(String s) {
    switch (s) {
      case 'aprovado':  return _green;
      case 'reprovado': return _red;
      default:          return _orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _black,
        foregroundColor: _white,
        elevation: 0,
        title: const Text('Documentos de entregadores',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: _filtros.entries.map((e) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: e.key == 'reprovado' ? 0 : 8),
                    child: _FiltroBotao(
                      label: e.value,
                      ativo: _filtro == e.key,
                      onTap: () => setState(() => _filtro = e.key),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('docs_entregador')
                  .where('status', isEqualTo: _filtro)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Erro ao carregar: ${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _red)),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: _accent));
                }

                final docs = snap.data!.docs.toList();
                // Mais antigos primeiro (quem está esperando há mais tempo)
                docs.sort((a, b) {
                  final ta = (a.data() as Map<String, dynamic>)['enviadoEm'];
                  final tb = (b.data() as Map<String, dynamic>)['enviadoEm'];
                  if (ta is Timestamp && tb is Timestamp) {
                    return ta.compareTo(tb);
                  }
                  return 0;
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: _grey),
                        SizedBox(height: 8),
                        Text('Nenhum documento aqui',
                            style: TextStyle(color: _grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc   = docs[i];
                    final d     = doc.data() as Map<String, dynamic>;
                    final nome  = (d['nome'] ?? '').toString().isEmpty
                        ? 'Sem nome'
                        : d['nome'].toString();
                    final placa = (d['placa'] ?? '').toString();
                    final tipo  = (d['tipoVeiculo'] ?? '').toString();
                    final cor   = _corStatus(_filtro);

                    String dataStr = '';
                    if (d['enviadoEm'] is Timestamp) {
                      final dt = (d['enviadoEm'] as Timestamp).toDate();
                      dataStr =
                          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                    }

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DocEntregadorDetalhe(uid: doc.id, dados: d),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: const Color.fromRGBO(0, 0, 0, 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(
                                    cor.red, cor.green, cor.blue, 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.two_wheeler, color: cor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nome,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: _black),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text(
                                    [
                                      if (tipo.isNotEmpty) tipo,
                                      if (placa.isNotEmpty) placa,
                                      if (dataStr.isNotEmpty) 'enviado em $dataStr',
                                    ].join(' · '),
                                    style: const TextStyle(
                                        fontSize: 12, color: _grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                size: 14, color: _grey),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Tela de análise: mostra placa, fotos e botões de aprovar/reprovar.
class DocEntregadorDetalhe extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> dados;
  const DocEntregadorDetalhe({super.key, required this.uid, required this.dados});

  @override
  State<DocEntregadorDetalhe> createState() => _DocEntregadorDetalheState();
}

class _DocEntregadorDetalheState extends State<DocEntregadorDetalhe> {
  static const _tipos = {
    'selfie':  'Selfie',
    'cnh':     'CNH',
    'crlv':    'Documento do veículo (CRLV)',
    'veiculo': 'Foto do veículo',
  };

  final Map<String, Uint8List> _imgs = {};
  bool _carregando = true;
  bool _salvando   = false;
  String _status   = '';
  String _motivo   = '';

  @override
  void initState() {
    super.initState();
    _status = (widget.dados['status'] ?? 'pendente').toString();
    _motivo = (widget.dados['motivoReprovacao'] ?? '').toString();
    _carregarImagens();
  }

  Future<void> _carregarImagens() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('docs_entregador')
          .doc(widget.uid)
          .collection('arquivos')
          .get();
      for (final a in snap.docs) {
        final b64 = (a.data()['base64'] ?? '') as String;
        if (b64.isNotEmpty) _imgs[a.id] = base64Decode(b64);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar imagens: $e'), backgroundColor: _red),
        );
      }
    }
    if (mounted) setState(() => _carregando = false);
  }

  void _ampliar(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: Center(child: Image.memory(bytes)),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: _white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pedirMotivo() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reprovar documentos'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Motivo (ex: CNH ilegível, placa não confere)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _red, foregroundColor: _white),
            onPressed: () {
              final t = ctrl.text.trim();
              if (t.isEmpty) return;
              Navigator.pop(ctx, t);
            },
            child: const Text('Reprovar'),
          ),
        ],
      ),
    );
  }

  Future<void> _decidir(String novoStatus, {String motivo = ''}) async {
    setState(() => _salvando = true);
    try {
      await FirebaseFirestore.instance
          .collection('docs_entregador')
          .doc(widget.uid)
          .update({
        'status':           novoStatus,
        'motivoReprovacao': motivo,
        'analisadoEm':      FieldValue.serverTimestamp(),
        'analisadoPor':     FirebaseAuth.instance.currentUser?.uid ?? '',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(novoStatus == 'aprovado'
              ? 'Documentos aprovados ✅'
              : 'Documentos reprovados'),
          backgroundColor: novoStatus == 'aprovado' ? _green : _red,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: _red),
        );
      }
    }
  }

  Future<void> _reprovar() async {
    final motivo = await _pedirMotivo();
    if (motivo == null) return;
    await _decidir('reprovado', motivo: motivo);
  }

  @override
  Widget build(BuildContext context) {
    final d      = widget.dados;
    final nome   = (d['nome'] ?? '').toString().isEmpty ? 'Sem nome' : d['nome'].toString();
    final placa  = (d['placa'] ?? '').toString();
    final tipo   = (d['tipoVeiculo'] ?? '').toString();

    Color corStatus;
    String labelStatus;
    switch (_status) {
      case 'aprovado':
        corStatus = _green;
        labelStatus = 'Aprovado';
        break;
      case 'reprovado':
        corStatus = _red;
        labelStatus = 'Reprovado';
        break;
      default:
        corStatus = _orange;
        labelStatus = 'Em análise';
    }

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _black,
        foregroundColor: _white,
        elevation: 0,
        title: const Text('Analisar documentos',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // ── Dados ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: const Color.fromRGBO(0, 0, 0, 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _black)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Badge(label: labelStatus, color: corStatus),
                          if (tipo.isNotEmpty) _Badge(label: tipo, color: _accent),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text('Placa informada',
                          style: TextStyle(fontSize: 12, color: _grey)),
                      const SizedBox(height: 2),
                      Text(placa.isEmpty ? '—' : placa,
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: _black)),
                      const SizedBox(height: 6),
                      const Text(
                        'Confira se a placa bate com o documento do veículo e com a foto.',
                        style: TextStyle(fontSize: 11, color: _grey),
                      ),
                      if (_status == 'reprovado' && _motivo.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('Motivo anterior: $_motivo',
                            style: const TextStyle(fontSize: 12, color: _red)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Imagens ──
                ..._tipos.entries.map((e) {
                  final bytes = _imgs[e.key];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: const Color.fromRGBO(0, 0, 0, 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.value,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _black)),
                        const SizedBox(height: 8),
                        if (bytes == null)
                          Container(
                            height: 70,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Não enviada',
                                style: TextStyle(color: _grey, fontSize: 13)),
                          )
                        else
                          GestureDetector(
                            onTap: () => _ampliar(bytes),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                bytes,
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        if (bytes != null)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text('Toque na imagem para ampliar',
                                style: TextStyle(fontSize: 11, color: _grey)),
                          ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 6),

                // ── Ações ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _salvando ? null : () => _decidir('aprovado'),
                    icon: _salvando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _white))
                        : const Icon(Icons.verified_user),
                    label: const Text('Aprovar documentos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: _white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _salvando ? null : _reprovar,
                    icon: const Icon(Icons.block),
                    label: const Text('Reprovar (com motivo)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: const BorderSide(color: _red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ───────── PEDIDOS ─────────

class PedidosTab extends StatelessWidget {
  const PedidosTab({super.key});

  Color _corStatus(String s) {
    switch (s) {
      case 'aceito':    return _accent;
      case 'concluido': return _green;
      case 'cancelado': return _red;
      default:          return _orange;
    }
  }

  String _labelStatus(String s) {
    switch (s) {
      case 'pendente':  return 'Aguardando';
      case 'aceito':    return 'Em andamento';
      case 'concluido': return 'Concluído';
      case 'cancelado': return 'Cancelado';
      default:          return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('requests')
          .orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _accent));
        final pedidos = snapshot.data!.docs.map(Pedido.fromDoc).toList();
        return _buildLista(
          titulo: '${pedidos.length} pedidos',
          items: pedidos.map((p) {
            final cor = _corStatus(p.status);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: const Color.fromRGBO(0,0,0,0.05), blurRadius: 8, offset: const Offset(0,3))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(cor.red, cor.green, cor.blue, 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.receipt_long_outlined, color: cor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.descricao, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _black),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (p.clienteEmail.isNotEmpty)
                          Text(p.clienteEmail, style: const TextStyle(fontSize: 12, color: _grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(cor.red, cor.green, cor.blue, 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_labelStatus(p.status),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cor)),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ───────── FINANCEIRO ─────────

enum _PeriodoFiltro { hoje, semana, mes }

class FinanceiroTab extends StatefulWidget {
  const FinanceiroTab({super.key});
  @override
  State<FinanceiroTab> createState() => _FinanceiroTabState();
}

class _FinanceiroTabState extends State<FinanceiroTab> {
  _PeriodoFiltro _periodo = _PeriodoFiltro.hoje;

  bool _dentroDoPeriodo(DateTime? data) {
    if (data == null) return false;
    final agora = DateTime.now();
    switch (_periodo) {
      case _PeriodoFiltro.hoje:
        return data.year == agora.year && data.month == agora.month && data.day == agora.day;
      case _PeriodoFiltro.semana:
        return agora.difference(data).inDays <= 7;
      case _PeriodoFiltro.mes:
        return data.year == agora.year && data.month == agora.month;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('earnings')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _accent));

        final todos = snapshot.data!.docs.map(Pagamento.fromDoc).toList();
        final filtrados = todos.where((p) => _dentroDoPeriodo(p.criadoEm?.toDate())).toList();

        final total = filtrados.fold<double>(0, (s, p) => s + p.valor);
        final ticketMedio = filtrados.isEmpty ? 0.0 : total / filtrados.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Filtro de período ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Expanded(child: _FiltroBotao(label: 'Hoje', ativo: _periodo == _PeriodoFiltro.hoje, onTap: () => setState(() => _periodo = _PeriodoFiltro.hoje))),
                  const SizedBox(width: 8),
                  Expanded(child: _FiltroBotao(label: 'Semana', ativo: _periodo == _PeriodoFiltro.semana, onTap: () => setState(() => _periodo = _PeriodoFiltro.semana))),
                  const SizedBox(width: 8),
                  Expanded(child: _FiltroBotao(label: 'Mês', ativo: _periodo == _PeriodoFiltro.mes, onTap: () => setState(() => _periodo = _PeriodoFiltro.mes))),
                ],
              ),
            ),

            // ─── Card de total em destaque ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color.fromRGBO(0,0,0,0.06), blurRadius: 12, offset: const Offset(0,4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total recebido', style: TextStyle(fontSize: 13, color: _grey, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('R\$ ${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _green)),
                    const SizedBox(height: 6),
                    Text('${filtrados.length} transação${filtrados.length == 1 ? '' : 'ões'} confirmada${filtrados.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 12, color: _grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ─── Ticket médio ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: const Color.fromRGBO(0,0,0,0.05), blurRadius: 8, offset: const Offset(0,3))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ticket médio', style: TextStyle(fontSize: 13, color: _grey, fontWeight: FontWeight.w500)),
                    Text('R\$ ${ticketMedio.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _black)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Transações',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _grey, letterSpacing: 0.8)),
            ),

            // ─── Lista de transações com contexto ───
            Expanded(
              child: filtrados.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: _grey),
                          SizedBox(height: 8),
                          Text('Nenhuma transação neste período', style: TextStyle(color: _grey)),
                        ],
                      ),
                    )
                  : ListView(
                      children: filtrados.map((p) {
                        final data = p.criadoEm?.toDate();
                        final dataStr = data != null
                            ? '${data.day.toString().padLeft(2,'0')}/${data.month.toString().padLeft(2,'0')}/${data.year}'
                            : 'Data desconhecida';
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: const Color.fromRGBO(0,0,0,0.05), blurRadius: 8, offset: const Offset(0,3))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(52,199,89,0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.attach_money, color: _green, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.profissionalNome,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _black),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text('${p.servico} · $dataStr',
                                        style: const TextStyle(fontSize: 12, color: _grey),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('R\$ ${p.valor.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _black)),
                                  const SizedBox(height: 2),
                                  const Icon(Icons.check_circle, color: _green, size: 16),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _FiltroBotao extends StatelessWidget {
  final String label;
  final bool ativo;
  final VoidCallback onTap;
  const _FiltroBotao({required this.label, required this.ativo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: ativo ? _accent : _card,
          borderRadius: BorderRadius.circular(10),
          boxShadow: ativo ? [] : [BoxShadow(color: const Color.fromRGBO(0,0,0,0.05), blurRadius: 6, offset: const Offset(0,2))],
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ativo ? _white : _grey)),
      ),
    );
  }
}

// ───────── SUPORTE ─────────

class SuporteTab extends StatelessWidget {
  const SuporteTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('suporte_chats')
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _accent));
        }
        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('${docs.length} conversas de suporte',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _grey, letterSpacing: 0.8)),
            ),
            Expanded(
              child: docs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.support_agent_outlined, size: 48, color: _grey),
                          SizedBox(height: 8),
                          Text('Nenhuma conversa ainda', style: TextStyle(color: _grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final data    = docs[i].data() as Map<String, dynamic>;
                        final nome    = data['nome'] ?? 'Usuário';
                        final tipo    = data['tipo'] ?? 'cliente';
                        final chatId  = data['chatId'] ?? '';
                        final isPro   = tipo == 'profissional';

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: const Color.fromRGBO(0,0,0,0.05), blurRadius: 8, offset: const Offset(0,3))],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            leading: CircleAvatar(
                              backgroundColor: isPro
                                  ? const Color.fromRGBO(52,199,89,0.15)
                                  : const Color.fromRGBO(39,110,241,0.12),
                              child: Icon(isPro ? Icons.build : Icons.person,
                                  color: isPro ? _green : _accent, size: 18),
                            ),
                            title: Text(nome,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _black)),
                            subtitle: Text(isPro ? 'Profissional' : 'Cliente',
                                style: const TextStyle(fontSize: 12, color: _grey)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: _grey),
                            onTap: () {
                              if (chatId.toString().isEmpty) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(chatId: chatId.toString()),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ───────── HELPERS ─────────

Widget _buildLista({required String titulo, required List<Widget> items}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(titulo,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _grey, letterSpacing: 0.8)),
      ),
      Expanded(
        child: items.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: _grey),
                    SizedBox(height: 8),
                    Text('Nenhum item', style: TextStyle(color: _grey)),
                  ],
                ),
              )
            : ListView(children: items),
      ),
    ],
  );
}

// Lista de usuários/profissionais com título + estado vazio, sem a
// barra de busca (que fica fora, na tela, pra não recriar o TextField
// a cada rebuild do StreamBuilder e perder o foco durante a digitação).
Widget _buildListaUsuarios({
  required BuildContext context,
  required String titulo,
  required List<AppUser> users,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Text(titulo,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _grey, letterSpacing: 0.8)),
      ),
      Expanded(
        child: users.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: _grey),
                    SizedBox(height: 8),
                    Text('Nenhum resultado', style: TextStyle(color: _grey)),
                  ],
                ),
              )
            : ListView(children: users.map((u) => _UserTile(user: u)).toList()),
      ),
    ],
  );
}