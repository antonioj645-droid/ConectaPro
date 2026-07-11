import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Serviço central de eventos e logs.
///
/// Centraliza aqui evita espalhar chamadas de Analytics/Crashlytics
/// direto nas telas — se um dia trocar de provedor, só mexe aqui.
///
/// IMPORTANTE: Crashlytics não tem suporte a Flutter Web (só
/// Android/iOS/macOS) — por isso toda chamada a FirebaseCrashlytics
/// aqui é protegida com `if (!kIsWeb)`. O Analytics funciona normal
/// na Web, não precisa dessa proteção.
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Chama isso assim que souber o UID do usuário logado (ex: no AuthCheck).
  /// Faz o Crashlytics e o Analytics associarem os próximos eventos/erros
  /// a esse usuário — essencial pra "reconstruir" o que aconteceu quando
  /// alguém reportar um problema específico.
  static Future<void> identificarUsuario(String uid, {String? role}) async {
    await _analytics.setUserId(id: uid);
    if (role != null) {
      await _analytics.setUserProperty(name: 'role', value: role);
    }
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance.setUserIdentifier(uid);
      if (role != null) {
        FirebaseCrashlytics.instance.setCustomKey('role', role);
      }
    }
  }

  /// Registra que o usuário entrou no app (uma vez por sessão) — dá
  /// visibilidade de usuários ativos no painel do Analytics.
  static Future<void> logLogin() async {
    await _analytics.logLogin(loginMethod: 'app');
  }

  // ─── Eventos do fluxo de pedido ──────────────────────────────────────────
  static Future<void> logPedidoCriado({
    required String pedidoId,
    required String categoria,
    required String subcategoria,
  }) async {
    await _analytics.logEvent(
      name: 'pedido_criado',
      parameters: {
        'pedido_id': pedidoId,
        'categoria': categoria,
        'subcategoria': subcategoria,
      },
    );
    if (!kIsWeb) {
      FirebaseCrashlytics.instance
          .log('Pedido criado: $pedidoId ($categoria / $subcategoria)');
    }
  }

  static Future<void> logPedidoAceito({
    required String pedidoId,
    required String profissionalId,
  }) async {
    await _analytics.logEvent(
      name: 'pedido_aceito',
      parameters: {
        'pedido_id': pedidoId,
        'profissional_id': profissionalId,
      },
    );
    if (!kIsWeb) {
      FirebaseCrashlytics.instance
          .log('Pedido aceito: $pedidoId por $profissionalId');
    }
  }

  static Future<void> logServicoConcluido({
    required String pedidoId,
  }) async {
    await _analytics.logEvent(
      name: 'servico_concluido',
      parameters: {'pedido_id': pedidoId},
    );
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.log('Serviço concluído: $pedidoId');
    }
  }

  // ─── Eventos do fluxo de pagamento (PIX) ─────────────────────────────────
  static Future<void> logPixGerado({
    required String paymentId,
    required double valor,
  }) async {
    await _analytics.logEvent(
      name: 'pix_gerado',
      parameters: {
        'payment_id': paymentId,
        'valor': valor,
      },
    );
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.log('PIX gerado: $paymentId (R\$ $valor)');
    }
  }

  static Future<void> logPixConfirmado({
    required String paymentId,
    required double valor,
  }) async {
    await _analytics.logEvent(
      name: 'pix_confirmado',
      parameters: {
        'payment_id': paymentId,
        'valor': valor,
      },
    );
    if (!kIsWeb) {
      FirebaseCrashlytics.instance
          .log('PIX confirmado: $paymentId (R\$ $valor)');
    }
  }

  // ─── Erros não-fatais que você queira rastrear manualmente ───────────────
  static void logErro(dynamic erro, StackTrace? stack, {String? contexto}) {
    if (kIsWeb) {
      debugPrint('Erro (${contexto ?? "sem contexto"}): $erro');
      return;
    }
    FirebaseCrashlytics.instance.recordError(
      erro,
      stack,
      reason: contexto,
      fatal: false,
    );
  }
}