import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

// ───────── MODELS ─────────

class AppUser {
  final String id, email, role, nome;
  final double balance;
  const AppUser({required this.id, required this.email, required this.role, required this.nome, required this.balance});
  factory AppUser.fromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: d['email'] ?? '',
      nome: d['nome'] ?? d['email'] ?? 'Sem nome',
      role: d['role'] ?? 'cliente',
      balance: (d['balance'] ?? 0).toDouble(),
    );
  }
}

class Pagamento {
  final String id;
  final double valor;
  final Timestamp? criadoEm;
  const Pagamento({required this.id, required this.valor, this.criadoEm});
  factory Pagamento.fromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Pagamento(
      id: doc.id,
      valor: (d['total'] ?? d['valor'] ?? 0).toDouble(),
      criadoEm: d['createdAt'] is Timestamp ? d['createdAt'] : null,
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

const _black   = Color(0xFF000000);
const _white   = Color(0xFFFFFFFF);
const _accent  = Color(0xFF276EF1);
const _surface = Color(0xFFF6F6F6);
const _card    = Color(0xFFFFFFFF);
const _grey    = Color(0xFF757575);
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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _black,
        foregroundColor: _white,
        elevation: 0,
        title: const Text('Painel Admin',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: _white,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        indicatorColor: const Color.fromRGBO(39, 110, 241, 0.12),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: _accent), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people, color: _accent), label: 'Usuários'),
          NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build, color: _accent), label: 'Profissionais'),
          NavigationDestination(icon: Icon(Icons.receipt_outlined), selectedIcon: Icon(Icons.receipt, color: _accent), label: 'Pedidos'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet, color: _accent), label: 'Financeiro'),
        ],
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

            final users     = userSnap.data!.docs.map(AppUser.fromDoc).toList();
            final pagamentos = paySnap.data!.docs.map(Pagamento.fromDoc).toList();
            final pedidos   = reqSnap.data!.docs.map(Pedido.fromDoc).toList();

            final totalGanhos  = pagamentos.fold<double>(0, (s, p) => s + p.valor);
            final profissionais = users.where((u) => u.role == 'profissional').length;
            final pendentes    = pedidos.where((p) => p.status == 'pendente').length;
            final aceitos      = pedidos.where((p) => p.status == 'aceito').length;
            final concluidos   = pedidos.where((p) => p.status == 'concluido').length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Saudação
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Visão Geral', style: TextStyle(color: _white, fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Total em ganhos: R\$ ${totalGanhos.toStringAsFixed(2)}',
                          style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Cards métricas
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _MetricCard(label: 'Usuários', value: users.length.toString(), icon: Icons.people, color: _accent),
                    _MetricCard(label: 'Profissionais', value: profissionais.toString(), icon: Icons.build, color: _green),
                    _MetricCard(label: 'Pendentes', value: pendentes.toString(), icon: Icons.hourglass_empty, color: _orange),
                    _MetricCard(label: 'Concluídos', value: concluidos.toString(), icon: Icons.check_circle, color: _green),
                    _MetricCard(label: 'Em andamento', value: aceitos.toString(), icon: Icons.pending_actions, color: _accent),
                    _MetricCard(label: 'Total pedidos', value: pedidos.length.toString(), icon: Icons.receipt_long, color: _grey),
                  ],
                ),
                const SizedBox(height: 20),

                // Gráfico
                if (pagamentos.isNotEmpty) ...[
                  const Text('Receita por pagamento',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: const Color.fromRGBO(0,0,0,0.06), blurRadius: 12, offset: const Offset(0,4))],
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

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: const Color.fromRGBO(0,0,0,0.06), blurRadius: 10, offset: const Offset(0,3))],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Color.fromRGBO(color.red, color.green, color.blue, 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _black)),
                Text(label, style: const TextStyle(fontSize: 11, color: _grey)),
              ],
            ),
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
      gridData: FlGridData(show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFFEEEEEE), strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40,
            getTitlesWidget: (v, _) => Text('R\$${v.toInt()}', style: const TextStyle(fontSize: 10, color: _grey)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: _accent,
          barWidth: 3,
          dotData: FlDotData(show: spots.length <= 10),
          belowBarData: BarAreaData(
            show: true,
            color: const Color.fromRGBO(39, 110, 241, 0.08),
          ),
        ),
      ],
    ));
  }
}

// ───────── USUÁRIOS ─────────

class UsuariosTab extends StatelessWidget {
  const UsuariosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _accent));
        final users = snapshot.data!.docs.map(AppUser.fromDoc).toList();
        return _buildLista(
          titulo: '${users.length} usuários',
          items: users.map((u) => _UserTile(user: u)).toList(),
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
          CircleAvatar(
            backgroundColor: isPro ? const Color.fromRGBO(52,199,89,0.15) : const Color.fromRGBO(39,110,241,0.12),
            child: Icon(isPro ? Icons.build : Icons.person, color: isPro ? _green : _accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.nome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _black),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
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
    );
  }
}

// ───────── PROFISSIONAIS ─────────

class ProfissionaisTab extends StatelessWidget {
  const ProfissionaisTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'profissional').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _accent));
        final users = snapshot.data!.docs.map(AppUser.fromDoc).toList();
        return _buildLista(
          titulo: '${users.length} profissionais',
          items: users.map((u) => _UserTile(user: u)).toList(),
        );
      },
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

class FinanceiroTab extends StatelessWidget {
  const FinanceiroTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('earnings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _accent));
        final pagamentos = snapshot.data!.docs.map(Pagamento.fromDoc).toList();
        final total = pagamentos.fold<double>(0, (s, p) => s + p.valor);

        return _buildLista(
          titulo: 'Total: R\$ ${total.toStringAsFixed(2)}',
          items: pagamentos.map((p) {
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
                        Text('R\$ ${p.valor.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _black)),
                        Text(dataStr, style: const TextStyle(fontSize: 12, color: _grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: _green, size: 18),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ───────── HELPER ─────────

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