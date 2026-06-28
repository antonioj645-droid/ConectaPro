import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilProfissionalPage extends StatelessWidget {
  final String providerId;

  const PerfilProfissionalPage({super.key, required this.providerId});

  static const _black         = Color(0xFF000000);
  static const _white         = Color(0xFFFFFFFF);
  static const _accent        = Color(0xFF276EF1);
  static const _surface       = Color(0xFFF6F6F6);
  static const _textSecondary = Color(0xFF757575);
  static const _green         = Color(0xFF34C759);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _black,
        foregroundColor: _white,
        elevation: 0,
        title: const Text(
          'Perfil do Profissional',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(providerId)
            .get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _accent));
          }

          if (!snap.hasData || !snap.data!.exists) {
            return const Center(
              child: Text(
                'Profissional não encontrado.',
                style: TextStyle(color: _textSecondary),
              ),
            );
          }

          final data = snap.data!.data() as Map<String, dynamic>;
          final nome      = data['nome'] ?? data['email'] ?? 'Profissional';
          final email     = data['email'] ?? '';
          final telefone  = data['telefone'] ?? '';
          final categoria = data['categoria'] ?? data['especialidade'] ?? '';
          final bio       = data['bio'] ?? data['descricao'] ?? '';
          final media     = ((data['mediaAvaliacao'] ?? 0) as num).toDouble();
          final total     = ((data['totalAvaliacoes'] ?? 0) as num).toInt();
          final fotoUrl   = data['fotoUrl'] ?? data['photoUrl'] ?? '';
          final fotoBase64 = data['fotoBase64'] ?? '';

          // Resolve a imagem: base64 tem prioridade, depois URL
          ImageProvider? imagemFoto;
          if (fotoBase64.isNotEmpty) {
            try {
              final bytes = base64Decode(fotoBase64);
              imagemFoto = MemoryImage(bytes);
            } catch (_) {}
          } else if (fotoUrl.isNotEmpty) {
            imagemFoto = NetworkImage(fotoUrl);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: _accent.withOpacity(0.1),
                  backgroundImage: imagemFoto,
                  child: imagemFoto == null
                      ? Text(
                          nome.isNotEmpty ? nome[0].toUpperCase() : 'P',
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: _accent),
                        )
                      : null,
                ),
                const SizedBox(height: 16),

                // Nome
                Text(
                  nome,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _black),
                  textAlign: TextAlign.center,
                ),

                // Categoria
                if (categoria.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    categoria,
                    style: const TextStyle(
                        fontSize: 14,
                        color: _accent,
                        fontWeight: FontWeight.w600),
                  ),
                ],

                // Avaliação
                if (media > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBE6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star,
                            color: Color(0xFFFFCC00), size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${media.toStringAsFixed(1)}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _black),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($total avaliações)',
                          style: const TextStyle(
                              fontSize: 13, color: _textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Informações
                _infoRow(Icons.email_outlined, 'E-mail', email),
                if (telefone.isNotEmpty)
                  _infoRow(Icons.phone_outlined, 'Telefone', telefone),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sobre',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _black),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bio,
                    style: const TextStyle(
                        fontSize: 14,
                        color: _textSecondary,
                        height: 1.5),
                  ),
                ],

                // Avaliações recentes
                const SizedBox(height: 24),
                _buildAvaliacoesRecentes(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _accent),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: _textSecondary)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _black)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvaliacoesRecentes() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('requests')
          .where('providerId', isEqualTo: providerId)
          .where('status', isEqualTo: 'concluido')
          .orderBy('avaliadoEm', descending: true)
          .limit(5)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final docs = snap.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['avaliacao'] != null;
        }).toList();

        if (docs.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Avaliações recentes',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _black),
            ),
            const SizedBox(height: 12),
            ...docs.map((doc) {
              final data       = doc.data() as Map<String, dynamic>;
              final nota       = (data['avaliacao'] as num).toInt();
              final comentario = data['comentario'] ?? '';
              final titulo     = data['titulo'] ?? data['descricao'] ?? 'Serviço';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < nota ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFCC00),
                          size: 16,
                        ),
                      ),
                    ),
                    if (titulo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(titulo,
                          style: const TextStyle(
                              fontSize: 12,
                              color: _accent,
                              fontWeight: FontWeight.w600)),
                    ],
                    if (comentario.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(comentario,
                          style: const TextStyle(
                              fontSize: 13, color: _textSecondary)),
                    ],
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}