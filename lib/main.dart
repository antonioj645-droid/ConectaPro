import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/area_cliente_page.dart';
import 'pages/area_profissional_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthCheck(), // ✅ AQUI É O SEGREDO
    );
  }
}

// ✅ CONTROLE INTELIGENTE
class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {

        // 🔄 carregando
        if (!authSnapshot.hasData) {
          return const LoginPage();
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const LoginPage();
        }

        return FutureBuilder(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),

          builder: (context, snapshot) {

            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data =
                (snapshot.data as DocumentSnapshot).data() as Map<String, dynamic>?;

            final role = data?['role'] ?? 'cliente';

            if (role == 'profissional') {
              return const AreaProfissionalPage();
            } else {
              return const AreaClientePage();
            }
          },
        );
      },
         );
  }
}
