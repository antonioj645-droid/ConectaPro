import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

// ───────── MODELS ─────────

class AppUser {
  final String id;
  final String email;
  final String role;
  final double balance;

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.balance,
  });

  factory AppUser.fromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: d['email'] ?? '',
      role: d['role'] ?? 'cliente',
      balance: (d['balance'] ?? 0).toDouble(),
    );
  }
}

class Pagamento {
  final String id;
  final double valor;
  final Timestamp? criadoEm;

  const Pagamento({
    required this.id,
    required this.valor,
    this.criadoEm,
  });

  factory Pagamento.fromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Pagamento(
      id: doc.id,
      valor: (d['total'] ?? 0).toDouble(),
      criadoEm: d['createdAt'] is Timestamp ? d['createdAt'] : null,
    );
  }
}

class Pedido {
  final String id;
  final String descricao;
  final String status;
  final String clienteEmail;

  const Pedido({
    required this.id,
    required this.descricao,
    required this.status,
    required this.clienteEmail,
  });

  factory Pedido.fromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Pedido(
      id: doc.id,
      descricao: d['description'] ?? 'Sem descrição',
      status: (d['status'] ?? 'unknown').toString(),
      clienteEmail: d['clienteEmail'] ?? '',
    );
  }
}

// ───────── CORES ─────────

class AppColors {
  static const blue = Color(0xFF185FA5);
  static const green = Color(0xFF3B6D11);
  static const purple = Color(0xFF534AB7);
  static const red = Color(0xFFA32D2D);
  static const orange = Color(0xFFBA7517);
}

// ───────── ADMIN PAGE ─────────

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _index = 0;

  final pages = const [
    DashboardTab(),
    UsuariosTab(),
    ProfissionaisTab(),
    PedidosTab(),
    FinanceiroTab(),
  ];

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel Admin"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          )
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Usuários'),
          NavigationDestination(icon: Icon(Icons.build), label: 'Profissionais'),
          NavigationDestination(icon: Icon(Icons.receipt), label: 'Pedidos'),
          NavigationDestination(icon: Icon(Icons.money), label: 'Financeiro'),
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

            if (!userSnap.hasData ||
                !paySnap.hasData ||
                !reqSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users =
                userSnap.data!.docs.map(AppUser.fromDoc).toList();

            final pagamentos =
                paySnap.data!.docs.map(Pagamento.fromDoc).toList();

            final pedidos =
                reqSnap.data!.docs.map(Pedido.fromDoc).toList();

            final total = pagamentos.fold<double>(
              0,
              (s, p) => s + p.valor,
            );

            final ativos =
                pedidos.where((p) => p.status == 'pending').length;

            final finalizados =
                pedidos.where((p) => p.status == 'completed').length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _card("Usuários", users.length.toString()),
                    _card("Ganhos", "R\$ ${total.toStringAsFixed(2)}"),
                    _card("Ativos", ativos.toString()),
                    _card("Finalizados", finalizados.toString()),
                  ],
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 220,
                  child: _RevenueChart(pagamentos: pagamentos),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card(String t, String v) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(t),
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

    final valid = pagamentos.where((p) => p.criadoEm != null).toList();

    if (valid.isEmpty) {
      return const Center(child: Text("Sem dados"));
    }

    final spots = List.generate(valid.length, (i) {
      return FlSpot(i.toDouble(), valid[i].valor);
    });

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
          )
        ],
      ),
    );
  }
}

// ───────── LISTAS ─────────

class UsuariosTab extends StatelessWidget {
  const UsuariosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView(
          children: docs.map((doc) {
            final u = AppUser.fromDoc(doc);
            return ListTile(
              title: Text(u.email),
              subtitle: Text("Saldo: R\$ ${u.balance}"),
            );
          }).toList(),
        );
      },
    );
  }
}

class ProfissionaisTab extends StatelessWidget {
  const ProfissionaisTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'profissional')
          .snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView(
          children: docs.map((doc) {
            final u = AppUser.fromDoc(doc);
            return ListTile(title: Text(u.email));
          }).toList(),
        );
      },
    );
  }
}

class PedidosTab extends StatelessWidget {
  const PedidosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('requests').snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView(
          children: docs.map((doc) {
            final p = Pedido.fromDoc(doc);
            return ListTile(
              title: Text(p.descricao),
              subtitle: Text(p.status),
            );
          }).toList(),
        );
      },
    );
  }
}

class FinanceiroTab extends StatelessWidget {
  const FinanceiroTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('earnings').snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView(
          children: docs.map((doc) {
            final p = Pagamento.fromDoc(doc);
            return ListTile(
              title: Text("R\$ ${p.valor}"),
            );
          }).toList(),
        );
      },
    );
  }
}