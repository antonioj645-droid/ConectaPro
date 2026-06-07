import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';

// ✅ NOVO IMPORT (NOTIFICAÇÃO LOCAL)
import 'services/notification_service.dart';

// PÁGINAS
import 'pages/login_page.dart';
import 'pages/area_cliente_page.dart';
import 'pages/area_profissional_page.dart';
import 'pages/admin_page.dart';

// SPLASH
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ INICIALIZA NOTIFICAÇÃO LOCAL
  await NotificationService.init();

  // ✅ FCM só no mobile
  if (!kIsWeb) {
    await setupNotifications();
  }

  runApp(const MyApp());
}

// ✅ PUSH (FCM)
Future<void> setupNotifications() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission();

    String? token = await messaging.getToken();
    debugPrint("TOKEN DISPOSITIVO: $token");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Nova notificação FCM: ${message.notification?.title}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Notificação aberta");
    });
  } catch (e) {
    debugPrint("Erro FCM: $e");
  }
}

// ✅ APP ROOT
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConectaPro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF185FA5),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}

// ✅ AUTH CHECK
class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {

        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _LoadingPage();
        }

        final user = authSnap.data;

        if (user == null) {
          return const LoginPage();
        }

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, snap) {

            if (snap.connectionState == ConnectionState.waiting) {
              return const _LoadingPage();
            }

            if (snap.hasError) {
              return _ErrorPage(
                message: snap.error.toString(),
                onRetry: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AuthCheck(),
                    ),
                  );
                },
              );
            }

            final doc = snap.data;

            if (doc == null || !doc.exists) {
              _createUser(user);
              return const AreaClientePage();
            }

            final data = doc.data();

            if (data == null) {
              return const LoginPage();
            }

            final bool blocked = (data['blocked'] as bool?) ?? false;
            final String role = (data['role'] as String?) ?? 'cliente';

            if (blocked) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.block, color: Colors.red, size: 60),
                      const SizedBox(height: 15),
                      const Text(
                        'Conta bloqueada',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: const Text("Sair"),
                      ),
                    ],
                  ),
                ),
              );
            }

            switch (role) {
              case 'admin':
                return AdminPage();

              case 'profissional':
                return const AreaProfissionalPage();

              default:
                return const AreaClientePage();
            }
          },
        );
      },
    );
  }

  // ✅ CRIAR USUÁRIO + TOKEN
  Future<void> _createUser(User user) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'email': user.email ?? '',
        'role': 'cliente',
        'blocked': false,
        'balance': 0.0,
        'criadoEm': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!kIsWeb) {
        String? token =
            await FirebaseMessaging.instance.getToken();

        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'fcmToken': token,
          });
        }
      }
    } catch (e) {
      debugPrint("Erro criando usuário: $e");
    }
  }
}

// ✅ LOADING
class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// ✅ ERROR
class _ErrorPage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPage({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 15),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text("Tentar novamente"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
