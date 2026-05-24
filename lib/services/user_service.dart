import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> alterarParaProfissional(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .update({
    'role': 'profissional',
    'atualizadoEm': FieldValue.serverTimestamp(),
  });

  await FirebaseAuth.instance.currentUser?.reload();
}